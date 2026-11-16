import { expect, test } from 'bun:test';
import type { ExtensionAPI, ExtensionContext, SessionEntry } from '@earendil-works/pi-coding-agent';
import sessionTitle, { buildTitlePrompt, chooseTitle, validTitle } from '../agent/extensions/session-title.ts';

// SAFETY: these branch fixtures only supply fields read by the title extension.
const user = (text: string): SessionEntry =>
  ({ type: 'message', message: { role: 'user', content: text } }) as SessionEntry;

// SAFETY: no provider consumes this assistant fixture; only its text content is inspected.
const assistant = (text = 'Implemented the session title refresh.'): SessionEntry =>
  ({ type: 'message', message: { role: 'assistant', content: [{ type: 'text', text }] } }) as SessionEntry;

function harness(name = '', answer = 'Accurate evolving session titles') {
  const branch: SessionEntry[] = [user('Keep session titles accurate'), assistant()];
  const handlers = new Map<string, (event: any, ctx: ExtensionContext) => any>();
  const events = new Map<string, () => any>();
  const names: string[] = [];
  const calls: { prompt: string; signal: AbortSignal }[] = [];
  let result = async () => answer;
  // SAFETY: extension under test only uses the branch reader on this context.
  const ctx = { sessionManager: { getBranch: () => branch } } as ExtensionContext;

  // SAFETY: this fake implements exactly the ExtensionAPI methods used by session-title.
  const pi = {
    on: (event: string, fn: (event: any, ctx: ExtensionContext) => any) => handlers.set(event, fn),
    events: { on: (event: string, fn: () => any) => events.set(event, fn) },
    getSessionName: () => name,
    setSessionName: (value: string) => {
      name = value;
      names.push(value);
      handlers.get('session_info_changed')?.({ name }, ctx);
    },
    appendEntry: (customType: string, data: { name: string; at: string }) => {
      // SAFETY: only customType/data are needed when reading the last auto title.
      branch.push({ type: 'custom', customType, data } as SessionEntry);
    },
  } as ExtensionAPI;

  sessionTitle(pi, async (_ctx, prompt, signal) => {
    calls.push({ prompt, signal });

    return result();
  });
  const fire = (event: string) => Promise.resolve(handlers.get(event)?.({}, ctx));
  void fire('session_start');

  return {
    branch,
    calls,
    names,
    fire,
    refresh: () => Promise.resolve(events.get('session-title:refresh')?.()),
    manual: (value: string) => pi.setSessionName(value),
    reply: (fn: () => Promise<string>) => {
      result = fn;
    },
    turn: () => {
      branch.push(user('Now work on the title tests'), assistant());
    },
    name: () => name,
  };
}

test('validator rejects real failures and prose; accepts concise work titles', () => {
  for (const title of [
    '',
    '   ',
    "The message cuts off at 'The user's g…'",
    'I created `handoff-demo.txt` with the line…',
    "I'm working on it",
    "I've done the task",
    'Sorry about that',
    'Here is the title',
    'Sure thing',
    'One two three four five six seven eight nine',
    'Fix titles. Add tests',
    'Fix titles\nAdd tests',
    '"Fix titles"',
    '`Fix titles`',
    'Fix titles?',
  ])
    expect(validTitle(title)).toBe(false);

  for (const title of [
    'Accurate evolving session titles',
    'Pi ⇄ Ultimate handoff',
    'Repair Rex session labels',
    'one two three four five six seven eight',
  ]) {
    expect(validTitle(title)).toBe(true);
  }
});

test('invalid answers keep the current name, or fall back to the latest first nonempty prompt line', () => {
  expect(chooseTitle('Sure, I can help', 'Repair title generation', 'new task')).toBe('Repair title generation');
  // A junk name stays until a valid answer arrives: a random prompt line ("it literally is running here: http…",
  // seen on the demo) is no better.
  expect(chooseTitle('Here is a title', 'The message cuts off', 'it literally is running here')).toBe(
    'The message cuts off',
  );
  expect(chooseTitle('Here is a title', '', `\n\n${'x'.repeat(80)}\nsecond line`)).toBe('x'.repeat(60));
  expect(chooseTitle('  Refresh session titles  ', '', 'ignored')).toBe('Refresh session titles');
});

test('human name wins forever, including a manual change while a title is in flight', async () => {
  const existing = harness('My chosen work title');
  await existing.fire('agent_settled');
  await existing.fire('session_compact');
  await existing.refresh();
  expect(existing.calls).toHaveLength(0);

  const h = harness();
  let finish!: (value: string) => void;
  h.reply(
    () =>
      new Promise((resolve) => {
        finish = resolve;
      }),
  );
  const pending = h.fire('agent_settled');
  h.manual('Human chosen name');
  finish('Generated work title');
  await pending;
  h.manual('');
  await h.fire('session_compact');
  expect(h.name()).toBe('');
  expect(h.calls).toHaveLength(1);
  expect(h.names).toEqual(['Human chosen name', '']);
});

