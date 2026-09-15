// @ts-nocheck
/**
 * Pi Bridge Extension
 *
 * Generic non-nvim ingress on a Unix socket.
 * The managed Pi wrapper enables it with PI_BRIDGE_LEGACY_SOCKET=1 so Telegram
 * (via Hammerspoon) and /tell keep working while pinvim is disabled. Bridge has
 * no heartbeat/status polling and does not handle nvim/pinvim peer frames.
 *
 * Protocol:
 *   Legacy:   ping, telegram, tell, and tell_ack payloads keep their existing
 *             top-level { ok: true|false } responses.
 *   Control:  { type: 'control', protocol: 'pi.control.v1', id, operation,
 *               params } supports sessions.list, message.last, and message.send.
 *             Responses echo id and operation and retain top-level ok.
 *
 * Discovery:
 *   Socket:   ${PI_STATE_DIR}/sockets/pi-{session}-{window}-{paneId}.sock
 *   Manifest: ${PI_STATE_DIR}/manifests/{socket-basename}.info
 *             (JSON: socket, cwd, pid, sessionId, sessionName, tmux metadata,
 *              owner, heartbeatAt, startedAt)
 *
 * Socket Configuration:
 *   Auto-detected from tmux session/window/pane when TMUX env is set.
 *   PI_SOCKET env var overrides auto-detection (for explicit control).
 *   Falls back to ${PI_STATE_DIR}/sockets/pi-default-0.sock outside tmux.
 *   Logical Pi session IDs and names remain metadata; stable tmux pane IDs own
 *   socket identity.
 *
 * Used by:
 *   - This extension (listens on auto-detected or PI_SOCKET path)
 *   - config/hammerspoon/lib/interop/pi.lua (forwards Telegram messages)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { execFile, execSync } from "node:child_process";
import crypto from "node:crypto";
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

// macOS sun_path limit is 104 bytes (incl. NUL terminator). Longer paths make
// net.Server.listen() throw EINVAL. Keep a safety margin.
const MAX_SOCKET_PATH_BYTES = 103;

/**
 * Build the socket path for a tmux pane. When the full path would exceed the
 * sun_path limit, the `{session}-{window}-{paneId}` name is truncated and a
 * deterministic 8-char sha256 suffix is appended so senders that use the same
 * scheme (tell.ts, hammerspoon interop/pi.lua) resolve the identical path.
 */
const utf8Bytes = (value: string): number =>
  new TextEncoder().encode(value).length;

const buildSocketPath = (
  session: string,
  window: string,
  paneId?: string,
): string => {
  const name = [session, window, paneId].filter(Boolean).join("-");
  const full = `${SOCKET_DIR}/${SOCKET_PREFIX}-${name}.sock`;
  if (utf8Bytes(full) <= MAX_SOCKET_PATH_BYTES) return full;
  const fixed = utf8Bytes(`${SOCKET_DIR}/${SOCKET_PREFIX}-.sock`) + 9; // "-" + 8 hex
  const budget = Math.max(MAX_SOCKET_PATH_BYTES - fixed, 8);
  const hash = crypto
    .createHash("sha256")
    .update(name)
    .digest("hex")
    .slice(0, 8);
  return `${SOCKET_DIR}/${SOCKET_PREFIX}-${name.slice(0, budget)}-${hash}.sock`;
};

