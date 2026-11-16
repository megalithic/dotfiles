/**
 * Find the Phoenix app a worktree runs and connect to its Tidewave MCP. The app is found by process, never by a
 * port argument: beam.smp processes whose cwd is the worktree, their listening TCP ports, the first that answers
 * MCP on 127.0.0.1. So another worktree's app, or anything off this machine, is never reached.
 */
import { execFile } from 'node:child_process';
import { realpath } from 'node:fs/promises';
import { McpClient, StreamableHttpTransport } from '@earendil-works/pi-mcp';
import type { Tool } from '@earendil-works/pi-mcp';

/** Runs a command and resolves its stdout, whatever its exit code (lsof exits 1 when it finds nothing). */
export type Run = (command: string, args: string[]) => Promise<string>;

export type Connect = (port: number) => Promise<McpClient>;

export type App = { root: string; port: number; client: McpClient };

const CONNECT_TIMEOUT = 3_000;

export const run: Run = (command, args) =>
  new Promise((resolve) => {
    execFile(command, args, { timeout: 5_000 }, (_error, stdout) => resolve(String(stdout ?? '')));
  });

/** The git toplevel of `cwd` (or `cwd` itself), with symlinks resolved as lsof reports a process's cwd. */
export async function worktreeRoot(cwd: string, exec: Run = run): Promise<string> {
  const top = (await exec('git', ['-C', cwd, 'rev-parse', '--show-toplevel'])).trim();
  return realpath(top || cwd);
}

/** Listening TCP ports of the beam.smp processes whose cwd is `root`, lowest first. */
export async function appPorts(root: string, exec: Run = run): Promise<number[]> {
  const pids: string[] = [];
  let pid = '';
  for (const line of (await exec('lsof', ['-a', '-c', 'beam.smp', '-d', 'cwd', '-Fpn'])).split('\n')) {
    if (line.startsWith('p')) pid = line.slice(1);
    else if (line === `n${root}` && /^\d+$/.test(pid)) pids.push(pid);
  }
  if (!pids.length) return [];
  const listening = await exec('lsof', ['-a', '-p', pids.join(','), '-iTCP', '-sTCP:LISTEN', '-P', '-n', '-Fn']);
  const ports = new Set<number>();
  for (const line of listening.split('\n')) {
    const port = /^n.*:(\d+)$/.exec(line)?.[1];
    if (port) ports.add(Number(port));
  }
  return [...ports].toSorted((a, b) => a - b);
}

export const connect: Connect = async (port) => {
  const client = new McpClient({ name: 'ultimate-tidewave', version: '1.0.0', requestTimeoutMs: CONNECT_TIMEOUT });
  try {
    await client.connect(
      new StreamableHttpTransport({ url: `http://127.0.0.1:${port}/tidewave/mcp`, openGetStream: false }),
    );
    return client;
  } catch (error) {
    await client.close().catch(() => {});
    throw error;
  }
};

/** The worktree's own app, connected; a port that does not answer Tidewave MCP (Erlang distribution, a debugger) is skipped. */
export async function openApp(cwd: string, exec: Run = run, open: Connect = connect): Promise<App> {
  const root = await worktreeRoot(cwd, exec);
  for (const port of await appPorts(root, exec)) {
    try {
      return { root, port, client: await open(port) };
    } catch {}
  }
  throw new Error(
    `No Phoenix app with Tidewave runs from ${root}. Start its server in that worktree (mise run start:server), then call again.`,
  );
}

export const listing = (app: Pick<App, 'root' | 'port'>, tools: Tool[]): string =>
  [
    `Tidewave of ${app.root} at 127.0.0.1:${app.port}: ${tools.length} tools. Call one with tidewave {tool, args}.`,
    ...tools.map(
      (tool) => `\n${tool.name}: ${tool.description?.trim() ?? ''}\n  input: ${JSON.stringify(tool.inputSchema)}`,
    ),
  ].join('\n');
