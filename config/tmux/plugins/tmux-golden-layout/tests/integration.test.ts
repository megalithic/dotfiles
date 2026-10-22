/**
 * Integration tests against an isolated tmux 3.8 server.
 *
 * The suite starts its own server on a private socket (`tmux -S ... -f
 * /dev/null`), sources the plugin entrypoint, and drives real hooks. The
 * user's live tmux server is never touched.
 */

import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, symlinkSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { GOLDEN_FRACTION } from "../src/allocate";
import { commit, readState } from "../src/tmux";

const PLUGIN_DIR = join(import.meta.dir, "..");
const GL = join(PLUGIN_DIR, "bin", "gl");
const ENTRYPOINT = join(PLUGIN_DIR, "golden-layout.tmux");
const REAL_TMUX = execFileSync("which", ["tmux"], { encoding: "utf8" }).trim();

const dir = mkdtempSync(join(tmpdir(), "gl-itest-"));
const SOCK = join(dir, "sock");
const ENV = { ...process.env, GL_TMUX_SOCKET: SOCK, TMUX: `${SOCK},0,0`, TMPDIR: dir };
const previousSocket = process.env.GL_TMUX_SOCKET;
const previousTmpdir = process.env.TMPDIR;

function tmux(...args: string[]): string {
  return execFileSync("tmux", ["-S", SOCK, ...args], { encoding: "utf8", env: ENV }).trim();
}

function gl(...args: string[]): { status: number; stdout: string; stderr: string } {
  const out = spawnSync(GL, args, { encoding: "utf8", env: ENV });
  return { status: out.status ?? 1, stdout: out.stdout ?? "", stderr: out.stderr ?? "" };
}

function loadPlugin(env: NodeJS.ProcessEnv = ENV): void {
  const out = spawnSync("bash", [ENTRYPOINT], { encoding: "utf8", env });
  if (out.status !== 0) throw new Error(`entrypoint failed: ${out.stderr}`);
}

async function waitFor<T>(fn: () => T | null | undefined | false, what: () => string, timeoutMs = 4000): Promise<T> {
  const start = Date.now();
  for (;;) {
    const v = fn();
    if (v) return v;
    if (Date.now() - start > timeoutMs) throw new Error(`timeout waiting for ${what()}`);
    await Bun.sleep(60);
  }
}

const paneWidth = (pane: string): number =>
  Number.parseInt(tmux("display-message", "-p", "-t", pane, "#{pane_width}"), 10);
const paneHeight = (pane: string): number =>
  Number.parseInt(tmux("display-message", "-p", "-t", pane, "#{pane_height}"), 10);
const windowOption = (win: string, name: string): string => tmux("show-options", "-wqv", "-t", win, name);
const layoutOf = (win: string): string => tmux("display-message", "-p", "-t", win, "#{window_layout}");
const activePane = (win: string): string => tmux("display-message", "-p", "-t", win, "#{pane_id}");

/** New window with two side-by-side panes, settled at the golden width. */
async function twoPaneWindow(): Promise<{ win: string; a: string; b: string }> {
  const win = tmux("new-window", "-P", "-F", "#{window_id}");
  const a = activePane(win);
  const b = tmux("split-window", "-h", "-t", a, "-P", "-F", "#{pane_id}");
  await waitFor(() => paneWidth(b) === TARGET_W, () => `golden split, got ${paneWidth(b)}`);
  return { win, a, b };
}

const W = 200;
const H = 50;
const TARGET_W = Math.round(W * GOLDEN_FRACTION); // 124
const TARGET_H = Math.round(H * GOLDEN_FRACTION); // 31

beforeAll(() => {
  process.env.GL_TMUX_SOCKET = SOCK;
  process.env.TMPDIR = dir;
  tmux("-f", "/dev/null", "new-session", "-d", "-x", String(W), "-y", String(H));
  tmux("set-option", "-g", "@gl-debug", "on");
  loadPlugin(); // exactly as tmux would (run-shell during config sourcing)
});

