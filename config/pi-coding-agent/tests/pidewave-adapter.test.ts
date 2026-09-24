import { expect, test } from "bun:test";
import type { ExtensionAPI, ExtensionContext, ToolDefinition } from "@earendil-works/pi-coding-agent";
import fs from "node:fs";
import { createRequire } from "node:module";
import { homedir } from "node:os";
import path from "node:path";

type Hook = (event: { reason?: string }, ctx: ExtensionContext) => void | Promise<void>;

type EventPayload = Parameters<ExtensionAPI["events"]["emit"]>[1];

type Registration = { dispose(): Promise<void> };

type Result<T> = { ok: true } & T | { ok: false; error: Error };

type Snapshot = { name: string; definition: typeof definition; runtime: true; persisted: false };

type RegisterRequest = { version: 1; name: string; definition: typeof definition; result?: Result<{ registration: Registration }> };

type SnapshotRequest = { version: 1; name: string; result?: Result<{ snapshot: Snapshot }> };

const definition = {
  httpTransport: "streamable-http" as const,
  url: "http://127.0.0.1:4300/tidewave/mcp",
  lifecycle: "keep-alive" as const,
  directTools: true,
};

const registerEvent = "pi-mcp-adapter:runtime-register:v1";

const snapshotEvent = "pi-mcp-adapter:runtime-snapshot:v1";

const statusEvent = "pi-mcp-adapter/status/v1";

function harness(cwd: string) {
  const listeners = new Map<string, Set<(payload: EventPayload) => void>>();
  const hooks = new Map<string, Hook[]>();
  const tools = new Map<string, ToolDefinition>();
  let active = new Set<string>();

  const events = {
    on(name: string, listener: (payload: EventPayload) => void) {
      const callbacks = listeners.get(name) ?? new Set();
      callbacks.add(listener);
      listeners.set(name, callbacks);

      return () => { callbacks.delete(listener); };
    },
    emit(name: string, payload: EventPayload) {
      for (const listener of listeners.get(name) ?? []) listener(payload);
    },
  };

  // SAFETY: The adapter path uses only these lifecycle, event, and tool-surface APIs.
  const pi = {
    events,
    on(name: string, hook: Hook) { hooks.set(name, [...hooks.get(name) ?? [], hook]); },
    registerTool(tool: ToolDefinition) {
      if (!tools.has(tool.name)) active.add(tool.name);
      tools.set(tool.name, tool);
    },
    getAllTools: () => [...tools.values()],
    getActiveTools: () => [...active],
    setActiveTools: (names: string[]) => { active = new Set(names); },
    registerCommand: () => {},
    registerFlag: () => {},
    getFlag: () => undefined,
  } as ExtensionAPI;

  // SAFETY: Headless initialization reads only cwd, mode, session branch, and status UI.
  const ctx = {
    cwd, hasUI: false, mode: "print",
    sessionManager: { getBranch: () => [] },
    ui: { setStatus: () => {} },
  } as ExtensionContext;

  return {
    pi, events, tools,
    active: () => [...active].sort(),
    async fire(name: string, reason?: string) {
      for (const hook of hooks.get(name) ?? []) await hook({ reason }, ctx);
    },
    execute: (name: string) => tools.get(name)!.execute("fixture", {}, undefined, undefined, ctx),
    register() {
      const request: RegisterRequest = {
        version: 1, name: "tidewave", definition,
      };

      events.emit(registerEvent, request);

      return request.result;
    },
    snapshot() {
      const request: SnapshotRequest = { version: 1, name: "tidewave" };
      events.emit(snapshotEvent, request);

      return request.result;
    },
  };
}

// Run standalone: imports and adapter paths depend on process-global environment.
test("stock adapter runtime registration stays proxy-only across deferred startup and reload", async () => {
  const originalEnv = { ...process.env };
  const agentDir = fs.mkdtempSync("/tmp/pidewave-adapter-");
  const instances: ReturnType<typeof harness>[] = [];
  process.env.PI_CODING_AGENT_DIR = agentDir;
  delete process.env.PI_PACKAGE_DIR;
  delete process.env.MCP_DIRECT_TOOLS;

  try {
    const installed = createRequire(path.join(homedir(), ".pi/agent/npm/package.json"));
    const entry = installed.resolve("pi-mcp-adapter");
    const { createJiti } = installed("jiti");

    const jiti = createJiti(import.meta.url, {
      moduleCache: false,
      alias: {
        "@earendil-works/pi-tui": installed.resolve("@earendil-works/pi-tui"),
        "typebox/value": installed.resolve("typebox/value"),
        typebox: installed.resolve("typebox"),
      },
    });

    const { createMcpAdapter } = await jiti.import(entry);
    const { computeServerHash } = await jiti.import(installed.resolve("pi-mcp-adapter/metadata-cache"));
    fs.writeFileSync(path.join(agentDir, "mcp-cache.json"), JSON.stringify({
      version: 1,
      servers: { tidewave: {
        configHash: computeServerHash(definition), cachedAt: Date.now(),
        tools: [{ name: "echo", description: "Fixture tool", inputSchema: { type: "object", properties: {} } }],
        resources: [],
      } },
    }));

    for (const reason of ["startup", "reload"]) {
      const h = harness(agentDir);
      instances.push(h);
      createMcpAdapter({ config: { mcpServers: {}, settings: { scriptMode: false, directTools: true } } })(h.pi);
      const published: ReturnType<typeof h.snapshot>[] = [];
      const unsubscribe = h.events.on(statusEvent, () => { published.push(h.snapshot()); });

      try {
        await h.fire("session_start", reason);
        const registered = h.register();
        expect(registered?.ok).toBe(true); // The event must answer synchronously.

        if (!registered?.ok) throw new Error("Runtime registration failed");
        const duplicate = h.register();
        expect(duplicate?.ok).toBe(false);

        if (duplicate?.ok === false) expect(duplicate.error.message).toContain("already registered");
        const deferred = h.snapshot();
        expect(deferred?.ok).toBe(false);

        if (deferred?.ok === false) expect(deferred.error.message).toContain("no active state");
        expect(h.active()).toEqual(["mcp"]);

        // Empty configured servers return before health timers or transports start.
        // Runtime registrations attach afterward. Never dispatch input or a real tool call.
        const result = await h.execute("mcp");
        expect(result.details).not.toHaveProperty("error");
        expect(h.active()).toEqual(["mcp", "mcp__tidewave"]);
        expect([...h.tools.keys()].sort()).toEqual(["mcp", "mcp__tidewave"]);
        const expected = { ok: true, snapshot: { name: "tidewave", definition, runtime: true, persisted: false } };
        expect(h.snapshot()).toEqual(expected);
        expect(published.at(-1)).toEqual(expected);
        expect((await h.execute("mcp__tidewave")).details).toMatchObject({ error: "missing_tool" });

        await registered.registration.dispose();
        await registered.registration.dispose();
        const disposed = h.snapshot();
        expect(disposed?.ok).toBe(false);

        if (disposed?.ok === false) expect(disposed.error.message).toContain("disposed");
        expect(h.active()).toEqual(["mcp"]);
      } finally {
        unsubscribe();
        await h.fire("session_shutdown");
      }
    }
  } finally {
    try {
      for (const h of instances) await h.fire("session_shutdown");
    } finally {
      process.env = originalEnv;
      // Keep the isolated fixture for failure inspection, matching adjacent tests.
    }
  }
}, 30_000);
