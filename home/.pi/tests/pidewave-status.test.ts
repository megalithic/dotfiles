import { afterEach, describe, expect, spyOn, test } from "bun:test";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { createRequire } from "node:module";
import net from "node:net";
import { createInterface } from "node:readline";
import { fileURLToPath } from "node:url";
import { homedir } from "node:os";
import fs from "node:fs";
import path from "node:path";
import { stripVTControlCharacters } from "node:util";

const stateDir = fs.mkdtempSync("/tmp/pi-pidewave-test-");

const bindingDir = path.join(stateDir, "tidewave", "bindings");

const originalEnv = { ...process.env };

process.env.PI_STATE_DIR = stateDir;

const { default: acp } = await import("../agent/extensions/acp.ts");

const installed = createRequire(path.join(homedir(), ".pi/agent/npm/package.json"));

const { createJiti } = installed("jiti");

const jiti = createJiti(import.meta.url, {
  moduleCache: false,
  alias: {
    "@earendil-works/pi-tui": installed.resolve("@earendil-works/pi-tui"),
    "typebox/value": installed.resolve("typebox/value"),
    typebox: installed.resolve("typebox"),
  },
});

const { visibleWidth } = await jiti.import("@earendil-works/pi-tui");

const { default: customFooter } = await jiti.import("../agent/extensions/custom-footer.ts");

process.env = { ...originalEnv };

const cleanups: (() => void | Promise<void>)[] = [];

afterEach(async () => {
  for (const cleanup of cleanups.splice(0).reverse()) await cleanup();
  process.env = { ...originalEnv };
  // Preserve temporary fixtures for failure inspection.
});

type LifecycleEvent = { reason?: "startup" | "reload" };

type Hook = (event: LifecycleEvent, ctx: ExtensionContext) => void;

type BindingFixture = {
  cwd?: string;
  socket?: string | number | boolean | null | string[] | { toString: string };
  appUrl?: string | number | boolean | null;
  port?: string | number | null;
};

const lifecycle = () => {
  const hooks = new Map<string, Hook>();

  // SAFETY: Only lifecycle and command registration, shared events and getThinkingLevel are used.
  const pi = {
    events: { emit: () => {}, on: () => () => {} },
    on: (name: string, hook: Hook) => { hooks.set(name, hook); },
    registerCommand: () => {},
    getThinkingLevel: () => "off",
  } as ExtensionAPI;

  return { pi, fire: (name: string, ctx: ExtensionContext) => hooks.get(name)?.({}, ctx) };
};

let fixtureId = 0;

const bindingHarness = (hasUI = true) => {
  const cwd = path.join(stateDir, `Work Tree_${++fixtureId}`);
  const slug = path.basename(cwd).toLowerCase().replace(/[^a-z0-9]+/g, "-");
  const statusCalls: [string, string | undefined][] = [];
  const widgetCalls: [string, undefined][] = [];

  // SAFETY: Binding lifecycle hooks read only cwd, hasUI, setStatus and setWidget.
  const ctx = {
    cwd, hasUI,
    ui: {
      setStatus: (key: string, value: string | undefined) => { statusCalls.push([key, value]); },
      setWidget: (key: string, value: undefined) => { widgetCalls.push([key, value]); },
    },
  } as ExtensionContext;

  const { pi, fire } = lifecycle();
  const interval = spyOn(globalThis, "setInterval");
  const clear = spyOn(globalThis, "clearInterval");
  acp(pi);
  cleanups.push(() => {
    fire("session_shutdown", ctx);
    interval.mockRestore();
    clear.mockRestore();
  });

  return {
    cwd, ctx, statusCalls, widgetCalls, interval, clear,
    fire: (name: string) => fire(name, ctx),
    status: () => {
      const raw = statusCalls.at(-1)?.[1];

      return raw === undefined ? undefined : JSON.parse(raw);
    },
    write: (binding: BindingFixture, filename = `${slug}.json`) => {
      fs.mkdirSync(bindingDir, { recursive: true });
      const file = path.join(bindingDir, filename);
      fs.writeFileSync(file, JSON.stringify(binding));

      return file;
    },
    tick: () => {
      expect(interval.mock.calls.length).toBeGreaterThan(0);
      interval.mock.calls.at(-1)![0]();
    },
  };
};

