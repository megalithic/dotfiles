import type { Context } from '@earendil-works/chord/context';
import { defineExtension, defineTool } from '@earendil-works/pi-durable';
import type { ConversationId, Harness } from '@earendil-works/pi-durable';
import { toLlmContent } from '@earendil-works/pi-mcp';
import { map, obj, opt, str, unknown } from '@earendil-works/pi-schema';
import { listing, openApp } from './lib.ts';

type Host = { harness(): Harness };

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
  return defineExtension({
    name: 'tidewave',
    tools: [
      defineTool({
        name: 'tidewave',
        description:
          "Use Tidewave MCP of the Phoenix app your own worktree runs (found by its process, on 127.0.0.1; no other app is reachable): tidewave {} lists its tools with input schemas, tidewave {tool, args} calls one. project_eval and execute_sql_query run code and SQL in that dev app. browser_eval needs a browser on the app's control page, which an HTTP 200 from the app doesn't show: open it in Helium first (helium-launch http://127.0.0.1:<PORT>/tidewave). While pi holds the worktree's baton, only listing, get_logs, get_docs and get_source_location work.",
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
