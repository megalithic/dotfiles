import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import readline from "node:readline";
import bridge, { _test } from "../agent/extensions/bridge.ts";

type LifecycleEvent = { reason: "startup" | "quit" };

type LifecycleHook = (event: LifecycleEvent, ctx: ExtensionContext) => void | Promise<void>;

const hooks = new Map<string, LifecycleHook>();

// SAFETY: The fixture exercises only bridge startup/shutdown and ping. It has no
// model, UI, persistence, or message delivery API, so those calls fail the test.
const pi = {
  on: (name: string, handler: LifecycleHook) => { hooks.set(name, handler); },
  events: { on: () => () => {} },
} as ExtensionAPI;

// SAFETY: These are the only context members read by startup and ping.
const ctx = {
  cwd: process.cwd(),
  hasUI: false,
  isIdle: () => true,
  hasPendingMessages: () => false,
  sessionManager: { getSessionId: () => `child-${process.pid}`, getSessionName: () => "contention-test" },
} as ExtensionContext;

bridge(pi);

const input = readline.createInterface({ input: process.stdin });

input.on("line", async (line) => {
  try {
    if (line === "start") {
      const starting = hooks.get("session_start")?.({ reason: "startup" }, ctx);
      process.stdout.write("starting\n");
      await starting;
      await _test.startServer(pi, ctx);
      process.stdout.write("started\n");
    } else if (line === "stop") {
      await hooks.get("session_shutdown")?.({ reason: "quit" }, ctx);
      process.stdout.write("stopped\n");
      input.close();
      process.stdin.destroy();
    }
  } catch (error) {
    process.stderr.write(String(error) + "\n");
    process.exitCode = 1;
    input.close();
    process.stdin.destroy();
  }
});

process.stdout.write("ready\n");
