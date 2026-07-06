import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";

type PendingCommand = { command: string; reason?: string };

const PENDING_COMMAND_KEY = Symbol.for("dotfiles.pi.executeCommand.pending");

function setSharedPendingCommand(command: PendingCommand | null): void {
  (globalThis as Record<symbol, PendingCommand | null>)[PENDING_COMMAND_KEY] =
    command;
}

function dispatchAfterIdle(
  ctx: { isIdle?: () => boolean },
  send: () => void | Promise<void>,
  onDone: () => void,
) {
  const attempt = async (count = 0) => {
    try {
      if (ctx.isIdle && !ctx.isIdle() && count < 20) {
        setTimeout(() => void attempt(count + 1), 50);
        return;
      }

      await Promise.resolve(send());
      onDone();
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes("Agent is already processing") && count < 20) {
        setTimeout(() => void attempt(count + 1), 50);
        return;
      }

      onDone();
      console.warn(`execute_command dispatch failed: ${message}`);
    }
  };

  setTimeout(() => void attempt(), 100);
}

export default function (pi: ExtensionAPI) {
  // Queue of commands to execute after agent turn ends
  let pendingCommand: PendingCommand | null = null;

  // Tool to execute a command/message directly (self-invoke)
  pi.registerTool({
    name: "execute_command",
    label: "Execute Command",
    description: `Execute a slash command or send a message as if the user typed it. The message is added to the session history and triggers a new turn. Use this to:
- Self-invoke /answer after asking multiple questions
- Run /reload after creating skills
- Execute any slash command programmatically
- Send follow-up prompts to yourself

The command/message appears in the conversation as a user message.`,
    promptSnippet:
      "Execute a slash command or send a message as if the user typed it. " +
      "Use to self-invoke /answer after asking questions, run /reload after creating skills, or send follow-up prompts.",

    parameters: Type.Object({
      command: Type.String({
        description:
          "The command or message to execute (e.g., '/answer', '/reload', or any text)",
      }),
      reason: Type.Optional(
        Type.String({
          description:
            "Optional explanation for why you're executing this command (shown to user)",
        }),
      ),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const { command, reason } = params;

      const queuedCommand = { command, reason };

      // Store command to be executed after agent turn ends. Also publish it on
      // globalThis so stop-hook can skip its own follow-up and avoid racing the
      // queued command.
      pendingCommand = queuedCommand;
      setSharedPendingCommand(queuedCommand);

      const explanation = reason
        ? `Queued for execution: ${command}\nReason: ${reason}`
        : `Queued for execution: ${command}`;

      return {
        content: [{ type: "text", text: explanation }],
        details: {
          command,
          reason,
          queued: true,
        },
      };
    },
  });

  // Execute pending command after agent turn completes
  pi.on("agent_end", async (event, ctx) => {
    if (pendingCommand) {
      const { command } = pendingCommand;
      pendingCommand = null;

      // Special handling for /answer via event bus (needs context)
      if (command === "/answer") {
        dispatchAfterIdle(
          ctx,
          () => pi.events.emit("trigger:answer", ctx),
          () => setSharedPendingCommand(null),
        );
      }
      // Auto-execute slash commands via sendUserMessage
      else if (command.startsWith("/")) {
        dispatchAfterIdle(
          ctx,
          () => pi.sendUserMessage(command, { deliverAs: "followUp" }),
          () => setSharedPendingCommand(null),
        );
      }
      // For non-command text, prefill editor and notify
      else {
        if (ctx.hasUI) {
          ctx.ui.setEditorText(command);
          ctx.ui.notify(`Press Enter to send: ${command}`, "info");
        }
        setSharedPendingCommand(null);
      }
    }
  });
}
