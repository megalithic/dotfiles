/**
 * Pi Nvim Intelligence Extension
 *
 * Provides nvim-aware context injection into agent turns.
 * Receives editor state from bridge.ts via pi.events bus — no socket of its own.
 *
 * Flow:
 *   nvim → bridge.ts socket → pi.events('pinvim:editor_state') → this extension
 *
 * Context injection (before_agent_start):
 *   [NEOVIM LIVE CONTEXT]
 *   Focused file: init.lua
 *   Filetype: lua
 *   Cursor: L17:C4
 *   Selection: lines 5-12
 *   Reference: @config/nvim/after/plugin/pi.lua
 *
 * Footer status (self-prefixed with `│ ` so it visually separates
 * from preceding extension statuses, which pi joins with a single space):
 *   │ init.lua:179             (connected, no selection)
 *   │ init.lua:5-12            (connected, with selection)
 *   (empty)                     (no state / stale)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

// =============================================================================
// Types
// =============================================================================

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

// =============================================================================
// State
// =============================================================================

let editorState: EditorState | null = null;
let lastUpdateAt: number | null = null;
let latestCtx: ExtensionContext | null = null;

// Stale threshold — safety net if disconnect event missed (crash without socket close)
const STALE_MS = 60 * 1000;

// =============================================================================
// Formatting
// =============================================================================

const isStale = (): boolean => {
  if (!lastUpdateAt) return true;
  return Date.now() - lastUpdateAt > STALE_MS;
};

const formatContext = (state: EditorState): string => {
  const parts: string[] = ["[NEOVIM LIVE CONTEXT]"];

  if (state.file) {
    parts.push(`Focused file: ${state.file}`);
  }

  if (state.filetype) {
    parts.push(`Filetype: ${state.filetype}`);
  }

  if (state.cursor) {
    parts.push(`Cursor: L${state.cursor.line}:C${state.cursor.col}`);
  }

  if (state.selectionRange) {
    parts.push(`Selection: lines ${state.selectionRange[0]}-${state.selectionRange[1]}`);
  }

  if (state.selection?.trim()) {
    parts.push("Selected text:");
    parts.push("```");
    parts.push(state.selection);
    parts.push("```");
  }

  if (state.file) {
    parts.push(`Reference: @${state.file}`);
  }

  if (state.modified) {
    parts.push("Buffer: modified (unsaved)");
  }

  if (state.buftext?.trim()) {
    parts.push("Buffer contents:");
    parts.push("```");
    parts.push(state.buftext);
    parts.push("```");
  }

  return parts.join("\n");
};

const formatStatus = (state: EditorState | null): string => {
  if (!state || isStale()) return "";

  const file = state.file
    ? state.file.split("/").pop() || state.file
    : "???";

  // `│ ` prefix = section separator (pi joins extension statuses
  // with a single space). No per-field icons; line/range appended
  // to the filename with a `:` separator.
  if (state.selectionRange) {
    const [s, e] = state.selectionRange;
    return `│ ${file}:${s}-${e}`;
  }

  const line = state.cursor ? `:${state.cursor.line}` : "";
  return `│ ${file}${line}`;
};

// =============================================================================
// Status Update
// =============================================================================

const updateStatus = (): void => {
  const ctx = latestCtx;
  if (!ctx?.hasUI) return;
  ctx.ui.setStatus("pinvim", formatStatus(editorState));
};

// =============================================================================
// Extension Entry Point
// =============================================================================

export default function (pi: ExtensionAPI): void {
  // Listen for editor state from bridge.ts
  pi.events.on("pinvim:editor_state", (data: unknown) => {
    editorState = data as EditorState;
    lastUpdateAt = Date.now();
    updateStatus();
  });

  // Listen for editor disconnect (normal exit or socket close)
  pi.events.on("pinvim:editor_disconnect", () => {
    editorState = null;
    lastUpdateAt = null;
    updateStatus();
  });

  // Inject context before each agent turn
  pi.on("before_agent_start", async () => {
    if (!editorState || isStale()) return;

    const content = formatContext(editorState);
    return {
      message: {
        customType: "pinvim-live-context",
        content,
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

  // Register /pinvim-info command
  pi.registerCommand("pinvim-info", {
    description: "Show pinvim status: socket path, editor state, last update",
    handler: async (_args, ctx) => {
      const socketPath = process.env.PI_SOCKET || "(not set)";
      const stale = isStale();
      const lastUpdate = lastUpdateAt
        ? `${new Date(lastUpdateAt).toISOString()}${stale ? " (stale)" : ""}`
        : "never";

      const lines = [
        `Socket: ${socketPath}`,
        `Last update: ${lastUpdate}`,
        `State: ${editorState ? JSON.stringify(editorState, null, 2) : "(none)"}`,
      ];

      if (ctx.hasUI) {
        ctx.ui.notify(lines.join("\n"), "info");
      }
    },
  });
}
