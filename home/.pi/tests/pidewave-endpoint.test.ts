import { afterEach, describe, expect, mock, spyOn, test } from "bun:test";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import fs from "node:fs";
import path from "node:path";

// Isolate ACP's module-time binding directory from the footer suite's environment.
const extensionCopy = path.join(fs.mkdtempSync("/tmp/pidewave-extension-"), "acp.ts");

fs.copyFileSync(new URL("../agent/extensions/acp.ts", import.meta.url), extensionCopy);

const { default: acp } = await import(extensionCopy);

const REGISTER = "pi-mcp-adapter:runtime-register:v1";

const SNAPSHOT = "pi-mcp-adapter:runtime-snapshot:v1";

const STATUS = "pi-mcp-adapter/status/v1";

const ENDPOINT = "pidewave:endpoint:v1";

const url = "http://localhost:4300/tidewave/mcp";

const originalEnv = { ...process.env };

const cleanups: (() => void | Promise<void>)[] = [];

afterEach(async () => {
  for (const cleanup of cleanups.splice(0).reverse()) await cleanup();
  process.env = { ...originalEnv };
});

type Request = {
  version: number;
  name: string;
  definition?: { httpTransport: string; url: string; lifecycle: string };
  result?: unknown;
};

type Hook = (event: { reason?: string }, ctx: ExtensionContext) => void | Promise<void>;

type SnapshotFixture = {
  name?: string;
  definition?: { url?: string };
  runtime?: boolean;
  persisted?: boolean;
};

type ConfigFixture = null | {
  pidewave?: { url: string | number | null };
  mcpServers?: { tidewave: { url: string } };
};

const eventBus = () => {
  const listeners = new Map<string, Set<(data: Request) => void>>();
  const publications: unknown[] = [];

  const emit = (name: string, data: Request) => {
    if (name === ENDPOINT) publications.push(data);

    for (const listener of listeners.get(name) ?? []) listener(data);
  };

  const on = (name: string, listener: (data: Request) => void) => {
    if (!listeners.has(name)) listeners.set(name, new Set());
    listeners.get(name)!.add(listener);

    return () => { listeners.get(name)!.delete(listener); };
  };

  return { listeners, publications, emit, on };
};

const harness = (options: {
  trusted?: boolean; hasUI?: boolean; adapter?: boolean; active?: boolean;
  bus?: ReturnType<typeof eventBus>;
} = {}) => {
  const cwd = fs.mkdtempSync("/tmp/pidewave-endpoint-");
  const file = path.join(cwd, ".pi", "mcp.json");
  const hooks = new Map<string, Hook>();
  const bus = options.bus ?? eventBus();
  const { listeners, publications, emit, on } = bus;
  const requests: Request[] = [];
  const notices: string[] = [];
  const dispose = mock(async () => {});
  const adapterUnsubscribers: (() => void)[] = [];
  let snapshot: SnapshotFixture | undefined;
  let registrationFailure = false;
  let snapshotAvailable = true;

  if (options.adapter !== false) {
    adapterUnsubscribers.push(on(REGISTER, (request) => {
      requests.push(structuredClone(request));
      request.result = registrationFailure
        ? { ok: false, error: new Error("duplicate server secret=do-not-print") }
        : { ok: true, registration: { dispose } };

      if (options.active !== false) snapshot = {
        name: "tidewave", definition: request.definition, runtime: true, persisted: false,
      };
    }));
    adapterUnsubscribers.push(on(SNAPSHOT, (request) => {
      if (snapshotAvailable) request.result = snapshot
        ? { ok: true, snapshot }
        : { ok: false, error: new Error("no active state secret=do-not-print") };
    }));
  }

  // SAFETY: Exercise only lifecycle hooks and the synchronous shared event contract.
  const pi = { on: (name: string, hook: Hook) => hooks.set(name, hook), events: { on, emit } } as ExtensionAPI;

  // SAFETY: Endpoint and footer hooks only use these context fields.
  const ctx = {
    cwd, hasUI: options.hasUI ?? false,
    isProjectTrusted: () => options.trusted ?? true,
    ui: {
      notify: (text: string) => notices.push(text), setWidget: () => {}, setStatus: () => {},
    },
  } as ExtensionContext;

  acp(pi);
  const fire = (name: string) => hooks.get(name)?.({}, ctx);
  cleanups.push(async () => { await fire("session_shutdown"); });

  return {
    pi, ctx, requests, publications, notices, dispose, file, fire, bus,
    stopAdapter: () => { for (const off of adapterUnsubscribers.splice(0)) off(); },
    write: (config: ConfigFixture = { pidewave: { url } }) => {
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, JSON.stringify(config));
    },
    status: () => emit(STATUS, { version: 1, name: "unused" }),
    snapshot: (value: SnapshotFixture | undefined) => { snapshot = value; },
    noSnapshot: () => { snapshotAvailable = false; },
    failRegistration: () => { registrationFailure = true; },
    statusListeners: () => [...(listeners.get(STATUS) ?? [])],
    endpoint: () => publications.at(-1),
  };
};

