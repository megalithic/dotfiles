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
import { execFile, spawnSync } from "node:child_process";
import crypto from "node:crypto";
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
const EDITOR_SERVICE_TIMEOUT_MS = 500;
const EDITOR_SERVICE_STALE_MS = 15_000;
// dot-0v6y: strict pairing staleness window. A same-window peer can only claim
// a Pi already paired with a different peer once its heartbeat is older.
const STRICT_PAIR_STALE_SECONDS = 20;

let tmuxCache: {
  at: number;
  value: { session: string; window: string; pane?: string } | null;
} = {
  at: 0,
  value: null,
};

const parseTmux = (
  stdout: string,
): { session: string; window: string; pane?: string } | null => {
  const [session, winName, winIndex, pane] = stdout.trim().split("\t");
  const window =
    winName && /^[a-zA-Z0-9_-]+$/.test(winName) ? winName : winIndex;
  return session && window ? { session, window, pane } : null;
};

const detectTmux = (
  callback: (
    tmux: { session: string; window: string; pane?: string } | null,
  ) => void,
): void => {
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
    [
      "display-message",
      "-p",
      "#{session_name}\t#{window_name}\t#{window_index}\t#{pane_id}",
    ],
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
  const match = SOCKET_PATH.match(
    /\/pi-([^-]+)-([^.]+?)(?:-eph-[^/]+)?\.sock$/,
  );
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

const hasParentContext = (): boolean =>
  !!(
    process.env.PINVIM_PARENT_ID ||
    process.env.PINVIM_WORKSPACE_ID ||
    process.env.PINVIM_INSTANCE_ID ||
    process.env.PINVIM_REGISTRY_ROOT
  );

const isExplicitChild = (): boolean =>
  process.env.PINVIM_SESSION_ROLE === "child" || isEphemeral();

const isNestedAttachOnly = (): boolean =>
  process.env.PINVIM_NESTED_ATTACH_ONLY === "1" ||
  process.env.PINVIM_LINK_MODE === "attach-only";

const shouldAutoScanNvimPeers = (): boolean =>
  !isNestedAttachOnly() && !hasParentContext();

const pinvimRelationState = ():
  | "attach-only"
  | "child"
  | "parent"
  | "no-parent" => {
  if (isNestedAttachOnly()) return "attach-only";
  if (isExplicitChild()) return "child";
  return hasParentContext() ? "parent" : "no-parent";
};

// =============================================================================
// Protocol types
// =============================================================================

type LinkMode =
  | "auto"
  | "manual"
  | "ephemeral"
  | "parked"
  | "explicit"
  | "bootstrap"
  | string;

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
  parentId?: string;
  pairId?: string;
  workspaceId?: string;
  instanceId?: string;
  registryRoot?: string;
  role?: "main" | "child" | "nested" | string;
  nvimListenAddress?: string;
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

interface FillPromptPayload {
  type: "fill_prompt";
  text: string;
  focus?: boolean;
}

type ExplicitDelivery = "attach" | "prompt";

interface ExplicitSendPayload {
  type: "explicit_send";
  delivery?: ExplicitDelivery;
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

interface TellAckPayload {
  type: "tell_ack";
  id?: string;
  to?: string;
  timestamp?: number;
}

interface TellPayload {
  type: "tell";
  protocol?: "pi.tell.v1" | string;
  id?: string;
  text: string;
  from?: string;
  fromSocket?: string;
  timestamp?: number;
}

type Payload =
  | HelloPayload
  | HeartbeatPayload
  | PingPayload
  | PromptPayload
  | FillPromptPayload
  | ExplicitSendPayload
  | TelegramPayload
  | TellPayload
  | TellAckPayload;

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

interface NvimPeerCandidate {
  id: string;
  kind?: "nvim" | string;
  owner?: string;
  cwd?: string;
  root?: string;
  pid?: number;
  session?: string;
  window?: string;
  pane?: string;
  tmux?: { session?: string; window?: string; pane?: string };
  heartbeatAt?: number;
  linkMode?: LinkMode;
  parentId?: string;
  workspaceId?: string;
  instanceId?: string;
  registryRoot?: string;
  role?: "main" | "child" | "nested" | string;
  nvimListenAddress?: string;
  editorService?: {
    address?: string;
    transport?: string;
  };
  socket?: string;
  socketSource?: string;
  connected?: boolean;
  peerId?: string;
  manifestPath?: string;
  score?: number;
  reasons?: string[];
}

interface ReloadBufferResult {
  ok?: boolean;
  path?: string;
  reloaded?: Array<{
    bufnr?: number;
    path?: string;
    current?: boolean;
    modified?: boolean;
    reloaded?: boolean;
    error?: string;
  }>;
  conflicts?: Array<{
    bufnr?: number;
    path?: string;
    current?: boolean;
    modified?: boolean;
  }>;
  missing?: Array<{
    path?: string;
    reason?: string;
  }>;
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

let repairCandidate: NvimPeerCandidate | null = null;
let repairedAt: number | null = null;
let repairReason: string | null = null;
let peerScanTimer: NodeJS.Timeout | null = null;
const acceptedSockets = new WeakSet<net.Socket>();
let latestCtx: ExtensionContext | null = null;
let nextTurnIsUserOrigin = false;
let pendingContext: {
  text: string;
  label: string;
  attachedAt: number;
  expiresAt: number;
} | null = null;
let pendingContextTimer: NodeJS.Timeout | null = null;
const PENDING_CONTEXT_TTL_MS = 5 * 60 * 1000;
let server: net.Server | null = null;
let infoManifestPath: string | null = null;
let editorServiceTimer: NodeJS.Timeout | null = null;
let editorServiceSocket: net.Socket | null = null;
let editorServiceRequestId = 1;

interface EditorServiceState {
  address: string | null;
  source: string;
  transport: "msgpack-rpc";
  connected: boolean;
  connecting: boolean;
  stale: boolean;
  lastOkAt: number | null;
  lastError: string | null;
  lastMethod: string | null;
}

type EditorMethod =
  | "status"
  | "context.current"
  | "diagnostics.current"
  | "open_file"
  | "reveal_file"
  | "reload_buffer"
  | "refresh_diagnostics"
  | "checktime"
  | "review.open";

interface EditorQueryResult {
  ok: boolean;
  result?: unknown;
  error?: string;
}

const editorService: EditorServiceState = {
  address: null,
  source: "none",
  transport: "msgpack-rpc",
  connected: false,
  connecting: false,
  stale: true,
  lastOkAt: null,
  lastError: null,
  lastMethod: null,
};
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

const isFillPromptPayload = (p: Payload): p is FillPromptPayload =>
  hasType(p) && p.type === "fill_prompt";

const isExplicitSendPayload = (p: Payload): p is ExplicitSendPayload =>
  hasType(p) && p.type === "explicit_send";

const isTelegramPayload = (p: Payload): p is TelegramPayload =>
  hasType(p) && p.type === "telegram";

const isTellPayload = (p: Payload): p is TellPayload =>
  hasType(p) && p.type === "tell";

const isTellAckPayload = (p: Payload): p is TellAckPayload =>
  hasType(p) && p.type === "tell_ack";

// =============================================================================
// Nvim editor service (msgpack-RPC)
// =============================================================================

const readJsonFile = (file: string): Record<string, unknown> | null => {
  try {
    const raw = fs.readFileSync(file, "utf-8");
    return JSON.parse(raw.split("\n")[0] || "{}") as Record<string, unknown>;
  } catch {
    return null;
  }
};

const editorAddressFromRecord = (
  record: Record<string, unknown> | null,
): string | null => {
  if (!record) return null;
  if (typeof record.nvimListenAddress === "string")
    return record.nvimListenAddress;
  const editor = record.editorService;
  if (editor && typeof editor === "object" && "address" in editor) {
    const address = (editor as Record<string, unknown>).address;
    if (typeof address === "string") return address;
  }
  return null;
};

const resolveEditorServiceAddress = (): {
  address: string | null;
  source: string;
} => {
  const activePeer = getActivePeer();
  if (process.env.PINVIM_NVIM_LISTEN_ADDRESS) {
    return { address: process.env.PINVIM_NVIM_LISTEN_ADDRESS, source: "env" };
  }
  if (activePeer?.nvimListenAddress) {
    return { address: activePeer.nvimListenAddress, source: "active peer" };
  }
  if (repairCandidate?.nvimListenAddress) {
    return {
      address: repairCandidate.nvimListenAddress,
      source: "nvim manifest",
    };
  }
  if (repairCandidate?.editorService?.address) {
    return {
      address: repairCandidate.editorService.address,
      source: "nvim manifest",
    };
  }

  const registryRoot = process.env.PINVIM_REGISTRY_ROOT;
  const instanceId = process.env.PINVIM_INSTANCE_ID;
  if (registryRoot && instanceId) {
    const intent = readJsonFile(
      path.join(registryRoot, "instances", instanceId, "main.intent.json"),
    );
    const address = editorAddressFromRecord(intent);
    if (address) return { address, source: "registry intent" };
  }

  if (registryRoot) {
    const instancesRoot = path.join(registryRoot, "instances");
    try {
      for (const entry of fs.readdirSync(instancesRoot)) {
        const intent = readJsonFile(
          path.join(instancesRoot, entry, "main.intent.json"),
        );
        const address = editorAddressFromRecord(intent);
        if (address) return { address, source: "registry intent" };
      }
    } catch {
      // Registry discovery is best-effort and non-fatal.
    }
  }

  return { address: null, source: "none" };
};

const encodeMsgpack = (value: unknown): Buffer => {
  if (value === null || value === undefined) return Buffer.from([0xc0]);
  if (typeof value === "boolean") return Buffer.from([value ? 0xc3 : 0xc2]);
  if (typeof value === "number") {
    if (Number.isInteger(value) && value >= 0 && value <= 0x7f)
      return Buffer.from([value]);
    if (Number.isInteger(value) && value >= -32 && value < 0)
      return Buffer.from([0xe0 | (value + 32)]);
    const buf = Buffer.alloc(5);
    if (value < 0) {
      buf[0] = 0xd2;
      buf.writeInt32BE(value, 1);
    } else {
      buf[0] = 0xce;
      buf.writeUInt32BE(value >>> 0, 1);
    }
    return buf;
  }
  if (typeof value === "string") {
    const body = Buffer.from(value, "utf-8");
    if (body.length <= 31)
      return Buffer.concat([Buffer.from([0xa0 | body.length]), body]);
    if (body.length <= 0xff)
      return Buffer.concat([Buffer.from([0xd9, body.length]), body]);
    const head = Buffer.alloc(3);
    head[0] = 0xda;
    head.writeUInt16BE(body.length, 1);
    return Buffer.concat([head, body]);
  }
  if (Array.isArray(value)) {
    const parts = value.map(encodeMsgpack);
    if (value.length <= 15)
      return Buffer.concat([Buffer.from([0x90 | value.length]), ...parts]);
    const head = Buffer.alloc(3);
    head[0] = 0xdc;
    head.writeUInt16BE(value.length, 1);
    return Buffer.concat([head, ...parts]);
  }
  if (typeof value === "object") {
    const entries = Object.entries(value as Record<string, unknown>).filter(
      ([, item]) => item !== undefined,
    );
    const parts = entries.flatMap(([key, item]) => [
      encodeMsgpack(key),
      encodeMsgpack(item),
    ]);
    if (entries.length <= 15)
      return Buffer.concat([Buffer.from([0x80 | entries.length]), ...parts]);
    const head = Buffer.alloc(3);
    head[0] = 0xde;
    head.writeUInt16BE(entries.length, 1);
    return Buffer.concat([head, ...parts]);
  }
  throw new Error(`unsupported msgpack value: ${typeof value}`);
};

const decodeMsgpack = (
  buffer: Buffer,
  offset = 0,
): { value: unknown; offset: number } | null => {
  if (offset >= buffer.length) return null;
  const byte = buffer[offset++];

  if (byte <= 0x7f) return { value: byte, offset };
  if (byte >= 0xe0) return { value: byte - 0x100, offset };
  if ((byte & 0xe0) === 0xa0) {
    const length = byte & 0x1f;
    if (offset + length > buffer.length) return null;
    return {
      value: buffer.subarray(offset, offset + length).toString("utf-8"),
      offset: offset + length,
    };
  }
  if ((byte & 0xf0) === 0x90) {
    const length = byte & 0x0f;
    const result: unknown[] = [];
    for (let i = 0; i < length; i++) {
      const decoded = decodeMsgpack(buffer, offset);
      if (!decoded) return null;
      result.push(decoded.value);
      offset = decoded.offset;
    }
    return { value: result, offset };
  }
  if ((byte & 0xf0) === 0x80) {
    const length = byte & 0x0f;
    const result: Record<string, unknown> = {};
    for (let i = 0; i < length; i++) {
      const key = decodeMsgpack(buffer, offset);
      if (!key) return null;
      const value = decodeMsgpack(buffer, key.offset);
      if (!value) return null;
      result[String(key.value)] = value.value;
      offset = value.offset;
    }
    return { value: result, offset };
  }

  if (byte === 0xc0) return { value: null, offset };
  if (byte === 0xc2 || byte === 0xc3) return { value: byte === 0xc3, offset };
  if (byte === 0xcc) {
    if (offset + 1 > buffer.length) return null;
    return { value: buffer.readUInt8(offset), offset: offset + 1 };
  }
  if (byte === 0xcd) {
    if (offset + 2 > buffer.length) return null;
    return { value: buffer.readUInt16BE(offset), offset: offset + 2 };
  }
  if (byte === 0xce) {
    if (offset + 4 > buffer.length) return null;
    return { value: buffer.readUInt32BE(offset), offset: offset + 4 };
  }
  if (byte === 0xcf) {
    if (offset + 8 > buffer.length) return null;
    return {
      value: Number(buffer.readBigUInt64BE(offset)),
      offset: offset + 8,
    };
  }
  if (byte === 0xcb) {
    if (offset + 8 > buffer.length) return null;
    return { value: buffer.readDoubleBE(offset), offset: offset + 8 };
  }
  if (byte === 0xd0) {
    if (offset + 1 > buffer.length) return null;
    return { value: buffer.readInt8(offset), offset: offset + 1 };
  }
  if (byte === 0xd1) {
    if (offset + 2 > buffer.length) return null;
    return { value: buffer.readInt16BE(offset), offset: offset + 2 };
  }
  if (byte === 0xd2) {
    if (offset + 4 > buffer.length) return null;
    return { value: buffer.readInt32BE(offset), offset: offset + 4 };
  }
  if (byte === 0xd3) {
    if (offset + 8 > buffer.length) return null;
    return { value: Number(buffer.readBigInt64BE(offset)), offset: offset + 8 };
  }
  if (byte === 0xd9) {
    if (offset + 1 > buffer.length) return null;
    const length = buffer.readUInt8(offset);
    offset += 1;
    if (offset + length > buffer.length) return null;
    return {
      value: buffer.subarray(offset, offset + length).toString("utf-8"),
      offset: offset + length,
    };
  }
  if (byte === 0xda) {
    if (offset + 2 > buffer.length) return null;
    const length = buffer.readUInt16BE(offset);
    offset += 2;
    if (offset + length > buffer.length) return null;
    return {
      value: buffer.subarray(offset, offset + length).toString("utf-8"),
      offset: offset + length,
    };
  }
  if (byte === 0xdc) {
    if (offset + 2 > buffer.length) return null;
    const length = buffer.readUInt16BE(offset);
    offset += 2;
    const result: unknown[] = [];
    for (let i = 0; i < length; i++) {
      const decoded = decodeMsgpack(buffer, offset);
      if (!decoded) return null;
      result.push(decoded.value);
      offset = decoded.offset;
    }
    return { value: result, offset };
  }
  if (byte === 0xde) {
    if (offset + 2 > buffer.length) return null;
    const length = buffer.readUInt16BE(offset);
    offset += 2;
    const result: Record<string, unknown> = {};
    for (let i = 0; i < length; i++) {
      const key = decodeMsgpack(buffer, offset);
      if (!key) return null;
      const value = decodeMsgpack(buffer, key.offset);
      if (!value) return null;
      result[String(key.value)] = value.value;
      offset = value.offset;
    }
    return { value: result, offset };
  }

  throw new Error(`unsupported msgpack byte: 0x${byte.toString(16)}`);
};

const markEditorServiceStale = (error: string): void => {
  editorService.connected = false;
  editorService.connecting = false;
  editorService.stale = true;
  editorService.lastError = error;
  updateStatus();
};

const markEditorServiceOk = (method?: string): void => {
  editorService.connected = true;
  editorService.connecting = false;
  editorService.stale = false;
  editorService.lastOkAt = Date.now();
  editorService.lastError = null;
  if (method) editorService.lastMethod = method;
  updateStatus();
};

const editorServiceRequest = (
  method: EditorMethod,
  params: Record<string, unknown> = {},
): Promise<EditorQueryResult> => {
  const discovery = resolveEditorServiceAddress();
  const address = discovery.address;
  editorService.address = address;
  editorService.source = discovery.source;
  if (!address) {
    markEditorServiceStale(
      "missing nvim listen address; using peer socket fallback only",
    );
    return Promise.resolve({
      ok: false,
      error: editorService.lastError || "missing nvim listen address",
    });
  }

  return new Promise((resolve) => {
    const socket = net.createConnection(address);
    socket.unref();
    socket.ref();
    let buffer = Buffer.alloc(0);
    let settled = false;
    const requestId = editorServiceRequestId++;
    const finish = (result: EditorQueryResult): void => {
      if (settled) return;
      settled = true;
      clearTimeout(timeout);
      socket.destroy();
      resolve(result);
    };
    const timeout = setTimeout(() => {
      markEditorServiceStale(`editor-service ${method} timeout`);
      finish({ ok: false, error: `editor-service ${method} timeout` });
    }, EDITOR_SERVICE_TIMEOUT_MS);
    timeout.unref();
    timeout.ref();

    socket.on("connect", () => {
      editorService.connecting = false;
      const lua =
        "local method, params = ...; return require('pinvim').api.editor_rpc(method, params or {})";
      socket.write(
        encodeMsgpack([0, requestId, "nvim_exec_lua", [lua, [method, params]]]),
      );
    });

    socket.on("data", (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      let decoded: { value: unknown; offset: number } | null;
      try {
        decoded = decodeMsgpack(buffer);
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        markEditorServiceStale(message);
        finish({ ok: false, error: message });
        return;
      }
      if (!decoded) return;
      const response = decoded.value;
      if (
        !Array.isArray(response) ||
        response[0] !== 1 ||
        response[1] !== requestId
      ) {
        finish({ ok: false, error: "unexpected editor-service response" });
        return;
      }
      const error = response[2];
      if (error) {
        const message =
          typeof error === "string" ? error : JSON.stringify(error);
        markEditorServiceStale(message);
        finish({ ok: false, error: message });
        return;
      }
      markEditorServiceOk(method);
      finish({ ok: true, result: response[3] });
    });

    socket.on("error", (err) => {
      markEditorServiceStale(err.message || "editor-service socket error");
      finish({
        ok: false,
        error: err.message || "editor-service socket error",
      });
    });

    socket.on("close", () => {
      if (!settled)
        finish({ ok: false, error: "editor-service socket closed" });
    });
  });
};

// =============================================================================
// Pi-initiated review spawn (dot-zarv)
//
// When a bare Pi has no paired Nvim editor service, `/piview` can spawn a
// review Nvim in a new tmux pane that pairs back to this Pi. The bare Pi adopts
// the target worktree's pinvim registry identity (parent.id + deterministic
// workspace_id) so the incoming Nvim peer passes peerAllowedForSocket via
// exactParentRegistry. Identity adoption is scoped to this spawn: it only runs
// when the Pi is unpaired, and re-adopts on each spawn so re-targeting works.
// =============================================================================

/** sha256(value).slice(0,16) — mirrors Nvim stable_hash in pinvim.lua. */
const stableHash16 = (value: string): string =>
  crypto.createHash("sha256").update(value).digest("hex").slice(0, 16);

/** Resolve the worktree root for a cwd (git toplevel), else cwd itself. */
const resolveWorktreeRoot = (cwd: string): string => {
  try {
    const res = spawnSync("git", ["rev-parse", "--show-toplevel"], {
      cwd,
      encoding: "utf-8",
      timeout: 2000,
    });
    if (res.status === 0 && res.stdout) return res.stdout.trim();
  } catch {
    // fall through
  }
  return cwd;
};

/** realpath with trailing-slash strip — mirrors Nvim normalize_path. */
const normalizePath = (p: string): string => {
  try {
    const real = fs.realpathSync(p);
    return real.replace(/\/+$/, "") || real;
  } catch {
    return p.replace(/\/+$/, "") || p;
  }
};

interface SpawnReviewResult {
  ok: boolean;
  socket?: string;
  worktree?: string;
  workspaceId?: string;
  pane?: string;
  error?: string;
}

/**
 * Spawn a review Nvim in a new tmux pane that pairs back to this Pi.
 *
 * Adopts the target worktree's registry identity (creating parent.id if absent
 * so the Nvim reuses it), sets this Pi's PINVIM_PARENT_ID/PINVIM_WORKSPACE_ID
 * env so peerAllowedForSocket accepts the incoming peer via exactParentRegistry,
 * and launches `nvim +PiReview <scope> [diffMode]` with PI_SOCKET pointing at this Pi.
 */
const spawnReviewNvim = (
  scope: string,
  worktreeCwd?: string,
  diffMode?: string,
): SpawnReviewResult => {
  if (!process.env.TMUX) {
    return { ok: false, error: "piview spawn requires tmux" };
  }
  const socket = SOCKET_PATH;
  if (!socket) {
    return { ok: false, error: "pinvim socket not resolved" };
  }

  const cwd = worktreeCwd || process.cwd();
  const root = normalizePath(resolveWorktreeRoot(cwd));
  const workspaceId = stableHash16(root);
  const registryDir = path.join(PI_STATE_DIR, "pinvim", workspaceId);
  const parentIdPath = path.join(registryDir, "parent.id");

  try {
    fs.mkdirSync(registryDir, { recursive: true });
  } catch {
    // best-effort; Nvim will recreate
  }

  // Read or create parent.id so Nvim's Registry.setup reuses the same id.
  let parentId = "";
  try {
    parentId = fs.readFileSync(parentIdPath, "utf-8").trim();
  } catch {
    parentId = `parent:${stableHash16(root + "\0" + String(Date.now()) + "\0" + String(process.pid))}`;
    try {
      fs.mkdirSync(path.dirname(parentIdPath), { recursive: true });
      fs.writeFileSync(parentIdPath, parentId, "utf-8");
    } catch {
      return { ok: false, error: "could not write pinvim parent.id" };
    }
  }

  // Adopt the worktree identity so the incoming Nvim peer is accepted.
  process.env.PINVIM_PARENT_ID = parentId;
  process.env.PINVIM_WORKSPACE_ID = workspaceId;

  // Spawn nvim in a new tmux pane, pointing it at this Pi's socket + identity.
  // tmux split-window -e KEY=VAL passes env to the new pane's process.
  const reviewArgs = [scope, diffMode].filter(Boolean).join(" ");
  const nvimCmd = `nvim '+PiReview ${reviewArgs}'`;
  const res = spawnSync(
    "tmux",
    [
      "split-window",
      "-h",
      "-l",
      "40%",
      "-c",
      root,
      "-P",
      "-F",
      "#{pane_id}",
      "-e",
      `PI_SOCKET=${socket}`,
      "-e",
      `PINVIM_PARENT_ID=${parentId}`,
      "-e",
      `PINVIM_WORKSPACE_ID=${workspaceId}`,
      nvimCmd,
    ],
    { encoding: "utf-8", timeout: 3000 },
  );
  const pane = res.stdout.trim();
  if (res.status !== 0 || !pane) {
    return {
      ok: false,
      error: `tmux split-window failed: ${res.stderr || "unknown"}`,
    };
  }
  return { ok: true, socket, worktree: root, workspaceId, pane };
};

interface FocusPaneResult {
  ok: boolean;
  pane?: string;
  error?: string;
}

/**
 * Focus the tmux pane hosting the paired review Nvim so the user lands in the
 * review surface after `/piview`. Defaults to the active peer's pane; callers
 * may pass an explicit pane id (e.g. a freshly spawned review pane).
 */
const focusReviewPane = (paneOverride?: string): FocusPaneResult => {
  if (!process.env.TMUX) {
    return { ok: false, error: "not in tmux" };
  }
  const pane = paneOverride || getActivePeer()?.tmux?.pane;
  if (!pane) {
    return { ok: false, error: "no paired Nvim pane known" };
  }
  // Select the window containing the pane first (no-op if same window), then
  // the pane itself. Pane ids are global so they resolve across windows.
  spawnSync("tmux", ["select-window", "-t", pane], { timeout: 800 });
  const res = spawnSync("tmux", ["select-pane", "-t", pane], {
    encoding: "utf-8",
    timeout: 800,
  });
  if (res.status !== 0) {
    return {
      ok: false,
      pane,
      error: (res.stderr || "").trim() || "tmux select-pane failed",
    };
  }
  return { ok: true, pane };
};

const pinvimEditorServiceApi = {
  query: editorServiceRequest,
  status: () => ({ ...editorService }),
  spawnReviewNvim,
  focusReviewPane,
};

(
  globalThis as typeof globalThis & {
    pinvimEditorService?: typeof pinvimEditorServiceApi;
  }
).pinvimEditorService = pinvimEditorServiceApi;

const ensureEditorServiceClient = (): void => {
  const discovery = resolveEditorServiceAddress();
  const address = discovery.address;
  editorService.address = address;
  editorService.source = discovery.source;
  if (!address) {
    markEditorServiceStale(
      "missing nvim listen address; using peer socket fallback only",
    );
    return;
  }

  const lastOkAge = editorService.lastOkAt
    ? Date.now() - editorService.lastOkAt
    : Infinity;
  if (editorService.connected && lastOkAge < EDITOR_SERVICE_STALE_MS) return;
  if (editorService.connecting) return;

  editorServiceSocket?.destroy();
  editorServiceSocket = null;
  editorService.connecting = true;
  editorService.connected = false;
  editorService.stale = lastOkAge >= EDITOR_SERVICE_STALE_MS;
  editorService.lastError = null;
  updateStatus();

  const socket = net.createConnection(address);
  editorServiceSocket = socket;
  socket.unref();
  const timeout = setTimeout(() => {
    socket.destroy();
    markEditorServiceStale("editor-service connect timeout");
  }, EDITOR_SERVICE_TIMEOUT_MS);
  timeout.unref();

  socket.on("connect", () => {
    clearTimeout(timeout);
    markEditorServiceOk("status");
    const request = [
      0,
      editorServiceRequestId++,
      "nvim_get_vvar",
      ["servername"],
    ];
    socket.write(encodeMsgpack(request));
    updateStatus();
  });

  socket.on("data", () => {
    markEditorServiceOk("status");
    updateStatus();
  });

  socket.on("error", (err) => {
    clearTimeout(timeout);
    markEditorServiceStale(err.message || "editor-service socket error");
  });

  socket.on("close", () => {
    clearTimeout(timeout);
    editorService.connected = false;
    editorService.connecting = false;
    if (
      !editorService.lastOkAt ||
      Date.now() - editorService.lastOkAt >= EDITOR_SERVICE_STALE_MS
    ) {
      editorService.stale = true;
    }
    updateStatus();
  });
};

// =============================================================================
// Formatting
// =============================================================================

const getActivePeer = (): PeerIdentity | null =>
  state.lastHello?.peer || state.lastHelloAck?.peer || null;

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
  linkMode:
    process.env.PINVIM_LINK_MODE ||
    (isNestedAttachOnly() ? "attach-only" : "auto"),
  parentId: process.env.PINVIM_PARENT_ID,
  pairId: process.env.PINVIM_PAIR_ID,
  workspaceId: process.env.PINVIM_WORKSPACE_ID,
  instanceId: process.env.PINVIM_INSTANCE_ID,
  registryRoot: process.env.PINVIM_REGISTRY_ROOT,
  role:
    process.env.PINVIM_SESSION_ROLE ||
    (isNestedAttachOnly() ? "nested" : isEphemeral() ? "child" : "main"),
  nvimListenAddress: resolveEditorServiceAddress().address || undefined,
  heartbeatAt: Math.floor(Date.now() / 1000),
});

const buildHelloAck = (): HelloAckPayload => ({
  type: "hello_ack",
  protocol: "pinvim.peer.v1",
  peer: buildPinvimPeerIdentity(),
  accepts: [
    "hello",
    "heartbeat",
    "ping",
    "prompt",
    "fill_prompt",
    "explicit_send",
  ],
});

const formatExplicitContext = (
  payload: ExplicitSendPayload,
  mode: "attached" | "prompt" = "prompt",
): string => {
  const { context } = payload;
  const parts: string[] = [
    mode === "attached"
      ? "[NEOVIM ATTACHED CONTEXT]"
      : "[NEOVIM EXPLICIT CONTEXT]",
  ];

  if (context.kind) parts.push(`Kind: ${context.kind}`);
  if (context.file) parts.push(`Focused file: ${context.file}`);
  if (context.filetype) parts.push(`Filetype: ${context.filetype}`);
  if (context.cursor)
    parts.push(`Cursor: L${context.cursor.line}:C${context.cursor.col}`);
  if (context.selectionRange)
    parts.push(
      `Range: lines ${context.selectionRange[0]}-${context.selectionRange[1]}`,
    );
  if (context.word) {
    const label = context.symbolKind
      ? `${context.symbolKind} \`${context.word}\``
      : `\`${context.word}\``;
    parts.push(`Symbol: ${label} \u25C0 cursor focus`);
    if (context.hasDiagnostics) parts.push("Diagnostics: present at cursor");
    if (context.lspActive) parts.push("LSP: active");
  }

  if (context.selection?.trim()) {
    parts.push(
      context.kind === "selection" ? "Selected text:" : "Cursor context:",
    );
    parts.push(`\`\`\`${context.filetype || ""}`);
    parts.push(context.selection);
    parts.push("```");
  }

  if (context.userInput?.trim()) {
    parts.push("User input:");
    parts.push(context.userInput.trim());
  }

  if (context.modified) parts.push("Buffer: modified (unsaved)");

  parts.push(
    mode === "attached"
      ? "User attached this context from Neovim before sending the prompt."
      : "User explicitly sent this context from Neovim.",
  );
  return parts.join("\n");
};

type PinvimFooterState = "connected" | "repaired" | "stale";

const pinvimFooterStatusPrefix = "pinvim.v1:";

const formatContextLabel = (payload: ExplicitSendPayload): string => {
  const context = payload.context;
  const file = context.file || context.absFile || context.kind || "context";
  const basename = file.split("/").pop() || file;
  if (context.selectionRange) {
    const [start, end] = context.selectionRange;
    return start === end
      ? `${basename}:${start}`
      : `${basename}:${start}-${end}`;
  }
  if (context.cursor?.line) return `${basename}:${context.cursor.line}`;
  return basename;
};

const exactPairConnected = (peer: PeerIdentity): boolean =>
  !!process.env.PINVIM_PAIR_ID && peer.pairId === process.env.PINVIM_PAIR_ID;

const pinvimFooterState = (peer: PeerIdentity): PinvimFooterState => {
  const health = getHealth();
  if (health.heartbeatAgeSeconds !== null && health.heartbeatAgeSeconds >= 120)
    return "stale";
  if (exactPairConnected(peer)) return "connected";
  return repairedAt ? "repaired" : "connected";
};

const formatFooterStatus = (): string => {
  const peer = getActivePeer();
  if (!peer) return "";

  const peerLabel = peer.root || peer.cwd || peer.id;
  const label =
    pendingContext?.label || peerLabel.split("/").pop() || peerLabel;
  const status = pinvimFooterState(peer);

  return `${pinvimFooterStatusPrefix}${JSON.stringify({ status, label })}`;
};

const formatStatus = (): string => {
  const peer = getActivePeer();
  if (!peer) return "(no active peer)";
  const peerLabel = peer.root || peer.cwd || peer.id;
  const status = pinvimFooterState(peer);
  const context = pendingContext ? `, context ${pendingContext.label}` : "";
  return `${status}: ${peerLabel}${context}`;
};

const getHealth = (): PinvimHealth => {
  const activePeer = getActivePeer();
  const heartbeatAgeSeconds = state.lastHeartbeat?.sentAt
    ? Math.max(Math.floor(Date.now() / 1000) - state.lastHeartbeat.sentAt, 0)
    : null;
  return {
    ok:
      !!activePeer &&
      (heartbeatAgeSeconds === null || heartbeatAgeSeconds < 120),
    activePeerId: activePeer?.id || null,
    heartbeatAgeSeconds,
  };
};

const samePath = (a?: string, b?: string): boolean =>
  !!a && !!b && path.resolve(a) === path.resolve(b);

const pidAlive = (pid?: number): boolean => {
  if (!pid || pid <= 0) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
};

// Detect orphaned `nvim --embed` whose GUI frontend died without reaping the
// child. Symptoms: PPID=1 (adopted by init) and no controlling terminal
// (tty `??`). Real terminal nvim has a pty tty and a shell parent.
const pidIsOrphanedEmbed = (pid?: number): boolean => {
  if (!pid || pid <= 0) return false;
  try {
    const res = spawnSync("ps", ["-p", String(pid), "-o", "ppid=,tty="], {
      encoding: "utf8",
      timeout: 500,
    });
    if (res.status !== 0 || !res.stdout) return false;
    const parts = res.stdout.trim().split(/\s+/);
    if (parts.length < 2) return false;
    const ppid = Number(parts[0]);
    const tty = parts[1];
    return ppid === 1 && (tty === "??" || tty === "?" || tty === "-");
  } catch {
    return false;
  }
};

const socketPathExists = (sockPath?: string): boolean => {
  if (!sockPath) return true; // No socket field in manifest -> nothing to check.
  try {
    return fs.statSync(sockPath).isSocket();
  } catch {
    return false;
  }
};

// manifestPath -> reason, surfaced by /pinvim-doctor for visibility.
const skippedManifests: Map<string, string> = new Map();

const nvimPeerAgeSeconds = (candidate: NvimPeerCandidate): number | null =>
  candidate.heartbeatAt
    ? Math.max(Math.floor(Date.now() / 1000) - candidate.heartbeatAt, 0)
    : null;

const candidateSession = (candidate: NvimPeerCandidate): string | undefined =>
  candidate.tmux?.session || candidate.session;

const candidateWindow = (candidate: NvimPeerCandidate): string | undefined =>
  candidate.tmux?.window || candidate.window;

const candidatePane = (candidate: NvimPeerCandidate): string | undefined =>
  candidate.tmux?.pane || candidate.pane;

const sameRootOrCwd = (candidate: NvimPeerCandidate): boolean =>
  samePath(candidate.cwd, process.cwd()) ||
  samePath(candidate.root, process.cwd());

const sameWindow = (candidate: NvimPeerCandidate): boolean =>
  candidateSession(candidate) === PI_SESSION &&
  candidateWindow(candidate) === PI_WINDOW;

const peerNeedsRepair = (): boolean => {
  const health = getHealth();
  return (
    !health.activePeerId ||
    (health.heartbeatAgeSeconds !== null && health.heartbeatAgeSeconds >= 120)
  );
};

const scoreNvimCandidate = (
  candidate: NvimPeerCandidate,
): NvimPeerCandidate | null => {
  const manifestKey = candidate.manifestPath || candidate.id || "";
  const skip = (reason: string): null => {
    if (manifestKey) skippedManifests.set(manifestKey, reason);
    return null;
  };
  if (candidate.kind !== "nvim" && candidate.owner !== "pinvim.lua")
    return skip("wrong kind/owner");
  if (candidate.pid !== undefined && !pidAlive(candidate.pid))
    return skip("pid dead");
  if (candidate.pid !== undefined && pidIsOrphanedEmbed(candidate.pid))
    return skip("orphaned --embed nvim (ppid=1, no tty)");
  if (candidate.socket && !socketPathExists(candidate.socket))
    return skip(`stale socket (${candidate.socket})`);
  if (candidateSession(candidate) !== PI_SESSION)
    return skip(`different tmux session (${candidateSession(candidate)})`);
  if (manifestKey) skippedManifests.delete(manifestKey);

  const age = nvimPeerAgeSeconds(candidate);
  const fresh = age !== null && age <= 30;
  const recent = age !== null && age <= 900;
  const windowMatch = sameWindow(candidate);
  const rootMatch = sameRootOrCwd(candidate);
  const ephemeral = isEphemeral();

  if (ephemeral) {
    const linkedHere = !SOCKET_PATH || candidate.socket === SOCKET_PATH;
    if (!windowMatch && !(rootMatch && recent && linkedHere)) return null;
  } else if (!windowMatch) {
    return null;
  }

  const reasons: string[] = [];
  let score = 0;
  if (windowMatch) {
    score += 200;
    reasons.push("same tmux window");
  }
  if (rootMatch) {
    score += 60;
    reasons.push("same cwd/root");
  }
  if (fresh) {
    score += 40;
    reasons.push("fresh heartbeat");
  } else if (recent) {
    score += 10;
    reasons.push("recent heartbeat");
  }
  if (candidatePane(candidate)) {
    score += 5;
    reasons.push(`pane ${candidatePane(candidate)}`);
  }

  return { ...candidate, score, reasons };
};

const scanNvimPeers = async (): Promise<NvimPeerCandidate[]> => {
  if (isNestedAttachOnly()) return [];

  let entries: string[] = [];
  try {
    entries = await fsp.readdir(INFO_DIR);
  } catch {
    return [];
  }

  const candidates: NvimPeerCandidate[] = [];
  for (const entry of entries) {
    if (!entry.startsWith("nvim-") || !entry.endsWith(".info")) continue;
    const manifestPath = path.join(INFO_DIR, entry);
    try {
      const raw = await fsp.readFile(manifestPath, "utf-8");
      const parsed = JSON.parse(
        raw.split("\n")[0] || "{}",
      ) as NvimPeerCandidate;
      const scored = scoreNvimCandidate({ ...parsed, manifestPath });
      if (scored) candidates.push(scored);
    } catch {
      // Ignore malformed manifests.
    }
  }

  candidates.sort((a, b) => {
    if ((a.score || 0) !== (b.score || 0))
      return (b.score || 0) - (a.score || 0);
    return (b.heartbeatAt || 0) - (a.heartbeatAt || 0);
  });

  return candidates;
};

const refreshRepairCandidate = async (
  opts: { force?: boolean } = {},
): Promise<void> => {
  if (isNestedAttachOnly() || (!opts.force && !shouldAutoScanNvimPeers())) {
    repairCandidate = null;
    return;
  }
  if (!opts.force && !peerNeedsRepair()) return;
  const [candidate] = await scanNvimPeers();
  // @lat: dot-so9c: RepairCandidate is diagnostic-only
  // Nvim manifests should never auto-adopt for pairing.
  // This is read-only for diagnostics and manual repair.
  repairCandidate = candidate || null;
  updateStatus();
};

const peerAllowedForSocket = (
  peer: PeerIdentity,
): { ok: boolean; reason: string } => {
  if (isNestedAttachOnly()) {
    return {
      ok: false,
      reason: "nested attach-only pinvim does not accept nvim peer links",
    };
  }

  const localIdentity = buildPinvimPeerIdentity();
  const identityChecks: Array<
    ["parentId" | "workspaceId" | "instanceId", string]
  > = [
    ["parentId", "parent identity"],
    ["workspaceId", "workspace identity"],
    ["instanceId", "nvim instance identity"],
  ];
  const exactParentRegistry =
    !!localIdentity.parentId &&
    !!localIdentity.workspaceId &&
    peer.parentId === localIdentity.parentId &&
    peer.workspaceId === localIdentity.workspaceId;

  for (const [key, label] of identityChecks) {
    if (key === "instanceId" && exactParentRegistry) continue;
    if ((localIdentity[key] || peer[key]) && localIdentity[key] !== peer[key]) {
      return { ok: false, reason: `mismatched pinvim ${label}` };
    }
  }

  if (
    localIdentity.pairId &&
    peer.pairId &&
    localIdentity.pairId !== peer.pairId
  ) {
    return { ok: false, reason: "mismatched pair identity" };
  }

  // dot-0v6y AC1/AC4: exact pairId is the strongest claim and is always
  // accepted, including non-tmux peers and explicit target mode.
  if (
    localIdentity.pairId &&
    peer.pairId &&
    localIdentity.pairId === peer.pairId
  ) {
    return { ok: true, reason: "exact pinvim pair id" };
  }

  if (exactParentRegistry) {
    return { ok: true, reason: "exact pinvim parent registry" };
  }

  const candidate: NvimPeerCandidate = {
    id: peer.id,
    kind: peer.kind,
    cwd: peer.cwd,
    root: peer.root,
    tmux: peer.tmux,
    heartbeatAt: peer.heartbeatAt,
    linkMode: peer.linkMode,
    parentId: peer.parentId,
    workspaceId: peer.workspaceId,
    instanceId: peer.instanceId,
    registryRoot: peer.registryRoot,
    role: peer.role,
    nvimListenAddress: peer.nvimListenAddress,
  };

  // dot-0v6y AC3: a same-window score must not steal a Pi that is still
  // actively paired with a different live peer. Allow the claim only when the
  // current peer is unpaired, gone, or its heartbeat is stale (>20s).
  const activePeer = getActivePeer();
  if (activePeer && activePeer.id !== peer.id) {
    const heartbeatAge = state.lastHeartbeat?.sentAt
      ? Math.max(Math.floor(Date.now() / 1000) - state.lastHeartbeat.sentAt, 0)
      : null;
    const activePeerLive =
      heartbeatAge === null || heartbeatAge <= STRICT_PAIR_STALE_SECONDS;
    if (activePeerLive) {
      return {
        ok: false,
        reason: `pinvim already paired with live peer ${activePeer.id} (strict claim blocked <${STRICT_PAIR_STALE_SECONDS}s)`,
      };
    }
  }

  const scored = scoreNvimCandidate(candidate);
  if (scored) return { ok: true, reason: (scored.reasons || []).join(", ") };

  const candidateMatchesRepair =
    isEphemeral() &&
    repairCandidate?.id === peer.id &&
    (!SOCKET_PATH || repairCandidate.socket === SOCKET_PATH) &&
    sameRootOrCwd(candidate);
  if (candidateMatchesRepair) {
    return { ok: true, reason: "recent same-root repair candidate" };
  }

  return {
    ok: false,
    reason: "nvim peer outside allowed tmux/window/root repair scope",
  };
};

const emitCommandLines = (
  ctx: ExtensionContext,
  lines: string[],
  level: "info" | "warn" = "info",
): void => {
  if (ctx.hasUI) {
    ctx.ui.notify(lines.join("\n"), level);
  } else {
    console.log(lines.join("\n"));
  }
};

const editorServiceStateLine = (): string =>
  editorService.connected
    ? "connected"
    : editorService.stale
      ? "stale"
      : "disconnected";

const editorServiceFallbackLine = (): string =>
  editorService.connected ? "no" : "peer socket only";

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
    `Local identity: ${JSON.stringify(buildPinvimPeerIdentity(), null, 2)}`,
    `Pinvim relation: ${pinvimRelationState()}`,
    `Nested attach-only: ${isNestedAttachOnly()}`,
    // dot-l8d4: surface strict pair state explicitly, not just inside JSON.
    `Pair id: ${process.env.PINVIM_PAIR_ID || "(none)"}`,
    `Active peer pair id: ${activePeer?.pairId || "(none)"}`,
    `Pair status: ${
      activePeer?.pairId && process.env.PINVIM_PAIR_ID
        ? activePeer.pairId === process.env.PINVIM_PAIR_ID
          ? "paired (exact)"
          : "mismatch"
        : "unpaired"
    }`,
    `Active peer: ${activePeer ? JSON.stringify(activePeer, null, 2) : "(none yet)"}`,
    `Repair candidate: ${repairCandidate ? JSON.stringify(repairCandidate, null, 2) : "(none)"}`,
    `Repaired at: ${repairedAt ? new Date(repairedAt).toISOString() : "(none)"}`,
    `Repair reason: ${repairReason || "(none)"}`,
    `Pending context: ${pendingContext ? `${pendingContext.label}, expires ${new Date(pendingContext.expiresAt).toISOString()}` : "(none)"}`,
    `Editor service: ${editorService.address || "(none)"}`,
    `Editor service source: ${editorService.source}`,
    `Editor service fallback: ${editorServiceFallbackLine()}`,
    `Editor service transport: ${editorService.transport}`,
    `Editor service connected: ${editorService.connected}`,
    `Editor service stale: ${editorService.stale}`,
    `Editor service last ok: ${editorService.lastOkAt ? new Date(editorService.lastOkAt).toISOString() : "(none)"}`,
    `Editor service error: ${editorService.lastError || "(none)"}`,
    `Editor service last method: ${editorService.lastMethod || "(none)"}`,
    "Responsibilities:",
    "- owns pinvim socket for all nvim↔pi frames",
    "- owns peer metadata + footer status",
    "- attach-mode explicit sends wait for the next user prompt",
    "- prompt-mode explicit sends become user messages; active sessions receive followUp",
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
    ctx.ui.setStatus("pinvim", formatFooterStatus());
    ctx.ui.setStatus("pinvim-context", undefined);
    ctx.ui.setStatus("pinvim-repair", undefined);
  } catch {
    latestCtx = null;
  }
};

