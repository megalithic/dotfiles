import { afterAll, describe, expect, test } from 'bun:test';
import type { ExtensionAPI, ExtensionContext, Theme } from '@earendil-works/pi-coding-agent';
import type { AssistantMessage } from '@earendil-works/pi-ai';
import { spawn } from 'node:child_process';
import { EventEmitter, once } from 'node:events';
import fs from 'node:fs';
import net from 'node:net';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { Value } from 'typebox/value';
import { Type } from 'typebox';

const stateDir = fs.mkdtempSync('/tmp/pi-bridge-test-');

// SAFETY: Fixtures intentionally implement only the bridge API members they exercise.
const asExtensionAPI = <T>(value: T): ExtensionAPI => value as ExtensionAPI;

// SAFETY: Fixtures intentionally implement only the bridge context members they exercise.
const asExtensionContext = <T>(value: T): ExtensionContext => value as ExtensionContext;

const themeHelpers: Pick<Theme, 'fg' | 'bg' | 'bold' | 'inverse'> = {
  fg: (_color, text) => text,
  bg: (_color, text) => text,
  bold: (text) => text,
  inverse: (text) => text,
};

// SAFETY: The tell card renderer calls only fg, bg, bold, and inverse.
const plainTheme = themeHelpers as Theme;

const originalEnv = { ...process.env };

process.env.PI_STATE_DIR = stateDir;

process.env.PI_SOCKET = path.join(stateDir, 'sockets', 'test.sock');

process.env.PI_SOCKET_OWNER_PID = String(process.pid);

process.env.PI_BRIDGE_LEGACY_SOCKET = '1';

delete process.env.TMUX;

const { default: bridge, _test } = await import('../agent/extensions/bridge.ts');

const socketPath = process.env.PI_SOCKET;

process.env = { ...originalEnv };

afterAll(() => {
  process.env = { ...originalEnv };
  // Test fixtures only; preserve the directory for failure inspection.
});

type TmuxLocation = Parameters<typeof _test.refreshTmuxLocation>[0];

const assistant = (
  text: string,
  stopReason: AssistantMessage['stopReason'] = 'stop',
): Parameters<typeof _test.captureAssistantResult>[0] => ({
  role: 'assistant',
  content: [{ type: 'text', text }],
  stopReason,
});

describe('bridge heartbeat metadata', () => {
  test('ignores missing tmux metadata for headless Pi processes', () => {
    const manifest: TmuxLocation = {};
    expect(_test.refreshTmuxLocation(manifest, null)).toBe(false);
    expect(manifest).toEqual({});
  });

  test("refreshes indices only for the manifest's tmux pane", () => {
    const manifest: TmuxLocation = { pane: '%7' };
    expect(
      _test.refreshTmuxLocation(manifest, {
        session: 'work',
        window: 'code',
        pane: '%7',
        windowIndex: '2',
        paneIndex: '1',
      }),
    ).toBe(true);
    expect(manifest.windowIndex).toBe('2');
    expect(manifest.paneIndex).toBe('1');

    expect(
      _test.refreshTmuxLocation(manifest, {
        session: 'work',
        window: 'other',
        pane: '%8',
        windowIndex: '3',
        paneIndex: '0',
      }),
    ).toBe(false);
    expect(manifest.windowIndex).toBe('2');
  });
});

describe('bridge socket selection', () => {
  test('shortens Unicode socket names by bytes without splitting codepoints', () => {
    const socket = _test.buildSocketPath('界😀'.repeat(80), 'code', '%1', '/tmp/sockets');
    expect(Buffer.byteLength(socket)).toBeLessThanOrEqual(103);
    expect(socket).not.toContain('�');
    expect(socket).toMatch(/-[a-f0-9]{8}\.sock$/);
    expect(_test.buildSocketPath('界😀'.repeat(80), 'code', '%2', '/tmp/sockets')).not.toBe(socket);
  });

  test('rejects a socket directory that leaves no room for the hashed basename', () => {
    expect(() => _test.buildSocketPath('code', '0', '%1', '/' + 'x'.repeat(100))).toThrow('Unix socket path limit');
  });

  test('headless defaults are process-specific', () => {
    expect(_test.resolveSocket({}, null, 101).socketPath).not.toBe(_test.resolveSocket({}, null, 102).socketPath);
  });

  test("preserves explicit overrides but ignores another process's published path", () => {
    expect(_test.resolveSocket({ PI_SOCKET: '/tmp/explicit.sock' }, null, 101).socketPath).toBe('/tmp/explicit.sock');
    expect(
      _test.resolveSocket({ PI_SOCKET: '/tmp/parent.sock', PI_SOCKET_OWNER_PID: '100' }, null, 101).socketPath,
    ).toEndWith('pi-process-101.sock');
    expect(_test.resolveSocket({ PI_SOCKET: '/tmp/own.sock', PI_SOCKET_OWNER_PID: '101' }, null, 101).socketPath).toBe(
      '/tmp/own.sock',
    );
  });
});

type LifecycleEvent = {
  reason?: 'startup' | 'reload';
  systemPromptOptions?: { selectedTools: string[] };
};

type LifecycleHook = (event: LifecycleEvent, ctx: ExtensionContext) => void | Promise<void>;

type BusHandler = Parameters<ExtensionAPI['events']['on']>[1];

type Delivery = {
  message: Parameters<ExtensionAPI['sendMessage']>[0];
  options: Parameters<ExtensionAPI['sendMessage']>[1];
};

const tidewaveEndpoint = { origin: 'http://localhost:4300', pathname: '/tidewave/mcp' };

