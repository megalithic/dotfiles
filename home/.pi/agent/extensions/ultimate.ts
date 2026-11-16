import type { ExtensionAPI, ExtensionContext } from '@earendil-works/pi-coding-agent';
import { Type } from 'typebox';
import {
  batonSchema,
  batonStatus,
  guardDecision,
  readBaton,
  resolveToplevel,
  spillHandoff,
  writeBaton,
} from '../lib/baton.ts';
import { readRegistry } from '../lib/registry.ts';
import { containingUltimate, registryTargets, resolveTargets, type Target } from '../lib/tell-targets.ts';
import { listTargets, originInfo, ultimateRequest } from '../lib/tell-transport.ts';

const pickupSchema = Type.Object({
  result: Type.Object({
    conversation: Type.Integer(),
    url: Type.String(),
    worktree: Type.String(),
    baton: batonSchema,
  }),
});

export const pickup = async (ctx: ExtensionContext, goal?: string) => {
  const target = containingUltimate(registryTargets(readRegistry()), ctx.cwd);

  if (!target) throw new Error(`no Ultimate runs for ${ctx.cwd}`);
  const { label, sessionId, socket } = originInfo(ctx);

  const response = await ultimateRequest(target, '/api/extensions/pi-sessions/actions/pickup', pickupSchema, {
    args: {
      cwd: ctx.cwd,
      sessionFile: ctx.sessionManager.getSessionFile(),
      goal: goal ? spillHandoff(goal) : undefined,
      from: { label, sessionId, socket, pid: process.pid },
    },
  });

  return response.result;
};

const historySchema = Type.Object({
  entries: Type.Array(
    Type.Object({
      id: Type.Integer(),
      kind: Type.String(),
      model: Type.Optional(
        Type.Array(
          Type.Object({
            role: Type.String(),
            content: Type.Union([
              Type.String(),
              Type.Array(
                Type.Object({
                  type: Type.String(),
                  text: Type.Optional(Type.String()),
                  name: Type.Optional(Type.String()),
                }),
              ),
            ]),
          }),
        ),
      ),
    }),
  ),
  before: Type.Optional(Type.Integer()),
});

/** Keep user/assistant text, never chain-of-thought, raw tools or system context. */
export const formatHistory = (value: Type.Static<typeof historySchema>, limit = 20): string => {
  const blocks: string[] = [];
  let size = 0;
  let cursor: number | undefined;
  const entries = [...value.entries].sort((a, b) => b.id - a.id);

  for (const entry of entries) {
    if (blocks.length >= limit) break;
    let block = '';

    if (!['pi.tool-result', 'pi.system', 'prompt.build'].includes(entry.kind)) {
      block = (entry.model || [])
        .filter((message) => ['user', 'assistant'].includes(message.role))
        .map((message) => {
          const text = Array.isArray(message.content)
            ? message.content
                .flatMap((part) =>
                  part.type === 'text'
                    ? [part.text || '']
                    : part.type === 'toolCall' && message.role === 'assistant'
                      ? [`[tool ${part.name || '?'}]`]
                      : [],
                )
                .join('\n')
            : message.content;

          return `#${entry.id} ${entry.kind} ${message.role}:\n${text}`;
        })
        .join('\n');
    }

    if (block.length > 4096) block = `${block.slice(0, 4080)}\n[truncated]`;

    if (block && size + block.length + 2 > 32768 - 128) break;
    cursor = entry.id;

    if (block) {
      blocks.push(block);
      size += block.length + 2;
    }
  }

  if (cursor === entries.at(-1)?.id && value.before !== undefined) cursor = value.before;

  return `${blocks.reverse().join('\n\n') || 'No readable entries.'}\n\nbefore: ${cursor ?? value.before ?? 'none'}`;
};

export const historyTarget = (
  inventory: Target[],
  cwd: string,
  batonProject?: string,
  project?: string,
): Target | undefined =>
  // An explicit project wins: on another machine this cwd may match an unrelated instance.
  (project ? resolveTargets(inventory, `ultimate:${project}`)[0] : undefined) ||
  inventory.find(
    (target) => target.ultimate && target.ultimate.project === batonProject && target.ultimate.alive !== false,
  ) ||
  containingUltimate(inventory, cwd);

const resultText = (text: string) => ({ content: [{ type: 'text' as const, text }], details: {} });

