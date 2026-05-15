/**
 * Pinvim Extension
 *
 * Primary pi-side nvim integration.
 * Owns editor/live-context state, peer metadata, and UI surfaces.
 * Transport stays outside this file.
 *
 * Safety: automatic live context injection is opt-in via PINVIM_LIVE_CONTEXT=1.
 * Default path is explicit nvim send (`gps` / :PinvimSend) to avoid spurious
 * nvim→pi messages.
 *
 * Current inputs:
 *   - pinvim:editor_state / pinvim:editor_disconnect / pinvim:prompt / pinvim:explicit_send
 *   - pinvim:hello / pinvim:hello_ack / pinvim:heartbeat
 *   - pinvim_legacy:* compatibility events during rollout
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

// =============================================================================
// Protocol Types
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
    cwd?: string;
    root?: string;
    modified?: boolean;
    [key: string]: unknown;
  };
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

interface PinvimHealth {
  ok: boolean;
  activePeerId: string | null;
  heartbeatAgeSeconds: number | null;
  editorStateFresh: boolean;
}

// =============================================================================
// State
// =============================================================================

const STALE_MS = 60 * 1000;
const LIVE_CONTEXT_ENABLED = process.env.PINVIM_LIVE_CONTEXT === "1";

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

const formatExplicitContext = (payload: ExplicitSendPayload): string => {
  const { context } = payload;
  const parts: string[] = ["[NEOVIM EXPLICIT CONTEXT]"];

  if (context.kind) {
    parts.push(`Kind: ${context.kind}`);
  }

  if (context.file) {
    parts.push(`Focused file: ${context.file}`);
  }

  if (context.filetype) {
    parts.push(`Filetype: ${context.filetype}`);
  }

  if (context.cursor) {
    parts.push(`Cursor: L${context.cursor.line}:C${context.cursor.col}`);
  }

  if (context.selectionRange) {
    parts.push(`Range: lines ${context.selectionRange[0]}-${context.selectionRange[1]}`);
  }

  if (context.word) {
    parts.push(`Word: ${context.word}`);
  }

  if (context.selection?.trim()) {
    parts.push(context.kind === "selection" ? "Selected text:" : "Cursor context:");
    parts.push(`\`\`\`${context.filetype || ""}`);
    parts.push(context.selection);
    parts.push("```");
  }

  if (context.modified) {
    parts.push("Buffer: modified (unsaved)");
  }

  parts.push("User explicitly sent this context from Neovim.");
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

const getHealth = (): PinvimHealth => {
  const activePeer = getActivePeer();
  const heartbeatAgeSeconds = state.lastHeartbeat?.sentAt
    ? Math.max(Math.floor(Date.now() / 1000) - state.lastHeartbeat.sentAt, 0)
    : null;
  const editorStateFresh = !!state.editorState && !isEditorStateStale();

  return {
    ok: !!activePeer && (heartbeatAgeSeconds === null || heartbeatAgeSeconds < 120),
    activePeerId: activePeer?.id || null,
    heartbeatAgeSeconds,
    editorStateFresh,
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
    "- own peer metadata + footer status",
    "- live context injection only when explicitly enabled",
    "- track peer metadata independent from transport choice",
    "Live context safety:",
    `- automatic injection enabled: ${LIVE_CONTEXT_ENABLED ? "yes" : "no"}`,
    "- default nvim path: explicit gps / :PinvimSend -> explicit_send",
    "- nvim opt-in gate: PINVIM_LIVE_CONTEXT=1 or setup opts",
    "- nvim debounce: 150ms default",
    "- nvim filters: file-backed buffers only; buftype must be empty",
    "- nvim size limits: selection 8000 bytes; buffer text 16000 bytes and off by default",
    "- pi freshness: editor state older than 60s is stale and not injected",
    "- pi delivery: explicit sends become user messages; active sessions receive followUp",
    "Current transport inputs:",
    "- bridge.ts shim forwards pinvim editor_state / disconnect / prompt during rollout",
    "- hello / hello_ack / heartbeat peer metadata events",
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

const setEditorState = (editorState: EditorState): void => {
  state.editorState = editorState;
  state.lastEditorUpdateAt = Date.now();
  updateStatus();
};

const clearEditorState = (): void => {
  state.editorState = null;
  state.lastEditorUpdateAt = null;
  updateStatus();
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

const deliverPrompt = (pi: ExtensionAPI, payload: PromptPayload): void => {
  if (!payload.message?.trim()) return;
  deliverMessage(pi, payload.message);
};

const deliverExplicitSend = (
  pi: ExtensionAPI,
  payload: ExplicitSendPayload,
): void => {
  deliverMessage(pi, formatExplicitContext(payload));
};

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI): void {
  pi.events.on("pinvim:editor_state", (data: unknown) => {
    setEditorState(data as EditorState);
  });

  pi.events.on("pinvim_legacy:editor_state", (data: unknown) => {
    setEditorState(data as EditorState);
  });

  pi.events.on("pinvim:editor_disconnect", () => {
    clearEditorState();
  });

  pi.events.on("pinvim_legacy:editor_disconnect", () => {
    clearEditorState();
  });

  pi.events.on("pinvim:prompt", (data: unknown) => {
    deliverPrompt(pi, data as PromptPayload);
  });

  pi.events.on("pinvim:explicit_send", (data: unknown) => {
    deliverExplicitSend(pi, data as ExplicitSendPayload);
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
    if (!LIVE_CONTEXT_ENABLED) return;
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

  pi.registerCommand("pinvim-health", {
    description: "Show pinvim link health: peer id, heartbeat age, editor freshness",
    handler: async (_args, ctx) => {
      const health = getHealth();
      const lines = [
        health.ok ? "pinvim health: ok" : "pinvim health: attention needed",
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Editor state fresh: ${health.editorStateFresh ? "yes" : "no"}`,
        `Automatic live context: ${LIVE_CONTEXT_ENABLED ? "enabled" : "disabled"}`,
      ];
      if (ctx.hasUI) {
        ctx.ui.notify(lines.join("\n"), health.ok ? "info" : "warn");
      }
    },
  });

  pi.registerCommand("pinvim-status", {
    description: "Show concise pinvim peer/editor status",
    handler: async (_args, ctx) => {
      const health = getHealth();
      const lines = [
        `pinvim status: ${formatStatus() || "(no active editor)"}`,
        `Active peer: ${health.activePeerId || "(none)"}`,
        `Heartbeat age: ${health.heartbeatAgeSeconds == null ? "(none)" : `${health.heartbeatAgeSeconds}s`}`,
        `Automatic live context: ${LIVE_CONTEXT_ENABLED ? "enabled" : "disabled"}`,
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