const clearPendingContext = (reason?: string): void => {
  if (pendingContextTimer) {
    clearTimeout(pendingContextTimer);
    pendingContextTimer = null;
  }
  const hadContext = pendingContext !== null;
  pendingContext = null;
  updateStatus();
  if (hadContext && reason) latestCtx?.ui?.notify?.(reason, "info");
};

const attachPendingContext = (payload: ExplicitSendPayload): void => {
  if (pendingContextTimer) {
    clearTimeout(pendingContextTimer);
    pendingContextTimer = null;
  }

  pendingContext = {
    text: formatExplicitContext(payload, "attached"),
    label: formatContextLabel(payload),
    attachedAt: Date.now(),
    expiresAt: Date.now() + PENDING_CONTEXT_TTL_MS,
  };
  pendingContextTimer = setTimeout(() => {
    clearPendingContext("Pinvim attached context expired");
  }, PENDING_CONTEXT_TTL_MS);
  pendingContextTimer.unref();

  updateStatus();
  latestCtx?.ui?.notify?.(
    `Pinvim attached ${payload.context.kind || "cursor"} context for next user prompt`,
    "info",
  );
};

const consumePendingContext = (): string | null => {
  if (!pendingContext) return null;
  if (Date.now() > pendingContext.expiresAt) {
    clearPendingContext("Pinvim attached context expired before next prompt");
    return null;
  }

  const text = pendingContext.text;
  clearPendingContext();
  return text;
};