afterAll(() => {
  try {
    tmux("kill-server");
  } catch {
    // already gone
  }
  try {
    rmSync(dir, { recursive: true, force: true });
  } finally {
    if (previousSocket === undefined) delete process.env.GL_TMUX_SOCKET;
    else process.env.GL_TMUX_SOCKET = previousSocket;
    if (previousTmpdir === undefined) delete process.env.TMPDIR;
    else process.env.TMPDIR = previousTmpdir;
  }
});

describe("plugin load", () => {
  test("registers indexed 3.8 hooks and the resume binding", () => {
    const hooks = tmux("show-hooks", "-gw");
    for (const h of ["window-pane-changed", "window-layout-changed", "window-unzoomed"]) {
      expect(hooks).toContain(`${h}[188]`);
    }
    expect(hooks).toContain("event '#{hook}' '#{hook_window}'");
    expect(tmux("show-hooks", "-g")).not.toContain("after-select-pane[188]");
    expect(tmux("list-keys")).toContain("resume");
  });

  test("reload removes hooks registered by the pre-3.8 plugin", () => {
    tmux("set-hook", "-g", "after-select-pane[188]", "display-message old");
    tmux("set-hook", "-g", "window-resized[188]", "display-message old");
    loadPlugin();
    expect(tmux("show-hooks", "-g")).not.toContain("after-select-pane[188]");
    expect(tmux("show-hooks", "-gw")).not.toContain("window-resized[188]");
  });

  test("re-sourcing the entrypoint does not duplicate hooks", () => {
    const count = (): number => tmux("show-hooks", "-gw").split("\n").filter((l) => l.includes("[188]")).length;
    const before = count();
    loadPlugin();
    expect(count()).toBe(before);
  });

  test("disabled reload unregisters hooks even when bun and mise are unavailable", () => {
    const pathDir = mkdtempSync(join(tmpdir(), "gl-path-itest-"));
    symlinkSync(REAL_TMUX, join(pathDir, "tmux"));
    try {
      tmux("set-option", "-g", "@gl-enabled", "off");
      loadPlugin({ ...ENV, PATH: `${pathDir}:/usr/bin:/bin` });
      expect(tmux("show-hooks", "-g")).not.toContain("[188]");
      expect(tmux("show-hooks", "-gw")).not.toContain("[188]");
      expect(tmux("list-keys")).not.toContain("tmux-golden-layout/bin/gl");
      expect(tmux("show-options", "-gqv", "@gl-bun")).toBe("");
    } finally {
      tmux("set-option", "-g", "@gl-enabled", "on");
      loadPlugin();
      rmSync(pathDir, { recursive: true, force: true });
    }
  });
});

