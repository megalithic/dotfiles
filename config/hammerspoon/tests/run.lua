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
  "watchers.dock",
  "watchers.hotspot",
  "contexts",
  "lollygagger",
  "hyper",
  "bindings",
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

local function configureDock()
  C.dock = {
    target_alt = { vendorID = 100, productID = 200 },
    keyboard = { vendorID = 400, productID = 300, productName = "Test Keyboard", debounceSeconds = 3 },
    kanata = {
      enabled = true,
      connected = "external.kbd",
      disconnected = "internal.kbd",
      configPath = "/tmp/kanata",
      daemonLabel = "test.kanata",
    },
  }
end

local function startDocked(mock)
  configureDock()
  C.dock.kanata.enabled = false
  mock.usbDevices = { C.dock.target_alt }

  local dock = require("watchers.dock")
  dock:start()
  return dock, mock.usbWatchers[#mock.usbWatchers]
end

local function tasksNamed(mock, name)
  local matches = {}
  for _, task in ipairs(mock.tasks) do
    if task.launchPath == "/bin/sh" and task.args[3] == name then table.insert(matches, task) end
  end
  return matches
end

local function emitDock(watcher, eventType)
  watcher:emit({ vendorID = C.dock.target_alt.vendorID, productID = C.dock.target_alt.productID, eventType = eventType })
end

local function emitKeyboard(mock, watcher, eventType, devices)
  mock.usbDevices = devices or (eventType == "added" and { C.dock.keyboard } or {})
  watcher:emit({ vendorID = C.dock.keyboard.vendorID, productID = C.dock.keyboard.productID, eventType = eventType })
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

test("hold passthrough posts down immediately for a running background app", function(mock)
  local hyper = req("hyper", { id = "apps" })
  mock.makeApp({ bundleID = "com.hold.app" })
  hyper:bindPassThrough({ "shift" }, "g", "com.hold.app", true)
  local bind = hyper.binds[#hyper.binds]

  bind.pressed()
  check(#mock.keyEvents == 1, "hold posts keydown without requiring focus")
  check(mock.keyEvents[1].isDown == true, "first event is keydown")
  check(mock.keyEvents[1].key == "g", "hold preserves key")
  check(#mock.launched == 0, "running background app is not relaunched")
  bind.released()
  check(#mock.keyEvents == 2 and mock.keyEvents[2].isDown == false, "release posts keyup")
end)

test("hold passthrough ignores repeat and duplicate release", function(mock)
  local hyper = req("hyper", { id = "apps" })
  mock.makeApp({ bundleID = "com.hold.app" })
  hyper:bindPassThrough({}, "g", "com.hold.app", true)
  local bind = hyper.binds[#hyper.binds]

  bind.pressed()
  bind.pressed()
  if bind.repeatFn then bind.repeatFn() end
  bind.released()
  bind.released()
  check(#mock.keyEvents == 2, "repeat and duplicate release do not duplicate events")
end)

test("hold passthrough flushes all holds on hyper exit", function(mock)
  local hyper = req("hyper", { id = "apps" })
  mock.makeApp({ bundleID = "com.hold.app" })
  hyper:bindPassThrough({}, "g", "com.hold.app", true)
  hyper:bindPassThrough({ "shift" }, "h", "com.hold.app", true)
  local first, second = hyper.binds[#hyper.binds - 1], hyper.binds[#hyper.binds]

  first.pressed()
  second.pressed()
  hyper:exit()
  check(#mock.keyEvents == 4, "exit releases both simultaneous holds")
  check(mock.keyEvents[3].isDown == false and mock.keyEvents[4].isDown == false, "exit posts keyups")
  first.released()
  second.released()
  check(#mock.keyEvents == 4, "key release after exit does not duplicate keyup")
end)

test("hold passthrough stop releases a live hold and cancels a pending hold", function(mock)
  local hyper = req("hyper", { id = "apps" })
  mock.makeApp({ bundleID = "com.stop.app" })
  hyper:bindPassThrough({}, "g", "com.stop.app", true)
  local live = hyper.binds[#hyper.binds]
  live.pressed()
  hyper:bindPassThrough({}, "h", "com.pending.app", true)
  local pending = hyper.binds[#hyper.binds]
  pending.pressed()
  hyper:stop()
  check(#mock.keyEvents == 2 and not mock.keyEvents[2].isDown, "stop releases live hold")
  mock.advance(15)
  check(#mock.keyEvents == 2 and mock.pendingTimers() == 0,
    "stop cancels pending hold without late keydown or stray keyup")
end)

test("hold passthrough reset releases live hold and cancels pending hold", function(mock)
  local hyper = req("hyper", { id = "apps" })
  mock.makeApp({ bundleID = "com.reset.app" })
  hyper:bindPassThrough({}, "g", "com.reset.app", true)
  local live = hyper.binds[#hyper.binds]
  live.pressed()

  local pendingHyper = req("hyper", { id = "pending-reset" })
  pendingHyper:bindPassThrough({}, "h", "com.pending.reset", true)
  pendingHyper.binds[#pendingHyper.binds].pressed()
  require("lib.state").resetHypers()
  mock.advance(15)
  check(#mock.keyEvents == 2 and not mock.keyEvents[2].isDown, "reset releases live hold and cancels pending hold")
end)

test("hold passthrough exit cancels a pending cold launch", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "g", "com.exit.app", true)
  hyper.binds[#hyper.binds].pressed()
  hyper:exit()
  mock.advance(15)
  check(#mock.keyEvents == 0 and mock.pendingTimers() == 0, "exit cancels pending hold without late events")
end)

test("held cold launch timeout stops without sending a key", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "g", "com.timeout.app", true)
  local bind = hyper.binds[#hyper.binds]
  bind.pressed()
  mock.advance(15)
  check(#mock.keyEvents == 0 and mock.pendingTimers() == 0, "held timeout sends no key and stops timer")
  bind.released()
  check(#mock.keyEvents == 0, "release after timeout sends no stray keyup")
end)

test("hold passthrough cancels cold launch on early release", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "g", "com.cold.app", true)
  local bind = hyper.binds[#hyper.binds]
  bind.pressed()
  check(#mock.launched == 1 and mock.pendingTimers() > 0, "cold hold launches and waits")
  bind.released()
  mock.advance(15)
  check(#mock.keyEvents == 0, "early release prevents late keydown")
  check(mock.pendingTimers() == 0, "early release cancels launch wait")
end)

test("hold passthrough cold launch posts down then up after focus", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "g", "com.cold.app", true)
  local bind = hyper.binds[#hyper.binds]
  bind.pressed()
  local app = mock.makeApp({ bundleID = "com.cold.app" })
  mock.frontmost = app
  mock.advance(0.2)
  check(#mock.keyEvents == 1 and mock.keyEvents[1].isDown, "cold launch posts keydown after focus")
  bind.released()
  check(#mock.keyEvents == 2 and not mock.keyEvents[2].isDown, "focused cold hold posts keyup")
end)

test("hold passthrough can be pressed again after cancellation", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindPassThrough({}, "g", "com.retry.app", true)
  local bind = hyper.binds[#hyper.binds]
  bind.pressed()
  bind.released()
  local app = mock.makeApp({ bundleID = "com.retry.app" })
  mock.frontmost = app
  bind.pressed()
  bind.released()
  check(#mock.keyEvents == 2, "second gesture emits down and up")
  check(mock.keyEvents[1].isDown and not mock.keyEvents[2].isDown, "second gesture has correct edge order")
end)

test("bindings routes tap and hold passthrough lists", function(mock)
  local launcher = {
    "noop.app",
    nil,
    {
      passThrough = { "p" },
      passThroughHold = { "g", { { "shift" }, "h" } },
    },
  }
  C.launchers = { launcher }
  local bindings = require("bindings")
  bindings.loadApps()
  local hyper = req("hyper", { id = "apps" })
  local tap, plainHold, modifiedHold
  for _, candidate in ipairs(hyper.binds or {}) do
    if candidate.key == "p" then tap = candidate end
    if candidate.key == "g" then plainHold = candidate end
    if candidate.key == "h" then modifiedHold = candidate end
  end
  check(tap ~= nil and tap.pressed == nil and tap.released ~= nil and tap.repeatFn == nil,
    "tap passthrough keeps release-only semantics")
  check(plainHold ~= nil and plainHold.pressed ~= nil and plainHold.released ~= nil,
    "string hold binding is routed")
  check(modifiedHold ~= nil and modifiedHold.mods[1] == "shift",
    "modifier hold binding preserves modifiers")
  mock.makeApp({ bundleID = "noop.app" })
  modifiedHold.pressed()
  modifiedHold.released()
  check(#mock.keyEvents == 2 and mock.keyEvents[1].isDown and not mock.keyEvents[2].isDown,
    "hold routing posts global down/up events")
  local hasShift = false
  for _, mod in ipairs(mock.keyEvents[1].mods) do
    if mod == "shift" then hasShift = true end
  end
  check(mock.keyEvents[1].mods[1] == "cmd" and hasShift,
    "hold routing includes hyper and extra modifiers")
end)

test("bindAppChord uses bounded cold-launch helper", function(mock)
  local hyper = req("hyper", { id = "apps" })
  hyper:bindAppChord({}, "c", "com.chord.app", { "cmd" }, "k")
  local bind = hyper.binds[#hyper.binds]
  bind.released()
  check(#mock.launched == 1 and mock.pendingTimers() > 0, "app chord launches and waits")
  mock.advance(15)
  check(#mock.keystrokes == 0 and mock.pendingTimers() == 0, "app chord timeout is bounded")
end)

test("dock watcher: startup applies connected state without tasks or timers", function(mock)
  local dock, watcher = startDocked(mock)

  check(watcher.started, "USB watcher started")
  check(dock.is_docked == true, "matching TS4 is docked at startup")
  mock.advance(3600)
  check(#mock.tasks == 0 and mock.pendingTimers() == 0, "dock state uses no shell tasks or timers")

  dock:stop()
  check(watcher.stopped, "USB watcher stopped")
end)

test("dock watcher: startup without TS4 is undocked", function(mock)
  configureDock()
  C.dock.kanata.enabled = false
  local dock = require("watchers.dock")
  dock:start()

  check(dock.is_docked == false, "no TS4 means undocked")
  dock:stop()
end)

test("dock watcher: only state transitions update dock state", function(mock)
  local dock, watcher = startDocked(mock)
  local logs = #mock.logs
  emitDock(watcher, "added")
  check(#mock.logs == logs, "duplicate connected event does nothing")

  emitDock(watcher, "removed")
  check(dock.is_docked == false and #mock.logs == logs + 1, "disconnect updates state once")
  emitDock(watcher, "removed")
  check(#mock.logs == logs + 1, "duplicate disconnected event does nothing")

  emitDock(watcher, "added")
  check(dock.is_docked == true and #mock.logs == logs + 2, "reconnect updates state once")
  dock:stop()
end)

test("dock watcher: docking and undocking never touch Wi-Fi", function(mock)
  local dock, watcher = startDocked(mock)
  emitDock(watcher, "removed")
  emitDock(watcher, "added")
  check(mock.wifiReads == 0 and #mock.wifiChanges == 0, "Wi-Fi power is left alone")
  check(#mock.notifications == 0, "no Wi-Fi notifications")
  dock:stop()
end)

test("dock watcher: unrelated USB events and unknown event types do nothing", function(mock)
  local dock, watcher = startDocked(mock)
  local logs = #mock.logs
  watcher:emit({ vendorID = 999, productID = 200, eventType = "removed" })
  watcher:emit({ vendorID = 100, productID = 999, eventType = "removed" })
  emitDock(watcher, "unknown")
  check(dock.is_docked == true, "both vendor and product must match a known event")
  check(#mock.logs == logs, "ignored events do not log")
  dock:stop()
end)

test("dock watcher: startup uses the same vendor and product match", function(mock)
  configureDock()
  C.dock.kanata.enabled = false
  mock.usbDevices = { { vendorID = 999, productID = 200 }, { vendorID = 100, productID = 999 } }
  local dock = require("watchers.dock")
  dock:start()
  check(dock.is_docked == false, "partial USB matches are not the dock")
  dock:stop()
end)

test("dock watcher: stop ignores stale USB callbacks and restart reapplies state", function(mock)
  local dock, watcher = startDocked(mock)
  dock:stop()
  watcher.callback({ vendorID = 100, productID = 200, eventType = "removed" })
  check(dock.is_docked == true, "stale callback does nothing after stop")
  mock.usbDevices = {}
  dock:start()
  check(dock.is_docked == false, "restart applies fresh USB state")
  check(#mock.tasks == 0 and mock.pendingTimers() == 0, "restart creates no tasks or timers")
  dock:stop()
end)

test("dock watcher: keyboard changes reconcile the latest profile under lock", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }

  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  local switches = tasksNamed(mock, "hammerspoon-kanata")

  check(#switches == 1, "startup starts one Kanata switch")
  check(switches[1].args[4] == "/tmp/kanata/external.kbd", "connected profile requested")
  check(dock._switch_lock == true, "switch lock held while task runs")

  emitKeyboard(mock, watcher, "removed")
  mock.advance(C.dock.keyboard.debounceSeconds)
  check(#tasksNamed(mock, "hammerspoon-kanata") == 1, "keyboard change does not overlap active switch")

  switches[1]:complete(0, "switched\n", "")
  switches = tasksNamed(mock, "hammerspoon-kanata")
  check(#switches == 2, "latest queued profile starts after active switch")
  check(switches[2].args[4] == "/tmp/kanata/internal.kbd", "disconnected profile wins")

  emitKeyboard(mock, watcher, "added")
  mock.advance(C.dock.keyboard.debounceSeconds)
  switches[2]:complete(1, "", "restart failed")
  switches = tasksNamed(mock, "hammerspoon-kanata")
  check(#switches == 3, "changed target starts fresh instead of retrying stale target")
  check(switches[3].args[4] == "/tmp/kanata/external.kbd", "newest connected profile wins")

  switches[3]:complete(0, "already\n", "")
  check(dock._switch_lock == false, "switch lock released after reconciliation")

  dock:stop()
end)

test("dock watcher: dock and keyboard actions stay independent", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.target_alt, C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  local switches = tasksNamed(mock, "hammerspoon-kanata")
  check(switches[1].args[4] == "/tmp/kanata/external.kbd", "keyboard selects external profile")
  switches[1]:complete(0, "already\n", "")

  emitDock(watcher, "removed")
  check(#tasksNamed(mock, "hammerspoon-kanata") == 1, "undocking does not change Kanata")
  emitKeyboard(mock, watcher, "removed")
  mock.advance(C.dock.keyboard.debounceSeconds)
  switches = tasksNamed(mock, "hammerspoon-kanata")
  check(
    #switches == 2 and switches[2].args[4] == "/tmp/kanata/internal.kbd",
    "keyboard removal selects internal profile"
  )
  dock:stop()
end)

test("dock watcher: Kanata failure retries once and notifies", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }

  local dock = require("watchers.dock")
  dock:start()
  local switches = tasksNamed(mock, "hammerspoon-kanata")

  switches[1]:complete(1, "", "first failure")
  switches = tasksNamed(mock, "hammerspoon-kanata")
  check(#switches == 2, "failed switch retried once")
  check(dock._switch_lock == true, "switch lock held during retry")

  switches[2]:complete(1, "", "second failure")
  check(#tasksNamed(mock, "hammerspoon-kanata") == 2, "second failure does not retry forever")
  check(dock._switch_lock == false, "switch lock released after final failure")
  check(#mock.notifications == 1, "final failure sends one notification")

  dock:stop()
end)

test("dock watcher: stop terminates Kanata tasks", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }

  local dock = require("watchers.dock")
  dock:start()
  local switchTask = tasksNamed(mock, "hammerspoon-kanata")[1]

  dock:stop()
  check(switchTask.terminated, "active Kanata task terminated")
  check(dock._switch_lock == false, "switch lock released on stop")

  local count = #mock.tasks
  switchTask:complete(0, "switched\n", "")
  check(#mock.tasks == count, "stale callbacks do not start new tasks")
end)

test("dock watcher: reported USB chatter causes no profile restarts", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  tasksNamed(mock, "hammerspoon-kanata")[1]:complete(0, "switched\n", "")

  -- Seconds from 15:36:54 in the reported sequence; initially connected.
  local events = {
    { 0, "removed" },
    { 2, "added" },
    { 6, "removed" },
    { 8, "added" },
    { 8, "removed" },
    { 10, "added" },
    { 19, "removed" },
    { 21, "added" },
  }
  for _, event in ipairs(events) do
    mock.advance(event[1] - mock.now)
    emitKeyboard(mock, watcher, event[2])
    check(mock.pendingTimers() == 1, "chatter keeps only one pending timer")
    check(dock.is_keyboard_connected == true, "raw chatter does not change settled state")
  end
  mock.advance(10)
  check(#tasksNamed(mock, "hammerspoon-kanata") == 1, "reported chatter never restarts Kanata")
  check(mock.pendingTimers() == 0, "no background polling after successful scan")
  check(not table.concat(mock.logs, "\n"):find("External keyboard disconnected", 1, true), "no false disconnect log")
  dock:stop()
end)

test("dock watcher: every matching event restarts the quiet period", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  tasksNamed(mock, "hammerspoon-kanata")[1]:complete(0, "already\n", "")

  emitKeyboard(mock, watcher, "removed")
  local oldTimer = dock._keyboardTimer
  mock.advance(2)
  emitKeyboard(mock, watcher, "removed")
  oldTimer.fn() -- A canceled callback must not clear or bypass the new timer.
  mock.advance(2)
  check(#mock.tasks == 1 and dock.is_keyboard_connected, "duplicate event extends the quiet period")
  mock.advance(1)
  check(#mock.tasks == 2 and not dock.is_keyboard_connected, "stable removal switches once after quiet period")
  check(mock.tasks[2].args[4] == "/tmp/kanata/internal.kbd", "stable removal selects internal profile")
  dock:stop()
end)

test("dock watcher: keyboard identity and actual presence decide the profile", function(mock)
  configureDock()
  mock.usbDevices = { { vendorID = 999, productID = C.dock.keyboard.productID } }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  check(dock.is_keyboard_connected == false, "same product ID from another vendor is not the keyboard")
  mock.tasks[1]:complete(0, "already\n", "")
  watcher:emit({ vendorID = 999, productID = C.dock.keyboard.productID, eventType = "added" })
  watcher:emit({ vendorID = C.dock.keyboard.vendorID, productID = 999, eventType = "added" })
  watcher:emit({ vendorID = C.dock.keyboard.vendorID, productID = C.dock.keyboard.productID, eventType = "unknown" })
  check(mock.pendingTimers() == 0, "partial matches and unknown events do not schedule work")

  emitKeyboard(mock, watcher, "removed", { C.dock.keyboard, C.dock.keyboard })
  mock.advance(3)
  check(dock.is_keyboard_connected == true and #mock.tasks == 2, "snapshot wins over removed event")
  mock.tasks[2]:complete(0, "switched\n", "")
  emitKeyboard(mock, watcher, "removed", { C.dock.keyboard })
  mock.advance(3)
  check(#mock.tasks == 2 and dock.is_keyboard_connected, "one remaining matching keyboard prevents disconnect")
  emitKeyboard(mock, watcher, "added", {})
  mock.advance(3)
  check(#mock.tasks == 3 and not dock.is_keyboard_connected, "empty snapshot wins over added event")
  dock:stop()
end)

test("dock watcher: custom debounce delay applies to a stable attachment", function(mock)
  configureDock()
  C.dock.keyboard.debounceSeconds = 5
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  mock.tasks[1]:complete(0, "already\n", "")
  emitKeyboard(mock, watcher, "added")
  mock.advance(3)
  check(#mock.tasks == 1, "configured delay replaces the default")
  mock.advance(2)
  check(#mock.tasks == 2 and dock.is_keyboard_connected, "stable attachment applies after configured delay")
  dock:stop()
end)

test("dock watcher: completion during debounce does not launch an outdated queued profile", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "removed")
  mock.advance(3)
  check(dock._desired_profile == "internal.kbd", "settled removal queues internal behind active external")
  emitKeyboard(mock, watcher, "added")
  mock.tasks[1]:complete(0, "switched\n", "")
  check(#mock.tasks == 1, "completion waits for the new quiet period")
  mock.advance(3)
  check(#mock.tasks == 1 and dock._desired_profile == "external.kbd", "return to completed profile needs no restart")
  check(dock._pendingSwitchResult == nil, "completed result is consumed once")
  dock:stop()
end)

test("dock watcher: completion during debounce applies a genuinely changed profile", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "removed")
  mock.tasks[1]:complete(0, "switched\n", "")
  check(#mock.tasks == 1, "successful completion does not bypass debounce")
  mock.advance(3)
  check(#mock.tasks == 2 and mock.tasks[2].args[4] == "/tmp/kanata/internal.kbd", "settled change starts once")
  dock:stop()
end)

test("dock watcher: failures during chatter retain one retry and its error", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "removed")
  mock.tasks[1]:complete(1, "", "first failure")
  check(#mock.tasks == 1, "failure does not retry during chatter")
  emitKeyboard(mock, watcher, "added")
  mock.advance(3)
  check(#mock.tasks == 2, "unchanged settled state still resumes the deferred retry")

  emitKeyboard(mock, watcher, "added")
  mock.tasks[2]:complete(1, "", "second failure")
  check(#mock.notifications == 0, "final failure waits until target is settled")
  mock.advance(3)
  check(#mock.tasks == 2 and #mock.notifications == 1, "second failure notifies without a third attempt")
  check(
    table.concat(mock.logs, "\n"):find("after one retry: second failure", 1, true) ~= nil,
    "failure detail survives debounce"
  )
  emitKeyboard(mock, watcher, "added")
  mock.advance(3)
  check(#mock.tasks == 2 and #mock.notifications == 1, "duplicates neither reset retry budget nor repeat notification")
  dock:stop()
end)

test("dock watcher: a changed target supersedes a deferred failed switch", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "removed")
  mock.tasks[1]:complete(1, "", "old target failed")
  mock.advance(3)
  check(#mock.tasks == 2 and mock.tasks[2].args[4] == "/tmp/kanata/internal.kbd", "new target replaces stale retry")
  mock.tasks[2]:complete(1, "", "new target failed")
  check(#mock.tasks == 3 and #mock.notifications == 0, "new target has its own one-retry budget")
  mock.tasks[3]:complete(1, "", "retry failed")
  check(#mock.tasks == 3 and #mock.notifications == 1, "new target still has a bounded retry")
  dock:stop()
end)

test("dock watcher: failed USB scans keep the profile and recover without another event", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "removed")
  mock.tasks[1]:complete(1, "", "restart failed")
  mock.usbDevices = nil
  mock.advance(3)
  check(
    dock.is_keyboard_connected == true and #mock.tasks == 1,
    "unknown USB state neither disconnects nor retries Kanata"
  )
  local logCount = #mock.logs
  mock.advance(30)
  check(#mock.logs == logCount and mock.pendingTimers() == 1, "failed scans keep one timer without repeated warnings")
  mock.usbDevices = {}
  mock.advance(3)
  check(
    #mock.tasks == 2 and not dock.is_keyboard_connected,
    "scan recovery applies actual state without a new USB event"
  )
  check(mock.tasks[2].args[4] == "/tmp/kanata/internal.kbd", "recovery supersedes the old failed target")
  check(mock.pendingTimers() == 0, "scan polling ends after recovery")
  dock:stop()
end)

test("dock watcher: unknown startup USB state does not select a profile", function(mock)
  configureDock()
  mock.usbDevices = nil
  local dock = require("watchers.dock")
  dock:start()
  check(dock.is_keyboard_connected == nil and #mock.tasks == 0, "startup scan failure is not a disconnect")
  check(mock.pendingTimers() == 1, "startup failure schedules a rescan")
  mock.usbDevices = { C.dock.keyboard }
  mock.advance(3)
  check(#mock.tasks == 1 and dock.is_keyboard_connected, "startup recovers when enumeration succeeds")
  dock:stop()
end)

test("dock watcher: stop and restart reject old timers, watchers and task results", function(mock)
  configureDock()
  mock.usbDevices = { C.dock.keyboard }
  local dock = require("watchers.dock")
  dock:start()
  local oldWatcher = mock.usbWatchers[#mock.usbWatchers]
  local oldTask = mock.tasks[1]
  emitKeyboard(mock, oldWatcher, "removed")
  local oldTimer = dock._keyboardTimer
  oldTask:complete(1, "", "deferred failure")
  dock:stop()
  oldTimer.fn()
  check(mock.pendingTimers() == 0 and #mock.tasks == 1, "stop cancels pending timer and deferred retry")

  dock:start()
  check(#mock.tasks == 2 and not dock.is_keyboard_connected, "restart samples present state immediately")
  local watcher = mock.usbWatchers[#mock.usbWatchers]
  emitKeyboard(mock, watcher, "added")
  local newTimer = dock._keyboardTimer
  oldWatcher.callback({ vendorID = 100, productID = 200, eventType = "added" })
  oldWatcher.callback({ vendorID = 400, productID = 300, eventType = "removed" })
  oldTimer.fn()
  oldTask:complete(1, "", "late old failure")
  check(
    dock._keyboardTimer == newTimer and mock.pendingTimers() == 1,
    "old callbacks cannot replace or clear new timer"
  )
  check(dock.is_docked == false and #mock.tasks == 2, "old lifecycle cannot affect dock state or Kanata")
  mock.advance(3)
  mock.tasks[2]:complete(0, "switched\n", "")
  check(#mock.tasks == 3 and mock.tasks[3].args[4] == "/tmp/kanata/external.kbd", "new lifecycle reconciles normally")
  dock:stop()
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
-- hotspot watcher: service order follows whether Wi-Fi is on the phone hotspot

local ETHERNET = "Thunderbolt Ethernet Slot 1"
local NETWORKSETUP = "/usr/sbin/networksetup"

local function serviceOrderOutput(names)
  local lines = { "An asterisk (*) denotes that a network service is disabled." }
  for i, name in ipairs(names) do
    local index = name == "Tailscale" and "*" or tostring(i)
    table.insert(lines, ("(%s) %s"):format(index, name))
    table.insert(lines, ("(Hardware Port: %s, Device: en%d)"):format(name, i))
    table.insert(lines, "")
  end
  return table.concat(lines, "\n")
end

local ETHERNET_FIRST = serviceOrderOutput({ ETHERNET, "Thunderbolt Bridge", "Wi-Fi", "Tailscale" })
local WIFI_FIRST = serviceOrderOutput({ "Wi-Fi", ETHERNET, "Thunderbolt Bridge", "Tailscale" })

local function setHotspot(mock, on)
  mock.netState["State:/Network/Interface/en0/IPv4"] = { Addresses = { on and "172.20.10.10" or "192.168.1.20" } }
end

local function startHotspot(mock, on)
  C.hotspot = { interface = "en0", subnetPrefix = "172.20.10.", wifiService = "Wi-Fi", ethernetService = ETHERNET }
  setHotspot(mock, on)
  local hotspot = require("watchers.hotspot")
  hotspot:start()
  return hotspot, mock.netStores[#mock.netStores]
end

local function lastTask(mock) return mock.tasks[#mock.tasks] end

local function sameList(a, b)
  if #a ~= #b then return false end
  for i = 1, #a do
    if a[i] ~= b[i] then return false end
  end
  return true
end

local function isReorder(task, names)
  local expected = { "-ordernetworkservices" }
  for _, name in ipairs(names) do
    table.insert(expected, name)
  end
  return task.launchPath == NETWORKSETUP and sameList(task.args, expected)
end

test("hotspot watcher: parses service order including disabled services", function()
  local hotspot = require("watchers.hotspot")
  local names = hotspot.parseOrder(ETHERNET_FIRST)
  check(sameList(names, { ETHERNET, "Thunderbolt Bridge", "Wi-Fi", "Tailscale" }), "names in order, (*) kept")
end)

test("hotspot watcher: moveAhead only moves the one service", function()
  local hotspot = require("watchers.hotspot")
  local names = { ETHERNET, "Thunderbolt Bridge", "Wi-Fi", "Tailscale" }
  local order = hotspot.moveAhead(names, "Wi-Fi", ETHERNET)
  check(order and sameList(order, { "Wi-Fi", ETHERNET, "Thunderbolt Bridge", "Tailscale" }), "Wi-Fi moved ahead")
  check(hotspot.moveAhead(order, "Wi-Fi", ETHERNET) == nil, "no change when already ahead")
  check(hotspot.moveAhead({ "Wi-Fi" }, ETHERNET, "Wi-Fi") == nil, "no change when a service is missing")
end)

test("hotspot watcher: joining the hotspot puts Wi-Fi ahead of Ethernet", function(mock)
  local hotspot, store = startHotspot(mock, false)
  check(store.started and store.keys[1] == "State:/Network/Interface/en0/IPv4", "watches Wi-Fi IPv4")
  check(#mock.tasks == 1 and lastTask(mock).args[1] == "-listnetworkserviceorder", "startup reads order")
  lastTask(mock):complete(0, ETHERNET_FIRST)
  check(#mock.tasks == 1, "Ethernet already ahead: no reorder")

  setHotspot(mock, true)
  store:emit()
  lastTask(mock):complete(0, ETHERNET_FIRST)
  check(
    isReorder(lastTask(mock), { "Wi-Fi", ETHERNET, "Thunderbolt Bridge", "Tailscale" }),
    "networksetup reorders Wi-Fi first without sudo"
  )
  lastTask(mock):complete(0)
  check(#mock.notifications == 0, "success does not notify")
  hotspot:stop()
end)

test("hotspot watcher: leaving the hotspot puts Ethernet back ahead", function(mock)
  local hotspot, store = startHotspot(mock, true)
  lastTask(mock):complete(0, WIFI_FIRST)
  check(#mock.tasks == 1, "Wi-Fi already ahead: no reorder")

  setHotspot(mock, false)
  store:emit()
  lastTask(mock):complete(0, WIFI_FIRST)
  check(
    isReorder(lastTask(mock), { ETHERNET, "Wi-Fi", "Thunderbolt Bridge", "Tailscale" }),
    "networksetup reorders Ethernet first"
  )
  hotspot:stop()
end)

test("hotspot watcher: a change during a run is applied after it", function(mock)
  local hotspot, store = startHotspot(mock, false)
  setHotspot(mock, true)
  store:emit()
  check(#mock.tasks == 1, "no second task while one runs")

  lastTask(mock):complete(0, ETHERNET_FIRST)
  check(#mock.tasks == 2 and lastTask(mock).args[1] == "-listnetworkserviceorder", "reruns after first run")
  lastTask(mock):complete(0, ETHERNET_FIRST)
  check(isReorder(lastTask(mock), { "Wi-Fi", ETHERNET, "Thunderbolt Bridge", "Tailscale" }), "rerun uses new state")
  hotspot:stop()
end)

test("hotspot watcher: a failed reorder notifies and logs the error", function(mock)
  local hotspot = startHotspot(mock, true)
  lastTask(mock):complete(0, ETHERNET_FIRST)
  lastTask(mock):complete(4, "** Error: The parameters were not valid.\n", "")
  check(#mock.notifications == 1, "one notification")
  check(mock.notifications[1].opts.subTitle == "Cannot put Wi-Fi ahead of " .. ETHERNET, "names the change")
  check(table.concat(mock.logs, "\n"):find("parameters were not valid", 1, true) ~= nil, "logs networksetup output")
  check(table.concat(mock.logs, "\n"):find("now ahead of", 1, true) == nil, "failure never logs success")
  hotspot:stop()
end)

test("hotspot + dock watchers: docking leaves Wi-Fi and order alone; hotspot still reorders", function(mock)
  local dock, usb = startDocked(mock)
  local hotspot, store = startHotspot(mock, false)
  lastTask(mock):complete(0, ETHERNET_FIRST)
  local tasks = #mock.tasks

  emitDock(usb, "removed")
  emitDock(usb, "added")
  check(#mock.tasks == tasks, "dock events start no networksetup tasks")
  check(mock.wifiReads == 0 and #mock.wifiChanges == 0, "dock events never touch Wi-Fi power")

  setHotspot(mock, true)
  store:emit()
  lastTask(mock):complete(0, ETHERNET_FIRST)
  check(
    isReorder(lastTask(mock), { "Wi-Fi", ETHERNET, "Thunderbolt Bridge", "Tailscale" }),
    "joining the hotspot while docked puts Wi-Fi first"
  )
  lastTask(mock):complete(0)

  emitDock(usb, "removed")
  check(#mock.tasks == tasks + 2, "undocking on the hotspot keeps Wi-Fi first")
  setHotspot(mock, false)
  store:emit()
  lastTask(mock):complete(0, WIFI_FIRST)
  check(
    isReorder(lastTask(mock), { ETHERNET, "Wi-Fi", "Thunderbolt Bridge", "Tailscale" }),
    "leaving the hotspot restores Ethernet first"
  )
  dock:stop()
  hotspot:stop()
end)

test("hotspot watcher: stop ignores late results and store events", function(mock)
  local hotspot, store = startHotspot(mock, true)
  local listTask = lastTask(mock)
  hotspot:stop()
  check(not store.started, "store stopped")
  listTask:complete(0, ETHERNET_FIRST)
  store.started = true
  store:emit()
  check(#mock.tasks == 1, "no tasks after stop")
end)

--------------------------------------------------------------------------------

print(("\n%d passed, %d failed"):format(passes, failures))
if failures > 0 then os.exit(1) end
