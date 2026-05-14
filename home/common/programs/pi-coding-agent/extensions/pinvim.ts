/**
 * Pinvim Extension
 *
 * Primary pi-side nvim integration.
 * Owns editor/live-context state, peer metadata, and UI surfaces.
 * Transport stays outside this file.
 *
 * Current inputs:
 *   - pinvim_legacy:editor_state / pinvim_legacy:editor_disconnect
 *   - pinvim:hello / pinvim:hello_ack / pinvim:heartbeat
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

interface EditorState {
  file?: string;
  cursor?: { line: number; col: number };
  selection?: string;
  selectionRange?: [number, number];
  filetype?: string;
  modified?: boolean;
  buftype?: string;
  buftext?: string;
  [key: string]: unknown;
}

interface PinvimState {
  protocol: "pinvim.peer.v1";
  lastHello: HelloPayload | null;
  lastHelloAck: HelloAckPayload | null;
  lastHeartbeat: HeartbeatPayload | null;
  editorState: EditorState | null;
  lastEditorUpdateAt: number | null;
}

// =============================================================================
// State
// =============================================================================

const STALE_MS = 60 * 1000;

const state: PinvimState = {
  protocol: "pinvim.peer.v1",
  lastHello: null,
  lastHelloAck: null,
  lastHeartbeat: null,
  editorState: null,
  lastEditorUpdateAt: null,
};

let latestCtx: ExtensionContext | null = null;

// =============================================================================
// Formatting
// =============================================================================

const isEditorStateStale = (): boolean => {
  if (!state.lastEditorUpdateAt) return true;
  return Date.now() - state.lastEditorUpdateAt > STALE_MS;
};

const getActivePeer = (): PeerIdentity | null =>
  state.lastHelloAck?.peer || state.lastHello?.peer || null;

const formatLiveContext = (editor: EditorState): string => {
  const parts: string[] = ["[NEOVIM LIVE CONTEXT]"];

  if (editor.file) {
    parts.push(`Focused file: ${editor.file}`);
  }

  if (editor.filetype) {
    parts.push(`Filetype: ${editor.filetype}`);
  }

  if (editor.cursor) {
    parts.push(`Cursor: L${editor.cursor.line}:C${editor.cursor.col}`);
  }

  if (editor.selectionRange) {
    parts.push(`Selection: lines ${editor.selectionRange[0]}-${editor.selectionRange[1]}`);
  }

  if (editor.selection?.trim()) {
    parts.push("Selected text:");
    parts.push("```");
    parts.push(editor.selection);
    parts.push("```");
  }

  if (editor.file) {
    parts.push(`Reference: @${editor.file}`);
  }

  if (editor.modified) {
    parts.push("Buffer: modified (unsaved)");
  }

  if (editor.buftext?.trim()) {
    parts.push("Buffer contents:");
    parts.push("```");
    parts.push(editor.buftext);
    parts.push("```");
  }

  return parts.join("\n");
};

const formatEditorStatus = (editor: EditorState | null): string => {
  if (!editor || isEditorStateStale()) return "";

  const file = editor.file
    ? editor.file.split("/").pop() || editor.file
    : "???";

  if (editor.selectionRange) {
    const [start, stop] = editor.selectionRange;
    return `│ ${file}:${start}-${stop}`;
  }

  const line = editor.cursor ? `:${editor.cursor.line}` : "";
  return `│ ${file}${line}`;
};

const formatPeerStatus = (): string => {
  const peer = getActivePeer();
  if (!peer) return "";
  const label = peer.root || peer.cwd || peer.id;
  return `│ pinvim:${label.split("/").pop() || label}`;
};

const formatStatus = (): string =>
  formatEditorStatus(state.editorState) || formatPeerStatus();

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
  const editorState = state.editorState
    ? JSON.stringify(state.editorState, null, 2)
    : "(none yet)";
  const activePeer = getActivePeer();
  const lastEditorUpdate = state.lastEditorUpdateAt
    ? `${new Date(state.lastEditorUpdateAt).toISOString()}${isEditorStateStale() ? " (stale)" : ""}`
    : "never";

  return [
    "pinvim state",
    `Protocol: ${state.protocol}`,
    `Active peer: ${activePeer ? JSON.stringify(activePeer, null, 2) : "(none yet)"}`,
    `Last editor update: ${lastEditorUpdate}`,
    "Responsibilities:",
    "- primary pi-side nvim extension",
    "- own live context injection + footer status",
    "- track peer metadata independent from transport choice",
    "Current transport inputs:",
    "- bridge.ts legacy editor_state / editor_disconnect bus",
    "- future direct hello / hello_ack / heartbeat events",
    `Last hello: ${lastHello}`,
    `Last hello_ack: ${lastHelloAck}`,
    `Last heartbeat: ${lastHeartbeat}`,
    `Editor state: ${editorState}`,
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
  pi.events.on("pinvim_legacy:editor_state", (data: unknown) => {
    state.editorState = data as EditorState;
    state.lastEditorUpdateAt = Date.now();
    updateStatus();
  });

  pi.events.on("pinvim_legacy:editor_disconnect", () => {
    state.editorState = null;
    state.lastEditorUpdateAt = null;
    updateStatus();
  });

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

  pi.on("before_agent_start", async () => {
    if (!state.editorState || isEditorStateStale()) return;

    return {
      message: {
        customType: "pinvim-live-context",
        content: formatLiveContext(state.editorState),
        display: false,
      },
    };
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
    description: "Show pinvim state: peer metadata, live editor context, transport inputs",
    handler: async (_args, ctx) => {
      const lines = renderInfoLines();
      if (ctx.hasUI) {
        ctx.ui.notify(lines.join("\n"), "info");
      }
    },
  });
}
