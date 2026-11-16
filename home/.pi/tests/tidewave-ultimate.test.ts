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

afterAll(() => {
  tidewave.stop(true);
  other.stop(true);
  rmSync(root, { recursive: true, force: true });
});

/** lsof as macOS prints it: beam 10 runs from `root`, beam 20 from another worktree, beam 30 from a sibling path. */
const fakeRun =
  (ports: number[], calls: string[][] = []): Run =>
  async (command, args) => {
    calls.push([command, ...args]);

    if (command === 'git') return `${root}\n`;

    if (args.includes('cwd')) return `p10\nfcwd\nn${root}\np20\nfcwd\nn/elsewhere/app\np30\nfcwd\nn${root}-copy\n`;

    return ports.map((port, index) => `p10\nf${50 + index}\nn${index ? '127.0.0.1' : '*'}:${port}`).join('\n');
  };

describe('tidewave app resolution', () => {
  test("only the worktree's own beams, their listening ports lowest first", async () => {
    const calls: string[][] = [];
    expect(await appPorts(root, fakeRun([53891, 4044, 53882], calls))).toEqual([4044, 53882, 53891]);
    expect(calls[1]).toContain('10');
    expect(calls[1]!.join(' ')).not.toMatch(/20|30/);
  });

  test('no beam in the worktree means no ports and no second lsof', async () => {
    const calls: string[][] = [];
    expect(await appPorts('/nowhere', fakeRun([4044], calls))).toEqual([]);
    expect(calls).toHaveLength(1);
  });

  test('connects to the first port that answers Tidewave MCP, lists and calls', async () => {
    const app = await openApp(root, fakeRun([other.port, tidewave.port].toSorted((a, b) => a - b)));

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

  test('no app answering names the worktree', async () => {
    await expect(openApp(root, fakeRun([other.port]))).rejects.toThrow(
      `No Phoenix app with Tidewave runs from ${root}`,
    );
  });
});
