/**
 * Stop Hook Extension
 *
 * After the agent stops, sends one follow-up asking it to verify it completed
 * everything. Resets counter on each new user prompt so every human message
 * gets at most one automatic follow-up.
 */

import {
  completeSimple,
  type SimpleStreamOptions,
} from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

const MAX_FOLLOWUPS = 1;
const MAX_TICKETS_PER_SECTION = 3;
const STOP_HOOK_CHECK_START_EVENT = "mega.stop-hook.check-start";
const STOP_HOOK_CHECK_END_EVENT = "mega.stop-hook.check-end";
const STOP_CHECK_PROMPT_BASE =
  "Review your last response. Did you complete everything the user asked? If the user asked a question, make sure you answered it in a format they could clearly see and understand. Do not run lat_search or lat_check just because of this review prompt; only use lat tools if you continue work and the actual task requires code or documentation changes. If not, continue working only within the user's requested scope. If the user only asked you to investigate, inspect, check, audit, or report findings, do not fix anything now; report findings and ask before changing anything. If you did complete everything, briefly confirm what was done. If ticket context is provided below, suggest the best next ticket(s) by related work first: same parent epic, same plan/task sequence, direct dependents or unblocked siblings, then related scope. Fall back to global priority only after related options.";

/**
 * Run a shell command and return trimmed output, or null on failure.
 */
