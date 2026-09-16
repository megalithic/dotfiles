/**
 * Event engine: classifies tmux hook events per window and decides between
 * golden resizing, declaration rendering, reference scaling, manual pause,
 * and ignoring our own layout echoes.
 *
 * State precedence per window:
 *   1. manual pause  -> scale the immutable manual reference on outer resize
 *   2. declaration   -> re-render exact declared ratios
 *   3. golden        -> exact 1/phi for the focused pane
 */

import { appendFileSync, mkdirSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import {
  DEFAULT_MINS,
  type Declaration,
  type Mins,
  computeGolden,
  declPanes,
  renderDeclaration,
  scaleReference,
  validateDeclaration,
} from "./allocate";
import { parseLayout, samePaneSet, serializeLayout } from "./layout";
import {
  type WindowOpts,
  type WindowState,
  applyLayout,
  displayMessage,
  getPaneOrder,
  getWindowOpts,
  getWindowState,
  historyContains,
  setWindowOpts,
  tmux,
} from "./tmux";

export const PAUSE_MESSAGE = "Auto resize paused for this window; prefix+= to resume";

const BUSY_TTL_MS = 1500;

export type EventKind = "focus" | "layout" | "resized" | "manual" | "topology";

// ── Runtime files (debug log) ──

function runtimeDir(): string {
  const sock = process.env.GL_TMUX_SOCKET ?? process.env.TMUX?.split(",")[0] ?? "default";
  const key = sock.replace(/[^a-zA-Z0-9._-]/g, "_");
  const uid = typeof process.getuid === "function" ? process.getuid() : 0;
  const dir = join(tmpdir(), `tmux-gl-${uid}`, key);
  mkdirSync(dir, { recursive: true });
  return dir;
}

let debugEnabled = false;

export function log(msg: string): void {
  if (!debugEnabled) return;
  try {
    appendFileSync(join(runtimeDir(), "log"), `${new Date().toISOString()} [${process.pid}] ${msg}\n`);
  } catch {
    // never let logging break the plugin
  }
}

/**
 * Apply `target` only if the window still looks exactly like the state the
 * computation was based on. Hook processes are serialized per window, but an
 * event can still become stale while waiting for the lock; stale work aborts.
 * `checkActivePane` is used for focus-dependent
 * (golden) layouts; declarations and reference scaling ignore focus.
 */
function applyVerified(
  st: WindowState,
  target: string,
  opts: WindowOpts,
  checkActivePane: boolean,
): WindowState | null {
  const before = getWindowState(st.windowId);
  if (
    !before ||
    before.zoomed ||
    before.layout !== st.layout ||
    before.width !== st.width ||
    before.height !== st.height ||
    (checkActivePane && before.activePane !== st.activePane)
  ) {
    log(`state changed under ${st.windowId}; skipping apply`);
    return null;
  }
  log(`apply ${st.windowId}: ${target}`);
  applyLayout(st.windowId, target, opts);

  // Verification and apply are separate tmux round-trips. If focus or outer
  // dimensions changed in that gap, the corresponding hook may have already
  // inspected the old layout and aborted. Return the new state so the caller
  // can settle it once more instead of leaving a stale last writer in place.
  const after = getWindowState(st.windowId);
  if (!after) return null;
  if (after.zoomed) {
    setWindowOpts(st.windowId, { zoomed: true, pending: true });
    return null;
  }
  if (
    after.width !== st.width ||
    after.height !== st.height ||
    (checkActivePane && after.activePane !== st.activePane)
  ) {
    return after;
  }
  return null;
}

// ── Helpers ──

interface Config {
  enabled: boolean;
  mins: Mins;
}

function readConfig(): Config {
  // One expansion round-trip for all global knobs.
  let out = "";
  try {
    out = tmux("display-message", "-p", "#{@gl-enabled}\u001f#{@gl-min-width}\u001f#{@gl-min-height}\u001f#{@gl-debug}");
  } catch {
    // server unreachable; caller handles
  }
  const [enabled, minW, minH, debug] = out.split("\u001f");
  const parsedMinW = Number(minW);
  const parsedMinH = Number(minH);
  debugEnabled = debug === "on" || debug === "1";
  return {
    enabled: enabled !== "off" && enabled !== "0",
    mins: {
      width: Number.isSafeInteger(parsedMinW) && parsedMinW > 0 ? parsedMinW : DEFAULT_MINS.width,
      height: Number.isSafeInteger(parsedMinH) && parsedMinH > 0 ? parsedMinH : DEFAULT_MINS.height,
    },
  };
}

function decodeDecl(b64: string): Declaration | null {
  try {
    const decl = JSON.parse(Buffer.from(b64, "base64").toString("utf8")) as Declaration;
    return validateDeclaration(decl) === null ? decl : null;
  } catch {
    return null;
  }
}

function paneNum(paneId: string): number {
  return Number.parseInt(paneId.slice(1), 10);
}

/** Reorder window panes (selection-sort of swap-pane calls) to match `desired`. */
function reorderPanes(windowId: string, desired: string[]): boolean {
  const current = getPaneOrder(windowId);
  if (current.length !== desired.length) return false;
  if (current.every((p, i) => p === desired[i])) return true;
  setWindowOpts(windowId, { busy: Date.now() });
  try {
    const order = current.slice();
    for (let i = 0; i < desired.length; i++) {
      if (order[i] === desired[i]) continue;
      const j = order.indexOf(desired[i]);
      if (j < 0) return false;
      tmux("swap-pane", "-d", "-s", order[i], "-t", order[j]);
      [order[i], order[j]] = [order[j], order[i]];
    }
    return true;
  } finally {
    // Leave the busy timestamp in place; it self-expires and suppresses the
    // swap-triggered layout events that may still be queued.
  }
}

// ── Recompute (declaration > golden) ──

function recompute(st: WindowState, opts: WindowOpts, mins: Mins, retries = 1): void {
  if (st.layout.includes("<")) {
    log(`floating panes present in ${st.windowId}; deferring apply`);
    setWindowOpts(st.windowId, { pending: true });
    return;
  }

  let target: string | null = null;
  let focusDependent = false;

  if (opts.decl) {
    const decl = decodeDecl(opts.decl);
    const desired = decl ? declPanes(decl.root) : [];
    const windowPanes = getPaneOrder(st.windowId);
    if (decl && sameSet(desired, windowPanes)) {
      if (!reorderPanes(st.windowId, desired)) {
        log(`declaration reorder failed for ${st.windowId}`);
        return;
      }
      const fresh = getWindowState(st.windowId);
      if (!fresh) return;
      st = fresh;
      const tree = renderDeclaration(decl, st.width, st.height, mins);
      if (!tree) {
        log(`declaration does not fit ${st.windowId} at ${st.width}x${st.height}; keeping current layout`);
        return;
      }
      target = serializeLayout(tree);
    } else {
      // Stale declaration (panes changed underneath it): drop it and fall
      // back to golden so the window never wedges.
      log(`clearing stale declaration on ${st.windowId}`);
      setWindowOpts(st.windowId, { decl: null });
    }
  }

  if (!target) {
    let topo;
    try {
      topo = parseLayout(st.layout);
    } catch (err) {
      log(`unparseable layout on ${st.windowId}: ${String(err)}`);
      return;
    }
    const tree = computeGolden(topo, paneNum(st.activePane), st.width, st.height, mins);
    if (!tree) {
      log(`golden layout infeasible for ${st.windowId} at ${st.width}x${st.height}; keeping current layout`);
      return;
    }
    target = serializeLayout(tree);
    focusDependent = true;
  }

  if (target === st.layout) {
    if (opts.lastApplied !== target) setWindowOpts(st.windowId, { lastApplied: target });
    return;
  }
  const changed = applyVerified(st, target, opts, focusDependent);
  if (changed && retries > 0) recompute(changed, getWindowOpts(st.windowId), mins, retries - 1);
}

function sameSet(a: string[], b: string[]): boolean {
  if (a.length !== b.length) return false;
  const sa = new Set(a);
  return b.every((x) => sa.has(x));
}

function pauseWindow(st: WindowState, opts: WindowOpts, silent = false): void {
  const wasPaused = opts.paused;
  setWindowOpts(st.windowId, { paused: true, manualRef: st.layout, pending: false });
  if (!wasPaused && !silent) displayMessage(PAUSE_MESSAGE);
}

function scaleManualRef(st: WindowState, opts: WindowOpts, mins: Mins, retries = 1): void {
  const refLayout = opts.manualRef ?? st.layout;
  let ref;
  try {
    ref = parseLayout(refLayout);
  } catch {
    setWindowOpts(st.windowId, { manualRef: st.layout });
    return;
  }
  let current;
  try {
    current = parseLayout(st.layout);
  } catch {
    return;
  }
  if (!samePaneSet(ref, current)) {
    // Topology changed while paused; the current layout becomes the reference.
    setWindowOpts(st.windowId, { manualRef: st.layout });
    return;
  }
  const tree = scaleReference(ref, st.width, st.height, mins);
  if (!tree) {
    log(`manual reference does not fit ${st.windowId} at ${st.width}x${st.height}; deferring`);
    return;
  }
  const target = serializeLayout(tree);
  if (target === st.layout) {
    if (opts.lastApplied !== target) setWindowOpts(st.windowId, { lastApplied: target });
    return;
  }
  const changed = applyVerified(st, target, opts, false);
  if (changed && retries > 0) scaleManualRef(changed, getWindowOpts(st.windowId), mins, retries - 1);
}

// ── Event entry point ──

export function handleEvent(
  kind: EventKind,
  windowId: string,
  eventPaneId?: string,
  eventLayout?: string,
): void {
  const config = readConfig();
  if (!config.enabled) return;

  const st = getWindowState(windowId);
  if (!st || st.windowId !== windowId) return; // window gone
  if (eventLayout && st.layout !== eventLayout) {
    log(`stale ${kind} event for ${windowId}; layout changed`);
    return;
  }
  if (kind === "focus" && eventPaneId && st.activePane !== eventPaneId) {
    log(`stale focus event ${eventPaneId} for ${windowId}; active=${st.activePane}`);
    return;
  }
  const opts = getWindowOpts(windowId);
  log(`event ${kind} ${windowId} layout=${st.layout} active=${st.activePane} paused=${opts.paused}`);

  // after-split-window and window-layout-changed describe the same topology
  // transition. Once one handler has applied a layout with the new pane set,
  // later topology handlers are stale even if another tool restores the split's
  // original geometry before they run.
  if (kind === "topology" && opts.lastApplied) {
    try {
      if (samePaneSet(parseLayout(st.layout), parseLayout(opts.lastApplied))) return;
    } catch {
      // let the normal recompute path report or recover from malformed state
    }
  }

  // Zoom: defer everything while zoomed; recompute once after unzoom.
  if (st.zoomed) {
    setWindowOpts(windowId, { zoomed: true, pending: true });
    return;
  }
  if (opts.zoomed) {
    setWindowOpts(windowId, { zoomed: false, pending: false });
    if (opts.pending) {
      if (opts.paused) scaleManualRef(st, opts, config.mins);
      else recompute(st, opts, config.mins);
    }
    return;
  }

  // tmux 3.7 custom layouts cannot restore floating panes. Keep declarations
  // and manual references intact, then settle once the last floating pane is
  // gone instead of treating it as a topology change.
  if (st.layout.includes("<")) {
    setWindowOpts(windowId, { pending: true });
    return;
  }
  if (opts.pending) {
    setWindowOpts(windowId, { pending: false });
    if (!opts.paused) {
      recompute(st, opts, config.mins);
      return;
    }
  }

  // Echo of one of our own recent select-layout calls: nothing to classify.
  // (focus/resized/topology events still fall through to recompute.)
  // An older history entry only counts as an echo when the pane set still
  // matches lastApplied — otherwise a kill-pane that coincidentally restores
  // an earlier geometry would be swallowed.
  if (kind === "layout" || kind === "manual") {
    if (st.layout === opts.lastApplied) return;
    if (opts.lastApplied && historyContains(opts, st.layout)) {
      try {
        if (samePaneSet(parseLayout(st.layout), parseLayout(opts.lastApplied))) return;
      } catch {
        // fall through to classification
      }
    }
  }

  // Multi-step declaration apply (pane swaps) in flight: ignore its noise.
  if (opts.busy && Date.now() - opts.busy <= BUSY_TTL_MS && kind === "layout") {
    return;
  }

  if (opts.paused) {
    handlePaused(kind, st, opts, config.mins);
    return;
  }

  switch (kind) {
    case "manual":
      // after-resize-pane that is not a zoom transition: user resize.
      pauseWindow(st, opts);
      return;
    case "layout": {
      if (!opts.lastApplied) {
        recompute(st, opts, config.mins);
        return;
      }
      let last;
      let current;
      try {
        last = parseLayout(opts.lastApplied);
        current = parseLayout(st.layout);
      } catch {
        recompute(st, opts, config.mins);
        return;
      }
      if (!samePaneSet(last, current)) {
        recompute(st, opts, config.mins); // topology change
        return;
      }
      if (last.width !== st.width || last.height !== st.height) {
        recompute(st, opts, config.mins); // outer resize scaled the layout
        return;
      }
      pauseWindow(st, opts); // same panes, same outer size: user changed geometry
      return;
    }
    case "resized":
    case "focus":
    case "topology":
      recompute(st, opts, config.mins);
      return;
  }
}

function handlePaused(kind: EventKind, st: WindowState, opts: WindowOpts, mins: Mins): void {
  switch (kind) {
    case "manual":
      setWindowOpts(st.windowId, { manualRef: st.layout });
      return;
    case "layout": {
      const refLayout = opts.lastApplied ?? opts.manualRef;
      if (!refLayout) {
        setWindowOpts(st.windowId, { manualRef: st.layout });
        return;
      }
      let ref;
      let current;
      try {
        ref = parseLayout(refLayout);
        current = parseLayout(st.layout);
      } catch {
        setWindowOpts(st.windowId, { manualRef: st.layout });
        return;
      }
      if (!samePaneSet(ref, current)) {
        // Topology changed while paused: adopt the new layout as reference.
        setWindowOpts(st.windowId, { manualRef: st.layout, lastApplied: null });
        return;
      }
      if (ref.width !== st.width || ref.height !== st.height) {
        scaleManualRef(st, opts, mins); // outer resize while paused
        return;
      }
      setWindowOpts(st.windowId, { manualRef: st.layout }); // refined manual layout
      return;
    }
    case "resized":
      scaleManualRef(st, opts, mins);
      return;
    case "focus":
    case "topology":
      return; // paused: no automatic resizing
  }
}

// ── API operations ──

export function resumeWindow(windowId: string): void {
  const config = readConfig();
  const st = getWindowState(windowId);
  if (!st) return;
  setWindowOpts(windowId, { paused: false, manualRef: null, pending: false });
  const opts = getWindowOpts(windowId);
  if (!config.enabled) return;
  if (st.zoomed) {
    setWindowOpts(windowId, { zoomed: true, pending: true });
    return;
  }
  recompute(st, opts, config.mins);
}

export function pauseWindowApi(windowId: string): void {
  const st = getWindowState(windowId);
  if (!st) return;
  const opts = getWindowOpts(windowId);
  pauseWindow(st, opts, true);
}

export function applyWindow(windowId: string): void {
  const config = readConfig();
  if (!config.enabled) return;
  const st = getWindowState(windowId);
  if (!st) return;
  const opts = getWindowOpts(windowId);
  if (opts.paused) {
    log(`apply skipped: ${windowId} is paused (prefix+= to resume)`);
    return;
  }
  if (st.zoomed) {
    setWindowOpts(windowId, { zoomed: true, pending: true });
    return;
  }
  recompute(st, opts, config.mins);
}

export function declareWindow(windowId: string, declJson: string): void {
  const decl = JSON.parse(declJson) as Declaration;
  const err = validateDeclaration(decl);
  if (err) throw new Error(`invalid declaration: ${err}`);
  const st = getWindowState(windowId);
  if (!st) throw new Error(`window not found: ${windowId}`);
  const windowPanes = getPaneOrder(windowId);
  const declared = declPanes(decl.root);
  if (!sameSet(declared, windowPanes)) {
    throw new Error(
      `declaration panes [${declared.join(",")}] do not match window panes [${windowPanes.join(",")}]`,
    );
  }
  setWindowOpts(windowId, { decl: Buffer.from(JSON.stringify(decl)).toString("base64") });
  applyWindow(windowId);
}

export function clearWindow(windowId: string): void {
  const st = getWindowState(windowId);
  if (!st) return;
  setWindowOpts(windowId, { decl: null });
  applyWindow(windowId);
}

export function setCompanion(companionWindowId: string, sourceWindowId: string, ownerPaneId: string): void {
  tmux(
    "set-option",
    "-w",
    "-t",
    companionWindowId,
    "@gl_companion_source",
    sourceWindowId,
    ";",
    "set-option",
    "-w",
    "-t",
    companionWindowId,
    "@gl_companion_owner",
    ownerPaneId,
  );
}

export function statusWindow(windowId: string): string {
  const st = getWindowState(windowId);
  const opts = st ? getWindowOpts(windowId) : null;
  const decl = opts?.decl ? decodeDecl(opts.decl) : null;
  return JSON.stringify(
    {
      window: windowId,
      state: st,
      paused: opts?.paused ?? false,
      declaration: decl,
      manualRef: opts?.manualRef ?? null,
      lastApplied: opts?.lastApplied ?? null,
      panes: st ? getPaneOrder(windowId) : [],
    },
    null,
    2,
  );
}
