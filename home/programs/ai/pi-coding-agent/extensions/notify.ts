/**
 * Notification Extension for Pi Coding Agent
 *
 * Uses ~/bin/ntfy for intelligent notification routing based on attention state.
 * Features:
 * - Attention detection (terminal focused, display asleep, etc.)
 * - Multi-channel routing (macOS, canvas overlay, phone, Pushover)
 * - Question tracking with reminders
 * - User activity tracking to hint at attention state
 * - Shows last assistant message as notification body
 * - Suppresses notifications during active telegram conversations
 *
 * Much more sophisticated than OSC 777 escape sequences.
 */

import type { AgentMessage, UserMessage } from "@mariozechner/pi-agent-core";
import type { AssistantMessage, TextContent } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn, execSync } from "node:child_process";
import path from "node:path";

const NTFY_PATH = path.join(process.env.HOME || "", "bin", "ntfy");

// Telegram message prefix (set by bridge.ts when forwarding from Hammerspoon)
const TELEGRAM_PREFIX = "📱 **Telegram message:**";

// Track when user last interacted (sent input)
let lastInputTime = Date.now();

// Track when last telegram message was received
let lastTelegramTime = 0;

// How recently a telegram message must be to suppress notifications (ms)
const TELEGRAM_SUPPRESS_WINDOW_MS = 60_000; // 1 minute

// Cache tmux session name (doesnt change during session)
let tmuxSessionName: string | null = null;

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

function getSource(): string {
  const session = getTmuxSessionName();
  return session ? `${session} pi` : "pi";
}

const ATTENTION_THRESHOLD_MS = 30_000;

function isUserLikelyAttentive(): boolean {
  return Date.now() - lastInputTime < ATTENTION_THRESHOLD_MS;
}

function isAssistantMessage(m: AgentMessage): m is AssistantMessage {
  return m.role === "assistant" && Array.isArray(m.content);
}

function isUserMessage(m: AgentMessage): m is UserMessage {
  return m.role === "user";
}

function getTextContent(message: AssistantMessage): string {
  return message.content
    .filter((block): block is TextContent => block.type === "text")
    .map((block) => block.text)
    .join("\n");
}

function getUserMessageText(message: UserMessage): string {
  if (typeof message.content === "string") return message.content;
  return message.content
    .filter((block): block is TextContent => block.type === "text")
    .map((block) => block.text)
    .join("\n");
}

function getLastMeaningfulLine(text: string, maxLength: number = 200): string {
  const lines = text.split("\n").map((l) => l.trim()).filter(Boolean);
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i];
    if (/^```|^---$|^===|^\*\*\*$/.test(line)) continue;
    if (/^[-*]*\s*$|^\d+\.\s*$/.test(line)) continue;
    if (line.length <= maxLength) return line;
    return line.slice(0, maxLength - 3) + "...";
  }
  return "Pi is waiting for your next instruction";
}

function extractNotificationBody(messages: AgentMessage[]): string {
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (isAssistantMessage(msg)) {
      const text = getTextContent(msg);
      if (text) return getLastMeaningfulLine(text);
    }
  }
  return "Pi is waiting for your next instruction";
}

/**
 * Check if telegram conversation is currently active.
 * Returns true if a telegram message was received within the suppress window.
 */
function isTelegramActive(): boolean {
  return Date.now() - lastTelegramTime < TELEGRAM_SUPPRESS_WINDOW_MS;
}

function notify(
  title: string,
  message: string,
  options: {
    urgency?: "normal" | "high" | "critical";
    attention?: boolean;
    question?: boolean;
    phone?: boolean;
  } = {}
): void {
  const args = ["send", "-t", title, "-m", message, "-s", getSource()];
  if (options.urgency) args.push("-u", options.urgency);
  if (options.attention !== undefined) args.push("-a", options.attention ? "true" : "false");
  if (options.question) args.push("-q");
  if (options.phone) args.push("-p");
  const proc = spawn(NTFY_PATH, args, { stdio: "ignore", detached: true });
  proc.unref();
}

// Track pending notification timeout
let pendingNotifyTimeout: ReturnType<typeof setTimeout> | null = null;

// Delay before showing "ready for input" notification (ms)
const NOTIFY_DELAY_MS = 3000;

export default function (pi: ExtensionAPI) {
  pi.on("input", async (_event, _ctx, message) => {
    lastInputTime = Date.now();
    
    // Track telegram messages to suppress duplicate notifications
    if (message && message.startsWith(TELEGRAM_PREFIX)) {
      lastTelegramTime = Date.now();
    }
    
    // Cancel pending notification if user starts typing
    if (pendingNotifyTimeout) {
      clearTimeout(pendingNotifyTimeout);
      pendingNotifyTimeout = null;
    }
  });

  pi.on("agent_end", async (event, ctx) => {
    if (!ctx.hasUI) return;
    
    // Skip notification if conversation includes telegram messages
    // Check if any recent user message was from telegram
    const hasTelegramInConversation = event.messages.some((msg) => {
      if (msg.role !== "user") return false;
      const content = typeof msg.content === "string" 
        ? msg.content 
        : msg.content.filter((b): b is { type: "text"; text: string } => b.type === "text")
            .map((b) => b.text).join("");
      return content.includes(TELEGRAM_PREFIX);
    });
    
    // Skip if telegram conversation OR recent telegram activity
    if (hasTelegramInConversation || isTelegramActive()) {
      return;
    }
    
    const body = extractNotificationBody(event.messages);
    
    // Delay notification to avoid spam when switching focus
    pendingNotifyTimeout = setTimeout(() => {
      pendingNotifyTimeout = null;
      notify("Ready for input", body, {});
    }, NOTIFY_DELAY_MS);
  });
    }, NOTIFY_DELAY_MS);
  });

  pi.on("error", async (event) => {
    notify("Error", event.error?.message || "An error occurred", {
      urgency: "high",
      attention: false,
    });
  });
}
