/**
 * Pinvim Extension
 *
 * Peer-state entrypoint for nvim↔pi handshake work.
 * Keep this file thin, transport-agnostic, and focused on typed handshake state.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

// =============================================================================
// Protocol Types
// =============================================================================

type LinkMode = "auto" | "explicit" | "bootstrap";

interface PeerIdentity {
  id: string;
  kind: "nvim" | "pi";
  cwd: string;
  root?: string;
  tmux?: {
    session?: string;
    window?: string;
  };
  linkMode: LinkMode;
  heartbeatAt?: number;
}

interface HelloPayload {
  type: "hello";
  protocol: "pinvim.peer.v1";
  peer: PeerIdentity;
  capabilities?: {
    liveContext?: boolean;
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

interface PinvimState {
  protocol: "pinvim.peer.v1";
  lastHello: HelloPayload | null;
  lastHelloAck: HelloAckPayload | null;
  lastHeartbeat: HeartbeatPayload | null;
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

// =============================================================================
// Formatting
// =============================================================================

const formatStatus = (): string => {
  if (!state.lastHelloAck) return "";
  const peer = state.lastHelloAck.peer;
  const label = peer.root || peer.cwd || peer.id;
  return `│ pinvim:${label.split("/").pop() || label}`;
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

  return [
    "pinvim peer state",
    `Protocol: ${state.protocol}`,
    "Responsibilities:",
    "- track hello / hello_ack peer metadata",
    "- surface active peer status in the UI",
    "- stay transport-agnostic; socket IO belongs outside this extension",
    "Target handshake:",
    "- peer id + cwd/root + tmux identity + link mode",
    "- heartbeat timestamps for freshness",
    `Last hello: ${lastHello}`,
    `Last hello_ack: ${lastHelloAck}`,
    `Last heartbeat: ${lastHeartbeat}`,
  ];
};

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

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI): void {
  pi.events.on("pinvim:hello", (data: unknown) => {
    state.lastHello = data as HelloPayload;
    updateStatus();
  });

  pi.events.on("pinvim:hello_ack", (data: unknown) => {
    state.lastHelloAck = data as HelloAckPayload;
    updateStatus();
  });

  pi.events.on("pinvim:heartbeat", (data: unknown) => {
    state.lastHeartbeat = data as HeartbeatPayload;
    updateStatus();
  });

  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus();
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus();
  });

  pi.on("session_shutdown", () => {
    latestCtx = null;
  });

  pi.registerCommand("pinvim-info", {
    description: "Show pinvim peer handshake state",
    handler: async (_args, ctx) => {
      const lines = renderInfoLines();
      if (ctx.hasUI) {
        ctx.ui.notify(lines.join("\n"), "info");
      }
    },
  });
}
