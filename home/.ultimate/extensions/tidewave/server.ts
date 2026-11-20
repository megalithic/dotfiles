import { BACKGROUND_CONTEXT, type Context } from '@earendil-works/chord/context';
import { defineExtension, defineTool } from '@earendil-works/pi-durable';
import type { ConversationId, Harness } from '@earendil-works/pi-durable';
import { toLlmContent } from '@earendil-works/pi-mcp';
import { map, obj, opt, str, unknown } from '@earendil-works/pi-schema';
import { conversationApp, linkConversation, listing, openApp, type LinkedApp } from './lib.ts';

type Host = {
  home: string;
  harness(): Harness;
  resource<T>(key: string, create: () => T): T;
  onOpen(callback: () => Promise<void>): void;
  onClose(callback: () => Promise<void>): void;
};

const controllers = new WeakMap<Host, { attach(id: number): Promise<LinkedApp> }>();
export const userActions = ['attach', 'inspect'];

async function attach(args: unknown, host: Host): Promise<LinkedApp> {
  const id = (args as { conversation?: unknown } | null)?.conversation;
  if (typeof id !== 'number' || !Number.isSafeInteger(id) || id < 1)
    throw new Error('Expected {conversation: positive integer}');
  const controller = controllers.get(host);
  if (!controller) throw new Error('Tidewave is not open');
  return controller.attach(id);
}

export const actions = {
  async attach(args: unknown, { host }: { host: Host }) {
    const { port, origin } = await attach(args, host);
    return { port, origin };
  },
  async inspect(args: unknown, { host }: { host: Host }) {
    return (await attach(args, host)).link.inspect();
  },
};

/** project_eval can run long; progress notifications renew it. */
const CALL_TIMEOUT = 10 * 60_000;

const failure = (text: string) => ({ output: [{ type: 'text' as const, text }], isError: true });

const message = (error: unknown) => (error instanceof Error ? error.message : String(error));

async function cwdOf(host: Host, id: number, ctx: Context): Promise<string> {
  const agent = await (await host.harness().conversation(id as ConversationId, ctx))?.agent(ctx);
  if (!agent?.cwd) throw new Error(`No cwd for conversation #${id}`);
  return agent.cwd;
}

export default function tidewave(host: Host) {
  const remembered = host.resource(
    'tidewave.links',
    () => new Map<number, Omit<LinkedApp, 'link'> & { link?: LinkedApp['link'] }>(),
  );
  const pending = new Map<number, Promise<LinkedApp>>();
  let closed = false;
  const submit = async (id: number, content: string) => {
    const harness = host.harness();
    const conversation = await harness.conversation(id as ConversationId, BACKGROUND_CONTEXT);
    if (!conversation) throw new Error(`Conversation #${id} is unavailable`);
    await harness.commit(async (tx) => {
      await conversation.submit(tx, { type: 'input', content, whenBusy: 'followUp' });
    }, BACKGROUND_CONTEXT);
  };
  const open = async (id: number): Promise<LinkedApp> => {
    const app = await conversationApp(host.home, id, await cwdOf(host, id, BACKGROUND_CONTEXT));
    const previous = remembered.get(id);
    if (previous?.link && previous.port === app.port && previous.origin === app.origin) return previous as LinkedApp;
    previous?.link?.stop();
    const { link, ready } = linkConversation(
      app,
      id,
      submit,
      async () => conversationApp(host.home, id, await cwdOf(host, id, BACKGROUND_CONTEXT)),
      () => {
        if (remembered.get(id) === entry) remembered.delete(id);
      },
    );
    const entry = { port: app.port, origin: app.origin, link };
    remembered.set(id, entry);
    try {
      await ready;
      return entry;
    } catch (error) {
      link.stop();
      if (remembered.get(id) === entry) remembered.set(id, { port: app.port, origin: app.origin });
      throw error;
    }
  };
  const controller = {
    attach(id: number): Promise<LinkedApp> {
      if (closed) return Promise.reject(new Error('Tidewave is closing'));
      const existing = pending.get(id);
      if (existing) return existing;
      const opening = open(id).finally(() => pending.delete(id));
      pending.set(id, opening);
      return opening;
    },
  };
  controllers.set(host, controller);
  host.onOpen(async () => {
    for (const id of remembered.keys()) {
      await controller.attach(id).catch((error) => console.error(`Tidewave #${id}: ${message(error)}`));
    }
  });
  host.onClose(async () => {
    closed = true;
    controllers.delete(host);
    await Promise.allSettled(pending.values());
    for (const entry of remembered.values()) {
      entry.link?.stop();
      delete entry.link;
    }
  });
  return defineExtension({
    name: 'tidewave',
    tools: [
      defineTool({
        name: 'tidewave',
        description:
          "Use Tidewave MCP of the Phoenix app your own worktree runs (found by its process, on 127.0.0.1; no other app is reachable): tidewave {} lists its tools with input schemas, tidewave {tool, args} calls one. project_eval and execute_sql_query run code and SQL in that dev app. browser_eval needs a connected Helium tab: open -a Helium http://localhost:<PORT>/tidewave/connect (not 127.0.0.1; allowed_origins rejects it on /ws). A connected browser isn't a session: browser_eval {action:'help'} reserves one and returns 'Active session: <sid>'; drive it with {action:'eval', sid, action_inputs:{code}}. While pi holds the worktree's baton, only listing, get_logs, get_docs and get_source_location work.",
        parameters: obj({
          tool: opt(str({ description: 'The Tidewave tool to call; omit to list the tools' })),
          args: opt(map(unknown(), { description: "The tool's arguments, matching its input schema" })),
        }),
        replay: 'unsafe',
        async execute({ tool, args }, api, ctx) {
          let app;
          try {
            app = await openApp(await cwdOf(host, api.conversationId, ctx));
          } catch (error) {
            return failure(message(error));
          }
          try {
            if (!tool) return { output: [{ type: 'text' as const, text: listing(app, await app.client.listTools()) }] };
            const result = await app.client.callTool(tool, args ?? {}, {
              signal: ctx.abortSignal,
              timeoutMs: CALL_TIMEOUT,
              onProgress: () => {},
            });
            return { output: toLlmContent(result), isError: result.isError === true };
          } catch (error) {
            return failure(`Tidewave ${tool ?? 'tools/list'} at 127.0.0.1:${app.port} failed: ${message(error)}`);
          } finally {
            await app.client.close().catch(() => {});
          }
        },
      }),
    ],
  });
}
