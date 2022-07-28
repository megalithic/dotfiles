local alert = require("utils.alert")
local Settings = require("hs.settings")
local mods = Settings.get(CONFIG_KEY).keys.mods
local apps = Settings.get(CONFIG_KEY).bindings.apps
local obj = {}

obj.__index = obj
obj.name = "quitter"
obj.debug = true
obj.mode = "double" -- or "long"

local modal = nil
local longPressKey = nil
local pressDelay = 0.1
local afterDelay = 1
local activeModalApp = nil

local appExited = false

local dbg = function(...)
  if obj.debug then return _G.dbg(fmt(...), false) end
end

local function teardown()
  if modal then modal:exit() end

  if longPressKey then longPressKey:delete() end

  activeModalApp = nil
end

function obj.pressedFn()
  alert.show("Hold ⌘Q")
  appExited = false

  hs.timer.usleep(1000000 * pressDelay)
end

function obj.quit()
  if obj.mode == "long" and appExited then return end
  local app = hs.application.frontmostApplication()

  app:kill()
  appExited = true
  hs.alert.closeAll()

  if obj.mode == "double" then obj:stop() end
end

function obj:start(opts)
  opts = opts or {}
  obj.mode = opts["mode"]
  if obj.mode == "double" then
    modal = hs.hotkey.modal.new(mods.Casc, "q", "Press Cmd+Q again to quit")

    function modal:entered()
      local app = hs.application.frontmostApplication()
      activeModalApp = app:bundleID()
      local enabled = apps[app:bundleID()] and apps[app:bundleID()].quitGuard

      if not enabled then
        obj.quit()
        obj:stop()
      end

      hs.timer.doAfter(afterDelay, function() obj:stop({ id = activeModalApp }) end)
    end

    modal:bind(mods.Casc, "q", obj.quit)
    modal:bind("", "escape", function() obj:stop({ id = activeModalApp }) end)
  elseif obj.mode == "long" then
    hs.hotkey.bind(mods.Casc, "q", obj.pressedFn, nil, obj.quit)
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
