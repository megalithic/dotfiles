import { expect, test } from "bun:test";
import { spawn, spawnSync, type ChildProcessWithoutNullStreams } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { createInterface } from "node:readline";

const modulePath = join(import.meta.dir, "../src/tmux.ts");

// Each worker reports both sides of the callback boundary. stdin gates release,
// so an incorrectly admitted contender cannot hide behind a fast callback.
function worker(socket: string, clock: number): {
  child: ChildProcessWithoutNullStreams;
  lines: string[];
  exited: Promise<number | null>;
} {
  const child = spawn(process.execPath, ["-e", `
    import { createInterface } from "node:readline";
    import { spawn } from "node:child_process";
    import { withWindowLock } from ${JSON.stringify(modulePath)};
    Date.now = () => ${clock};
    let release;
    createInterface({ input: process.stdin }).on("line", async (command) => {
      if (command === "release") { release?.(); return; }
      if (command === "other-window") {
        await withWindowLock("@996", () => console.log("other-window-entered"));
        return;
      }
      if (command === "descendant") {
        const child = spawn(process.execPath, ["-e", "console.log('ready'); await Bun.sleep(30000)"],
          { stdio: ["ignore", "pipe", "ignore"] });
        child.stdout.once("data", () => console.log("descendant:" + child.pid));
        return;
      }
      if (command === "start") {
        const pending = withWindowLock("@997", async () => {
          console.log("entered");
          await new Promise(resolve => { release = resolve; });
        });
        console.log("started");
        try {
          await pending;
          console.log("released");
        } catch (err) { console.log("error:" + err.message); }
      }
    });
    console.log("ready");
  `], { env: { ...process.env, GL_TMUX_SOCKET: socket, TMPDIR: join(socket, "..") }, stdio: "pipe" });
  const lines: string[] = [];
  createInterface({ input: child.stdout }).on("line", (line) => lines.push(line));
  child.stderr.on("data", (data) => lines.push(`stderr: ${data}`));
  const exited = new Promise<number | null>((resolve) => child.once("exit", resolve));
  return { child, lines, exited };
}

async function waitFor(check: () => boolean, timeout = 3000): Promise<void> {
  const deadline = performance.now() + timeout;
  while (!check()) {
    if (performance.now() > deadline) throw new Error("lock worker did not reach expected state");
    await Bun.sleep(10);
  }
}

for (const age of [0, 20_000]) {
  test(age === 0 ? "a later same-millisecond process cannot overtake an active owner" :
    "a live owner cannot be evicted because its clock is old", async () => {
    const dir = mkdtempSync(join(tmpdir(), "gl-lock-test-"));
    const socket = join(dir, "sock");
    const first = worker(socket, 1_800_000_000_000);
    const second = worker(socket, 1_800_000_000_000 + age);
    // Legacy ordering sorts PID text, not numbers. Run the larger one first.
    const [holder, waiter] = age === 0 && String(first.child.pid) < String(second.child.pid)
      ? [second, first] : [first, second];
    try {
      await waitFor(() => holder.lines.includes("ready") && waiter.lines.includes("ready"));
      holder.child.stdin.write("start\n");
      await waitFor(() => holder.lines.includes("entered"));
      waiter.child.stdin.write("start\n");
      await waitFor(() => waiter.lines.includes("started"));
      await Bun.sleep(100);
      expect(waiter.lines).not.toContain("entered");
      holder.child.stdin.write("release\n");
      await waitFor(() => holder.lines.includes("released") && waiter.lines.includes("entered"));
      waiter.child.stdin.write("release\n");
      await waitFor(() => waiter.lines.includes("released"));
    } finally {
      holder.child.kill("SIGKILL");
      waiter.child.kill("SIGKILL");
      await Promise.all([holder.exited, waiter.exited]);
      rmSync(dir, { recursive: true, force: true });
    }
  });
}