const harness = (cwd = process.cwd()) => {
  const hooks = new Map<string, LifecycleHook>();
  const events = new Map<string, BusHandler>();
  const persistedTexts: string[] = [];
  const delivered: Delivery[] = [];

  // SAFETY: Tests call only bridge's lifecycle hooks, runtime event bus, and
  // model delivery; UI is deliberately absent so accidental use fails the test.
  const pi = asExtensionAPI({
    on: (name: string, handler: LifecycleHook) => {
      hooks.set(name, handler);
    },
    registerMessageRenderer: () => {},
    sendMessage: (message: Delivery['message'], options: Delivery['options']) => {
      delivered.push({ message, options });
    },
    appendEntry: (_kind: string, data: { text: string }) => {
      persistedTexts.push(data.text);
      // Stop before external notification or model delivery in wire tests.
      throw new Error('fixture refuses persistence');
    },
    events: {
      on: (name: string, handler: BusHandler) => {
        events.set(name, handler);

        return () => {
          events.delete(name);
        };
      },
    },
  });

  // SAFETY: Bridge's tested lifecycle/status path uses only these context members.
  const ctx = asExtensionContext({
    cwd,
    hasUI: false,
    isIdle: () => true,
    hasPendingMessages: () => false,
    sessionManager: { getSessionId: () => 'test-session', getSessionName: () => 'test-name' },
  });

  bridge(pi);

  return {
    pi,
    ctx,
    events,
    persistedTexts,
    delivered,
    connectTidewave: (endpoint = tidewaveEndpoint) => {
      events.get('pidewave:endpoint:v1')?.({ version: 1, endpoint });
    },
    beforeAgentStart: async (selectedTools: string[]) => {
      await hooks.get('before_agent_start')?.({ systemPromptOptions: { selectedTools } }, ctx);
    },
    start: async (reason: 'startup' | 'reload' = 'startup') => {
      await hooks.get('session_start')?.({ reason }, ctx);
      await _test.startServer(pi, ctx);
    },
    stop: async () => {
      await hooks.get('session_shutdown')?.({ reason: 'reload' }, ctx);
    },
  };
};

const responseSchema = Type.Object({
  ok: Type.Boolean(),
  error: Type.Optional(Type.String()),
  protocol: Type.Optional(Type.String()),
  id: Type.Optional(Type.String()),
  operation: Type.Optional(Type.String()),
  type: Type.Optional(Type.String()),
  pid: Type.Optional(Type.Number()),
  sessionId: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  idle: Type.Optional(Type.Boolean()),
  pending: Type.Optional(Type.Boolean()),
  runtime: Type.Optional(
    Type.Object({
      bridge: Type.Object({ version: Type.String(), loadedAt: Type.String(), sourceHash: Type.String() }),
      tell: Type.Union([
        Type.Object({
          version: Type.String(),
          loadedAt: Type.String(),
          sourceHash: Type.Union([Type.String(), Type.Null()]),
        }),
        Type.Null(),
      ]),
    }),
  ),
});

const request = (payload: string, splitAt?: number): Promise<Type.Static<typeof responseSchema>> =>
  new Promise((resolve, reject) => {
    const client = net.createConnection(socketPath);
    client.setEncoding('utf8');
    let buffer = '';
    client.setTimeout(1000, () => {
      client.destroy();
      reject(new Error('bridge request timed out'));
    });
    client.once('error', reject);
    client.once('connect', () => {
      const frame = Buffer.from(payload + '\n');

      if (splitAt === undefined) {
        client.write(frame);

        return;
      }

      client.write(frame.subarray(0, splitAt));
      setTimeout(() => client.write(frame.subarray(splitAt)), 15);
    });
    client.on('data', (chunk) => {
      buffer += chunk.toString();

      if (!buffer.includes('\n')) return;
      client.destroy();

      try {
        const response: unknown = JSON.parse(buffer.split('\n')[0]!);

        if (!Value.Check(responseSchema, response)) throw new Error('invalid test response');
        resolve(response);
      } catch (error) {
        reject(error);
      }
    });
  });

const staleSocket = (name: string, pid = 2147483647, heartbeatAt = new Date(0).toISOString()) => {
  const socket = path.join(stateDir, 'sockets', `${name}.sock`);
  fs.mkdirSync(path.dirname(socket), { recursive: true });
  fs.mkdirSync(path.join(stateDir, 'manifests'), { recursive: true });

  const child = Bun.spawnSync([
    process.execPath,
    '-e',
    `require('node:net').createServer().listen(${JSON.stringify(socket)}, () => process.exit(0))`,
  ]);

  expect(child.exitCode).toBe(0);
  fs.writeFileSync(_test.manifestForSocket(socket), JSON.stringify({ socket, pid, owner: 'stale-owner', heartbeatAt }));

  return socket;
};

const contender = (socket: string) => {
  const tsconfig = path.join(stateDir, 'fixture-tsconfig.json');
  fs.writeFileSync(
    tsconfig,
    JSON.stringify({
      compilerOptions: {
        paths: {
          typebox: [fileURLToPath(import.meta.resolve('typebox'))],
          'typebox/value': [fileURLToPath(import.meta.resolve('typebox/value'))],
        },
      },
    }),
  );

  const child = spawn(
    process.execPath,
    ['--tsconfig-override', tsconfig, path.join(import.meta.dir, 'bridge-contention.fixture.ts')],
    {
      env: {
        ...process.env,
        PI_STATE_DIR: stateDir,
        PI_SOCKET: socket,
        PI_SOCKET_OWNER_PID: '',
        PI_BRIDGE_LEGACY_SOCKET: '1',
        TMUX: '',
        TMUX_PANE: '',
      },
      stdio: ['pipe', 'pipe', 'inherit'],
    },
  );

  const events = new EventEmitter();
  const seen = new Set<string>();
  let buffer = '';
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', (chunk: string) => {
    buffer += chunk;
    let newline = buffer.indexOf('\n');

    while (newline !== -1) {
      const line = buffer.slice(0, newline);
      buffer = buffer.slice(newline + 1);
      seen.add(line);
      events.emit(line);
      newline = buffer.indexOf('\n');
    }
  });
  const exited = new Promise<number | null>((resolve) => child.once('exit', resolve));

  return {
    pid: child.pid,
    start: () => child.stdin.write('start\n'),
    waitFor: async (line: string) => {
      if (!seen.has(line)) await once(events, line, { signal: AbortSignal.timeout(3000) });
    },
    stop: async () => {
      child.stdin.end('stop\n');
      const timer = setTimeout(() => child.kill(), 2000);

      try {
        expect(await exited).toBe(0);
      } finally {
        clearTimeout(timer);
      }
    },
  };
};

