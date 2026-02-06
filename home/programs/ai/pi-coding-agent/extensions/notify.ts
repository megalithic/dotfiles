/**
 * Notification Extension for Pi Coding Agent
 *
 * Uses ~/bin/ntfy for intelligent notification routing based on attention state.
 * Features:
 * - Attention detection (terminal focused, display asleep, etc.)
 * - Multi-channel routing (macOS, canvas overlay, phone, Pushover)
 * - Question tracking with reminders
 * - User activity tracking to hint at attention state
 *
 * Much more sophisticated than OSC 777 escape sequences.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn, execSync } from "node:child_process";
import path from "node:path";

const NTFY_PATH = path.join(process.env.HOME || "", "bin", "ntfy");

// Track when user last interacted (sent input)
let lastInputTime = Date.now();

// Cache tmux session name (doesn't change during session)
let tmuxSessionName: string | null = null;

/**
 * Get the current tmux session name, or null if not in tmux.
 */
function getTmuxSessionName(): string | null {
  if (tmuxSessionName !== null) return tmuxSessionName;
  
  if (!process.env.TMUX) {
    tmuxSessionName = "";
    return null;
  }
  
  try {
    const result = execSync("tmux display-message -p '#S'", {
      encoding: "utf-8",
      timeout: 1000,
      stdio: ["pipe", "pipe", "pipe"],
    }).trim();
    tmuxSessionName = result || "";
    return tmuxSessionName || null;
  } catch {
    tmuxSessionName = "";
    return null;
  }
}

/**
 * Get the source string for notifications (e.g., "pi" or "mega pi")
 */
function getSource(): string {
  const session = getTmuxSessionName();
  return session ? `${session} pi` : "pi";
}

// How recently must user have typed to be considered "paying attention"
const ATTENTION_THRESHOLD_MS = 30_000; // 30 seconds

/**
 * Check if user is likely paying attention based on recent input activity.
 * Returns true if user typed within ATTENTION_THRESHOLD_MS, false otherwise.
 */
function isUserLikelyAttentive(): boolean {
  return Date.now() - lastInputTime < ATTENTION_THRESHOLD_MS;
}

/**
 * Send a notification via the ntfy script.
 *
 * @param title - Notification title
 * @param message - Notification body
 * @param options - Additional options
 */
function notify(
  title: string,
  message: string,
  options: {
    urgency?: "normal" | "high" | "critical";
    attention?: boolean; // true = user attentive, false = user away
    question?: boolean;
    phone?: boolean;
    pushover?: boolean;
  } = {}
): void {
  const args = ["send", "-t", title, "-m", message, "-s", getSource()];

  if (options.urgency) {
    args.push("-u", options.urgency);
  }

  // Pass attention hint if provided
  if (options.attention !== undefined) {
    args.push("-a", options.attention ? "true" : "false");
  }

  if (options.question) {
    args.push("-q");
  }

  if (options.phone) {
    args.push("-p");
  }

  if (options.pushover) {
    args.push("-P");
  }

  // Fire and forget - don't wait for completion
  const proc = spawn(NTFY_PATH, args, {
    stdio: "ignore",
    detached: true,
  });
  proc.unref();
}

export default function (pi: ExtensionAPI) {
  // Track user input to determine attention state
  pi.on("input", async () => {
    lastInputTime = Date.now();
  });

  // Notify when agent finishes and is waiting for input
  pi.on("agent_end", async (_event, ctx) => {
    // Only notify if we have a UI (not in headless mode)
    // Don't pass attention hint - let Hammerspoon detect based on window focus
    // (input-based detection causes false positives when user is reading)
    if (ctx.hasUI) {
      notify("Ready for input", "Pi is waiting for your next instruction", {});
    }
  });

  // Notify on errors with higher urgency (always notify, ignore attention)
  pi.on("error", async (event) => {
    notify("Error", event.error?.message || "An error occurred", {
      urgency: "high",
      attention: false, // Always treat errors as needing attention
    });
  });
}
