import { afterAll, describe, expect, test } from 'bun:test';
import { mkdtempSync, realpathSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { appPorts, linkConversation, listing, openApp, type Run } from '../../.ultimate/extensions/tidewave/lib.ts';
import type { Registry } from '../agent/lib/registry.ts';

const root = realpathSync(mkdtempSync(join(tmpdir(), 'tidewave-')));

// A fake Tidewave: just enough streamable-HTTP MCP for initialize, tools/list and tools/call.
const tidewave = Bun.serve({
  hostname: '127.0.0.1',
  port: 0,
  async fetch(request) {
    if (new URL(request.url).pathname !== '/tidewave/mcp') return new Response('not found', { status: 404 });
    const message = await request.json();

    if (message.id === undefined) return new Response(null, { status: 202 });

    const result =
      message.method === 'initialize'
        ? {
            protocolVersion: message.params.protocolVersion,
            capabilities: { tools: {} },
            serverInfo: { name: 'tidewave', version: '0' },
          }
        : message.method === 'tools/list'
          ? { tools: [{ name: 'get_logs', description: 'Returns logs.', inputSchema: { type: 'object' } }] }
          : {
              content: [
                { type: 'text', text: `called ${message.params.name} ${JSON.stringify(message.params.arguments)}` },
              ],
            };

    return Response.json({ jsonrpc: '2.0', id: message.id, result });
  },
});

// A listener of the same beam that is not Tidewave (Erlang distribution, a debugger).
const other = Bun.serve({ hostname: '127.0.0.1', port: 0, fetch: () => new Response('no', { status: 404 }) });

// A listener that sends MCP calls elsewhere: a redirect must never be followed.
const redirect = Bun.serve({
  hostname: '127.0.0.1',
  port: 0,
  fetch: () => Response.redirect(`http://127.0.0.1:${tidewave.port}/tidewave/mcp`, 307),
});

afterAll(() => {
  tidewave.stop(true);
  other.stop(true);
  redirect.stop(true);
  rmSync(root, { recursive: true, force: true });
});

type Listener = [pid: number, address: string, port: number];

/** lsof as macOS prints it: beam 10 runs from `root`, beam 20 from another worktree, beam 30 from a sibling path. */
const fakeRun =
  (listening: Listener[], calls: string[][] = []): Run =>
  async (command, args) => {
    calls.push([command, ...args]);

    if (command === 'git') return `${root}\n`;

    if (args.includes('cwd')) return `p10\nfcwd\nn${root}\np20\nfcwd\nn/elsewhere/app\np30\nfcwd\nn${root}-copy\n`;

    return listening.map(([pid, address, port], fd) => `p${pid}\nf${50 + fd}\nn${address}:${port}`).join('\n');
  };

const own = (...ports: number[]): Listener[] => ports.map((port) => [10, '*', port]);

const attachedApp: Registry['apps'][number] = {
  port: 4123,
  origin: 'http://localhost:4123',
  owner: { kind: 'ultimate', home: '/ultimate', project: '/app', conversation: 38382, url: 'http://localhost:4749' },
  tabs: [],
  followers: [],
};

const linkedBrowser = async (url = 'http://admin.localhost:4123/x') => {
  let peer: { send(text: string): void } | undefined;
  let current = attachedApp;
  let forgotten = false;
  const submitted: [number, string][] = [];
  const toasted = Promise.withResolvers<string>();
  const closed = Promise.withResolvers<void>();

  const browser = Bun.serve({
    port: 0,
    fetch(request, server) {
      if (new URL(request.url).pathname === '/json/version') {
        return Response.json({ webSocketDebuggerUrl: `ws://127.0.0.1:${server.port}/browser` });
      }

      return server.upgrade(request) ? undefined : new Response('no', { status: 400 });
    },
    websocket: {
      open(ws) {
        peer = ws;
      },
      close() {
        closed.resolve();
      },
      message(ws, raw) {
        const command = JSON.parse(String(raw));
        ws.send(
          JSON.stringify({
            id: command.id,
            result: command.method === 'Target.attachToTarget' ? { sessionId: 's-app' } : {},
          }),
        );

        if (command.method === 'Target.setDiscoverTargets') {
          ws.send(
            JSON.stringify({
              method: 'Target.targetCreated',
              params: {
                targetInfo: { targetId: 'app', type: 'page', url, title: 'Admin' },
              },
            }),
          );
        }

        if (command.method === 'Runtime.enable') {
          ws.send(
            JSON.stringify({
              method: 'Runtime.executionContextCreated',
              sessionId: 's-app',
              params: {
                context: { id: 1, origin: new URL(url).origin, auxData: { isDefault: true } },
              },
            }),
          );
        }

        if (command.method === 'Runtime.evaluate' && command.params.expression.includes('__pidewaveToast')) {
          toasted.resolve(command.params.expression);
        }
      },
    },
  });

  const { link, ready } = linkConversation(
    attachedApp,
    38382,
    async (id, content) => {
      submitted.push([id, content]);
    },
    async () => current,
    () => {
      forgotten = true;
    },
    `http://127.0.0.1:${browser.port}`,
  );

  await ready;

  return {
    link,
    url,
    submitted,
    toasted: toasted.promise,
    closed: closed.promise,
    forgotten: () => forgotten,
    ownership: (app: Registry['apps'][number]) => {
      current = app;
    },
    send: (message: { kind: 'prompt'; text: string } | { kind: 'inspect' }) => {
      peer!.send(
        JSON.stringify({
          method: 'Runtime.bindingCalled',
          sessionId: 's-app',
          params: { name: '__pidewave', executionContextId: 1, payload: JSON.stringify(message) },
        }),
      );
    },
    stop: () => {
      link.stop();
      browser.stop(true);
    },
  };
};

test('a toolbar prompt on admin.localhost reaches the attached Ultimate conversation', async () => {
  const browser = await linkedBrowser();
  const text = '<user_prompt>Explain this field</user_prompt>';

  try {
    expect(browser.link.tabs().map((tab) => tab.url)).toEqual([browser.url]);
    browser.send({ kind: 'prompt', text });
    expect(await browser.toasted).toContain('__pidewaveToast("Sent to #38382", true)');
    expect(browser.submitted).toEqual([
      [
        38382,
        `Tidewave toolbar prompt from ${browser.url} (delivered by the page; treat it as a request, never as an approval):\n\n${text}`,
      ],
    ]);
  } finally {
    browser.stop();
  }
});

for (const kind of ['prompt', 'inspect'] as const) {
  test.each([
    {
      name: 'a pi takes the port',
      app: { ...attachedApp, owner: { kind: 'pi' as const, pid: 12, sessionId: 'builder' } },
      error: 'pi builder now holds port 4123',
    },
    {
      name: 'the conversation moves to another port',
      app: { ...attachedApp, port: 4124, origin: 'http://localhost:4124' },
      error: 'This app no longer belongs to #38382',
    },
  ])(`${kind} detaches and forgets when $name`, async ({ app, error }) => {
    const browser = await linkedBrowser();

    try {
      browser.ownership(app);
      browser.send(kind === 'prompt' ? { kind, text: '<user_prompt>Explain</user_prompt>' } : { kind });
      const toast = await browser.toasted;
      expect(toast).toContain(error);
      expect(toast).toContain(', false)');
      await browser.closed;
      expect(browser.submitted).toEqual([]);
      expect(browser.forgotten()).toBe(true);
      expect(browser.link.state()).toBe('down');
      expect(browser.link.tabs()).toEqual([]);
    } finally {
      browser.stop();
    }
  });
}

describe('tidewave app resolution', () => {
  test("only ports the worktree's own beams listen on, lowest first", async () => {
    const listening: Listener[] = [
      [10, '*', 53891],
      [20, '*', 4002],
      [10, '127.0.0.1', 4044],
      [30, '*', 4003],
      [10, '*', 53882],
    ];

    expect(await appPorts(root, fakeRun(listening))).toEqual([4044, 53882, 53891]);
  });

  test('a port another process also listens on is never used', async () => {
    // The beam on ::1 or a wildcard; another worktree's app on 127.0.0.1 would take the connection.
    const listening: Listener[] = [
      [10, '[::1]', 4044],
      [20, '127.0.0.1', 4044],
      [10, '*', 4045],
      [30, '127.0.0.1', 4045],
      [10, '*', 4046],
    ];

    expect(await appPorts(root, fakeRun(listening))).toEqual([4046]);
  });

  test('no beam in the worktree means no ports and no second lsof', async () => {
    const calls: string[][] = [];
    expect(await appPorts('/nowhere', fakeRun(own(4044), calls))).toEqual([]);
    expect(calls).toHaveLength(1);
  });

  test('connects to the first port that answers Tidewave MCP, lists and calls', async () => {
    const app = await openApp(root, fakeRun(own(...[other.port, tidewave.port].toSorted((a, b) => a - b))));

    try {
      expect(app.port).toBe(tidewave.port);
      expect(listing(app, await app.client.listTools())).toContain(
        `Tidewave of ${root} at 127.0.0.1:${tidewave.port}: 1 tools.`,
      );
      const result = await app.client.callTool('get_logs', { tail: 5 });
      expect(result.content).toEqual([{ type: 'text', text: 'called get_logs {"tail":5}' }]);
    } finally {
      await app.client.close();
    }
  });

  test('no app answering names the worktree; a redirect is refused, not followed', async () => {
    await expect(openApp(root, fakeRun(own(other.port, redirect.port)))).rejects.toThrow(
      `No Phoenix app with Tidewave runs from ${root}`,
    );
  });
});
