/**
 * Pi Bridge Extension
 *
 * Creates a Unix socket for bidirectional communication with pi.
 * Accepts JSON payloads from nvim, Telegram (via Hammerspoon), and other sources.
 * Returns JSON responses to all clients ({ ok: true } / { ok: false, error }).
 *
 * Protocol:
 *   Request:  { type: 'ping' }                         → { ok: true, type: 'pong' }
 *   Request:  { type: 'prompt', message: '...' }        → { ok: true }
 *   Request:  { type: 'editor_state', state: {...} }    → { ok: true }
 *   Request:  { type: 'telegram', text: '...' }         → { ok: true }
 *   Request:  { type: 'tell', text: '...' }             → { ok: true }
 *   Request:  { file: '...', task: '...' }              → { ok: true }  (legacy nvim)
 *   Error:    (any malformed JSON)                      → { ok: false, error: '...' }
 *
 * Discovery:
 *   Socket:   /tmp/pi-{session}.sock
 *   Manifest: /tmp/pi-nvim-sockets/{session}.info  (JSON: socket, cwd, pid, startedAt)
 *
 * Socket Configuration:
 *   Auto-detected from tmux session/window when TMUX env is set.
 *   PI_SOCKET env var overrides auto-detection (for explicit control).
 *   Falls back to /tmp/pi-default-0.sock outside tmux.
 *
 * Socket pattern: /tmp/pi-{session}-{window}.sock
 *
 * Used by:
 *   - This extension (listens on auto-detected or PI_SOCKET path)
 *   - config/nvim/after/plugin/pi.lua (connects to socket)
 *   - config/hammerspoon/lib/interop/pi.lua (forwards Telegram messages)
 *   - bin/ftm (checks for socket existence)
 *   - bin/tmux-toggle-pi (finds/manages agent window)
 *
 * Status display (in footer):
 *   π session:model (green) - socket active (e.g., "π mega:opus-4")
 *   π (dim)                 - socket inactive (regular pi)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import { execSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";

// =============================================================================
// Socket Auto-Detection
// =============================================================================

const SOCKET_DIR = process.env.PI_SOCKET_DIR || "/tmp";
const SOCKET_PREFIX = process.env.PI_SOCKET_PREFIX || "pi";

/** Detect tmux session and window names. Returns null if not in tmux. */
const detectTmux = (): { session: string; window: string } | null => {
  if (!process.env.TMUX) return null;
  try {
    const session = execSync("tmux display-message -p '#{session_name}'", {
      encoding: "utf-8",
      timeout: 2000,
    }).trim();
    const winName = execSync("tmux display-message -p '#{window_name}'", {
      encoding: "utf-8",
      timeout: 2000,
    }).trim();
    const winIndex = execSync("tmux display-message -p '#{window_index}'", {
      encoding: "utf-8",
      timeout: 2000,
    }).trim();
    // Use window name if alphanumeric, otherwise index
    const window =
      winName && /^[a-zA-Z0-9_-]+$/.test(winName) ? winName : winIndex;
    return session && window ? { session, window } : null;
  } catch {
    return null;
  }
};

/** Resolve socket path and session name. */
const resolveSocket = (): {
  socketPath: string | null;
  session: string;
  window: string;
} => {
  // Explicit override takes priority
  if (process.env.PI_SOCKET) {
    return {
      socketPath: process.env.PI_SOCKET,
      session: process.env.PI_SESSION || "default",
      window: process.env.PI_WINDOW || "0",
    };
  }

  // Auto-detect from tmux
  const tmux = detectTmux();
  if (tmux) {
    return {
      socketPath: `${SOCKET_DIR}/${SOCKET_PREFIX}-${tmux.session}-${tmux.window}.sock`,
      session: tmux.session,
      window: tmux.window,
    };
  }

  // Fallback outside tmux
  return {
    socketPath: `${SOCKET_DIR}/${SOCKET_PREFIX}-default-0.sock`,
    session: "default",
    window: "0",
  };
};

const { socketPath: SOCKET_PATH, session: PI_SESSION } = resolveSocket();
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

type TellPayload = {
  type: "tell";
  text: string;
  from?: string;
  timestamp?: number;
};

type PingPayload = {
  type: "ping";
};

type PromptPayload = {
  type: "prompt";
  message: string;
};

type EditorStatePayload = {
  type: "editor_state";
  state: {
    file?: string;
    cursor?: { line: number; col: number };
    selection?: string;
    filetype?: string;
    [key: string]: unknown;
  };
};

type EditorDisconnectPayload = {
  type: "editor_disconnect";
};

type Payload =
  | NvimPayload
  | TelegramPayload
  | TellPayload
  | PingPayload
  | PromptPayload
  | EditorStatePayload
  | EditorDisconnectPayload;

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  "type" in p && p.type === "telegram";

const isTellPayload = (p: Payload): p is TellPayload =>
  "type" in p && p.type === "tell";

const isPingPayload = (p: Payload): p is PingPayload =>
  "type" in p && p.type === "ping";

