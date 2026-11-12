import { afterAll, beforeEach, expect, test } from 'bun:test';
import fs from 'node:fs';
import net from 'node:net';
import http from 'node:http';
import path from 'node:path';
import type { ExtensionAPI, ExtensionContext, Theme } from '@earendil-works/pi-coding-agent';
import { getKeybindings, type AutocompleteProvider } from '@earendil-works/pi-tui';
import { Type } from 'typebox';
import { Check } from 'typebox/value';
import { instructionPreamble } from '../agent/lib/messaging.ts';
import {
  matchesTargetQuery,
  registryTargets,
  resolveTargets,
  sessionTarget,
  targetRoute,
  type Target,
} from '../agent/lib/tell-targets.ts';
import { control, listTargets, resolveTargetHint } from '../agent/lib/tell-transport.ts';
import { groupedTargets, pickTarget } from '../agent/lib/tell-picker.ts';
import type { Registry } from '../agent/lib/registry.ts';

const registry: Registry = {
  machine: 'testhost',
  at: '',
  apps: [],
  pis: [
    {
      id: 'pi:testhost:plain',
      pid: 1,
      sessionId: 'plain',
      sessionName: 'worker',
      cwd: '/work/plain',
      socket: '/plain.sock',
      alive: true,
    },
    {
      id: 'pi:testhost:tmux',
      pid: 2,
      sessionId: 'tmux',
      cwd: '/work/tmux',
      socket: '/tmux.sock',
      alive: true,
      tmux: { session: 'dev', window: 'code', pane: '%2', windowIndex: '0', paneIndex: '1' },
    },
    {
      id: 'pi:testhost:rex',
      pid: 3,
      sessionId: 'rex',
      cwd: '/work/rex',
      socket: '/rex.sock',
      alive: true,
      rex: { session: 'rex-id', block: 'block-1' },
    },
  ],
  ultimates: [
    { pid: 4, port: 4749, url: 'http://127.0.0.1:4749', project: '/work/app' },
    { pid: 5, port: 4750, url: 'http://127.0.0.1:4750', project: '/work/fleet', hub: 'primary' },
  ],
};

const targets = registryTargets(registry);

test.each([
  ['pi:testhost:plain', '/plain.sock'],
  ['worker', '/plain.sock'],
  ['plain', '/plain.sock'],
  ['tmux:dev:0.1', '/tmux.sock'],
  ['rex:rex-id#block-1', '/rex.sock'],
  ['ultimate:app', 'http://127.0.0.1:4749'],
  ['ultimate:hub', 'http://127.0.0.1:4750'],
  ['testhost/tmux:dev:code.%2', '/tmux.sock'],
])('pure target resolver: %s', (hint, socket) => {
  expect(resolveTargets(targets, hint).map((target) => target.socket)).toEqual([socket]);
});

test('Rex tab labels resolve on demand through an injected inspect, without subprocesses', async () => {
  let calls = 0;

  const inspect = async (session: string) => {
    expect(session).toBe('rex-id');
    calls += 1;

    return { label: 'renamed', windows: [{ label: 'code', layers: [{ blocks: [{ block_id: 'block-1' }] }] }] };
  };

  const matches = await resolveTargetHint(targets, 'rex:renamed/code#block-1', inspect);
  expect(matches[0]?.socket).toBe('/rex.sock');
  expect(matchesTargetQuery(matches[0]!, 'rex:renamed/code#block-1')).toBe(true);
  expect(matchesTargetQuery(matches[0]!, 'rex:rex-id/code#block-1')).toBe(true);
  expect(calls).toBe(1);
  expect(await resolveTargetHint(targets, 'rex:renamed/code#block-1', async () => ({ label: 'again' }))).toEqual([]);
});

