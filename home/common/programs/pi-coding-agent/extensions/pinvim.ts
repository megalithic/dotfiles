/**
 * Pinvim Extension
 *
 * Primary pi-side nvim integration.
 * Owns pinvim socket, peer metadata, UI surfaces, and explicit context delivery.
 * bridge.ts does not handle nvim/pinvim frames.
 *
 * Context path is explicit nvim send (`gps` / `gpa` / :PinvimSend) to avoid spurious
 * nvim→pi messages.
 *
 * Current pinvim inputs:
 *   - socket frames: prompt / explicit_send / hello / heartbeat / ping
 *   - pi commands: /pinvim-info /pinvim-health /pinvim-status /pinvim-send
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";
import fs from "node:fs";
import fsp from "node:fs/promises";
import net from "node:net";
import path from "node:path";

// =============================================================================
// Socket discovery
// =============================================================================

const xdgStateHome =
  process.env.XDG_STATE_HOME ||
  (process.env.HOME ? path.join(process.env.HOME, ".local", "state") : "/tmp");
const PI_STATE_DIR = process.env.PI_STATE_DIR || path.join(xdgStateHome, "pi");
const SOCKET_DIR = path.join(PI_STATE_DIR, "sockets");
const INFO_DIR = path.join(PI_STATE_DIR, "manifests");
const SOCKET_PREFIX = "pi";

let tmuxCache: { at: number; value: { session: string; window: string; pane?: string } | null } = {
  at: 0,
  value: null,
};

const parseTmux = (stdout: string): { session: string; window: string; pane?: string } | null => {
  const [session, winName, winIndex, pane] = stdout.trim().split("\t");
  const window = winName && /^[a-zA-Z0-9_-]+$/.test(winName) ? winName : winIndex;
  return session && window ? { session, window, pane } : null;
};

const detectTmux = (callback: (tmux: { session: string; window: string; pane?: string } | null) => void): void => {
  if (!process.env.TMUX) {
    callback(null);
    return;
  }

  if (tmuxCache.value && Date.now() - tmuxCache.at < 5000) {
    callback(tmuxCache.value);
    return;
  }

  execFile(
    "tmux",
    ["display-message", "-p", "#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}"],
    { encoding: "utf-8", timeout: 2000 },
    (err, stdout) => {
      const tmux = err ? null : parseTmux(stdout);
      tmuxCache = { at: Date.now(), value: tmux };
      callback(tmux);
    },
  );
};

let SOCKET_PATH: string | null = process.env.PI_SOCKET || null;
let PI_SESSION = process.env.PI_SESSION || "default";
let PI_WINDOW = process.env.PI_WINDOW || "0";
let PI_PANE: string | undefined;

if (SOCKET_PATH) {
  const match = SOCKET_PATH.match(/\/pi-([^-]+)-([^.]+?)(?:-eph-[^/]+)?\.sock$/);
  if (match) {
    PI_SESSION = process.env.PI_SESSION || match[1];
    PI_WINDOW = process.env.PI_WINDOW || match[2];
  }
} else if (!process.env.TMUX) {
  SOCKET_PATH = `${SOCKET_DIR}/${SOCKET_PREFIX}-default-0.sock`;
}

const resolveSocketAsync = (callback: () => void): void => {
  if (SOCKET_PATH) {
    callback();
    return;
  }

  detectTmux((tmux) => {
    if (tmux) {
      PI_SESSION = tmux.session;
      PI_WINDOW = tmux.window;
      PI_PANE = tmux.pane;
      SOCKET_PATH = `${SOCKET_DIR}/${SOCKET_PREFIX}-${tmux.session}-${tmux.window}.sock`;
    } else {
      SOCKET_PATH = `${SOCKET_DIR}/${SOCKET_PREFIX}-default-0.sock`;
    }
    callback();
  });
};

const isPinvimSocketEnabled = (): boolean => !!SOCKET_PATH;
const isEphemeral = (): boolean =>
  process.env.PI_EPHEMERAL === "1" ||
  (!!SOCKET_PATH && /-eph-[^/]+\.sock$/.test(SOCKET_PATH));

// =============================================================================
// Protocol types
// =============================================================================

type LinkMode = "auto" | "manual" | "ephemeral" | "parked" | "explicit" | "bootstrap" | string;

interface PeerIdentity {
  id: string;
  kind: "nvim" | "pi";
  cwd: string;
  root?: string;
  tmux?: {
    session?: string;
    window?: string;
    pane?: string;
  };
  linkMode: LinkMode;
  heartbeatAt?: number;
}

interface HelloPayload {
  type: "hello";
  protocol: "pinvim.peer.v1";
  peer: PeerIdentity;
  capabilities?: {
    compose?: boolean;
    explicitSend?: boolean;
  };
}

interface HelloAckPayload {
  type: "hello_ack";
  protocol: "pinvim.peer.v1";
  peer: PeerIdentity;
  accepts?: string[];
}

interface HeartbeatPayload {
  type: "heartbeat";
  protocol: "pinvim.peer.v1";
  peerId: string;
  sentAt: number;
}

interface PingPayload {
  type: "ping";
}

interface PromptPayload {
  type: "prompt";
  message: string;
}

interface ExplicitSendPayload {
  type: "explicit_send";
  context: {
    kind?: "selection" | "cursor";
    file?: string;
    absFile?: string;
    filetype?: string;
    cursor?: { line: number; col: number };
    selection?: string;
    selectionRange?: [number, number];
    word?: string;
    symbolKind?: string;
    hasDiagnostics?: boolean;
    lspActive?: boolean;
    userInput?: string;
    cwd?: string;
    root?: string;
    modified?: boolean;
    [key: string]: unknown;
  };
}

interface TelegramPayload {
  type: "telegram";
  text: string;
  source?: string;
  timestamp?: number;
}

interface TellPayload {
  type: "tell";
  text: string;
  from?: string;
  timestamp?: number;
}

type Payload =
  | HelloPayload
  | HeartbeatPayload
  | PingPayload
  | PromptPayload
  | ExplicitSendPayload
  | TelegramPayload
  | TellPayload;

interface PinvimState {
  protocol: "pinvim.peer.v1";
  lastHello: HelloPayload | null;
  lastHelloAck: HelloAckPayload | null;
  lastHeartbeat: HeartbeatPayload | null;
}

interface PinvimHealth {
  ok: boolean;
  activePeerId: string | null;
  heartbeatAgeSeconds: number | null;
}

// =============================================================================
// State
// =============================================================================

const state: PinvimState = {
  protocol: "pinvim.peer.v1",
  lastHello: null,
  lastHelloAck: null,
  lastHeartbeat: null,
};

let latestCtx: ExtensionContext | null = null;
let server: net.Server | null = null;
let infoManifestPath: string | null = null;
const startedAt = new Date().toISOString();

// =============================================================================
// Type guards
// =============================================================================

const hasType = (p: Payload): p is Payload & { type: string } =>
  typeof p === "object" && p !== null && "type" in p;

const isHelloPayload = (p: Payload): p is HelloPayload =>
  hasType(p) && p.type === "hello";

const isHeartbeatPayload = (p: Payload): p is HeartbeatPayload =>
  hasType(p) && p.type === "heartbeat";

const isPingPayload = (p: Payload): p is PingPayload =>
  hasType(p) && p.type === "ping";

const isPromptPayload = (p: Payload): p is PromptPayload =>
  hasType(p) && p.type === "prompt";

const isExplicitSendPayload = (p: Payload): p is ExplicitSendPayload =>
  hasType(p) && p.type === "explicit_send";

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  hasType(p) && p.type === "telegram";

const isTellPayload = (p: Payload): p is TellPayload =>
  hasType(p) && p.type === "tell";

// =============================================================================
// Formatting
// =============================================================================

const getActivePeer = (): PeerIdentity | null =>
  state.lastHelloAck?.peer || state.lastHello?.peer || null;

const buildPinvimPeerIdentity = (): PeerIdentity => ({
  id: `pi:${PI_SESSION}:${PI_WINDOW}:${process.pid}`,
  kind: "pi",
  cwd: process.cwd(),
  root: process.cwd(),
  tmux: {
    session: PI_SESSION,
    window: PI_WINDOW,
    pane: PI_PANE,
  },
  linkMode: process.env.PINVIM_LINK_MODE || "auto",
  heartbeatAt: Math.floor(Date.now() / 1000),
});

const buildHelloAck = (): HelloAckPayload => ({
  type: "hello_ack",
  protocol: "pinvim.peer.v1",
  peer: buildPinvimPeerIdentity(),
  accepts: ["hello", "heartbeat", "ping", "prompt", "explicit_send"],
});

const formatExplicitContext = (payload: ExplicitSendPayload): string => {
  const { context } = payload;
  const parts: string[] = ["[NEOVIM EXPLICIT CONTEXT]"];

  if (context.kind) parts.push(`Kind: ${context.kind}`);
  if (context.file) parts.push(`Focused file: ${context.file}`);
  if (context.filetype) parts.push(`Filetype: ${context.filetype}`);
  if (context.cursor) parts.push(`Cursor: L${context.cursor.line}:C${context.cursor.col}`);
  if (context.selectionRange) parts.push(`Range: lines ${context.selectionRange[0]}-${context.selectionRange[1]}`);
  if (context.word) {
    const label = context.symbolKind
      ? `${context.symbolKind} \`${context.word}\``
      : `\`${context.word}\``;
    parts.push(`Symbol: ${label} \u25C0 cursor focus`);
    if (context.hasDiagnostics) parts.push("Diagnostics: present at cursor");
    if (context.lspActive) parts.push("LSP: active");
  }

  if (context.selection?.trim()) {
    parts.push(context.kind === "selection" ? "Selected text:" : "Cursor context:");
    parts.push(`\`\`\`${context.filetype || ""}`);
    parts.push(context.selection);
    parts.push("```");
  }

  if (context.userInput?.trim()) {
    parts.push("User input:");
    parts.push(context.userInput.trim());
  }

  if (context.modified) parts.push("Buffer: modified (unsaved)");

  parts.push("User explicitly sent this context from Neovim.");
  return parts.join("\n");
};

const formatPeerStatus = (): string => {
  const peer = getActivePeer();
  if (!peer) return "";
  const label = peer.root || peer.cwd || peer.id;
  return `│ pinvim:${label.split("/").pop() || label}`;
};

const formatStatus = (): string => formatPeerStatus();

const getHealth = (): PinvimHealth => {
  const activePeer = getActivePeer();
  const heartbeatAgeSeconds = state.lastHeartbeat?.sentAt
    ? Math.max(Math.floor(Date.now() / 1000) - state.lastHeartbeat.sentAt, 0)
    : null;
  return {
    ok: !!activePeer && (heartbeatAgeSeconds === null || heartbeatAgeSeconds < 120),
    activePeerId: activePeer?.id || null,
    heartbeatAgeSeconds,
  };
};

const renderInfoLines = (): string[] => {
  const lastHello = state.lastHello
    ? JSON.stringify(state.lastHello, null, 2)
    : "(none yet)";
  const lastHelloAck = state.lastHelloAck
    ? JSON.stringify(state.lastHelloAck, null, 2)
    : "(none yet)";
  const lastHeartbeat = state.lastHeartbeat
    ? JSON.stringify(state.lastHeartbeat, null, 2)
    : "(none yet)";
  const activePeer = getActivePeer();

  return [
    "pinvim state",
    `Protocol: ${state.protocol}`,
    `Socket: ${SOCKET_PATH || "(disabled)"}`,
    `Active peer: ${activePeer ? JSON.stringify(activePeer, null, 2) : "(none yet)"}`,
    "Responsibilities:",
    "- owns pinvim socket for all nvim↔pi frames",
    "- owns peer metadata + footer status",
    "- explicit sends become user messages; active sessions receive followUp",
    "Current pinvim socket inputs:",
    "- prompt / explicit_send user context frames",
    "- hello / hello_ack / heartbeat peer metadata frames",
    "- ping health frames",
    `Last hello: ${lastHello}`,
    `Last hello_ack: ${lastHelloAck}`,
    `Last heartbeat: ${lastHeartbeat}`,
  ];
};

// =============================================================================
// Delivery and socket helpers
// =============================================================================

const updateStatus = (): void => {
  const ctx = latestCtx;
  if (!ctx) return;
  try {
    if (!ctx.hasUI) return;
    ctx.ui.setStatus("pinvim", formatStatus());
  } catch {
    latestCtx = null;
  }
};

const deliverMessage = (pi: ExtensionAPI, message: string): void => {
  if (!message.trim()) return;

  const ctx = latestCtx;
  if (!ctx) {
    void pi.sendUserMessage(message);
    return;
  }

  if (ctx.isIdle()) {
    void pi.sendUserMessage(message);
  } else {
    void pi.sendUserMessage(message, { deliverAs: "followUp" });
  }
};

const respond = (socket: net.Socket, data: Record<string, unknown>): void => {
  if (socket.destroyed || !socket.writable) return;
  try {
    socket.write(JSON.stringify(data) + "\n");
  } catch {
    // Client may have disconnected.
  }
};

const respondOk = (socket: net.Socket, extra?: Record<string, unknown>): void =>
  respond(socket, { ok: true, ...extra });

const respondError = (socket: net.Socket, error: string): void =>
  respond(socket, { ok: false, error });

let manifestWriteTimer: NodeJS.Timeout | null = null;
let manifestWriteInFlight = false;
let lastManifestWriteAt = 0;

const writeInfoManifestNow = async (): Promise<void> => {
  if (!SOCKET_PATH || !PI_SESSION || manifestWriteInFlight) return;

  manifestWriteInFlight = true;
  try {
    await fsp.mkdir(INFO_DIR, { recursive: true });
    const socketBase = SOCKET_PATH.split("/").pop()?.replace(/\.sock$/, "") || PI_SESSION;
    infoManifestPath = `${INFO_DIR}/${socketBase}.info`;
    const manifest = {
      socket: SOCKET_PATH,
      cwd: process.cwd(),
      pid: process.pid,
      session: PI_SESSION,
      window: PI_WINDOW,
      pane: PI_PANE,
      ephemeral: isEphemeral(),
      owner: "pinvim.ts",
      heartbeatAt: Math.floor(Date.now() / 1000),
      startedAt,
    };
    await fsp.writeFile(infoManifestPath, JSON.stringify(manifest) + "\n");
    lastManifestWriteAt = Date.now();
  } catch {
    // Non-fatal — manifest is for discovery convenience.
  } finally {
    manifestWriteInFlight = false;
  }
};

const scheduleInfoManifest = (force = false): void => {
  if (!SOCKET_PATH || !PI_SESSION) return;
  if (!force && Date.now() - lastManifestWriteAt < 5000) return;
  if (manifestWriteTimer) return;

  // Heartbeats can be frequent; write manifest async + throttled so socket frame
  // handling never waits on mkdir/writeFile.
  manifestWriteTimer = setTimeout(() => {
    manifestWriteTimer = null;
    void writeInfoManifestNow();
  }, force ? 0 : 250);
};

const cleanupInfoManifest = (): void => {
  if (infoManifestPath && fs.existsSync(infoManifestPath)) {
    try {
      fs.unlinkSync(infoManifestPath);
    } catch {
      // Ignore.
    }
  }
};

const handleSocketPayload = (pi: ExtensionAPI, socket: net.Socket, payload: Payload): void => {
  if (isPingPayload(payload)) {
    respondOk(socket, { type: "pong" });
    return;
  }

  if (isHelloPayload(payload)) {
    if (payload.protocol !== "pinvim.peer.v1") {
      respondError(socket, `unsupported pinvim protocol: ${payload.protocol}`);
      return;
    }

    state.lastHello = payload;
    const helloAck = buildHelloAck();
    state.lastHelloAck = helloAck;
    updateStatus();
    respondOk(socket, helloAck);
    return;
  }

  if (isHeartbeatPayload(payload)) {
    if (payload.protocol !== "pinvim.peer.v1") {
      respondError(socket, `unsupported pinvim protocol: ${payload.protocol}`);
      return;
    }

    state.lastHeartbeat = payload;
    scheduleInfoManifest();
    updateStatus();
    respondOk(socket, {
      type: "heartbeat",
      protocol: payload.protocol,
      peerId: buildPinvimPeerIdentity().id,
      sentAt: payload.sentAt,
    });
    return;
  }

  if (isExplicitSendPayload(payload)) {
    deliverMessage(pi, formatExplicitContext(payload));
    respondOk(socket);
    return;
  }

  if (isPromptPayload(payload)) {
    if (!payload.message?.trim()) {
      respondError(socket, "prompt message is empty");
      return;
    }
    deliverMessage(pi, payload.message);
    respondOk(socket);
    return;
  }

  if (hasType(payload) && (payload.type === "editor_state" || payload.type === "editor_disconnect")) {
    respondError(socket, "editor_state live context is unsupported; use explicit_send");
    return;
  }

  if (isTelegramPayload(payload)) {
    latestCtx?.ui?.notify?.("Telegram message received", "info");
    deliverMessage(pi, `📱 **Telegram message:**\n${payload.text}`);
    respondOk(socket);
    return;
  }

  if (isTellPayload(payload)) {
    const fromSession = payload.from || "unknown";
    latestCtx?.ui?.notify?.(`Task from ${fromSession}`, "info");
    deliverMessage(pi, payload.text);
    respondOk(socket);
    return;
  }

  if (hasType(payload)) {
    respondError(socket, `unsupported payload type: ${String(payload.type)}`);
    return;
  }

  respondError(socket, "unsupported untyped pinvim payload; use explicit_send");
};

const startServer = (pi: ExtensionAPI, ctx: ExtensionContext): void => {
  if (!SOCKET_PATH || server) return;

  void (async () => {
    if (!SOCKET_PATH || server) return;

    await fsp.mkdir(path.dirname(SOCKET_PATH), { recursive: true });

    if (fs.existsSync(SOCKET_PATH)) {
      try {
        await fsp.unlink(SOCKET_PATH);
      } catch {
        // Ignore stale socket errors.
      }
    }

    server = net.createServer((socket) => {
    let buffer = "";

    socket.on("error", () => {
      // EPIPE, ECONNRESET, etc. — client disconnected before response.
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
          handleSocketPayload(pi, socket, payload);
        } catch {
          respondError(socket, "invalid JSON");
        }
      }
    });
    });

    server.listen(SOCKET_PATH);
    scheduleInfoManifest(true);

    if (ctx.hasUI) {
      ctx.ui.notify(`Pinvim socket listening: ${SOCKET_PATH}`, "info");
    }
  })().catch(() => {
    // Socket setup is best-effort; pinvim commands still load without ingress.
  });
};

// =============================================================================
// Extension entry point
// =============================================================================

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus();

    resolveSocketAsync(() => {
      if (isPinvimSocketEnabled()) startServer(pi, ctx);
    });
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus();
  });

  pi.on("session_shutdown", () => {
    latestCtx = null;
    server?.close();
    server = null;

    if (SOCKET_PATH && fs.existsSync(SOCKET_PATH)) {
      try {
        fs.unlinkSync(SOCKET_PATH);
      } catch {
        // Ignore cleanup failures.
      }
    }

    cleanupInfoManifest();
  });

  pi.registerCommand("pinvim-info", {
    description: "Show pinvim state: peer metadata, socket, and transport inputs",
    handler: async (_args, ctx) => {
      const lines = renderInfoLines();
      if (ctx.hasUI) ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  pi.registerCommand("pinvim-health", {
    description: "Show pinvim link health: peer id and heartbeat age",
    handler: async (_args, ctx) => {
      const health = getHealth();
      const lines = [
        health.ok ? "pinvim health: ok" : "pinvim health: attention needed",
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Socket: ${SOCKET_PATH || "(disabled)"}`,
      ];
      if (ctx.hasUI) ctx.ui.notify(lines.join("\n"), health.ok ? "info" : "warn");
    },
  });

  pi.registerCommand("pinvim-status", {
    description: "Show concise pinvim peer status",
    handler: async (_args, ctx) => {
      const health = getHealth();
      const lines = [
        `pinvim status: ${formatStatus() || "(no active peer)"}`,
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Socket: ${SOCKET_PATH || "(disabled)"}`,
      ];
      if (ctx.hasUI) ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  pi.registerCommand("pinvim-send", {
    description: "Explicitly send text from pi command input as a user message",
    handler: async (args, ctx) => {
      const message = args?.trim();
      if (!message) {
        if (ctx.hasUI) ctx.ui.notify("Usage: /pinvim-send <message>", "warn");
        return;
      }
      deliverMessage(pi, `[PINVIM EXPLICIT MESSAGE]\n${message}`);
    },
  });
}
