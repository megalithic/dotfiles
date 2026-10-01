import { afterEach, describe, expect, spyOn, test } from "bun:test";
import type { ExtensionAPI, ExtensionContext, McpServerConfig } from "@earendil-works/pi-coding-agent";
import fs from "node:fs";
import path from "node:path";

// Isolate ACP's module-time binding directory from the footer suite's environment.
// Kept under tests/ so the copy still resolves @earendil-works/pi-coding-agent.
const extensionCopy = path.join(fs.mkdtempSync(path.join(import.meta.dirname, ".pidewave-extension-")), "acp.ts");

fs.copyFileSync(new URL("../agent/extensions/acp.ts", import.meta.url), extensionCopy);

process.on("exit", () => fs.rmSync(path.dirname(extensionCopy), { recursive: true, force: true }));

const { default: acp } = await import(extensionCopy);

const ENDPOINT = "pidewave:endpoint:v1";

const PING_INTERVAL_MS = 10_000;

const url = "http://localhost:4300/tidewave/mcp";

const originalEnv = { ...process.env };

const cleanups: (() => void | Promise<void>)[] = [];

// Real intervals still run; every harness clears its own on shutdown.
const intervals = spyOn(globalThis, "setInterval");

afterEach(async () => {
  for (const cleanup of cleanups.splice(0).reverse()) await cleanup();
  process.env = { ...originalEnv };
});

type Hook = (event: { reason?: string }, ctx: ExtensionContext) => void | Promise<void>;

type CommandHandler = (args: string, ctx: ExtensionContext) => Promise<void>;

type Probe = { url: string; pings: number; closed: number; ping(): Promise<void>; close(): Promise<void> };

type EndpointEvent = { version: number; endpoint?: { origin: string; pathname: string } };

type CommandUi = { notify(text: string): void; select?(title: string, options: string[]): Promise<string> };

type Entry = { event: string; at: string; [key: string]: string | boolean | undefined };

type ConfigFixture = null | {
  pidewave?: { url: string | number | null };
  mcpServers?: { tidewave: { url: string } };
};

const eventBus = () => {
  const listeners = new Map<string, Set<(data: EndpointEvent) => void>>();
  const publications: EndpointEvent[] = [];

  const emit = (name: string, data: EndpointEvent) => {
    if (name === ENDPOINT) publications.push(data);

    for (const listener of listeners.get(name) ?? []) listener(data);
  };

  const on = (name: string, listener: (data: EndpointEvent) => void) => {
    if (!listeners.has(name)) listeners.set(name, new Set());
    listeners.get(name)!.add(listener);

    return () => { listeners.get(name)!.delete(listener); };
  };

  return { publications, emit, on };
};