const editorContextPayload = (context: unknown): ExplicitSendPayload | null => {
  if (!context || typeof context !== "object") return null;
  return {
    type: "explicit_send",
    delivery: "attach",
    context: context as ExplicitSendPayload["context"],
  };
};

const fetchLiveEditorContext = async (): Promise<string | null> => {
  const response = await editorServiceRequest("context.current");
  if (!response.ok) return null;
  const payload = editorContextPayload(response.result);
  if (!payload) return null;
  return formatExplicitContext(payload, "attached").replace(
    "[NEOVIM ATTACHED CONTEXT]",
    "[NEOVIM LIVE CONTEXT]",
  );
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

const tellWidgetTimers = new Map<string, ReturnType<typeof setTimeout>>();

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
  return `${cleaned.slice(0, maxLength - 1)}…`;
};

const notifyTellViaNtfy = (from: string, text: string): void => {
  const home = process.env.HOME || "";
  const candidates = [path.join(home, "bin", "ntfy"), "ntfy"];
  const title = `Pi tell from ${from}`;
  const message = summarizeTellText(text, 220) || "New Pi tell message";
  const tryNext = (index: number): void => {
    const command = candidates[index];
    if (!command) return;
    execFile(
      command,
      ["send", "-t", title, "-m", message, "-s", "pi tell"],
      { timeout: 2000 },
      (err) => {
        if (err && index + 1 < candidates.length) tryNext(index + 1);
      },
    );
  };
  tryNext(0);
};

