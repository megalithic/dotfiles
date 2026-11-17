import { execFile } from 'node:child_process';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { promisify } from 'node:util';
import { BACKGROUND_CONTEXT as context } from '@earendil-works/chord/context';
import { defineDoc, defineExtension, defineTool, ROOT_CONVERSATION_ID } from '@earendil-works/pi-durable';
import type { ConversationDocToken, ConversationId, Harness, JsonObject } from '@earendil-works/pi-durable';
import { int, obj, oneOf, opt, str } from '@earendil-works/pi-schema';
import { add, DOCUMENT, done, find, initial, record } from './lib.ts';
import type { State } from './lib.ts';

type Host = {
  harness(): Harness;
  doc(kind: string): ConversationDocToken<JsonObject> | undefined;
};
type ActionContext = { host: Host; signal: AbortSignal };

export const Items = defineDoc<State>({
  kind: DOCUMENT,
  checkpointWhen: () => false,
  version: 1,
  scope: 'conversation',
  history: 'latest',
  fork: 'initial',
  initial,
});
export const docs = [Items];

const run = promisify(execFile);
async function openArtifact(args: unknown, { host, signal }: ActionContext, reveal: boolean) {
  const item = await host.harness().commit(async (tx) => {
    const state = await tx.doc(Items, ROOT_CONVERSATION_ID);
    return { ...find(state, record(args).id) };
  }, context);
  if (item.kind !== 'artifact' || !item.path) throw new Error('This inbox item is not an artifact');
  const path =
    item.path === '~' ? homedir() : item.path.startsWith('~/') ? join(homedir(), item.path.slice(2)) : item.path;
  await run('open', reveal ? ['-R', path] : [path], { signal, timeout: 30_000 });
  return { id: item.id };
}

export const userActions = ['done', 'open', 'reveal'];
export const actions = {
  async done(args: unknown, { host }: ActionContext) {
    return host
      .harness()
      .commit(async (tx) => done(await tx.doc(Items, ROOT_CONVERSATION_ID), record(args).id, Date.now()), context);
  },
  async open(args: unknown, ctx: ActionContext) {
    return openArtifact(args, ctx, false);
  },
  async reveal(args: unknown, ctx: ActionContext) {
    return openArtifact(args, ctx, true);
  },
};

export default function inboxItems(host: Host) {
  return defineExtension({
    name: 'inbox-items',
    tools: [
      defineTool({
        name: 'inbox',
        description:
          "Put something in the project's Inbox for the user to return to: an action they must take later that needs no answer, an artifact you made (path), or a shareable link (url). Anything needing their answer stays a question message. add {kind, title, text, url?, path?, key?}; a repeated key returns its existing item. done {id} marks it complete; list returns open items. Items stay until Done. Use a stable key when retrying an add.",
        parameters: obj({
          action: { ...oneOf(['add', 'done', 'list'] as const), type: 'string' },
          kind: opt({ ...oneOf(['action', 'artifact', 'link'] as const), type: 'string' }),
          title: opt(str()),
          text: opt(str()),
          url: opt(str()),
          path: opt(str()),
          key: opt(str()),
          id: opt(int({ minimum: 1 })),
        }),
        // A key is optional, so an interrupted keyless add must not replay.
        replay: 'unsafe',
        async execute(args, api, ctx) {
          let conversation = api.conversationId;
          if (args.action === 'add') {
            // Same by-kind lookup as Ultimate's actingAs helper; no cross-clone runtime import.
            const sideDoc = host.doc('sidechat');
            const side = sideDoc && (await host.harness().snapshot(sideDoc, conversation, ctx));
            if (typeof side?.of === 'number') conversation = side.of as ConversationId;
          }
          const result = await api.commit(async (tx) => {
            const state = await tx.doc(Items, ROOT_CONVERSATION_ID);
            if (args.action === 'add') return add(state, args, conversation, Date.now());
            if (args.action === 'done') return done(state, args.id, Date.now());
            return state.items.filter((item) => item.done === undefined).map((item) => ({ ...item }));
          }, ctx);
          return { output: [{ type: 'text', text: JSON.stringify(result) }] };
        },
      }),
    ],
  });
}