const harness = (options: {
  trusted?: boolean; hasUI?: boolean; cwd?: string; bus?: ReturnType<typeof eventBus>;
  // Whether Tidewave answers connects and pings.
  up?: boolean;
  // Make registerMcpServer throw, as Pi does for invalid or foreign names.
  refuse?: boolean;
} = {}) => {
  const cwd = options.cwd ?? fs.mkdtempSync("/tmp/pidewave-endpoint-");
  const file = path.join(cwd, ".pi", "mcp.json");
  const hooks = new Map<string, Hook>();
  const bus = options.bus ?? eventBus();
  const registrations: [string, McpServerConfig][] = [];
  const unregistrations: string[] = [];
  const notices: string[] = [];
  const entries: [string, Entry][] = [];
  const commands = new Map<string, CommandHandler>();
  const probes: Probe[] = [];
  const connects: string[] = [];
  const firstInterval = intervals.mock.calls.length;
  let up = options.up ?? true;
  let gate: Promise<void> | undefined;

  const connect = async (target: URL): Promise<Probe> => {
    connects.push(target.href);

    if (gate) await gate;

    if (!up) throw new Error("connect refused secret=do-not-print");

    const probe: Probe = {
      url: target.href, pings: 0, closed: 0,
      ping: async () => {
        probe.pings += 1;

        if (!up) throw new Error("ping failed secret=do-not-print");
      },
      close: async () => { probe.closed += 1; },
    };

    probes.push(probe);

    return probe;
  };

  // SAFETY: Exercise only lifecycle hooks, commands, the shared event bus and the MCP registration API.
  const pi = {
    on: (name: string, hook: Hook) => hooks.set(name, hook),
    events: { on: bus.on, emit: bus.emit },
    registerCommand: (name: string, command: { handler: CommandHandler }) => { commands.set(name, command.handler); },
    registerMcpServer: (name: string, config: McpServerConfig) => {
      if (options.refuse) throw new Error('MCP server "tidewave" is already registered by extension "/secret/do-not-print.ts"');
      registrations.push([name, structuredClone(config)]);
    },
    unregisterMcpServer: (name: string) => { unregistrations.push(name); },
    appendEntry: (type: string, data: Entry) => { entries.push([type, data]); },
  } as ExtensionAPI;

  // SAFETY: Endpoint and footer hooks only use these context fields.
  const ctx = {
    cwd, hasUI: options.hasUI ?? false,
    isProjectTrusted: () => options.trusted ?? true,
    ui: {
      notify: (text: string) => notices.push(text), setWidget: () => {}, setStatus: () => {},
    },
  } as ExtensionContext;

  acp(pi, connect);
  const fire = (name: string, event: { reason?: string } = {}) => hooks.get(name)?.(event, ctx);
  cleanups.push(async () => { await fire("session_shutdown"); });

  return {
    pi, ctx, bus, file, registrations, unregistrations, notices, entries, commands, probes, connects, fire,
    // Let connect/ping promises resolve.
    settle: async () => { for (let i = 0; i < 5; i += 1) await new Promise((resolve) => setImmediate(resolve)); },
    write: (config: ConfigFixture = { pidewave: { url } }) => {
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, JSON.stringify(config));
    },
    setUp: (value: boolean) => { up = value; },
    // Hold connects until released, to interleave shutdown with a pending connect.
    hold: () => {
      let release!: () => void;
      gate = new Promise<void>((resolve) => { release = resolve; });

      return () => { gate = undefined; release(); };
    },
    // Run the ping monitor's interval callback once.
    tick: async () => {
      const call = intervals.mock.calls.slice(firstInterval).filter(([, delay]) => delay === PING_INTERVAL_MS).at(-1);

      expect(call).toBeDefined();
      call![0]();

      for (let i = 0; i < 5; i += 1) await new Promise((resolve) => setImmediate(resolve));
    },
    // SAFETY: The command handler reads only cwd, trust, and the notify/select UI members supplied here.
    pidewave: (ui: CommandUi = ctx.ui) => commands.get("pidewave")!("", { ...ctx, ui } as ExtensionContext),
    endpoint: () => bus.publications.at(-1),
  };
};

const published = (origin = "http://localhost:4300") => ({ version: 1, endpoint: { origin, pathname: "/tidewave/mcp" } });

const registration = (href = url) => ["tidewave", { url: href, exposure: "direct" }];

