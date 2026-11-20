/**
 * Find the Phoenix app a worktree runs and connect to its Tidewave MCP. The app is found by process, never by a
 * port argument: beam.smp processes whose cwd is the worktree, the TCP ports only they listen on, the first that
 * answers MCP on 127.0.0.1, with redirects refused. So another worktree's app, or anything off this machine, is
 * never reached.
 */
import { realpath } from 'node:fs/promises';
import { McpClient, StreamableHttpTransport } from '@earendil-works/pi-mcp';
import type { McpFetch, Tool } from '@earendil-works/pi-mcp';
import { beamCwds, listeners, ownedPorts, run, type Run } from '../../../.pi/agent/lib/beam.ts';
import { createBrowserLink, type BrowserLink } from '../../../.pi/agent/extensions/pidewave/browser.ts';
import { readRegistry, withUltimateApps, type Registry } from '../../../.pi/agent/lib/registry.ts';

export { run, type Run };

export type LinkedApp = { port: number; origin: string; link: BrowserLink };
export type Submit = (conversation: number, content: string) => Promise<void>;

/** The shared registry gives pi precedence, so check the worktree too when its Ultimate entry is hidden. */
export async function conversationApp(
  home: string,
  conversation: number,
  cwd: string,
): Promise<Registry['apps'][number]> {
  const registry = await withUltimateApps(readRegistry());
  const canonicalHome = await realpath(home);
  let app: Registry['apps'][number] | undefined;
  for (const candidate of registry.apps) {
    const owner = candidate.owner;
    if (
      owner.kind === 'ultimate' &&
      owner.conversation === conversation &&
      (await realpath(owner.home)) === canonicalHome
    ) {
      app = candidate;
      break;
    }
  }
  const root = app ? undefined : await worktreeRoot(cwd);
  const pi = registry.apps.find(
    (candidate) => candidate.owner.kind === 'pi' && (app ? candidate.port === app.port : candidate.root === root),
  );
  if (pi?.owner.kind === 'pi')
    throw new Error(
      `Port ${pi.port} is held by pi ${pi.owner.sessionId ?? pi.owner.pid}; detach its Tidewave link first.`,
    );
  if (!app)
    throw new Error(
      `No Phoenix app found for Ultimate #${conversation}. Start its server in that conversation's worktree.`,
    );
  return app;
}

/** One CDP owner; delivery is injected so tests and reloads need no retained harness. */
export function linkConversation(origin: string, conversation: number, submit: Submit, endpoint?: string) {
  let link: BrowserLink;
  let connected: () => void;
  const ready = new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => {
      if (link.state() === 'up') resolve();
      else reject(new Error('Helium has no CDP on port 9223; open Helium first.'));
    }, 3_000);
    connected = () => {
      if (link.state() === 'up' && link.tabs().length) {
        clearTimeout(timer);
        resolve();
      }
    };
  });
  const toast = (target: string, text: string, ok: boolean) =>
    link
      .evaluate(target, `window.__pidewaveToast && window.__pidewaveToast(${JSON.stringify(text)}, ${ok})`)
      .catch(() => {});
  link = createBrowserLink(
    origin,
    {
      change: () => connected(),
      message: (message, tab) => {
        if (message.kind === 'prompt') {
          void submit(conversation, `From Seth via the Tidewave toolbar on ${tab.url}:\n\n${message.text}`)
            .then(() => toast(tab.targetId, `Sent to #${conversation}`, true))
            .catch((error) => toast(tab.targetId, error instanceof Error ? error.message : String(error), false));
        } else if (message.kind === 'inspect') {
          void link.inspect(tab.targetId, false).then((result) => {
            if (result !== 'active') void toast(tab.targetId, result, false);
          });
        } else if (message.kind === 'focus-pi') {
          void toast(tab.targetId, `This app belongs to Ultimate #${conversation}`, true);
        }
      },
    },
    endpoint,
  );
  link.start();
  return { link, ready };
}

export type Connect = (port: number) => Promise<McpClient>;

export type App = { root: string; port: number; client: McpClient };

const CONNECT_TIMEOUT = 3_000;

/** The git toplevel of `cwd` (or `cwd` itself), with symlinks resolved as lsof reports a process's cwd. */
export async function worktreeRoot(cwd: string, exec: Run = run): Promise<string> {
  const top = (await exec('git', ['-C', cwd, 'rev-parse', '--show-toplevel'])).trim();
  return realpath(top || cwd);
}

/**
 * TCP ports that only the beam.smp processes whose cwd is `root` listen on, lowest first. A port another process
 * also listens on is left out, whatever the addresses: a more specific bind (127.0.0.1 beside a wildcard, which BSD
 * allows) or an IPv4 listener beside a beam bound to ::1 would take a connection to 127.0.0.1. lsof sees only this
 * user's processes.
 */
export async function appPorts(root: string, exec: Run = run): Promise<number[]> {
  const beams = beamCwds(await exec('lsof', ['-a', '-c', 'beam.smp', '-d', 'cwd', '-Fpn']));
  const own = new Set(beams.filter(({ cwd }) => cwd === root).map(({ pid }) => pid));
  if (!own.size) return [];
  return ownedPorts(listeners(await exec('lsof', ['-iTCP', '-sTCP:LISTEN', '-P', '-n', '-Fpn'])), own);
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
