import { describe, expect, mock, test } from 'bun:test';
import { mkdtemp, mkdir, readFile, readdir, realpath, rm, stat, symlink, utimes, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  batonPath,
  branchOfUltimate,
  buildSession,
  chooseSession,
  extractSession,
  framePickup,
  landInput,
  landedMessage,
  drainHandoffs,
  returnBaton,
  withBatonLock,
  checkLand,
  run,
  guardDecision,
  listWorktrees,
  nearestBaton,
  readBaton,
  sessionDirectory,
  sessionFiles,
  spill,
  validateSessionFile,
  worktreeBaton,
  writeBaton,
} from '../../.ultimate/extensions/pi-sessions/lib.ts';
import type { Baton, BranchHost, HandoffStore, Worktree } from '../../.ultimate/extensions/pi-sessions/lib.ts';

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
  test('handoff survives failed delivery and retries without moving the baton again', async () => {
    const state: HandoffStore = {
      items: {
        'submission-1': {
          conversationId: 61,
          worktree: '/work/topic',
          branch: 'topic',
          sha: '1234567890',
          target: 'main',
          batonDone: false,
        },
      },
    };

    let attempts = 0;
    let moves = 0;
    const notices: string[] = [];

    const deps = {
      pending: async () => structuredClone(state.items),
      returnBaton: async () => {
        moves += 1;
      },
      batonDone: async (id: string) => {
        state.items[id].batonDone = true;
      },
      deliver: async () => {
        attempts += 1;

        if (attempts === 1) throw new Error('offline');
      },
      remove: async (id: string) => {
        delete state.items[id];
      },
      notice: (text: string) => notices.push(text),
    };

    await drainHandoffs(deps);
    expect(state.items['submission-1'].batonDone).toBe(true);
    expect(notices[0]).toContain('offline');
    await drainHandoffs(deps);
    expect(state.items).toEqual({});
    expect(attempts).toBe(2);
    expect(moves).toBe(1);
  });

  test('baton mutex checks ownership after a queued newer pickup writes', async () => {
    await temporary(async (worktree) => {
      const previous: Baton = {
        v: 1,
        holder: 'ultimate',
        worktree,
        at: 'now',
        by: 'pickup',
        ultimate: { url: 'http://localhost', project: worktree, conversation: 61 },
      };

      await writeBaton(previous);
      let finish!: () => void;

      const barrier = new Promise<void>((resolve) => {
        finish = resolve;
      });

      const newer: Baton = { ...previous, ultimate: { ...previous.ultimate!, conversation: 62 } };

      const pickupWrite = withBatonLock(worktree, async () => {
        await barrier;
        await writeBaton(newer);
      });

      const returning = returnBaton(worktree, { conversation: 61 });
      finish();
      await pickupWrite;
      expect((await returning).moved).toBe(false);
      expect(await readBaton(worktree)).toEqual(newer);
      expect((await returnBaton(worktree, { conversation: 62 })).moved).toBe(true);
      expect((await readBaton(worktree))?.holder).toBe('pi');
    });
  });

  test('land input names workspace submit and the PR path', () => {
    const input = landInput('From pi', '/work/topic', 'Ship it', 'Brief');

    for (const text of [
      'workspace submit',
      'git push -u origin HEAD',
      'gh pr create',
      'PR URL',
      'release',
      'Commit nothing new',
      'Do not tell Seth "done"',
    ])
      expect(input).toContain(text);
  });

  test('landed message includes sha7, target, push status and prune command', () => {
    for (const pushed of [undefined, 'origin/main']) {
      const message = landedMessage({ sha: '123456789abcdef', target: 'main', pushed }, 'topic');

      for (const text of ['1234567', 'main', pushed ? `pushed to ${pushed}` : 'not pushed', 'rwt prune topic'])
        expect(message).toContain(text);
    }
  });

  test('host land checks require a clean branch ahead of the main checkout', async () => {
    await temporary(async (directory) => {
      const repo = join(directory, 'repo');
      const topic = join(directory, 'topic');
      await mkdir(repo);

      const git = (...args: string[]) =>
        run('git', [
          '-C',
          repo,
          '-c',
          'commit.gpgsign=false',
          '-c',
          'user.name=Test',
          '-c',
          'user.email=test@example.com',
          ...args,
        ]);

      await git('init', '-b', 'main');
      await git('commit', '--allow-empty', '-m', 'initial');
      await git('worktree', 'add', '-b', 'topic', topic);
      await expect(checkLand(repo)).rejects.toThrow('default branch');
      await expect(checkLand(topic)).rejects.toThrow('Nothing ahead');
      await writeFile(join(topic, 'change'), 'change');
      await expect(checkLand(topic)).rejects.toThrow('commit first');
      await run('git', ['-C', topic, 'add', 'change']);
      const tree = (await run('git', ['-C', topic, 'write-tree'])).stdout.trim();
      const commit = (await git('commit-tree', tree, '-p', 'HEAD', '-m', 'change')).stdout.trim();
      await run('git', ['-C', topic, 'update-ref', 'HEAD', commit]);
      expect(await checkLand(topic)).toBe('topic');
    });
  });
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

      // An allowlist: codemode's nested calls skip beforeTool (reproduced on a preview), and instance, screenshot and
      // subagent can write too.
      for (const tool of ['edit', 'write', 'bash', 'codemode', 'instance', 'screenshot', 'subagent'])
        expect(guardDecision(tool, found)?.block).toContain(`pi holds the baton for ${worktree}`);

      // reply_pi answers a pi's ask_pi, which may come from the pi holding this baton.
      for (const tool of ['read', 'reply_pi', 'pickup', 'release']) expect(guardDecision(tool, found)).toBeUndefined();

      // Tidewave: listing and the read-only tools pass; eval, SQL and the browser do not.
      for (const args of [
        {},
        { tool: 'get_logs', args: { tail: 5 } },
        { tool: 'get_docs' },
        { tool: 'get_source_location' },
      ])
        expect(guardDecision('tidewave', found, args)).toBeUndefined();

      for (const args of [
        { tool: 'project_eval' },
        { tool: 'execute_sql_query' },
        { tool: 'browser_eval' },
        { tool: 42 },
      ])
        expect(guardDecision('tidewave', found, args)?.block).toContain('pi holds the baton');
      expect(guardDecision('mcp', found, { tool: 'get_logs' })?.block).toContain('pi holds the baton');
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

  test("starts a pickup as a non-isolated branch of the standing @ultimate, from its tree's root", async () => {
    const started: Parameters<BranchHost['branch']>[0][] = [];

    const host = (rootOf: number | undefined, roots: number[]): BranchHost => ({
      standing: async () => 48,
      roots: async () => roots,
      rootOf: async (id) => (id === 48 ? rootOf : undefined),
      branch: async (branch) => {
        started.push(branch);

        return { id: 100 };
      },
    });

    expect(await branchOfUltimate(host(7, [1, 7]), 'prompt', 'title')).toEqual({ id: 100, ultimate: 48 });
    expect(started[0]).toEqual({ from: 7, prompt: 'prompt', title: 'title', isolated: false, deliver: false, by: 48 });
    // @ultimate stands outside the trees: the project's only root.
    await branchOfUltimate(host(undefined, [1]), 'prompt', 'title');
    expect(started[1]).toMatchObject({ from: 1, by: 48 });
    await expect(branchOfUltimate(host(undefined, [1, 7]), 'prompt', 'title')).rejects.toThrow('roots: #1, #7');
    expect(started).toHaveLength(2);
  });

  test('reads no baton for a conversation whose worktree is gone, without running git', async () => {
    const calls: string[][] = [];

    const baton = await worktreeBaton(
      '/work/app',
      '/work/app/.worktrees/landed-and-removed',
      async (_command, args) => {
        calls.push(args);

        return { stdout: '', stderr: '' };
      },
    );

    expect(baton).toBeNull();
    expect(calls).toEqual([]);
  });

  test('server persists landed handoff before draining and preserves a newer baton owner', async () => {
    // The server facet's Ultimate imports, which only the host provides.
    mock.module('@earendil-works/pi-durable', () => ({
      configure: async () => undefined,
      defineDoc: <Doc>(doc: Doc) => doc,
      ROOT_CONVERSATION_ID: 1,
      defineExtension: <Extension>(extension: Extension) => extension,
      defineTool: <Tool>(tool: Tool) => tool,
      hook: () => ({}),
      ToolTask: {},
    }));
    mock.module('@earendil-works/chord/context', () => ({ BACKGROUND_CONTEXT: {} }));
    const { actions, default: install } = await import('../../.ultimate/extensions/pi-sessions/server.ts');

    await temporary(async (directory) => {
      const path = await realpath(directory);
      let handler!: Parameters<Parameters<typeof install>[0]['react']>[2];
      let commits = 0;
      const state: HandoffStore = { items: {} };
      const notices: string[] = [];

      const barrier = new Promise<void>(() => {});

      const baton: Baton = {
        v: 1,
        holder: 'ultimate',
        worktree: path,
        at: 'now',
        by: 'pickup',
        ultimate: { conversation: 61, project: path, url: 'http://localhost' },
      };

      let external = false;
      // SAFETY: registration and the reactor only use these host methods; no live host or pi is contacted.
      install({
        react: (_name, _tokens, callback, options) => {
          expect(options).toEqual({ from: 'now' });
          handler = callback;
        },
        need: () => ({ get: async () => ({ path, branch: 'topic', external }) }),
        onOpen: () => undefined,
        harness: () => ({
          commit: () => {
            commits += 1;

            return barrier;
          },
        }),
        notice: (text: string) => notices.push(text),
      } as Parameters<typeof install>[0]);
      // SAFETY: this reactor uses tx only for its handoff document; this fixture provides that document.
      const tx = { doc: async () => state } as Parameters<typeof handler>[0];

      // SAFETY: 61 is a positive synthetic conversation ID; all consumed landing fields are present.
      const event = {
        data: { submission: 'landing-1', conversationId: 61, sha: '1234567890', target: 'main' },
      } as Parameters<typeof handler>[1];

      await writeBaton(baton);
      await handler(tx, event);
      expect(Object.keys(state.items)).toHaveLength(0);
      external = true;
      // SAFETY: 62 is a positive synthetic conversation ID naming a different owner.
      await handler(tx, { data: { ...event.data, conversationId: 62 } } as Parameters<typeof handler>[1]);
      expect(Object.keys(state.items)).toHaveLength(0);
      await handler(tx, event);
      expect(commits).toBe(3);
      expect(state.items['landing-1']).toMatchObject({ conversationId: 61, branch: 'topic', batonDone: false });
      expect((await readBaton(path))?.holder).toBe('ultimate');
      // A newer pickup replaces ownership after the reactor's check but before its outbox drains.
      const newer: Baton = { ...baton, ultimate: { ...baton.ultimate!, conversation: 62 } };
      await withBatonLock(path, () => writeBaton(newer));
      const delivered: string[] = [];
      await drainHandoffs({
        pending: async () => structuredClone(state.items),
        returnBaton,
        batonDone: async (id) => {
          state.items[id].batonDone = true;
        },
        deliver: async (_item, text) => {
          delivered.push(text);
        },
        remove: async (id) => {
          delete state.items[id];
        },
        notice: (text) => notices.push(text),
      });
      expect(await readBaton(path)).toEqual(newer);
      expect(delivered).toHaveLength(1);
      expect(delivered[0]).toContain('Landed 1234567');
      expect(state.items).toEqual({});
      expect(notices).toEqual([]);
    });

    await temporary(async (directory) => {
      const project = await realpath(directory);
      const worktree = join(project, '.worktrees', 'topic');
      await mkdir(join(project, '.git'), { recursive: true });
      await mkdir(worktree, { recursive: true });
      await writeBaton({ v: 1, holder: 'pi', worktree, at: '2026-01-01T00:00:00Z', by: 'release' });
      let cwd = project;

      // SAFETY: the baton action reads only host.projectRoot, the conversation's agent cwd and exec.
      const context = {
        host: {
          projectRoot: project,
          harness: () => ({ conversation: async () => ({ agent: async () => ({ cwd }) }) }),
        },
        conversationId: 61,
        exec: async (_command: string, args: string[]) => ({
          stdout: args.includes('--show-toplevel') ? args[1] : join(project, '.git'),
          stderr: '',
        }),
      } as Parameters<typeof actions.baton>[1];

      expect(await actions.baton(null, context)).toBeNull();
      cwd = worktree;
      expect((await actions.baton(null, context))?.worktree).toBe(worktree);
    });
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