describe("Pidewave native endpoint", () => {
  test("absent configuration and legacy mcpServers never register", () => {
    for (const config of [undefined, {}, { mcpServers: { tidewave: { url } } }, null]) {
      const h = harness();

      if (config !== undefined) h.write(config);
      h.fire("session_start");
      expect(h.registrations).toEqual([]);
      expect(h.endpoint()).toEqual({ version: 1 });
    }
  });

  test("project trust is checked before reading configuration", () => {
    const h = harness({ trusted: false });
    h.write();
    const read = spyOn(fs, "readFileSync");

    try {
      h.fire("session_start");
      expect(read).not.toHaveBeenCalled();
      expect(h.registrations).toEqual([]);
    } finally { read.mockRestore(); }
  });

  test("missing project trust API fails closed", () => {
    const h = harness();
    h.write();
    Reflect.deleteProperty(h.ctx, "isProjectTrusted");
    h.fire("session_start");
    expect(h.registrations).toEqual([]);
    expect(h.endpoint()).toEqual({ version: 1 });
  });

  test.each([
    "http://example.com:4300/tidewave/mcp", "http://127.1:4300/tidewave/mcp",
    "http://2130706433:4300/tidewave/mcp", "http://LOCALHOST:4300/tidewave/mcp",
    "http://localhost.:4300/tidewave/mcp", "http://[::1]:4300/tidewave/mcp",
    "http://user:secret@localhost:4300/tidewave/mcp", "http://localhost:4300/tidewave/mcp?secret=1",
    "http://localhost:4300/tidewave/mcp#secret", "http://localhost:4300/tidewave/mcp?",
    "http://localhost:4300/tidewave/mcp#", "http://localhost:4300/other",
    "http://localhost:4300/a/../tidewave/mcp", "http://localhost:4300/tidewave/mcp/",
    "http://localhost:0/tidewave/mcp", "http://localhost:65536/tidewave/mcp",
    "http://localhost:9832/tidewave/mcp", "http://localhost:04300/tidewave/mcp",
    "http://localhost:80/tidewave/mcp", "http://localhost:/tidewave/mcp",
    "http://localhost:4300/tidewave/%6dcp", "http://localhost:4300/tidewave/mcp\n",
    "ftp://localhost:4300/tidewave/mcp", "file:///tidewave/mcp", "!echo secret",
    "", 123, null,
  ])("rejects unsafe/noncanonical endpoint %p", (unsafe) => {
    const h = harness({ hasUI: true });
    h.write({ pidewave: { url: unsafe } });
    h.fire("session_start");
    expect(h.registrations).toEqual([]);
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.notices).toHaveLength(1);
    expect(h.notices[0]).toMatch(/^Pidewave endpoint unavailable: (Unsafe Pidewave endpoint|Invalid Pidewave configuration|unreadable \.pi\/mcp\.json or endpoint URL)\.$/);
    const text = String(unsafe ?? "");

    if (text.length > 3) expect(h.notices.join()).not.toContain(text);
  });

  test("a configured tidewave server shadows the registration and is refused", () => {
    const h = harness({ hasUI: true });
    h.write({ pidewave: { url }, mcpServers: { tidewave: { url: "http://localhost:4400/tidewave/mcp" } } });
    h.fire("session_start");
    expect(h.registrations).toEqual([]);
    expect(h.notices).toEqual(["Pidewave endpoint unavailable: Configured tidewave server shadows Pidewave."]);
  });

  test.each(["http://localhost:1", "https://127.0.0.1:65535", "http://localhost", "https://127.0.0.1"])("accepts canonical origin %s", async (origin) => {
    const h = harness();
    h.write({ pidewave: { url: `${origin}/tidewave/mcp` } });
    h.fire("session_start");
    expect(h.registrations).toEqual([registration(`${origin}/tidewave/mcp`)]);
    await h.settle();
    expect(h.endpoint()).toEqual(published(origin));
  });

  test.each(["${PIDEWAVE_TEST_PORT}", "$env:PIDEWAVE_TEST_PORT", "{env:PIDEWAVE_TEST_PORT}"])("freezes interpolation %s at registration", async (expression) => {
    process.env.PIDEWAVE_TEST_PORT = "4300";
    const h = harness();
    h.write({ pidewave: { url: `http://localhost:${expression}/tidewave/mcp` } });
    h.fire("session_start");
    expect(h.registrations).toEqual([registration()]);
    process.env.PIDEWAVE_TEST_PORT = "4400";
    h.write({ pidewave: { url: "http://localhost:4500/tidewave/mcp" } });
    h.fire("before_agent_start");
    h.fire("session_start");
    await h.settle();
    expect(h.registrations).toHaveLength(1);
    expect(h.connects).toEqual([url]);
    expect(h.endpoint()).toEqual(published());
  });

  test.each([undefined, ""])("rejects missing/empty environment value %p", (value) => {
    if (value === undefined) delete process.env.PIDEWAVE_TEST_PORT;
    else process.env.PIDEWAVE_TEST_PORT = value;

    for (const expression of ["${PIDEWAVE_TEST_PORT}", "$env:PIDEWAVE_TEST_PORT", "{env:PIDEWAVE_TEST_PORT}"]) {
      const h = harness();
      h.write({ pidewave: { url: `http://localhost:${expression}/tidewave/mcp` } });
      h.fire("session_start");
      expect(h.registrations).toEqual([]);
      expect(h.endpoint()).toEqual({ version: 1 });
    }
  });

  test("malformed JSON reports no raw configuration", () => {
    const h = harness({ hasUI: true });
    h.write();
    fs.writeFileSync(h.file, '{"secret":"do-not-print"');
    h.fire("session_start");
    expect(h.registrations).toEqual([]);
    expect(h.notices.join()).not.toContain("do-not-print");
    expect(h.notices).toHaveLength(1);
  });

  test("a refused registration fails closed and names neither Pi's error nor its path", async () => {
    const h = harness({ hasUI: true, refuse: true });
    h.write();
    h.fire("session_start");
    await h.settle();
    expect(h.notices).toEqual(["Pidewave endpoint unavailable: MCP registration refused."]);
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.connects).toEqual([]);
    expect(h.entries).toEqual([
      ["pidewave", expect.objectContaining({ event: "unavailable", reason: "MCP registration refused", trusted: true })],
    ]);
    expect(JSON.stringify([h.notices, h.entries])).not.toContain("do-not-print");
    await h.fire("session_shutdown");
    expect(h.unregistrations).toEqual([]);
  });

  test("publishes only after a successful ping, revokes on failure, and reconnects on the next tick", async () => {
    const h = harness({ up: false });
    h.write();
    h.fire("session_start");
    expect(h.endpoint()).toEqual({ version: 1 });
    await h.settle();
    expect(h.connects).toEqual([url]);
    expect(h.endpoint()).toEqual({ version: 1 });

    h.setUp(true);
    await h.tick();
    expect(h.connects).toHaveLength(2);
    expect(h.probes).toHaveLength(1);
    expect(h.probes[0].pings).toBe(1);
    expect(h.endpoint()).toEqual(published());

    await h.tick();
    expect(h.connects).toHaveLength(2); // The session is reused while pings succeed.
    expect(h.probes[0].pings).toBe(2);

    h.setUp(false);
    await h.tick();
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.probes[0].closed).toBe(1);

    h.setUp(true);
    await h.tick();
    expect(h.connects).toHaveLength(3);
    expect(h.endpoint()).toEqual(published());
    expect(h.entries.map(([, data]) => [data.event, data.status, data.url])).toEqual([
      ["registered", undefined, "http://localhost:4300"],
      ["status", "connected", "http://localhost:4300"],
      ["status", "unreachable", "http://localhost:4300"],
      ["status", "connected", "http://localhost:4300"],
    ]);
    expect(JSON.stringify(h.entries)).not.toContain("do-not-print");
  });

  test("endpoint work survives a pi without appendEntry", async () => {
    const h = harness({ hasUI: true });
    Reflect.deleteProperty(h.pi, "appendEntry");
    h.write();
    h.fire("session_start");
    await h.settle();
    expect(h.registrations).toHaveLength(1);
    expect(h.endpoint()).toEqual(published());
    expect(h.notices).toEqual([]);
  });

  test("shutdown revokes first, unregisters once, closes the probe, and ignores a late connect", async () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    await h.settle();
    expect(h.endpoint()).toEqual(published());
    const stopping = h.fire("session_shutdown");
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.unregistrations).toEqual(["tidewave"]);
    await stopping;
    expect(h.probes[0].closed).toBe(1);

    const late = harness({ bus: h.bus });
    late.write();
    const release = late.hold();
    late.fire("session_start");
    expect(late.connects).toEqual([url]);
    await late.fire("session_shutdown");
    release();
    await late.settle();
    expect(late.probes).toHaveLength(1);
    expect(late.probes[0].closed).toBe(1);
    expect(late.probes[0].pings).toBe(0);
    expect(late.endpoint()).toEqual({ version: 1 });

    process.env.PIDEWAVE_TEST_PORT = "4400";
    const next = harness({ bus: h.bus });
    next.write({ pidewave: { url: "http://localhost:${PIDEWAVE_TEST_PORT}/tidewave/mcp" } });
    next.fire("session_start", { reason: "reload" });
    await next.settle();
    expect(next.endpoint()).toEqual(published("http://localhost:4400"));
  });

  test("a probe close failure is contained", async () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    await h.settle();

    h.probes[0].close = async () => { throw new Error("already closed"); };

    await h.fire("session_shutdown");

    expect(h.endpoint()).toEqual({ version: 1 });
  });

  describe("/pidewave", () => {
    test("re-registers, pings, and confirms the connection", async () => {
      const h = harness();
      h.write();
      h.fire("session_start");
      await h.settle();
      await h.pidewave();
      expect(h.unregistrations).toEqual(["tidewave"]);
      expect(h.registrations).toEqual([registration(), registration()]);
      expect(h.probes).toHaveLength(2);
      expect(h.probes[0].closed).toBe(1);
      expect(h.endpoint()).toEqual(published());
      expect(h.notices).toEqual(["Pidewave: Tidewave connected at http://localhost:4300."]);
    });

    test("reports an unreachable Tidewave without exposing the error", async () => {
      const h = harness({ up: false });
      h.write();
      h.fire("session_start");
      await h.settle();
      await h.pidewave();
      expect(h.endpoint()).toEqual({ version: 1 });
      expect(h.notices).toEqual([
        "Pidewave: Tidewave did not answer at http://localhost:4300; start Phoenix there with `mise run start:server`.",
      ]);
    });

    test("picks up a changed URL", async () => {
      process.env.PIDEWAVE_TEST_PORT = "4300";
      const h = harness();
      h.write({ pidewave: { url: "http://localhost:${PIDEWAVE_TEST_PORT}/tidewave/mcp" } });
      h.fire("session_start");
      await h.settle();
      process.env.PIDEWAVE_TEST_PORT = "4400";
      await h.pidewave();
      expect(h.registrations.at(-1)).toEqual(registration("http://localhost:4400/tidewave/mcp"));
      expect(h.endpoint()).toEqual(published("http://localhost:4400"));
    });

    test("without a pidewave.url it warns and leaves the registration alone", async () => {
      const h = harness();
      h.fire("session_start");
      await h.pidewave();
      expect(h.unregistrations).toEqual([]);
      expect(h.notices).toEqual(["Pidewave: no pidewave.url in .pi/mcp.json; run `mise run bootstrap` to generate it."]);
    });

    test("an unsafe pidewave.url is reported without re-registering", async () => {
      const h = harness();
      h.write({ pidewave: { url: "http://evil.example/tidewave/mcp" } });
      h.fire("session_start");
      await h.pidewave();
      expect(h.registrations).toEqual([]);
      expect(h.notices.at(-1)).toBe("Pidewave: Unsafe Pidewave endpoint.");
    });

    test("a refused registration is reported once", async () => {
      const h = harness({ hasUI: true, refuse: true });
      h.write();
      h.fire("session_start");

      h.notices.length = 0;
      await h.pidewave();
      expect(h.notices).toEqual(["Pidewave endpoint unavailable: MCP registration refused."]);
    });

    test("an untrusted project offers to save trust and asks for a restart", async () => {
      const h = harness({ trusted: false });
      h.write();
      h.fire("session_start");
      const agentDir = fs.mkdtempSync("/tmp/pidewave-agent-");
      process.env.PI_CODING_AGENT_DIR = agentDir;
      let prompt: string | undefined;

      await h.pidewave({
        notify: (text: string) => h.notices.push(text),
        select: async (title: string) => {
          prompt = title;

          return "Trust this folder";
        },
      });
      expect(h.registrations).toEqual([]);
      expect(prompt).toContain(h.ctx.cwd);
      expect(JSON.parse(fs.readFileSync(path.join(agentDir, "trust.json"), "utf8"))).toEqual({ [fs.realpathSync(h.ctx.cwd)]: true });
      expect(h.notices.at(-1)).toBe(`Pidewave: trusted ${path.resolve(h.ctx.cwd)}. Restart Pi, then run /pidewave again.`);
    });

    test("declining trust leaves the store alone", async () => {
      const h = harness({ trusted: false });
      h.fire("session_start");
      const agentDir = fs.mkdtempSync("/tmp/pidewave-agent-");
      process.env.PI_CODING_AGENT_DIR = agentDir;
      await h.pidewave({ notify: (text: string) => h.notices.push(text), select: async () => "Cancel" });
      expect(fs.existsSync(path.join(agentDir, "trust.json"))).toBe(false);
      expect(h.notices.at(-1)).toBe("Pidewave: project is not trusted, so no Tidewave endpoint can be registered.");
    });
  });

  test("footer status shows the registered origin only while Tidewave answers", async () => {
    const h = harness({ hasUI: true, up: false });
    const statuses: (string | undefined)[] = [];

    h.ctx.ui.setStatus = (key: string, value: string | undefined) => { if (key === "pidewave") statuses.push(value); };

    h.write();
    h.fire("session_start");
    await h.settle();
    h.fire("before_agent_start");
    expect(statuses.at(-1)).toBeUndefined();
    h.setUp(true);
    await h.tick();
    expect(JSON.parse(statuses.at(-1)!)).toEqual({ url: "http://localhost:4300", boundHere: false, connected: true });
    h.setUp(false);
    await h.tick();
    expect(statuses.at(-1)).toBeUndefined();
  });
});
