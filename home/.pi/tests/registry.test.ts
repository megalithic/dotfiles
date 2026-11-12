import { afterAll, afterEach, beforeEach, expect, test } from 'bun:test';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { readRegistry } from '../agent/lib/registry.ts';

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
      tmux: { session: 'dev', window: 'code', pane: '%1', windowIndex: '0', paneIndex: '1' },
    },
  ]);
  expect(readRegistry({ includeDead: true }).pis.map((pi) => pi.alive)).toEqual([false, true, false]);
});

test('app leases expose tabs, live followers, and Rex seat metadata', () => {
  const socket = path.join(home, 'holder.sock');
  fs.writeFileSync(socket, '');
  const terminal = { kind: 'rex', rex: { session: 'rex-session', block: 'rex-block' } };

  const lease = {
    v: 1,
    port: 4000,
    origin: 'http://localhost:4000',
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
      origin: lease.origin,
      root: '/work',
      holder: { pid: process.pid, sessionId: 'one', socket },
      tabs: [{ id: 'tab1', url: 'http://localhost:4000/page', lastActiveAt: Date.parse('2026-01-01T00:00:00Z') }],
      followers: [process.ppid],
    },
  ]);
  expect(readRegistry().pis[0]?.rex).toEqual(terminal.rex);
  expect(readRegistry().pis[0]?.tmux).toBeUndefined();
  expect(readRegistry({ includeDead: true }).apps[1]?.alive).toBe(false);
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
