/**
 * Bring this Pi's terminal forward: the Rex block, the tmux pane, or the
 * terminal app of a plain shell. The Pi focuses itself from its own lease
 * terminal, so nothing has to search for the right pane.
 */

import { execFile } from 'node:child_process';
import type { Terminal } from './lease.ts';
import { isJsonNumber, isJsonObject, isJsonString, type JsonValue } from './shared.ts';

/** Runs a command; resolves stdout, or undefined when it fails. */
export type Run = (command: string, args: string[]) => Promise<string | undefined>;

export const run: Run = (command, args) =>
  new Promise((resolve) =>
    execFile(command, args, { encoding: 'utf8', timeout: 3_000 }, (error, stdout) =>
      resolve(error ? undefined : stdout),
    ),
  );

const REX_APP = 'com.superlogical.rex';

type Ancestor = { pid: number; command: string };

/** A process and its parents, from `ps -axo pid=,ppid=,comm=`. */
export const ancestors = (pid: number, table: string): Ancestor[] => {
  const rows = new Map<number, { ppid: number; command: string }>();

  for (const line of table.split('\n')) {
    const match = /^\s*(\d+)\s+(\d+)\s+(.+)$/.exec(line);

    if (match) rows.set(Number(match[1]), { ppid: Number(match[2]), command: match[3]! });
  }

  const chain: Ancestor[] = [];

  for (let current = pid; current > 1 && chain.length < 30;) {
    const row = rows.get(current);

    if (!row) break;
    chain.push({ pid: current, command: row.command });
    current = row.ppid;
  }

  return chain;
};

/** The app that owns a process chain. Rex terminals descend from the headless Rex Server. */
export const appFor = (chain: Ancestor[]): { bundle: string } | { path: string } | undefined => {
  for (const { command } of chain) {
    if (command.includes('/com.superlogical.rex/')) return { bundle: REX_APP };
    const app = /^(.*?\.app)\/Contents\/MacOS\//.exec(command)?.[1];

    if (app) return { path: app };
  }
};

const json = (text: string | undefined): JsonValue | undefined => {
  try {
    return text ? JSON.parse(text) : undefined;
  } catch {}
};

const collectBlocks = (value: JsonValue | undefined, out: Set<string>): void => {
  if (Array.isArray(value)) {
    for (const item of value) collectBlocks(item, out);
  } else if (isJsonObject(value)) {
    if (isJsonString(value.block_id)) out.add(value.block_id);

    for (const item of Object.values(value)) collectBlocks(item, out);
  }
};

/** The Rex block whose terminal process is one of these ancestors (tmux running inside Rex). */
const rexBlockFor = async (chain: Ancestor[], exec: Run): Promise<{ session: string; block: string } | undefined> => {
  const pids = new Set(chain.map((entry) => entry.pid));
  const list = json(await exec('rex', ['ls', '--json']));
  const sessions = isJsonObject(list) && Array.isArray(list.sessions) ? list.sessions : [];

  for (const entry of sessions) {
    if (!isJsonObject(entry) || !isJsonString(entry.session_id)) continue;
    const session = entry.session_id;
    const blocks = new Set<string>();
    collectBlocks(json(await exec('rex', ['session', 'inspect', session, '--json'])), blocks);

    for (const block of blocks) {
      const proc = json(await exec('rex', ['block', 'call', '-s', session, '-b', block, 'process']));
      const child = isJsonObject(proc) && isJsonObject(proc.child) ? proc.child.pid : undefined;

      if (isJsonNumber(child) && pids.has(child)) return { session, block };
    }
  }
};

const focusRex = async (session: string, block: string, exec: Run): Promise<boolean> => {
  await exec('rex', ['do', 'session.select', `session_id=${session}`]);
  const focused = await exec('rex', ['focus', '-s', session, block]);
  await exec('open', ['-b', REX_APP]);

  return focused !== undefined;
};

const activate = async (pid: number, exec: Run): Promise<void> => {
  const table = await exec('ps', ['-axo', 'pid=,ppid=,comm=']);
  const chain = table ? ancestors(pid, table) : [];
  const app = appFor(chain);

  if (!app) return;

  if ('bundle' in app && app.bundle === REX_APP) {
    const where = await rexBlockFor(chain, exec);

    if (where && (await focusRex(where.session, where.block, exec))) return;
  }

  await exec('open', 'bundle' in app ? ['-b', app.bundle] : ['-a', app.path]);
};

/** Resolves an error message, or undefined on success. */
export const focusTerminal = async (
  terminal: Terminal,
  exec: Run = run,
  pid = process.pid,
): Promise<string | undefined> => {
  if (terminal.kind === 'rex' && terminal.rex) {
    const { session, block } = terminal.rex;

    return (await focusRex(session, block, exec)) ? undefined : `Rex could not focus block ${block}.`;
  }

  if (terminal.kind === 'tmux' && terminal.tmux) {
    const { pane } = terminal.tmux;
    const where = await exec('tmux', ['display-message', '-p', '-t', pane, '#{session_name}\t#{window_index}']);
    const [session, window] = (where ?? '').trim().split('\t');

    if (!session || !window) return `tmux pane ${pane} is gone.`;

    // Switch the most recently active client, then raise the terminal window that shows it.
    const clients = await exec('tmux', ['list-clients', '-F', '#{client_activity}\t#{client_pid}\t#{client_tty}']);

    const [, latestPid, tty] =
      (clients ?? '')
        .trim()
        .split('\n')
        .map((line) => line.split('\t'))
        .toSorted((a, b) => Number(b[0] ?? 0) - Number(a[0] ?? 0))[0] ?? [];

    const switched = await exec('tmux', [
      'switch-client',
      ...(tty ? ['-c', tty] : []),
      '-t',
      `=${session}`,
      ';',
      'select-window',
      '-t',
      `=${session}:${window}`,
      ';',
      'select-pane',
      '-t',
      pane,
    ]);

    if (latestPid) await activate(Number(latestPid), exec);

    return switched === undefined ? `tmux could not switch to ${session}.` : undefined;
  }

  await activate(pid, exec);
};