test('junk legacy auto name gets replaced and recorded; branch auto name remains eligible', async () => {
  const h = harness('The message cuts off at the prompt');
  await h.fire('agent_settled');
  expect(h.names).toEqual(['Accurate evolving session titles']);
  expect(h.branch.at(-1)).toMatchObject({
    type: 'custom',
    customType: 'session-title',
    data: { name: h.name(), at: expect.any(String) },
  });
  h.reply(async () => 'Pi handoff title refresh');
  await h.refresh();
  expect(h.name()).toBe('Pi handoff title refresh');
});

test('identical title is skipped case-insensitively without recording another auto name', async () => {
  const h = harness();
  await h.fire('agent_settled');
  const count = h.branch.length;
  h.reply(async () => 'ACCURATE EVOLVING SESSION TITLES');
  await h.refresh();
  expect(h.calls).toHaveLength(2);
  expect(h.names).toHaveLength(1);
  expect(h.branch).toHaveLength(count);
});

test('prompt uses newest user text, latest summary and latest text reply, never tools/thinking/system', () => {
  // SAFETY: these deliberately partial entries exercise only role/type/content/summary fields.
  const branch = [
    user('old prompt'),
    assistant('old reply'),
    { type: 'compaction', summary: 'old summary', systemMessage: 'PRIVATE' },
    user('latest prompt'),
    { type: 'message', message: { role: 'toolResult', content: 'PRIVATE tool result' } },
    { type: 'message', message: { role: 'system', content: 'PRIVATE system' } },
    {
      type: 'message',
      message: {
        role: 'assistant',
        content: [
          { type: 'thinking', thinking: 'PRIVATE thinking' },
          { type: 'toolCall', name: 'bash', arguments: { command: 'PRIVATE command' } },
          { type: 'text', text: 'latest reply' },
        ],
      },
    },
    { type: 'compaction', summary: 'latest summary' },
  ] as SessionEntry[];

  const prompt = buildTitlePrompt(branch, 'Current work title');
  expect(prompt).toContain('Current work title');
  // The task follows the tagged data: data-last prompts made Haiku continue the session instead of titling it.
  expect(prompt.trimEnd()).toMatch(/Task: write a 3–6 word title[^]*Reply with the title only\.$/);
  expect(prompt).toContain('latest prompt\n---\nold prompt');
  expect(prompt).toContain('latest summary');
  expect(prompt).toContain('latest reply');

  for (const hidden of ['PRIVATE', 'old summary', 'old reply']) expect(prompt).not.toContain(hidden);

  const capped = buildTitlePrompt([user('o'.repeat(2000)), user('n'.repeat(2000)), assistant('a'.repeat(2000))], '');
  expect(capped.match(/n/g)?.length).toBeGreaterThan(capped.match(/o/g)?.length || 0);
  expect(capped).not.toContain('a'.repeat(801));
  expect(capped.length).toBeLessThan(2500);
});

test('settled waits for the first exchange, compaction/refresh trigger, otherwise at most every ten turns', async () => {
  const h = harness();
  const reply = h.branch.pop()!;
  await h.fire('agent_settled');
  expect(h.calls).toHaveLength(0);
  h.branch.push(reply);
  await h.fire('agent_settled');
  expect(h.calls).toHaveLength(1);

  for (let i = 0; i < 9; i++) {
    h.turn();
    await h.fire('agent_settled');
  }

  expect(h.calls).toHaveLength(1);
  h.turn();
  await h.fire('agent_settled');
  await h.fire('agent_settled');
  expect(h.calls).toHaveLength(2);
  await h.fire('session_compact');
  expect(h.calls).toHaveLength(3);
  await h.refresh();
  expect(h.calls).toHaveLength(4);

  for (let i = 0; i < 9; i++) {
    h.turn();
    await h.fire('agent_settled');
  }

  expect(h.calls).toHaveLength(4);
});

test('one title call in flight; shutdown aborts and prevents the result from landing', async () => {
  const h = harness();
  let finish!: (value: string) => void;
  h.reply(
    () =>
      new Promise((resolve) => {
        finish = resolve;
      }),
  );
  const pending = h.fire('agent_settled');
  await h.fire('agent_settled');
  await h.fire('session_compact');
  await h.refresh();
  expect(h.calls).toHaveLength(1);
  await h.fire('session_shutdown');
  expect(h.calls[0]!.signal.aborted).toBe(true);
  finish('Generated after shutdown');
  await pending;
  expect(h.names).toHaveLength(0);
  expect(h.calls).toHaveLength(1);
});