export default function (pi: ExtensionAPI) {
  const toplevels = new Map<string, string>();
  let timer: ReturnType<typeof setInterval> | undefined;
  let current: ExtensionContext | undefined;

  const toplevel = (cwd: string) => {
    const cached = toplevels.get(cwd);

    if (cached) return cached;
    const root = resolveToplevel(cwd);
    toplevels.set(cwd, root);

    return root;
  };

  const batonFor = (cwd: string) => {
    let root: string;

    try {
      root = toplevel(cwd);
    } catch {
      // A non-git session has no worktree baton. Never cache a failed git lookup.
      return undefined;
    }

    return readBaton(root);
  };

  const refresh = (ctx: ExtensionContext) => {
    try {
      ctx.ui.setStatus('baton', batonStatus(batonFor(ctx.cwd)));
    } catch (error) {
      ctx.ui.setStatus('baton', `Baton error: ${error instanceof Error ? error.message : String(error)}`);
    }
  };

  const handoff = async (ctx: ExtensionContext, goal?: string) => {
    const result = await pickup(ctx, goal);
    pi.events.emit('session-title:refresh', {});
    refresh(ctx);

    return result;
  };

  pi.on('session_start', (_event, ctx) => {
    current = ctx;
    refresh(ctx);

    if (timer) clearInterval(timer);
    timer = setInterval(() => {
      if (current) refresh(current);
    }, 5000);
    timer.unref();
  });
  pi.on('agent_end', (_event, ctx) => {
    current = ctx;
    refresh(ctx);
  });
  pi.on('session_shutdown', () => {
    if (timer) clearInterval(timer);
    timer = undefined;
    current = undefined;
  });
  pi.on('tool_call', (event, ctx) => {
    if (!['edit', 'write', 'bash', 'interactive_shell'].includes(event.toolName)) return;

    try {
      return guardDecision(event.toolName, batonFor(ctx.cwd));
    } catch (error) {
      return {
        block: true,
        reason: `Cannot verify worktree baton: ${error instanceof Error ? error.message : String(error)}. Ask Seth, or run /baton take.`,
      };
    }
  });

  pi.registerCommand('ultimate', {
    description: 'Hand this worktree to Ultimate: /ultimate [goal]',
    async handler(args, ctx) {
      try {
        const result = await handoff(ctx, args.trim() || undefined);
        ctx.ui.notify(`Ultimate #${result.conversation} picked up ${result.worktree}: ${result.url}`, 'info');
      } catch (error) {
        ctx.ui.notify(String(error), 'error');
      }
    },
  });
  pi.registerTool({
    name: 'ultimate_handoff',
    label: 'Hand off to Ultimate',
    description: 'Give Ultimate this worktree and goal. Edits are then blocked; end your turn after handing off.',
    parameters: Type.Object({ goal: Type.Optional(Type.String()) }),
    async execute(_id, params, _signal, _update, ctx) {
      try {
        const result = await handoff(ctx, params.goal);

        return resultText(
          `Ultimate #${result.conversation} now holds ${result.worktree}: ${result.url}. Edits are blocked. End your turn now.`,
        );
      } catch (error) {
        return { ...resultText(String(error)), isError: true };
      }
    },
  });
  pi.registerCommand('baton', {
    description: 'Show the worktree baton, or /baton take to take it back',
    async handler(args, ctx) {
      try {
        const root = toplevel(ctx.cwd);
        const baton = readBaton(root);

        if (args.trim() === 'take') {
          const from = originInfo(ctx);
          writeBaton({
            v: 1,
            holder: 'pi',
            worktree: root,
            at: new Date().toISOString(),
            by: 'take',
            ultimate: baton?.ultimate,
            pi: { sessionId: from.sessionId, pid: process.pid, label: from.label },
          });
          refresh(ctx);
          ctx.ui.notify(`Pi holds the baton for ${root}.`, 'info');
        } else if (args.trim()) {
          ctx.ui.notify('Usage: /baton [take]', 'error');
        } else {
          ctx.ui.notify(
            baton
              ? `${baton.holder === 'ultimate' ? `Ultimate #${baton.ultimate?.conversation ?? '?'} (${baton.ultimate?.url ?? 'unknown URL'})` : 'Pi'} holds the baton for ${root} since ${baton.at}.`
              : `Nobody holds the baton for ${root}.`,
            'info',
          );
        }
      } catch (error) {
        ctx.ui.notify(String(error), 'error');
      }
    },
  });
  pi.registerTool({
    name: 'ultimate_read',
    label: 'Read Ultimate',
    description:
      'Read Ultimate conversation history, optionally over SSH. Defaults to this worktree’s baton; use before to page backwards.',
    parameters: Type.Object({
      conversation: Type.Optional(Type.Integer({ minimum: 1 })),
      machine: Type.Optional(Type.String()),
      project: Type.Optional(Type.String()),
      before: Type.Optional(Type.Integer({ minimum: 1 })),
      limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 64 })),
    }),
    annotations: { readOnlyHint: true },
    async execute(_id, params, _signal, _update, ctx) {
      try {
        const baton = batonFor(ctx.cwd);
        const conversation = params.conversation ?? baton?.ultimate?.conversation;

        if (!conversation) throw new Error('Specify conversation, or pick up this worktree in Ultimate first.');
        const inventory = params.machine ? await listTargets(params.machine) : registryTargets(readRegistry());
        const target = historyTarget(inventory, ctx.cwd, baton?.ultimate?.project, params.project);

        if (!target) throw new Error(`no Ultimate runs for ${ctx.cwd}`);

        const history = await ultimateRequest(
          target,
          `/api/conversations/${conversation}/history?before=${params.before ?? 999999999}`,
          historySchema,
        );

        return resultText(formatHistory(history, params.limit));
      } catch (error) {
        return { ...resultText(String(error)), isError: true };
      }
    },
  });
}
