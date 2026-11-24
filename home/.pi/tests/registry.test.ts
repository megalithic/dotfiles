import { afterAll, afterEach, beforeEach, expect, test } from 'bun:test';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { probeApp, readRegistry, withUltimateApps } from '../agent/lib/registry.ts';

const fixtures = fs.mkdtempSync('/tmp/registry-');

const originalEnv = { ...process.env };

const deadPid = spawnSync('true').pid!;

let home: string;

let state: string;

let ultimateHome: string;

const write = <T>(file: string, value: T): void => {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, JSON.stringify(value));
};

beforeEach(() => {
  home = fs.mkdtempSync(path.join(fixtures, 'run-'));
  state = path.join(home, 'state/pi');
  ultimateHome = path.join(home, '.ultimate');
  process.env = {
    ...originalEnv,
    HOME: home,
    PI_STATE_DIR: state,
    ULTIMATE_USER_HOME: ultimateHome,
    ULTIMATE_HOME: path.join(home, 'wrong-instance-home'),
    HOSTNAME: 'testhost.local',
  };
});

afterEach(() => {
  process.env = { ...originalEnv };
});

afterAll(() => fs.rmSync(fixtures, { recursive: true, force: true }));

test('live Pi registrations require a live pid and an existing socket; dead entries are opt-in', () => {
  const socket = path.join(home, 'live.sock');
  fs.writeFileSync(socket, '');

  const manifest = {
    pid: process.pid,
    socket,
    cwd: '/work',
    sessionId: 'session/one',
    sessionName: 'one',
    state: 'idle',
    statusUpdatedAt: '2026-01-01T00:00:00Z',
  };

  write(path.join(state, 'manifests/live.info'), {
    ...manifest,
    session: 'dev',
    window: 'code',
    pane: '%1',
    windowIndex: '0',
    paneIndex: '1',
  });
  write(path.join(state, 'manifests/dead.info'), { ...manifest, pid: deadPid, sessionId: 'dead' });
  write(path.join(state, 'manifests/missing-socket.info'), { ...manifest, socket: path.join(home, 'missing.sock') });

  const registry = readRegistry();

  expect(registry.machine).toBe('testhost');
  expect(Number.isFinite(Date.parse(registry.at))).toBe(true);
  expect(registry.pis).toEqual([
    {
      ...manifest,
      id: 'pi:testhost:session%2Fone',
      alive: true,
      ephemeral: false,
      tmux: { session: 'dev', window: 'code', pane: '%1', windowIndex: '0', paneIndex: '1' },
    },
  ]);
  expect(readRegistry({ includeDead: true }).pis.map((pi) => pi.alive)).toEqual([false, true, false]);
});

test('ephemeral registrations stay hidden without hiding a replacement in the same pane', () => {
  const socket = path.join(home, 'replacement.sock');
  fs.writeFileSync(socket, '');

  const replacement = {
    pid: process.pid,
    socket,
    sessionId: 'replacement',
    session: 'dev',
    window: 'code',
    pane: '%reused',
  };

  write(path.join(state, 'manifests/stale.info'), {
    ...replacement,
    pid: deadPid,
    socket: `${socket}.gone`,
    ephemeral: true,
  });
  write(path.join(state, 'manifests/replacement.info'), replacement);
  expect(readRegistry().pis.map((pi) => pi.sessionId)).toEqual(['replacement']);
  write(path.join(state, 'manifests/replacement.info'), { ...replacement, ephemeral: true });
  expect(readRegistry().pis).toEqual([]);
  expect(readRegistry({ includeDead: true }).pis).toEqual([]);
  expect(readRegistry({ includeEphemeral: true }).pis[0]).toMatchObject({ sessionId: 'replacement', ephemeral: true });
});

test('app leases expose tabs, live followers, and Rex seat metadata', () => {
  const socket = path.join(home, 'holder.sock');
  fs.writeFileSync(socket, '');
  const terminal = { kind: 'rex', rex: { session: 'rex-session', block: 'rex-block' } };

  const lease = {
    v: 1,
    port: 4000,
    origin: 'http://127.0.0.1:4000',
    root: '/work',
    cwd: '/work',
    pid: process.pid,
    sessionId: 'one',
    socket,
    terminal,
    claimedAt: new Date().toISOString(),
    browser: {
      cdp: 'up',
      tabs: [{ targetId: 'tab1', url: 'http://localhost:4000/page', lastActiveAt: '2026-01-01T00:00:00Z' }],
    },
  };

  write(path.join(state, 'pidewave/ports/4000.json'), lease);
  write(path.join(state, 'pidewave/ports/4001.json'), { ...lease, port: 4001, pid: deadPid });
  write(path.join(state, 'pidewave/pis/holder.json'), lease);
  write(path.join(state, 'pidewave/pis/follower.json'), { pid: process.ppid, port: 4000, socket: null });
  write(path.join(state, 'pidewave/pis/dead.json'), { pid: deadPid, port: 4000, socket: null });
  write(path.join(state, 'manifests/rex.info'), { pid: process.pid, socket, session: 'rex-label', window: '1' });

  expect(readRegistry().apps).toEqual([
    {
      port: 4000,
      origin: 'http://localhost:4000',
      root: '/work',
      owner: { kind: 'pi', pid: process.pid, sessionId: 'one', socket },
      holder: { pid: process.pid, sessionId: 'one', socket },
      tabs: [{ id: 'tab1', url: 'http://localhost:4000/page', lastActiveAt: Date.parse('2026-01-01T00:00:00Z') }],
      followers: [process.ppid],
    },
  ]);
  expect(readRegistry().pis[0]?.rex).toEqual(terminal.rex);
  expect(readRegistry().pis[0]?.tmux).toBeUndefined();
  expect(readRegistry({ includeDead: true }).apps[1]?.alive).toBe(false);
});