const sendToRetiredListener = (): Promise<void> =>
  new Promise((resolve, reject) => {
    const client = net.createConnection(socketPath);
    client.setTimeout(500, () => {
      client.destroy();
      reject(new Error('retired listener did not close connection'));
    });
    client.once('error', () => {
      client.destroy();
    });
    client.once('connect', () => client.write('{"type":"tell","text":"must not deliver"}\n'));
    client.once('close', () => resolve());
  });

describe('bridge Tidewave connection publication', () => {
  const manifest = () => _test.readManifest(_test.manifestForSocket(socketPath));

  test('publishes connections before the first prompt, regardless of startup ordering', async () => {
    for (const reason of ['startup', 'reload'] as const) {
      for (const order of [
        ['endpoint', 'start'],
        ['start', 'endpoint'],
      ]) {
        const runtime = harness();

        try {
          for (const step of order) {
            if (step === 'start') await runtime.start(reason);
            else runtime.events.get('pidewave:endpoint:v1')?.({ version: 1, endpoint: tidewaveEndpoint });
          }

          expect(manifest()?.tidewaveConnected).toBe(true);
          expect(manifest()?.tidewaveEndpoint).toEqual(tidewaveEndpoint);
          expect(manifest()?.pid).toBe(process.pid);
          expect(manifest()?.cwd).toBe(runtime.ctx.cwd);
        } finally {
          await runtime.stop();
        }
      }
    }
  });

  test('shutdown revokes the manifest before draining and ignores late callbacks', async () => {
    const runtime = harness();
    const endpointListener = runtime.events.get('pidewave:endpoint:v1');

    try {
      await runtime.start();
      runtime.connectTidewave();
      expect(manifest()?.tidewaveConnected).toBe(true);
      const stopping = runtime.stop();

      try {
        expect(manifest()?.tidewaveConnected).toBe(false);
        expect(manifest()?.tidewaveEndpoint).toBeUndefined();
        endpointListener?.({ version: 1, endpoint: tidewaveEndpoint });
        expect(manifest()?.tidewaveConnected).toBe(false);
        expect(manifest()?.tidewaveEndpoint).toBeUndefined();
      } finally {
        await stopping;
      }

      expect(manifest()).toBeNull();
    } finally {
      await runtime.stop();
    }
  });

  test('endpoint revocation and malformed events replace early and active grants', async () => {
    for (const early of [true, false]) {
      for (const event of [undefined, null, {}, { version: 1 }, { version: 2, endpoint: tidewaveEndpoint }]) {
        const runtime = harness();

        try {
          if (!early) await runtime.start();
          runtime.connectTidewave();
          runtime.events.get('pidewave:endpoint:v1')?.(event);

          if (early) await runtime.start();
          expect(manifest()?.tidewaveConnected).toBe(false);
          expect(manifest()?.tidewaveEndpoint).toBeUndefined();
        } finally {
          await runtime.stop();
        }
      }
    }
  });

  test('tool availability cannot grant or revoke connection authorization', async () => {
    const runtime = harness();

    try {
      await runtime.start();
      await runtime.beforeAgentStart(['mcp__tidewave']);
      expect(manifest()?.tidewaveConnected).toBe(false);
      runtime.connectTidewave();
      await runtime.beforeAgentStart([]);
      expect(manifest()?.tidewaveConnected).toBe(true);
    } finally {
      await runtime.stop();
    }
  });

  test('missing or unsafe connection endpoints revoke both manifest fields', async () => {
    const runtime = harness();

    const endpoints: unknown[] = [
      undefined,
      null,
      'http://localhost:4300/tidewave/mcp',
      {},
      { origin: 4300, pathname: '/tidewave/mcp' },
      { origin: tidewaveEndpoint.origin, pathname: null },
      ...[
        '',
        'not-a-url',
        'ftp://localhost:4300',
        'https://example.com:4300',
        'http://localhost.evil:4300',
        'http://localhost.:4300',
        'http://127.0.0.2:4300',
        'http://[::1]:4300',
        'http://127.1:4300',
        'http://2130706433:4300',
        'http://user:secret@localhost:4300',
        'http://localhost:4300?token=secret',
        'http://localhost:4300#secret',
        'http://localhost:4300?',
        'http://localhost:4300#',
        'http://localhost:4300/',
        'http://localhost:4300/tidewave/mcp',
        'http://localhost:0',
        'http://localhost:65536',
        'http://localhost:-1',
        'http://localhost:9832',
        'https://127.0.0.1:9832',
        'http://localhost:09832',
        'HTTP://LOCALHOST:4300',
        'http://localhost:04300',
        ' http://localhost:4300',
        'http://localhost:4300\n',
        'http://localhost:80',
      ].map((origin) => ({ origin, pathname: '/tidewave/mcp' })),
      ...[
        '/',
        '/mcp',
        '/tidewave/mcp/',
        '/tidewave/mcp?secret',
        '/tidewave/mcp#secret',
        '/tidewave/../tidewave/mcp',
        '/tidewave/%6dcp',
      ].map((pathname) => ({ origin: tidewaveEndpoint.origin, pathname })),
    ];

    try {
      await runtime.start();

      for (const endpoint of endpoints) {
        runtime.connectTidewave();
        expect(manifest()?.tidewaveConnected).toBe(true);
        expect(manifest()?.tidewaveEndpoint).toEqual(tidewaveEndpoint);
        runtime.events.get('pidewave:endpoint:v1')?.({ version: 1, endpoint });
        expect(manifest()?.tidewaveConnected).toBe(false);
        expect(manifest()?.tidewaveEndpoint).toBeUndefined();
      }
    } finally {
      await runtime.stop();
    }
  });

  test('changed safe endpoints publish immediately while remaining connected', async () => {
    const runtime = harness();

    try {
      await runtime.start();
      runtime.connectTidewave();

      for (const origin of [
        'http://localhost:4301',
        'https://127.0.0.1:4301',
        'http://localhost',
        'https://localhost',
        'http://127.0.0.1:1',
        'https://localhost:65535',
      ]) {
        const endpoint = { origin, pathname: '/tidewave/mcp' };
        runtime.events.get('pidewave:endpoint:v1')?.({ version: 1, endpoint });
        expect(manifest()?.tidewaveConnected).toBe(true);
        expect(manifest()?.tidewaveEndpoint).toEqual(endpoint);
      }
    } finally {
      await runtime.stop();
    }
  });

  test('early endpoint snapshots are copied and only the latest identity is published', async () => {
    const runtime = harness();
    const endpoint = { origin: 'https://127.0.0.1:4400', pathname: '/tidewave/mcp' };

    try {
      runtime.connectTidewave();
      runtime.connectTidewave(endpoint);
      endpoint.origin = 'https://example.com';
      await runtime.start('reload');
      expect(manifest()?.tidewaveConnected).toBe(true);
      expect(manifest()?.tidewaveEndpoint).toEqual({ origin: 'https://127.0.0.1:4400', pathname: '/tidewave/mcp' });
    } finally {
      await runtime.stop();
    }
  });

  test('reload clears authorization and retires the old endpoint subscriber', async () => {
    const first = harness();
    const oldEndpointListener = first.events.get('pidewave:endpoint:v1');

    try {
      await first.start();
      first.connectTidewave();
      expect(manifest()?.tidewaveConnected).toBe(true);
    } finally {
      await first.stop();
    }

    expect(first.events.has('pidewave:endpoint:v1')).toBe(false);
    expect(manifest()).toBeNull();

    const next = harness();

    try {
      await next.start('reload');
      expect(manifest()?.tidewaveConnected).toBe(false);
      expect(manifest()?.tidewaveEndpoint).toBeUndefined();
      oldEndpointListener?.({ version: 1, endpoint: tidewaveEndpoint });
      expect(manifest()?.tidewaveConnected).toBe(false);
      expect(manifest()?.tidewaveEndpoint).toBeUndefined();
      next.connectTidewave();
      expect(manifest()?.tidewaveConnected).toBe(true);
      expect(manifest()?.tidewaveEndpoint).toEqual(tidewaveEndpoint);
    } finally {
      await next.stop();
    }
  });

  test('connection events never overwrite a foreign manifest', async () => {
    const runtime = harness();
    const manifestPath = _test.manifestForSocket(socketPath);
    let original: string | undefined;

    try {
      await runtime.start();
      original = fs.readFileSync(manifestPath, 'utf8');
      fs.writeFileSync(manifestPath, JSON.stringify({ ...manifest(), owner: 'foreign', tidewaveConnected: false }));
      runtime.connectTidewave();
      expect(manifest()?.owner).toBe('foreign');
      expect(manifest()?.tidewaveConnected).toBe(false);
      expect(manifest()?.tidewaveEndpoint).toBeUndefined();
    } finally {
      if (original) fs.writeFileSync(manifestPath, original);
      await runtime.stop();
    }
  });
});

