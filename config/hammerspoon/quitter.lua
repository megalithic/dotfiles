-- Quitter: Prevents accidental Cmd+Q quits
-- REF: https://github.com/Hammerspoon/Spoons/blob/master/Source/HoldToQuit.spoon/init.lua
--
-- Modes:
--   "single" = one Cmd+Q quits (useful with nuke=true for instant death apps like Zoom)
--   "double" = press Cmd+Q twice within 1s to quit
--   "long"   = hold Cmd+Q for 1s to quit
--
-- Options:
--   nuke = true means use kill9() (SIGKILL) instead of graceful kill()

local obj = {}

obj.__index = obj
obj.name = "quitter"
obj.longDelay = 1 -- seconds to hold for "long" mode
obj.doubleDelay = 1 -- seconds window for "double" mode

-- Internal state
local doubleModal = nil
local longTimer = nil
local quitHotkey = nil

-- Check if current app is protected by quitter
local function getAppConfig()
  local app = hs.application.frontmostApplication()
  if not app then return nil, nil end

  local bundleID = app:bundleID()
  local config = C.quitters[bundleID]

  return app, config
end

-- Perform the quit action (graceful or nuke)
local function performQuit(app, config)
  if not app then return end

  local appName = app:name()
  local useNuke = config and config.nuke

  if useNuke then
    U.log.i(string.format("[quitter] NUKING %s (%s)", appName, app:bundleID()))
    app:kill9()
  else
    U.log.i(string.format("[quitter] Quitting %s (%s)", appName, app:bundleID()))
    app:kill()
  end

  hs.alert.closeAll()
end

-- Clean up double mode modal
local function exitDoubleMode()
  if doubleModal then
    doubleModal:exit()
    doubleModal:delete()
    doubleModal = nil
  end
end

-- Handle Cmd+Q press
local function onPress()
  local app, config = getAppConfig()

  -- Not protected - quit immediately
  if not config then
    if app then app:kill() end
    return
  end

  local mode = config.mode or "double"

  if mode == "single" then
    -- Single mode: quit immediately (with nuke if configured)
    performQuit(app, config)
  elseif mode == "double" then
    -- Double mode: enter modal for second press
    exitDoubleMode() -- Clean up any existing modal

    doubleModal = hs.hotkey.modal.new()

    local appName = app and app:name() or "App"
    hs.alert.show("Press ⌘Q again to quit " .. appName, 1)

    -- Bind second Cmd+Q press
    doubleModal:bind({ "cmd" }, "q", function()
      performQuit(app, config)
      exitDoubleMode()
    end)

    -- Escape to cancel
    doubleModal:bind("", "escape", function()
      hs.alert.closeAll()
      exitDoubleMode()
    end)

    doubleModal:enter()

    -- Auto-exit after timeout
    hs.timer.doAfter(obj.doubleDelay, function() exitDoubleMode() end)
  elseif mode == "long" then
    -- Long mode: start timer, quit if held long enough
    if longTimer then longTimer:stop() end

    longTimer = hs.timer.doAfter(obj.longDelay, function()
      local currentApp, currentConfig = getAppConfig()
      -- Verify still same app and still long mode
      if currentApp and currentConfig and currentConfig.mode == "long" then performQuit(currentApp, currentConfig) end
      longTimer = nil
    end)
  end
end

-- Handle Cmd+Q release (for long mode)
local function onRelease()
  local app, config = getAppConfig()

  -- Only relevant for long mode
  if config and config.mode == "long" then
    if longTimer then
      -- Released before timeout - show hint, don't quit
      longTimer:stop()
      longTimer = nil

      local appName = app and app:name() or "App"
      hs.alert.show("Hold ⌘Q to quit " .. appName, 1)
    end
  end
end

function obj:start(opts)
  opts = opts or {}

  -- Bind Cmd+Q with press and release handlers
  quitHotkey = hs.hotkey.bind({ "cmd" }, "q", onPress, onRelease)

  U.log.i("started")
  return self
end

function obj:stop()
  if quitHotkey then
    quitHotkey:delete()
    quitHotkey = nil
  end
  exitDoubleMode()
  if longTimer then
    longTimer:stop()
    longTimer = nil
  end
  U.log.i("stopped")
  return self
end

return obj
