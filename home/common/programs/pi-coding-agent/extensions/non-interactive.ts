/**
 * Non-interactive Mode Extension
 *
 * Detects when pi runs without a TUI (pi -p, pi -c) and appends system prompt
 * instructions that prevent conversational behavior. When the agent cannot ask
 * questions or wait for input, it must make assumptions and keep going.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const NON_INTERACTIVE_INSTRUCTIONS = `

# Non-interactive mode

You are running in non-interactive mode. The user cannot respond to questions or provide additional input.

Rules:
- Never ask clarifying questions. Make reasonable assumptions and proceed.
- Never produce conversational filler ("Would you like me to...", "Let me know if...", "I'll wait for your input").
- Be direct. State what you did, not what you could do.
- If you are blocked or stuck, document the blocker clearly and stop. Do not ask for help.
- Minimize chatter. Output only what is necessary.`;

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", async (_event, ctx: ExtensionContext) => {
    if (ctx.hasUI) return;

    const prompt = _event.systemPrompt + NON_INTERACTIVE_INSTRUCTIONS;
    return { systemPrompt: prompt };
  });
}