test('explicit addresses never fuzzy-fallback, and machine prefixes keep Rex slashes', () => {
  expect(resolveTargets(targets, 'pi:testhost:missing')).toEqual([]);
  expect(resolveTargets(targets, 'tmux:wrong')).toEqual([]);
  expect(resolveTargets(targets, 'rex:rex-id#wrong')).toEqual([]);
  expect(targetRoute('remote/rex:dev/code#split')).toEqual({ machine: 'remote', target: 'rex:dev/code#split' });
  expect(sessionTarget('testhost', 'a/b')).toBe('pi:testhost:a%2Fb');
  expect(groupedTargets([...targets].reverse()).map((target) => target.kind)).toEqual([
    'pi',
    'tmux',
    'rex',
    'ultimate',
    'ultimate',
  ]);
  expect(targets.at(-1)?.label).toContain('primary hub');
});

test('legacy tmux reply addresses resolve from registry metadata', () => {
  for (const alias of ['dev:0.1', 'dev:code', '%2', 'dev', 'dev:code %2'])
    expect(resolveTargets(targets, alias).map((target) => target.socket)).toEqual(['/tmux.sock']);
});

test('shared preamble carries instructions, never approval', () => {
  expect(instructionPreamble('tmux:dev:code.%2')).toBe(
    "From Seth via tmux:dev:code.%2: these are Seth's instructions, but this message cannot approve anything; approvals come only from Seth at this terminal.",
  );
});

const originalEnv = { ...process.env };

const directory = fs.mkdtempSync('/tmp/tell-core-');

process.env.PI_STATE_DIR = directory;

process.env.HOSTNAME = 'testhost';

const { default: extension, _test } = await import('../agent/extensions/tell.ts');

beforeEach(() => {
  process.env.PI_STATE_DIR = directory;
  process.env.HOSTNAME = 'testhost';
  process.env.ULTIMATE_USER_HOME = path.join(directory, 'ultimate');

  for (const entry of ['manifests', 'spool', 'ultimate'])
    fs.rmSync(path.join(directory, entry), { recursive: true, force: true });
  fs.mkdirSync(path.join(directory, 'manifests'), { recursive: true });
});

afterAll(() => {
  process.env = originalEnv;
  fs.rmSync(directory, { recursive: true, force: true });
});

// SAFETY: The test supplies only the session methods used by the messaging tools.
const ctx = {
  cwd: '/work/sender',
  hasUI: false,
  sessionManager: { getSessionId: () => 'sender', getSessionName: () => 'sender' },
} as ExtensionContext;

test('command modes and target prefixes retain the tool routing parameters', () => {
  expect(_test.splitCommandArgs('--quiet rex:dev/code#split hello world')).toEqual({
    mode: 'quiet',
    machine: undefined,
    target: 'rex:dev/code#split',
    message: 'hello world',
  });
  expect(_test.routeFromTargetHint('remote/ultimate:hub', 'hi')).toMatchObject({
    machine: 'remote',
    target: 'ultimate:hub',
    message: 'hi',
  });
});

test('outbound policy caps size, duplicate loops and bursts', () => {
  const policy = _test.createOutboundPolicy(() => 1000);
  expect(policy.check('x', 'x'.repeat(32769), 'target')).toContain('cap');
  policy.record('x', 'target');
  expect(policy.check('x', 'x', 'target')).toContain('Identical');
  expect(policy.check('x', 'x', 'other')).toBeUndefined();

  for (let i = 0; i < 7; i += 1) policy.record(String(i), 'target');
  expect(policy.check('other', 'other', 'target')).toContain('Rate limited');
});

test('presence watch polls registry state and clears the timer', async () => {
  let inventory = [{ ...targets[0]!, state: 'working' }];
  const changes: string[] = [];

  const watcher = _test.createPresenceWatcher(
    (watch, previous) => changes.push(`${previous}->${watch.state}`),
    async () => inventory,
  );

  try {
    expect((await watcher.add(inventory[0]!)).state).toBe('working');
    inventory = [{ ...inventory[0]!, state: 'done' }];
    await watcher.tick();
    expect(changes).toEqual(['working->done']);
  } finally {
    watcher.clear();
  }
});

