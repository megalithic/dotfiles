/**
 * Find the Phoenix app a worktree runs and connect to its Tidewave MCP. The app is found by process, never by a
 * port argument: beam.smp processes whose cwd is the worktree, the TCP ports only they listen on, the first that
 * answers MCP on 127.0.0.1, with redirects refused. So another worktree's app, or anything off this machine, is
 * never reached.
 */
import { execFile } from 'node:child_process';
import { realpath } from 'node:fs/promises';
import { McpClient, StreamableHttpTransport } from '@earendil-works/pi-mcp';
import type { McpFetch, Tool } from '@earendil-works/pi-mcp';

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

/** `[pid, port]` of each TCP listener in lsof's `-Fpn` output. */
const listeners = (out: string): [string, number][] => {
  const found: [string, number][] = [];
  let pid = '';
  for (const line of out.split('\n')) {
    if (line.startsWith('p')) pid = line.slice(1);
    const port = /^n.*:(\d+)$/.exec(line)?.[1];
    if (port && pid) found.push([pid, Number(port)]);
  }
  return found;
};

/**
 * TCP ports that only the beam.smp processes whose cwd is `root` listen on, lowest first. A port another process
 * also listens on is left out, whatever the addresses: a more specific bind (127.0.0.1 beside a wildcard, which BSD
 * allows) or an IPv4 listener beside a beam bound to ::1 would take a connection to 127.0.0.1. lsof sees only this
 * user's processes.
 */
export async function appPorts(root: string, exec: Run = run): Promise<number[]> {
  const own = new Set<string>();
  let pid = '';
  for (const line of (await exec('lsof', ['-a', '-c', 'beam.smp', '-d', 'cwd', '-Fpn'])).split('\n')) {
    if (line.startsWith('p')) pid = line.slice(1);
    else if (line === `n${root}` && /^\d+$/.test(pid)) own.add(pid);
  }
  if (!own.size) return [];
  const all = listeners(await exec('lsof', ['-iTCP', '-sTCP:LISTEN', '-P', '-n', '-Fpn']));
  const ports = new Set(all.filter(([listener]) => own.has(listener)).map(([, port]) => port));
  for (const [listener, port] of all) if (!own.has(listener)) ports.delete(port);
  return [...ports].toSorted((a, b) => a - b);
}

/** A redirect could send a call (code, SQL) to another app or host: refuse every one. */
const noRedirects: McpFetch = (input, init) => fetch(input, { ...init, redirect: 'error' });

/** Connects within CONNECT_TIMEOUT for the whole handshake, or closes the client and throws. */
export const connect: Connect = async (port) => {
  const client = new McpClient({ name: 'ultimate-tidewave', version: '1.0.0', requestTimeoutMs: CONNECT_TIMEOUT });
  const url = `http://127.0.0.1:${port}/tidewave/mcp`;
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    await Promise.race([
      client.connect(new StreamableHttpTransport({ url, fetch: noRedirects, openGetStream: false })),
      new Promise((_resolve, reject) => {
        timer = setTimeout(() => reject(new Error(`${url} did not answer in time`)), CONNECT_TIMEOUT);
      }),
    ]);
    return client;
  } catch (error) {
    await client.close().catch(() => {});
    throw error;
  } finally {
    clearTimeout(timer);
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
