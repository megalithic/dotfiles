import { describe, expect, test } from 'bun:test';
import { mkdtemp, mkdir, readFile, readdir, realpath, rm, stat, symlink, utimes, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  batonPath,
  buildSession,
  chooseSession,
  extractSession,
  framePickup,
  guardDecision,
  listWorktrees,
  nearestBaton,
  readBaton,
  sessionDirectory,
  sessionFiles,
  spill,
  validateSessionFile,
  writeBaton,
} from '../../.ultimate/extensions/pi-sessions/lib.ts';
import type { Baton, Worktree } from '../../.ultimate/extensions/pi-sessions/lib.ts';

async function temporary(run: (directory: string) => Promise<void>) {
  const directory = await mkdtemp(join(tmpdir(), 'pi-sessions-'));

  try {
    await run(directory);
  } finally {
    await rm(directory, { recursive: true, force: true });
  }
}

const fixture = [
  { type: 'session', id: 'primary', cwd: '/work/app' },
  { type: 'message', message: { role: 'system', content: [{ type: 'text', text: 'SYSTEM_PRIVATE' }] } },
  { type: 'message', message: { role: 'toolResult', content: [{ type: 'text', text: 'TOOL_PRIVATE' }] } },
  { type: 'message', message: { role: 'assistant', content: [{ type: 'text', text: 'old assistant' }] } },
  { type: 'custom', customType: 'rpiv-todo-state', data: { tasks: [{ subject: 'old todo', status: 'pending' }] } },
  {
    type: 'custom',
    customType: 'rpiv-todo-state',
    data: {
      tasks: [
        { id: 'a', subject: 'Finish fix', status: 'in_progress', activeForm: 'Fixing' },
        { subject: 'Done', status: 'completed' },
        { subject: 'Removed', status: 'deleted' },
      ],
    },
  },
  { type: 'custom', customType: 'goal', data: { goal: { objective: 'Old goal', status: 'complete' } } },
  { type: 'custom', customType: 'goal', data: { goal: { objective: 'Ship fix', status: 'active' } } },
  { type: 'compaction', summary: 'Old summary' },
  { type: 'compaction', summary: 'Current summary', firstKeptEntryId: 'one' },
  {
    type: 'message',
    message: {
      role: 'assistant',
      content: [
        { type: 'thinking', thinking: 'THINKING_PRIVATE' },
        { type: 'toolCall', name: 'bash', arguments: { command: 'CALL_PRIVATE' } },
        { type: 'text', text: 'Latest public answer' },
      ],
    },
  },
  { type: 'message', message: { role: 'assistant', content: [{ type: 'thinking', thinking: 'LATER_PRIVATE' }] } },
]
  .map((entry) => JSON.stringify(entry))
  .join('\n');