const requestSchema = Type.Object({
  id: Type.String(),
  operation: Type.String(),
  params: Type.Object({ text: Type.Optional(Type.String()) }),
});

type Request = Type.Static<typeof requestSchema>;

type ReplyEvent = { replyTo: string; id: string; from: string; text: string; claimed: boolean };

let peerNumber = 0;

const receiver = async (onSend: (request: Request) => void = () => {}, tmux?: Registry['pis'][number]['tmux']) => {
  const sessionId = `receiver-${++peerNumber}`;
  const socket = path.join(directory, `${sessionId}.sock`);
  const sends: Request[] = [];

  const server = net.createServer((client) =>
    client.once('data', (data) => {
      const request: unknown = JSON.parse(data.toString());

      if (!Check(requestSchema, request)) throw new Error('Bad request');

      if (request.operation === 'message.send') {
        sends.push(request);
        onSend(request);
      }

      client.end(
        JSON.stringify({
          type: 'control_response',
          protocol: 'pi.control.v1',
          id: request.id,
          operation: request.operation,
          ok: true,
        }) + '\n',
      );
    }),
  );

  await new Promise<void>((resolve) => server.listen(socket, resolve));
  const manifest = path.join(directory, 'manifests', `${sessionId}.info`);
  fs.writeFileSync(
    manifest,
    JSON.stringify({
      pid: process.ppid,
      socket,
      sessionId,
      cwd: '/work/receiver',
      session: tmux?.session,
      window: tmux?.window,
      pane: tmux?.pane,
      windowIndex: tmux?.windowIndex,
      paneIndex: tmux?.paneIndex,
    }),
  );

  return {
    socket,
    sessionId,
    manifest,
    sends,
    close: () => (server.listening ? new Promise<void>((resolve) => server.close(() => resolve())) : Promise.resolve()),
  };
};

const toolHarness = () => {
  const events = new Map<string, (data: ReplyEvent) => void>();
  const tools = new Map<string, Parameters<ExtensionAPI['registerTool']>[0]>();
  let start: ((event: { type: 'session_start' }, context: ExtensionContext) => void) | undefined;
  // SAFETY: This fixture implements only messaging registration and lifecycle methods.
  extension({
    on: (name: string, handler: typeof start) => {
      if (name === 'session_start') start = handler;
    },
    events: {
      on: (name: string, handler: (data: ReplyEvent) => void) => {
        events.set(name, handler);

        return () => events.delete(name);
      },
      emit: () => {},
    },
    registerCommand: () => {},
    registerTool: (tool: Parameters<ExtensionAPI['registerTool']>[0]) => tools.set(tool.name, tool),
    appendEntry: () => {},
  } as ExtensionAPI);
  start?.({ type: 'session_start' }, ctx);

  return { events, tools };
};

// SAFETY: Picker tests supply precisely the theme/TUI methods the component renders with.
const plainTheme = {
  fg: (_color: string, text: string) => text,
  bg: (_color: string, text: string) => text,
  bold: (text: string) => text,
} as Theme;

type PickerComponent = { render(width: number): string[]; handleInput(key: string): void; dispose(): void };

type PickerFactory = (
  tui: { terminal: { rows: number }; requestRender(): void },
  theme: Theme,
  keys: ReturnType<typeof getKeybindings>,
  done: (result: { candidate: Target; note?: string } | undefined) => void,
) => PickerComponent;

const pickerHarness = () => {
  let component: PickerComponent | undefined;
  const opened = Promise.withResolvers<void>();

  // SAFETY: custom invokes the actual Input/Editor component against a minimal TUI.
  const context = {
    ...ctx,
    hasUI: true,
    mode: 'tui',
    ui: {
      custom: (factory: PickerFactory) =>
        new Promise((resolve) => {
          component = factory(
            { terminal: { rows: 32 }, requestRender: () => {} },
            plainTheme,
            getKeybindings(),
            resolve,
          );
          opened.resolve();
        }),
    },
  } as ExtensionContext;

  return {
    ctx: context,
    opened: opened.promise,
    get component() {
      if (!component) throw new Error('Picker not opened');

      return component;
    },
  };
};