describe("golden focus resizing", () => {
  let win: string;
  let left: string;
  let right: string;

  test("split triggers golden layout for the focused pane", async () => {
    win = tmux("display-message", "-p", "#{window_id}");
    left = tmux("display-message", "-p", "#{pane_id}");
    right = tmux("split-window", "-h", "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(right) === TARGET_W, () => `right pane at ${TARGET_W}, got ${paneWidth(right)}`);
    expect(paneWidth(left)).toBe(W - 1 - TARGET_W);
  });

  test("focus switch grows the other pane to the same exact target", async () => {
    tmux("select-pane", "-t", left);
    await waitFor(() => paneWidth(left) === TARGET_W, () => `left golden, got ${paneWidth(left)}`);
    expect(paneWidth(right)).toBe(W - 1 - TARGET_W);
  });

  test("last-pane (no select-pane hook) also resizes, and keeps last-pane history", async () => {
    tmux("last-pane");
    await waitFor(() => paneWidth(right) === TARGET_W, () => `right golden after last-pane, got ${paneWidth(right)}`);
    tmux("last-pane");
    await waitFor(() => paneWidth(left) === TARGET_W, () => `left golden after last-pane, got ${paneWidth(left)}`);
  });

  test("nested split: focused pane hits both axis targets", async () => {
    const bottom = tmux("split-window", "-v", "-t", right, "-P", "-F", "#{pane_id}");
    await waitFor(
      () => paneWidth(bottom) === TARGET_W && paneHeight(bottom) === TARGET_H,
      () => `nested golden ${TARGET_W}x${TARGET_H}, got ${paneWidth(bottom)}x${paneHeight(bottom)}`,
    );
    tmux("kill-pane", "-t", bottom);
    // focus moves to a remaining pane, which settles at the golden width
    await waitFor(() => paneWidth(activePane(win)) === TARGET_W, () => "golden after kill-pane");
  });

  test("outer window resize keeps golden ratio without drift", async () => {
    tmux("select-pane", "-t", left);
    await waitFor(() => paneWidth(left) === TARGET_W, () => "left golden");
    tmux("resize-window", "-x", "150", "-y", String(H));
    const t150 = Math.round(150 * GOLDEN_FRACTION);
    await waitFor(() => paneWidth(left) === t150, () => `left at ${t150} after shrink, got ${paneWidth(left)}`);
    tmux("resize-window", "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(left) === TARGET_W, () => "left golden restored after grow");
  });

  test("applied layout settles (no self-triggering loop)", async () => {
    await Bun.sleep(500);
    const before = layoutOf(win);
    await Bun.sleep(700);
    expect(layoutOf(win)).toBe(before);
  });
});

describe("manual pause and resume", () => {
  let win: string;
  let a: string;

  beforeAll(async () => {
    ({ win, a } = await twoPaneWindow());
  });

  test("manual resize pauses automation for this window only", async () => {
    tmux("resize-pane", "-t", a, "-x", "100");
    await waitFor(() => windowOption(win, "@gl_paused") === "1", () => "window paused");
    tmux("select-pane", "-t", a); // focus change must NOT resize while paused
    await Bun.sleep(400);
    expect(paneWidth(a)).toBe(100);
    expect(activePane(win)).toBe(a); // and must not restore the focus captured at pause
  });

  test("outer resize while paused scales the manual reference proportionally", async () => {
    tmux("resize-window", "-t", win, "-x", "100", "-y", String(H));
    await waitFor(() => paneWidth(a) === 50, () => `paused pane scaled to 50, got ${paneWidth(a)}`);
    tmux("resize-window", "-t", win, "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(a) === 100, () => "paused pane scaled back to 100 (no drift)");
    expect(windowOption(win, "@gl_paused")).toBe("1");
  });

  test("outer resize while zoomed settles the paused reference after unzoom", async () => {
    tmux("resize-pane", "-Z", "-t", a);
    tmux("resize-window", "-t", win, "-x", "150", "-y", String(H));
    await Bun.sleep(300);
    tmux("resize-pane", "-Z", "-t", a);
    await waitFor(() => paneWidth(a) === 75, () => `paused reference scaled after unzoom, got ${paneWidth(a)}`);
    tmux("resize-window", "-t", win, "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(a) === 100, () => "paused reference restored after zoom resize cycle");
    expect(windowOption(win, "@gl_paused")).toBe("1");
  });

  test("resume reapplies golden immediately", async () => {
    expect(gl("resume", win).status).toBe(0);
    await waitFor(() => windowOption(win, "@gl_paused") === "", () => "pause cleared");
    await waitFor(() => paneWidth(a) === TARGET_W, () => `golden restored after resume, got ${paneWidth(a)}`);
    tmux("kill-window", "-t", win);
  });
});

describe("floating panes", () => {
  test("tiled panes keep resizing and the floating pane is left alone", async () => {
    const { win, a, b } = await twoPaneWindow();
    const floating = tmux("new-pane", "-d", "-t", win, "-P", "-F", "#{pane_id}");
    const floatGeometry = (): string =>
      tmux("display-message", "-p", "-t", floating, "#{pane_width}x#{pane_height}+#{pane_left}+#{pane_top}");
    const before = floatGeometry();
    tmux("select-pane", "-t", a);
    await waitFor(() => paneWidth(a) === TARGET_W, () => `golden with floating pane open, got ${paneWidth(a)}`);
    expect(floatGeometry()).toBe(before);
    expect(windowOption(win, "@gl_paused")).toBe("");
    tmux("select-pane", "-t", b);
    await waitFor(() => paneWidth(b) === TARGET_W, () => "golden back on b");
    tmux("kill-window", "-t", win);
  });
});

describe("zoom", () => {
  test("zoomed window is left alone; unzoom applies the new size", async () => {
    const { win, b } = await twoPaneWindow();
    tmux("resize-pane", "-Z", "-t", b);
    tmux("resize-window", "-t", win, "-x", "150", "-y", String(H));
    await Bun.sleep(300);
    expect(tmux("display-message", "-p", "-t", win, "#{window_zoomed_flag}")).toBe("1");
    tmux("resize-pane", "-Z", "-t", b);
    const t150 = Math.round(150 * GOLDEN_FRACTION);
    await waitFor(() => paneWidth(b) === t150, () => `golden applied after unzoom, got ${paneWidth(b)}`);
    tmux("resize-window", "-t", win, "-x", String(W), "-y", String(H));
    tmux("kill-window", "-t", win);
  });

  test("focus changed while zoomed is settled after unzoom", async () => {
    const { win, a, b } = await twoPaneWindow();
    tmux("resize-pane", "-Z", "-t", b);
    tmux("select-pane", "-Z", "-t", a); // keeps the window zoomed
    await Bun.sleep(300);
    tmux("resize-pane", "-Z", "-t", a);
    await waitFor(() => paneWidth(a) === TARGET_W, () => `a golden after unzoom, got ${paneWidth(a)}`);
    tmux("kill-window", "-t", win);
  });
});

describe("foreign layout changes", () => {
  test("another tool's select-layout pauses the window", async () => {
    const { win, b } = await twoPaneWindow();
    tmux("select-layout", "-t", win, "even-horizontal");
    await waitFor(() => windowOption(win, "@gl_paused") === "1", () => "paused by foreign select-layout");
    // the foreign layout is preserved, not fought
    expect(Math.abs(paneWidth(b) - Math.floor((W - 1) / 2))).toBeLessThanOrEqual(1);
    expect(gl("resume", win).status).toBe(0);
    await waitFor(() => paneWidth(b) === TARGET_W, () => "golden after resume");
    tmux("kill-window", "-t", win);
  });

  test("swapping panes without resizing re-settles instead of pausing", async () => {
    const { win, a, b } = await twoPaneWindow();
    tmux("swap-pane", "-d", "-s", a, "-t", b);
    await waitFor(() => tmux("list-panes", "-t", win, "-F", "#{pane_id}").startsWith(b), () => "panes swapped");
    await Bun.sleep(400);
    expect(paneWidth(activePane(win))).toBe(TARGET_W);
    expect(windowOption(win, "@gl_paused")).toBe("");
    tmux("kill-window", "-t", win);
  });
});

describe("races", () => {
  test("focus flapping settles on the last focused pane at the exact target", async () => {
    const { win, a, b } = await twoPaneWindow();
    for (let i = 0; i < 10; i++) tmux("select-pane", "-t", i % 2 === 0 ? a : b);
    tmux("select-pane", "-t", a);
    await waitFor(() => paneWidth(a) === TARGET_W, () => `a golden after flapping, got ${paneWidth(a)}`);
    expect(windowOption(win, "@gl_paused")).toBe(""); // not paused by our own churn
    tmux("kill-window", "-t", win);
  });

  test("commit drops work computed from a stale snapshot", async () => {
    const { win, a } = await twoPaneWindow();
    const stale = readState(win)!;
    tmux("select-pane", "-t", a); // focus is part of the layout, so the snapshot is now stale
    await waitFor(() => paneWidth(a) === TARGET_W, () => "a golden");
    const settled = layoutOf(win);
    commit(stale, [`select-layout -t ${win} even-horizontal`]);
    expect(layoutOf(win)).toBe(settled);
    expect(windowOption(win, "@gl_expect")).toBe("");

    const fresh = readState(win)!;
    commit(fresh, [`set-option -w -t ${win} @gl_probe 1`]);
    expect(windowOption(win, "@gl_probe")).toBe("1");
    tmux("kill-window", "-t", win);
  });
});
