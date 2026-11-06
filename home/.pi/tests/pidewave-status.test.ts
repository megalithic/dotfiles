import { afterEach, describe, expect, test } from 'bun:test';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createRequire } from 'node:module';
import net from 'node:net';
import { createInterface } from 'node:readline';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import { stripVTControlCharacters } from 'node:util';

const stateDir = fs.mkdtempSync('/tmp/pi-pidewave-test-');

// SAFETY: Fixtures intentionally implement only the status API members they exercise.
const asExtensionAPI = <T>(value: T): ExtensionAPI => value as ExtensionAPI;

// SAFETY: Fixtures intentionally implement only the status context members they exercise.
const asExtensionContext = <T>(value: T): ExtensionContext => value as ExtensionContext;

const originalEnv = { ...process.env };

const installed = createRequire(import.meta.url);

const { createJiti } = installed('jiti');

const jiti = createJiti(import.meta.url, {
  moduleCache: false,
  alias: {
    '@earendil-works/pi-tui': installed.resolve('@earendil-works/pi-tui'),
    'typebox/value': installed.resolve('typebox/value'),
    typebox: installed.resolve('typebox'),
  },
});

const { visibleWidth } = await jiti.import('@earendil-works/pi-tui');

const { default: customFooter } = await jiti.import('../agent/extensions/custom-footer.ts');

const cleanups: (() => void | Promise<void>)[] = [];

afterEach(async () => {
  for (const cleanup of cleanups.splice(0).reverse()) await cleanup();
  process.env = { ...originalEnv };
  // Preserve temporary fixtures for failure inspection.
});

type Hook = (event: { reason?: 'startup' | 'reload' }, ctx: ExtensionContext) => void;

const lifecycle = () => {
  const hooks = new Map<string, Hook>();

  // SAFETY: Only lifecycle and command registration, shared events and getThinkingLevel are used.
  const pi = asExtensionAPI({
    events: { emit: () => {}, on: () => () => {} },
    on: (name: string, hook: Hook) => {
      hooks.set(name, hook);
    },
    registerCommand: () => {},
    getThinkingLevel: () => 'off',
  });

  return { pi, fire: (name: string, ctx: ExtensionContext) => hooks.get(name)?.({}, ctx) };
};

let fixtureId = 0;

const url = 'http://localhost:4000';

const writeLease = (root: string, socket: string | null, port = 4000 + fixtureId) => {
  const dir = path.join(stateDir, 'pidewave', 'ports');
  fs.mkdirSync(dir, { recursive: true });
  fs.writeFileSync(
    path.join(dir, `${port}.json`),
    JSON.stringify({
      v: 1,
      port,
      origin: `http://localhost:${port}`,
      root,
      cwd: root,
      pid: process.pid,
      sessionId: 'session-1',
      sessionName: 'holder',
      tellId: 'pi:test:session-1',
      socket,
      terminal: { kind: 'plain' },
      claimedAt: new Date().toISOString(),
      browser: { cdp: 'off', tabs: [] },
      lastPromptAt: null,
    }),
  );
};

const acpHarness = () => {
  const entry = fileURLToPath(new URL('../agent/extensions/pidewave/acp.ts', import.meta.url));

  const child = spawn(process.execPath, [entry], {
    cwd: stateDir,
    env: { ...process.env, PI_STATE_DIR: stateDir },
    stdio: ['pipe', 'pipe', 'pipe'],
  });

  const lines = createInterface({ input: child.stdout });
  const output = lines[Symbol.asyncIterator]();

  cleanups.push(async () => {
    lines.close();

    if (child.exitCode === null && child.signalCode === null) {
      const exited = once(child, 'exit');
      child.kill();
      await exited;
    }
  });

  return {
    send: (text: string) => child.stdin.write(`${text}\n`),
    read: async () => {
      const line = await output.next();
      expect(line.done).toBe(false);

      return JSON.parse(line.value!);
    },
  };
};

