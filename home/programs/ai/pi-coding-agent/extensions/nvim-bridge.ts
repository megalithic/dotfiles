/**
 * Neovim Bridge Extension
 *
 * Creates a Unix socket that accepts JSON payloads from Neovim.
 * This allows sending code context (selection, diagnostics, hover info) to pi.
 *
 * Socket naming (when run via pinvim in tmux):
 *   Real socket: /tmp/pi-{session}_{window}_{pane}_{pid}.sock
 *   Session symlink: /tmp/pi-{session}.sock -> real socket
 *
 * Neovim connects to the session symlink, so all panes in a session share one bridge.
 * Falls back to /tmp/pi.sock when not in tmux.
 *
 * SOCKET CONTRACT (single source of truth):
 *   Session symlink pattern: /tmp/pi-{tmux_session_name}.sock
 *   This pattern is used by:
 *     - This extension (creates the symlink)
 *     - config/nvim/after/plugin/pi-bridge.lua (connects to it)
 *   If you change this pattern, update both files.
 *
 * Use `pinvim` instead of `pi` to enable this extension.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import fs from "node:fs";
import net from "node:net";

const SOCKET_PATH = process.env.PI_SOCKET || "/tmp/pi.sock";
const PI_SESSION = process.env.PI_SESSION;
const SESSION_SYMLINK = PI_SESSION ? `/tmp/pi-${PI_SESSION}.sock` : null;

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

const startServer = (pi: ExtensionAPI): void => {
  if (server) return;

  // Clean up stale socket
  if (fs.existsSync(SOCKET_PATH)) {
    try {
      fs.unlinkSync(SOCKET_PATH);
    } catch {
      // Ignore stale socket errors
    }
  }

  // Clean up stale session symlink (always try - existsSync returns false for broken symlinks)
  if (SESSION_SYMLINK) {
    try {
      fs.unlinkSync(SESSION_SYMLINK);
    } catch {
      // Ignore - symlink may not exist
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

          const ctx = latestCtx;
          if (ctx?.isIdle()) {
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

  // Create session symlink for nvim to discover
  // Nvim uses this path: /tmp/pi-{session}.sock
  if (SESSION_SYMLINK) {
    try {
      // Remove any stale symlink first (in case cleanup above missed it)
      try {
        fs.unlinkSync(SESSION_SYMLINK);
      } catch {
        // Ignore
      }
      fs.symlinkSync(SOCKET_PATH, SESSION_SYMLINK);
    } catch {
      // Symlink creation may fail if another instance raced us
    }
  }
};

export default function (pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;
    startServer(pi);

    if (ctx.hasUI) {
      const displayPath = SESSION_SYMLINK || SOCKET_PATH;
      ctx.ui.notify(`nvim bridge listening at ${displayPath}`, "info");
    }
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
  });

  pi.on("session_shutdown", () => {
    server?.close();
    server = null;

    // Clean up socket
    if (fs.existsSync(SOCKET_PATH)) {
      try {
        fs.unlinkSync(SOCKET_PATH);
      } catch {
        // Ignore cleanup failures
      }
    }

    // Clean up session symlink
    if (SESSION_SYMLINK && fs.existsSync(SESSION_SYMLINK)) {
      try {
        fs.unlinkSync(SESSION_SYMLINK);
      } catch {
        // Ignore cleanup failures
      }
    }
  });
}
