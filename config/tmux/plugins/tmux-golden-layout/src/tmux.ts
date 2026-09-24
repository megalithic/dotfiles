/**
 * Thin tmux IO layer. All server communication goes through here.
 *
 * The socket is resolved from GL_TMUX_SOCKET (set by the plugin entrypoint
 * and by tests) and falls back to the TMUX environment variable that tmux
 * sets for run-shell children, so the CLI always talks to the server that
 * fired the hook.
 */

import { execFileSync, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { closeSync, mkdirSync, openSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

function socketPath(): string {
  const explicit = process.env.GL_TMUX_SOCKET;
  if (explicit) return explicit;
  return process.env.TMUX?.split(",")[0] ?? "default";
}

function socketArgs(): string[] {
  const socket = socketPath();
  return socket === "default" ? [] : ["-S", socket];
}

/** Serialize state transitions for one window across asynchronous hook processes. */
export async function withWindowLock<T>(windowId: string, fn: () => T | Promise<T>): Promise<T> {
  const socketHash = createHash("sha256").update(socketPath()).digest("hex").slice(0, 16);
  const root = join(tmpdir(), `tmux-gl-${typeof process.getuid === "function" ? process.getuid() : 0}`, socketHash);
  mkdirSync(root, { recursive: true, mode: 0o700 });

  // Each call needs a separate open, including concurrent calls in this process.
  // Keep the inode: unlinking it would let new callers bypass existing waiters.
  // The kernel releases ownership on close or process exit, never on a TTL.
  const fd = openSync(join(root, `lock-${windowId.slice(1)}.flock`), "a", 0o600);
  try {
    await new Promise<void>((resolve, reject) => {
      // Descriptor mode keeps ownership on our open file after the helper exits.
      const child = spawn("/usr/bin/lockf", ["-s", "-t", "15", "0"], { stdio: [fd, "ignore", "ignore"] });
      child.once("error", reject);
      child.once("exit", (code, signal) => {
        if (code === 0) resolve();
        else reject(new Error(code === 75
          ? `timed out waiting for layout lock: ${windowId}`
          : `could not acquire layout lock: ${windowId} (${signal ?? code})`));
      });
    });
    return await fn();
  } finally {
    closeSync(fd);
  }
}

const TMUX_TIMEOUT_MS = 3000;

/** Run one tmux command, returning trimmed stdout. */
export function tmux(...args: string[]): string {
  return execFileSync("tmux", [...socketArgs(), ...args], {
    encoding: "utf8",
    timeout: TMUX_TIMEOUT_MS,
  }).trim();
}

/** Run several tmux commands in one server round-trip (`;`-separated). */
export function tmuxMulti(commands: string[][]): string {
  const args: string[] = [...socketArgs()];
  commands.forEach((cmd, i) => {
    if (i > 0) args.push(";");
    args.push(...cmd);
  });
  return execFileSync("tmux", args, { encoding: "utf8", timeout: TMUX_TIMEOUT_MS }).trim();
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

/** Tiled pane ids in tmux window order (floating panes are not layout cells). */
export function getPaneOrder(windowId: string): string[] {
  const out = tmux("list-panes", "-t", windowId, "-F", "#{pane_id}\u001f#{pane_floating_flag}");
  if (out === "") return [];
  return out
    .split("\n")
    .map((line) => line.split("\u001f"))
    .filter(([, floating]) => floating !== "1")
    .map(([pane]) => pane);
}

// ── Per-window plugin state (window-scoped @gl_* user options) ──
// Window options die with the window, so state cleanup is automatic, and the
// window id key is stable across renames and index moves.

interface HistoryEntry {
  option: string;
  value: string;
}

export interface WindowOpts {
  paused: boolean;
  /** immutable reference layout captured at manual pause */
  manualRef: string | null;
  /** base64 JSON declaration */
  decl: string | null;
  /** recent independently stored "ts:layout" entries; hook echoes match these */
  history: HistoryEntry[];
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

const HISTORY_PREFIX = "@gl_history_";
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
  const history: HistoryEntry[] = [];
  const legacy = (map.get(OPT_NAMES.history) ?? "").split("|").filter((e) => e.length > 0);
  history.push(...legacy.map((value) => ({ option: OPT_NAMES.history, value })));
  for (const [option, value] of map) {
    if (option.startsWith(HISTORY_PREFIX)) history.push({ option, value });
  }
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
  if (patch.lastApplied !== undefined) put(OPT_NAMES.lastApplied, patch.lastApplied);
  if (patch.zoomed !== undefined) put(OPT_NAMES.zoomed, patch.zoomed ? "1" : null);
  if (patch.pending !== undefined) put(OPT_NAMES.pending, patch.pending ? "1" : null);
  if (patch.busy !== undefined) put(OPT_NAMES.busy, patch.busy > 0 ? String(patch.busy) : null);
  if (cmds.length > 0) tmuxMulti(cmds);
}

/** Timestamps of history entries ("ts:layout"). */
function historyTimestamp(entry: string): number {
  return Number.parseInt(entry.slice(0, entry.indexOf(":")), 10) || 0;
}

function historyEntryFresh(entry: string, now: number): boolean {
  return now - historyTimestamp(entry) <= HISTORY_TTL_MS;
}

/** True when a layout string is one we applied recently. */
export function historyContains(opts: WindowOpts, layout: string): boolean {
  if (opts.lastApplied === layout) return true;
  const now = Date.now();
  return opts.history.some(
    ({ value }) => historyEntryFresh(value, now) && value.slice(value.indexOf(":") + 1) === layout,
  );
}

/**
 * Apply a layout: store this history entry under a layout-specific option,
 * record last-applied, and select it in one server round-trip. Independent
 * options keep concurrent applies from overwriting each other's echo guards.
 */
export function applyLayout(windowId: string, layout: string, opts: WindowOpts): void {
  const now = Date.now();
  const option = `${HISTORY_PREFIX}${createHash("sha256").update(layout).digest("hex").slice(0, 16)}`;
  const value = `${now}:${layout}`;
  const fresh = opts.history
    .filter((entry) => entry.option !== OPT_NAMES.history && historyEntryFresh(entry.value, now))
    .filter((entry) => entry.option !== option);
  const keep = [...fresh, { option, value }]
    .sort((a, b) => historyTimestamp(a.value) - historyTimestamp(b.value))
    .slice(-HISTORY_LIMIT);
  const keepOptions = new Set(keep.map((entry) => entry.option));
  const staleOptions = new Set(
    opts.history.map((entry) => entry.option).filter((name) => !keepOptions.has(name)),
  );
  const commands: string[][] = [...staleOptions].map((name) => [
    "set-option",
    "-w",
    "-u",
    "-t",
    windowId,
    name,
  ]);
  commands.push(
    ["set-option", "-w", "-t", windowId, option, value],
    ["set-option", "-w", "-t", windowId, OPT_NAMES.lastApplied, layout],
    ["select-layout", "-t", windowId, layout],
  );
  tmuxMulti(commands);
}

export function displayMessage(message: string): void {
  try {
    tmux("display-message", message);
  } catch {
    // no client attached; fine
  }
}