test("dead-owner recovery uses the same socket as the crashed owner", async () => {
  const dir = mkdtempSync(join(tmpdir(), "gl-lock-test-"));
  const socket = join(dir, "sock");
  const holder = worker(socket, 1_800_000_000_000);
  const waiter = worker(socket, 1_800_000_000_001);
  let descendant: number | undefined;
  try {
    await waitFor(() => holder.lines.includes("ready") && waiter.lines.includes("ready"));
    holder.child.stdin.write("start\n");
    await waitFor(() => holder.lines.includes("entered"));
    waiter.child.stdin.write("start\n");
    await waitFor(() => waiter.lines.includes("started"));
    holder.child.stdin.write("descendant\n");
    await waitFor(() => holder.lines.some((line) => line.startsWith("descendant:")));
    descendant = Number(holder.lines.find((line) => line.startsWith("descendant:"))!.split(":")[1]);
    holder.child.kill("SIGKILL");
    await holder.exited;
    await waitFor(() => waiter.lines.includes("entered"));
    // The executed descendant is still alive, but did not inherit the lock fd.
    expect(() => process.kill(descendant!, 0)).not.toThrow();
    waiter.child.stdin.write("release\n");
    await waitFor(() => waiter.lines.includes("released"));
  } finally {
    holder.child.kill("SIGKILL");
    waiter.child.kill("SIGKILL");
    await Promise.all([holder.exited, waiter.exited]);
    try {
      if (descendant !== undefined) {
        try { process.kill(descendant, "SIGKILL"); }
        catch (err) { if ((err as NodeJS.ErrnoException).code !== "ESRCH") throw err; }
        await waitFor(() => {
          try { process.kill(descendant!, 0); return false; }
          catch (err) {
            if ((err as NodeJS.ErrnoException).code === "ESRCH") return true;
            throw err;
          }
        });
      }
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  }
});

test("a timed-out waiter leaves the owner locked and can retry", async () => {
  const dir = mkdtempSync(join(tmpdir(), "gl-lock-test-"));
  const socket = join(dir, "sock");
  const holder = worker(socket, 1_800_000_000_000);
  const waiter = worker(socket, 1_800_000_000_000);
  try {
    await waitFor(() => holder.lines.includes("ready") && waiter.lines.includes("ready"));
    holder.child.stdin.write("start\n");
    await waitFor(() => holder.lines.includes("entered"));
    waiter.child.stdin.write("start\n");
    await waitFor(() => waiter.lines.includes("started"));
    await waitFor(() => waiter.lines.includes("error:timed out waiting for layout lock: @997"), 17_000);
    expect(waiter.lines).not.toContain("entered");
    waiter.child.stdin.write("start\n");
    await waitFor(() => waiter.lines.filter((line) => line === "started").length === 2);
    await Bun.sleep(100);
    expect(waiter.lines).not.toContain("entered");
    holder.child.stdin.write("release\n");
    await waitFor(() => holder.lines.includes("released") && waiter.lines.includes("entered"));
    waiter.child.stdin.write("release\n");
    await waitFor(() => waiter.lines.includes("released"));
  } finally {
    holder.child.kill("SIGKILL");
    waiter.child.kill("SIGKILL");
    await Promise.all([holder.exited, waiter.exited]);
    rmSync(dir, { recursive: true, force: true });
  }
}, 25_000);

test("different windows and sockets do not block each other", async () => {
  const dir = mkdtempSync(join(tmpdir(), "gl-lock-test-"));
  const holder = worker(join(dir, "sock"), 1_800_000_000_000);
  const other = worker(join(dir, "other-sock"), 1_800_000_000_000);
  try {
    await waitFor(() => holder.lines.includes("ready") && other.lines.includes("ready"));
    holder.child.stdin.write("start\n");
    await waitFor(() => holder.lines.includes("entered"));
    holder.child.stdin.write("other-window\n");
    other.child.stdin.write("start\n");
    await waitFor(() => holder.lines.includes("other-window-entered") && other.lines.includes("entered"));
    expect(holder.lines).not.toContain("released");
    holder.child.stdin.write("release\n");
    other.child.stdin.write("release\n");
    await waitFor(() => holder.lines.includes("released") && other.lines.includes("released"));
  } finally {
    holder.child.kill("SIGKILL");
    other.child.kill("SIGKILL");
    await Promise.all([holder.exited, other.exited]);
    rmSync(dir, { recursive: true, force: true });
  }
});

test("same-process callbacks serialize and thrown callbacks release only their own descriptor", () => {
  const dir = mkdtempSync(join(tmpdir(), "gl-lock-test-"));
  try {
    const result = spawnSync(process.execPath, ["-e", `
      import { withWindowLock } from ${JSON.stringify(modulePath)};
      Date.now = () => 1_800_000_000_000;
      let active = 0, maxActive = 0;
      const results = await Promise.allSettled(Array.from({ length: 40 }, (_, i) =>
        withWindowLock("@997", async () => {
          active++;
          maxActive = Math.max(maxActive, active);
          try {
            await Bun.sleep(2);
            if (i === 0) throw new Error("async callback failed");
          } finally { active--; }
          return i;
        })
      ));
      let syncError = "";
      try { await withWindowLock("@997", () => { throw new Error("sync callback failed"); }); }
      catch (err) { syncError = err.message; }
      const value = await withWindowLock("@997", () => 42);
      console.log(JSON.stringify({ maxActive, rejected: results.filter(r => r.status === "rejected").length,
        syncError, value }));
    `], { encoding: "utf8", timeout: 5000, env: { ...process.env, GL_TMUX_SOCKET: join(dir, "sock"), TMPDIR: dir } });
    expect(result.status).toBe(0);
    expect(JSON.parse(result.stdout)).toEqual({ maxActive: 1, rejected: 1, syncError: "sync callback failed", value: 42 });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