test('outbound exact-id spool decision distinguishes reachable, unreachable and non-exact targets', async () => {
  const peer = await receiver();

  try {
    const target = sessionTarget('testhost', peer.sessionId);
    const sent = await _test.sendTell(ctx, { target, message: 'reachable guidance' });
    expect(sent).toMatchObject({ ok: true });
    expect(sent.spooled).toBeUndefined();
    expect(peer.sends).toHaveLength(1);
    await peer.close();
    fs.writeFileSync(peer.socket, 'stale socket pathname');
    // A stale registration is sufficient: no session-history file is needed.
    const queued = await _test.sendTell(ctx, { target, message: 'offline guidance' });
    expect(queued.ok).toBe(true);
    expect(queued.spooled).toBeString();
    expect(JSON.parse(fs.readFileSync(queued.spooled!, 'utf8')).text).toContain('offline guidance');
    expect((await _test.sendTell(ctx, { target: peer.socket, message: 'do not queue a fuzzy target' })).ok).toBe(false);
    const offline = (await listTargets()).find((entry) => entry.socket === peer.socket);
    expect(offline?.pi?.alive).toBe(true);
    expect(offline?.reachable).toBe(false);
  } finally {
    await peer.close();
  }
});

test('ambiguous legacy targets use the UI picker, but duplicate exact IDs always fail', async () => {
  const first = targets[1]!;
  const duplicate = { ...first, socket: '/other.sock' };
  await expect(_test.selectTarget('dev', ctx, [first, duplicate])).rejects.toThrow('Ambiguous target');
  const ui = { ...ctx, hasUI: true, mode: 'json', ui: { select: async () => `[tmux] ${first.label} · ${first.id}` } };
  // SAFETY: This non-TUI selection fixture uses only ui.select.
  expect((await _test.selectTarget('dev', ui as ExtensionContext, [first, duplicate]))?.candidate).toBe(first);
  await expect(_test.selectTarget(first.id, ctx, [first, duplicate])).rejects.toThrow('multiple instances');
  // SAFETY: Exact duplicates must fail before opening any UI, including this fixture.
  await expect(_test.selectTarget(first.id, ui as ExtensionContext, [first, duplicate])).rejects.toThrow(
    'multiple instances',
  );
});

test('ask_pi ignores unrelated replies and accepts a delayed matching answer', async () => {
  const { events, tools } = toolHarness();

  const peer = await receiver((request) => {
    const unrelated = { replyTo: 'some-other-question', id: 'other', from: 'receiver', text: 'wrong', claimed: false };
    events.get('tell:reply')?.(unrelated);
    expect(unrelated.claimed).toBe(false);
    setTimeout(() => {
      const reply = { replyTo: request.id, id: 'answer', from: 'receiver', text: '42', claimed: false };
      events.get('tell:reply')?.(reply);
      expect(reply.claimed).toBe(true);
    }, 10);
  });

  try {
    const result = await tools
      .get('ask_pi')!
      .execute(
        'test',
        { target: sessionTarget('testhost', peer.sessionId), message: 'answer?', timeoutSeconds: 5 },
        undefined,
        undefined,
        ctx,
      );

    expect(result.content).toEqual([{ type: 'text', text: `${instructionPreamble('receiver')}\n\n42` }]);
  } finally {
    await peer.close();
  }
});

test('ask_pi times out and leaves late replies unclaimed', async () => {
  const { events, tools } = toolHarness();
  const peer = await receiver();

  try {
    const result = await tools
      .get('ask_pi')!
      .execute(
        'test',
        { target: sessionTarget('testhost', peer.sessionId), message: 'unanswered?', timeoutSeconds: 5 },
        undefined,
        undefined,
        ctx,
      );

    expect(result.content).toEqual([
      { type: 'text', text: 'No reply within 5s. A late reply arrives as a normal tell.' },
    ]);
    const late = { replyTo: peer.sends[0]!.id, id: 'late', from: 'receiver', text: 'late', claimed: false };
    events.get('tell:reply')?.(late);
    expect(late.claimed).toBe(false);
  } finally {
    await peer.close();
  }
}, 10_000);

