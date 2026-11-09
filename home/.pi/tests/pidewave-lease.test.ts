import { afterAll, afterEach, beforeEach, describe, expect, spyOn, test } from 'bun:test';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { spawnSync } from 'node:child_process';
import { once } from 'node:events';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import type { createBrowserLink, LinkEvents } from '../agent/extensions/pidewave/browser.ts';
import pidewave, { type PidewaveStatus, STATUS_EVENT } from '../agent/extensions/pidewave/index.ts';
import {
  claimLease,
  holderAlive,
  type Lease,
  leaseDir,
  readLease,
  releaseLease,
  terminalFromEnv,
  updateLease,
} from '../agent/extensions/pidewave/lease.ts';

const stateDir = fs.mkdtempSync('/tmp/pidewave-lease-');

const originalEnv = { ...process.env };

// Never let a test reach the real browser on CDP 9223.
const offlineLink: typeof createBrowserLink = () => ({
  start: () => {},
  stop: () => {},
  state: () => 'down' as const,
  tabs: () => [],
  evaluate: async () => undefined,
  inspect: async () => 'active',
});

const cleanups: (() => void | Promise<void>)[] = [];

// SAFETY: Fixtures implement only the API members the lease lifecycle uses.
const asExtensionAPI = <T>(value: T): ExtensionAPI => value as ExtensionAPI;

// SAFETY: Fixtures implement only the context members the lease lifecycle uses.
const asExtensionContext = <T>(value: T): ExtensionContext => value as ExtensionContext;

// A pid that existed and is gone.
const deadPid = spawnSync('true').pid!;

let nextPort = 4100;

beforeEach(() => {
  process.env = { ...originalEnv, PI_STATE_DIR: fs.mkdtempSync(path.join(stateDir, 'run-')), HOSTNAME: 'testhost' };

  // Never inherit this terminal or reach the live Pi that runs the tests.
  for (const name of [
    'PI_SUBAGENT_NAME',
    'PI_EPHEMERAL',
    'PI_SOCKET',
    'PI_SOCKET_OWNER_PID',
    'TMUX',
    'TMUX_PANE',
    'REX_SESSION',
    'REX_BLOCK',
  ]) {
    delete process.env[name];
  }
});

afterEach(async () => {
  for (const cleanup of cleanups.splice(0).reverse()) await cleanup();
  process.env = { ...originalEnv };
});

afterAll(() => fs.rmSync(stateDir, { recursive: true, force: true }));

const lease = (port: number, overrides: Partial<Lease> = {}): Lease => ({
  v: 1,
  port,
  origin: `http://localhost:${port}`,
  root: '/tmp/wt',
  cwd: '/tmp/wt',
  pid: process.pid,
  sessionId: 's1',
  sessionName: 'one',
  tellId: 'pi:testhost:s1',
  socket: null,
  terminal: { kind: 'plain' },
  claimedAt: new Date().toISOString(),
  browser: { cdp: 'off', tabs: [] },
  lastPromptAt: null,
  ...overrides,
});

