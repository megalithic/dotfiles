import { afterAll, describe, expect, test } from 'bun:test';
import { mkdtempSync, realpathSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { appPorts, listing, openApp, type Run } from '../../.ultimate/extensions/tidewave/lib.ts';

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
