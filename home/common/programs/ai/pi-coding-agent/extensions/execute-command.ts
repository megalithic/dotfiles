import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";

export default function (pi: ExtensionAPI) {
  // Queue of commands to execute after agent turn ends
  let pendingCommand: { command: string; reason?: string } | null = null;

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
        description: "The command or message to execute (e.g., '/answer', '/reload', or any text)" 
      }),
      reason: Type.Optional(
        Type.String({ 
          description: "Optional explanation for why you're executing this command (shown to user)" 
        })
      ),
    }),

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const { command, reason } = params;

      // Store command to be executed after agent turn ends
      pendingCommand = { command, reason };

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
        setTimeout(() => {
          pi.events.emit("trigger:answer", ctx);
        }, 100);
      } 
      // Auto-execute slash commands via sendUserMessage
      else if (command.startsWith("/")) {
        setTimeout(() => {
          pi.sendUserMessage(command);
        }, 100);
      }
      // For non-command text, prefill editor and notify
      else {
        if (ctx.hasUI) {
          ctx.ui.setEditorText(command);
          ctx.ui.notify(`Press Enter to send: ${command}`, "info");
        }
      }
    }
  });
}