const persistAndSurfaceTell = (
  pi: ExtensionAPI,
  payload: TellPayload,
): void => {
  const ctx = latestCtx;
  const id = payload.id || `tell-${Date.now().toString(36)}`;
  const from = payload.from || "unknown";
  const summary = summarizeTellText(payload.text) || "New Pi tell message";

  pi.appendEntry("tell-message", {
    id,
    direction: "received",
    from,
    fromSocket: payload.fromSocket,
    text: payload.text,
    timestamp: payload.timestamp || Math.floor(Date.now() / 1000),
  });

  notifyTellViaNtfy(from, payload.text);

  if (!ctx?.hasUI) return;
  ctx.ui.notify(`Tell from ${from}`, "info");
  ctx.ui.setWidget("tell", [
    ctx.ui.theme.fg("accent", `Tell from ${from}`),
    summary,
    ctx.ui.theme.fg(
      "muted",
      `Use /tell ${from.split(" ")[0]} <message> to reply`,
    ),
  ]);

  const existing = tellWidgetTimers.get(id);
  if (existing) clearTimeout(existing);
  const timer = setTimeout(() => {
    latestCtx?.ui?.setWidget?.("tell", undefined);
    tellWidgetTimers.delete(id);
  }, 120_000);
  timer.unref();
  tellWidgetTimers.set(id, timer);
};

