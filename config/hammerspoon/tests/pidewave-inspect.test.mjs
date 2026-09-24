// Run with: node --test config/hammerspoon/tests/pidewave-inspect.test.mjs
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";
import vm from "node:vm";

// Execute the production expression, not a second implementation of Inspect.
const source = readFileSync(new URL("../lib/interop/pidewave.lua", import.meta.url), "utf8");
const expression = source.match(
  /local js\s*=\s*"([^"\n]*)"\s*\.\.\s*expectedJson\s*\.\.\s*"([^"\n]*)"\s*\.\.\s*\[\[([\s\S]*?)\]\]/,
);
assert.ok(expression, "could not extract the Inspect expression from pidewave.lua");
const origin = "http://localhost:4123";
const script = new vm.Script(
  expression[1] + JSON.stringify({ origin }) + expression[2] + expression[3],
);

async function inspect(initial = {}, onTick = () => {}) {
  const state = {
    now: 0,
    clicks: 0,
    selected: false,
    panel: false,
    buttonPresent: true,
    toolbarPresent: true,
    shadowRootPresent: true,
    disabled: false,
    ariaDisabled: false,
    connected: true,
    visible: true,
    width: 20,
    height: 20,
    readyState: "complete",
    visibilityState: "visible",
    origin,
    pathname: "/orders",
    ...initial,
  };
  const timers = [];
  const button = {
    get disabled() { return state.disabled; },
    get isConnected() { return state.connected; },
    getAttribute(name) {
      if (name === "aria-label") return "Inspect";
      if (name === "aria-disabled") return state.ariaDisabled ? "true" : null;
      return null;
    },
    getBoundingClientRect: () => ({ width: state.width, height: state.height }),
    checkVisibility: state.noCheckVisibility ? undefined : () => state.visible,
    classList: { contains: (name) => name === "bg-accent" && state.selected },
    click() { state.clicks++; },
  };
  const root = {
    querySelectorAll: () => state.buttonPresent ? [button] : [],
    querySelector: (selector) => selector === '[data-testid="inspector-panel"]' && state.panel ? {} : null,
  };
  const context = {
    location: {
      get origin() { return state.origin; },
      get pathname() { return state.pathname; },
      get href() { return state.origin + state.pathname; },
    },
    document: {
      get readyState() { return state.readyState; },
      get visibilityState() { return state.visibilityState; },
      getElementById(id) {
        assert.equal(id, "tidewave-toolbar");
        return state.toolbarPresent ? { shadowRoot: state.shadowRootPresent ? root : null } : null;
      },
    },
    Date: { now: () => state.now },
    setTimeout(callback, delay) { timers.push({ callback, at: state.now + delay }); },
  };
  const pending = script.runInNewContext(context, { timeout: 1000 });
  let ticks = 0;
  while (timers.length) {
    assert.ok(ticks++ < 100, "Inspect must stop polling at its deadline");
    const timer = timers.shift();
    state.now = timer.at;
    onTick(state);
    timer.callback();
  }
  return { result: await pending, ...state };
}

test("already-selected Inspect waits for delayed panel without clicking", async () => {
  const result = await inspect({ selected: true }, (state) => {
    if (state.now >= 300) state.panel = true;
  });
  assert.equal(result.result, "active");
  assert.equal(result.clicks, 0);
  assert.equal(result.now, 300);
});

test("already-active Inspect succeeds without clicking", async () => {
  const result = await inspect({ selected: true, panel: true });
  assert.equal(result.result, "active");
  assert.equal(result.clicks, 0);
  assert.equal(result.now, 0);
});

test("clicks once and waits for both selected state and panel", async () => {
  const result = await inspect({}, (state) => {
    assert.equal(state.clicks, 1);
    if (state.now >= 200) state.selected = true;
    if (state.now >= 400) state.panel = true;
  });
  assert.equal(result.result, "active");
  assert.equal(result.clicks, 1);
  assert.equal(result.now, 400);
});

for (const [name, initial, makeReady] of [
  ["disabled button", { disabled: true }, (state) => { state.disabled = false; }],
  ["aria-disabled button", { ariaDisabled: true }, (state) => { state.ariaDisabled = false; }],
  ["hidden button", { visible: false }, (state) => { state.visible = true; }],
  ["detached button", { connected: false }, (state) => { state.connected = true; }],
  ["background page", { visibilityState: "hidden" }, (state) => { state.visibilityState = "visible"; }],
  ["loading page", { readyState: "loading" }, (state) => { state.readyState = "complete"; }],
  ["zero-sized fallback button", { noCheckVisibility: true, width: 0 }, (state) => { state.width = 20; }],
]) {
  test(`waits for ${name} before clicking once`, async () => {
    const result = await inspect(initial, (state) => {
      if (state.now <= 300) assert.equal(state.clicks, 0);
      if (state.now === 300) makeReady(state);
      if (state.now >= 400) {
        state.selected = true;
        state.panel = true;
      }
    });
    assert.equal(result.result, "active");
    assert.equal(result.clicks, 1);
    assert.equal(result.now, 400);
  });
}

for (const [name, initial] of [
  ["scheme", { origin: "https://localhost:4123" }],
  ["host", { origin: "http://127.0.0.1:4123" }],
  ["port", { origin: "http://localhost:4999" }],
  ["remote host", { origin: "http://example.com:4123" }],
  ["Tidewave route", { pathname: "/tidewave" }],
  ["Tidewave child route", { pathname: "/tidewave/mcp" }],
]) {
  test(`location mismatch: ${name} never clicks`, async () => {
    const result = await inspect(initial);
    assert.match(result.result, /^location-mismatch:/);
    assert.equal(result.clicks, 0);
    assert.equal(result.now, 0);
  });
}

test("location is rechecked while waiting for readiness", async () => {
  const result = await inspect({ disabled: true }, (state) => {
    state.disabled = false;
    state.origin = "http://localhost:4999";
  });
  assert.match(result.result, /^location-mismatch:/);
  assert.equal(result.clicks, 0);
});

for (const [name, initial, clicks, suffix] of [
  ["missing toolbar", { toolbarPresent: false }, 0, "no-toolbar:no-button"],
  ["missing shadow root", { shadowRootPresent: false }, 0, "toolbar:no-button"],
  ["missing button", { buttonPresent: false }, 0, "toolbar:no-button"],
  ["disabled button", { disabled: true }, 0, "toolbar:button-disabled"],
  ["hidden button", { visible: false }, 0, "toolbar:button-hidden"],
  ["unconfirmed click", {}, 1, "toolbar:click-unconfirmed"],
  ["selected button without panel", { selected: true }, 0, "toolbar:button"],
]) {
  test(`${name} times out without repeated clicks`, async () => {
    const result = await inspect(initial);
    assert.equal(result.result, `not-ready:complete:visible:${suffix}`);
    assert.equal(result.clicks, clicks);
    assert.equal(result.now, 4000);
  });
}
