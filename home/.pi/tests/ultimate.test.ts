import { afterAll, afterEach, beforeEach, expect, spyOn, test } from 'bun:test';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import type { ExtensionContext } from '@earendil-works/pi-coding-agent';
import {
  batonPath,
  batonStatus,
  checkLand,
  guardDecision,
  readBaton,
  resolveToplevel,
  spillHandoff,
  writeBaton,
  type Baton,
} from '../agent/lib/baton.ts';
import { formatHistory, historyTarget, pickup } from '../agent/extensions/ultimate.ts';
import { containingUltimate, registryTargets } from '../agent/lib/tell-targets.ts';
import type { Registry } from '../agent/lib/registry.ts';

const directory = fs.mkdtempSync('/tmp/ultimate-core-');

const originalEnv = { ...process.env };

const originalFetch = globalThis.fetch;

const worktree = path.join(directory, 'repo');

fs.mkdirSync(worktree);

execFileSync('git', ['init', '--quiet', worktree]);

const root = resolveToplevel(worktree);

const baton: Baton = {
  v: 1,
  holder: 'ultimate',
  worktree: root,
  at: '2026-06-17T12:00:00.000Z',
  by: 'pickup',
  ultimate: { url: 'http://localhost:4749/?conversation=48', project: root, conversation: 48 },
};

beforeEach(() => {
  process.env.PI_STATE_DIR = path.join(directory, 'state');
  process.env.ULTIMATE_USER_HOME = path.join(directory, 'ultimate');
  fs.rmSync(path.join(root, '.local'), { recursive: true, force: true });
  fs.rmSync(process.env.ULTIMATE_USER_HOME, { recursive: true, force: true });
});

afterEach(() => {
  globalThis.fetch = originalFetch;
});

afterAll(() => {
  process.env = originalEnv;
  fs.rmSync(directory, { recursive: true, force: true });
});

test('/land refuses dirty, default branch and nothing ahead in a git worktree', () => {
  const repo = path.join(directory, 'land-repo');
  const topic = path.join(directory, 'land-topic');

  const git = (cwd: string, ...args: string[]) =>
    execFileSync(
      'git',
      ['-c', 'commit.gpgsign=false', '-c', 'user.name=Test', '-c', 'user.email=test@example.com', ...args],
      { cwd, stdio: 'pipe' },
    );

  fs.mkdirSync(repo);
  git(repo, 'init', '-b', 'main');
  git(repo, 'commit', '--allow-empty', '-m', 'initial');
  git(repo, 'worktree', 'add', '-b', 'topic', topic);
  expect(() => checkLand(repo)).toThrow('default branch');
  expect(() => checkLand(topic)).toThrow('Nothing ahead');
  fs.writeFileSync(path.join(topic, 'change'), 'changed');
  expect(() => checkLand(topic)).toThrow('commit first');
  git(topic, 'add', 'change');
  const tree = git(topic, 'write-tree').toString().trim();
  const commit = git(topic, 'commit-tree', tree, '-p', 'HEAD', '-m', 'change').toString().trim();
  git(topic, 'update-ref', 'HEAD', commit);
  expect(checkLand(topic)).toBe('topic');
});

test('baton resolves git toplevel, atomically replaces a private file and leaves no temporary files', () => {
  const nested = path.join(root, 'nested');
  fs.mkdirSync(nested, { recursive: true });
  expect(resolveToplevel(nested)).toBe(root);
  expect(readBaton(root)).toBeUndefined();
  writeBaton(baton);
  expect(readBaton(root)).toEqual(baton);
  expect(fs.statSync(batonPath(root)).mode & 0o777).toBe(0o600);
  const rename = fs.renameSync;
  let replaced = false;

  const spy = spyOn(fs, 'renameSync').mockImplementation((source, destination) => {
    expect(readBaton(root)).toEqual(baton);
    expect(fs.statSync(source).mode & 0o777).toBe(0o600);
    expect(destination).toBe(batonPath(root));
    replaced = true;
    rename(source, destination);
  });

  try {
    fs.chmodSync(batonPath(root), 0o644);
    writeBaton({ ...baton, holder: 'pi', by: 'take' });
    expect(replaced).toBe(true);
    expect(readBaton(root)?.holder).toBe('pi');
    expect(fs.statSync(batonPath(root)).mode & 0o777).toBe(0o600);
    expect(fs.readdirSync(path.dirname(batonPath(root)))).toEqual(['agent-baton.json']);
  } finally {
    spy.mockRestore();
  }
});