describe('lease file', () => {
  test('a free port is claimed; a live holder keeps it unless forced', () => {
    const port = ++nextPort;
    expect(claimLease(lease(port))).toEqual({ held: true });

    const other = lease(port, { pid: process.ppid, sessionName: 'other' });
    const refused = claimLease(other);
    expect(refused.held).toBe(false);
    expect(readLease(port)?.pid).toBe(process.pid);

    expect(claimLease(other, true)).toEqual({ held: true });
    expect(readLease(port)?.sessionName).toBe('other');
    expect(fs.readdirSync(leaseDir()).filter((name) => name.endsWith('.tmp'))).toEqual([]);
  });

  test('a dead holder or one from before the last boot is taken over', () => {
    const port = ++nextPort;
    fs.mkdirSync(leaseDir(), { recursive: true });
    fs.writeFileSync(path.join(leaseDir(), `${port}.json`), JSON.stringify(lease(port, { pid: deadPid })));
    expect(claimLease(lease(port))).toEqual({ held: true });

    expect(holderAlive(lease(port, { pid: process.ppid, claimedAt: new Date(0).toISOString() }))).toBe(false);
    expect(holderAlive(lease(port, { pid: process.ppid }))).toBe(true);
    // A live pid without the recorded bridge socket is a reused pid.
    expect(holderAlive(lease(port, { pid: process.ppid, socket: '/tmp/pidewave-no-such.sock' }))).toBe(false);
  });

  test('update and release act only for the holding pid', () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid }));
    expect(updateLease(lease(port, { sessionName: 'mine' }))).toBe(false);
    releaseLease(port, process.pid);
    expect(readLease(port)?.pid).toBe(process.ppid);
    releaseLease(port, process.ppid);
    expect(readLease(port)).toBeNull();
  });

  test('racing processes: exactly one claims a free port', async () => {
    const port = ++nextPort;
    const module = new URL('../agent/extensions/pidewave/lease.ts', import.meta.url).pathname;
    const start = Date.now() + 400;

    const script = `
      const { claimLease } = await import(${JSON.stringify(module)});
      while (Date.now() < ${start}) {}
      const lease = { v: 1, port: ${port}, origin: 'http://localhost:${port}', root: '/tmp', cwd: '/tmp', pid: process.pid,
        sessionId: null, sessionName: null, tellId: null, socket: null, terminal: { kind: 'plain' },
        claimedAt: new Date().toISOString(), browser: { cdp: 'off', tabs: [] }, lastPromptAt: null };
      console.log(JSON.stringify(claimLease(lease).held));
      await new Promise((resolve) => setTimeout(resolve, 500));
    `;

    const runs = Array.from({ length: 6 }, () =>
      Bun.spawn([process.execPath, '-e', script], { env: process.env, stdout: 'pipe' }),
    );

    const held = await Promise.all(runs.map(async (run) => (await new Response(run.stdout).text()).trim()));
    expect(held.filter((value) => value === 'true')).toHaveLength(1);
    expect(held.filter((value) => value === 'false')).toHaveLength(5);
  });

  test('malformed files read as absent', () => {
    const port = ++nextPort;
    fs.mkdirSync(leaseDir(), { recursive: true });
    fs.writeFileSync(path.join(leaseDir(), `${port}.json`), '{"v":1,"port":"x"}');
    expect(readLease(port)).toBeNull();
  });

  test('terminal: tmux wins over inherited Rex ids', () => {
    expect(terminalFromEnv({ TMUX: '/tmp/t,1,0', TMUX_PANE: '%3', REX_SESSION: 's', REX_BLOCK: 'b' })).toEqual({
      kind: 'tmux',
      tmux: { pane: '%3' },
    });
    expect(terminalFromEnv({ REX_SESSION: 's', REX_BLOCK: 'b', REX_SERVER: 'unix:///x' })).toEqual({
      kind: 'rex',
      rex: { session: 's', block: 'b', server: 'unix:///x' },
    });
    expect(terminalFromEnv({})).toEqual({ kind: 'plain' });
  });
});

type Hook = (event: { reason?: string }, ctx: ExtensionContext) => void | Promise<void>;

