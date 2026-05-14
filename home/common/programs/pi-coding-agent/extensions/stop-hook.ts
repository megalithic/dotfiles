/**
 * Stop Hook Extension
 *
 * After the agent stops, sends one follow-up asking it to verify it completed
 * everything. Resets counter on each new user prompt so every human message
 * gets at most one automatic follow-up.
 */

import { completeSimple } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

const MAX_FOLLOWUPS = 1;
const MAX_TICKETS_PER_SECTION = 3;

const FORMATTING_RULES = `
IMPORTANT FORMATTING RULES FOR VCS AND TICKET STATUS:
I have provided raw CLI dumps for VCS status and tk tickets below inside <raw_vcs> and <raw_tickets> blocks. DO NOT simply repeat or list this output. Instead, analyze it and provide a very short, concise conversational summary.

For VCS: e.g., "You're on a clean, empty commit." OR "You've got uncommitted working changes currently described as [commit msg]... however, they look like they belong in a separate commit. I recommend..."

For Tickets: e.g., "You've been working on [ticket_id] ([very brief title summary]). It needs to be closed, and I recommend starting on [next_ticket_id] next to continue with this branch."
`;

const STOP_CHECK_PROMPT_BASE = `Review your last response. Did you complete everything the user asked? If not, continue working. If you did complete everything, briefly confirm what was done.

${FORMATTING_RULES}`;

const INTERRUPTED_PROMPT_BASE = `You were interrupted (the user pressed Escape to stop you). Review what you were doing and what state things are in. If work is partially done, summarize where you left off and what remains. Ask the user how they'd like to proceed rather than automatically resuming — they may have stopped you intentionally to change direction.

${FORMATTING_RULES}`;

/**
 * Gather lightweight VCS status (jj or git, whichever is available).
 * Returns a short summary or empty string if no VCS / no changes.
 */
function getVcsContext(): string {
  const run = (cmd: string): string | null => {
    try {
      return execSync(cmd, { encoding: "utf-8", timeout: 5000, stdio: ["pipe", "pipe", "pipe"] }).trim();
    } catch {
      return null;
    }
  };

  // Detect VCS: jj first, then git
  const jjStatus = run("jj status 2>/dev/null");
  if (jjStatus !== null) {
    const jjLog = run("jj log -n 3 --no-pager 2>/dev/null") || "";
    const parts = [`VCS (jj) status:\n${jjStatus}`];
    if (jjLog) parts.push(`Recent commits:\n${jjLog}`);
    return parts.join("\n\n");
  }

  const gitStatus = run("git status --short 2>/dev/null");
  if (gitStatus !== null) {
    const gitLog = run("git log --oneline -3 2>/dev/null") || "";
    const parts = [`VCS (git) status:\n${gitStatus || "(clean)"}`];
    if (gitLog) parts.push(`Recent commits:\n${gitLog}`);
    return parts.join("\n\n");
  }

  return "";
}

/**
 * Gather ticket context if .tickets/ exists in cwd.
 * Returns top in-progress and ready tickets (unblocked + tagged), or empty string.
 */
function getTicketContext(): string {
  const run = (cmd: string): string | null => {
    try {
      return execSync(cmd, { encoding: "utf-8", timeout: 5000, stdio: ["pipe", "pipe", "pipe"] }).trim();
    } catch {
      return null;
    }
  };

  // Only if .tickets/ dir exists (tk is in use for this project)
  const hasTickets = run("test -d .tickets && echo yes");
  if (hasTickets !== "yes") return "";

  const topLines = (text: string | null): string =>
    (text || "")
      .split("\n")
      .filter((line) => line.trim().length > 0)
      .slice(0, MAX_TICKETS_PER_SECTION)
      .join("\n");

  // Get ready (unblocked) tickets tagged for development
  const ready = topLines(run("tk ready -T ready-for-development 2>/dev/null"));
  // Also get in-progress tickets for awareness
  const inProgress = topLines(run("tk list --status=in_progress 2>/dev/null"));

  const parts: string[] = [];
  if (inProgress) parts.push(`Top ${MAX_TICKETS_PER_SECTION} in-progress tickets:\n${inProgress}`);
  if (ready) parts.push(`Top ${MAX_TICKETS_PER_SECTION} ready tickets (unblocked, by priority):\n${ready}`);

  if (parts.length === 0) return "";
  return `<raw_tickets>\nTicket context:\n${parts.join("\n\n")}\n</raw_tickets>`;
}

const MAX_GATEKEEPER_FAILURES = 3;

const GATEKEEPER_PROMPT = `You are a gatekeeper that decides whether an AI coding agent should be nudged to double-check its work.

Given the last user-assistant exchange, answer YES if:
- The assistant used tools (file edits, shell commands, searches) but may not have fully completed the user's request
- The task was non-trivial and verification is worthwhile
- There are signs of incomplete work (partial changes, untested code, missing steps)

Answer NO if:
- The assistant clearly completed everything the user asked
- The work was simple and straightforward (e.g., a single file edit, a quick lookup)
- The assistant already verified its own work

Respond with only YES or NO.`;

const PAIRS_TO_SEND = 3;

function extractText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content))
    return content
      .filter((b: any) => b.type === "text")
      .map((b: any) => b.text)
      .join("\n");
  return "";
}