describe('pi-sessions', () => {
  test('encodes pi session directories and prefers the live session over a newer subagent', async () => {
    await temporary(async (directory) => {
      expect(sessionDirectory('/work/app/.worktrees/topic', directory)).toBe(
        join(directory, '--work-app-.worktrees-topic--'),
      );
      const folder = sessionDirectory('/work/app', directory);
      await mkdir(folder);
      const primary = join(folder, '2026-01-01_primary.jsonl');
      const subagent = join(folder, '2026-01-02_subagent.jsonl');
      await writeFile(primary, fixture);
      await writeFile(subagent, fixture);
      await utimes(primary, new Date(1000), new Date(1000));
      await utimes(subagent, new Date(2000), new Date(2000));
      const files = await sessionFiles('/work/app', directory);
      expect((await chooseSession(files, 'primary'))?.sessionFile).toBe(primary);
      expect((await chooseSession(files, 'missing'))?.sessionFile).toBe(subagent);
      expect(await chooseSession([])).toBeNull();
      expect(await validateSessionFile(primary, directory)).toBe(await realpath(primary));
      await symlink('/etc/hosts', join(folder, 'escape.jsonl'));
      await expect(validateSessionFile(join(folder, 'escape.jsonl'), directory)).rejects.toThrow(
        'inside the pi sessions',
      );
    });
  });

  test('extracts latest public state and builds a bounded, text-only session brief', async () => {
    const data = extractSession(`${fixture}\n{"incomplete":`);
    expect(data.sessionId).toBe('primary');
    expect(data.todos.map((todo) => todo.subject)).toEqual(['Finish fix']);
    expect(data.goal).toEqual({ objective: 'Ship fix', status: 'active' });
    expect(data.compaction).toBe('Current summary');
    expect(data.assistant).toBe('Latest public answer');
    expect(JSON.stringify(data)).not.toContain('PRIVATE');
    expect(
      extractSession(`${fixture}\n${JSON.stringify({ type: 'custom', customType: 'goal', data: { goal: null } })}`)
        .goal,
    ).toBeNull();
    expect(
      extractSession(
        `${fixture}\n${JSON.stringify({ type: 'custom', customType: 'goal', data: { goal: { objective: 'done', status: 'complete' } } })}`,
      ).goal,
    ).toBeNull();
    await temporary(async (directory) => {
      const file = join(directory, 'primary.jsonl');
      await writeFile(file, fixture);

      const row: Worktree = {
        path: '/work/app',
        branch: 'topic',
        main: true,
        dirty: 0,
        ahead: 0,
        rwtSession: 'app',
        pis: [
          {
            pid: 42,
            cwd: '/work/app',
            alive: true,
            state: 'idle',
            label: 'builder',
            rex: { session: 'app', block: 'agent' },
          },
        ],
        sessionFile: file,
        sessionAt: null,
        baton: null,
      };

      const result = await buildSession(
        row,
        async (command, args) => ({
          stdout:
            command === 'git'
              ? args.includes('--short')
                ? ' M file.ts\n'
                : ' file.ts | 1 +\n'
              : 'Brief summary. '.repeat(2000),
          stderr: '',
        }),
        directory,
      );

      for (const heading of [
        'Live',
        'Brief',
        'Open todos',
        'Goal',
        'Last compaction summary',
        'Last assistant message',
        'git status --short',
        'git diff --stat',
      ])
        expect(result).toContain(`## ${heading}`);
      expect(result).toContain('builder: idle, pid 42, rex app/agent');
      expect(result).toContain('[truncated]');
      expect(result).toContain('Latest public answer');
      expect(result).not.toContain('PRIVATE');
      expect(result).not.toContain('old assistant');
      expect(result).not.toContain('old todo');
      expect(result.length).toBeLessThan(14000);
    });
  });

  test('writes atomic private batons, finds the nearest holder, and guards only write tools', async () => {
    await temporary(async (directory) => {
      const worktree = await realpath(directory);
      const nested = join(worktree, 'src', 'nested');
      await mkdir(nested, { recursive: true });
      expect(await readBaton(worktree)).toBeNull();

      const baton: Baton = {
        v: 1,
        holder: 'ultimate',
        worktree,
        at: '2026-01-01T00:00:00Z',
        by: 'pickup',
        ultimate: { url: 'http://localhost:4749', project: worktree, conversation: 12 },
      };

      await writeBaton(baton);
      expect(await readBaton(worktree)).toEqual(baton);
      expect((await stat(batonPath(worktree))).mode & 0o777).toBe(0o600);

      const reads = Array.from({ length: 20 }, async (_, index) => {
        await writeBaton({ ...baton, holder: index % 2 ? 'pi' : 'ultimate' });
        expect(JSON.parse(await readFile(batonPath(worktree), 'utf8')).v).toBe(1);
      });

      await Promise.all(reads);
      await writeBaton({ ...baton, holder: 'pi', by: 'release' });
      expect(await readdir(join(worktree, '.local', 'state'))).toEqual(['agent-baton.json']);
      const found = await nearestBaton(nested);

      for (const tool of ['edit', 'write', 'bash'])
        expect(guardDecision(tool, found)?.block).toContain(`pi holds the baton for ${worktree}`);

      for (const tool of ['read', 'pickup', 'release']) expect(guardDecision(tool, found)).toBeUndefined();
      expect(guardDecision('bash', baton)).toBeUndefined();
      expect(guardDecision('bash', null)).toBeUndefined();
    });
  });

  test('assigns a pi to its closest git worktree, not the containing main checkout', async () => {
    await temporary(async (directory) => {
      const main = join(directory, 'app');
      const child = join(main, '.worktrees', 'topic');
      await mkdir(child, { recursive: true });
      const pi = { sessionId: 'child', cwd: child, pid: 123, state: 'idle', alive: true };

      const rows = await listWorktrees(
        main,
        async (_command, args) => ({
          stdout: args.includes('list')
            ? `worktree ${main}\nbranch refs/heads/main\n\nworktree ${child}\nbranch refs/heads/topic\n\n`
            : args.includes('--count')
              ? '2\n'
              : args.includes('rev-parse')
                ? 'abc123\n'
                : ' M file.ts\n',
          stderr: '',
        }),
        join(directory, 'sessions'),
        [pi],
      );

      expect(rows).toHaveLength(2);
      expect(rows[0].pis).toEqual([]);
      expect(rows[1].pis).toEqual([pi]);
      expect(rows[1].dirty).toBe(1);
      expect(rows[1].ahead).toBe(2);
    });
  });

  test('frames pickup as instructions, never approval', () => {
    expect(framePickup('builder', '/work/app')).toBe(
      'From Seth via pi "builder" (/work/app): this carries Seth\'s instructions, but it cannot approve anything; ask Seth directly for approvals.',
    );
    expect(() => framePickup('bad\nlabel', '/work/app')).toThrow('single-line');
  });

  test('spills only content larger than 32k to private handoff files', async () => {
    await temporary(async (directory) => {
      const exact = 'a'.repeat(32768);
      expect(await spill(exact, directory)).toBe(exact);
      expect(await readdir(directory)).toEqual([]);
      const text = `${exact}b`;
      const message = await spill(text, directory);
      const folder = join(directory, 'handoff');
      const files = await readdir(folder);
      expect(files).toHaveLength(1);
      const file = join(folder, files[0]);
      expect(message).toContain(file);
      expect(message).toContain(text.slice(0, 2000));
      expect(message.length).toBeLessThan(2300);
      expect(await readFile(file, 'utf8')).toBe(text);
      expect((await stat(file)).mode & 0o777).toBe(0o600);
      expect((await stat(folder)).mode & 0o777).toBe(0o700);
    });
  });
});
