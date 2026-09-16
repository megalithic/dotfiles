/**
 * Thin tmux IO layer. All server communication goes through here.
 *
 * The socket is resolved from GL_TMUX_SOCKET (set by the plugin entrypoint
 * and by tests) and falls back to the TMUX environment variable that tmux
 * sets for run-shell children, so the CLI always talks to the server that
 * fired the hook.
 */

import { execFileSync } from "node:child_process";

function socketArgs(): string[] {
  const explicit = process.env.GL_TMUX_SOCKET;
  if (explicit) return ["-S", explicit];
  const tmuxEnv = process.env.TMUX;
  if (tmuxEnv) {
    const sock = tmuxEnv.split(",")[0];
    if (sock) return ["-S", sock];
  }
  return [];
}

/** Run one tmux command, returning trimmed stdout. */
export function tmux(...args: string[]): string {
  return execFileSync("tmux", [...socketArgs(), ...args], { encoding: "utf8" }).trim();
}

/** Run several tmux commands in one server round-trip (`;`-separated). */
export function tmuxMulti(commands: string[][]): string {
  const args: string[] = [...socketArgs()];
  commands.forEach((cmd, i) => {
    if (i > 0) args.push(";");
    args.push(...cmd);
  });
  return execFileSync("tmux", args, { encoding: "utf8" }).trim();
}

export interface WindowState {
  windowId: string;
  width: number;
  height: number;
  zoomed: boolean;
  activePane: string;
  layout: string;
}

const STATE_FORMAT =
  "#{window_id}\u001f#{window_width}\u001f#{window_height}\u001f#{window_zoomed_flag}\u001f#{pane_id}\u001f#{window_layout}";

/** Snapshot one window's live state, or null when the window is gone. */
export function getWindowState(windowId: string): WindowState | null {
  let out: string;
  try {
    out = tmux("display-message", "-p", "-t", windowId, STATE_FORMAT);
  } catch {
    return null;
  }
  const [id, w, h, z, pane, layout] = out.split("\u001f");
  if (!id || !layout) return null;
  return {
    windowId: id,
    width: Number.parseInt(w, 10),
    height: Number.parseInt(h, 10),
    zoomed: z === "1",
    activePane: pane,
    layout,
  };
}

/** Window pane ids in tmux window order. */
export function getPaneOrder(windowId: string): string[] {
  const out = tmux("list-panes", "-t", windowId, "-F", "#{pane_id}");
  return out === "" ? [] : out.split("\n");
}

// ── Per-window plugin state (window-scoped @gl_* user options) ──
// Window options die with the window, so state cleanup is automatic, and the
// window id key is stable across renames and index moves.

export interface WindowOpts {
  paused: boolean;
  /** immutable reference layout captured at manual pause */
  manualRef: string | null;
  /** base64 JSON declaration */
  decl: string | null;
  /** recent "ts:layout" entries we applied; hook echoes match against this */
  history: string[];
  /** last layout string this plugin applied */
  lastApplied: string | null;
  /** last observed zoom flag */
  zoomed: boolean;
  /** apply deferred while zoomed */
  pending: boolean;
  /** ms timestamp while a multi-step apply (pane reorder) is in flight */
  busy: number;
}

const OPT_NAMES = {
  paused: "@gl_paused",
  manualRef: "@gl_manual_ref",
  decl: "@gl_decl",
  history: "@gl_history",
  lastApplied: "@gl_last_applied",
  zoomed: "@gl_zoomed",
  pending: "@gl_pending",
  busy: "@gl_busy",
} as const;

const HISTORY_LIMIT = 6;
const HISTORY_TTL_MS = 5000;