const socket = path.join(stateDir, "pi.sock");

const url = "http://localhost:4000";

describe("pidewave binding status", () => {
  test("absent bindings clear the legacy widget and status without repeated updates", () => {
    const h = bindingHarness();
    h.fire("session_start");
    expect(h.widgetCalls).toEqual([["pidewave", undefined]]);
    expect(h.statusCalls).toEqual([["pidewave", undefined]]);
    h.tick();
    h.fire("before_agent_start");
    expect(h.statusCalls).toHaveLength(1);
  });

  test("exact normalized cwd wins over a conflicting slug filename", () => {
    const h = bindingHarness();
    process.env.PI_SOCKET = socket;
    h.write({ cwd: "/another/worktree", socket: "other.sock", appUrl: "http://wrong.test" });
    h.write({ cwd: `${h.cwd}/../${path.basename(h.cwd)}`, socket, appUrl: url }, `exact-${fixtureId}.json`);
    fs.writeFileSync(path.join(bindingDir, "00-malformed.json"), "{");
    h.fire("session_start");
    expect(h.status()).toEqual({ url, boundHere: true, connected: false });
  });

  test("a malformed exact-cwd binding cannot fall through to a different slug binding", () => {
    const h = bindingHarness();
    h.write({ socket: "other.sock", appUrl: "http://wrong.test" });
    h.write({ cwd: h.cwd, socket: 123, appUrl: url }, `invalid-exact-${fixtureId}.json`);
    h.fire("session_start");
    expect(h.status()).toBeUndefined();
  });

  test("slug fallback works with no exact cwd match and a valid port", () => {
    const h = bindingHarness();
    process.env.PI_SOCKET = socket;
    h.write({ cwd: "/old/location", socket, port: 4321 });
    h.fire("session_start");
    expect(h.status()).toEqual({ url: "http://localhost:4321", boundHere: true, connected: false });
  });

  test.each([0, -1, 65536, 4.5, "4000", null])("rejects invalid fallback port %p", (port) => {
    const h = bindingHarness();
    h.write({ socket, port });
    h.fire("session_start");
    expect(h.status()).toBeUndefined();
  });

  test.each([socket, "other.sock", undefined])("ownership follows PI_SOCKET=%p, not socket existence", (currentSocket) => {
    const h = bindingHarness();

    if (currentSocket === undefined) delete process.env.PI_SOCKET;
    else process.env.PI_SOCKET = currentSocket;
    h.write({ socket, appUrl: url, port: 9999 });
    h.fire("session_start");
    expect(h.status()).toEqual({ url, boundHere: currentSocket === socket, connected: false });
  });

  test.each([undefined, "", 123, null, true, ["pi.sock"], { toString: "pi.sock" }].map((bindingSocket) => ({ bindingSocket })))("requires a nonempty binding socket (%p)", ({ bindingSocket }) => {
    const h = bindingHarness();
    h.write({ socket: bindingSocket, appUrl: url });
    h.fire("session_start");
    expect(h.status()).toBeUndefined();
  });

  test.each([1, 65535])("accepts fallback port boundary %p", (port) => {
    const h = bindingHarness();
    h.write({ socket, port });
    h.fire("session_start");
    expect(h.status()?.url).toBe(`http://localhost:${port}`);
  });

  test.each(["", 123, true, null])("invalid appUrl %p cannot activate a port fallback", (appUrl) => {
    const h = bindingHarness();
    h.write({ socket, appUrl, port: 4000 });
    h.fire("session_start");
    expect(h.status()).toBeUndefined();
  });

  test.each(["null", "[]", '"socket"', "123", "true"])("rejects non-object binding %s", (raw) => {
    const h = bindingHarness();
    fs.writeFileSync(h.write({}), raw);
    h.fire("session_start");
    expect(h.status()).toBeUndefined();
  });

  test("idle polling notices creation, rebind and deletion; shutdown clears its unref timer", () => {
    const h = bindingHarness();
    process.env.PI_SOCKET = socket;
    h.fire("session_start");
    expect(h.interval.mock.calls).toHaveLength(1);
    expect(h.interval.mock.calls[0][1]).toBe(1000);
    const timer = h.interval.mock.results[0].value;
    expect(timer.hasRef()).toBe(false);
    const file = h.write({ socket, appUrl: url });
    h.tick();
    expect(h.status()).toEqual({ url, boundHere: true, connected: false });
    h.tick();
    expect(h.statusCalls).toHaveLength(2);
    h.write({ socket: "other.sock", appUrl: "https://app.test:4443/path" });
    h.tick();
    expect(h.status()).toEqual({ url: "https://app.test:4443/path", boundHere: false, connected: false });
    // Remove it from the binding namespace, retaining the fixture for inspection.
    fs.renameSync(file, `${file}.deleted`);
    h.tick();
    expect(h.status()).toBeUndefined();
    expect(h.statusCalls).toHaveLength(4);
    h.fire("session_shutdown");
    expect(h.clear).toHaveBeenCalledWith(timer);
    expect(h.statusCalls.at(-1)).toEqual(["pidewave", undefined]);
    expect(h.statusCalls).toHaveLength(5);
  });

  test("restart clears the previous poll; headless sessions never poll or touch UI", () => {
    const h = bindingHarness();
    h.fire("session_start");
    const firstTimer = h.interval.mock.results[0].value;
    h.fire("session_start");
    expect(h.clear).toHaveBeenCalledWith(firstTimer);
    const secondTimer = h.interval.mock.results[1].value;
    h.ctx.hasUI = false;
    h.statusCalls.length = 0;
    h.widgetCalls.length = 0;
    h.interval.mockClear();
    h.fire("session_start");
    expect(h.clear).toHaveBeenCalledWith(secondTimer);
    h.fire("before_agent_start");
    h.fire("session_shutdown");
    expect(h.interval).not.toHaveBeenCalled();
    expect(h.statusCalls).toEqual([]);
    expect(h.widgetCalls).toEqual([]);
  });
});

