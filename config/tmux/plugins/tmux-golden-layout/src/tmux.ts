/**
 * Thin tmux IO layer. All server communication goes through here.
 *
 * The socket is resolved from GL_TMUX_SOCKET (set by the plugin entrypoint
 * and by tests) and falls back to the TMUX environment variable that tmux
 * sets for run-shell children, so the CLI always talks to the server that
 * fired the hook.
 */

import { execFileSync } from "node:child_process";

export function socketPath(): string {
  return process.env.GL_TMUX_SOCKET || (process.env.TMUX?.split(",")[0] ?? "default");
}

const TMUX_TIMEOUT_MS = 3000;

/** Run tmux commands in one server round-trip (separate commands with ";"). */
export function tmux(...args: string[]): string {
  const socket = socketPath();
  const socketArgs = socket === "default" ? [] : ["-S", socket];
  return execFileSync("tmux", [...socketArgs, ...args], { encoding: "utf8", timeout: TMUX_TIMEOUT_MS }).trim();
}

// Everything commit() relies on staying the same between snapshot and apply.
// The layout covers geometry, focus, and last-pane order.
const GUARD = "#{window_zoomed_flag}#{@gl_paused}#{window_layout}";

export interface WindowState {
  windowId: string;
  zoomed: boolean;
  activePane: string;
  paused: boolean;
  /** manual reference layout captured at pause */
  ref: string;
  /** layout the plugin last applied or accepted */
  applied: string;
  layout: string;
  /** GUARD as expanded for this snapshot */
  guard: string;
  config: { enabled: string; minWidth: string; minHeight: string; debug: string };
}

const STATE_FORMAT = [
  GUARD,
  "#{window_id}",
  "#{window_zoomed_flag}",
  "#{pane_id}",
  "#{@gl_paused}",
  "#{@gl_ref}",
  "#{@gl_applied}",
  "#{window_layout}",
  "#{@gl-enabled}",
  "#{@gl-min-width}",
  "#{@gl-min-height}",
  "#{@gl-debug}",
].join("\u001f");

/** Snapshot one window (and the plugin options) in a single round-trip, or null when it is gone. */
export function readState(windowId: string): WindowState | null {
  let out: string;
  try {
    out = tmux("display-message", "-p", "-t", windowId, STATE_FORMAT);
  } catch {
    return null;
  }
  const [guard, id, zoomed, pane, paused, ref, applied, layout, enabled, minWidth, minHeight, debug] =
    out.split("\u001f");
  if (id !== windowId || !layout) return null;
  return {
    windowId,
    zoomed: zoomed === "1",
    activePane: pane,
    paused: paused === "1",
    ref,
    applied,
    layout,
    guard,
    config: { enabled, minWidth, minHeight, debug },
  };
}

/**
 * Run tmux command strings only if the window still matches `state`. tmux
 * runs the check and the commands back to back in one command queue, so no
 * other client can change the window in between; stale work is dropped and
 * the hook for whatever changed the window settles it instead.
 */
export function commit(state: WindowState, commands: string[]): void {
  const w = state.windowId;
  tmux(
    "set-option", "-w", "-t", w, "@gl_expect", state.guard, ";",
    "if-shell", "-F", "-t", w, `#{==:${GUARD},#{@gl_expect}}`, commands.join(" ; "), ";",
    "set-option", "-wu", "-t", w, "@gl_expect",
  );
}
