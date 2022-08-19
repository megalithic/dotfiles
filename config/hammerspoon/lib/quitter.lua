-- @REF https://github.com/Hammerspoon/Spoons/blob/master/Source/HoldToQuit.spoon/init.lua

local alert = require("utils.alert")
local Settings = require("hs.settings")
local mods = Settings.get(CONFIG_KEY).keys.mods
local apps = Settings.get(CONFIG_KEY).bindings.apps
local obj = {}

obj.__index = obj
obj.name = "quitter"
obj.debug = true
obj.mode = "double" -- or "long"
obj.longDelay = 1

local modal = nil
local longTimer = nil
local longHotkey = nil
local afterDelay = 1

local function guarded()
  local app = hs.application.frontmostApplication()
  local appConfig = apps[app:bundleID()]
  local enabled = appConfig and appConfig.quitter ~= nil and appConfig.quitter

  if enabled then note(fmt(":: quitter activated for %s", app:bundleID())) end

  return enabled
end

local function maybe_force_quit()
  if not guarded() then
    obj.quit()
    return
  end
end

local function teardown()
  if modal then modal:exit() end
  if longTimer then longTimer:stop() end
end

function obj.pressedFn()
  if obj.mode == "double" then obj.quit() end
  if obj.mode == "long" then
    maybe_force_quit()
    longTimer:start()
  end
end

function obj:releasedFn()
  maybe_force_quit()

  if longTimer:running() then
    longTimer:stop()
    local app = hs.application.frontmostApplication()
    hs.alert.show("Hold ⌘Q to quit " .. app:name())
  end
end

function obj.quit()
  local app = hs.application.frontmostApplication()
  app:kill()
  hs.alert.closeAll()
  obj:stop()
end

function obj:start(opts)
  opts = opts or {}
  obj.mode = opts["mode"]

  if obj.mode == "double" then
    modal = hs.hotkey.modal.new(mods.Casc, "q", "Press Cmd+Q again to quit")

    function modal:entered()
      maybe_force_quit()
      -- kill our modal after a time of no follow-up keypresses
      hs.timer.doAfter(afterDelay, function() obj:stop() end)
    end

    modal:bind(mods.Casc, "q", obj.pressedFn)
    modal:bind("", "escape", function() obj:stop() end)
  elseif obj.mode == "long" then
    if longTimer then
      longTimer:start()
    else
      longTimer = hs.timer.delayed.new(obj.longDelay, obj.quit)
    end

    if longHotkey then
      longHotkey:enable()
    else
      longHotkey = hs.hotkey.bind(mods.Casc, "q", obj.pressedFn, obj.releasedFn)
    end
  end

  note(fmt("[START] %s", obj.name))

  return self
end

function obj:stop(opts)
  opts = opts or {}

  teardown()

  return self
end

return obj
