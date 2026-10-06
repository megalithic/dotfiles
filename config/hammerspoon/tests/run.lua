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
    docked = { wifi = "off" },
    undocked = { wifi = "on" },
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

test("dock watcher: startup applies connected state without tasks or timers", function(mock)
  mock.wifiDetails.interface = "en5"
  local dock, watcher = startDocked(mock)

  check(watcher.started, "USB watcher started")
  check(dock.is_docked == true, "matching TS4 is docked at startup")
  check(mock.wifiReads == 1, "startup reads actual Wi-Fi power once")
  check(#mock.wifiChanges == 1 and mock.wifiChanges[1].power == false, "startup turns Wi-Fi off")
  check(mock.wifiChanges[1].interface == "en5", "uses actual Wi-Fi interface, not hardcoded en0")
  check(table.concat(mock.logs, "\n"):find("Wi-Fi off on en5", 1, true) ~= nil, "power change is logged")
  mock.advance(3600)
  check(mock.wifiReads == 1 and #mock.wifiChanges == 1, "elapsed time causes no Wi-Fi work")
  check(#mock.tasks == 0 and mock.pendingTimers() == 0, "Wi-Fi uses no shell tasks or timers")

  dock:stop()
  check(watcher.stopped, "USB watcher stopped")
end)

test("dock watcher: startup undocked turns Wi-Fi on", function(mock)
  configureDock()
  C.dock.kanata.enabled = false
  mock.wifiDetails.power = false
  local dock = require("watchers.dock")
  dock:start()

  check(dock.is_docked == false, "no TS4 means undocked")
  check(#mock.wifiChanges == 1 and mock.wifiChanges[1].power == true, "undocked startup restores Wi-Fi")
  dock:stop()
end)

test("dock watcher: only state transitions change Wi-Fi", function(mock)
  local dock, watcher = startDocked(mock)
  local logs = #mock.logs
  emitDock(watcher, "added")
  check(mock.wifiReads == 1 and #mock.logs == logs, "duplicate connected event does nothing")

  emitDock(watcher, "removed")
  check(dock.is_docked == false and mock.wifiDetails.power == true, "disconnect immediately turns Wi-Fi on")
  emitDock(watcher, "removed")
  check(mock.wifiReads == 2, "duplicate disconnected event does nothing")

  emitDock(watcher, "added")
  check(dock.is_docked == true and mock.wifiDetails.power == false, "reconnect turns Wi-Fi off")
  check(#mock.wifiChanges == 3, "one power change per transition")
  dock:stop()
end)

test("dock watcher: unrelated USB events and unknown event types do nothing", function(mock)
  local dock, watcher = startDocked(mock)
  local logs = #mock.logs
  watcher:emit({ vendorID = 999, productID = 200, eventType = "removed" })
  watcher:emit({ vendorID = 100, productID = 999, eventType = "removed" })
  emitDock(watcher, "unknown")
  check(dock.is_docked == true and mock.wifiReads == 1, "both vendor and product must match a known event")
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
  check(#mock.wifiChanges == 0, "already-on Wi-Fi is unchanged while undocked")
  dock:stop()
end)

test("dock watcher: already-correct Wi-Fi is not set or logged", function(mock)
  mock.wifiDetails.power = false
  local dock, watcher = startDocked(mock)
  check(#mock.wifiChanges == 0, "already-off Wi-Fi is unchanged while docked")
  check(table.concat(mock.logs, "\n"):find("Wi-Fi", 1, true) == nil, "no Wi-Fi log for a no-op")

  mock.wifiDetails.power = true -- Changed externally, not by the dock watcher.
  emitDock(watcher, "removed")
  check(#mock.wifiChanges == 0, "disconnect checks actual power instead of cached target")
  check(table.concat(mock.logs, "\n"):find("Wi-Fi", 1, true) == nil, "no Wi-Fi log for already-on power")
  dock:stop()
end)

test("dock watcher: unavailable Wi-Fi interface notifies without retries", function(mock)
  mock.wifiDetails = nil
  local dock, watcher = startDocked(mock)
  check(#mock.wifiChanges == 0, "unavailable interface is not written")
  check(#mock.notifications == 1, "unavailable interface notifies")
  check(mock.notifications[1].opts.subTitle == "Cannot read Wi-Fi interface", "failure identifies interface lookup")
  emitDock(watcher, "added")
  mock.advance(60)
  check(mock.wifiReads == 1 and #mock.notifications == 1, "no duplicate event or background retries")
  dock:stop()
end)

test("dock watcher: incomplete Wi-Fi details do not select a fallback interface", function(mock)
  mock.wifiDetails = { power = true }
  local dock, watcher = startDocked(mock)
  check(#mock.wifiChanges == 0 and #mock.notifications == 1, "missing interface name notifies without guessing")
  mock.wifiDetails = { interface = "en0" }
  emitDock(watcher, "removed")
  check(#mock.wifiChanges == 0 and #mock.notifications == 2, "missing power state notifies without guessing")
  dock:stop()
end)

test("dock watcher: Wi-Fi power failures notify without success logs", function(mock)
  mock.wifiSetResult = false
  mock.wifiSetError = "permission denied"
  local dock, watcher = startDocked(mock)
  check(mock.wifiDetails.power == true, "failed power change leaves actual power unchanged")
  check(#mock.notifications == 1, "failed power change notifies")
  check(mock.notifications[1].opts.subTitle:find("permission denied", 1, true) ~= nil, "failure includes API error")
  check(table.concat(mock.logs, "\n"):find("Wi-Fi off on", 1, true) == nil, "failed change never logs success")
  emitDock(watcher, "added")
  mock.advance(60)
  check(#mock.wifiChanges == 1 and mock.pendingTimers() == 0, "failed change does not start retry machinery")

  mock.wifiDetails.power = false
  mock.wifiSetResult = nil
  mock.wifiSetError = nil
  emitDock(watcher, "removed")
  check(#mock.notifications == 2, "nil setPower result also notifies")
  check(table.concat(mock.logs, "\n"):find("Wi-Fi on on", 1, true) == nil, "nil result never logs success")
  dock:stop()
end)

test("dock watcher: stop ignores stale USB callbacks and restart reapplies state", function(mock)
  local dock, watcher = startDocked(mock)
  dock:stop()
  watcher.callback({ vendorID = 100, productID = 200, eventType = "removed" })
  check(mock.wifiReads == 1 and #mock.wifiChanges == 1, "stale callback does nothing after stop")
  mock.usbDevices = {}
  dock:start()
  check(dock.is_docked == false and mock.wifiDetails.power == true, "restart applies fresh USB state")
  check(#mock.tasks == 0 and mock.pendingTimers() == 0, "restart creates no Wi-Fi tasks or timers")
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
  check(mock.wifiDetails.power == true, "undocking still turns Wi-Fi on")
  emitKeyboard(mock, watcher, "removed")
  mock.advance(C.dock.keyboard.debounceSeconds)
  switches = tasksNamed(mock, "hammerspoon-kanata")
  check(
    #switches == 2 and switches[2].args[4] == "/tmp/kanata/internal.kbd",
    "keyboard removal selects internal profile"
  )
  check(mock.wifiReads == 2 and #mock.wifiChanges == 2, "keyboard removal does not touch Wi-Fi")
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
  local reads = mock.wifiReads
  oldWatcher.callback({ vendorID = 100, productID = 200, eventType = "added" })
  oldWatcher.callback({ vendorID = 400, productID = 300, eventType = "removed" })
  oldTimer.fn()
  oldTask:complete(1, "", "late old failure")
  check(
    dock._keyboardTimer == newTimer and mock.pendingTimers() == 1,
    "old callbacks cannot replace or clear new timer"
  )
  check(mock.wifiReads == reads and #mock.tasks == 2, "old lifecycle cannot affect Wi-Fi or Kanata")
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

print(("\n%d passed, %d failed"):format(passes, failures))
if failures > 0 then os.exit(1) end
