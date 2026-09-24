/**
 * Pi Bridge Extension
 *
 * Generic non-nvim ingress on a Unix socket.
 * The managed Pi wrapper enables it with PI_BRIDGE_LEGACY_SOCKET=1 so Telegram
 * (via Hammerspoon) and /tell keep working while pinvim is disabled. Bridge has
 * no nvim/pinvim peer polling or frame handling.
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
 *   Falls back to a process-specific socket outside tmux.
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
import type { AssistantMessage } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { Value } from "typebox/value";
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

const MAX_CLIENT_BUFFER_CHARS = 1024 * 1024;

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
  directory = SOCKET_DIR,
): string => {
  const name = [session, window, paneId].filter(Boolean).join("-");
  const full = `${directory}/${SOCKET_PREFIX}-${name}.sock`;

  if (utf8Bytes(full) <= MAX_SOCKET_PATH_BYTES) return full;
  const fixed = utf8Bytes(`${directory}/${SOCKET_PREFIX}-.sock`) + 9; // "-" + 8 hex
  const budget = MAX_SOCKET_PATH_BYTES - fixed;

  if (budget < 0) throw new Error("PI_STATE_DIR socket directory exceeds the Unix socket path limit");

  const hash = crypto
    .createHash("sha256")
    .update(name)
    .digest("hex")
    .slice(0, 8);

  let prefix = "";

  for (const character of name) {
    if (utf8Bytes(prefix + character) > budget) break;
    prefix += character;
  }

  return `${directory}/${SOCKET_PREFIX}-${prefix}-${hash}.sock`;
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

type SocketIdentity = {
  socketPath: string;
  session: string;
  window: string;
};

/** Only unmarked overrides or this process's own published socket are local. */
const resolveSocket = (
  env: NodeJS.ProcessEnv = process.env,
  tmux = detectTmux(),
  pid = process.pid,
): SocketIdentity => {
  if (env.PI_SOCKET && (!env.PI_SOCKET_OWNER_PID || env.PI_SOCKET_OWNER_PID === String(pid))) {
    return {
      socketPath: env.PI_SOCKET,
      session: env.PI_SESSION || tmux?.session || "default",
      window: env.PI_WINDOW || tmux?.window || "0",
    };
  }

  if (tmux) {
    return {
      socketPath: buildSocketPath(tmux.session, tmux.window, tmux.pane),
      session: tmux.session,
      window: tmux.window,
    };
  }

  // Fallback outside tmux
  return {
    socketPath: buildSocketPath("process", String(pid)),
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

const deliveryModeSchema = Type.Union([Type.Literal("steer"), Type.Literal("follow_up")]);

const tellFields = {
  text: Type.String(),
  id: Type.Optional(Type.String()),
  from: Type.Optional(Type.String()),
  fromSocket: Type.Optional(Type.String()),
  sessionId: Type.Optional(Type.String()),
  sessionName: Type.Optional(Type.String()),
  timestamp: Type.Optional(Type.Number()),
};

const telegramSchema = Type.Object({
  type: Type.Literal("telegram"),
  text: Type.String(),
  source: Type.Optional(Type.String()),
  timestamp: Type.Optional(Type.Number()),
});

const tellSchema = Type.Object({
  type: Type.Literal("tell"),
  ...tellFields,
  protocol: Type.Optional(Type.String()),
  mode: Type.Optional(deliveryModeSchema),
});

const controlEnvelopeFields = {
  type: Type.Literal("control"),
  protocol: Type.Optional(Type.String()),
  id: Type.Optional(Type.String()),
  operation: Type.Optional(Type.String()),
};

const controlEnvelopeSchema = Type.Object(controlEnvelopeFields);

const controlSchema = Type.Object({
  ...controlEnvelopeFields,
  params: Type.Optional(Type.Object({
    ...tellFields,
    text: Type.Optional(Type.String()),
    messageId: Type.Optional(Type.String()),
    tellProtocol: Type.Optional(Type.String()),
    mode: Type.Optional(Type.String()),
  })),
});

const tellAckSchema = Type.Object({
  type: Type.Literal("tell_ack"),
  id: Type.Optional(Type.String()),
  to: Type.Optional(Type.String()),
  timestamp: Type.Optional(Type.Number()),
});

const pingSchema = Type.Object({ type: Type.Literal("ping") });

const payloadSchema = Type.Union([telegramSchema, tellSchema, controlSchema, tellAckSchema, pingSchema]);

const envelopeSchema = Type.Object({ type: Type.Optional(Type.String()) });

const pongSchema = Type.Object({ ok: Type.Literal(true) });

type TelegramPayload = Type.Static<typeof telegramSchema>;

type TellPayload = Type.Static<typeof tellSchema>;

type ControlPayload = Type.Static<typeof controlSchema>;

type ControlEnvelope = Type.Static<typeof controlEnvelopeSchema>;

type TellAckPayload = Type.Static<typeof tellAckSchema>;

type PingPayload = Type.Static<typeof pingSchema>;

type Payload = Type.Static<typeof payloadSchema>;

type DeliveryMode = Type.Static<typeof deliveryModeSchema>;

const runtimeSchema = Type.Object({
  version: Type.String(),
  loadedAt: Type.String(),
  sourceHash: Type.Union([Type.String(), Type.Null()]),
});

type RuntimeIdentity = Type.Static<typeof runtimeSchema>;

const bridgeRuntime: RuntimeIdentity = {
  version: "bridge.v2",
  loadedAt: new Date().toISOString(),
  sourceHash: crypto.createHash("sha256").update(fs.readFileSync(new URL(import.meta.url))).digest("hex"),
};

let tellRuntime: RuntimeIdentity | null = null;

const localHttpEndpointSchema = Type.Object({
  origin: Type.String(),
  pathname: Type.String(),
});

type LocalHttpEndpoint = Type.Static<typeof localHttpEndpointSchema>;

const manifestSchema = Type.Object({
  socket: Type.String({ minLength: 1 }),
  cwd: Type.Optional(Type.String()),
  pid: Type.Optional(Type.Integer({ minimum: 1 })),
  owner: Type.Optional(Type.String({ minLength: 1 })),
  session: Type.Optional(Type.String()),
  window: Type.Optional(Type.String()),
  pane: Type.Optional(Type.String()),
  windowIndex: Type.Optional(Type.String()),
  paneIndex: Type.Optional(Type.String()),
  sessionId: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  sessionName: Type.Optional(Type.Union([Type.String(), Type.Null()])),
  startedAt: Type.Optional(Type.Union([Type.String(), Type.Number()])),
  heartbeatAt: Type.Optional(Type.Union([Type.String(), Type.Number()])),
  ephemeral: Type.Optional(Type.Boolean()),
  tidewaveConnected: Type.Optional(Type.Boolean()),
  tidewaveEndpoint: Type.Optional(localHttpEndpointSchema),
  state: Type.Optional(Type.Union([Type.Literal("idle"), Type.Literal("working"), Type.Literal("input_needed"), Type.Literal("done"), Type.Literal("error")])),
  statusUpdatedAt: Type.Optional(Type.String()),
  bridge: Type.Optional(runtimeSchema),
  tell: Type.Optional(Type.Union([runtimeSchema, Type.Null()])),
});

type BridgeManifest = Type.Static<typeof manifestSchema>;

type TmuxLocation = Pick<BridgeManifest, "pane" | "windowIndex" | "paneIndex">;

type ControlSession = Omit<BridgeManifest, "owner" | "ephemeral" | "tidewaveConnected" | "tidewaveEndpoint"> & { reachable: boolean };

type ControlData = { sessions: ControlSession[] } | { message: LastAssistantMessage | null } | { accepted: true; messageId?: string; deliveredAs: "direct" | DeliveryMode };

type BridgeResponse = {
  ok: boolean;
  type?: string;
  protocol?: string;
  id?: string;
  operation?: string;
  error?: string;
  data?: ControlData;
  deliveredAs?: "direct" | DeliveryMode;
  runtime?: { bridge: RuntimeIdentity; tell: RuntimeIdentity | null };
  pid?: number;
  sessionId?: string | null;
  sessionName?: string | null;
  idle?: boolean;
  pending?: boolean;
};

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

type BridgeActivityState =
  | "idle"
  | "working"
  | "input_needed"
  | "done"
  | "error";

let activityState: BridgeActivityState = "idle";

let activityBeforePrompt: BridgeActivityState | null = null;

let activityUpdatedAt = new Date().toISOString();

type AssistantResult = Pick<AssistantMessage, "role" | "content" | "stopReason">;

let latestAssistantResult: AssistantResult | null = null;

let socketInode: number | null = null;

let heartbeatTimer: ReturnType<typeof setInterval> | null = null;

let watchdogTimer: ReturnType<typeof setInterval> | null = null;

let retryTimer: ReturnType<typeof setTimeout> | null = null;

let shuttingDown = false;

let startAttempt: Promise<void> | null = null;

let tellWidgetTimer: ReturnType<typeof setTimeout> | null = null;

let retryDelay = 250;

let retryLogs = 0;

// Versioned pi-mcp-adapter status events distinguish live connections from
// cached tools. The bridge publishes this gate even before the first prompt.
const MCP_STATUS_EVENT = "pi-mcp-adapter/status/v1";

const TIDEWAVE_ENDPOINT_EVENT = "pidewave:endpoint:v1";

const tidewaveEndpointEventSchema = Type.Object({
  version: Type.Literal(1),
  endpoint: Type.Optional(localHttpEndpointSchema),
});

const mcpStatusSchema = Type.Object({
  version: Type.Literal(1),
  servers: Type.Array(Type.Object({
    name: Type.String(),
    status: Type.String(),
    disabled: Type.Boolean(),
  })),
});

let tidewaveConnected = false;

let tidewaveEndpoint: LocalHttpEndpoint | undefined;

const safeTidewaveEndpoint = (endpoint: LocalHttpEndpoint | undefined): LocalHttpEndpoint | undefined => {
  if (!endpoint || endpoint.pathname !== "/tidewave/mcp") return undefined;

  try {
    const url = new URL(endpoint.origin);
    const port = Number(url.port || (url.protocol === "https:" ? 443 : 80));

    if (
      !["http:", "https:"].includes(url.protocol) ||
      !["localhost", "127.0.0.1"].includes(url.hostname) ||
      url.origin !== endpoint.origin || url.username || url.password || url.search || url.hash ||
      !Number.isInteger(port) || port < 1 || port > 65535 || port === 9832
    ) return undefined;

    return { origin: url.origin, pathname: endpoint.pathname };
  } catch {
    return undefined;
  }
};

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

const refreshTmuxLocation = (
  manifest: TmuxLocation,
  tmux: ReturnType<typeof detectTmux>,
): boolean => {
  // Headless and spawned Pi processes have no tmux metadata. Optional chaining
  // alone is unsafe here: `undefined === manifest.pane` is true when both are
  // absent, then dereferencing tmux crashes the process on the heartbeat.
  if (!tmux || tmux.pane !== manifest.pane) return false;
  manifest.windowIndex = tmux.windowIndex;
  manifest.paneIndex = tmux.paneIndex;

  return true;
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
  );

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
  if (!pid || !Number.isSafeInteger(pid) || pid < 1) return false;

  try {
    process.kill(pid, 0);

    return true;
  } catch {
    return false;
  }
};

const manifestForSocket = (socket: string): string =>
  path.join(INFO_DIR, `${path.basename(socket).replace(/\.sock$/, "")}.info`);

const readManifest = (manifestPath: string): BridgeManifest | null => {
  try {
    const value: unknown = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

    return Value.Check(manifestSchema, value) ? value : null;
  } catch {
    return null;
  }
};

const claimSchema = Type.Object({ owner: Type.String(), pid: Type.Integer({ minimum: 1 }) });

type SocketClaim = { path: string; ino: number; dev: number; owner: string };

const acquireSocketClaim = (socket: string): SocketClaim | null => {
  const claimPath = `${socket}.claim`;
  let fd: number;

  try {
    fd = fs.openSync(claimPath, "wx", 0o600);
  } catch (error) {
    if (error instanceof Error && "code" in error && error.code === "EEXIST") return null;
    throw error;
  }

  try {
    fs.writeFileSync(fd, JSON.stringify({ owner: ownerToken, pid: process.pid }) + "\n");
    const stat = fs.fstatSync(fd);

    return { path: claimPath, ino: stat.ino, dev: stat.dev, owner: ownerToken };
  } finally {
    fs.closeSync(fd);
  }
};

const releaseSocketClaim = (claim: SocketClaim): void => {
  try {
    const stat = fs.lstatSync(claim.path);
    const value: unknown = JSON.parse(fs.readFileSync(claim.path, "utf8"));

    if (stat.ino === claim.ino && stat.dev === claim.dev && Value.Check(claimSchema, value) && value.owner === claim.owner && value.pid === process.pid) {
      fs.unlinkSync(claim.path);
    }
  } catch {
    // Missing, replaced, or malformed claims are never removed by this owner.
  }
};

const pingSocket = (socket: string): Promise<boolean> =>
  new Promise((resolve) => {
    const client = net.createConnection(socket);
    client.setEncoding("utf8");
    let settled = false;
    let buffer = "";

    const finish = (ok: boolean): void => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      client.destroy();
      resolve(ok);
    };

    const timer = setTimeout(() => finish(false), 250);
    client.once("connect", () => client.write('{"type":"ping"}\n'));
    client.on("data", (data) => {
      buffer += data.toString();

      if (buffer.length > MAX_CLIENT_BUFFER_CHARS) return finish(false);
      const newline = buffer.indexOf("\n");

      if (newline === -1) return;

      try {
        finish(Value.Check(pongSchema, JSON.parse(buffer.slice(0, newline))));
      } catch {
        finish(false);
      }
    });
    client.once("error", () => finish(false));
    client.once("close", () => finish(false));
  });

