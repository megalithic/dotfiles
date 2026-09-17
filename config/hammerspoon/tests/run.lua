-- Lifecycle/mock tests for the Hammerspoon watcher + event-routing stack.
-- Run from config/hammerspoon: lua tests/run.lua
-- Uses tests/mock_hs.lua (virtual clock, fake apps/watchers/hotkeys/modals);
-- no Hammerspoon runtime required.

package.path = "./?.lua;./?/init.lua;" .. package.path

local mockHs = require("tests.mock_hs")

local failures = 0
local passes = 0

local function check(cond, msg)
  if cond then
    passes = passes + 1
  else
    failures = failures + 1
    print("FAIL: " .. msg)
  end
end

local FRESH_MODULES = {
  "watchers.app",
  "contexts",
  "lollygagger",
  "hyper",
  "quitter",
  "utils",
  "tests.mock_hs",
}

local function freshEnv()
  for _, mod in ipairs(FRESH_MODULES) do
    package.loaded[mod] = nil
  end
  _G.hs = nil
  _G.U = nil
  _G.C = nil
  _G.Hypers = nil
  _G.DEBUG = nil
  _G.APP_MODALS_ENABLED = nil
  local mock = mockHs.new()
  mock.install()
  return mock
end

local function test(name, fn)
  local mock = freshEnv()
  local ok, err = pcall(fn, mock)
  if not ok then
    failures = failures + 1
    print(("FAIL: %s errored: %s"):format(name, tostring(err)))
  else
    print(("ok: %s"):format(name))
  end
end

--------------------------------------------------------------------------------

test("eventString maps constants and survives unknown events", function(mock)
  local utils = require("utils")
  check(utils.eventString(hs.application.watcher.terminated) == "terminated", "terminated maps")
  check(utils.eventString("AXTitleChanged") == "AXTitleChanged", "string passthrough")
  check(utils.eventString(99) == "99", "unknown numeric event does not error")
end)

test("hyper binds the physical key exactly once across ids", function(mock)
  req("hyper", { id = "a" })
  req("hyper", { id = "b" })
  req("hyper", { id = "c" })

  local hyperBinds = 0
  for _, hk in ipairs(mock.hotkeys) do
    if hk.key == "F19" then hyperBinds = hyperBinds + 1 end
  end
  check(hyperBinds == 1, "expected 1 F19 hotkey, got " .. hyperBinds)
end)