describe('standalone ACP boundaries', () => {
  test('initializes without Pi runtime imports and ignores malformed envelopes and notifications', async () => {
    const cli = acpHarness();

    for (const line of [
      '{',
      'null',
      '[]',
      '123',
      '{"method":1}',
      '{"method":"initialize","id":{}}',
      '{"method":"initialize"}',
      '{"method":"session/cancel","id":91}',
      '{"method":"$/cancel","id":92}',
    ]) {
      cli.send(line);
    }

    cli.send(JSON.stringify({ id: 1, method: 'initialize', params: { protocolVersion: 99 } }));
    expect(await cli.read()).toMatchObject({
      jsonrpc: '2.0',
      id: 1,
      result: {
        protocolVersion: 1,
        authMethods: [],
        agentCapabilities: { loadSession: false },
      },
    });
    cli.send(JSON.stringify({ id: 'auth', method: 'authenticate' }));
    expect(await cli.read()).toEqual({ jsonrpc: '2.0', id: 'auth', result: {} });

    for (const method of ['unsupported', 'toString', 'constructor', '__proto__']) {
      cli.send(JSON.stringify({ id: method, method }));
      expect(await cli.read()).toMatchObject({ id: method, error: { code: -32601 } });
    }

    cli.send(JSON.stringify({ id: 2, method: 'session/prompt', params: { sessionId: 123 } }));
    expect(await cli.read()).toMatchObject({ id: 2, error: { code: -32602 } });
  });

  test.each(['{"ok":true}', '{"ok":false,"error":"denied"}', '{"ok":"true"}', 'null', '{'])(
    'forwards decoded content and handles bridge response %s',
    async (response) => {
      const cwd = path.join(stateDir, `Work Tree_${++fixtureId}`);
      const socketPath = path.join(stateDir, `bridge-${fixtureId}.sock`);
      const requests: string[] = [];

      const server = net.createServer((peer) => {
        let buffer = '';
        peer.on('data', (chunk) => {
          buffer += chunk.toString();

          if (!buffer.includes('\n')) return;

          requests.push(buffer.trim());
          peer.end(`${response}\n`);
        });
      });

      server.listen(socketPath);
      await once(server, 'listening');
      cleanups.push(
        () =>
          new Promise<void>((resolve) => {
            server.close(() => resolve());
          }),
      );
      writeLease(cwd, socketPath);
      const cli = acpHarness();
      cli.send(JSON.stringify({ id: 1, method: 'session/new', params: { cwd: path.join(cwd, 'lib') } }));
      const session = await cli.read();
      const sessionId = session.result.sessionId;
      expect(sessionId).toStartWith('pidewave-');
      cli.send(
        JSON.stringify({
          id: 2,
          method: 'session/prompt',
          params: {
            sessionId,
            prompt: [
              { type: 'text', text: 'hello' },
              { type: 'resource_link', uri: 'file:///link' },
              { type: 'resource', resource: { text: 'context' } },
              { type: 'resource', resource: { uri: 'file:///embedded' } },
              null,
              123,
              { type: 'text', text: 123 },
              { type: 'resource', resource: { text: { invalid: true } } },
            ],
          },
        }),
      );
      const update = await cli.read();
      expect(update).toMatchObject({
        method: 'session/update',
        params: {
          sessionId,
          update: { sessionUpdate: 'agent_message_chunk', content: { type: 'text' } },
        },
      });
      const detail = update.params.update.content.text;
      expect(detail).toContain(
        response === '{"ok":true}' ? 'Forwarded' : response.includes('denied') ? 'denied' : 'did not accept',
      );
      expect(await cli.read()).toMatchObject({ id: 2, result: { stopReason: 'end_turn' } });
      expect(requests).toHaveLength(1);
      expect(JSON.parse(requests[0]!)).toMatchObject({
        type: 'control',
        protocol: 'pi.control.v1',
        operation: 'message.send',
        params: { text: 'hello\nfile:///link\ncontext\nfile:///embedded', mode: 'follow_up', from: 'tidewave' },
      });

      cli.send(
        JSON.stringify({
          id: 3,
          method: 'session/prompt',
          params: { sessionId, prompt: [{ type: 'text', text: false }] },
        }),
      );
      expect((await cli.read()).params.update.content.text).toContain('Empty prompt');
      expect(await cli.read()).toMatchObject({ id: 3, result: { stopReason: 'end_turn' } });
      expect(requests).toHaveLength(1);
    },
  );
});

const colors = new Map([
  ['accent', '\x1b[36m'],
  ['muted', '\x1b[90m'],
  ['success', '\x1b[32m'],
]);

const theme = {
  fg: (name: string, text: string) => `${colors.get(name) || '\x1b[37m'}${text}\x1b[0m`,
  bold: (text: string) => `\x1b[1m${text}\x1b[22m`,
};

const footerHarness = (statuses: Map<string, string>) => {
  const { pi, fire } = lifecycle();
  let component: { render(width: number): string[]; dispose(): void };

  // SAFETY: Rendering uses only these context fields; UI callbacks receive real footer code.
  const ctx = asExtensionContext({
    // A missing cwd makes the asynchronous starship spawn fail without executing it.
    cwd: path.join(stateDir, 'missing-footer-cwd'),
    hasUI: true,
    sessionManager: { getSessionName: () => '', getEntries: () => [] },
    getContextUsage: () => ({ tokens: 0, contextWindow: 1000, percent: 0 }),
    model: { provider: 'test', id: 'test-model', reasoning: false },
    ui: {
      setStatus: () => {},
      setFooter: (factory: Function) => {
        component = factory({ requestRender: () => {} }, theme, {
          getExtensionStatuses: () => statuses,
          onBranchChange: () => () => {},
        });
      },
    },
  });

  cleanups.push(() => {
    component?.dispose();
    fire('session_shutdown', ctx);
  });
  customFooter(pi);
  fire('session_start', ctx);

  return (width = 240) => component.render(width);
};