test('Ultimate apps match real worktree ownership, prefer a listened PORT over stray PHX_PORT, and keep pi leases', async () => {
  const instanceHome = path.join(ultimateHome, 'projects/app');
  const project = '/work/app';
  write(path.join(instanceHome, 'ultimate.lock'), { pid: process.pid, port: 4749, project });
  write(path.join(state, 'pidewave/ports/4000.json'), {
    v: 1,
    port: 4000,
    pid: process.pid,
    claimedAt: new Date().toISOString(),
  });
  const hash = createHash('sha256').update(instanceHome).digest('hex').slice(0, 6);
  const root = `/work/app/.worktrees/ult-${hash}-38382`;
  const calls: string[][] = [];

  const registry = await withUltimateApps(readRegistry(), {
    run: async (command, args) => {
      calls.push([command, ...args]);

      if (args.includes('cwd')) return `p10\nn/work/link\np11\nn/work/ult-${hash}-38383\np12\nn/work/non-ult`;

      if (command === 'ps') return args.at(-1) === '10' ? 'beam.smp PHX_PORT=4266 PORT=23820' : 'beam.smp PORT=4000';

      return 'p10\nn*:23820\nn127.0.0.1:58462\np11\nn*:4000\np12\nn*:4002';
    },
    fs: {
      realpath: async (file) => (file === '/work/link' ? root : file),
      readFile: async () => '',
    },
    probe: async () => {
      throw new Error('A listened environment port needs no probe');
    },
  });

  expect(registry.apps).toEqual([
    {
      port: 4000,
      origin: 'http://localhost:4000',
      root: undefined,
      owner: { kind: 'pi', pid: process.pid, sessionId: undefined, socket: undefined },
      holder: { pid: process.pid, sessionId: undefined, socket: undefined },
      tabs: [],
      followers: [],
    },
    {
      port: 23820,
      origin: 'http://localhost:23820',
      root,
      pid: 10,
      owner: { kind: 'ultimate', project, home: instanceHome, conversation: 38382, url: 'http://127.0.0.1:4749' },
      tabs: [],
      followers: [],
    },
  ]);
  expect(calls.filter(([command]) => command === '/usr/sbin/lsof')).toHaveLength(2);
  expect(calls).toContainEqual(['ps', '-E', '-ww', '-o', 'command=', '-p', '10']);
});

test('Ultimate probe fallback chooses the lowest answering owned port and excludes another pid sharing a port', async () => {
  const instanceHome = path.join(ultimateHome, 'projects/app');
  write(path.join(instanceHome, 'ultimate.lock'), { pid: process.pid, port: 4749, project: '/work/app' });
  const hash = createHash('sha256').update(instanceHome).digest('hex').slice(0, 6);
  const root = `/work/ult-${hash}-38382`;
  const probed: number[] = [];

  const registry = await withUltimateApps(readRegistry(), {
    run: async (command, args) => {
      if (args.includes('cwd')) return `p10\nn${root}`;

      if (command === 'ps') return 'beam.smp PHX_PORT=4266';

      return 'p10\nn*:4300\nn127.0.0.1:4200\nn*:4100\nn*:4000\np99\nn127.0.0.1:4000';
    },
    fs: { realpath: async (file) => file, readFile: async () => '' },
    probe: async (port) => {
      probed.push(port);

      return port !== 4100;
    },
  });

  expect(probed).toEqual([4100, 4200, 4300]);
  expect(registry.apps).toHaveLength(1);
  expect(registry.apps[0]?.port).toBe(4200);
});

