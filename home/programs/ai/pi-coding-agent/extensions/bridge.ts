/**
 * Pi Bridge Extension
 *
 * Creates a Unix socket for external communication with pi.
 * Accepts JSON payloads from nvim, Telegram (via Hammerspoon), and other sources.
 *
 * Socket Configuration (from nix - single source of truth):
 *   - PI_SOCKET_DIR: /tmp
 *   - PI_SOCKET_PREFIX: pi
 *   - PI_SESSION: tmux session name (or "default")
 *   - PI_SOCKET: full path, e.g., /tmp/pi-mega.sock
 *
 * Socket pattern: /tmp/pi-{session}.sock (one per tmux session)
 *
 * Used by:
 *   - pinvim/pisock wrapper (sets PI_SOCKET env var)
 *   - This extension (listens on PI_SOCKET)
 *   - config/nvim/after/plugin/pi-bridge.lua (connects to socket)
 *   - config/hammerspoon/lib/interop/pi.lua (forwards Telegram messages)
 *   - bin/ftm (checks for socket existence)
 *   - bin/tmux-pinvim-toggle (finds/manages agent window)
 *
 * Status display (in footer):
 *   π session:model (green) - socket active (e.g., "π mega:opus-4")
 *   π (dim)                 - socket inactive (regular pi)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import fs from "node:fs";
import net from "node:net";

// Socket configuration from environment (set by pinvim/pisock wrapper)
const SOCKET_PATH = process.env.PI_SOCKET;
const PI_SESSION = process.env.PI_SESSION;
const IS_BRIDGE_ENABLED = !!SOCKET_PATH;

// Status icon
const PI_ICON = "π";

// =============================================================================
// Payload Types
// =============================================================================

type NvimPayload = {
  file?: string;
  range?: [number, number];
  selection?: string;
  lsp?: {
    diagnostics?: string[];
    hover?: string;
  };
  task?: string;
};

type TelegramPayload = {
  type: "telegram";
  text: string;
  source?: string;
  timestamp?: number;
};

type Payload = NvimPayload | TelegramPayload;

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  "type" in p && p.type === "telegram";

// =============================================================================
// State
// =============================================================================

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;

// =============================================================================
// Message Formatting
// =============================================================================

const formatNvimMessage = (payload: NvimPayload): string => {
  const parts: string[] = [];

  if (payload.file) parts.push(`File: ${payload.file}`);
  if (payload.range)
    parts.push(`Lines: ${payload.range[0]}-${payload.range[1]}`);

  if (payload.selection?.trim()) {
    parts.push("Selection:");
    parts.push("```");
    parts.push(payload.selection);
    parts.push("```");
  }

  if (payload.lsp?.diagnostics?.length) {
    parts.push("LSP diagnostics:");
    for (const diag of payload.lsp.diagnostics) parts.push(`- ${diag}`);
  }

  if (payload.lsp?.hover?.trim()) {
    parts.push("LSP hover:");
    parts.push("```");
    parts.push(payload.lsp.hover);
    parts.push("```");
  }

  if (payload.task?.trim()) {
    parts.push(`Task: ${payload.task.trim()}`);
  } else {
    parts.push("Task: (not provided)");
  }

  return parts.join("\n");
};

// =============================================================================
// Status Display
// =============================================================================

const getModelShortName = (modelId: string | undefined): string => {
  if (!modelId) return "?";
  
  // Extract model name, strip provider prefix and version suffixes
  // e.g., "anthropic/claude-opus-4-5-20250131" → "opus-4"
  const name = modelId.split("/").pop() || modelId;
  
  // Common model name shortenings
  if (name.includes("opus")) return "opus-4";
  if (name.includes("sonnet")) return "sonnet-4";
  if (name.includes("haiku")) return "haiku";
  if (name.includes("gpt-4o")) return "gpt-4o";
  if (name.includes("gpt-4")) return "gpt-4";
  if (name.includes("o1")) return "o1";
  if (name.includes("o3")) return "o3";
  
  // Fallback: first part of name
  return name.split("-").slice(0, 2).join("-");
};


// =============================================================================
// Socket Server
// =============================================================================

const startServer = (pi: ExtensionAPI, ctx: ExtensionContext): void => {
  if (!SOCKET_PATH) return;
  if (server) return;

  // Clean up stale socket
  if (fs.existsSync(SOCKET_PATH)) {
    try {
      fs.unlinkSync(SOCKET_PATH);
    } catch {
      // Ignore stale socket errors
    }
  }

  server = net.createServer((socket) => {
    let buffer = "";

    socket.on("data", (chunk) => {
      buffer += chunk.toString();

      let idx = buffer.indexOf("\n");
      while (idx !== -1) {
        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 1);
        idx = buffer.indexOf("\n");

        if (!line) continue;

        try {
          const payload = JSON.parse(line) as Payload;
          
          // Handle Telegram messages
          if (isTelegramPayload(payload)) {
            const telegramMessage = `📱 **Telegram message:**\n${payload.text}`;
            const currentCtx = latestCtx;
            
            // Show notification in TUI
            if (currentCtx?.hasUI) {
              currentCtx.ui.notify("Telegram message received", "info");
            }
            
            if (currentCtx?.isIdle()) {
              void pi.sendUserMessage(telegramMessage);
            } else {
              void pi.sendUserMessage(telegramMessage, { deliverAs: "followUp" });
            }
            continue;
          }
          
          // Handle nvim payloads
          const message = formatNvimMessage(payload as NvimPayload);
          if (!message) continue;

          const currentCtx = latestCtx;
          if (currentCtx?.isIdle()) {
            void pi.sendUserMessage(message);
          } else {
            void pi.sendUserMessage(message, { deliverAs: "followUp" });
          }
        } catch {
          // Ignore malformed payloads
        }
      }
    });
  });

  server.listen(SOCKET_PATH);

  // Update status to connected
};

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;

    // Show initial status

    // Start server if bridge is enabled (invoked via pinvim/pisock)
    if (IS_BRIDGE_ENABLED) {
      startServer(pi, ctx);

      if (ctx.hasUI) {
        ctx.ui.notify(`Bridge listening: ${SOCKET_PATH}`, "info");
      }
    }
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
  });

  // Update status when model changes
  pi.on("model_select", (_event, ctx) => {
    latestCtx = ctx;
  });

  pi.on("session_shutdown", () => {
    server?.close();
    server = null;

    // Clean up socket
    if (SOCKET_PATH && fs.existsSync(SOCKET_PATH)) {
      try {
        fs.unlinkSync(SOCKET_PATH);
      } catch {
        // Ignore cleanup failures
      }
    }
  });
}