const focusOwnTmuxPane = (): void => {
  if (!PI_PANE && !process.env.TMUX_PANE) return;
  const pane = PI_PANE || process.env.TMUX_PANE;
  if (!pane) return;
  execFile("tmux", ["select-pane", "-t", pane], { timeout: 500 }, () => {});
};

const changedPathFromToolEvent = (
  event: { input?: unknown },
  cwd: string,
): string | null => {
  const input = (event.input || {}) as Record<string, unknown>;
  const rawPath =
    typeof input.path === "string"
      ? input.path
      : typeof input.file === "string"
        ? input.file
        : typeof input.absFile === "string"
          ? input.absFile
          : null;
  if (!rawPath || rawPath.trim() === "") return null;
  return path.isAbsolute(rawPath) ? rawPath : path.resolve(cwd, rawPath);
};

const describeReloadBufferResult = (
  toolName: string,
  filePath: string,
  result: ReloadBufferResult,
): string | null => {
  const conflicts = result.conflicts || [];
  if (conflicts.length === 0) return null;
  return [
    `Pinvim kept dirty buffer${conflicts.length === 1 ? "" : "s"} unchanged after ${toolName}: ${path.basename(filePath)}`,
    "Disk changed. Buffer still dirty. Compare buffer with file before saving.",
  ].join("\n");
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

let manifestWriteTimer: NodeJS.Timeout | null = null;
let manifestWriteInFlight = false;
let lastManifestWriteAt = 0;

const writeInfoManifestNow = async (): Promise<void> => {
  if (!SOCKET_PATH || !PI_SESSION || manifestWriteInFlight) return;

  manifestWriteInFlight = true;
  try {
    await fsp.mkdir(INFO_DIR, { recursive: true });
    const socketBase =
      SOCKET_PATH.split("/")
        .pop()
        ?.replace(/\.sock$/, "") || PI_SESSION;
    infoManifestPath = `${INFO_DIR}/${socketBase}.info`;
    const identity = buildPinvimPeerIdentity();
    const manifest = {
      socket: SOCKET_PATH,
      cwd: process.cwd(),
      root: process.cwd(),
      pid: process.pid,
      session: PI_SESSION,
      window: PI_WINDOW,
      pane: PI_PANE,
      ephemeral: isEphemeral(),
      owner: "pinvim.ts",
      linkMode:
        process.env.PINVIM_LINK_MODE || (isEphemeral() ? "ephemeral" : "auto"),
      parentId: identity.parentId,
      workspaceId: identity.workspaceId,
      instanceId: identity.instanceId,
      pairId: process.env.PINVIM_PAIR_ID || identity.parentId,
      registryRoot: identity.registryRoot,
      role: identity.role,
      relation: pinvimRelationState(),
      attachOnly: isNestedAttachOnly(),
      nvimListenAddress: identity.nvimListenAddress,
      editorService: {
        address: identity.nvimListenAddress,
        source: editorService.source,
        fallback: editorServiceFallbackLine(),
        transport: "msgpack-rpc",
        connected: editorService.connected,
        stale: editorService.stale,
        lastMethod: editorService.lastMethod,
      },
      activePeerId: getActivePeer()?.id || null,
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
  manifestWriteTimer = setTimeout(
    () => {
      manifestWriteTimer = null;
      void writeInfoManifestNow();
    },
    force ? 0 : 250,
  );
  manifestWriteTimer.unref();
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

const handleSocketPayload = (
  pi: ExtensionAPI,
  socket: net.Socket,
  payload: Payload,
): void => {
  if (isPingPayload(payload)) {
    respondOk(socket, { type: "pong" });
    return;
  }

  if (isHelloPayload(payload)) {
    if (payload.protocol !== "pinvim.peer.v1") {
      respondError(socket, `unsupported pinvim protocol: ${payload.protocol}`);
      return;
    }

    const allowed = peerAllowedForSocket(payload.peer);
    if (!allowed.ok) {
      respondError(socket, allowed.reason);
      return;
    }

    acceptedSockets.add(socket);
    const wasRepairing = peerNeedsRepair() || repairCandidate !== null;
    state.lastHello = payload;
    const helloAck = buildHelloAck();
    state.lastHelloAck = helloAck;
    if (wasRepairing) {
      repairedAt = Date.now();
      repairReason = allowed.reason || "hello accepted";
      repairCandidate = null;
      updateStatus();
      latestCtx?.ui?.notify?.(
        `Pinvim peer repaired: ${payload.peer.id}`,
        "info",
      );
    }
    updateStatus();
    respondOk(socket, helloAck);
    return;
  }

  if (isHeartbeatPayload(payload)) {
    if (!acceptedSockets.has(socket)) {
      respondError(socket, "pinvim peer not accepted; send hello first");
      return;
    }

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
    if (!acceptedSockets.has(socket)) {
      respondError(socket, "pinvim peer not accepted; send hello first");
      return;
    }

    const delivery: ExplicitDelivery =
      payload.delivery === "prompt" || payload.context.userInput?.trim()
        ? "prompt"
        : "attach";
    if (delivery === "attach") {
      attachPendingContext(payload);
      respondOk(socket, { delivery: "attach" });
    } else {
      deliverMessage(pi, formatExplicitContext(payload, "prompt"));
      respondOk(socket, { delivery: "prompt" });
    }
    return;
  }

  // @lat: [[pi-coding-agent#Runtime settings]]
  // dot-ks5d: fill_prompt (shade-next remote input) is ownership-neutral.
  // It must never run peerAllowedForSocket, add to acceptedSockets, claim or
  // reclaim the pair, or auto-submit. It only prefills the editor and may
  // focus the pane, leaving strict pair ownership untouched.
  if (isFillPromptPayload(payload)) {
    if (typeof payload.text !== "string") {
      respondError(socket, "fill_prompt text must be a string");
      return;
    }
    if (!latestCtx) {
      respondError(socket, "Pi UI context is not ready");
      return;
    }
    latestCtx.ui.setEditorText(payload.text);
    if (payload.focus !== false) focusOwnTmuxPane();
    respondOk(socket, {
      type: "fill_prompt",
      focused: payload.focus !== false,
    });
    return;
  }

  if (isPromptPayload(payload)) {
    if (!acceptedSockets.has(socket)) {
      respondError(socket, "pinvim peer not accepted; send hello first");
      return;
    }

    if (!payload.message?.trim()) {
      respondError(socket, "prompt message is empty");
      return;
    }
    deliverMessage(pi, payload.message);
    respondOk(socket);
    return;
  }

  if (
    hasType(payload) &&
    (payload.type === "editor_state" || payload.type === "editor_disconnect")
  ) {
    respondError(
      socket,
      "editor_state live context is unsupported; use explicit_send",
    );
    return;
  }

  if (isTelegramPayload(payload)) {
    latestCtx?.ui?.notify?.("Telegram message received", "info");
    deliverMessage(pi, `📱 **Telegram message:**\n${payload.text}`);
    respondOk(socket);
    return;
  }

  if (isTellPayload(payload)) {
    const fromLabel = payload.from || "unknown";
    persistAndSurfaceTell(pi, payload);
    deliverMessage(pi, payload.text);
    // Send async acknowledgement back to sender
    if (payload.fromSocket && payload.protocol === "pi.tell.v1") {
      void sendTellAck(payload.fromSocket, fromLabel, payload.id);
    }
    respondOk(socket, { id: payload.id, type: "tell_ack" });
    return;
  }

  if (isTellAckPayload(payload)) {
    const toLabel = payload.to || "unknown";
    latestCtx?.ui?.notify?.(`Tell acknowledged by ${toLabel}`, "info");
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
  if (!SOCKET_PATH || server || isNestedAttachOnly()) return;

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
    server.unref();
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
    ensureEditorServiceClient();
    if (!editorServiceTimer) {
      editorServiceTimer = setInterval(() => {
        ensureEditorServiceClient();
      }, 5000);
      editorServiceTimer.unref();
    }

    if (shouldAutoScanNvimPeers() && !peerScanTimer) {
      peerScanTimer = setInterval(() => {
        void refreshRepairCandidate();
      }, 2000);
      peerScanTimer.unref();
    }
    void refreshRepairCandidate();

    resolveSocketAsync(() => {
      if (isPinvimSocketEnabled()) startServer(pi, ctx);
    });
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus();
  });

  pi.on("input", (event) => {
    nextTurnIsUserOrigin = event.source !== "extension";
  });

  pi.on("before_agent_start", async () => {
    if (!nextTurnIsUserOrigin) return;
    nextTurnIsUserOrigin = false;
    ensureEditorServiceClient();
    const text = consumePendingContext() || (await fetchLiveEditorContext());
    if (!text) return;
    return {
      message: {
        customType: "pinvim-context",
        content: text,
        display: true,
      },
    };
  });

  pi.on("tool_result", async (event, ctx) => {
    const toolName = String(event.toolName || "").toLowerCase();
    if (!new Set(["edit", "write"]).has(toolName)) return;
    if (event.isError) return;

    const filePath = changedPathFromToolEvent(event, ctx.cwd);
    if (!filePath) return;

    const response = await editorServiceRequest("reload_buffer", {
      path: filePath,
      reason: `pi-tool:${toolName}`,
    });
    if (!response.ok) return;

    const summary = describeReloadBufferResult(
      toolName,
      filePath,
      (response.result || {}) as ReloadBufferResult,
    );
    if (!summary) return;

    if (ctx.hasUI) ctx.ui.notify(summary, "warn");
    return {
      content: [
        ...event.content,
        {
          type: "text" as const,
          text: `⚠️ ${summary}`,
        },
      ],
    };
  });

  pi.on("session_shutdown", () => {
    latestCtx = null;
    for (const timer of tellWidgetTimers.values()) {
      clearTimeout(timer);
    }
    tellWidgetTimers.clear();
    if (peerScanTimer) {
      clearInterval(peerScanTimer);
      peerScanTimer = null;
    }
    if (editorServiceTimer) {
      clearInterval(editorServiceTimer);
      editorServiceTimer = null;
    }
    editorServiceSocket?.destroy();
    editorServiceSocket = null;
    server?.close();
    server = null;

    if (!isNestedAttachOnly() && SOCKET_PATH && fs.existsSync(SOCKET_PATH)) {
      try {
        fs.unlinkSync(SOCKET_PATH);
      } catch {
        // Ignore cleanup failures.
      }
    }

    if (!isNestedAttachOnly()) cleanupInfoManifest();
    clearPendingContext();
  });

  pi.registerCommand("pinvim-info", {
    description:
      "Show pinvim state: peer metadata, socket, and transport inputs",
    handler: async (_args, ctx) => {
      ensureEditorServiceClient();
      const lines = renderInfoLines();
      emitCommandLines(ctx, lines, "info");
    },
  });

  pi.registerCommand("pinvim-health", {
    description: "Show pinvim link health: peer id and heartbeat age",
    handler: async (_args, ctx) => {
      ensureEditorServiceClient();
      const health = getHealth();
      const lines = [
        health.ok ? "pinvim health: ok" : "pinvim health: attention needed",
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Link mode: ${buildPinvimPeerIdentity().linkMode}`,
        `Relation: ${pinvimRelationState()}`,
        `Nested attach-only: ${isNestedAttachOnly() ? "yes" : "no"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Repair candidate: ${repairCandidate?.id || "(none)"}`,
        `Last repair: ${repairedAt ? new Date(repairedAt).toISOString() : "(none)"}`,
        `Pending context: ${pendingContext ? `${pendingContext.label}, expires ${new Date(pendingContext.expiresAt).toISOString()}` : "(none)"}`,
        `Editor service: ${editorService.address || "(none)"}`,
        `Editor service source: ${editorService.source}`,
        `Editor service fallback: ${editorServiceFallbackLine()}`,
        `Editor service state: ${editorServiceStateLine()}`,
        `Editor service error: ${editorService.lastError || "(none)"}`,
        `Socket: ${SOCKET_PATH || "(disabled)"}`,
      ];
      emitCommandLines(ctx, lines, health.ok ? "info" : "warn");
    },
  });

  pi.registerCommand("pinvim-status", {
    description: "Show concise pinvim peer status",
    handler: async (_args, ctx) => {
      ensureEditorServiceClient();
      const health = getHealth();
      const lines = [
        `pinvim status: ${formatStatus() || "(no active peer)"}`,
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Link mode: ${buildPinvimPeerIdentity().linkMode}`,
        `Relation: ${pinvimRelationState()}`,
        `Nested attach-only: ${isNestedAttachOnly() ? "yes" : "no"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Repair candidate: ${repairCandidate?.id || "(none)"}`,
        `Last repair: ${repairedAt ? new Date(repairedAt).toISOString() : "(none)"}`,
        `Pending context: ${pendingContext ? `${pendingContext.label}, expires ${new Date(pendingContext.expiresAt).toISOString()}` : "(none)"}`,
        `Editor service: ${editorService.address || "(none)"}`,
        `Editor service source: ${editorService.source}`,
        `Editor service fallback: ${editorServiceFallbackLine()}`,
        `Editor service state: ${editorServiceStateLine()}`,
        `Editor service error: ${editorService.lastError || "(none)"}`,
        `Socket: ${SOCKET_PATH || "(disabled)"}`,
      ];
      emitCommandLines(ctx, lines, "info");
    },
  });

  pi.registerCommand("pinvim-doctor", {
    description: "Diagnose pinvim peer and Nvim editor-service transports",
    handler: async (_args, ctx) => {
      ensureEditorServiceClient();
      await refreshRepairCandidate({ force: true });
      const editorStatus = await editorServiceRequest("status");
      const health = getHealth();
      const activePeer = getActivePeer();
      const piIdentity = buildPinvimPeerIdentity();
      const lines = [
        health.ok && !editorService.stale
          ? "pinvim doctor: ok"
          : "pinvim doctor: attention needed",
        `Pi identity: ${piIdentity.id}`,
        `Pi role: ${piIdentity.role || "(none)"}`,
        `Pi relation: ${pinvimRelationState()}`,
        `Pi link mode: ${piIdentity.linkMode}`,
        `Pi nested attach-only: ${isNestedAttachOnly() ? "yes" : "no"}`,
        `Pi parent id: ${piIdentity.parentId || "(none)"}`,
        `Pi workspace id: ${piIdentity.workspaceId || "(none)"}`,
        `Pi instance id: ${piIdentity.instanceId || "(none)"}`,
        `Pi registry root: ${piIdentity.registryRoot || "(none)"}`,
        `Pi tmux: ${PI_SESSION}/${PI_WINDOW}${PI_PANE ? "/" + PI_PANE : ""}`,
        `Pi ephemeral: ${isEphemeral()}`,
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Active peer role: ${activePeer?.role || "(none)"}`,
        `Active peer parent id: ${activePeer?.parentId || "(none)"}`,
        `Active peer workspace id: ${activePeer?.workspaceId || "(none)"}`,
        `Active peer instance id: ${activePeer?.instanceId || "(none)"}`,
        `Active peer registry root: ${activePeer?.registryRoot || "(none)"}`,
        `Active peer tmux: ${activePeer?.tmux?.session || "?"}/${activePeer?.tmux?.window || "?"}${activePeer?.tmux?.pane ? "/" + activePeer.tmux.pane : ""}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Repair candidate: ${repairCandidate?.id || "(none)"}`,
        skippedManifests.size === 0
          ? "Skipped manifests: (none)"
          : `Skipped manifests:\n${Array.from(skippedManifests.entries())
              .map(([k, v]) => `  - ${path.basename(k)}: ${v}`)
              .join("\n")}`,
        `Socket: ${SOCKET_PATH || "(disabled)"}`,
        `Editor service address: ${editorService.address || "(none)"}`,
        `Editor service source: ${editorService.source}`,
        `Editor service fallback: ${editorServiceFallbackLine()}`,
        `Editor service transport: ${editorService.transport}`,
        `Editor service connected: ${editorService.connected}`,
        `Editor service stale: ${editorService.stale}`,
        `Editor service last ok: ${editorService.lastOkAt ? new Date(editorService.lastOkAt).toISOString() : "(none)"}`,
        `Editor service last method: ${editorService.lastMethod || "(none)"}`,
        `Editor service error: ${editorService.lastError || "(none)"}`,
        `Editor API status: ${editorStatus.ok ? "ok" : editorStatus.error || "error"}`,
      ];
      if (!health.activePeerId) {
        lines.push(
          "hint: no active nvim peer; start pinvim from nvim or check PI_SOCKET",
        );
      }
      if (editorService.stale) {
        lines.push(
          "hint: editor service stale; pi will fall back to peer socket for context",
        );
      }
      if (
        activePeer?.parentId &&
        piIdentity.parentId &&
        activePeer.parentId !== piIdentity.parentId
      ) {
        lines.push(
          `hint: peer parent id mismatch (peer=${activePeer.parentId} pi=${piIdentity.parentId}); nested or misrouted session`,
        );
      }
      emitCommandLines(
        ctx,
        lines,
        health.ok && !editorService.stale ? "info" : "warn",
      );
    },
  });

  pi.registerCommand("pinvim-context", {
    description: "Fetch current Nvim buffer context through the editor service",
    handler: async (_args, ctx) => {
      const text = await fetchLiveEditorContext();
      if (!text) {
        emitCommandLines(
          ctx,
          [editorService.lastError || "No editor context available"],
          "warn",
        );
        return;
      }
      emitCommandLines(ctx, [text], "info");
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