describe('bridge recovery and wire boundaries', () => {
  test('factory reuse after shutdown registers and publishes the loaded runtime', async () => {
    for (let cycle = 0; cycle < 2; cycle += 1) {
      const runtime = harness(`/test/cwd-${cycle}`);

      try {
        await runtime.start();
        expect(_test.readManifest(_test.manifestForSocket(socketPath))?.cwd).toBe(`/test/cwd-${cycle}`);
        expect(_test.readManifest(_test.manifestForSocket(socketPath))?.tidewaveConnected).toBe(false);

        if (cycle === 0) {
          await runtime.connectTidewave();
          expect(_test.readManifest(_test.manifestForSocket(socketPath))?.tidewaveConnected).toBe(true);
        }

        const identity = { version: 'tell-test', loadedAt: new Date().toISOString(), sourceHash: 'tell-hash' };
        runtime.events.get('tell:runtime')?.(identity);
        const pong = await request('{"type":"ping"}');
        expect(pong.ok).toBe(true);
        expect(pong.pid).toBe(process.pid);
        expect(pong.sessionId).toBe('test-session');
        expect(pong.idle).toBe(true);
        expect(pong.pending).toBe(false);
        expect(pong.runtime?.bridge.sourceHash).toMatch(/^[a-f0-9]{64}$/);
        expect(pong.runtime?.tell).toEqual(identity);
        expect(_test.readManifest(_test.manifestForSocket(socketPath))?.tell).toEqual(identity);
      } finally {
        await runtime.stop();
      }

      expect(fs.existsSync(socketPath)).toBe(false);
      expect(fs.existsSync(_test.manifestForSocket(socketPath))).toBe(false);
    }
  });

  test('restores a missing manifest, but never overwrites a foreign manifest', async () => {
    const runtime = harness();
    const manifestPath = _test.manifestForSocket(socketPath);

    try {
      await runtime.start();
      fs.unlinkSync(manifestPath);
      _test.checkRegistration(runtime.pi, runtime.ctx);
      const manifest = _test.readManifest(manifestPath);
      expect(manifest?.pid).toBe(process.pid);
      fs.writeFileSync(manifestPath, JSON.stringify({ ...manifest, owner: 'foreign' }));
      _test.checkRegistration(runtime.pi, runtime.ctx);
      expect(_test.readManifest(manifestPath)?.owner).toBe('foreign');
      await sendToRetiredListener();
      expect(runtime.persistedTexts).toEqual([]);
      await runtime.stop();
      await sendToRetiredListener();
      expect(runtime.persistedTexts).toEqual([]);
    } finally {
      await runtime.stop();
      fs.unlinkSync(socketPath);
      fs.unlinkSync(manifestPath);
    }
  });

  test("rebinds after the active listener's pathname disappears", async () => {
    const runtime = harness();

    try {
      await runtime.start();
      fs.unlinkSync(socketPath);
      _test.checkRegistration(runtime.pi, runtime.ctx);
      await _test.startServer(runtime.pi, runtime.ctx);
      expect(await _test.pingSocket(socketPath)).toBe(true);
    } finally {
      await runtime.stop();
    }
  });

  test('concurrent starts serialize stale reclaim and shutdown drains startup', async () => {
    staleSocket('test');
    const runtime = harness();

    try {
      await Promise.all([
        runtime.start(),
        _test.startServer(runtime.pi, runtime.ctx),
        _test.startServer(runtime.pi, runtime.ctx),
      ]);
      expect(await _test.pingSocket(socketPath)).toBe(true);
    } finally {
      await runtime.stop();
    }

    staleSocket('test');
    const replacement = harness();
    const pending = replacement.start();
    await replacement.stop();
    await pending;
    expect(await _test.pingSocket(socketPath)).toBe(false);
  });

  test('independent processes cannot reclaim or bind while another holds the startup claim', async () => {
    const socket = path.join(stateDir, 'sockets', 'contended.sock');
    const connections = new Set<net.Socket>();

    const blocker = net.createServer((client) => {
      connections.add(client);
      client.once('close', () => connections.delete(client));
    });

    await new Promise<void>((resolve) => blocker.listen(socket, resolve));
    fs.writeFileSync(
      _test.manifestForSocket(socket),
      JSON.stringify({ socket, pid: 2147483647, owner: 'dead-owner', heartbeatAt: new Date(0).toISOString() }),
    );
    const initialInode = fs.statSync(socket).ino;
    const first = contender(socket);
    const second = contender(socket);

    try {
      await Promise.all([first.waitFor('ready'), second.waitFor('ready')]);
      first.start();
      await first.waitFor('starting');
      expect(fs.existsSync(`${socket}.claim`)).toBe(true);
      second.start();
      await second.waitFor('started');
      expect(fs.statSync(socket).ino).toBe(initialInode);
      expect(_test.readManifest(_test.manifestForSocket(socket))?.owner).toBe('dead-owner');
      await first.waitFor('started');
      expect(_test.readManifest(_test.manifestForSocket(socket))?.pid).toBe(first.pid);
      expect(await _test.pingSocket(socket)).toBe(true);
      expect(_test.readManifest(_test.manifestForSocket(socket))?.pid).toBe(first.pid);
    } finally {
      await second.stop();
      await first.stop();

      for (const client of connections) client.destroy();
      await new Promise<void>((resolve) => blocker.close(() => resolve()));
    }

    // The losing contender may legitimately hold a retry claim while the
    // winner is alive. Claims must be gone only after both owners stop.
    expect(fs.existsSync(`${socket}.claim`)).toBe(false);
  });

  test('an abandoned claim blocks startup without touching stale socket evidence', async () => {
    const socket = staleSocket('test');
    const inode = fs.statSync(socket).ino;
    fs.writeFileSync(`${socket}.claim`, JSON.stringify({ owner: 'abandoned', pid: 2147483647 }));
    const runtime = harness();

    try {
      await runtime.start();
      expect(fs.statSync(socket).ino).toBe(inode);
      expect(_test.readManifest(_test.manifestForSocket(socket))?.owner).toBe('stale-owner');
      expect(fs.existsSync(`${socket}.claim`)).toBe(true);
    } finally {
      await runtime.stop();
      fs.unlinkSync(`${socket}.claim`);
      fs.unlinkSync(socket);
      fs.unlinkSync(_test.manifestForSocket(socket));
    }
  });

  test('discovery probes sockets rather than trusting a live pid', async () => {
    const dead = staleSocket('dead-live-pid', process.pid);
    const sessions = await _test.controlSessions();
    expect(sessions.find((entry) => entry.socket === dead)?.reachable).toBe(false);
    expect(await _test.canReclaim(dead)).toBe(false);
  });

  test('stale reclaim rejects recent or malformed owner evidence', async () => {
    const recent = staleSocket('recent', 2147483647, new Date().toISOString());
    const invalid = staleSocket('invalid', 2147483647, 'not-a-date');
    expect(await _test.canReclaim(recent)).toBe(false);
    expect(await _test.canReclaim(invalid)).toBe(false);
    fs.writeFileSync(_test.manifestForSocket(invalid), '{"socket":42}');
    expect(_test.readManifest(_test.manifestForSocket(invalid))).toBeNull();
    expect(await _test.canReclaim(invalid)).toBe(false);
    fs.writeFileSync(
      _test.manifestForSocket(invalid),
      JSON.stringify({ socket: invalid, pid: 2147483647, owner: 'old', startedAt: new Date(0).toISOString() }),
    );
    expect(await _test.canReclaim(invalid)).toBe(false);
    fs.writeFileSync(
      _test.manifestForSocket(invalid),
      JSON.stringify({ socket: invalid, pid: 2147483647, heartbeatAt: new Date(0).toISOString() }),
    );
    expect(await _test.canReclaim(invalid)).toBe(false);
  });

  test('decodes tell text split in the middle of a multibyte UTF-8 character', async () => {
    const runtime = harness();

    try {
      await runtime.start();
      const payload = JSON.stringify({ type: 'tell', text: 'hello 界😀' });
      const splitAt = Buffer.from(payload).indexOf(Buffer.from('界')) + 1;
      await request(payload, splitAt);
      expect(runtime.persistedTexts).toEqual(['hello 界😀']);
    } finally {
      await runtime.stop();
    }
  });

  test('rejects malformed ingress without delivery and retains legacy ping', async () => {
    const runtime = harness();

    try {
      await runtime.start();

      for (const payload of [
        'null',
        '[]',
        '{"type":"tell","text":12}',
        '{"type":"telegram","text":null}',
        '{"type":"control","params":{"text":{}}}',
        '{',
      ]) {
        expect((await request(payload)).ok).toBe(false);
      }

      const invalidControl = await request(
        '{"type":"control","protocol":"pi.control.v1","id":"bad-text","operation":"message.send","params":{"text":12}}',
      );

      expect(invalidControl).toMatchObject({
        ok: false,
        type: 'control_response',
        protocol: 'pi.control.v1',
        id: 'bad-text',
        operation: 'message.send',
      });
      expect((await request('{"type":"future"}')).error).toBe('unsupported payload type: future');
      expect((await request('{"type":"ping"}')).type).toBe('pong');
    } finally {
      await runtime.stop();
    }
  });
});

