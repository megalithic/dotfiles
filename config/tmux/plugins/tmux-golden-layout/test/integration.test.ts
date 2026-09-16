/**
 * Integration tests against an isolated tmux server.
 *
 * Each suite starts its own server on a private socket (`tmux -S ... -f
 * /dev/null`), sources the plugin entrypoint, and drives real hooks. The
 * user's live tmux server is never touched.
 */

import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { execFileSync, spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

import { GOLDEN_FRACTION } from "../src/allocate";

const PLUGIN_DIR = join(import.meta.dir, "..");
const GL = join(PLUGIN_DIR, "bin", "gl");
const ENTRYPOINT = join(PLUGIN_DIR, "golden-layout.tmux");

const dir = mkdtempSync(join(tmpdir(), "gl-itest-"));
const SOCK = join(dir, "sock");
const ENV = { ...process.env, GL_TMUX_SOCKET: SOCK, TMUX: `${SOCK},0,0` };

function tmux(...args: string[]): string {
  return execFileSync("tmux", ["-S", SOCK, ...args], { encoding: "utf8", env: ENV }).trim();
}

function gl(...args: string[]): { status: number; stdout: string; stderr: string } {
  const out = spawnSync(GL, args, { encoding: "utf8", env: ENV });
  return { status: out.status ?? 1, stdout: out.stdout ?? "", stderr: out.stderr ?? "" };
}

async function waitFor<T>(fn: () => T | null | undefined | false, what: string, timeoutMs = 4000): Promise<T> {
  const start = Date.now();
  for (;;) {
    const v = fn();
    if (v) return v;
    if (Date.now() - start > timeoutMs) throw new Error(`timeout waiting for ${what}`);
    await Bun.sleep(60);
  }
}

function paneWidth(pane: string): number {
  return Number.parseInt(tmux("display-message", "-p", "-t", pane, "#{pane_width}"), 10);
}

function paneHeight(pane: string): number {
  return Number.parseInt(tmux("display-message", "-p", "-t", pane, "#{pane_height}"), 10);
}

function windowOption(win: string, name: string): string {
  return tmux("show-options", "-wqv", "-t", win, name);
}

const W = 200;
const H = 50;
const TARGET_W = Math.round(W * GOLDEN_FRACTION); // 124
const TARGET_H = Math.round(H * GOLDEN_FRACTION); // 31

beforeAll(() => {
  tmux("-f", "/dev/null", "new-session", "-d", "-x", String(W), "-y", String(H));
  tmux("set-option", "-g", "@gl-debug", "on");
  // Load the plugin exactly as tmux would (run-shell during config sourcing).
  const out = spawnSync("bash", [ENTRYPOINT], { encoding: "utf8", env: ENV });
  if (out.status !== 0) throw new Error(`entrypoint failed: ${out.stderr}`);
});

afterAll(() => {
  try {
    tmux("kill-server");
  } catch {
    // already gone
  }
  rmSync(dir, { recursive: true, force: true });
});

describe("plugin load", () => {
  test("registers indexed hooks and resume binding", () => {
    const sessionHooks = tmux("show-hooks", "-g");
    expect(sessionHooks).toContain("after-select-pane[188]");
    expect(sessionHooks).toContain("after-resize-pane[188]");
    expect(sessionHooks).toContain("after-split-window[188]");
    // window-scoped hooks live in the global window option table
    const windowHooks = tmux("show-hooks", "-gw");
    expect(windowHooks).toContain("window-layout-changed[188]");
    expect(windowHooks).toContain("window-resized[188]");
    const keys = tmux("list-keys");
    expect(keys).toContain("resume");
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
    // focus follows the new split; it should get the golden width
    await waitFor(() => paneWidth(right) === TARGET_W, `right pane at ${TARGET_W}, got ${paneWidth(right)}`);
    expect(paneWidth(left)).toBe(W - 1 - TARGET_W);
  });

  test("focus switch grows the other pane to the same exact target", async () => {
    tmux("select-pane", "-t", left);
    await waitFor(() => paneWidth(left) === TARGET_W, "left pane golden after focus");
    expect(paneWidth(right)).toBe(W - 1 - TARGET_W);
  });

  test("nested split: focused pane hits both axis targets", async () => {
    const bottom = tmux("split-window", "-v", "-t", right, "-P", "-F", "#{pane_id}");
    tmux("select-pane", "-t", bottom);
    await waitFor(
      () => paneWidth(bottom) === TARGET_W && paneHeight(bottom) === TARGET_H,
      `nested golden ${TARGET_W}x${TARGET_H}, got ${paneWidth(bottom)}x${paneHeight(bottom)}`,
    );
    tmux("kill-pane", "-t", bottom);
    await waitFor(() => tmux("list-panes", "-F", "#{pane_id}").split("\n").length === 2, "back to 2 panes");
  });

  test("outer window resize keeps golden ratio without drift", async () => {
    tmux("select-pane", "-t", left);
    await waitFor(() => paneWidth(left) === TARGET_W, "left golden");
    tmux("resize-window", "-x", "150", "-y", String(H));
    const t150 = Math.round(150 * GOLDEN_FRACTION);
    await waitFor(() => paneWidth(left) === t150, `left at ${t150} after shrink, got ${paneWidth(left)}`);
    tmux("resize-window", "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(left) === TARGET_W, "left golden restored after grow");
  });
});

describe("manual pause and resume", () => {
  let win: string;
  let a: string;
  let b: string;

  beforeAll(async () => {
    win = tmux("new-window", "-P", "-F", "#{window_id}");
    a = tmux("display-message", "-p", "-t", win, "#{pane_id}");
    b = tmux("split-window", "-h", "-t", a, "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(b) === TARGET_W, "initial golden in new window");
  });

  test("manual resize pauses automation for this window only", async () => {
    tmux("resize-pane", "-t", a, "-x", "100");
    await waitFor(() => windowOption(win, "@gl_paused") === "1", "window paused");
    // focus change must NOT resize while paused
    tmux("select-pane", "-t", a);
    await Bun.sleep(400);
    expect(paneWidth(a)).toBe(100);
  });

  test("outer resize while paused scales the manual reference proportionally", async () => {
    tmux("resize-window", "-x", "100", "-y", String(H));
    await waitFor(() => paneWidth(a) === 50, `paused pane scaled to 50, got ${paneWidth(a)}`);
    tmux("resize-window", "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(a) === 100, "paused pane scaled back to 100 (no drift)");
    expect(windowOption(win, "@gl_paused")).toBe("1");
  });

  test("resume reapplies golden immediately", async () => {
    const r = gl("resume", win);
    expect(r.status).toBe(0);
    await waitFor(() => windowOption(win, "@gl_paused") === "", "pause cleared");
    await waitFor(() => paneWidth(a) === TARGET_W, `golden restored after resume, got ${paneWidth(a)}`);
  });
});

describe("declarative API", () => {
  let win: string;
  let a: string;
  let b: string;

  beforeAll(async () => {
    win = tmux("new-window", "-P", "-F", "#{window_id}");
    a = tmux("display-message", "-p", "-t", win, "#{pane_id}");
    b = tmux("split-window", "-h", "-t", a, "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(b) === TARGET_W, "golden before declaration");
  });

  test("declare 65/35 applies exact ratios", async () => {
    const decl = { root: { split: "h", ratios: [0.65, 0.35], children: [{ pane: a }, { pane: b }] } };
    const r = gl("declare", win, JSON.stringify(decl));
    expect(r.status).toBe(0);
    // largest remainder: 199 cells -> 129.35/69.65 -> 129/70
    await waitFor(() => paneWidth(a) === 129, `65% => 129 cells, got ${paneWidth(a)}`);
    expect(paneWidth(b)).toBe(70);
  });

  test("declaration suppresses golden focus resizing", async () => {
    tmux("select-pane", "-t", b);
    await Bun.sleep(400);
    expect(paneWidth(a)).toBe(129);
    expect(paneWidth(b)).toBe(70);
  });

  test("declared ratios survive outer resizes exactly", async () => {
    tmux("resize-window", "-x", "120", "-y", String(H));
    // 119 cells -> 77.35/41.65 -> 77/42
    await waitFor(() => paneWidth(a) === 77, `scaled 65% => 77, got ${paneWidth(a)}`);
    tmux("resize-window", "-x", String(W), "-y", String(H));
    await waitFor(() => paneWidth(a) === 129, "exact 65% restored after resize cycle");
  });

  test("declaration reorders panes to match declared order", async () => {
    const decl = { root: { split: "h", ratios: [0.35, 0.65], children: [{ pane: b }, { pane: a }] } };
    const r = gl("declare", win, JSON.stringify(decl));
    expect(r.status).toBe(0);
    await waitFor(() => tmux("list-panes", "-t", win, "-F", "#{pane_id}").split("\n")[0] === b, "b first");
    // 199 cells -> 69.65/129.35 -> 70/129 (largest remainder)
    await waitFor(() => paneWidth(b) === 70, `b at 35%, got ${paneWidth(b)}`);
  });

  test("declare rejects pane mismatch", () => {
    const decl = { root: { split: "h", children: [{ pane: a }, { pane: "%999" }] } };
    const r = gl("declare", win, JSON.stringify(decl));
    expect(r.status).not.toBe(0);
    expect(r.stderr).toContain("do not match");
  });

  test("clear returns the window to golden resizing", async () => {
    const r = gl("clear", win);
    expect(r.status).toBe(0);
    tmux("select-pane", "-t", a);
    await waitFor(() => paneWidth(a) === TARGET_W, `golden after clear, got ${paneWidth(a)}`);
  });

  test("grid declaration builds an even grid", async () => {
    const c = tmux("split-window", "-h", "-t", win, "-P", "-F", "#{pane_id}");
    const d = tmux("split-window", "-h", "-t", win, "-P", "-F", "#{pane_id}");
    const panes = tmux("list-panes", "-t", win, "-F", "#{pane_id}").split("\n");
    expect(panes.length).toBe(4);
    const r = gl("grid", win, ...panes);
    expect(r.status).toBe(0);
    await waitFor(() => Math.abs(paneWidth(panes[0]) - paneWidth(panes[1])) <= 1 && paneHeight(panes[0]) < H - 5, "2x2 grid");
    gl("clear", win);
    tmux("kill-pane", "-t", c);
    tmux("kill-pane", "-t", d);
  });

  test("companion association is stored on the companion window", () => {
    const comp = tmux("new-window", "-P", "-F", "#{window_id}");
    const r = gl("companion", comp, win, a);
    expect(r.status).toBe(0);
    expect(windowOption(comp, "@gl_companion_source")).toBe(win);
    expect(windowOption(comp, "@gl_companion_owner")).toBe(a);
    tmux("kill-window", "-t", comp);
  });

  test("status reports window state", () => {
    const r = gl("status", win);
    expect(r.status).toBe(0);
    const parsed = JSON.parse(r.stdout);
    expect(parsed.window).toBe(win);
    expect(parsed.paused).toBe(false);
  });
});

describe("zoom deferral", () => {
  test("zoomed window defers changes; unzoom applies them", async () => {
    const win = tmux("new-window", "-P", "-F", "#{window_id}");
    const b = tmux("split-window", "-h", "-t", win, "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(b) === TARGET_W, "golden before zoom");
    tmux("resize-pane", "-Z", "-t", b);
    await waitFor(() => windowOption(win, "@gl_zoomed") === "1", "zoom recorded");
    // Outer resize while zoomed: must be deferred, then applied after unzoom.
    tmux("resize-window", "-t", win, "-x", "150", "-y", String(H));
    await Bun.sleep(300);
    expect(windowOption(win, "@gl_pending")).toBe("1");
    tmux("resize-pane", "-Z", "-t", b); // unzoom
    await waitFor(() => windowOption(win, "@gl_zoomed") === "", "zoom cleared");
    const t150 = Math.round(150 * GOLDEN_FRACTION);
    await waitFor(() => paneWidth(b) === t150, `deferred golden applied after unzoom, got ${paneWidth(b)}`);
    tmux("kill-window", "-t", win);
  });
});

describe("foreign layout changes", () => {
  test("another tool's select-layout pauses the window (pi even-horizontal scenario)", async () => {
    const win = tmux("new-window", "-P", "-F", "#{window_id}");
    const b = tmux("split-window", "-h", "-t", win, "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(b) === TARGET_W, "golden before foreign layout");
    tmux("select-layout", "-t", win, "even-horizontal");
    await waitFor(() => windowOption(win, "@gl_paused") === "1", "paused by foreign select-layout");
    // the foreign layout is preserved, not fought
    expect(Math.abs(paneWidth(b) - Math.floor((W - 1) / 2))).toBeLessThanOrEqual(1);
    const r = gl("resume", win);
    expect(r.status).toBe(0);
    await waitFor(() => paneWidth(b) === TARGET_W, "golden after resume");
    tmux("kill-window", "-t", win);
  });
});

describe("rapid focus changes", () => {
  test("focus flapping settles on the last focused pane at the exact target", async () => {
    const win = tmux("new-window", "-P", "-F", "#{window_id}");
    const a = tmux("display-message", "-p", "-t", win, "#{pane_id}");
    const b = tmux("split-window", "-h", "-t", win, "-P", "-F", "#{pane_id}");
    await waitFor(() => paneWidth(b) === TARGET_W, "initial golden");
    for (let i = 0; i < 10; i++) {
      tmux("select-pane", "-t", i % 2 === 0 ? a : b);
    }
    tmux("select-pane", "-t", a);
    await waitFor(() => paneWidth(a) === TARGET_W, `a golden after flapping, got ${paneWidth(a)}`);
    // and it must not be paused by our own churn
    expect(windowOption(win, "@gl_paused")).toBe("");
    tmux("kill-window", "-t", win);
  });
});

describe("hook idempotency and loop prevention", () => {
  test("applied layout settles (no self-triggering loop)", async () => {
    const win = tmux("new-window", "-P", "-F", "#{window_id}");
    tmux("split-window", "-h", "-t", win);
    await Bun.sleep(700);
    const layout1 = tmux("display-message", "-p", "-t", win, "#{window_layout}");
    await Bun.sleep(700);
    const layout2 = tmux("display-message", "-p", "-t", win, "#{window_layout}");
    expect(layout2).toBe(layout1);
    tmux("kill-window", "-t", win);
  });

  test("re-sourcing the entrypoint does not duplicate hooks", () => {
    const before = tmux("show-hooks", "-g").split("\n").filter((l) => l.includes("[188]")).length;
    const out = spawnSync("bash", [ENTRYPOINT], { encoding: "utf8", env: ENV });
    expect(out.status).toBe(0);
    const after = tmux("show-hooks", "-g").split("\n").filter((l) => l.includes("[188]")).length;
    expect(after).toBe(before);
  });
});