const harness = (
  port: number,
  options: { hasUI?: boolean; sessionId?: string; link?: typeof createBrowserLink; bootstrapped?: boolean } = {},
) => {
  const cwd = fs.mkdtempSync('/tmp/pidewave-lease-wt-');
  fs.mkdirSync(path.join(cwd, '.pi'));

  const bootstrap = () =>
    fs.writeFileSync(
      path.join(cwd, '.pi', 'mcp.json'),
      JSON.stringify({ pidewave: { url: `http://localhost:${port}/tidewave/mcp` } }),
    );

  if (options.bootstrapped !== false) bootstrap();

  const hooks = new Map<string, Hook>();
  const commands = new Map<string, (args: string, ctx: ExtensionContext) => Promise<void>>();
  const notices: string[] = [];
  const statuses: PidewaveStatus[] = [];

  const pi = asExtensionAPI({
    on: (name: string, hook: Hook) => hooks.set(name, hook),
    events: {
      on: () => () => {},
      emit: (name: string, data: PidewaveStatus) => {
        if (name === STATUS_EVENT) statuses.push(data);
      },
    },
    registerCommand: (name: string, command: { handler: (args: string, ctx: ExtensionContext) => Promise<void> }) =>
      commands.set(name, command.handler),
    registerShortcut: () => {},
    registerMcpServer: () => {},
    unregisterMcpServer: () => {},
    appendEntry: () => {},
  });

  const ctx = asExtensionContext({
    cwd,
    hasUI: options.hasUI ?? true,
    isProjectTrusted: () => true,
    sessionManager: { getSessionId: () => options.sessionId ?? 'sess/1', getSessionName: () => 'worker' },
    ui: { notify: (text: string) => notices.push(text), setStatus: () => {}, setWidget: () => {} },
  });

  const never = async () => {
    throw new Error('down');
  };

  pidewave(pi, never, () => undefined, options.link ?? offlineLink);
  const fire = (name: string, event: { reason?: string } = {}) => hooks.get(name)?.(event, ctx);
  cleanups.push(async () => {
    await fire('session_shutdown', { reason: 'quit' });
  });

  return {
    bootstrap,
    notices,
    fire,
    status: () => statuses.at(-1),
    command: (args: string) => commands.get('pidewave')!(args, ctx),
  };
};

describe('lease lifecycle', () => {
  test('an interactive Pi claims its port at start with its tell id and terminal', () => {
    const port = ++nextPort;
    const h = harness(port);
    h.fire('session_start');
    const held = readLease(port)!;
    expect(held).toMatchObject({ pid: process.pid, tellId: 'pi:testhost:sess%2F1', sessionName: 'worker' });
    expect(h.status()).toMatchObject({ role: 'holder', port, connected: false });
  });

  test('subagents, ephemeral and headless Pis never claim', async () => {
    for (const setup of [
      () => (process.env.PI_SUBAGENT_NAME = 'scout'),
      () => (process.env.PI_EPHEMERAL = '1'),
      () => undefined,
    ]) {
      const port = ++nextPort;
      setup();

      const h = harness(port, {
        hasUI: process.env.PI_SUBAGENT_NAME !== undefined || process.env.PI_EPHEMERAL === '1',
      });

      h.fire('session_start');
      expect(readLease(port)).toBeNull();
      await h.fire('session_shutdown', { reason: 'quit' });
      delete process.env.PI_SUBAGENT_NAME;
      delete process.env.PI_EPHEMERAL;
    }
  });

  test('a second Pi follows a live holder, takes over on claim, and the old holder is told', () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid, sessionName: 'first' }));
    const h = harness(port);
    h.fire('session_start');
    expect(h.status()).toMatchObject({ role: 'follower', holder: { sessionName: 'first' } });

    void h.command('claim');
    expect(readLease(port)?.pid).toBe(process.pid);
    expect(h.status()).toMatchObject({ role: 'holder' });

    claimLease(lease(port, { pid: process.ppid, sessionName: 'third' }), true);
    h.fire('before_agent_start');
    expect(h.status()).toMatchObject({ role: 'follower', holder: { sessionName: 'third' } });
    expect(h.notices.at(-1)).toBe('Pidewave: browser prompts moved to third.');
  });

  test('a follower takes the port when the holder dies', () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid }));
    const h = harness(port);
    h.fire('session_start');
    expect(h.status()?.role).toBe('follower');
    fs.writeFileSync(path.join(leaseDir(), `${port}.json`), JSON.stringify(lease(port, { pid: deadPid })));
    h.fire('before_agent_start');
    expect(h.status()?.role).toBe('holder');
  });

  test('reload keeps the lease and the reloaded copy adopts it; quit releases it', async () => {
    const port = ++nextPort;
    const first = harness(port);
    first.fire('session_start');
    await first.fire('session_shutdown', { reason: 'reload' });
    expect(readLease(port)?.pid).toBe(process.pid);

    const second = harness(port);
    second.fire('session_start', { reason: 'reload' });
    expect(second.status()?.role).toBe('holder');
    await second.fire('session_shutdown', { reason: 'quit' });
    expect(readLease(port)).toBeNull();
  });

  test('/pidewave status names the holder', async () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid, sessionName: 'first' }));
    const h = harness(port);
    h.fire('session_start');
    await h.command('status');
    expect(h.notices.at(-1)).toContain('browser prompts go to first');
  });
});

