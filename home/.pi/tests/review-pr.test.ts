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
  inboxCard,
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
  const events = new Map<string, (data: Reply) => Promise<void>>();
  const execs: string[][] = [];
  const bodies: string[] = [];
  const notes: string[] = [];
  let command: (args: string, ctx: ExtensionContext) => Promise<void> = async () => {};

  extension(
    asExtensionAPI({
      on: (name: string, handler: Handler) => on.set(name, handler),
      events: {
        on: (name: string, handler: (data: Reply) => Promise<void>) => events.set(name, handler),
        emit: () => {},
      },
      registerCommand: (_name: string, options: { handler: typeof command }) => (command = options.handler),
      exec: async (cmd: string, args: string[]) => {
        execs.push([cmd, ...args]);
        bodies.push(fs.readFileSync(args.at(-1) ?? '', 'utf8'));

        return { code: 0, stdout: '', stderr: '' };
      },
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

  return { on, events, execs, bodies, notes, ctx, run: (args: string) => command(args, ctx) };
};

const seed = () => fs.writeFileSync(path.join(state, 'review-pr.json'), JSON.stringify([review]));

test('a reply saves the draft and verdict; only the picked action posts, and Approve needs APPROVED plus a confirm', async () => {
  seed();
  const pi = harness('approve');
  await pi.events.get('tell:reply')?.({
    replyTo: review.key,
    text: 'Verdict: APPROVED\n\nteam report\n\nDRAFT:\nNothing blocks merge.\n\n**Good to have**\n- `lib/a.ex:3` rename x.',
  });
  expect(fs.readFileSync(draft, 'utf8')).toBe('Nothing blocks merge.\n\n**Good to have**\n- `lib/a.ex:3` rename x.\n');
  expect(readReviews()[0]?.verdict).toBe('APPROVED');

  // A redelivered reply never overwrites the draft Seth edited.
  fs.writeFileSync(draft, 'Edited by Seth.\n');
  await pi.events.get('tell:reply')?.({ replyTo: review.key, text: 'Verdict: APPROVED\n\nDRAFT:\nold' });
  expect(fs.readFileSync(draft, 'utf8')).toBe('Edited by Seth.\n');

  const blocked = pi.on.get('tool_call')?.(
    { toolName: 'bash', input: { command: 'gh pr review 228 --approve' } },
    pi.ctx,
  );

  expect(blocked).toMatchObject({ block: true });

  await pi.run('post 228');
  const [call] = pi.execs;

  expect(call?.slice(0, -1)).toEqual(['gh', ...reviewArgs('approve', review, '').slice(0, -1)]);
  expect(pi.bodies).toEqual(['Edited by Seth.\n']);
  expect(readReviews()).toEqual([]);
});

test('a verdict adds one artifact to the reviewing Ultimate; failure still saves the draft', async () => {
  const requests: { route: string; method: string; origin: string | null; body: unknown }[] = [];
  let fail = false;

  const server = Bun.serve({
    port: 0,
    async fetch(request) {
      requests.push({
        route: new URL(request.url).pathname,
        method: request.method,
        origin: request.headers.get('Origin'),
        body: await request.json(),
      });

      return Response.json(fail ? { error: 'unavailable' } : { result: { id: 1 } }, { status: fail ? 500 : 200 });
    },
  });

  try {
    const seeded = { ...review, ultimate: { socket: `${server.url}api/extensions/pi-bridge/actions/tell` } };
    const seedTarget = () => fs.writeFileSync(path.join(state, 'review-pr.json'), JSON.stringify([seeded]));
    seedTarget();
    const pi = harness(undefined);
    pi.on.get('session_start')?.({ toolName: '', input: { command: '' } }, pi.ctx);
    const reply = { replyTo: review.key, text: 'Verdict: APPROVED\nteam report\nDRAFT:\nbody' };

    await pi.events.get('tell:reply')?.(reply);
    expect(requests).toEqual([
      {
        route: '/api/extensions/inbox-items/actions/add',
        method: 'POST',
        origin: server.url.origin,
        body: { args: inboxCard({ ...seeded, verdict: 'APPROVED' }) },
      },
    ]);
    expect(requests[0]?.body).toMatchObject({
      args: {
        kind: 'artifact',
        title: 'Review draft: acme/app#228 — APPROVED',
        text: `${review.title}\n${review.url}\nRevise it in pi or with \`/review-pr edit 228\`; post it from pi with \`/review-pr post 228\`.`,
        path: draft,
        url: review.url,
        key: review.key,
      },
    });
    await pi.events.get('tell:reply')?.(reply);
    expect(requests).toHaveLength(1);
    expect(fs.readFileSync(draft, 'utf8')).toBe('body\n');

    fail = true;
    seedTarget();
    await pi.events.get('tell:reply')?.({ ...reply, text: 'Verdict: APPROVED\nDRAFT:\nstill saved' });
    expect(requests).toHaveLength(2);
    expect(fs.readFileSync(draft, 'utf8')).toBe('still saved\n');
    expect(readReviews()[0]?.verdict).toBe('APPROVED');
    expect(pi.notes.at(-1)).toContain('Inbox card failed: Ultimate rejected request: HTTP 500');
    expect(pi.execs).toEqual([]);
  } finally {
    await server.stop(true);
  }
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

  for (const command of [
    'gh pr review --approve 228 --body ok',
    'gh -R acme/app pr review --approve',
    'gh pr comment https://github.com/x/y/pull/9 -b hi',
    'gh api repos/acme/app/pulls/228/reviews -f event=APPROVE',
    'gh api graphql -f query="mutation { addPullRequestReview(input: {}) { clientMutationId } }"',
    "gh api -f body='Fix A; retain B' repos/acme/app/issues/228/comments",
    'cd x && GH_TOKEN=1 gh pr comment 228 -b "a | b"',
    'echo $(gh pr review 228 --approve)',
    'result="$(gh pr review 228 --approve)"',
    `result="$(printf '1) Review'; gh pr review 228 --approve)"`,
    'echo "$(gh pr review 228 --approve)"',
    'echo "`gh pr comment 228 -b hi`"',
    'echo "it\'s $(echo $(gh api repos/a/b/issues/1/comments -f body=x))"',
    'gh api graphql --input /tmp/payload.json',
    'gh api graphql --input=/tmp/payload.json',
    'gh api graphql -F query=@/tmp/q.graphql',
    'mise exec -- gh pr review 228 --approve',
    'mise x gh@2 -- gh api graphql --input p.json',
    'gh api graphql --field=query=@q.graphql',
    'gh api graphql -F query=@-',
    'gh api graphql -f id=PR_1',
    'GH_PROMPT_DISABLED=1 mise exec -- gh pr review 123 --approve',
    'env mise exec -- GH_HOST=x gh pr comment 1 -b hi',
    'command -- gh pr review 123 --approve',
    '/usr/bin/env -i PATH=/x /opt/homebrew/bin/gh pr review 1 --approve',
    'nice -n 5 timeout 30 gh pr comment 1 -b hi',
    'echo 1 | xargs -I{} gh pr review {} --approve',
    'gh pr \\\n  review 123 --approve',
    'gh \\\napi graphql --input p.json',
    "gh pr $'review' 1 --approve",
    'eval "gh pr review 1 --approve"',
    "bash -c 'gh pr review 1 --approve'",
    "/bin/zsh -lc 'cd x && gh pr comment 1 -b hi'",
    'sh -c "echo; gh api repos/a/b/issues/1/comments -f body=x"',
  ])
    expect(blockedPost(command, [review])).toBe(true);
  expect(blockedPost('gh pr view 228 --comments', [review])).toBe(false);
  expect(blockedPost('gh api graphql -f query="{ viewer { login } }"', [review])).toBe(false);
  expect(blockedPost('mise exec -- gh pr view 228', [review])).toBe(false);
  expect(blockedPost("bash -c 'gh pr view 1'", [review])).toBe(false);
  expect(blockedPost('gh pr \\\n  view 1', [review])).toBe(false);
  expect(blockedPost('gh api graphql --field=query="query { viewer { login } }"', [review])).toBe(false);
  expect(blockedPost('gh pr view 228 --comments --repo acme/code-review', [review])).toBe(false);
  expect(blockedPost('gh api repos/acme/app/pulls/228/comments --jq .[].body', [review])).toBe(true);
  expect(blockedPost("git commit -m 'gh pr review 228'", [review])).toBe(false);
  expect(blockedPost("echo '$(gh pr review 228 --approve)'", [review])).toBe(false);
  expect(blockedPost(`echo "$(printf '(')" '$(gh pr review 228 --approve)'`, [review])).toBe(false);
  expect(blockedPost('gh pr review 228 --approve', [])).toBe(false);
});
