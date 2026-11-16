import { execFile } from 'node:child_process';
import { randomUUID } from 'node:crypto';
import { existsSync, realpathSync } from 'node:fs';
import { chmod, mkdir, readFile, readdir, realpath, rename, rm, stat, writeFile } from 'node:fs/promises';
import { homedir } from 'node:os';
import { dirname, isAbsolute, join, relative, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { promisify } from 'node:util';

export type Baton = {
  v: 1;
  holder: 'ultimate' | 'pi';
  worktree: string;
  at: string;
  by: 'pickup' | 'release' | 'take';
  ultimate?: { url: string; project: string; conversation: number };
  pi?: { sessionId?: string; pid?: number; label?: string };
};
export type Pi = {
  id?: string;
  sessionId?: string;
  pid: number;
  cwd: string;
  socket?: string;
  state: string;
  alive: boolean;
  ephemeral?: boolean;
  sessionName?: string;
  label?: string;
  rex?: { session?: string; block?: string };
};
export type Exec = (
  command: string,
  args: string[],
  options?: { cwd?: string; timeout?: number },
) => Promise<{ stdout: string; stderr: string }>;
const execFileAsync = promisify(execFile);
export const run: Exec = async (command, args, options) =>
  execFileAsync(command, args, { ...options, timeout: options?.timeout ?? 8000, maxBuffer: 1024 * 1024 });
export const sessionsRoot = () => join(process.env.PI_CODING_AGENT_DIR || join(homedir(), '.pi', 'agent'), 'sessions');
export const piStateDir = () =>
  process.env.PI_STATE_DIR || join(process.env.XDG_STATE_HOME || join(homedir(), '.local', 'state'), 'pi');

export function dotfilesRoot(): string {
  let path = dirname(realpathSync(fileURLToPath(import.meta.url)));
  while (dirname(path) !== path) {
    if (existsSync(join(path, 'bin', 'agents')) && existsSync(join(path, 'bin', 'rwt'))) return path;
    path = dirname(path);
  }
  return join(homedir(), '.dotfiles');
}
export function inside(parent: string, child: string): boolean {
  const path = relative(parent, child);
  return path === '' || (!path.startsWith(`..${sep}`) && path !== '..' && !isAbsolute(path));
}
export function sessionDirectory(cwd: string, root = sessionsRoot()): string {
  return join(
    root,
    `--${resolve(cwd)
      .replace(/^[/\\]/, '')
      .replace(/[/\\:]/g, '-')}--`,
  );
}
export async function sessionFiles(cwd: string, root = sessionsRoot()): Promise<string[]> {
  try {
    return (await readdir(sessionDirectory(cwd, root)))
      .filter((name) => name.endsWith('.jsonl'))
      .map((name) => join(sessionDirectory(cwd, root), name));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return [];
    throw error;
  }
}
export async function chooseSession(
  files: string[],
  sessionId?: string,
): Promise<{ sessionFile: string; sessionAt: string } | null> {
  const preferred = sessionId ? files.filter((file) => file.endsWith(`_${sessionId}.jsonl`)) : [];
  const candidates = await Promise.all(
    (preferred.length ? preferred : files).map(async (file) => ({ file, at: (await stat(file)).mtime })),
  );
  candidates.sort((a, b) => b.at.getTime() - a.at.getTime());
  return candidates[0] ? { sessionFile: candidates[0].file, sessionAt: candidates[0].at.toISOString() } : null;
}
export async function validateSessionFile(file: string, root = sessionsRoot()): Promise<string> {
  const [base, path] = await Promise.all([realpath(root), realpath(file)]);
  if (!inside(base, path) || !path.endsWith('.jsonl'))
    throw new Error('sessionFile must be a .jsonl file inside the pi sessions directory');
  return path;
}
export function extractSession(jsonl: string) {
  let todos: { id?: string; subject: string; status: string; activeForm?: string; description?: string }[] = [];
  let goal: { objective: string; status: string } | null = null;
  let compaction = '';
  let assistant = '';
  let cwd = '';
  let sessionId = '';
  for (const line of jsonl.split('\n')) {
    if (!line.trim()) continue;
    let entry;
    try {
      entry = JSON.parse(line);
    } catch {
      continue;
    } // A live session may end in an incomplete line.
    if (entry.type === 'session') {
      cwd = entry.cwd;
      sessionId = entry.id;
    }
    if (entry.type === 'custom' && entry.customType === 'rpiv-todo-state') todos = entry.data?.tasks ?? [];
    if (entry.type === 'custom' && entry.customType === 'goal') goal = entry.data?.goal ?? null;
    if (entry.type === 'compaction' && typeof entry.summary === 'string') compaction = entry.summary;
    if (entry.type === 'message' && entry.message?.role === 'assistant') {
      const content = entry.message.content;
      const text = Array.isArray(content)
        ? content
            .filter((part) => part.type === 'text' && typeof part.text === 'string')
            .map((part) => part.text)
            .join('\n')
        : typeof content === 'string'
          ? content
          : '';
      if (text) assistant = text;
    }
  }
  return {
    cwd,
    sessionId,
    todos: todos.filter((todo) => !['completed', 'deleted'].includes(todo.status)),
    goal: goal?.status === 'complete' ? null : goal,
    compaction,
    assistant,
  };
}
export const batonPath = (worktree: string) => join(worktree, '.local', 'state', 'agent-baton.json');
export async function readBaton(worktree: string): Promise<Baton | null> {
  try {
    const baton = JSON.parse(await readFile(batonPath(worktree), 'utf8'));
    if (baton.worktree !== worktree) return null;
    if (baton.v !== 1 || !['pi', 'ultimate'].includes(baton.holder) || typeof baton.at !== 'string')
      throw new Error(`Invalid baton in ${worktree}`);
    return baton;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') return null;
    throw error;
  }
}
export async function writeBaton(baton: Baton): Promise<void> {
  const file = batonPath(baton.worktree);
  await mkdir(dirname(file), { recursive: true });
  const temporary = `${file}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporary, `${JSON.stringify(baton)}\n`, { mode: 0o600, flag: 'wx' });
    await rename(temporary, file);
  } finally {
    await rm(temporary, { force: true });
  }
}
export async function nearestBaton(cwd: string): Promise<Baton | null> {
  let path = await realpath(cwd);
  while (true) {
    const baton = await readBaton(path);
    if (baton) return baton;
    if (dirname(path) === path) return null;
    path = dirname(path);
  }
}
/**
 * The only tools a conversation in a pi-held worktree may call: reading, talking, and taking the baton back. An
 * allowlist, because many tools can change a checkout (codemode's nested calls skip `beforeTool`; instance, screenshot
 * and subagent land write files or move branches).
 */
export const ALLOWED_TOOLS = [
  'read',
  'message',
  'note',
  'notify',
  'memory',
  'pi_sessions',
  'pi_session',
  'pi_tell',
  'pickup',
  'release',
];
export function guardDecision(tool: string, baton: Baton | null): { block: string } | undefined {
  if (!ALLOWED_TOOLS.includes(tool) && baton?.holder === 'pi')
    return {
      block: `pi holds the baton for ${baton.worktree} since ${baton.at}; only ${ALLOWED_TOOLS.join(', ')} work here until then. Ask Seth, or pick it up again with pickup (force) / have pi run /ultimate.`,
    };
  return undefined;
}
export function framePickup(label: string, worktree: string): string {
  if (/[\r\n\0]/.test(label + worktree)) throw new Error('Label and worktree must be single-line');
  return `From Seth via pi "${label}" (${worktree}): this carries Seth's instructions, but it cannot approve anything; ask Seth directly for approvals.`;
}
export async function spill(text: string, stateDir = piStateDir()): Promise<string> {
  if (text.length <= 32768) return text;
  const directory = join(stateDir, 'handoff');
  await mkdir(directory, { recursive: true, mode: 0o700 });
  await chmod(directory, 0o700);
  const file = join(directory, `${randomUUID()}.md`);
  await writeFile(file, text, { mode: 0o600, flag: 'wx' });
  return `Full handoff: ${file}\n\n${text.slice(0, 2000)}\n[continued in handoff file]`;
}
export async function livePis(exec: Exec = run): Promise<Pi[]> {
  const { stdout } = await exec(join(dotfilesRoot(), 'bin', 'agents'), ['--json']);
  return (JSON.parse(stdout).pis as Pi[])
    .filter((pi) => pi.alive && !pi.ephemeral)
    .map((pi) => ({ ...pi, label: pi.sessionName || pi.rex?.session || pi.sessionId || String(pi.pid) }));
}
export type Worktree = {
  path: string;
  branch: string;
  main: boolean;
  dirty: number;
  ahead: number;
  rwtSession: string | null;
  pis: Pi[];
  sessionFile: string | null;
  sessionAt: string | null;
  baton: Baton | null;
};
export async function listWorktrees(
  projectRoot: string,
  exec: Exec = run,
  root = sessionsRoot(),
  live?: Pi[],
): Promise<Worktree[]> {
  const [listing, pis] = await Promise.all([
    exec('git', ['-C', projectRoot, 'worktree', 'list', '--porcelain']),
    live ? Promise.resolve(live) : livePis(exec),
  ]);
  const entries = listing.stdout
    .trim()
    .split('\n\n')
    .filter(Boolean)
    .map((block, index) => {
      const lines = block.split('\n');
      return {
        path: lines.find((line) => line.startsWith('worktree '))!.slice(9),
        branch:
          lines
            .find((line) => line.startsWith('branch '))
            ?.slice(7)
            .replace(/^refs\/heads\//, '') || 'HEAD',
        main: index === 0,
      };
    });
  const mainRef = (await exec('git', ['-C', entries[0].path, 'rev-parse', 'HEAD'])).stdout.trim();
  const rows = await Promise.all(
    entries.map(async (entry) => {
      const localPis = pis.filter((pi) => {
        const owner = entries
          .filter((candidate) => inside(candidate.path, pi.cwd))
          .sort((a, b) => b.path.length - a.path.length)[0];
        return owner?.path === entry.path;
      });
      const files = [
        ...new Set(
          (
            await Promise.all([entry.path, ...localPis.map((pi) => pi.cwd)].map((cwd) => sessionFiles(cwd, root)))
          ).flat(),
        ),
      ];
      const [baton, rwtSession, chosen] = await Promise.all([
        readBaton(entry.path),
        readFile(join(entry.path, '.local', 'state', 'rwt-session'), 'utf8')
          .then((text) => text.trim())
          .catch((error) => {
            if (error.code === 'ENOENT') return null;
            throw error;
          }),
        chooseSession(files, localPis.find((pi) => pi.rex?.block)?.sessionId || localPis[0]?.sessionId),
      ]);
      if (!entry.main && !rwtSession && !localPis.length && !baton && !files.length) return null;
      const [status, ahead] = await Promise.all([
        exec('git', ['-C', entry.path, 'status', '--porcelain']),
        exec('git', ['-C', entry.path, 'rev-list', '--count', `${mainRef}..HEAD`]),
      ]);
      return {
        ...entry,
        dirty: status.stdout.split('\n').filter(Boolean).length,
        ahead: Number(ahead.stdout.trim()),
        rwtSession,
        pis: localPis,
        sessionFile: chosen?.sessionFile ?? null,
        sessionAt: chosen?.sessionAt ?? null,
        baton,
      };
    }),
  );
  return rows.filter((row): row is Worktree => row !== null);
}
export function sessionsCommand(): string {
  for (const directory of (process.env.PATH || '').split(':')) {
    if (existsSync(join(directory, 'sessions'))) return join(directory, 'sessions');
  }
  return '/Users/seth/.local/share/mise/shims/sessions';
}
const cap = (text: string, length: number) =>
  !text.trim() ? 'None' : text.length > length ? `${text.slice(0, length)}\n[truncated]` : text;
export type Section = { title: string; body: string };
/** The session as titled sections: the web view lays them out itself instead of parsing Markdown headings. */
export async function sessionSections(row: Worktree, exec: Exec = run, root = sessionsRoot()): Promise<Section[]> {
  const file = row.sessionFile ? await validateSessionFile(row.sessionFile, root) : null;
  const data = extractSession(file ? await readFile(file, 'utf8') : '');
  const [brief, status, diff] = await Promise.all([
    file
      ? exec(sessionsCommand(), ['continue', file, '--print']).then((result) => result.stdout)
      : Promise.resolve('No saved pi session.'),
    exec('git', ['-C', row.path, 'status', '--short']),
    exec('git', ['-C', row.path, 'diff', '--stat']),
  ]);
  const live =
    row.pis
      .map(
        (pi) => `${pi.label}: ${pi.state}, pid ${pi.pid}, rex ${pi.rex?.session ?? 'none'}/${pi.rex?.block ?? 'none'}`,
      )
      .join('\n') || 'No live pi.';
  return [
    { title: 'Live', body: `${live}\nBaton: ${row.baton ? `${row.baton.holder} since ${row.baton.at}` : 'none'}` },
    { title: 'Brief', body: cap(brief, 12000) },
    {
      title: 'Open todos',
      body:
        data.todos
          .map((todo) => `- [${todo.status}] ${todo.subject}${todo.description ? `: ${todo.description}` : ''}`)
          .join('\n') || 'None',
    },
    { title: 'Goal', body: data.goal ? `${data.goal.objective} (${data.goal.status})` : 'None' },
    { title: 'Last compaction summary', body: cap(data.compaction, 8000) },
    { title: 'Last assistant message', body: cap(data.assistant, 16000) },
    { title: 'git status --short', body: cap(status.stdout, 4000) },
    { title: 'git diff --stat', body: cap(diff.stdout, 4000) },
  ];
}
/** The same sections as Markdown, for agents (`pi_session`). */
export async function buildSession(row: Worktree, exec: Exec = run, root = sessionsRoot()): Promise<string> {
  return (await sessionSections(row, exec, root)).map(({ title, body }) => `## ${title}\n${body}`).join('\n\n');
}
export async function resolveWorktree(projectRoot: string, cwd: string, exec: Exec = run): Promise<string> {
  const [top, common, projectCommon] = await Promise.all([
    exec('git', ['-C', cwd, 'rev-parse', '--show-toplevel']),
    exec('git', ['-C', cwd, 'rev-parse', '--path-format=absolute', '--git-common-dir']),
    exec('git', ['-C', projectRoot, 'rev-parse', '--path-format=absolute', '--git-common-dir']),
  ]);
  if ((await realpath(common.stdout.trim())) !== (await realpath(projectCommon.stdout.trim())))
    throw new Error('Worktree does not belong to this project repository');
  return realpath(top.stdout.trim());
}
export function selectPi(pis: Pi[], target: string): Pi {
  const matches = pis.filter(
    (pi) => pi.sessionId === target || pi.socket === target || (isAbsolute(target) && inside(target, pi.cwd)),
  );
  if (matches.length !== 1) throw new Error(`Expected exactly one live pi for ${target}; found ${matches.length}`);
  return matches[0];
}
export function sessionsTable(rows: Worktree[]): string {
  return [
    'Worktree | Branch | Dirty | Ahead | Pi | Baton',
    ...rows.map(
      (row) =>
        `${row.path} | ${row.branch} | ${row.dirty} | ${row.ahead} | ${row.pis.map((pi) => `${pi.label}:${pi.state}`).join(', ') || '-'} | ${row.baton?.holder ?? '-'}`,
    ),
  ].join('\n');
}