test("hyper passthrough wait is bounded when app never fronts", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "j", "com.never.launches")

  -- Find the passthrough modal bind and trigger it (app not running)
  local bind = hyper.binds[#hyper.binds]
  bind.released()

  check(mock.launched[1] == "com.never.launches", "launch attempted")
  check(mock.pendingTimers() > 0, "wait timer scheduled")

  mock.advance(15) -- past the 10s deadline
  check(#mock.keystrokes == 0, "no keystroke after timeout")
  check(mock.pendingTimers() == 0, "wait timer stopped after deadline")
end)

test("hyper passthrough sends key when app fronts", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "j", "com.test.app")

  local bind = hyper.binds[#hyper.binds]
  bind.released()

  local app = mock.makeApp({ bundleID = "com.test.app" })
  mock.frontmost = app
  mock.advance(0.5)

  check(#mock.keystrokes == 1, "keystroke sent once app fronted")
  check(mock.pendingTimers() == 0, "wait timer stopped after firing")
end)

test("app watcher: watch, terminate cleanup, relaunch re-watch", function(mock)
  U.resourcePath = function() return "tests/fixtures/contexts/" end

  local appw = require("watchers.app")
  appw:start()
  local gw = mock.appWatchers[#mock.appWatchers]

  local A = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })
  gw:emit("TestApp", hs.application.watcher.launched, A)

  check(appw.watchers.app[A:pid()] ~= nil, "watcher registered by pid")
  check(A.watchers[1] and A.watchers[1].started, "uielement watcher started")

  -- Terminated: appName is nil, app object near-dead (bundleID() == nil)
  A._dead = true
  gw:emit(nil, hs.application.watcher.terminated, A)

  check(appw.watchers.app[A:pid()] == nil, "entry removed on termination")
  check(A.watchers[1].stopped, "uielement watcher stopped on termination")

  -- Relaunch: new pid must be re-watched (bundleID keying blocked this)
  local A2 = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })
  gw:emit("TestApp", hs.application.watcher.launched, A2)

  check(appw.watchers.app[A2:pid()] ~= nil, "relaunched app re-watched")
  check(A2.watchers[1] and A2.watchers[1].started, "new uielement watcher started")

  -- nil-app events must not error
  gw:emit("Ghost", hs.application.watcher.activated, nil)
  gw:emit(nil, hs.application.watcher.terminated, nil)

  appw:stop()
  check(A2.watchers[1].stopped, "watchers stopped on module stop")
  check(mock.appWatchers[#mock.appWatchers].started == false, "global watcher stopped")
end)

test("contexts: preload idempotent, frontmost gating, deactivation", function(mock)
  U.resourcePath = function() return "tests/fixtures/contexts/" end

  local contexts = require("contexts")
  local first = contexts:preload()
  local ctx = first["com.test.app"]
  check(ctx ~= nil, "fixture context loaded")
  check(ctx.modal ~= nil and ctx.modal.binds, "modal created from actions")

  local again = contexts:preload()
  check(again["com.test.app"] == ctx, "preload reuses loaded context")
  check(again["com.test.app"].modal == ctx.modal, "no duplicate modal minted")

  local A = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })

  -- Background activation event (not frontmost): modal must NOT enter
  mock.frontmost = nil
  contexts:run({ context = ctx, event = hs.application.watcher.activated, appObj = A, bundleID = "com.test.app" })
  check(ctx.modal.active == false, "modal not entered while app in background")
  check(ctx.activated == 1, "onActivate hook still called")

  -- Frontmost activation: modal enters
  mock.frontmost = A
  contexts:run({ context = ctx, event = hs.application.watcher.activated, appObj = A, bundleID = "com.test.app" })
  check(ctx.modal.active == true, "modal entered when frontmost")

  -- Deactivation: modal exits
  contexts:run({ context = ctx, event = hs.application.watcher.deactivated, appObj = A, bundleID = "com.test.app" })
  check(ctx.modal.active == false, "modal exited on deactivation")
  check(ctx.deactivated >= 1, "onDeactivate hook called")

  -- nil app + nil bundleID: must not error
  contexts:run({ context = ctx, event = hs.application.watcher.activated, appObj = nil, bundleID = nil })

  -- Erroring lifecycle hooks must not propagate into the caller
  local errCtx = first["com.err.app"]
  check(errCtx ~= nil, "error fixture loaded")
  local B = mock.makeApp({ bundleID = "com.err.app", name = "ErrApp" })
  mock.frontmost = B
  contexts:run({ context = errCtx, event = hs.application.watcher.activated, appObj = B, bundleID = "com.err.app" })
  contexts:run({ context = errCtx, event = hs.application.watcher.deactivated, appObj = B, bundleID = "com.err.app" })
  check(errCtx.modal.active == false, "modal state managed despite erroring hooks")
end)

