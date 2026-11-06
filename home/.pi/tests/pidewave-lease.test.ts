import { afterAll, afterEach, beforeEach, describe, expect, test } from 'bun:test';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
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
  delete process.env.PI_SUBAGENT_NAME;
  delete process.env.PI_EPHEMERAL;
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

const harness = (port: number, options: { hasUI?: boolean; sessionId?: string } = {}) => {
  const cwd = fs.mkdtempSync('/tmp/pidewave-lease-wt-');
  fs.mkdirSync(path.join(cwd, '.pi'));
  fs.writeFileSync(
    path.join(cwd, '.pi', 'mcp.json'),
    JSON.stringify({ pidewave: { url: `http://localhost:${port}/tidewave/mcp` } }),
  );

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

  pidewave(pi, never);
  const fire = (name: string, event: { reason?: string } = {}) => hooks.get(name)?.(event, ctx);
  cleanups.push(async () => {
    await fire('session_shutdown', { reason: 'quit' });
  });

  return {
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