describe('browser prompts', () => {
  test('the holder links its origin and delivers prompts over its own bridge socket', async () => {
    const port = ++nextPort;
    const socketPath = path.join(process.env.PI_STATE_DIR!, 'bridge.sock');
    const requests: { operation: string; params: { text: string; from: string; mode: string } }[] = [];

    const server = net.createServer((peer) =>
      peer.on('data', (chunk) => {
        requests.push(JSON.parse(chunk.toString()));
        peer.end('{"ok":true}\n');
      }),
    );

    server.listen(socketPath);
    await once(server, 'listening');
    cleanups.push(() => new Promise<void>((resolve) => server.close(() => resolve())));
    process.env.PI_SOCKET = socketPath;

    const evaluations: string[] = [];
    let events: LinkEvents | undefined;
    let origin: string | undefined;

    const link: typeof createBrowserLink = (linkOrigin, linkEvents) => {
      origin = linkOrigin;
      events = linkEvents;

      return {
        ...offlineLink(linkOrigin, linkEvents),
        state: () => 'up' as const,
        evaluate: async (_target: string, expression: string) => {
          evaluations.push(expression);

          return undefined;
        },
      };
    };

    const h = harness(port, { link });
    h.fire('session_start');
    expect(origin).toBe(`http://localhost:${port}`);

    const tab = { targetId: 't1', url: `${origin}/x`, title: 'x', kind: 'app' as const };
    events!.message({ kind: 'prompt', text: '<user_prompt>hi</user_prompt>' }, tab);
    await new Promise((resolve) => setTimeout(resolve, 50));

    expect(requests).toEqual([
      expect.objectContaining({
        operation: 'message.send',
        params: { text: '<user_prompt>hi</user_prompt>', mode: 'follow_up', from: 'tidewave' },
      }),
    ]);
    expect(evaluations.at(-1)).toContain('Sent to worker');
    expect(readLease(port)?.lastPromptAt).toBeString();
  });

  test("another process's PI_SOCKET is never used", async () => {
    const port = ++nextPort;
    process.env.PI_SOCKET = '/tmp/parent-pi.sock';
    process.env.PI_SOCKET_OWNER_PID = String(process.ppid);
    const evaluations: string[] = [];
    let events: LinkEvents | undefined;

    const link: typeof createBrowserLink = (linkOrigin, linkEvents) => {
      events = linkEvents;

      return {
        ...offlineLink(linkOrigin, linkEvents),
        evaluate: async (_target: string, expression: string) => {
          evaluations.push(expression);

          return undefined;
        },
      };
    };

    const h = harness(port, { link });
    h.fire('session_start');
    expect(readLease(port)?.socket).toBeNull();
    events!.message(
      { kind: 'prompt', text: '<user_prompt>x</user_prompt>' },
      {
        targetId: 't',
        url: `http://localhost:${port}/`,
        title: '',
        kind: 'app',
      },
    );
    await new Promise((resolve) => setTimeout(resolve, 20));
    expect(evaluations.at(-1)).toContain('its bridge socket is not running');
  });

  test('a follower never links the browser', () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid }));
    let linked = false;

    const h = harness(port, {
      link: (...args) => {
        linked = true;

        return offlineLink(...args);
      },
    });

    h.fire('session_start');
    expect(linked).toBe(false);
  });
});

