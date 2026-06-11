/**
 * Pi Bridge Extension
 *
 * Transitional non-nvim ingress on a Unix socket.
 * Disabled by default; pinvim.ts owns the primary pi socket and all nvim/pinvim
 * peer behavior. Bridge has no knowledge of pinvim peer frames anymore.
 * Enable with PI_BRIDGE_LEGACY_SOCKET=1 to accept Telegram (via Hammerspoon)
 * and tell payloads on a dedicated socket; nvim/pinvim frames are not handled
 * here even when enabled.
 *
 * Protocol:
 *   Request:  { type: 'ping' }                  → { ok: true, type: 'pong' }
 *   Request:  { type: 'telegram', text: '...' } → { ok: true }
 *   Request:  { type: 'tell', text: '...' }     → { ok: true }
 *   Request:  any other typed payload           → { ok: false, error: '...' }
 *   Error:    (any malformed JSON)              → { ok: false, error: '...' }
 *
 * Discovery:
 *   Socket:   ${PI_STATE_DIR}/sockets/pi-{session}-{window}.sock
 *   Manifest: ${PI_STATE_DIR}/manifests/{socket-basename}.info
 *             (JSON: socket, cwd, pid, session, window, pane, startedAt)
 *
 * Socket Configuration:
 *   Auto-detected from tmux session/window when TMUX env is set.
 *   PI_SOCKET env var overrides auto-detection (for explicit control).
 *   Falls back to ${PI_STATE_DIR}/sockets/pi-default-0.sock outside tmux.
 *
 * Used by:
 *   - This extension (listens on auto-detected or PI_SOCKET path)
 *   - config/hammerspoon/lib/interop/pi.lua (forwards Telegram messages)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";

// =============================================================================
// Socket Auto-Detection
// =============================================================================

const xdgStateHome =
  process.env.XDG_STATE_HOME ||
  (process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");
const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");
const SOCKET_DIR = path.join(PI_STATE_DIR, "sockets");
const INFO_DIR = path.join(PI_STATE_DIR, "manifests");
const SOCKET_PREFIX = "pi";

/** Detect tmux session/window/pane names. Returns null if not in tmux. */
const detectTmux = (): {
  session: string;
  window: string;
  pane?: string;
} | null => {
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
    const pane = execSync("tmux display-message -p '#{pane_id}'", {
      encoding: "utf-8",
      timeout: 2000,
    }).trim();
    // Use window name if alphanumeric, otherwise index
    const window =
      winName && /^[a-zA-Z0-9_-]+$/.test(winName) ? winName : winIndex;
    return session && window ? { session, window, pane } : null;
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

const {
  socketPath: SOCKET_PATH,
  session: PI_SESSION,
  window: PI_WINDOW,
} = resolveSocket();
const IS_BRIDGE_ENABLED =
  !!SOCKET_PATH && process.env.PI_BRIDGE_LEGACY_SOCKET === "1";

// =============================================================================
// Payload Types
// =============================================================================

type TelegramPayload = {
  type: "telegram";
  text: string;
  source?: string;
  timestamp?: number;
};

type TellPayload = {
  type: "tell";
  protocol?: "pi.tell.v1" | string;
  id?: string;
  text: string;
  from?: string;
  fromSocket?: string;
  timestamp?: number;
};

type TellAckPayload = {
  type: "tell_ack";
  id?: string;
  to?: string;
  timestamp?: number;
};

type PingPayload = {
  type: "ping";
};

type Payload = TelegramPayload | TellPayload | TellAckPayload | PingPayload;

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  "type" in p && p.type === "telegram";

const isTellPayload = (p: Payload): p is TellPayload =>
  "type" in p && p.type === "tell";

const isTellAckPayload = (p: Payload): p is TellAckPayload =>
  "type" in p && p.type === "tell_ack";

const isPingPayload = (p: Payload): p is PingPayload =>
  "type" in p && p.type === "ping";

// =============================================================================
// State
// =============================================================================

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;
let infoManifestPath: string | null = null;

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

// Send async acknowledgement to the sender's socket
const sendTellAck = async (
  toSocket: string,
  originalFrom: string,
  tellId?: string,
): Promise<void> => {
  const client = net.createConnection(toSocket);
  const ack: TellAckPayload = {
    type: "tell_ack",
    id: tellId,
    to: originalFrom,
    timestamp: Math.floor(Date.now() / 1000),
  };

  const timeoutMs = 500;
  const timer = setTimeout(() => {
    client.destroy();
  }, timeoutMs);

  client.on("error", () => {
    clearTimeout(timer);
    client.destroy();
  });

  client.on("connect", () => {
    try {
      client.write(JSON.stringify(ack) + "\n");
    } catch {
      // Ignore errors sending ack
    }
    clearTimeout(timer);
    client.destroy();
  });
};

// =============================================================================
// Info Manifest
// =============================================================================

const writeInfoManifest = (): void => {
  if (!SOCKET_PATH || !PI_SESSION) return;

  try {
    if (!fs.existsSync(INFO_DIR)) {
      fs.mkdirSync(INFO_DIR, { recursive: true });
    }

    // Key manifest by socket basename so multiple pis per tmux session (e.g.
    // primary + ephemeral) don't clobber each other's manifests.
    const socketBase =
      SOCKET_PATH.split("/")
        .pop()
        ?.replace(/\.sock$/, "") || PI_SESSION;
    infoManifestPath = `${INFO_DIR}/${socketBase}.info`;
    const manifest = {
      socket: SOCKET_PATH,
      cwd: process.cwd(),
      pid: process.pid,
      session: PI_SESSION,
      window: PI_WINDOW,
      pane: detectTmux()?.pane,
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

  fs.mkdirSync(path.dirname(SOCKET_PATH), { recursive: true });

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
              void pi.sendUserMessage(telegramMessage, {
                deliverAs: "followUp",
              });
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
            // Send async acknowledgement back to sender
            if (payload.fromSocket && payload.protocol === "pi.tell.v1") {
              void sendTellAck(payload.fromSocket, fromSession, payload.id);
            }
            respondOk(socket, { id: payload.id, type: "tell_ack" });
            continue;
          }

          // Handle tell_ack messages (acknowledgement from receivers)
          if (isTellAckPayload(payload)) {
            const toLabel = payload.to || "unknown";
            const currentCtx = latestCtx;

            // Show notification in TUI
            if (currentCtx?.hasUI) {
              currentCtx.ui.notify(`Tell acknowledged by ${toLabel}`, "info");
            }
            respondOk(socket);
            continue;
          }

          if ("type" in payload) {
            respondError(
              socket,
              `unsupported payload type: ${String(payload.type)}`,
            );
            continue;
          }

          respondError(socket, "unsupported untyped bridge payload");
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

    // Start transitional server only when explicitly enabled.
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
