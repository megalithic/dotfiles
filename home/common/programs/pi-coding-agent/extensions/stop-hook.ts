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

const STOP_CHECK_PROMPT_BASE =
  "Review your last response. Did you complete everything the user asked? If not, continue working. If you did complete everything, briefly confirm what was done. If ticket context is provided below, suggest the best next ticket(s) to work on based on priority and dependency order.";

const INTERRUPTED_PROMPT_BASE =
  "You were interrupted (the user pressed Escape to stop you). Review what you were doing and what state things are in. If work is partially done, summarize where you left off and what remains. Ask the user how they'd like to proceed rather than automatically resuming — they may have stopped you intentionally to change direction.";

/**
 * Run a shell command and return trimmed output, or null on failure.
 */
function run(cmd: string): string | null {
  try {
    return execSync(cmd, { encoding: "utf-8", timeout: 5000, stdio: ["pipe", "pipe", "pipe"] }).trim();
  } catch {
    return null;
  }
}

/**
 * Parse jj/git status into a concise VCS summary for the prompt.
 * Returns a short conversational string or empty string if no VCS.
 */
function getVcsSummary(): string {
  // --- jj ---
  const jjStatus = run("jj status 2>/dev/null");
  if (jjStatus !== null) {
    const jjLog = run("jj log -n 3 --no-pager 2>/dev/null") || "";
    const jjDesc = run("jj description 2>/dev/null") || "";

    // Parse working copy state from jj status output
    const hasWorkingChanges = !jjStatus.includes("no changes") && jjStatus.length > 0;
    const isEmptyCommit = jjLog.includes("(empty)");

    let summary = "VCS (jj): ";
    if (hasWorkingChanges) {
      const changeCount = jjStatus.split("\n").filter((l) => l.trim().length > 0).length;
      summary += `You have ${changeCount} uncommitted working change${changeCount !== 1 ? "s" : ""} on commit "${jjDesc.split("\n")[0] || "(no description)"}". I recommend committing them with jj describe or jj new before continuing.`;
    } else if (isEmptyCommit) {
      summary += `You're on a clean, empty commit ("${jjDesc.split("\n")[0] || "no description"}").`;
    } else {
      summary += `Working copy is clean. Current commit: "${jjDesc.split("\n")[0] || "(no description)"}".`;
    }

    // Parse recent commits for context
    const commitLines = jjLog.split("\n").filter((l) => l.trim().length > 0).slice(0, 3);
    if (commitLines.length > 0) {
      summary += ` Recent: ${commitLines.map((l) => l.replace(/\s+/g, " ").trim()).join("; ")}`;
    }

    return summary;
  }

  // --- git fallback ---
  const gitStatus = run("git status --short 2>/dev/null");
  if (gitStatus !== null) {
    const isClean = gitStatus.length === 0;
    const gitLog = run("git log --oneline -3 2>/dev/null") || "";

    let summary = "VCS (git): ";
    if (isClean) {
      summary += "Working tree is clean.";
    } else {
      const changeCount = gitStatus.split("\n").filter((l) => l.trim().length > 0).length;
      summary += `You have ${changeCount} uncommitted change${changeCount !== 1 ? "s" : ""}. I recommend committing before continuing.`;
    }

    if (gitLog) {
      summary += ` Recent: ${gitLog.split("\n").filter((l) => l.trim().length > 0).join("; ")}`;
    }

    return summary;
  }

  return "";
}

/**
 * Parse ticket context into a concise summary for the prompt.
 * Returns a short conversational string or empty string if no tickets.
 */
function getTicketSummary(): string {
  // Only if .tickets/ dir exists (tk is in use for this project)
  const hasTickets = run("test -d .tickets && echo yes");
  if (hasTickets !== "yes") return "";

  const inProgressRaw = run("tk list --status=in_progress 2>/dev/null");
  const readyRaw = run("tk ready -T ready-for-development 2>/dev/null");
  // Also get unblocked ready tickets without tag filter
  const readyUnblockedRaw = run("tk ready 2>/dev/null");

  const parseTicketLine = (line: string): { id: string; text: string } | null => {
    // tk list format: "dot-xxxx [status] - Title text"
    const match = line.match(/^(\S+)\s+\[\S+\]\s+-\s+(.+)/);
    if (!match) return null;
    return { id: match[1], text: match[2].trim() };
  };

  const parseTopTickets = (raw: string | null, max: number): { id: string; text: string }[] => {
    if (!raw) return [];
    return raw
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0)
      .slice(0, max)
      .map(parseTicketLine)
      .filter((t): t is { id: string; text: string } => t !== null);
  };

  const inProgress = parseTopTickets(inProgressRaw, MAX_TICKETS_PER_SECTION);
  const ready = parseTopTickets(readyRaw.length ? readyRaw : readyUnblockedRaw, MAX_TICKETS_PER_SECTION);

  const parts: string[] = [];

  if (inProgress.length > 0) {
    const items = inProgress.map((t) => `${t.id} (${t.text})`).join(", ");
    parts.push(`In-progress: ${items}`);
  }

  if (ready.length > 0) {
    const items = ready.map((t) => `${t.id} (${t.text})`).join(", ");
    parts.push(`Ready next: ${items}`);
  }

  if (parts.length === 0) return "";
  return `Tickets: ${parts.join(". ")}.`;
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

    // Append concise VCS + ticket summaries (no raw CLI dumps)
    const vcsSummary = getVcsSummary();
    const ticketSummary = getTicketSummary();
    const contextParts = [basePrompt];
    if (vcsSummary) contextParts.push(vcsSummary);
    if (ticketSummary) contextParts.push(ticketSummary);
    const prompt = contextParts.join("\n\n");

    pi.sendUserMessage(prompt, { deliverAs: "followUp" });
  });
}