export function getWindowOpts(windowId: string): WindowOpts {
  let out = "";
  try {
    out = tmux("show-options", "-w", "-t", windowId);
  } catch {
    // window gone or no options; fall through to defaults
  }
  const map = new Map<string, string>();
  for (const line of out.split("\n")) {
    const m = /^(@gl_\S+)(?: (.*))?$/.exec(line);
    if (!m) continue;
    let v = m[2] ?? "";
    if (v.startsWith('"') && v.endsWith('"')) v = v.slice(1, -1);
    map.set(m[1], v);
  }
  const history = (map.get(OPT_NAMES.history) ?? "").split("|").filter((e) => e.length > 0);
  return {
    paused: map.get(OPT_NAMES.paused) === "1",
    manualRef: map.get(OPT_NAMES.manualRef) ?? null,
    decl: map.get(OPT_NAMES.decl) ?? null,
    history,
    lastApplied: map.get(OPT_NAMES.lastApplied) ?? null,
    zoomed: map.get(OPT_NAMES.zoomed) === "1",
    pending: map.get(OPT_NAMES.pending) === "1",
    busy: Number.parseInt(map.get(OPT_NAMES.busy) ?? "0", 10) || 0,
  };
}

export type OptPatch = Partial<{
  paused: boolean;
  manualRef: string | null;
  decl: string | null;
  history: string[] | null;
  lastApplied: string | null;
  zoomed: boolean;
  pending: boolean;
  busy: number;
}>;

/** Batch-write window state options in one tmux invocation. */
export function setWindowOpts(windowId: string, patch: OptPatch): void {
  const cmds: string[][] = [];
  const put = (name: string, value: string | null): void => {
    if (value === null) cmds.push(["set-option", "-w", "-u", "-t", windowId, name]);
    else cmds.push(["set-option", "-w", "-t", windowId, name, value]);
  };
  if (patch.paused !== undefined) put(OPT_NAMES.paused, patch.paused ? "1" : null);
  if (patch.manualRef !== undefined) put(OPT_NAMES.manualRef, patch.manualRef);
  if (patch.decl !== undefined) put(OPT_NAMES.decl, patch.decl);
  if (patch.history !== undefined)
    put(OPT_NAMES.history, patch.history && patch.history.length > 0 ? patch.history.join("|") : null);
  if (patch.lastApplied !== undefined) put(OPT_NAMES.lastApplied, patch.lastApplied);
  if (patch.zoomed !== undefined) put(OPT_NAMES.zoomed, patch.zoomed ? "1" : null);
  if (patch.pending !== undefined) put(OPT_NAMES.pending, patch.pending ? "1" : null);
  if (patch.busy !== undefined) put(OPT_NAMES.busy, patch.busy > 0 ? String(patch.busy) : null);
  if (cmds.length > 0) tmuxMulti(cmds);
}

/** Timestamps of history entries ("ts:layout"). */
function historyEntryFresh(entry: string, now: number): boolean {
  const ts = Number.parseInt(entry.slice(0, entry.indexOf(":")), 10) || 0;
  return now - ts <= HISTORY_TTL_MS;
}

/** True when a layout string is one we applied recently. */
export function historyContains(opts: WindowOpts, layout: string): boolean {
  if (opts.lastApplied === layout) return true;
  const now = Date.now();
  return opts.history.some((e) => historyEntryFresh(e, now) && e.slice(e.indexOf(":") + 1) === layout);
}

/**
 * Apply a layout: push it onto the applied-history, record last-applied, and
 * select it in one server round-trip so hook echoes can be recognized even
 * when several of our applies race.
 */
export function applyLayout(windowId: string, layout: string, opts: WindowOpts): void {
  const now = Date.now();
  const history = [...opts.history.filter((e) => historyEntryFresh(e, now)), `${now}:${layout}`].slice(
    -HISTORY_LIMIT,
  );
  tmuxMulti([
    ["set-option", "-w", "-t", windowId, "@gl_history", history.join("|")],
    ["set-option", "-w", "-t", windowId, "@gl_last_applied", layout],
    ["select-layout", "-t", windowId, layout],
  ]);
}

export function displayMessage(message: string): void {
  try {
    tmux("display-message", message);
  } catch {
    // no client attached; fine
  }
}