/** Detect tmux session/window/pane names. Returns null if not in tmux. */
const detectTmux = (): {
  session: string;
  window: string;
  pane?: string;
  paneIndex?: string;
  windowIndex?: string;
} | null => {
  if (!process.env.TMUX) return null;
  try {
    // Target our own pane explicitly: without -t, display-message reports the
    // client's ACTIVE window, not the window this process runs in.
    const target = process.env.TMUX_PANE
      ? `-t '${process.env.TMUX_PANE}' `
      : "";
    // Single subprocess: batched tab-separated format. This runs at startup
    // AND on every heartbeat, so collapsing five execSync spawns into one is a
    // 5x reduction in per-interval tmux process churn across all Pi panes.
    const raw = execSync(
      `tmux display-message -p ${target}'#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}\t#{pane_index}'`,
      { encoding: "utf-8", timeout: 2000 },
    );
    const [session, winName, winIndex, pane, paneIndex] = raw
      .replace(/\n$/, "")
      .split("\t");
    // Use window name if alphanumeric, otherwise index
    const window =
      winName && /^[a-zA-Z0-9_-]+$/.test(winName) ? winName : winIndex;
    return session && window
      ? { session, window, pane, paneIndex, windowIndex: winIndex }
      : null;
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
      socketPath: buildSocketPath(tmux.session, tmux.window, tmux.pane),
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

type DeliveryMode = "steer" | "follow_up";

type TellPayload = {
  type: "tell";
  protocol?: "pi.tell.v1" | string;
  id?: string;
  text: string;
  from?: string;
  fromSocket?: string;
  sessionId?: string;
  sessionName?: string;
  timestamp?: number;
  mode?: DeliveryMode;
};

type ControlOperation = "sessions.list" | "message.last" | "message.send";

type ControlPayload = {
  type: "control";
  protocol?: string;
  id?: string;
  operation?: string;
  params?: Record<string, unknown>;
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

type Payload =
  | TelegramPayload
  | TellPayload
  | TellAckPayload
  | PingPayload
  | ControlPayload;

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  "type" in p && p.type === "telegram";

const isTellPayload = (p: Payload): p is TellPayload =>
  "type" in p && p.type === "tell";

const isTellAckPayload = (p: Payload): p is TellAckPayload =>
  "type" in p && p.type === "tell_ack";

const isPingPayload = (p: Payload): p is PingPayload =>
  "type" in p && p.type === "ping";

const isControlPayload = (p: Payload): p is ControlPayload =>
  "type" in p && p.type === "control";

// =============================================================================
// State
// =============================================================================

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;
let infoManifestPath: string | null = null;
const clientSockets = new Set<net.Socket>();
const ownerToken = crypto.randomBytes(16).toString("hex");
let socketInode: number | null = null;
let heartbeatTimer: ReturnType<typeof setInterval> | null = null;
let watchdogTimer: ReturnType<typeof setInterval> | null = null;
let retryTimer: ReturnType<typeof setTimeout> | null = null;
let shuttingDown = false;
let tellWidgetTimer: ReturnType<typeof setTimeout> | null = null;
let retryDelay = 250;
let retryLogs = 0;
// Live tidewave-MCP-connected gate. pi surfaces each connected MCP server as a
// single tool `mcp__<serverName>` in the built system prompt's selectedTools;
// it appears only when the server actually connected (not merely configured).
// Captured in before_agent_start and mirrored into the manifest so Hammerspoon
// can gate the Tidewave->pi handshake by reading the active pane's manifest.
const TIDEWAVE_TOOL = "mcp__tidewave";
let tidewaveConnected = false;
const HEARTBEAT_MS = 10_000;
const STALE_HEARTBEAT_MS = 45_000;
const MAX_RETRY_MS = 8_000;
const MAX_RETRY_LOGS = 5;
const BRIDGE_LOG = path.join(PI_STATE_DIR, "logs", "bridge.log");

type PiSessionIdentity = {
  sessionId: string | null;
  sessionName: string | null;
};

type LastAssistantMessage = {
  role: "assistant";
  content: string;
  timestamp?: number;
};

const piSessionIdentity = (ctx: ExtensionContext | null): PiSessionIdentity => {
  const manager = ctx?.sessionManager;
  return {
    sessionId: manager?.getSessionId?.() || null,
    sessionName: manager?.getSessionName?.() || null,
  };
};

const summarizeTellText = (text: string, maxLength = 160): string => {
  const cleaned = text
    .split("\n")
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => !line.startsWith("[TELL:"))
    .join(" ")
    .replace(/\s+/g, " ")
    .trim();
  if (cleaned.length <= maxLength) return cleaned;
  return `${cleaned.slice(0, Math.max(0, maxLength - 3))}...`;
};

const notifyTellViaNtfy = (from: string, text: string): void => {
  const home = process.env.HOME || "";
  const commands = [home && path.join(home, "bin", "ntfy"), "ntfy"].filter(
    Boolean,
  ) as string[];
  const args = [
    "send",
    "-t",
    `Pi tell from ${from}`,
    "-m",
    summarizeTellText(text, 220) || "New Pi tell message",
    "-s",
    "pi tell",
  ];
  const tryNext = (index: number): void => {
    const command = commands[index];
    if (!command) return;
    execFile(command, args, { timeout: 2000 }, (error) => {
      if (error) tryNext(index + 1);
    });
  };
  tryNext(0);
};

const persistAndSurfaceTell = (
  pi: ExtensionAPI,
  ctx: ExtensionContext | null,
  payload: TellPayload,
): void => {
  const id = payload.id || `tell-${Date.now().toString(36)}`;
  const from = payload.from || "unknown";
  const receiver = piSessionIdentity(ctx);
  pi.appendEntry("tell-message", {
    id,
    direction: "received",
    from,
    fromSocket: payload.fromSocket,
    senderSessionId: payload.sessionId,
    senderSessionName: payload.sessionName,
    receiverSessionId: receiver.sessionId,
    receiverSessionName: receiver.sessionName,
    text: payload.text,
    mode: payload.mode || "follow_up",
    timestamp: payload.timestamp || Math.floor(Date.now() / 1000),
  });

  notifyTellViaNtfy(from, payload.text);

  if (!ctx?.hasUI) return;
  ctx.ui.notify(`Tell from ${from}`, "info");
  ctx.ui.setWidget("tell", [
    ctx.ui.theme.fg("accent", `Tell from ${from}`),
    summarizeTellText(payload.text),
    ctx.ui.theme.fg("muted", "Persisted in session history"),
  ]);

  if (tellWidgetTimer) clearTimeout(tellWidgetTimer);
  tellWidgetTimer = setTimeout(() => {
    latestCtx?.ui?.setWidget?.("tell", undefined);
    tellWidgetTimer = null;
  }, 120_000);
  tellWidgetTimer.unref?.();
};

const deliverTell = (
  pi: ExtensionAPI,
  ctx: ExtensionContext | null,
  text: string,
  mode: DeliveryMode = "follow_up",
): "direct" | DeliveryMode => {
  if (!ctx || ctx.isIdle()) {
    void pi.sendUserMessage(text);
    return "direct";
  }
  if (mode === "steer") {
    void pi.sendUserMessage(text, { deliverAs: "steer" });
    return "steer";
  }
  void pi.sendUserMessage(text, { deliverAs: "followUp" });
  return "follow_up";
};

const latestAssistantMessage = (
  ctx: ExtensionContext | null,
): LastAssistantMessage | null => {
  const branch = ctx?.sessionManager.getBranch() || [];
  for (let i = branch.length - 1; i >= 0; i--) {
    const entry = branch[i];
    if (entry.type !== "message" || entry.message.role !== "assistant")
      continue;
    const content = Array.isArray(entry.message.content)
      ? entry.message.content
          .filter(
            (part): part is { type: "text"; text: string } =>
              part.type === "text",
          )
          .map((part) => part.text)
          .join("\n")
          .trim()
      : String(entry.message.content).trim();
    if (content) {
      return {
        role: "assistant",
        content,
        timestamp: entry.message.timestamp,
      };
    }
  }
  return null;
};

const logBridge = (message: string): void => {
  try {
    fs.mkdirSync(path.dirname(BRIDGE_LOG), { recursive: true });
    fs.appendFileSync(BRIDGE_LOG, `${new Date().toISOString()} ${message}\n`);
  } catch {}
};

const pidAlive = (pid: number | undefined): boolean => {
  if (!pid || !Number.isFinite(pid)) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
};

const manifestForSocket = (socket: string): string =>
  path.join(INFO_DIR, `${path.basename(socket).replace(/\.sock$/, "")}.info`);

const readManifest = (manifestPath: string): Record<string, unknown> | null => {
  try {
    return JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  } catch {
    return null;
  }
};

const pingSocket = (socket: string): Promise<boolean> =>
  new Promise((resolve) => {
    const client = net.createConnection(socket);
    let settled = false;
    const finish = (ok: boolean): void => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      client.destroy();
      resolve(ok);
    };
    const timer = setTimeout(() => finish(false), 250);
    client.once("connect", () => client.write('{"type":"ping"}\n'));
    client.once("data", (data) => {
      try {
        finish(JSON.parse(String(data).split("\n")[0]).ok === true);
      } catch {
        finish(false);
      }
    });
    client.once("error", () => finish(false));
  });

const canReclaim = async (socket: string): Promise<boolean> => {
  const manifestPath = manifestForSocket(socket);
  try {
    const initialStat = fs.statSync(socket);
    if (!initialStat.isSocket()) return false;
    const initial = readManifest(manifestPath);
    if (!initial || initial.socket !== socket || (await pingSocket(socket)))
      return false;
    const heartbeatValue = initial.heartbeatAt || initial.startedAt || "";
    const heartbeat =
      typeof heartbeatValue === "number"
        ? heartbeatValue
        : Date.parse(String(heartbeatValue));
    const recent =
      Number.isFinite(heartbeat) && Date.now() - heartbeat < STALE_HEARTBEAT_MS;
    if (pidAlive(Number(initial.pid)) || recent) return false;

    const current = readManifest(manifestPath);
    const currentStat = fs.statSync(socket);
    if (
      !current ||
      current.owner !== initial.owner ||
      current.pid !== initial.pid ||
      current.socket !== socket ||
      currentStat.dev !== initialStat.dev ||
      currentStat.ino !== initialStat.ino
    )
      return false;

    logBridge(
      `reclaiming stale socket socket=${socket} pid=${initial.pid || "?"} heartbeat=${initial.heartbeatAt || "?"}`,
    );
    fs.unlinkSync(socket);
    const finalManifest = readManifest(manifestPath);
    if (
      finalManifest?.owner === initial.owner &&
      finalManifest?.pid === initial.pid
    ) {
      fs.unlinkSync(manifestPath);
    }
    return true;
  } catch {
    return false;
  }
};

const ownedSocket = (): boolean => {
  if (!SOCKET_PATH || socketInode === null || !infoManifestPath) return false;
  try {
    const stat = fs.statSync(SOCKET_PATH);
    const manifest = readManifest(infoManifestPath);
    return (
      stat.ino === socketInode &&
      manifest?.owner === ownerToken &&
      manifest?.socket === SOCKET_PATH
    );
  } catch {
    return false;
  }
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

const writeManifestAtomic = (manifest: Record<string, unknown>): boolean => {
  if (!infoManifestPath) return false;
  const temp = `${infoManifestPath}.${ownerToken}.tmp`;
  try {
    fs.writeFileSync(temp, JSON.stringify(manifest) + "\n", { mode: 0o600 });
    fs.renameSync(temp, infoManifestPath);
    return true;
  } catch {
    try {
      fs.unlinkSync(temp);
    } catch {}
    return false;
  }
};

const writeInfoManifest = (): boolean => {
  if (!SOCKET_PATH || !PI_SESSION) return false;
  try {
    fs.mkdirSync(INFO_DIR, { recursive: true });
    infoManifestPath = manifestForSocket(SOCKET_PATH);
    const now = new Date().toISOString();
    const tmux = detectTmux();
    return writeManifestAtomic({
      socket: SOCKET_PATH,
      cwd: process.cwd(),
      pid: process.pid,
      session: PI_SESSION,
      window: PI_WINDOW,
      windowIndex: tmux?.windowIndex,
      pane: tmux?.pane,
      paneIndex: tmux?.paneIndex,
      owner: ownerToken,
      heartbeatAt: now,
      ephemeral:
        process.env.PI_EPHEMERAL === "1" ||
        /-eph-[^-]+-[^-]+\.sock$/.test(SOCKET_PATH),
      startedAt: now,
      tidewaveConnected,
      ...piSessionIdentity(latestCtx),
    });
  } catch {
    return false;
  }
};

const cleanupInfoManifest = (): void => {
  if (!infoManifestPath) return;
  try {
    const manifest = readManifest(infoManifestPath);
    if (manifest?.owner === ownerToken && manifest?.pid === process.pid) {
      fs.unlinkSync(infoManifestPath);
    }
  } catch {}
};

// =============================================================================
// Control protocol
// =============================================================================

const controlSessions = (): Array<Record<string, unknown>> => {
  try {
    return fs
      .readdirSync(INFO_DIR)
      .filter((entry) => entry.endsWith(".info"))
      .flatMap((entry) => {
        const manifest = readManifest(path.join(INFO_DIR, entry));
        if (
          !manifest ||
          manifest.ephemeral === true ||
          typeof manifest.socket !== "string"
        ) {
          return [];
        }
        let socketExists = false;
        try {
          socketExists = fs.statSync(manifest.socket).isSocket();
        } catch {}
        return [
          {
            sessionId: manifest.sessionId ?? null,
            sessionName: manifest.sessionName ?? null,
            socket: manifest.socket,
            cwd: manifest.cwd,
            pid: manifest.pid,
            session: manifest.session,
            window: manifest.window,
            windowIndex: manifest.windowIndex,
            pane: manifest.pane,
            paneIndex: manifest.paneIndex,
            startedAt: manifest.startedAt,
            heartbeatAt: manifest.heartbeatAt,
            reachable: socketExists && pidAlive(Number(manifest.pid)),
          },
        ];
      })
      .sort((a, b) =>
        String(
          a.sessionName || a.session || a.sessionId || a.socket,
        ).localeCompare(
          String(b.sessionName || b.session || b.sessionId || b.socket),
        ),
      );
  } catch {
    return [];
  }
};

const controlResponse = (
  request: ControlPayload,
  data?: unknown,
  error?: string,
): Record<string, unknown> => ({
  ok: !error,
  type: "control_response",
  protocol: "pi.control.v1",
  id: request.id,
  operation: request.operation,
  ...(error ? { error } : { data }),
});

const handleControl = (
  request: ControlPayload,
  pi: ExtensionAPI,
  ctx: ExtensionContext | null,
): Record<string, unknown> => {
  if (request.protocol !== "pi.control.v1") {
    return controlResponse(request, undefined, "unsupported control protocol");
  }
  if (!request.id) {
    return controlResponse(
      request,
      undefined,
      "control request id is required",
    );
  }
  const operations: ControlOperation[] = [
    "sessions.list",
    "message.last",
    "message.send",
  ];
  if (!operations.includes(request.operation as ControlOperation)) {
    return controlResponse(
      request,
      undefined,
      `unsupported control operation: ${String(request.operation || "unknown")}`,
    );
  }
  if (request.operation === "sessions.list") {
    return controlResponse(request, { sessions: controlSessions() });
  }
  if (!ctx) {
    return controlResponse(request, undefined, "session not ready");
  }
  if (request.operation === "message.last") {
    return controlResponse(request, {
      message: latestAssistantMessage(ctx),
    });
  }

  const params = request.params || {};
  if (typeof params.text !== "string" || !params.text.trim()) {
    return controlResponse(
      request,
      undefined,
      "message.send requires non-empty params.text",
    );
  }
  if (
    params.mode !== undefined &&
    params.mode !== "steer" &&
    params.mode !== "follow_up"
  ) {
    return controlResponse(
      request,
      undefined,
      "message.send mode must be steer or follow_up",
    );
  }

  const payload: TellPayload = {
    type: "tell",
    text: params.text,
    id: typeof params.messageId === "string" ? params.messageId : request.id,
    from: typeof params.from === "string" ? params.from : undefined,
    fromSocket:
      typeof params.fromSocket === "string" ? params.fromSocket : undefined,
    sessionId:
      typeof params.sessionId === "string" ? params.sessionId : undefined,
    sessionName:
      typeof params.sessionName === "string" ? params.sessionName : undefined,
    protocol:
      typeof params.tellProtocol === "string" ? params.tellProtocol : undefined,
    timestamp:
      typeof params.timestamp === "number" ? params.timestamp : undefined,
    mode: params.mode as DeliveryMode | undefined,
  };
  persistAndSurfaceTell(pi, ctx, payload);
  const deliveredAs = deliverTell(pi, ctx, payload.text, payload.mode);
  if (payload.fromSocket && payload.protocol === "pi.tell.v1") {
    void sendTellAck(payload.fromSocket, payload.from || "unknown", payload.id);
  }
  return controlResponse(request, {
    accepted: true,
    messageId: payload.id,
    deliveredAs,
  });
};

// =============================================================================
// Socket Server
// =============================================================================

const scheduleRetry = (
  pi: ExtensionAPI,
  ctx: ExtensionContext,
  reason: string,
): void => {
  if (shuttingDown || retryTimer) return;
  const delay = retryDelay;
  retryDelay = Math.min(retryDelay * 2, MAX_RETRY_MS);
  if (retryLogs < MAX_RETRY_LOGS) {
    logBridge(`retrying in ${delay}ms reason=${reason} socket=${SOCKET_PATH}`);
    retryLogs += 1;
  }
  retryTimer = setTimeout(() => {
    retryTimer = null;
    if (!shuttingDown) void startServer(pi, ctx);
  }, delay);
  retryTimer.unref?.();
};

const startWatchdog = (pi: ExtensionAPI, ctx: ExtensionContext): void => {
  if (watchdogTimer) return;
  watchdogTimer = setInterval(() => {
    if (shuttingDown) return;
    if (!server) {
      scheduleRetry(pi, ctx, "listener missing");
      return;
    }
    if (ownedSocket()) return;

    // If only our manifest disappeared, restore it while the pathname still
    // resolves to our listener. Do not abandon a healthy server and then get
    // stuck behind an unowned socket that stale reclamation must reject.
    try {
      if (
        SOCKET_PATH &&
        socketInode !== null &&
        fs.statSync(SOCKET_PATH).ino === socketInode &&
        writeInfoManifest()
      )
        return;
    } catch {}

    // Node unlinks its original Unix path on server.close(). If another owner
    // has rebound that path, closing this displaced listener would remove the
    // replacement. Leave the unreachable listener unrefed; process exit closes
    // its file descriptor without path cleanup.
    server.unref();
    for (const socket of clientSockets) socket.destroy();
    clientSockets.clear();
    server = null;
    socketInode = null;
    if (heartbeatTimer) clearInterval(heartbeatTimer);
    heartbeatTimer = null;
    scheduleRetry(pi, ctx, "registration lost");
  }, HEARTBEAT_MS);
  watchdogTimer.unref?.();
};

const startServer = async (
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): Promise<void> => {
  if (shuttingDown || !SOCKET_PATH || server) return;

  fs.mkdirSync(path.dirname(SOCKET_PATH), { recursive: true });

  // Reclaim only an explicitly stale owner. Never unlink based on ping failure.
  if (fs.existsSync(SOCKET_PATH)) {
    const reclaimed = await canReclaim(SOCKET_PATH);
    if (shuttingDown) return;
    if (!reclaimed) {
      scheduleRetry(pi, ctx, "socket owned");
      return;
    }
  }
  if (shuttingDown) return;

  server = net.createServer((socket) => {
    let buffer = "";
    clientSockets.add(socket);
    socket.once("close", () => clientSockets.delete(socket));

    socket.on("error", (_err) => {
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

          if (isControlPayload(payload)) {
            respond(socket, handleControl(payload, pi, latestCtx));
            continue;
          }

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
            if (typeof payload.text !== "string" || !payload.text.trim()) {
              respondError(socket, "tell text is required");
              continue;
            }
            const fromSession = payload.from || "unknown";
            persistAndSurfaceTell(pi, latestCtx, payload);
            const deliveredAs = deliverTell(
              pi,
              latestCtx,
              payload.text,
              payload.mode,
            );
            if (payload.fromSocket && payload.protocol === "pi.tell.v1") {
              void sendTellAck(payload.fromSocket, fromSession, payload.id);
            }
            respondOk(socket, {
              id: payload.id,
              type: "tell_ack",
              deliveredAs,
            });
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

  const pendingServer = server;
  pendingServer.once("error", (err) => {
    if (server === pendingServer) server = null;
    socketInode = null;
    scheduleRetry(pi, ctx, `listen failed: ${String(err)}`);
  });
  pendingServer.listen(SOCKET_PATH, () => {
    if (shuttingDown) {
      // Shutdown may have run after listen() but before this callback. This
      // pending server still owns the path, so close it instead of leaving an
      // unrefed listener that blocks the replacement runtime.
      pendingServer.close();
      return;
    }
    if (server !== pendingServer) return;
    try {
      socketInode = fs.statSync(SOCKET_PATH).ino;
    } catch {
      socketInode = null;
    }
    if (socketInode === null || !writeInfoManifest()) {
      const failedServer = server;
      server = null;
      try {
        if (
          socketInode !== null &&
          fs.statSync(SOCKET_PATH).ino === socketInode
        ) {
          fs.unlinkSync(SOCKET_PATH);
        }
      } catch {}
      socketInode = null;
      // Do not call close(): Node may unlink a replacement bound after our
      // manual unlink. The unrefed listener dies with the process.
      failedServer?.unref();
      for (const socket of clientSockets) socket.destroy();
      clientSockets.clear();
      scheduleRetry(pi, ctx, "manifest write failed");
      return;
    }

    retryDelay = 250;
    retryLogs = 0;
    heartbeatTimer = setInterval(() => {
      if (!ownedSocket() || !infoManifestPath) return;
      const manifest = readManifest(infoManifestPath);
      if (manifest?.owner !== ownerToken || manifest?.pid !== process.pid)
        return;
      manifest.heartbeatAt = new Date().toISOString();
      manifest.tidewaveConnected = tidewaveConnected;
      Object.assign(manifest, piSessionIdentity(latestCtx));
      const tmux = detectTmux();
      if (tmux?.pane === manifest.pane) {
        manifest.windowIndex = tmux.windowIndex;
        manifest.paneIndex = tmux.paneIndex;
      }
      writeManifestAtomic(manifest);
    }, HEARTBEAT_MS);
    heartbeatTimer.unref?.();
  });

  // Update status to connected
};

// =============================================================================
// Extension Entry Point
// =============================================================================

export const _test = {
  buildSocketPath,
  canReclaim,
  controlResponse,
  controlSessions,
  deliverTell,
  handleControl,
  latestAssistantMessage,
  manifestForSocket,
  piSessionIdentity,
  pidAlive,
  summarizeTellText,
};

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;

    // Start generic ingress only when explicitly enabled by the Pi wrapper.
    if (IS_BRIDGE_ENABLED) {
      startWatchdog(pi, ctx);
      void startServer(pi, ctx);

      if (ctx.hasUI) {
        ctx.ui.notify(`Bridge listening: ${SOCKET_PATH}`, "info");
      }
    }
  });

  const refreshSessionContext = (ctx: ExtensionContext): void => {
    latestCtx = ctx;
    if (!ownedSocket() || !infoManifestPath) return;
    const manifest = readManifest(infoManifestPath);
    if (manifest?.owner !== ownerToken || manifest?.pid !== process.pid) return;
    Object.assign(manifest, piSessionIdentity(ctx));
    manifest.heartbeatAt = new Date().toISOString();
    writeManifestAtomic(manifest);
  };

  // Capture the live tidewave-MCP gate. selectedTools lists `mcp__tidewave`
  // only when the server actually connected, so this refreshes per turn and
  // writes the current truth into the manifest for Hammerspoon to read.
  pi.on("before_agent_start", (event, ctx) => {
    const selected =
      (event as { systemPromptOptions?: { selectedTools?: string[] } })
        .systemPromptOptions?.selectedTools ??
      ctx.getSystemPromptOptions?.().selectedTools ??
      [];
    const next = selected.includes(TIDEWAVE_TOOL);
    if (next !== tidewaveConnected) {
      tidewaveConnected = next;
      refreshSessionContext(ctx);
    } else {
      latestCtx = ctx;
    }
    return undefined;
  });

  pi.on("session_switch", (_event, ctx) => {
    refreshSessionContext(ctx);
  });

  pi.on("session_info_changed", (_event, ctx) => {
    refreshSessionContext(ctx);
  });

  // Update status when model changes
  pi.on("model_select", (_event, ctx) => {
    refreshSessionContext(ctx);
  });

  pi.on("session_shutdown", async () => {
    shuttingDown = true;
    if (retryTimer) clearTimeout(retryTimer);
    if (watchdogTimer) clearInterval(watchdogTimer);
    if (heartbeatTimer) clearInterval(heartbeatTimer);
    if (tellWidgetTimer) clearTimeout(tellWidgetTimer);
    retryTimer = null;
    watchdogTimer = null;
    heartbeatTimer = null;
    tellWidgetTimer = null;
    latestCtx?.ui?.setWidget?.("tell", undefined);

    const ownsPath = ownedSocket();
    const activeServer = server;
    for (const socket of clientSockets) socket.destroy();
    clientSockets.clear();

    if (ownsPath && activeServer) {
      // Closing the server releases its Unix pathname and file descriptor.
      // Await it so repeated /reload cycles cannot accumulate old listeners.
      await new Promise<void>((resolve) => activeServer.close(() => resolve()));
      cleanupInfoManifest();
    } else {
      // Closing a displaced Node Unix server could unlink its replacement path.
      activeServer?.unref();
    }
    server = null;
    socketInode = null;
  });
}
