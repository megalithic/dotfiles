import { afterAll, expect, test } from 'bun:test';
import fs from 'node:fs';
import path from 'node:path';
import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';

const state = (process.env.PI_STATE_DIR = fs.mkdtempSync('/tmp/review-pr-'));

const {
  actionsFor,
  blockedPost,
  default: extension,
  harnessMentions,
  parseReply,
  readReviews,
  reviewArgs,
} = await import('../agent/extensions/review-pr.ts');

afterAll(() => fs.rmSync(state, { recursive: true, force: true }));

const draft = path.join(state, 'pr-228-review.md');

const review = {
  key: 'review-pr-228-abc',
  repo: 'acme/app',
  number: 228,
  title: 'feat: reports',
  head: 'abc',
  url: 'https://github.com/acme/app/pull/228',
  draft,
};

type ToolCall = { toolName: string; input: { command: string } };

type Handler = (event: ToolCall, ctx: ExtensionContext) => { block: boolean } | undefined;

type Reply = { replyTo: string; text: string };

// SAFETY: Fixtures implement only the API members review-pr.ts registers and calls.
const asExtensionAPI = <T>(value: T): ExtensionAPI => value as ExtensionAPI;

// SAFETY: Fixtures implement only the context members the command and hooks use.
const asExtensionContext = <T>(value: T): ExtensionContext => value as ExtensionContext;

const harness = (selected: string | undefined, confirmed = true) => {
  const on = new Map<string, Handler>();
  const events = new Map<string, (data: Reply) => void>();
  const execs: string[][] = [];
  const notes: string[] = [];
  let command: (args: string, ctx: ExtensionContext) => Promise<void> = async () => {};

  extension(
    asExtensionAPI({
      on: (name: string, handler: Handler) => on.set(name, handler),
      events: { on: (name: string, handler: (data: Reply) => void) => events.set(name, handler), emit: () => {} },
      registerCommand: (_name: string, options: { handler: typeof command }) => (command = options.handler),
      exec: async (cmd: string, args: string[]) => (execs.push([cmd, ...args]), { code: 0, stdout: '', stderr: '' }),
    }),
  );

  const ctx = asExtensionContext({
    cwd: state,
    ui: {
      setStatus: () => {},
      notify: (text: string) => notes.push(text),
      select: async () => selected,
      confirm: async () => confirmed,
      editor: async () => undefined,
    },
  });

  return { on, events, execs, notes, ctx, run: (args: string) => command(args, ctx) };
};

const seed = () => fs.writeFileSync(path.join(state, 'review-pr.json'), JSON.stringify([review]));

test('a reply saves the draft and verdict; only the picked action posts, and Approve needs APPROVED plus a confirm', async () => {
  seed();
  const pi = harness('approve');
  pi.events.get('tell:reply')?.({
    replyTo: review.key,
    text: 'Verdict: APPROVED\n\nteam report\n\nDRAFT:\nNothing blocks merge.\n\n**Good to have**\n- `lib/a.ex:3` rename x.',
  });
  expect(fs.readFileSync(draft, 'utf8')).toBe('Nothing blocks merge.\n\n**Good to have**\n- `lib/a.ex:3` rename x.\n');
  expect(readReviews()[0]?.verdict).toBe('APPROVED');

  const blocked = pi.on.get('tool_call')?.(
    { toolName: 'bash', input: { command: 'gh pr review 228 --approve' } },
    pi.ctx,
  );

  expect(blocked).toMatchObject({ block: true });

  await pi.run('post 228');
  expect(pi.execs).toEqual([['gh', ...reviewArgs('approve', review)]]);
  expect(readReviews()).toEqual([]);
});

test('declining the approval confirm posts nothing', async () => {
  seed();
  fs.writeFileSync(path.join(state, 'review-pr.json'), JSON.stringify([{ ...review, verdict: 'APPROVED' }]));
  const pi = harness('approve', false);
  await pi.run('post');
  expect(pi.execs).toEqual([]);
});

test('a draft naming the harness is refused before any menu', async () => {
  fs.writeFileSync(draft, 'Reviewed by Ultimate #51923.\n');
  fs.writeFileSync(path.join(state, 'review-pr.json'), JSON.stringify([{ ...review, verdict: 'NEEDS CHANGES' }]));
  const pi = harness('comment');
  await pi.run('post');
  expect(pi.execs).toEqual([]);
  expect(pi.notes.at(-1)).toContain('Ultimate');
});

test('pure helpers', () => {
  expect(actionsFor('NEEDS CHANGES')).toEqual(['comment', 'request changes']);
  expect(harnessMentions('Per pi and reviewer-security, see #51923; api change is fine')).toEqual([
    'pi',
    'reviewer-security',
    '#51923',
  ]);
  expect(parseReply('no marker').draft).toBeUndefined();
  expect(blockedPost('gh api repos/acme/app/pulls/228/reviews -f event=APPROVE', [review])).toBe(review);
  expect(blockedPost('gh pr view 228', [review])).toBeUndefined();
});