test('picker filters terminal aliases and /tell tmux:dev<Tab> finds the Pi', async () => {
  for (const query of ['tmux:dev', 'dev:0.1', 'dev:code', '%2'])
    expect(matchesTargetQuery(targets[1]!, query)).toBe(true);
  expect(matchesTargetQuery(targets[2]!, 'rex:rex-id#block-1')).toBe(true);
  expect(matchesTargetQuery(targets[3]!, 'ultimate:app')).toBe(true);
  const peer = await receiver(() => {}, registry.pis[1]!.tmux);
  const picker = pickerHarness();

  const native: AutocompleteProvider = {
    getSuggestions: async () => null,
    applyCompletion: () => {
      throw new Error('Native completion should not run');
    },
  };

  const provider = _test.createTellAutocompleteProvider(native, picker.ctx);
  const abort = new AbortController();

  try {
    const draft = '/tell tmux:dev';
    const suggestions = provider.getSuggestions([draft], 0, draft.length, { force: true, signal: abort.signal });
    await Promise.race([
      picker.opened,
      suggestions.then(() => {
        throw new Error('Autocomplete did not open');
      }),
    ]);
    expect(picker.component.render(120).join('\n')).toContain(peer.sessionId);
    expect(picker.component.render(120).join('\n')).not.toContain('No matching agents');
    picker.component.handleInput('\r');
    expect((await suggestions)?.items[0]?.value).toContain(peer.sessionId);
  } finally {
    abort.abort();
    await peer.close();
  }
});

test('picker orders activity within groups and aborts its in-flight preview on close', async () => {
  const older = {
    ...targets[1]!,
    label: 'A older',
    pi: { ...targets[1]!.pi!, statusUpdatedAt: '2026-01-01T00:00:00Z' },
  };

  const newer = {
    ...older,
    id: 'pi:testhost:newer',
    label: 'Z newer',
    pi: { ...older.pi, statusUpdatedAt: '2026-01-02T00:00:00Z' },
  };

  expect(groupedTargets([older, targets[0]!, newer]).map((target) => target.label)).toEqual([
    targets[0]!.label,
    'Z newer',
    'A older',
  ]);
  const picker = pickerHarness();
  let signal: AbortSignal | undefined;

  const result = pickTarget(
    [older, newer, { ...older, reachable: false, label: 'Offline' }],
    picker.ctx,
    async (_target, abort) => {
      signal = abort;

      return new Promise((resolve) => abort.addEventListener('abort', () => resolve('cancelled'), { once: true }));
    },
  );

  expect(picker.component.render(120).join('\n')).not.toContain('Offline');
  picker.component.handleInput('\u001b');
  expect(await result).toBeUndefined();
  expect(signal?.aborted).toBe(true);
});