const acpHarness = () => {
  const entry = path.join(stateDir, "acp.ts");
  fs.copyFileSync(fileURLToPath(new URL("../agent/extensions/acp.ts", import.meta.url)), entry);

  const child = spawn(process.execPath, [entry], {
    cwd: stateDir,
    env: { ...process.env, PI_STATE_DIR: stateDir },
    stdio: ["pipe", "pipe", "pipe"],
  });

  const lines = createInterface({ input: child.stdout });
  const output = lines[Symbol.asyncIterator]();

  cleanups.push(async () => {
    lines.close();

    if (child.exitCode === null && child.signalCode === null) {
      const exited = once(child, "exit");
      child.kill();
      await exited;
    }
  });

  return {
    send: (text: string) => child.stdin.write(`${text}\n`),
    read: async () => {
      const line = await output.next();
      expect(line.done).toBe(false);

      return JSON.parse(line.value!);
    },
  };
};

describe("standalone ACP boundaries", () => {
  test("initializes without Pi runtime imports and ignores malformed envelopes and notifications", async () => {
    const cli = acpHarness();

    for (const line of ["{", "null", "[]", "123", '{"method":1}', '{"method":"initialize","id":{}}',
      '{"method":"initialize"}', '{"method":"session/cancel","id":91}', '{"method":"$/cancel","id":92}']) {
      cli.send(line);
    }

    cli.send(JSON.stringify({ id: 1, method: "initialize", params: { protocolVersion: 99 } }));
    expect(await cli.read()).toMatchObject({ jsonrpc: "2.0", id: 1, result: {
      protocolVersion: 1, authMethods: [], agentCapabilities: { loadSession: false },
    } });
    cli.send(JSON.stringify({ id: "auth", method: "authenticate" }));
    expect(await cli.read()).toEqual({ jsonrpc: "2.0", id: "auth", result: {} });

    for (const method of ["unsupported", "toString", "constructor", "__proto__"]) {
      cli.send(JSON.stringify({ id: method, method }));
      expect(await cli.read()).toMatchObject({ id: method, error: { code: -32601 } });
    }

    cli.send(JSON.stringify({ id: 2, method: "session/prompt", params: { sessionId: 123 } }));
    expect(await cli.read()).toMatchObject({ id: 2, error: { code: -32602 } });
  });

  test.each(['{"ok":true}', '{"ok":false,"error":"denied"}', '{"ok":"true"}', "null", "{"])(
    "forwards decoded content and handles bridge response %s", async (response) => {
      const h = bindingHarness();
      const socketPath = path.join(stateDir, `bridge-${fixtureId}.sock`);
      const requests: string[] = [];

      const server = net.createServer((peer) => {
        let buffer = "";
        peer.on("data", (chunk) => {
          buffer += chunk.toString();

          if (!buffer.includes("\n")) return;

          requests.push(buffer.trim());
          peer.end(`${response}\n`);
        });
      });

      server.listen(socketPath);
      await once(server, "listening");
      cleanups.push(() => new Promise<void>((resolve) => { server.close(() => resolve()); }));
      h.write({ socket: socketPath, cwd: h.cwd, appUrl: url });
      const cli = acpHarness();
      cli.send(JSON.stringify({ id: 1, method: "session/new", params: { cwd: h.cwd } }));
      const session = await cli.read();
      const sessionId = session.result.sessionId;
      expect(sessionId).toStartWith("pidewave-");
      cli.send(JSON.stringify({ id: 2, method: "session/prompt", params: { sessionId, prompt: [
        { type: "text", text: "hello" }, { type: "resource_link", uri: "file:///link" },
        { type: "resource", resource: { text: "context" } },
        { type: "resource", resource: { uri: "file:///embedded" } },
        null, 123, { type: "text", text: 123 }, { type: "resource", resource: { text: { invalid: true } } },
      ] } }));
      const update = await cli.read();
      expect(update).toMatchObject({ method: "session/update", params: {
        sessionId, update: { sessionUpdate: "agent_message_chunk", content: { type: "text" } },
      } });
      const detail = update.params.update.content.text;
      expect(detail).toContain(response === '{"ok":true}' ? "Forwarded" : response.includes("denied") ? "denied" : "did not accept");
      expect(await cli.read()).toMatchObject({ id: 2, result: { stopReason: "end_turn" } });
      expect(requests).toHaveLength(1);
      expect(JSON.parse(requests[0])).toMatchObject({
        type: "control", protocol: "pi.control.v1", operation: "message.send",
        params: { text: "hello\nfile:///link\ncontext\nfile:///embedded", mode: "follow_up", from: "tidewave" },
      });

      cli.send(JSON.stringify({ id: 3, method: "session/prompt", params: { sessionId, prompt: [{ type: "text", text: false }] } }));
      expect((await cli.read()).params.update.content.text).toContain("Empty prompt");
      expect(await cli.read()).toMatchObject({ id: 3, result: { stopReason: "end_turn" } });
      expect(requests).toHaveLength(1);
    },
  );
});

