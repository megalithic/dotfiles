/**
 * Neovim Bridge Extension
 *
 * Creates a Unix socket that accepts JSON payloads from Neovim.
 * This allows sending code context (selection, diagnostics, hover info) to pi.
 *
 * Socket naming (when run via pinvim in tmux):
 *   /tmp/pi-{session}-{window}.sock
 *
 * Falls back to /tmp/pi.sock when not in tmux.
 *
 * SOCKET CONTRACT (single source of truth):
 *   Pattern: /tmp/pi-{session}-{window}.sock
 *   Used by:
 *     - pinvim wrapper (sets PI_SOCKET env var)
 *     - This extension (listens on PI_SOCKET)
 *     - config/nvim/after/plugin/pi-bridge.lua (connects to it)
 *     - bin/ftm (checks for socket existence)
 *   If you change this pattern, update all files.
 *
 * Status icons (shown in footer before cwd):
 *   󰢩 (green) - nvim bridge active (pinvim)
 *   󰢩 (dim)   - nvim bridge inactive (regular pi)
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import fs from "node:fs";
import net from "node:net";

// Only start server if PI_SOCKET is set (i.e., invoked via pinvim)
const SOCKET_PATH = process.env.PI_SOCKET;
const IS_PINVIM = !!SOCKET_PATH;

// Nerd font icons
const NVIM_ICON = "󰢩"; // neovim icon

type Payload = {
  file?: string;
  range?: [number, number];
  selection?: string;
  lsp?: {
    diagnostics?: string[];
    hover?: string;
  };
  task?: string;
};

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;

const formatMessage = (payload: Payload): string => {
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
          const message = formatMessage(payload);
          if (!message) continue;

          const currentCtx = latestCtx;
          if (currentCtx?.isIdle()) {
            void pi.sendUserMessage(message);
          } else {
            void pi.sendUserMessage(message, { deliverAs: "followUp" });
          }
        } catch {
          // Ignore malformed payloads
        }
      }
    });
  });

  server.listen(SOCKET_PATH);

  // Update status to connected
  if (ctx.hasUI) {
    ctx.ui.setStatus("nvim", ctx.ui.theme.fg("success", NVIM_ICON));
  }
};

const updateStatus = (ctx: ExtensionContext): void => {
  if (!ctx.hasUI) return;

  if (IS_PINVIM && server) {
    // Connected - green icon
    ctx.ui.setStatus("nvim", ctx.ui.theme.fg("success", NVIM_ICON));
  } else {
    // Not connected - dim icon
    ctx.ui.setStatus("nvim", ctx.ui.theme.fg("muted", NVIM_ICON));
  }
};

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;

    // Show initial status
    updateStatus(ctx);

    // Start server if this is pinvim
    if (IS_PINVIM) {
      startServer(pi, ctx);

      if (ctx.hasUI) {
        ctx.ui.notify(`nvim bridge listening at ${SOCKET_PATH}`, "info");
      }
    }
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
    updateStatus(ctx);
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
  });
}