const canReclaim = async (socket: string): Promise<boolean> => {
  const manifestPath = manifestForSocket(socket);

  try {
    const initialStat = fs.statSync(socket);

    if (!initialStat.isSocket()) return false;
    const initial = readManifest(manifestPath);

    if (!initial?.owner || !initial.pid || initial.heartbeatAt === undefined || initial.socket !== socket || (await pingSocket(socket)))
      return false;
    const heartbeat = new Date(initial.heartbeatAt).getTime();

    const recent =
      Number.isFinite(heartbeat) && Date.now() - heartbeat < STALE_HEARTBEAT_MS;

    if (pidAlive(initial.pid) || recent || !Number.isFinite(heartbeat)) return false;

    const current = readManifest(manifestPath);
    const currentStat = fs.statSync(socket);

    if (
      !current ||
      current.owner !== initial.owner ||
      current.pid !== initial.pid ||
      current.socket !== socket ||
      current.heartbeatAt !== initial.heartbeatAt ||
      current.startedAt !== initial.startedAt ||
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
      manifest?.pid === process.pid &&
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

const respond = (socket: net.Socket, data: BridgeResponse): void => {
  if (socket.destroyed || !socket.writable) return;

  try {
    socket.write(JSON.stringify(data) + "\n");
  } catch {
    // Client may have disconnected
  }
};

const respondOk = (socket: net.Socket, extra?: Omit<BridgeResponse, "ok">): void =>
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

const writeManifestAtomic = (manifest: BridgeManifest): boolean => {
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

const writeInfoManifest = (restoreOnly = false): boolean => {
  if (!SOCKET_PATH || !PI_SESSION) return false;

  try {
    fs.mkdirSync(INFO_DIR, { recursive: true });
    infoManifestPath = manifestForSocket(SOCKET_PATH);
    const now = new Date().toISOString();
    const tmux = detectTmux();

    if (restoreOnly && fs.existsSync(infoManifestPath)) return false;

    const manifest: BridgeManifest = {
      socket: SOCKET_PATH,
      cwd: latestCtx?.cwd || process.cwd(),
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
      tidewaveEndpoint,
      state: activityState,
      statusUpdatedAt: activityUpdatedAt,
      bridge: bridgeRuntime,
      tell: tellRuntime,
      ...piSessionIdentity(latestCtx),
    };

    if (restoreOnly) {
      // Exclusive creation cannot replace a foreign registration appearing
      // between the watchdog's missing-file check and this write.
      fs.writeFileSync(infoManifestPath, JSON.stringify(manifest) + "\n", { flag: "wx", mode: 0o600 });

      return true;
    }

    return writeManifestAtomic(manifest);
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

const updateActivityState = (
  state: BridgeActivityState,
  ctx: ExtensionContext | null = latestCtx,
): void => {
  activityState = state;
  activityUpdatedAt = new Date().toISOString();

  if (ctx) latestCtx = ctx;

  if (!ownedSocket() || !infoManifestPath) return;
  const manifest = readManifest(infoManifestPath);

  if (manifest?.owner !== ownerToken || manifest?.pid !== process.pid) return;
  manifest.state = activityState;
  manifest.statusUpdatedAt = activityUpdatedAt;
  Object.assign(manifest, piSessionIdentity(latestCtx));
  writeManifestAtomic(manifest);
};

const beginPrompt = (ctx: ExtensionContext | null = latestCtx): void => {
  if (activityState !== "input_needed") activityBeforePrompt = activityState;
  updateActivityState("input_needed", ctx);
};

const endPrompt = (ctx: ExtensionContext | null = latestCtx): void => {
  const next = activityBeforePrompt ?? "idle";
  activityBeforePrompt = null;
  updateActivityState(next, ctx);
};

const captureAssistantResult = (message: AssistantResult): void => {
  latestAssistantResult = message;
};

const assistantResultText = (): string => {
  const content = latestAssistantResult?.content;

  if (!Array.isArray(content)) return "";

  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        part.type === "text",
    )
    .map((part) => part.text)
    .join("\n")
    .trim();
};

const settledActivityState = (): BridgeActivityState => {
  if (latestAssistantResult?.stopReason === "error") return "error";

  return /\?[\s*_`"')\]]*$/.test(assistantResultText().trimEnd())
    ? "input_needed"
    : "done";
};

// =============================================================================
// Control protocol
// =============================================================================

const controlSessions = async (): Promise<ControlSession[]> => {
  try {
    const manifests = fs.readdirSync(INFO_DIR)
      .filter((entry) => entry.endsWith(".info"))
      .flatMap((entry) => {
        const manifest = readManifest(path.join(INFO_DIR, entry));

        return manifest && !manifest.ephemeral ? [manifest] : [];
      });

    const sessions = await Promise.all(manifests.map(async (manifest) => ({
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
      state: manifest.state ?? "idle",
      statusUpdatedAt: manifest.statusUpdatedAt,
      bridge: manifest.bridge,
      tell: manifest.tell,
      reachable: await pingSocket(manifest.socket),
    })));

    return sessions.sort((a, b) =>
      (a.sessionName || a.session || a.sessionId || a.socket).localeCompare(
        b.sessionName || b.session || b.sessionId || b.socket,
      ),
    );
  } catch {
    return [];
  }
};

const controlResponse = (
  request: ControlEnvelope,
  data?: ControlData,
  error?: string,
): BridgeResponse => ({
  ok: !error,
  type: "control_response",
  protocol: "pi.control.v1",
  id: request.id,
  operation: request.operation,
  ...(error ? { error } : { data }),
});

const handleControl = async (
  request: ControlPayload,
  pi: ExtensionAPI,
  ctx: ExtensionContext | null,
): Promise<BridgeResponse> => {
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

  const operations = [
    "sessions.list",
    "message.last",
    "message.send",
  ];

  if (!operations.includes(request.operation || "")) {
    return controlResponse(
      request,
      undefined,
      `unsupported control operation: ${String(request.operation || "unknown")}`,
    );
  }

  if (request.operation === "sessions.list") {
    return controlResponse(request, { sessions: await controlSessions() });
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

  if (!params.text?.trim()) {
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
    id: params.messageId ?? request.id,
    from: params.from,
    fromSocket: params.fromSocket,
    sessionId: params.sessionId,
    sessionName: params.sessionName,
    protocol: params.tellProtocol,
    timestamp: params.timestamp,
    mode: params.mode,
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

const checkRegistration = (pi: ExtensionAPI, ctx: ExtensionContext): void => {
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
        writeInfoManifest(true)
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
};

const startWatchdog = (pi: ExtensionAPI, ctx: ExtensionContext): void => {
  if (watchdogTimer) return;
  watchdogTimer = setInterval(() => checkRegistration(pi, ctx), HEARTBEAT_MS);
  watchdogTimer.unref?.();
};

const startServer = (
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): Promise<void> => {
  if (startAttempt) return startAttempt;
  startAttempt = startListener(pi, ctx).catch((error) => {
    logBridge(`listener setup failed: ${String(error)}`);
    scheduleRetry(pi, ctx, "listener setup failed");
  }).finally(() => {
    startAttempt = null;
  });

  return startAttempt;
};

const startListener = async (
  pi: ExtensionAPI,
  ctx: ExtensionContext,
): Promise<void> => {
  if (shuttingDown || !SOCKET_PATH || server) return;

  const socketDir = path.dirname(SOCKET_PATH);
  fs.mkdirSync(socketDir, { recursive: true, mode: 0o700 });
  fs.mkdirSync(INFO_DIR, { recursive: true, mode: 0o700 });

  if (socketDir === SOCKET_DIR) fs.chmodSync(socketDir, 0o700);
  fs.chmodSync(INFO_DIR, 0o700);
  const claim = acquireSocketClaim(SOCKET_PATH);

  if (!claim) {
    scheduleRetry(pi, ctx, "socket claim held; abandoned claims require manual cleanup");

    return;
  }

  try {
    await bindListener(pi, ctx);
  } finally {
    releaseSocketClaim(claim);
  }
};

const bindListener = async (pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> => {
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
    if (server !== pendingServer || shuttingDown) {
      socket.destroy();

      return;
    }

    socket.setEncoding("utf8");
    let buffer = "";
    clientSockets.add(socket);
    socket.once("close", () => clientSockets.delete(socket));

    socket.on("error", (_err) => {
      // EPIPE, ECONNRESET, etc. — client disconnected before we could respond.
      // Safe to ignore; socket 'close' event handles cleanup.
    });

    socket.on("data", (chunk) => {
      if (server !== pendingServer || shuttingDown) {
        socket.destroy();

        return;
      }

      buffer += chunk.toString();

      if (buffer.length > MAX_CLIENT_BUFFER_CHARS) {
        respondError(socket, "request too large");
        socket.destroy();

        return;
      }

      let idx = buffer.indexOf("\n");

      while (idx !== -1) {
        if (server !== pendingServer || shuttingDown) {
          socket.destroy();

          return;
        }

        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 1);
        idx = buffer.indexOf("\n");

        if (!line) continue;

        try {
          const payload: unknown = JSON.parse(line);

          if (!Value.Check(payloadSchema, payload)) {
            if (Value.Check(controlEnvelopeSchema, payload)) {
              respond(socket, controlResponse(payload, undefined, "invalid control parameters"));
              continue;
            }

            const error = Value.Check(envelopeSchema, payload) && payload.type && !["ping", "telegram", "tell", "tell_ack", "control"].includes(payload.type)
              ? `unsupported payload type: ${payload.type}`
              : "invalid bridge payload";

            respondError(socket, error);
            continue;
          }

          if (isControlPayload(payload)) {
            void handleControl(payload, pi, latestCtx).then(
              (response) => respond(socket, response),
              () => respond(socket, controlResponse(payload, undefined, "control request failed")),
            );
            continue;
          }

          // Handle ping/pong
          if (isPingPayload(payload)) {
            respondOk(socket, {
              type: "pong",
              runtime: { bridge: bridgeRuntime, tell: tellRuntime },
              pid: process.pid,
              ...piSessionIdentity(latestCtx),
              idle: latestCtx?.isIdle() ?? false,
              pending: latestCtx?.hasPendingMessages() ?? false,
            });
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
            if (!payload.text.trim()) {
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
        } catch {
          respondError(socket, "invalid JSON");
        }
      }
    });
  });

  const pendingServer = server;
  await new Promise<void>((resolve) => {
  pendingServer.once("error", (err) => {
    if (server === pendingServer) {
      server = null;
      socketInode = null;
      scheduleRetry(pi, ctx, `listen failed: ${String(err)}`);
    }

    resolve();
  });
  pendingServer.listen(SOCKET_PATH, () => {
    resolve();

    if (server !== pendingServer) return;

    try {
      fs.chmodSync(SOCKET_PATH, 0o600);
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
      manifest.tidewaveEndpoint = tidewaveEndpoint;
      manifest.cwd = latestCtx?.cwd || process.cwd();
      Object.assign(manifest, piSessionIdentity(latestCtx));
      refreshTmuxLocation(manifest, detectTmux());
      writeManifestAtomic(manifest);
    }, HEARTBEAT_MS);
    heartbeatTimer.unref?.();
  });
  });
};

// =============================================================================
// Extension Entry Point
// =============================================================================

export const _test = {
  activityState: () => activityState,
  beginPrompt,
  buildSocketPath,
  canReclaim,
  checkRegistration,
  captureAssistantResult,
  controlResponse,
  controlSessions,
  deliverTell,
  endPrompt,
  handleControl,
  latestAssistantMessage,
  manifestForSocket,
  piSessionIdentity,
  pidAlive,
  pingSocket,
  resolveSocket,
  readManifest,
  startServer,
  refreshTmuxLocation,
  settledActivityState,
  summarizeTellText,
  updateActivityState,
};

export default function (pi: ExtensionAPI): void {
  tellRuntime = null;
  let reportedTidewaveEndpoint: LocalHttpEndpoint | undefined;
  let reportedTidewaveConnected = false;
  let sessionActive = false;

  const unsubscribeRuntime = pi.events.on("tell:runtime", (data) => {
    if (!Value.Check(runtimeSchema, data)) return;
    tellRuntime = data;

    if (!ownedSocket() || !infoManifestPath) return;
    const manifest = readManifest(infoManifestPath);

    if (!manifest) return;
    manifest.tell = tellRuntime;
    writeManifestAtomic(manifest);
  });

  pi.on("session_start", (_event, ctx) => {
    shuttingDown = false;
    retryDelay = 250;
    retryLogs = 0;
    // Earlier startup hooks may have already published either half of the gate.
    tidewaveEndpoint = reportedTidewaveConnected ? reportedTidewaveEndpoint : undefined;
    tidewaveConnected = !!tidewaveEndpoint;
    sessionActive = true;
    latestCtx = ctx;
    activityState = "idle";
    activityBeforePrompt = null;
    activityUpdatedAt = new Date().toISOString();
    latestAssistantResult = null;

    // Start generic ingress only when explicitly enabled by the Pi wrapper.
    if (IS_BRIDGE_ENABLED) {
      process.env.PI_SOCKET = SOCKET_PATH;
      process.env.PI_SOCKET_OWNER_PID = String(process.pid);
      startWatchdog(pi, ctx);
      void startServer(pi, ctx);
    }
  });

  const refreshSessionContext = (ctx: ExtensionContext): void => {
    latestCtx = ctx;

    if (!ownedSocket() || !infoManifestPath) return;
    const manifest = readManifest(infoManifestPath);

    if (manifest?.owner !== ownerToken || manifest?.pid !== process.pid) return;
    Object.assign(manifest, piSessionIdentity(ctx));
    manifest.cwd = ctx.cwd;
    manifest.tidewaveConnected = tidewaveConnected;
    manifest.tidewaveEndpoint = tidewaveEndpoint;
    manifest.heartbeatAt = new Date().toISOString();
    writeManifestAtomic(manifest);
  };

  const publishTidewave = (): void => {
    const endpoint = reportedTidewaveConnected ? reportedTidewaveEndpoint : undefined;

    if (!sessionActive || (
      endpoint?.origin === tidewaveEndpoint?.origin &&
      endpoint?.pathname === tidewaveEndpoint?.pathname
    )) return;
    tidewaveEndpoint = endpoint;
    tidewaveConnected = !!endpoint;

    if (latestCtx) refreshSessionContext(latestCtx);
  };

  const unsubscribeMcpStatus = pi.events.on(MCP_STATUS_EVENT, (data) => {
    const servers = Value.Check(mcpStatusSchema, data)
      ? data.servers.filter((server) => server.name === "tidewave") : [];

    reportedTidewaveConnected = servers.length === 1 &&
      servers[0].status === "connected" && !servers[0].disabled;
    publishTidewave();
  });

  const unsubscribeTidewaveEndpoint = pi.events.on(TIDEWAVE_ENDPOINT_EVENT, (data) => {
    reportedTidewaveEndpoint = Value.Check(tidewaveEndpointEventSchema, data)
      ? safeTidewaveEndpoint(data.endpoint) : undefined;
    publishTidewave();
  });

  pi.on("session_info_changed", (_event, ctx) => {
    refreshSessionContext(ctx);
  });

  // Update status when model changes
  pi.on("model_select", (_event, ctx) => {
    refreshSessionContext(ctx);
  });

  pi.on("input", (_event, ctx) => {
    updateActivityState("working", ctx);
  });

  pi.on("agent_start", (_event, ctx) => {
    latestAssistantResult = null;
    activityBeforePrompt = null;
    updateActivityState("working", ctx);
  });

  pi.on("message_end", (event) => {
    if (event.message.role === "assistant") captureAssistantResult(event.message);
  });

  pi.on("agent_end", (event) => {
    for (let i = event.messages.length - 1; i >= 0; i--) {
      const message = event.messages[i];

      if (message?.role === "assistant") {
        captureAssistantResult(message);
        break;
      }
    }
  });

  pi.on("ui_prompt_start", (_event, ctx) => {
    beginPrompt(ctx);
  });

  pi.on("ui_prompt_end", (_event, ctx) => {
    endPrompt(ctx);
  });

  pi.on("agent_settled", (_event, ctx) => {
    activityBeforePrompt = null;
    updateActivityState(settledActivityState(), ctx);
  });

  pi.on("session_shutdown", async () => {
    sessionActive = false;
    reportedTidewaveConnected = false;
    reportedTidewaveEndpoint = undefined;
    tidewaveEndpoint = undefined;
    tidewaveConnected = false;

    if (latestCtx) refreshSessionContext(latestCtx);
    shuttingDown = true;
    unsubscribeRuntime();
    unsubscribeMcpStatus();
    unsubscribeTidewaveEndpoint();

    if (retryTimer) clearTimeout(retryTimer);

    if (watchdogTimer) clearInterval(watchdogTimer);

    if (heartbeatTimer) clearInterval(heartbeatTimer);

    if (tellWidgetTimer) clearTimeout(tellWidgetTimer);
    retryTimer = null;
    watchdogTimer = null;
    heartbeatTimer = null;
    tellWidgetTimer = null;
    latestCtx?.ui?.setWidget?.("tell", undefined);

    // Drain asynchronous reclaim/listen before closing so old startup work
    // cannot bind a socket after the replacement runtime starts.
    await startAttempt;

    if (heartbeatTimer) clearInterval(heartbeatTimer);
    heartbeatTimer = null;
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
