#!/usr/bin/env bun
/**
 * tmux-golden-layout CLI.
 *
 * Hook events (fire-and-forget; never fail the tmux server):
 *   gl event <focus|layout|resized|manual|topology> <window-id> [pane-id]
 *
 * API (for Nvim, Pi, and other integrations; exits non-zero on error):
 *   gl declare <window-id> <declaration-json|->   set/replace a declaration
 *   gl grid <window-id> [pane-id...]              even-grid declaration
 *   gl clear <window-id>                          back to golden resizing
 *   gl apply <window-id>                          reapply current declaration/golden
 *   gl pause <window-id>                          pause automation (silent)
 *   gl resume <window-id>                         resume + reapply
 *   gl companion <companion-window> <source-window> <owner-pane>
 *   gl status <window-id>                         JSON debug state
 *
 * Declaration JSON:
 *   {"root":{"split":"h","ratios":[0.65,0.35],
 *            "children":[{"pane":"%1"},{"pane":"%2"}]}}
 */

import { gridDeclaration } from "./allocate";
import {
  type EventKind,
  applyWindow,
  clearWindow,
  declareWindow,
  handleEvent,
  log,
  pauseWindowApi,
  resumeWindow,
  setCompanion,
  statusWindow,
} from "./engine";
import { getPaneOrder } from "./tmux";

const EVENT_KINDS = new Set(["focus", "layout", "resized", "manual", "topology"]);

function usage(): never {
  process.stderr.write(
    "usage: gl event <kind> <window-id> [pane-id] | declare <win> <json|-> | grid <win> [panes...] |\n" +
      "       clear <win> | apply <win> | pause <win> | resume <win> |\n" +
      "       companion <companion-win> <source-win> <owner-pane> | status <win>\n",
  );
  process.exit(2);
}

function requireWindow(arg: string | undefined): string {
  if (!arg || !/^@\d+$/.test(arg)) {
    process.stderr.write(`expected a window id like @5, got: ${arg ?? "<missing>"}\n`);
    process.exit(2);
  }
  return arg;
}

async function main(): Promise<void> {
  const [cmd, ...rest] = process.argv.slice(2);
  switch (cmd) {
    case "event": {
      // Never propagate failures out of hook context.
      try {
        const kind = rest[0];
        const windowId = rest[1];
        if (!kind || !EVENT_KINDS.has(kind) || !windowId || !/^@\d+$/.test(windowId)) return;
        handleEvent(kind as EventKind, windowId);
      } catch (err) {
        log(`event error: ${err instanceof Error ? (err.stack ?? err.message) : String(err)}`);
      }
      return;
    }
    case "resume":
      resumeWindow(requireWindow(rest[0]));
      return;
    case "pause":
      pauseWindowApi(requireWindow(rest[0]));
      return;
    case "apply":
      applyWindow(requireWindow(rest[0]));
      return;
    case "clear":
      clearWindow(requireWindow(rest[0]));
      return;
    case "declare": {
      const windowId = requireWindow(rest[0]);
      let json = rest[1];
      if (!json) usage();
      if (json === "-") json = await new Response(Bun.stdin.stream()).text();
      declareWindow(windowId, json);
      return;
    }
    case "grid": {
      const windowId = requireWindow(rest[0]);
      const panes = rest.slice(1).length > 0 ? rest.slice(1) : getPaneOrder(windowId);
      if (panes.length === 0) throw new Error("no panes for grid declaration");
      declareWindow(windowId, JSON.stringify(gridDeclaration(panes)));
      return;
    }
    case "companion": {
      const companion = requireWindow(rest[0]);
      const source = requireWindow(rest[1]);
      const owner = rest[2];
      if (!owner || !/^%\d+$/.test(owner)) {
        process.stderr.write(`expected an owner pane id like %3, got: ${owner ?? "<missing>"}\n`);
        process.exit(2);
      }
      setCompanion(companion, source, owner);
      return;
    }
    case "status":
      process.stdout.write(`${statusWindow(requireWindow(rest[0]))}\n`);
      return;
    default:
      usage();
  }
}

main().catch((err) => {
  process.stderr.write(`${err instanceof Error ? err.message : String(err)}\n`);
  process.exit(1);
});