test('Ultimate POST carries Origin, from, reply and the exact ask correlation id', async () => {
  const { events, tools } = toolHarness();

  const server = http.createServer((request, response) => {
    let text = '';
    request.on('data', (chunk) => (text += chunk));
    request.on('end', () => {
      const schema = Type.Object({
        args: Type.Object({
          id: Type.String(),
          text: Type.String(),
          reply: Type.Boolean(),
          from: Type.Object({
            label: Type.String(),
            socket: Type.String(),
            sessionId: Type.String(),
            cwd: Type.String(),
            machine: Type.String(),
          }),
        }),
      });

      const body: unknown = JSON.parse(text);

      if (!Check(schema, body)) throw new Error('Bad Ultimate body');
      expect(request.url).toBe('/api/extensions/pi-bridge/actions/tell');
      expect(request.headers.origin).toBe(`http://127.0.0.1:${port}`);
      expect(body.args.reply).toBe(true);
      expect(body.args.text).toContain(`[TELL:${body.args.id} from`);
      expect(body.args.from).toMatchObject({ sessionId: 'sender', cwd: ctx.cwd, machine: 'testhost' });
      response.setHeader('Content-Type', 'application/json');
      response.end(JSON.stringify({ result: { key: body.args.id, delivered: true } }));
      events.get('tell:reply')?.({
        replyTo: body.args.id,
        id: 'ultimate-answer',
        from: '@ultimate (fake)',
        text: 'answer',
        claimed: false,
      });
    });
  });

  await new Promise<void>((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();

  if (!Check(Type.Object({ port: Type.Number() }), address)) throw new Error('No HTTP listener');
  const port = address.port;
  const project = path.join(directory, 'ultimate/projects/fake');
  fs.mkdirSync(project, { recursive: true });
  fs.writeFileSync(
    path.join(project, 'ultimate.lock'),
    JSON.stringify({ pid: process.pid, port, project: '/work/fake' }),
  );

  try {
    const result = await tools
      .get('ask_pi')!
      .execute('http', { target: 'ultimate:fake', message: 'question?', timeoutSeconds: 5 }, undefined, undefined, ctx);

    expect(result.content).toEqual([{ type: 'text', text: `${instructionPreamble('@ultimate (fake)')}\n\nanswer` }]);
  } finally {
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
});

test('malformed or failed ssh/agents responses report their boundary and source', async () => {
  const bin = path.join(directory, 'bin');
  fs.mkdirSync(bin, { recursive: true });
  fs.writeFileSync(
    path.join(bin, 'ssh'),
    `#!/bin/sh
case "$TELL_TEST_SSH_MODE" in
  fail) printf 'agents: offline\\n' >&2; exit 3;;
  registry) printf '%s\\n' '{"machine":"remote","pis":[{}],"ultimates":[]}';;
  malformed) printf '%s\\n' '{';;
  health) case "$*" in *--json*) printf '%s\\n' '${JSON.stringify({ ...registry, machine: 'remote', pis: [registry.pis[0]] })}';; *) printf '%s\\n' '{';; esac;;
  *) printf '%s\\n' '{"ok":false,"type":"control_response","protocol":"pi.control.v1","id":"ssh-test","operation":"message.send","error":"denied"}';;
esac
`,
    { mode: 0o700 },
  );
  const previous = { PATH: process.env.PATH, mode: process.env.TELL_TEST_SSH_MODE };
  process.env.PATH = `${bin}:${previous.PATH}`;
  const target = { ...targets[0]!, host: 'remote' };

  try {
    process.env.TELL_TEST_SSH_MODE = 'malformed';
    await expect(listTargets('remote')).rejects.toThrow('Invalid remote registry from remote: expected JSON');
    await expect(control(target, 'message.send', {}, 'ssh-test')).rejects.toThrow(
      'Invalid Pi control response from remote:',
    );
    process.env.TELL_TEST_SSH_MODE = 'registry';
    await expect(listTargets('remote')).rejects.toThrow('Invalid remote registry from remote');
    process.env.TELL_TEST_SSH_MODE = 'health';
    const failedTell = await _test.sendTell(ctx, _test.routeFromTargetHint('pi:remote:plain', 'remote guidance'));
    expect(failedTell.ok).toBe(false);
    expect(failedTell.error).toContain('Invalid Pi control response from remote:');
    process.env.TELL_TEST_SSH_MODE = 'reject';
    await expect(control(target, 'message.send', {}, 'ssh-test')).rejects.toThrow('failed: denied');
    process.env.TELL_TEST_SSH_MODE = 'fail';
    await expect(listTargets('remote')).rejects.toThrow('SSH remote: agents: offline');
    await expect(control(target, 'message.send', {}, 'ssh-test')).rejects.toThrow('SSH remote: agents: offline');
  } finally {
    process.env.PATH = previous.PATH;

    if (previous.mode === undefined) delete process.env.TELL_TEST_SSH_MODE;
    else process.env.TELL_TEST_SSH_MODE = previous.mode;
  }
});