const published = (origin = "http://localhost:4300") => ({ version: 1, endpoint: { origin, pathname: "/tidewave/mcp" } });

const owned = (definitionUrl = url) => ({ name: "tidewave", definition: { url: definitionUrl }, runtime: true, persisted: false });

describe("Pidewave runtime endpoint", () => {
  test("absent configuration and legacy mcpServers never register", () => {
    for (const config of [undefined, {}, { mcpServers: { tidewave: { url } } }, null]) {
      const h = harness();

      if (config !== undefined) h.write(config);
      h.fire("session_start");
      expect(h.requests).toEqual([]);
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
      expect(h.requests).toEqual([]);
    } finally { read.mockRestore(); }
  });

  test("missing project trust API fails closed", () => {
    const h = harness();
    h.write();
    Reflect.deleteProperty(h.ctx, "isProjectTrusted");
    h.fire("session_start");
    expect(h.requests).toEqual([]);
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
    expect(h.requests).toEqual([]);
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.notices).toEqual(["Pidewave endpoint unavailable; check project configuration and MCP registration."]);
  });

  test.each(["http://localhost:1", "https://127.0.0.1:65535", "http://localhost", "https://127.0.0.1"])("accepts canonical origin %s", (origin) => {
    const h = harness();
    h.write({ pidewave: { url: `${origin}/tidewave/mcp` } });
    h.fire("session_start");
    expect(h.endpoint()).toEqual(published(origin));
  });

  test.each(["${PIDEWAVE_TEST_PORT}", "$env:PIDEWAVE_TEST_PORT", "{env:PIDEWAVE_TEST_PORT}"])("freezes interpolation %s at registration", (expression) => {
    process.env.PIDEWAVE_TEST_PORT = "4300";
    const h = harness();
    h.write({ pidewave: { url: `http://localhost:${expression}/tidewave/mcp` } });
    h.fire("session_start");
    expect(h.requests).toEqual([{ version: 1, name: "tidewave", definition: {
      httpTransport: "streamable-http", url, lifecycle: "keep-alive",
    } }]);
    process.env.PIDEWAVE_TEST_PORT = "4400";
    h.write({ pidewave: { url: "http://localhost:4500/tidewave/mcp" } });
    h.fire("before_agent_start");
    h.fire("session_start");
    h.status();
    expect(h.requests).toHaveLength(1);
    expect(h.endpoint()).toEqual(published());
  });

  test.each([undefined, ""])("rejects missing/empty environment value %p", (value) => {
    if (value === undefined) delete process.env.PIDEWAVE_TEST_PORT;
    else process.env.PIDEWAVE_TEST_PORT = value;

    for (const expression of ["${PIDEWAVE_TEST_PORT}", "$env:PIDEWAVE_TEST_PORT", "{env:PIDEWAVE_TEST_PORT}"]) {
      const h = harness();
      h.write({ pidewave: { url: `http://localhost:${expression}/tidewave/mcp` } });
      h.fire("session_start");
      expect(h.requests).toEqual([]);
      expect(h.endpoint()).toEqual({ version: 1 });
    }
  });

  test("malformed JSON reports no raw configuration", () => {
    const h = harness({ hasUI: true });
    h.write();
    fs.writeFileSync(h.file, '{"secret":"do-not-print"');
    h.fire("session_start");
    expect(h.requests).toEqual([]);
    expect(h.notices.join()).not.toContain("do-not-print");
    expect(h.notices).toHaveLength(1);
  });

  test.each([false, true])("missing adapter or duplicate registration fails closed (adapter=%p)", (adapter) => {
    const h = harness({ adapter, hasUI: true });
    h.write();
    h.failRegistration();
    h.fire("session_start");
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.statusListeners()).toEqual([]);
    expect(h.notices.join()).not.toContain("do-not-print");
    expect(h.dispose).not.toHaveBeenCalled();
  });

  test("deferred startup publishes only after a status event confirms active ownership, without polling", () => {
    const h = harness({ active: false });
    h.write();
    const interval = spyOn(globalThis, "setInterval");
    const timeout = spyOn(globalThis, "setTimeout");

    try {
      h.fire("session_start");
      expect(h.requests).toHaveLength(1);
      expect(h.endpoint()).toEqual({ version: 1 });
      h.snapshot(owned());
      h.status();
      expect(h.endpoint()).toEqual(published());
      expect(interval).not.toHaveBeenCalled();
      expect(timeout).not.toHaveBeenCalled();
    } finally { interval.mockRestore(); timeout.mockRestore(); }
  });

  test.each([
    undefined, {}, { ...owned(), name: "other" }, { ...owned(), runtime: false },
    { ...owned(), persisted: true }, { ...owned(), definition: {} },
    owned("http://localhost:4400/tidewave/mcp"),
  ])("revokes on unavailable/shadowed/mismatched snapshot %p", (snapshot) => {
    const h = harness();
    h.write();
    h.fire("session_start");
    expect(h.endpoint()).toEqual(published());
    h.snapshot(snapshot);
    h.status();
    expect(h.endpoint()).toEqual({ version: 1 });
  });

  test("missing snapshot responder revokes a published endpoint", () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    expect(h.endpoint()).toEqual(published());
    h.noSnapshot();
    h.status();
    expect(h.endpoint()).toEqual({ version: 1 });
  });

  test("adapter shutdown before ACP shutdown revokes ownership", async () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    expect(h.endpoint()).toEqual(published());
    h.snapshot(undefined);
    h.status();
    expect(h.endpoint()).toEqual({ version: 1 });
    await h.fire("session_shutdown");
    expect(h.dispose).toHaveBeenCalledTimes(1);
  });

  test("startup collision never publishes", () => {
    const h = harness({ active: false });
    h.write();
    h.fire("session_start");
    h.snapshot({ ...owned(), runtime: false, persisted: true });
    h.status();
    h.noSnapshot();
    h.status();
    expect(h.publications.every((value) => JSON.stringify(value) === '{"version":1}')).toBe(true);
  });

  test("shutdown revokes before disposal settles, unsubscribes, and ignores late callbacks across reload", async () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    const late = h.statusListeners()[0];
    let finish!: () => void;
    h.dispose.mockImplementation(() => new Promise<void>((resolve) => { finish = resolve; }));
    const stopping = h.fire("session_shutdown");
    expect(h.endpoint()).toEqual({ version: 1 });
    expect(h.statusListeners()).toEqual([]);
    expect(h.dispose).toHaveBeenCalledTimes(1);
    const count = h.publications.length;
    late({ version: 1, name: "unused" });
    h.status();
    expect(h.publications).toHaveLength(count);
    h.stopAdapter();
    process.env.PIDEWAVE_TEST_PORT = "4400";
    const next = harness({ bus: h.bus });
    next.write({ pidewave: { url: "http://localhost:${PIDEWAVE_TEST_PORT}/tidewave/mcp" } });
    next.fire("session_start");
    expect(next.endpoint()).toEqual(published("http://localhost:4400"));
    late({ version: 1, name: "unused" });
    finish();
    await stopping;
    expect(next.endpoint()).toEqual(published("http://localhost:4400"));
    expect(h.dispose).toHaveBeenCalledTimes(1);
  });

  test("adapter disposal failure is contained", async () => {
    const h = harness();
    h.write();
    h.fire("session_start");
    h.dispose.mockImplementation(async () => { throw new Error("adapter stopped"); });
    await h.fire("session_shutdown");
    expect(h.endpoint()).toEqual({ version: 1 });
  });
});