// ntfy runs on receipt; point it at nothing so tests never push notifications.
const withoutNtfy = <T>(run: () => T): T => {
  const env = { HOME: process.env.HOME, PATH: process.env.PATH };
  process.env.HOME = stateDir;
  process.env.PATH = '/nonexistent';

  try {
    return run();
  } finally {
    Object.assign(process.env, env);
  }
};

describe('bridge tell delivery', () => {
  type Details = Parameters<typeof _test.deliverTell>[2];

  const details = (mode: Details['mode'], source: Details['source'] = 'pi', from = 'work:1.1 (~/x)'): Details => ({
    id: 'tell-1',
    from,
    mode,
    source,
  });

  const recorder = (idle: boolean) => {
    const sent: Delivery[] = [];

    return {
      sent,
      pi: asExtensionAPI({
        sendMessage: (message: Delivery['message'], options: Delivery['options']) => {
          sent.push({ message, options });
        },
      }),
      ctx: asExtensionContext({ isIdle: () => idle }),
    };
  };

  test.each([
    [true, 'follow_up', 'started', { triggerTurn: true, deliverAs: 'followUp' }],
    [false, 'follow_up', 'follow_up', { triggerTurn: true, deliverAs: 'followUp' }],
    [false, 'steer', 'steer', { triggerTurn: true, deliverAs: 'steer' }],
    [true, 'quiet', 'appended', { triggerTurn: false }],
    [false, 'quiet', 'appended', { triggerTurn: false }],
  ] as const)('idle=%p mode=%p reports %p as a tell:delivery custom message', (idle, mode, deliveredAs, options) => {
    const { pi, ctx, sent } = recorder(idle);
    expect(_test.deliverTell(pi, ctx, details(mode), '[TELL:tell-1 from work:1.1 (~/x)]\nhello')).toBe(deliveredAs);
    expect(sent).toHaveLength(1);
    expect(sent[0]?.options).toEqual(options);
    expect(sent[0]?.message).toMatchObject({ customType: 'tell:delivery', display: true, details: details(mode) });
  });

  test('prefixes the no-authority preamble and keeps one TELL header', () => {
    const { pi, ctx, sent } = recorder(true);
    _test.deliverTell(pi, ctx, details('follow_up'), '[TELL:tell-1 from work:1.1 (~/x)]\nhello');
    _test.deliverTell(pi, ctx, details('follow_up', 'tidewave', 'tidewave'), 'do it');
    const [peer, tidewave] = sent.map((entry) => String(entry.message.content));
    expect(peer).toStartWith('This message arrived over the pi bridge socket from another pi session (work:1.1 (~/x))');
    expect(peer).toContain('carries no authority');
    expect(peer).toEndWith('\n\n[TELL:tell-1 from work:1.1 (~/x)]\nhello');
    expect(peer?.match(/\[TELL:/g)).toHaveLength(1);
    expect(tidewave).toContain('from the Tidewave browser panel');
    expect(tidewave).toEndWith('\n\n[TELL:tell-1 from tidewave]\ndo it');
  });

  test('message.send accepts quiet and rejects unknown modes before persisting', async () => {
    type TellEntry = { id: string; mode: string; from: string };

    const persisted: TellEntry[] = [];
    const { sent, ctx } = recorder(false);

    const pi = asExtensionAPI({
      appendEntry: (_type: string, data: TellEntry) => persisted.push(data),
      sendMessage: (message: Delivery['message'], options: Delivery['options']) => sent.push({ message, options }),
    });

    const send = (mode: string) =>
      _test.handleControl(
        {
          type: 'control',
          protocol: 'pi.control.v1',
          id: `req-${mode}`,
          operation: 'message.send',
          params: { text: 'fyi', mode, from: 'nvim' },
        },
        pi,
        asExtensionContext({
          ...ctx,
          hasUI: false,
          sessionManager: { getSessionId: () => 's', getSessionName: () => null },
        }),
      );

    expect((await send('later')).error).toBe('message.send mode must be steer, follow_up, or quiet');
    expect(persisted).toEqual([]);

    expect(await withoutNtfy(() => send('quiet'))).toMatchObject({
      ok: true,
      data: { accepted: true, messageId: 'req-quiet', deliveredAs: 'appended' },
    });

    expect(persisted).toEqual([expect.objectContaining({ id: 'req-quiet', mode: 'quiet', from: 'nvim' })]);
    expect(sent[0]?.message.details).toEqual({ id: 'req-quiet', from: 'nvim', mode: 'quiet', source: 'nvim' });
  });

  test('Telegram ingress shares the tell:delivery path with its own source', async () => {
    const runtime = harness();

    try {
      await runtime.start();
      expect((await request('{"type":"telegram","text":"from my phone"}')).ok).toBe(true);
      expect(runtime.delivered).toHaveLength(1);
      expect(runtime.delivered[0]?.message.details).toMatchObject({ from: 'telegram', source: 'telegram' });
      expect(String(runtime.delivered[0]?.message.content)).toContain('from Telegram, forwarded by Hammerspoon');
      expect(runtime.delivered[0]?.options).toEqual({ triggerTurn: true, deliverAs: 'followUp' });
    } finally {
      await runtime.stop();
    }
  });

  test('strips terminal escapes from peer text before notify and the widget', () => {
    const shown: string[] = [];

    const ctx = asExtensionContext({
      hasUI: true,
      sessionManager: { getSessionId: () => 's', getSessionName: () => null },
      ui: {
        theme: plainTheme,
        notify: (text: string) => shown.push(text),
        setWidget: (_key: string, lines: string[] | undefined) => shown.push(...(lines ?? [])),
      },
    });

    withoutNtfy(() =>
      _test.persistAndSurfaceTell(asExtensionAPI({ appendEntry: () => {} }), ctx, {
        type: 'tell',
        id: 'tell-1',
        from: 'evil\x1b[2J\x1b]0;title\x07 peer',
        text: '[TELL:tell-1 from evil]\nclear\x1b[2Jscreen\x00 now\x07',
      }),
    );

    expect(shown.filter((line) => /\p{Cc}/u.test(line))).toEqual([]);
    expect(shown).toContain('Tell from evil peer');
    expect(shown).toContain('clearscreen now');
  });

  test('inbound caps size, per-sender rate, and per-sender backlog', () => {
    expect(_test.admitInbound('cap-sender', 'x'.repeat(32 * 1024 + 1))).toContain('the cap is 32768');

    for (let i = 0; i < 8; i += 1) expect(_test.admitInbound('rate-sender', 'hi', 1_000)).toBeUndefined();
    expect(_test.admitInbound('rate-sender', 'hi', 1_000)).toContain('rate limited');
    expect(_test.admitInbound('other-sender', 'hi', 1_000)).toBeUndefined();
    expect(_test.admitInbound('rate-sender', 'hi', 31_001)).toBeUndefined();

    for (let i = 0; i < 50; i += 1) {
      expect(_test.admitInbound('busy-sender', 'hi', i * 4_000)).toBeUndefined();
      _test.countUnread('busy-sender', i % 2 ? 'follow_up' : 'appended');
    }

    expect(_test.admitInbound('busy-sender', 'hi', 400_000)).toContain('50 messages from busy-sender');
    _test.clearUnread();
    expect(_test.admitInbound('busy-sender', 'hi', 400_000)).toBeUndefined();
    _test.countUnread('busy-sender', 'started');
    expect(_test.admitInbound('busy-sender', 'hi', 404_000)).toBeUndefined();
  });

  test('message.send echoes replyTo in details, the header, and the session entry', async () => {
    const persisted: Array<{ replyTo?: string }> = [];
    const { sent, ctx } = recorder(true);

    const response = await withoutNtfy(() =>
      _test.handleControl(
        {
          type: 'control',
          protocol: 'pi.control.v1',
          id: 'answer',
          operation: 'message.send',
          params: { text: 'done', from: 'nvim', replyTo: 'tell-question' },
        },
        asExtensionAPI({
          events: { emit: () => {} },
          appendEntry: (_type: string, data: { replyTo?: string }) => persisted.push(data),
          sendMessage: (message: Delivery['message'], options: Delivery['options']) => sent.push({ message, options }),
        }),
        asExtensionContext({
          ...ctx,
          hasUI: false,
          sessionManager: { getSessionId: () => 's', getSessionName: () => null },
        }),
      ),
    );

    expect(response.ok).toBe(true);
    expect(persisted[0]?.replyTo).toBe('tell-question');
    expect(sent[0]?.message.details).toMatchObject({ id: 'answer', replyTo: 'tell-question' });
    expect(String(sent[0]?.message.content)).toEndWith('[TELL:answer reply to tell-question from nvim]\ndone');
  });

  test('drains spooled tells once, oldest first, skipping known ids and bad files', () => {
    const directory = path.join(stateDir, 'spool', encodeURIComponent('resumed/session'));
    fs.mkdirSync(directory, { recursive: true });

    type SpoolFile = { type: 'tell'; id?: string; text?: string; from?: string; sessionId?: string };

    const write = (id: string, value: SpoolFile) =>
      fs.writeFileSync(path.join(directory, `${id}.json`), JSON.stringify(value));

    write('tell-b', { type: 'tell', id: 'tell-b', text: 'second', from: 'peer', sessionId: 'p' });
    write('tell-a', { type: 'tell', id: 'tell-a', text: 'first', from: 'peer', sessionId: 'p' });
    write('tell-seen', { type: 'tell', id: 'tell-seen', text: 'again', from: 'peer' });
    write('tell-huge', { type: 'tell', id: 'tell-huge', text: 'x'.repeat(40_000) });
    write('tell-bad', { type: 'tell' });
    fs.writeFileSync(path.join(directory, 'notes.txt'), 'ignored');

    const persisted: string[] = [];
    const { sent } = recorder(true);

    const pi = asExtensionAPI({
      appendEntry: (_type: string, data: { id: string }) => persisted.push(data.id),
      sendMessage: (message: Delivery['message'], options: Delivery['options']) => sent.push({ message, options }),
    });

    const ctx = asExtensionContext({
      hasUI: false,
      isIdle: () => true,
      sessionManager: {
        getSessionId: () => 'resumed/session',
        getSessionName: () => null,
        getEntries: () => [{ type: 'custom', customType: 'tell-message', data: { id: 'tell-seen' } }],
      },
    });

    expect(withoutNtfy(() => _test.drainSpool(pi, ctx))).toBe(2);
    expect(persisted).toEqual(['tell-a', 'tell-b']);
    expect(sent.map((entry) => entry.options)).toEqual([
      { triggerTurn: true, deliverAs: 'followUp' },
      { triggerTurn: true, deliverAs: 'followUp' },
    ]);
    expect(fs.readdirSync(directory)).toEqual(['notes.txt']);
    expect(withoutNtfy(() => _test.drainSpool(pi, ctx))).toBe(0);
  });

  test('a reply claimed by a waiting ask_pi is answered, not delivered to the model', () => {
    const { sent, ctx } = recorder(false);
    const persisted: string[] = [];

    const pi = asExtensionAPI({
      events: {
        emit: (name: string, data: { replyTo: string; claimed: boolean }) => {
          if (name === 'tell:reply' && data.replyTo === 'tell-question') data.claimed = true;
        },
      },
      appendEntry: (_type: string, data: { id: string }) => persisted.push(data.id),
      sendMessage: (message: Delivery['message'], options: Delivery['options']) => sent.push({ message, options }),
    });

    const received = withoutNtfy(() =>
      _test.receiveTell(
        pi,
        asExtensionContext({
          ...ctx,
          hasUI: false,
          sessionManager: { getSessionId: () => 's', getSessionName: () => null },
        }),
        { type: 'tell', id: 'tell-answer', text: '42', from: 'peer', sessionId: 'ask-peer', replyTo: 'tell-question' },
      ),
    );

    expect(received).toMatchObject({ ok: true, deliveredAs: 'answered' });
    expect(persisted).toEqual(['tell-answer']);
    expect(sent).toEqual([]);
  });

  test('message.send refuses oversized text before persisting', async () => {
    const persisted: string[] = [];
    const { sent, ctx } = recorder(true);

    const response = await _test.handleControl(
      {
        type: 'control',
        protocol: 'pi.control.v1',
        id: 'huge',
        operation: 'message.send',
        params: { text: 'x'.repeat(40_000), from: 'tidewave' },
      },
      asExtensionAPI({ appendEntry: (type: string) => persisted.push(type) }),
      ctx,
    );

    expect(response.error).toContain('the cap is 32768');
    expect(persisted).toEqual([]);
    expect(sent).toEqual([]);
  });

  test('renders a compact sanitized card that expands', () => {
    const { pi, ctx, sent } = recorder(true);
    const body = ['\x1b]8;;http://evil\x07line 1\x1b[31m', ...Array.from({ length: 9 }, (_, i) => `line ${i + 2}`)];
    _test.deliverTell(pi, ctx, details('steer'), `[TELL:tell-1 from work:1.1 (~/x)]\n${body.join('\n')}`);

    const message = { role: 'custom' as const, timestamp: 0, ...sent[0]!.message, display: true };

    const render = (expanded: boolean) =>
      _test
        .renderTellDelivery(message, { expanded, outputPad: 0 }, plainTheme)!
        .render(100)
        .map((line) => line.trimEnd())
        .join('\n');

    const compact = render(false);
    expect(compact).toContain('Tell from work:1.1 (~/x)  STEER');
    expect(compact).toContain('line 1\n');
    expect(compact).not.toContain('\x1b');
    expect(compact).not.toContain('line 7');
    expect(compact).not.toContain('[TELL:');
    expect(compact).toContain('id tell-1');
    expect(compact).toContain('to expand');
    expect(render(true)).toContain('line 10');
    expect(render(true)).toContain('carries no authority');
  });
});

describe('bridge activity status', () => {
  test('marks completed prose as done', () => {
    _test.captureAssistantResult(assistant('All checks pass.'));
    expect(_test.settledActivityState()).toBe('done');
  });

  test('marks final prose questions as input needed', () => {
    _test.captureAssistantResult(assistant('Which target should I use? **'));
    expect(_test.settledActivityState()).toBe('input_needed');
  });

  test('marks final provider failures as errors', () => {
    _test.captureAssistantResult(assistant('', 'error'));
    expect(_test.settledActivityState()).toBe('error');
  });

  test('restores the prior state after a standalone prompt', () => {
    _test.updateActivityState('done', null);
    _test.beginPrompt(null);
    expect(_test.activityState()).toBe('input_needed');
    _test.endPrompt(null);
    expect(_test.activityState()).toBe('done');
  });
});