const colors = new Map([["accent", "\x1b[36m"], ["muted", "\x1b[90m"], ["success", "\x1b[32m"]]);

const theme = {
  fg: (name: string, text: string) => `${colors.get(name) || "\x1b[37m"}${text}\x1b[0m`,
  bold: (text: string) => `\x1b[1m${text}\x1b[22m`,
};

const footerHarness = (statuses: Map<string, string>) => {
  const { pi, fire } = lifecycle();
  let component: { render(width: number): string[]; dispose(): void };
  const guardKey = Symbol.for("pi.mcp-error-guard.state");
  const originalGuard = Object.getOwnPropertyDescriptor(globalThis, guardKey);
  const originalError = console.error;

  // SAFETY: Rendering uses only these context fields; UI callbacks receive real footer code.
  const ctx = {
    // A missing cwd makes the asynchronous starship spawn fail without executing it.
    cwd: path.join(stateDir, "missing-footer-cwd"), hasUI: true,
    sessionManager: { getSessionName: () => "", getEntries: () => [] },
    getContextUsage: () => ({ tokens: 0, contextWindow: 1000, percent: 0 }),
    model: { provider: "test", id: "test-model", reasoning: false },
    ui: {
      setStatus: () => {},
      setFooter: (factory: Function) => {
        component = factory({ requestRender: () => {} }, theme, {
          getExtensionStatuses: () => statuses,
          onBranchChange: () => () => {},
        });
      },
    },
  } as ExtensionContext;

  cleanups.push(() => {
    component?.dispose();
    fire("session_shutdown", ctx);
    console.error = originalError;

    if (originalGuard) Object.defineProperty(globalThis, guardKey, originalGuard);
    else Reflect.deleteProperty(globalThis, guardKey);
  });
  customFooter(pi);
  fire("session_start", ctx);

  return (width = 240) => component.render(width);
};

