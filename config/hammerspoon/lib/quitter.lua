local Settings = require("hs.settings")
local mods = Settings.get(CONFIG_KEY).keys.mods
local obj = {}

obj.__index = obj
obj.name = "quitter"
obj.debug = true
obj.modals = {}
obj.longPressKey = nil
obj.pressDelay = 2.5
obj.afterDelay = 1
obj.pressMode = "double"

local appExited = false

local dbg = function(...)
  if obj.debug then return _G.dbg(fmt(...), false) end
end

function obj.pressedFn()
  appExited = false
  hs.alert.show("⌘Q")
  hs.timer.usleep(1000000 * obj.pressDelay)
end

function obj.quit()
  if obj.pressMode == "long" and appExited then return end

  local app = hs.application.frontmostApplication()
  if app:bundleID() == obj.modalBundleID then app:kill() end

  appExited = true
  hs.alert.closeAll()

  if obj.pressMode == "double" then obj:stop() end
end

function obj:init(opts)
  opts = opts or {}
  obj.pressMode = opts["pressMode"] or "double"

  local id = opts["id"]
  obj.modalBundleID = id

  local app = hs.application.frontmostApplication()
  dbg(fmt("modal: %s, front: %s", obj.modalBundleID, app:bundleID()))

  if app:bundleID() ~= obj.modalBundleID then return end

  if obj.pressMode == "double" and obj.modals[obj.modalBundleID] == nil then
    obj.modals[obj.modalBundleID] = hs.hotkey.modal.new(mods.Casc, "q", "Press Cmd+Q again to quit")

    function obj.modal:entered()
      hs.timer.doAfter(obj.afterDelay, function() obj:stop({ id = obj.modalBundleID }) end)
    end
  end
  return self
end

function obj:start(_bundleID)
  local app = hs.application.frontmostApplication()
  dbg(fmt("modal: %s, front: %s", obj.modalBundleID, app:bundleID()))

  if app:bundleID() ~= obj.modalBundleID then
    obj:stop({ id = obj.modalBundleID })

    return
  end

  note(fmt("[START] quitter.%s", obj.modalBundleID))

  if obj.pressMode == "double" then
    obj.modals[obj.modalBundleID]:bind(mods.Casc, "q", obj.quit)
  elseif obj.pressMode == "long" then
    obj.longPressKey = hs.hotkey.bind(mods.Casc, "q", obj.pressedFn, nil, obj.quit)
  end

  obj.modal:bind("", "escape", function() obj:stop({ id = obj.modalBundleID }) end)

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local id = opts["id"]
  note(fmt("[STOP] quitter.%s", id))

  if obj.modals[id] then
    obj.modals[id]:exit()
    obj.modals = nil
  end

  if obj.longPressKey then
    obj.longPressKey:delete()
    obj.longPressKey = nil
  end

  obj.modalBundleID = nil

  return self
end

return obj
