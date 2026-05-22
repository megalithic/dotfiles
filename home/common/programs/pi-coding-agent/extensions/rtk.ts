/**
 * rtk Command Rewrite Extension
 *
 * Intercepts bash tool calls and rewrites commands through rtk for token savings.
 * Falls back to the original command if rtk is unavailable or no rewrite applies.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashTool } from "@earendil-works/pi-coding-agent";
import { execSync } from "node:child_process";

export default function (pi: ExtensionAPI) {
  const cwd = process.cwd();

  const bashTool = createBashTool(cwd, {
    spawnHook: ({ command, cwd, env }) => {
      // Skip already-rtk-prefixed commands
      if (/^\s*rtk\s/.test(command)) {
        return { command, cwd, env };
      }

      try {
        const result = execSync(`rtk rewrite ${JSON.stringify(command)}`, {
          encoding: "utf-8",
          timeout: 5000,
          stdio: ["pipe", "pipe", "pipe"],
        }).trim();

        if (result && result !== command) {
          return { command: result, cwd, env };
        }
      } catch {
        // rtk not found, not installed, or exited 1 (no rewrite needed)
      }

      return { command, cwd, env };
    },
  });

  pi.registerTool({
    ...bashTool,
    execute: async (id, params, signal, onUpdate, _ctx) => {
      return bashTool.execute(id, params, signal, onUpdate);
    },
  });
}