function run(cmd: string): string | null {
  try {
    return execSync(cmd, {
      encoding: "utf-8",
      timeout: 5000,
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
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
    const hasWorkingChanges =
      !jjStatus.includes("no changes") && jjStatus.length > 0;
    const isEmptyCommit = jjLog.includes("(empty)");

    let summary = "VCS (jj): ";
    if (hasWorkingChanges) {
      const changeCount = jjStatus
        .split("\n")
        .filter((l) => l.trim().length > 0).length;
      summary += `You have ${changeCount} uncommitted working change${changeCount !== 1 ? "s" : ""} on commit "${jjDesc.split("\n")[0] || "(no description)"}". I recommend committing them with jj describe or jj new before continuing.`;
    } else if (isEmptyCommit) {
      summary += `You're on a clean, empty commit ("${jjDesc.split("\n")[0] || "no description"}").`;
    } else {
      summary += `Working copy is clean. Current commit: "${jjDesc.split("\n")[0] || "(no description)"}".`;
    }

    // Parse recent commits for context
    const commitLines = jjLog
      .split("\n")
      .filter((l) => l.trim().length > 0)
      .slice(0, 3);
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
      const changeCount = gitStatus
        .split("\n")
        .filter((l) => l.trim().length > 0).length;
      summary += `You have ${changeCount} uncommitted change${changeCount !== 1 ? "s" : ""}. I recommend committing before continuing.`;
    }

    if (gitLog) {
      summary += ` Recent: ${gitLog
        .split("\n")
        .filter((l) => l.trim().length > 0)
        .join("; ")}`;
    }

    return summary;
  }

  return "";
}

/**
 * Parse ticket context into a concise summary for the prompt.
 * Returns a short conversational string or empty string if no tickets.
 */
function getTicketSummary(messages: any[]): string {
  // Only if .tickets/ dir exists (tk is in use for this project)
  const hasTickets = run("test -d .tickets && echo yes");
  if (hasTickets !== "yes") return "";

  type TicketLine = {
    id: string;
    text: string;
    status?: string;
    priority?: number;
    deps?: string[];
  };
  type TicketMeta = {
    id: string;
    title: string;
    status?: string;
    priority?: number;
    parent?: string;
    deps?: string[];
  };

  const parseTicketLine = (line: string): TicketLine | null => {
    // tk ready format: "dot-xxxx [P2][open] - Title <- [dep]"
    // tk list format: "dot-xxxx [open] - Title"
    const match = line.match(
      /^(\S+)\s+((?:\[[^\]]+\])+)?\s*-\s+(.+?)(?:\s+<-\s+\[([^\]]+)\])?$/,
    );
    if (!match) return null;
    const badges = match[2] || "";
    const priorityMatch = badges.match(/\[P(\d+)\]/);
    const statusMatch = badges.match(/\[(open|in_progress|closed|blocked)\]/);
    return {
      id: match[1],
      text: match[3].trim(),
      status: statusMatch?.[1],
      priority: priorityMatch ? Number(priorityMatch[1]) : undefined,
      deps: match[4]?.split(/[,\s]+/).filter(Boolean) || [],
    };
  };

  const parseTickets = (raw: string | null): TicketLine[] => {
    if (!raw) return [];
    return raw
      .split("\n")
      .map((l) => l.trim())
      .filter((l) => l.length > 0)
      .map(parseTicketLine)
      .filter((t): t is TicketLine => t !== null);
  };

  const showCache = new Map<string, TicketMeta | null>();
  const showTicket = (id: string): TicketMeta | null => {
    if (showCache.has(id)) return showCache.get(id) || null;
    const raw = run(`tk show ${id} 2>/dev/null`);
    if (!raw) {
      showCache.set(id, null);
      return null;
    }
    const meta: TicketMeta = { id, title: "" };
    const title = raw.match(/#\s+(.+)/);
    const status = raw.match(/^status:\s+(\S+)/m);
    const priority = raw.match(/^priority:\s+(\d+)/m);
    const parent = raw.match(/^parent:\s+(\S+)/m);
    const deps = raw.match(/^deps:\s+\[([^\]]*)\]/m);
    meta.title = title?.[1]?.trim() || id;
    meta.status = status?.[1];
    meta.priority = priority ? Number(priority[1]) : undefined;
    meta.parent = parent?.[1];
    meta.deps = deps?.[1]?.split(/[ ,]+/).filter(Boolean) || [];
    showCache.set(id, meta);
    return meta;
  };

  const stripInjectedOverview = (text: string): string => {
    // Prior stop-hook followups include generated VCS/Tickets summaries. Those
    // should not become the next anchor, or unrelated in-progress tickets can
    // keep winning over the ticket the human/assistant just worked on.
    return text
      .replace(/\nVCS \([^\n]+\):[\s\S]*$/m, "")
      .replace(/\nTickets:[\s\S]*$/m, "");
  };

  const recentIds = messages
    .flatMap((m: any) =>
      Array.from(
        stripInjectedOverview(extractText(m.content)).matchAll(
          /\b(?:dot|pca)-[a-z0-9-]+\b/g,
        ),
      ).map((x) => x[0]),
    )
    .reverse();
  const anchorId = recentIds.find((id, idx, arr) => arr.indexOf(id) === idx);
  const anchor = anchorId ? showTicket(anchorId) : null;

  const inProgressRaw = run("tk list --status=in_progress 2>/dev/null");
  const readyRaw = run("tk ready -T ready-for-development 2>/dev/null");
  const readyUnblockedRaw = run("tk ready 2>/dev/null");

  const inProgress = parseTickets(inProgressRaw);
  const ready = [...parseTickets(readyRaw), ...parseTickets(readyUnblockedRaw)];
  const all = [...inProgress, ...ready].filter(
    (ticket, index, tickets) =>
      tickets.findIndex((t) => t.id === ticket.id) === index,
  );

  const anchorWords = new Set(
    (anchor?.title || "").toLowerCase().match(/[a-z0-9]+/g) || [],
  );
  const scored = all
    .map((ticket, index) => {
      const meta = showTicket(ticket.id);
      let score = 0;
      const reasons: string[] = [];

      if (anchorId && ticket.id === anchorId) {
        score += 240;
        reasons.push("active ticket");
      }
      if (anchor?.parent && meta?.parent === anchor.parent) {
        score += 120;
        reasons.push("same epic");
      }
      if (
        anchorId &&
        (ticket.deps?.includes(anchorId) || meta?.deps?.includes(anchorId))
      ) {
        score += 200;
        reasons.push("direct dependent");
      }
      if (ticket.status === "in_progress" || meta?.status === "in_progress") {
        score += 45;
        reasons.push("already in progress");
      }

      const words = new Set(
        ticket.text.toLowerCase().match(/[a-z0-9]+/g) || [],
      );
      const overlap = [...words].filter(
        (w) => w.length > 3 && anchorWords.has(w),
      ).length;
      if (overlap > 0) {
        score += Math.min(overlap * 10, 40);
        reasons.push("related scope");
      }

      score -= (ticket.priority ?? meta?.priority ?? 9) * 2;
      score -= index / 100;
      return { ...ticket, meta, score, reasons };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, MAX_TICKETS_PER_SECTION);

  const isRelatedToAnchor = (ticket: TicketLine): boolean => {
    if (!anchor || !anchorId) return false;
    if (ticket.id === anchorId) return true;
    const meta = showTicket(ticket.id);
    if (anchor.parent && meta?.parent === anchor.parent) return true;
    if (ticket.deps?.includes(anchorId) || meta?.deps?.includes(anchorId))
      return true;
    const words = new Set(ticket.text.toLowerCase().match(/[a-z0-9]+/g) || []);
    return [...words].some((w) => w.length > 3 && anchorWords.has(w));
  };

  const parts: string[] = [];
  if (anchor)
    parts.push(
      `Anchor: ${anchor.id} (${anchor.title})${anchor.parent ? ` parent ${anchor.parent}` : ""}`,
    );
  if (inProgress.length > 0) {
    const relatedInProgress = anchor
      ? inProgress.filter(isRelatedToAnchor)
      : inProgress;
    const otherInProgress = anchor
      ? inProgress.filter((ticket) => !isRelatedToAnchor(ticket))
      : [];

    if (relatedInProgress.length > 0) {
      const items = relatedInProgress
        .slice(0, MAX_TICKETS_PER_SECTION)
        .map((t) => `${t.id} (${t.text})`)
        .join(", ");
      parts.push(`In-progress: ${items}`);
    }

    if (otherInProgress.length > 0) {
      const items = otherInProgress
        .slice(0, MAX_TICKETS_PER_SECTION)
        .map((t) => `${t.id} (${t.text})`)
        .join(", ");
      parts.push(`Other in-progress: ${items}`);
    }
  }
  if (scored.length > 0) {
    const items = scored
      .map(
        (t) =>
          `${t.id} (${t.text}${t.reasons.length ? `; ${t.reasons.join(", ")}` : "; global priority fallback"})`,
      )
      .join(", ");
    parts.push(`Recommended next: ${items}`);
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

function isEditorContextOnly(text: string): boolean {
  const trimmed = text.trim();
  return (
    /^\[(?:NEOVIM|NVIM|PINVIM)\b[^\]]*CONTEXT\]/i.test(trimmed) &&
    !/\nUser input:\s*\S/i.test(trimmed)
  );
}

function isLatInstructionOnly(text: string): boolean {
  return text.trim().startsWith("Before starting work, run `lat_search`");
}

function getLastUserTurnTexts(messages: any[]): string[] {
  let lastUserIndex = -1;
  for (let i = messages.length - 1; i >= 0; i--) {
    if (messages[i].role === "user") {
      lastUserIndex = i;
      break;
    }
  }
  if (lastUserIndex === -1) return [];

  let firstUserIndex = lastUserIndex;
  while (firstUserIndex > 0 && messages[firstUserIndex - 1].role === "user") {
    firstUserIndex--;
  }

  return messages
    .slice(firstUserIndex, lastUserIndex + 1)
    .map((m) => extractText(m.content))
    .map((text) => text.trim())
    .filter(Boolean);
}

function isEditorContextOnlyTurn(messages: any[]): boolean {
  const texts = getLastUserTurnTexts(messages);
  return (
    texts.length > 0 &&
    texts.some(isEditorContextOnly) &&
    texts.every(
      (text) => isEditorContextOnly(text) || isLatInstructionOnly(text),
    )
  );
}

const PENDING_COMMAND_KEY = Symbol.for("dotfiles.pi.executeCommand.pending");

type PendingExecuteCommand = { command: string; reason?: string };

function getSharedPendingExecuteCommand(): PendingExecuteCommand | null {
  return (
    (globalThis as Record<symbol, PendingExecuteCommand | null>)[
      PENDING_COMMAND_KEY
    ] || null
  );
}

function queuedExecuteCommand(messages: any[]): boolean {
  if (getSharedPendingExecuteCommand()) return true;

  const lastAssistant = [...messages]
    .reverse()
    .find((m: any) => m.role === "assistant");
  if (!lastAssistant || !Array.isArray(lastAssistant.content)) return false;
  return lastAssistant.content.some(
    (b: any) => b.type === "toolCall" && b.name === "execute_command",
  );
}

function sendStopHookFollowup(
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  prompt: string,
) {
  const send = (attempt = 0) => {
    try {
      if (!ctx.isIdle() && attempt < 20) {
        setTimeout(() => send(attempt + 1), 50);
        return;
      }

      pi.sendMessage(
        {
          customType: "stop-hook",
          content: prompt,
          display: false,
        },
        { deliverAs: "followUp", triggerTurn: true },
      );
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      if (message.includes("Agent is already processing") && attempt < 20) {
        setTimeout(() => send(attempt + 1), 50);
        return;
      }

      if (message.includes("Agent is already processing")) {
        try {
          pi.sendUserMessage(prompt, { deliverAs: "followUp" });
        } catch {
          // Avoid surfacing stop-hook fallback failures as runtime errors.
        }
      }
    }
  };

  setTimeout(() => send(), 0);
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
 * Call a gatekeeper via the same model pi is using for this session.
 */
async function askGatekeeper(
  contextMessages: any[],
  ctx: ExtensionContext,
  thinkingLevel: ReturnType<ExtensionAPI["getThinkingLevel"]>,
): Promise<boolean | null> {
  const model = ctx.model;
  if (!model) return null;

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || !auth.apiKey) return null;

  const options: SimpleStreamOptions = {
    apiKey: auth.apiKey,
    headers: auth.headers,
    maxTokens: 16,
  };
  if (thinkingLevel !== "off") {
    options.reasoning = thinkingLevel;
  }

  const response = await completeSimple(
    model,
    { messages: contextMessages },
    options,
  );

  if (ctx.signal?.aborted || response.stopReason === "aborted") return null;

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

function wasUserInterrupted(messages: any[], ctx: ExtensionContext): boolean {
  return (
    ctx.signal?.aborted === true ||
    messages.some(
      (m: any) => m.role === "assistant" && m.stopReason === "aborted",
    )
  );
}

async function shouldSendNudge(
  messages: any[],
  ctx: ExtensionContext,
  thinkingLevel: ReturnType<ExtensionAPI["getThinkingLevel"]>,
  failureCounter: { count: number },
): Promise<boolean> {
  if (wasUserInterrupted(messages, ctx)) return false;

  // Skip gatekeeper if too many consecutive failures
  if (failureCounter.count >= MAX_GATEKEEPER_FAILURES) return false;

  // Quick heuristic: skip for obvious completions
  if (looksComplete(messages)) return false;

  const contextMessages = buildGatekeeperMessages(messages);

  // Ask the same model and thinking level pi is using for this session.
  try {
    const result = await askGatekeeper(contextMessages, ctx, thinkingLevel);
    if (wasUserInterrupted(messages, ctx)) return false;
    if (result !== null) {
      failureCounter.count = 0;
      return result;
    }
  } catch {
    failureCounter.count++;
    return false;
  }

  // Default model unavailable — don't nudge without informed decision
  failureCounter.count++;
  return false;
}

export default function (pi: ExtensionAPI) {
  let followupCount = 0;
  const gatekeeperFailures = { count: 0 };

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      followupCount = 0;
    }
  });

  pi.on("agent_end", async (event, ctx) => {
    if (followupCount >= MAX_FOLLOWUPS) return;

    // Escape aborts the stop hook too. During agent_end, ctx.signal is still
    // the active run's AbortSignal; stopReason is the persisted fallback.
    if (wasUserInterrupted(event.messages, ctx)) return;

    // Skip nudge when pinvim/neovim only sent editor context without a user prompt.
    if (isEditorContextOnlyTurn(event.messages)) return;

    // Skip nudge when the assistant queued a self-invoked command via the
    // `execute_command` tool. The execute-command extension will dispatch the
    // queued command (e.g. /answer) on agent_end, and nudging now would race
    // with that follow-up turn and hide its output from the user.
    if (queuedExecuteCommand(event.messages)) return;

    // Skip nudge when agent made no tool calls (simple Q&A).
    const hasToolUse = event.messages.some(
      (m: any) =>
        m.role === "assistant" &&
        Array.isArray(m.content) &&
        m.content.some((b: any) => b.type === "toolCall"),
    );
    if (!hasToolUse) return;

    pi.events.emit(STOP_HOOK_CHECK_START_EVENT, undefined);
    try {
      const shouldNudge = await shouldSendNudge(
        event.messages,
        ctx,
        pi.getThinkingLevel(),
        gatekeeperFailures,
      );
      if (!shouldNudge || wasUserInterrupted(event.messages, ctx)) return;
    } finally {
      pi.events.emit(STOP_HOOK_CHECK_END_EVENT, undefined);
    }

    followupCount++;

    // Append concise VCS + ticket summaries (no raw CLI dumps)
    const vcsSummary = getVcsSummary();
    const ticketSummary = getTicketSummary(event.messages);
    const contextParts = [STOP_CHECK_PROMPT_BASE];
    if (vcsSummary) contextParts.push(vcsSummary);
    if (ticketSummary) contextParts.push(ticketSummary);
    const prompt = contextParts.join("\n\n");

    sendStopHookFollowup(pi, ctx, prompt);
  });
}