test('guard blocks only the four writing tools while Ultimate holds the baton', () => {
  for (const tool of ['edit', 'write', 'bash', 'interactive_shell']) {
    expect(guardDecision(tool, readBaton(root))).toBeUndefined();
    expect(guardDecision(tool, { ...baton, holder: 'pi' })).toBeUndefined();
    expect(guardDecision(tool, baton)).toEqual({
      block: true,
      reason: `Ultimate #48 (${baton.ultimate!.url}) holds the baton for ${root} since ${baton.at}; it hands back with release. Ask Seth, or run /baton take.`,
    });
  }

  for (const tool of ['read', 'ultimate_read', 'tell_pi']) expect(guardDecision(tool, baton)).toBeUndefined();
  expect(batonStatus(baton)).toBe('Ultimate #48 holds this worktree');
  expect(batonStatus({ ...baton, holder: 'pi' })).toBe('pi holds this worktree');
  expect(batonStatus(undefined)).toBeUndefined();
});

const inventory = registryTargets({
  machine: 'testhost',
  pis: [{ id: 'pi:testhost:plain', pid: 1, socket: '/plain.sock', cwd: '/work/app', alive: true }],
  ultimates: [
    { pid: 1, port: 1, url: 'http://parent:1', project: '/work' },
    { pid: 2, port: 2, url: 'http://child:2', project: '/work/app' },
    { pid: 3, port: 3, url: 'http://dead:3', project: '/work/app/nested', alive: false },
    { pid: 4, port: 4, url: 'http://hub:4', project: '/hub', hub: 'primary', home: '/u/.ultimate/projects/hub-1' },
  ],
});

test('instance selection uses the deepest live containing project with directory boundaries', () => {
  expect(containingUltimate(inventory, '/work/app/nested')?.socket).toBe('http://child:2');
  expect(containingUltimate(inventory, '/work/apple')?.socket).toBe('http://parent:1');
  expect(containingUltimate(inventory, '/outside')).toBeUndefined();
  // A pi in one of an instance's own conversation worktrees (outside its project) reaches that instance.
  expect(containingUltimate(inventory, '/u/.ultimate/projects/hub-1/worktrees/9095/src')?.socket).toBe('http://hub:4');
  expect(containingUltimate(inventory, '/u/.ultimate/projects/hub-1/state')).toBeUndefined();
  expect(historyTarget(inventory, '/work/app', '/hub')?.socket).toBe('http://hub:4');
  expect(historyTarget(inventory, '/work/app')?.socket).toBe('http://child:2');
  expect(historyTarget(inventory, '/outside', undefined, 'app')?.socket).toBe('http://child:2');
  expect(historyTarget(inventory, '/outside', undefined, 'hub')?.socket).toBe('http://hub:4');
  // An explicit project that resolves to nothing never falls back to the baton's or cwd's instance.
  expect(historyTarget(inventory, '/work/app', '/hub', 'missing')).toBeUndefined();
});

// SAFETY: pickup uses only cwd and these session manager methods, not a running Pi.
const ctx = {
  cwd: root,
  sessionManager: {
    getSessionId: () => 'test-session',
    getSessionFile: () => '/safe/session-path.jsonl',
  },
} as ExtensionContext;

const registerUltimate = () => {
  const project = path.join(process.env.ULTIMATE_USER_HOME!, 'projects/fake');
  fs.mkdirSync(project, { recursive: true });

  const instance: Registry['ultimates'][number] = {
    pid: process.pid,
    port: 45678,
    url: 'http://127.0.0.1:45678',
    project: root,
  };

  fs.writeFileSync(path.join(project, 'ultimate.lock'), JSON.stringify(instance));

  return instance;
};