const isPromptPayload = (p: Payload): p is PromptPayload =>
  "type" in p && p.type === "prompt";

const isEditorStatePayload = (p: Payload): p is EditorStatePayload =>
  "type" in p && p.type === "editor_state";

const isEditorDisconnectPayload = (p: Payload): p is EditorDisconnectPayload =>
  "type" in p && p.type === "editor_disconnect";

// =============================================================================
// Constants
// =============================================================================

const INFO_DIR = "/tmp/pi-nvim-sockets";

// =============================================================================
// State
// =============================================================================

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;
let infoManifestPath: string | null = null;

// Track sockets that have sent editor_state (for crash detection)
const editorSockets = new Set<net.Socket>();

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
// Response Helpers
// =============================================================================

const respond = (socket: net.Socket, data: Record<string, unknown>): void => {
  if (socket.destroyed || !socket.writable) return;
  try {
    socket.write(JSON.stringify(data) + "\n");
  } catch {
    // Client may have disconnected
  }
};

const respondOk = (socket: net.Socket, extra?: Record<string, unknown>): void =>
  respond(socket, { ok: true, ...extra });

const respondError = (socket: net.Socket, error: string): void =>
  respond(socket, { ok: false, error });

// =============================================================================
// Info Manifest
// =============================================================================

const writeInfoManifest = (): void => {
  if (!SOCKET_PATH || !PI_SESSION) return;

  try {
    if (!fs.existsSync(INFO_DIR)) {
      fs.mkdirSync(INFO_DIR, { recursive: true });
    }

    infoManifestPath = `${INFO_DIR}/${PI_SESSION}.info`;
    const manifest = {
      socket: SOCKET_PATH,
      cwd: process.cwd(),
      pid: process.pid,
      session: PI_SESSION,
      startedAt: new Date().toISOString(),
    };
    fs.writeFileSync(infoManifestPath, JSON.stringify(manifest) + "\n");
  } catch {
    // Non-fatal — manifest is for discovery convenience
  }
};

const cleanupInfoManifest = (): void => {
  if (infoManifestPath && fs.existsSync(infoManifestPath)) {
    try {
      fs.unlinkSync(infoManifestPath);
    } catch {
      // Ignore
    }
  }
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

    socket.on("error", (err) => {
      // EPIPE, ECONNRESET, etc. — client disconnected before we could respond.
      // Safe to ignore; socket 'close' event handles cleanup.
    });

    socket.on("close", () => {
      if (editorSockets.has(socket)) {
        editorSockets.delete(socket);
        pi.events.emit("pinvim:editor_disconnect");
      }
    });

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

          // Handle ping/pong
          if (isPingPayload(payload)) {
            respondOk(socket, { type: "pong" });
            continue;
          }

          // Handle prompt injection
          if (isPromptPayload(payload)) {
            if (!payload.message?.trim()) {
              respondError(socket, "prompt message is empty");
              continue;
            }
            const currentCtx = latestCtx;
            if (currentCtx?.isIdle()) {
              void pi.sendUserMessage(payload.message);
            } else {
              void pi.sendUserMessage(payload.message, { deliverAs: "followUp" });
            }
            respondOk(socket);
            continue;
          }

          // Handle editor state (forward to pinvim.ts via event bus)
          if (isEditorStatePayload(payload)) {
            editorSockets.add(socket);
            pi.events.emit("pinvim:editor_state", payload.state);
            respondOk(socket);
            continue;
          }

          // Handle editor disconnect (forward to pinvim.ts)
          if (isEditorDisconnectPayload(payload)) {
            editorSockets.delete(socket);
            pi.events.emit("pinvim:editor_disconnect");
            respondOk(socket);
            continue;
          }

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
            respondOk(socket);
            continue;
          }
          
          // Handle tell/delegate messages from other pi agents
          if (isTellPayload(payload)) {
            const fromSession = payload.from || "unknown";
            const currentCtx = latestCtx;
            
            // Show notification in TUI
            if (currentCtx?.hasUI) {
              currentCtx.ui.notify(`Task from ${fromSession}`, "info");
            }
            
            if (currentCtx?.isIdle()) {
              void pi.sendUserMessage(payload.text);
            } else {
              void pi.sendUserMessage(payload.text, { deliverAs: "followUp" });
            }
            respondOk(socket);
            continue;
          }
          
          // Handle nvim payloads (legacy — no "type" field)
          const message = formatNvimMessage(payload as NvimPayload);
          if (!message) {
            respondError(socket, "empty nvim payload");
            continue;
          }

          const currentCtx = latestCtx;
          if (currentCtx?.isIdle()) {
            void pi.sendUserMessage(message);
          } else {
            void pi.sendUserMessage(message, { deliverAs: "followUp" });
          }
          respondOk(socket);
        } catch {
          respondError(socket, "invalid JSON");
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
      writeInfoManifest();

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

    // Clean up info manifest
    cleanupInfoManifest();
  });
}