const blue = (text: string) => `\x1b[38;2;81;173;229m${text}\x1b[39m`;

const status = (boundHere = true, appUrl = 'https://app.test:4443/path?query=hidden#fragment', connected?: boolean) =>
  JSON.stringify({ url: appUrl, boundHere, connected });

describe('pidewave footer rendering', () => {
  test.each([true, false])('icon and port occur once, first among extension statuses, boundHere=%p', (boundHere) => {
    const render = footerHarness(
      new Map([
        ['pidewave', status(boundHere, undefined, true)],
        ['z-status', 'last'],
        ['n-status', 'between'],
        ['a-status', 'first'],
      ]),
    );

    const line = render()[1]!;
    const plain = stripVTControlCharacters(line);
    expect(plain).toContain('\u{F1A81} 4443 │ first │ between │ last');
    expect(plain.match(/4443/g)).toHaveLength(1);
    expect(line).toContain(boundHere ? blue('\u{F1A81} 4443') : theme.fg('dim', '\u{F1A81} 4443'));
    expect(plain).not.toContain('app.test');
    expect(plain).not.toContain('query');
    expect(plain).not.toContain('boundHere');
  });

  test.each([true, false])('a binding without a live Tidewave connection shows nothing, boundHere=%p', (boundHere) => {
    const line = footerHarness(
      new Map([
        ['mcp', 'MCP 0/3'],
        ['pidewave', status(boundHere)],
      ]),
    )()[1]!;

    const plain = stripVTControlCharacters(line);
    expect(plain).not.toContain('4443');
    expect(plain).toContain('0/3');
  });

  test.each([undefined, 'MCP connecting...', 'MCP: 2 servers enabled (1 connected)'])(
    'shows port even when canonical MCP is absent or unparsed (%p)',
    (mcp) => {
      const statuses = new Map([['pidewave', status(false, url, true)]]);

      if (mcp !== undefined) statuses.set('mcp', mcp);
      const line = footerHarness(statuses)()[1]!;
      expect(line).toContain(theme.fg('dim', '\u{F1A81} 4000'));
      expect(stripVTControlCharacters(line)).not.toContain('boundHere');
    },
  );

  test('connected is blue when bound here and dim otherwise', () => {
    expect(footerHarness(new Map([['pidewave', status(true, url, true)]]))()[1]).toContain(blue('\u{F1A81} 4000'));
    expect(footerHarness(new Map([['pidewave', status(false, url, true)]]))()[1]).toContain(
      theme.fg('dim', '\u{F1A81} 4000'),
    );
  });

  test.each([
    '{',
    'null',
    '[]',
    '{}',
    JSON.stringify({ url, boundHere: 'true' }),
    JSON.stringify({ url: 4000, boundHere: true }),
    JSON.stringify({ url, boundHere: true, connected: 'yes' }),
    status(true, 'not a URL'),
    status(true, 'ftp://app.test'),
    status(true, 'javascript:alert(1)'),
    status(true, 'file:///tmp/app'),
    status(true, 'https://user:secret@app.test'),
    status(true, 'http://user@app.test'),
    status(true, 'http://:secret@app.test'),
  ])('suppresses invalid status %p without leaking raw data', (invalid) => {
    const statuses = new Map([['mcp', 'MCP 2/3']]);
    const render = footerHarness(statuses);
    const withoutStatus = render();
    statuses.set('pidewave', invalid);
    expect(render()).toEqual(withoutStatus);
    statuses.delete('mcp');
    statuses.delete('pidewave');
    const standalone = render();
    statuses.set('pidewave', invalid);
    expect(render()).toEqual(standalone);
  });

  test('falls back to the default port and stays within narrow terminal widths', () => {
    const render = footerHarness(
      new Map([
        ['other', 'ok'],
        ['pidewave', status(true, 'http://LOCALHOST:80/path', true)],
      ]),
    );

    expect(stripVTControlCharacters(render()[1]!)).toContain('\u{F1A81} 80 │ ok');

    for (const width of [1, 2, 3, 8, 16, 30, 40, 60, 80]) {
      const lines = render(width);
      expect(lines).toHaveLength(2);

      for (const line of lines) expect(visibleWidth(line)).toBeLessThanOrEqual(width);
      expect(stripVTControlCharacters(lines.join('\n'))).not.toContain('boundHere');
    }
  });
});