describe('inspect from Pi', () => {
  test('a follower takes the port, links the browser and runs Inspect with the browser raised', async () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid, sessionName: 'first' }));
    const inspections: [string | undefined, boolean | undefined][] = [];

    const link: typeof createBrowserLink = (linkOrigin, linkEvents) => ({
      ...offlineLink(linkOrigin, linkEvents),
      state: () => 'up',
      inspect: async (targetId, raise) => {
        inspections.push([targetId, raise]);

        return 'not-ready:loading';
      },
    });

    const h = harness(port, { link });
    h.fire('session_start');
    expect(h.status()?.role).toBe('follower');
    await h.command('inspect');
    expect(readLease(port)?.pid).toBe(process.pid);
    expect(inspections).toEqual([[undefined, true]]);
    expect(h.notices.at(-1)).toBe('Pidewave: not-ready:loading');
  });

  test('a headless Pi cannot take the port', async () => {
    const port = ++nextPort;
    const h = harness(port, { hasUI: false });
    h.fire('session_start');
    await h.command('inspect');
    expect(readLease(port)).toBeNull();
    expect(h.notices.at(-1)).toBe('Pidewave: only an interactive Pi can take browser prompts.');
  });
});

describe('review fixes', () => {
  test('a holder that lost the port refuses tab actions at once, before the next reconcile', async () => {
    const port = ++nextPort;
    const evaluations: string[] = [];
    let events: LinkEvents | undefined;

    const link: typeof createBrowserLink = (linkOrigin, linkEvents) => {
      events = linkEvents;

      return {
        ...offlineLink(linkOrigin, linkEvents),
        evaluate: async (_target: string, expression: string) => {
          evaluations.push(expression);

          return undefined;
        },
      };
    };

    const h = harness(port, { link });
    h.fire('session_start');
    claimLease(lease(port, { pid: process.ppid, sessionName: 'thief' }), true);
    const tab = { targetId: 't', url: `http://localhost:${port}/`, title: '', kind: 'app' as const };
    events!.message({ kind: 'prompt', text: '<user_prompt>x</user_prompt>' }, tab);
    expect(evaluations.at(-1)).toContain('Browser prompts moved to thief');
    expect(h.status()?.role).toBe('follower');
  });

  test('a reload onto another port releases the old lease', async () => {
    const first = ++nextPort;
    const a = harness(first);
    a.fire('session_start');
    await a.fire('session_shutdown', { reason: 'reload' });
    expect(readLease(first)?.pid).toBe(process.pid);

    const b = harness(++nextPort);
    b.fire('session_start', { reason: 'reload' });
    expect(readLease(first)).toBeNull();
    expect(b.status()?.role).toBe('holder');
  });

  test('an endpoint that appears after start still gets lease polling', async () => {
    const port = ++nextPort;
    const intervals = spyOn(globalThis, 'setInterval');

    try {
      const h = harness(port, { bootstrapped: false });
      h.fire('session_start');
      expect(intervals.mock.calls.filter(([, delay]) => delay === 5_000)).toHaveLength(0);
      h.bootstrap();
      await h.command('');
      expect(readLease(port)?.pid).toBe(process.pid);
      expect(intervals.mock.calls.filter(([, delay]) => delay === 5_000)).toHaveLength(1);
    } finally {
      intervals.mockRestore();
    }
  });

  test('followers record a seat for bin/pidewave; quitting removes it', async () => {
    const port = ++nextPort;
    claimLease(lease(port, { pid: process.ppid }));
    const h = harness(port);
    h.fire('session_start');
    const seat = path.join(process.env.PI_STATE_DIR!, 'pidewave', 'pis', `${process.pid}.json`);
    expect(JSON.parse(fs.readFileSync(seat, 'utf8'))).toMatchObject({
      pid: process.pid,
      port,
      terminal: { kind: 'plain' },
    });
    await h.fire('session_shutdown', { reason: 'quit' });
    expect(fs.existsSync(seat)).toBe(false);
  });
});
