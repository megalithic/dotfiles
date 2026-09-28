// @ts-nocheck
/**
 * Agent Status Extension
 *
 * Publishes this pi's coarse activity state to a per-session file so external
 * pickers (bin/ftm) can render attention dots without touching the pi socket.
 * Modeled on fleet's hook approach (nicknisi/fleet): lifecycle events write a
 * tiny status file; readers only do file reads.
 *
 * File: ${PI_STATE_DIR}/status/pi-{session}-{window}.status
 * Line: "<state> <pid> <session>"  (single line, space-separated; session
 *       last so readers match it exactly instead of prefix-matching the
 *       filename, which collides across session names sharing a prefix)
 *
 * States:
 *   idle     session up, no turn running yet (startup, no prompt)
 *   working  agent is thinking / running tools
 *   asking   waiting on the user — structured question (ask_user_question
 *            tool) or the turn's final assistant message ends with a
 *            question mark (prose-question heuristic)
 *   error    turn ended after an error — needs attention
 *   done     turn ended cleanly — agent finished its work
 *
 * Only interactive tmux pis publish (ctx.hasUI + TMUX); ephemeral/subagent
 * runs stay silent. The file is removed on session_shutdown, and readers
 * must validate the pid (kill -0) to ignore crashed leftovers.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const xdgStateHome =
  process.env.XDG_STATE_HOME ||
  (process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");
const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");
const STATUS_DIR = path.join(PI_STATE_DIR, "status");

type AgentState = "idle" | "working" | "asking" | "error" | "done";

let statusPath: string | null = null;
let session: string | null = null;
let sawError = false;

/** Detect tmux session/window for this pane. Returns null outside tmux. */
const detectTmux = (): { session: string; window: string } | null => {
  if (!process.env.TMUX) return null;
  try {
    const target = process.env.TMUX_PANE
      ? `-t '${process.env.TMUX_PANE}' `
      : "";
    const fmt = (f: string): string =>
      execSync(`tmux display-message -p ${target}'${f}'`, {
        encoding: "utf-8",
        timeout: 2000,
      }).trim();
    const sess = fmt("#{session_name}");
    const winName = fmt("#{window_name}");
    const window =
      winName && /^[a-zA-Z0-9_-]+$/.test(winName)
        ? winName
        : fmt("#{window_index}");
    return sess && window ? { session: sess, window } : null;
  } catch {
    return null;
  }
};

const writeState = (state: AgentState): void => {
  if (!statusPath || !session) return;
  try {
    fs.mkdirSync(STATUS_DIR, { recursive: true });
    fs.writeFileSync(statusPath, `${state} ${process.pid} ${session}\n`);
  } catch {
    // Non-fatal — status is advisory
  }
};

const removeStatus = (): void => {
  if (!statusPath) return;
  try {
    fs.unlinkSync(statusPath);
  } catch {
    // Ignore
  }
};

const isAskTool = (toolName: unknown): boolean =>
  typeof toolName === "string" && toolName.includes("ask_user_question");

/**
 * True when the last assistant message reads as a question to the user:
 * its text ends with "?" after trailing markdown/quote/paren noise is
 * stripped. Coarse by design — a status dot, not NLP.
 */
const endsWithQuestion = (messages: unknown): boolean => {
  if (!Array.isArray(messages)) return false;
  for (let i = messages.length - 1; i >= 0; i--) {
    const m = messages[i] as {
      role?: string;
      content?: unknown;
    };
    if (m?.role !== "assistant") continue;
    let text = "";
    if (typeof m.content === "string") {
      text = m.content;
    } else if (Array.isArray(m.content)) {
      text = m.content
        .filter(
          (c): c is { type: string; text: string } =>
            (c as { type?: string })?.type === "text" &&
            typeof (c as { text?: unknown }).text === "string",
        )
        .map((c) => c.text)
        .join("\n");
    }
    return /\?[\s*_`"')\]]*$/.test(text.trimEnd());
  }
  return false;
};

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;
    const tmux = detectTmux();
    if (!tmux) return;
    session = tmux.session;
    statusPath = path.join(
      STATUS_DIR,
      `pi-${tmux.session}-${tmux.window}.status`,
    );
    writeState("idle");
  });

  pi.on("input", () => writeState("working"));

  pi.on("agent_start", () => {
    sawError = false;
    writeState("working");
  });

  pi.on("tool_call", (event) => {
    if (isAskTool(event?.toolName)) writeState("asking");
  });

  pi.on("tool_execution_end", (event) => {
    if (isAskTool(event?.toolName)) writeState("working");
  });

  pi.on("error", () => {
    sawError = true;
  });

  pi.on("agent_end", (event) =>
    writeState(
      sawError
        ? "error"
        : endsWithQuestion((event as { messages?: unknown })?.messages)
          ? "asking"
          : "done",
    ),
  );

  pi.on("session_shutdown", () => removeStatus());
}
