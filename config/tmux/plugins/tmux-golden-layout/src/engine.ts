/**
 * Event engine. Hooks only report "something happened in window @N"; every
 * decision is made from a fresh snapshot, and every change is committed only
 * if the window still matches that snapshot (see commit()).
 *
 * Per-window state lives in window options, so it dies with the window:
 *   @gl_applied  layout the plugin last applied or accepted
 *   @gl_paused   "1" after a manual resize or another tool's layout change
 *   @gl_ref      manual layout captured at pause, rescaled on outer resizes
 */

import { appendFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { DEFAULT_MINS, type Mins, computeGolden, scaleReference } from "./allocate";
import { type LayoutNode, parseLayout, samePaneSet, serializeLayout, shape } from "./layout";
import { type WindowState, commit, readState, socketPath, tmux } from "./tmux";

export const PAUSE_MESSAGE = "Auto resize paused for this window; prefix+= to resume";

// ── Debug log ──

let debugEnabled = false;

export function log(msg: string): void {
  if (!debugEnabled) return;
  try {
    const uid = typeof process.getuid === "function" ? process.getuid() : 0;
    const dir = join(tmpdir(), `tmux-gl-${uid}`, socketPath().replace(/[^a-zA-Z0-9._-]/g, "_"));
    mkdirSync(dir, { recursive: true });
    appendFileSync(join(dir, "log"), `${new Date().toISOString()} [${process.pid}] ${msg}\n`);
  } catch {
    // never let logging break the plugin
  }
}

// ── Helpers ──

function readMins(st: WindowState): Mins {
  const w = Number(st.config.minWidth);
  const h = Number(st.config.minHeight);
  return {
    width: Number.isSafeInteger(w) && w > 0 ? w : DEFAULT_MINS.width,
    height: Number.isSafeInteger(h) && h > 0 ? h : DEFAULT_MINS.height,
  };
}

function tryParse(layout: string): LayoutNode | null {
  try {
    return layout ? parseLayout(layout) : null;
  } catch {
    return null;
  }
}

/** tmux command that stores the window's current layout in a window option. */
const record = (st: WindowState, option: string): string =>
  `set-option -Fw -t ${st.windowId} ${option} '#{window_layout}'`;

// ── Settling ──

/** Apply golden resizing, or rescale the manual reference while paused. */
function settle(st: WindowState, current: LayoutNode, mins: Mins): void {
  let target: LayoutNode | null;
  if (st.paused) {
    const ref = tryParse(st.ref);
    if (!ref || !samePaneSet(ref, current)) {
      // Panes changed while paused: the new layout becomes the reference.
      commit(st, [record(st, "@gl_ref"), record(st, "@gl_applied")]);
      return;
    }
    target = scaleReference(ref, current, mins);
  } else {
    const focus = Number.parseInt(st.activePane.slice(1), 10);
    target = computeGolden(current, focus, current.width, current.height, mins);
  }
  if (!target) {
    // Floating pane focused, or minimum sizes cannot fit.
    log(`no layout for ${st.windowId} at ${current.width}x${current.height}; keeping current`);
    return;
  }
  const layout = serializeLayout(target);
  if (layout === st.layout) {
    if (st.applied !== st.layout) commit(st, [record(st, "@gl_applied")]);
    return;
  }
  if (layout.includes("'")) return; // cannot be single-quoted; tmux never emits it
  log(`apply ${st.windowId}: ${layout}`);
  commit(st, [`select-layout -t ${st.windowId} '${layout}'`, record(st, "@gl_applied")]);
}

/** Classify window-layout-changed against the layout the plugin last applied. */
function layoutChanged(st: WindowState, current: LayoutNode, mins: Mins): void {
  const applied = tryParse(st.applied);
  if (
    !applied ||
    !samePaneSet(current, applied) ||
    current.width !== applied.width ||
    current.height !== applied.height
  ) {
    settle(st, current, mins); // new window, panes added or removed, or outer resize
    return;
  }
  if (shape(current) === shape(applied)) return; // our own layout; only focus or floating panes changed
  if (!st.paused && shape(current, false) === shape(applied, false)) {
    settle(st, current, mins); // panes swapped places without resizing
    return;
  }
  // Same panes and size, but geometry we did not apply: a manual resize or
  // another tool's select-layout. Pause, or refine the paused reference.
  const commands = [record(st, "@gl_ref"), record(st, "@gl_applied")];
  if (!st.paused) {
    commands.push(`set-option -w -t ${st.windowId} @gl_paused 1`, `display-message '${PAUSE_MESSAGE}'`);
  }
  commit(st, commands);
}

// ── Entry points ──

export function handleEvent(hook: string, windowId: string): void {
  const st = readState(windowId);
  if (!st || st.config.enabled === "off" || st.config.enabled === "0") return;
  debugEnabled = st.config.debug === "on" || st.config.debug === "1";
  log(`${hook} ${windowId} active=${st.activePane} paused=${st.paused} zoomed=${st.zoomed} layout=${st.layout}`);
  if (st.zoomed) return; // window-unzoomed settles it later
  const current = parseLayout(st.layout);
  const mins = readMins(st);
  if (hook === "window-layout-changed") layoutChanged(st, current, mins);
  else settle(st, current, mins);
}

export function resumeWindow(windowId: string): void {
  tmux("set-option", "-wu", "-t", windowId, "@gl_paused", ";", "set-option", "-wu", "-t", windowId, "@gl_ref");
  handleEvent("resume", windowId);
}