function buildGatekeeperMessages(messages: any[]) {
  // Single reverse pass: collect last N user-assistant pairs
  const collected: { role: string; content: unknown }[] = [];
  let pairCount = 0;

  for (let i = messages.length - 1; i >= 0 && pairCount < PAIRS_TO_SEND; i--) {
    const m = messages[i];
    if (m.role !== "user" && m.role !== "assistant") continue;
    collected.unshift(m);
    if (m.role === "user") pairCount++;
  }

  const text = collected
    .map((m) => {
      const label = m.role === "user" ? "User" : "Assistant";
      return `${label}:\n${extractText(m.content)}`;
    })
    .join("\n\n");

  return [
    {
      role: "user" as const,
      content: [
        {
          type: "text" as const,
          text: `${GATEKEEPER_PROMPT}\n\n${text}`,
        },
      ],
      timestamp: Date.now(),
    },
  ];
}

/**
 * Call cloud gatekeeper via pi's model registry + completeSimple.
 */
async function askGatekeeper(
  provider: string,
  modelId: string,
  contextMessages: any[],
  ctx: ExtensionContext,
  isOllama: boolean = false
): Promise<boolean | null> {
  const model = ctx.modelRegistry.find(provider, modelId);
  if (!model) return null;

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || (!auth.apiKey && !isOllama)) return null;

  const response = await completeSimple(
    model,
    { messages: contextMessages },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      maxTokens: 16,
    },
  );

  const text = response.content
    .filter((c: any): c is { type: "text"; text: string } => c.type === "text")
    .map((c) => c.text)
    .join("")
    .trim()
    .toUpperCase();

  return !text.startsWith("NO");
}

// Quick heuristic: skip gatekeeper for obvious completions
function looksComplete(messages: any[]): boolean {
  const lastAssistant = [...messages]
    .reverse()
    .find((m: any) => m.role === "assistant");
  if (!lastAssistant) return false;

  const text = extractText(lastAssistant.content).toLowerCase();

  // Check for completion signals in the assistant's response
  const completionSignals = [
    /\ball (changes|tasks|steps) (applied|done|complete|committed)\b/,
    /\bverification passed\b/,
    /\ball tests? (pass|passed)\b/,
  ];

  return completionSignals.some((re) => re.test(text));
}

async function shouldSendNudge(
  messages: any[],
  ctx: ExtensionContext,
  failureCounter: { count: number },
): Promise<boolean> {
  // Skip gatekeeper if too many consecutive failures
  if (failureCounter.count >= MAX_GATEKEEPER_FAILURES) return false;

  // Quick heuristic: skip for obvious completions
  if (looksComplete(messages)) return false;

  const contextMessages = buildGatekeeperMessages(messages);

  // Resolution for multi-pass preset fallback
  const preset = process.env.PI_MULTI_PASS_PRESET || process.env.PI_PROFILE || "mega";
  let fallbackProvider = "rx-anthropic";
  let fallbackModel = "claude-haiku-4-5";
  
  if (preset === "mega") {
    fallbackProvider = "codex";
    fallbackModel = "gpt-4o-mini"; // Standard identifier, assume 5.4-mini meant 4o-mini
  }

  const gatekeepers = [
    // 1. Ollama gemma4:e4b
    { type: "local-e4b", fn: () => askGatekeeper("ollama", "gemma4:e4b", contextMessages, ctx, true) },
    // 2. Ollama gemma4:e2b
    { type: "local-e2b", fn: () => askGatekeeper("ollama", "gemma4:e2b", contextMessages, ctx, true) },
    // 3. Fallback based on profile
    { type: "fallback", fn: () => askGatekeeper(fallbackProvider, fallbackModel, contextMessages, ctx, false) },
  ];

  for (const gatekeeper of gatekeepers) {
    try {
      const result = await gatekeeper.fn();
      if (result !== null) {
        failureCounter.count = 0;
        return result;
      }
    } catch {
      failureCounter.count++;
    }
  }

  // Both unavailable — nudge as safe default (unless too many failures)
  if (failureCounter.count >= MAX_GATEKEEPER_FAILURES) return false;
  return true;
}

export default function (pi: ExtensionAPI) {
  let followupCount = 0;
  const gatekeeperFailures = { count: 0 };

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      followupCount = 0;
    }
  });

  pi.on("agent_end", async (event, _ctx) => {
    if (followupCount >= MAX_FOLLOWUPS) return;

    // Detect if agent was interrupted (user hit Escape)
    const wasInterrupted = event.messages.some(
      (m: any) => m.role === "assistant" && m.n === "aborted",
    );

    // Skip nudge when agent made no tool calls (simple Q&A) — unless interrupted
    if (!wasInterrupted) {
      const hasToolUse = event.messages.some(
        (m: any) =>
          m.role === "assistant" &&
          Array.isArray(m.content) &&
          m.content.some((b: any) => b.type === "toolCall"),
      );
      if (!hasToolUse) return;
    }

    // Skip gatekeeper for interruptions — always nudge on abort
    if (!wasInterrupted) {
      const shouldNudge = await shouldSendNudge(
        event.messages,
        _ctx,
        gatekeeperFailures,
      );
      if (!shouldNudge) return;
    }

    followupCount++;

    // Pick base prompt based on whether agent was interrupted
    const basePrompt = wasInterrupted
      ? INTERRUPTED_PROMPT_BASE
      : STOP_CHECK_PROMPT_BASE;

    // Append VCS + ticket context if available
    const vcsContext = getVcsContext();
    const ticketContext = getTicketContext();
    const contextParts = [basePrompt];
    if (vcsContext) contextParts.push(`<raw_vcs>\n${vcsContext}\n</raw_vcs>`);
    if (ticketContext) contextParts.push(ticketContext); // ticketContext already wrapped in getTicketContext
    const prompt = contextParts.join("\n\n");

    pi.sendUserMessage(prompt, { deliverAs: "followUp" });
  });
}