test('pickup POST uses the registry URL, Origin and session path/from, never raw session content', async () => {
  const instance = registerUltimate();
  const calls: { url: unknown; init: RequestInit | undefined }[] = [];
  // SAFETY: only fetch’s call signature is used by the transport; Bun’s extra fetch methods are irrelevant here.
  globalThis.fetch = (async (url, init) => {
    calls.push({ url, init });

    return Response.json({
      result: { conversation: 48, url: `${instance.url}/?conversation=48`, worktree: root, baton },
    });
  }) as typeof fetch;
  expect((await pickup(ctx, 'Finish tests')).conversation).toBe(48);
  expect(calls).toHaveLength(1);
  expect(calls[0]!.url).toBe(`${instance.url}/api/extensions/pi-sessions/actions/pickup`);
  expect(calls[0]!.init).toMatchObject({
    method: 'POST',
    headers: { Origin: instance.url, 'Content-Type': 'application/json' },
  });
  expect(JSON.parse(String(calls[0]!.init!.body))).toEqual({
    args: {
      cwd: root,
      sessionFile: '/safe/session-path.jsonl',
      goal: 'Finish tests',
      from: { label: expect.any(String), sessionId: 'test-session', socket: expect.any(String), pid: process.pid },
    },
  });
  await pickup(ctx, 'Land it', { land: true });
  expect(JSON.parse(String(calls[1]!.init!.body)).args.land).toBe(true);
  // SAFETY: this stub only needs fetch’s callable shape; transport never uses Bun’s extra fetch methods.
  globalThis.fetch = (async () => Response.json({ error: 'busy' }, { status: 409 })) as typeof fetch;
  await expect(pickup(ctx)).rejects.toThrow('HTTP 409: busy');
});

test('pickup without a containing Ultimate fails before any request', async () => {
  await expect(pickup(ctx)).rejects.toThrow(`no Ultimate runs for ${root}`);
});

test('history is oldest first, hides thinking/results/system and exposes a paging cursor', () => {
  const history = {
    entries: [
      {
        id: 9,
        kind: 'pi.assistant',
        model: [
          {
            role: 'assistant',
            content: [
              { type: 'thinking', text: 'PRIVATE' },
              { type: 'text', text: 'Answer' },
              { type: 'toolCall', name: 'read', arguments: { secret: 'PRIVATE' } },
            ],
          },
        ],
      },
      ...['pi.tool-result', 'pi.system', 'prompt.build'].map((kind, index) => ({
        id: index + 5,
        kind,
        model: [{ role: 'user', content: 'PRIVATE' }],
      })),
      { id: 4, kind: 'pi.user', model: [{ role: 'user', content: 'Question' }] },
      { id: 3, kind: 'board.message', model: [{ role: 'user', content: 'Note' }] },
    ],
    before: 3,
  };

  const formatted = formatHistory(history);
  expect(formatted).toBe(
    '#3 board.message user:\nNote\n\n#4 pi.user user:\nQuestion\n\n#9 pi.assistant assistant:\nAnswer\n[tool read]\n\nbefore: 3',
  );
  expect(formatted).not.toContain('PRIVATE');
  expect(formatHistory(history, 1)).toEndWith('before: 9');
});

test('history caps every entry at 4k, the whole at 32k and pages from the last consumed entry', () => {
  const formatted = formatHistory(
    {
      entries: Array.from({ length: 64 }, (_, index) => ({
        id: 64 - index,
        kind: 'pi.assistant',
        model: [{ role: 'assistant', content: 'x'.repeat(5000) }],
      })),
      before: 1,
    },
    64,
  );

  expect(formatted.length).toBeLessThanOrEqual(32768);
  const blocks = formatted.split('\n\n');
  expect(blocks.pop()).toBe('before: 58');
  expect(blocks).toHaveLength(7);

  for (const block of blocks) expect(block.length).toBeLessThanOrEqual(4096);
  expect(formatted).toContain('[truncated]');
});

test('goals over 32k spill to a private handoff file with a short preview', () => {
  const small = 'x'.repeat(32768);
  expect(spillHandoff(small)).toBe(small);
  const text = 'y'.repeat(32769);
  const preview = spillHandoff(text);
  const dir = path.join(process.env.PI_STATE_DIR!, 'handoff');
  const file = path.join(dir, fs.readdirSync(dir)[0]!);
  expect(preview).toContain(file);
  expect(preview).toContain('y'.repeat(2000));
  expect(preview.length).toBeLessThan(3000);
  expect(fs.readFileSync(file, 'utf8')).toBe(text);
  expect(fs.statSync(file).mode & 0o777).toBe(0o600);
  expect(fs.statSync(dir).mode & 0o777).toBe(0o700);
});