const status = (boundHere = true, appUrl = "https://app.test:4443/path?query=hidden#fragment", connected?: boolean) =>
  JSON.stringify({ url: appUrl, boundHere, connected });

describe("pidewave footer rendering", () => {
  test.each([true, false])("URL occurs once, first among extension statuses, boundHere=%p", (boundHere) => {
    const render = footerHarness(new Map([
      ["pidewave", status(boundHere)], ["mcp-other", "1/2"],
      ["n-status", "between"], ["mcp", "MCP: 2/3"],
    ]));

    const line = render()[1];
    const plain = stripVTControlCharacters(line);
    expect(plain).toContain("https://app.test:4443 │  2/3 │  1/2 │ between");
    expect(plain.match(/https:\/\/app\.test:4443/g)).toHaveLength(1);
    expect(line).toContain(theme.fg(boundHere ? "accent" : "muted", "https://app.test:4443"));
    expect(plain).not.toContain("query");
    expect(plain).not.toContain("boundHere");
  });

  test.each([true, false])("URL ownership color ignores zero live MCP servers, boundHere=%p", (boundHere) => {
    const line = footerHarness(new Map([["mcp", "MCP 0/3"], ["pidewave", status(boundHere)]]))()[1];
    expect(stripVTControlCharacters(line)).toContain("https://app.test:4443 │  0/3");
    expect(line).toContain(theme.fg(boundHere ? "accent" : "muted", "https://app.test:4443"));
  });

  test.each([undefined, "MCP connecting...", "MCP: 2 servers enabled (1 connected)"])(
    "shows URL even when canonical MCP is absent or unparsed (%p)", (mcp) => {
      const statuses = new Map([["pidewave", status(false, url, true)]]);

      if (mcp !== undefined) statuses.set("mcp", mcp);
      const line = footerHarness(statuses)()[1];
      expect(line).toContain(theme.fg("success", url));
      expect(stripVTControlCharacters(line)).not.toContain("boundHere");
    },
  );

  test("connected overrides binding ownership color", () => {
    const line = footerHarness(new Map([["pidewave", status(true, url, true)]]))()[1];
    expect(line).toContain(theme.fg("success", url));
  });

  test.each([
    "{", "null", "[]", "{}", JSON.stringify({ url, boundHere: "true" }),
    JSON.stringify({ url: 4000, boundHere: true }),
    JSON.stringify({ url, boundHere: true, connected: "yes" }),
    status(true, "not a URL"), status(true, "ftp://app.test"),
    status(true, "javascript:alert(1)"), status(true, "file:///tmp/app"),
    status(true, "https://user:secret@app.test"), status(true, "http://user@app.test"),
    status(true, "http://:secret@app.test"),
  ])("suppresses invalid status %p without leaking raw data", (invalid) => {
    const statuses = new Map([["mcp", "MCP 2/3"]]);
    const render = footerHarness(statuses);
    const withoutStatus = render();
    statuses.set("pidewave", invalid);
    expect(render()).toEqual(withoutStatus);
    statuses.delete("mcp");
    statuses.delete("pidewave");
    const standalone = render();
    statuses.set("pidewave", invalid);
    expect(render()).toEqual(standalone);
  });

  test("normalizes HTTP origins and stays within narrow terminal widths", () => {
    const render = footerHarness(new Map([["mcp", "MCP 2/3"], ["pidewave", status(true, "http://LOCALHOST:80/path")]]));
    expect(stripVTControlCharacters(render()[1])).toContain("http://localhost │  2/3");

    for (const width of [1, 2, 3, 8, 16, 30, 40, 60, 80]) {
      const lines = render(width);
      expect(lines).toHaveLength(2);

      for (const line of lines) expect(visibleWidth(line)).toBeLessThanOrEqual(width);
      expect(stripVTControlCharacters(lines.join("\n"))).not.toContain("boundHere");
    }
  });
});