test("terminated events route context + lollygagger cleanup", function(mock)
  U.resourcePath = function() return "tests/fixtures/contexts/" end
  C.lollygaggers = { ["com.test.app"] = { 1, nil } } -- hide after 1 minute

  local appw = require("watchers.app")
  appw:start()
  local gw = mock.appWatchers[#mock.appWatchers]

  local A = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })
  mock.frontmost = A
  gw:emit("TestApp", hs.application.watcher.launched, A)
  gw:emit("TestApp", hs.application.watcher.activated, A)

  local ctx = appw.watchers.context["com.test.app"]
  check(ctx.modal.active == true, "modal active while app frontmost")

  -- Deactivate: lollygagger schedules hide timer
  mock.frontmost = nil
  gw:emit("TestApp", hs.application.watcher.deactivated, A)
  local timersAfterDeactivate = mock.pendingTimers()
  check(timersAfterDeactivate > 0, "lollygagger hide timer scheduled")

  -- Terminate: context deactivates and lollygagger timers are cancelled
  A._dead = true
  gw:emit(nil, hs.application.watcher.terminated, A)
  check(ctx.modal.active == false, "modal exited on termination")
  check(mock.pendingTimers() < timersAfterDeactivate, "lollygagger timer cancelled on termination")

  -- Advancing past the hide interval must not touch the dead app
  mock.advance(120)
  check(not A._hidden, "no hide action on terminated app")

  -- Stop while a modal is entered: modal must exit so hotkeys release,
  -- and the idempotent preload must not resume a phantom-active modal.
  local A3 = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })
  mock.frontmost = A3
  gw:emit("TestApp", hs.application.watcher.launched, A3)
  gw:emit("TestApp", hs.application.watcher.activated, A3)
  check(ctx.modal.active == true, "modal active before stop")

  appw:stop()
  check(ctx.modal.active == false, "modal exited on watcher stop")
  check(ctx._modalActive == false, "_modalActive flag cleared on stop")
end)

test("lollygagger cancels timers on reactivation", function(mock)
  C.lollygaggers = { ["com.test.app"] = { 1, 2 } }
  local lolly = require("lollygagger")
  lolly:start()

  local A = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })

  lolly:run("TestApp", hs.application.watcher.deactivated, A)
  check(mock.pendingTimers() == 2, "hide + quit timers scheduled")

  lolly:run("TestApp", hs.application.watcher.activated, A)
  check(mock.pendingTimers() == 0, "timers cancelled on activation")

  mock.advance(200)
  check(not A._hidden and A:isRunning(), "app untouched after cancellation")

  -- bundleID hint path (terminated app that no longer reports a bundleID)
  lolly:run("TestApp", hs.application.watcher.deactivated, A)
  check(mock.pendingTimers() == 2, "timers rescheduled")
  A._dead = true
  lolly:run("com.test.app", hs.application.watcher.terminated, A, "com.test.app")
  check(mock.pendingTimers() == 0, "hint-based termination cancels timers")

  lolly:stop()
end)

test("quitter: stale double-mode timer cannot exit a newer modal", function(mock)
  C.quitters = { ["com.test.app"] = { mode = "double" } }
  local quitter = require("quitter")
  quitter:start()

  local hk = mock.hotkeys[#mock.hotkeys]
  check(hk.key == "q", "cmd+q hotkey bound")

  local A = mock.makeApp({ bundleID = "com.test.app", name = "TestApp" })
  mock.frontmost = A

  -- First press: modal 1 + auto-exit timer
  hk.pressed()
  local modal1 = mock.modals[#mock.modals]
  check(modal1.active, "first double-mode modal active")

  -- Escape at t+0.1 cancels modal 1 (and, with the fix, its timer)
  mock.advance(0.1)
  local escapeBind
  for _, b in ipairs(modal1.binds) do
    if b.key == "escape" then escapeBind = b end
  end
  escapeBind.pressed()
  check(not modal1.active, "first modal exited via escape")

  -- Second press at t+0.5: new modal must survive past t+1.0 (stale timer)
  mock.advance(0.4)
  hk.pressed()
  local modal2 = mock.modals[#mock.modals]
  check(modal2 ~= modal1 and modal2.active, "second modal active")

  mock.advance(0.7) -- t = 1.2: stale timer (t=1.0) would have killed modal2
  check(modal2.active, "second modal survives stale timer window")

  mock.advance(0.5) -- t = 1.7: modal2's own timeout (t=1.5) has fired
  check(not modal2.active and modal2.deleted, "second modal auto-exits on its own timeout")

  quitter:stop()
end)

--------------------------------------------------------------------------------

print(("\n%d passed, %d failed"):format(passes, failures))
if failures > 0 then os.exit(1) end