test.each(['application/json', 'text/event-stream'])(
  'Ultimate probe rejects lower 404 and 500 ports in favor of an MCP reply (%s)',
  async (contentType) => {
    const statuses = new Map<number, number>();
    const requests: { method: string; type: string | null; accept: string | null; body: unknown }[] = [];

    const servers = Array.from({ length: 3 }, () =>
      Bun.serve({
        hostname: '127.0.0.1',
        port: 0,
        async fetch(request, server) {
          requests.push({
            method: request.method,
            type: request.headers.get('content-type'),
            accept: request.headers.get('accept'),
            body: await request.json(),
          });
          const status = statuses.get(server.port!)!;

          const reply = JSON.stringify({
            jsonrpc: '2.0',
            id: 1,
            result: { protocolVersion: '2025-06-18', capabilities: {} },
          });

          return new Response(contentType === 'application/json' ? reply : `data: ${reply}\n\n`, {
            status,
            headers: { 'Content-Type': contentType },
          });
        },
      }),
    );

    const ports = servers.map((server) => server.port!).toSorted((a, b) => a - b);
    ports.forEach((port, index) => statuses.set(port, [404, 500, 200][index]!));
    const instanceHome = path.join(ultimateHome, 'projects/app');
    write(path.join(instanceHome, 'ultimate.lock'), { pid: process.pid, port: 4749, project: '/work/app' });
    const hash = createHash('sha256').update(instanceHome).digest('hex').slice(0, 6);
    const root = `/work/ult-${hash}-38382`;

    try {
      const registry = await withUltimateApps(readRegistry(), {
        run: async (command, args) => {
          if (args.includes('cwd')) return `p10\nn${root}`;

          if (command === 'ps') return 'beam.smp';

          return `p10\n${ports.map((port) => `n*:${port}`).join('\n')}`;
        },
        fs: { realpath: async (file) => file, readFile: async () => '' },
      });

      expect(registry.apps.map((app) => app.port)).toEqual([ports[2]!]);
      expect(requests).toHaveLength(3);

      for (const request of requests) {
        expect(request.method).toBe('POST');
        expect(request.type).toBe('application/json');
        expect(request.accept).toBe('application/json, text/event-stream');
        expect(request.body).toMatchObject({
          jsonrpc: '2.0',
          method: 'initialize',
          params: { protocolVersion: '2025-06-18' },
        });
      }
    } finally {
      servers.forEach((server) => server.stop(true));
    }
  },
);

test.each([
  ['a null result', { jsonrpc: '2.0', id: 1, result: null }],
  ['method not found', { jsonrpc: '2.0', id: 1, error: { code: -32601, message: 'Method not found' } }],
  ['a result without protocolVersion', { jsonrpc: '2.0', id: 1, result: { capabilities: {} } }],
])('Ultimate probe rejects %s', async (_name, body) => {
  const server = Bun.serve({ hostname: '127.0.0.1', port: 0, fetch: () => Response.json(body) });

  try {
    expect(await probeApp(server.port!)).toBe(false);
  } finally {
    server.stop(true);
  }
});

test('Rex manifest identity wins over stale seat metadata without an app lease', () => {
  const socket = path.join(home, 'rex.sock');
  fs.writeFileSync(socket, '');
  const manifest = { pid: process.pid, socket, rexSession: 'live-session', rexBlock: 'live-block' };
  write(path.join(state, 'manifests/rex.info'), manifest);
  write(path.join(state, 'pidewave/pis/stale.json'), {
    ...manifest,
    terminal: { kind: 'rex', rex: { session: 'old', block: 'old' } },
  });
  expect(readRegistry().pis[0]?.rex).toEqual({ session: 'live-session', block: 'live-block' });
});

test('Ultimate locks include hidden folders, mark primary and containing hubs, and ignore stale or invalid locks', () => {
  const lock = { pid: process.pid, port: 4749, project: path.join(home, 'fleet') };
  const projects = path.join(ultimateHome, 'projects');
  write(path.join(projects, '.primary/ultimate.lock'), lock);
  write(path.join(projects, 'secondary/ultimate.lock'), { ...lock, port: 4750, project: path.join(home, 'code') });
  write(path.join(projects, 'app/ultimate.lock'), { ...lock, port: 4751, project: path.join(home, 'code/app') });
  write(path.join(projects, 'sibling/ultimate.lock'), { ...lock, port: 4752, project: path.join(home, 'code-other') });
  write(path.join(projects, 'dead/ultimate.lock'), { ...lock, pid: deadPid, project: home });
  write(path.join(projects, 'invalid/ultimate.lock'), { ...lock, pid: 'not-a-pid' });
  write(path.join(ultimateHome, 'settings.json'), { fleet: { primary: '~/fleet' } });

  expect(readRegistry().ultimates.map(({ port, hub }) => ({ port, hub }))).toEqual([
    { port: 4749, hub: 'primary' },
    { port: 4751, hub: undefined },
    { port: 4750, hub: 'secondary' },
    { port: 4752, hub: undefined },
  ]);
  expect(readRegistry().ultimates[0]?.url).toBe('http://127.0.0.1:4749');
  expect(readRegistry({ includeDead: true }).ultimates.find((instance) => instance.pid === deadPid)).toMatchObject({
    alive: false,
  });
});
