/**
 * Notification Extension for Pi Coding Agent
 *
 * Uses ~/bin/ntfy for intelligent notification routing based on attention state.
 * Features:
 * - Attention detection (terminal focused, display asleep, etc.)
 * - Multi-channel routing (macOS, canvas overlay, phone, Pushover)
 * - Question tracking with reminders
 *
 * Much more sophisticated than OSC 777 escape sequences.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { spawn } from "node:child_process";
import path from "node:path";

const NTFY_PATH = path.join(process.env.HOME || "", "bin", "ntfy");

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
    question?: boolean;
    phone?: boolean;
    pushover?: boolean;
  } = {}
): void {
  const args = ["send", "-t", title, "-m", message, "-s", "pi"];

  if (options.urgency) {
    args.push("-u", options.urgency);
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
  // Notify when agent finishes and is waiting for input
  pi.on("agent_end", async (_event, ctx) => {
    // Only notify if we have a UI (not in headless mode)
    if (ctx.hasUI) {
      notify("Ready for input", "Pi is waiting for your next instruction");
    }
  });

  // Notify on errors with higher urgency
  pi.on("error", async (event) => {
    notify("Error", event.error?.message || "An error occurred", {
      urgency: "high",
    });
  });
}
