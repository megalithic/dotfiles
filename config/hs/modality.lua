local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "modality"
obj.alerts = {}
obj.isOpen = false
obj.debug = false

local dbg = function(str, ...)
  if type(str) == "string" then
    str = fmt(":: [%s] %s", obj.name, str)
  else
    str = fmt(":: [%s] %s", obj.name, I(str))
  end

  if obj.debug then
    if ... == nil then
      return _G.dbg(str, false)
    else
      return _G.dbg(fmt(str, ...), false)
    end
  end
end

-- function obj:start(opts)
--   opts = opts or {}
--   local hyperKey = opts["hyperKey"] or HYPER
--
--   -- sets up our config'd hyper key as the "trigger" for hyper key things; likely F19
--   obj.hyperBind = hs.hotkey.bind({}, hyperKey, function() obj:enter() end, function() obj:exit() end)
--
--   info(fmt("[START] %s %s", obj.name, opts["id"] or ""))
--
--   return self
-- end
--
-- function obj:stop()
--   obj:delete()
--   obj.hyperBind:delete()
--
--   return self
-- end
--

function obj:delayedExit(delay)
  delay = delay or 1

  if delayedExitTimer ~= nil then
    delayedExitTimer:stop()
    delayedExitTimer = nil
  end

  delayedExitTimer = hs.timer.doAfter(delay, function()
    dbg("delaying exit..")
    self:exit()
    delayedExitTimer = nil
  end)

  return self
end

-- function obj.selectWindow(index)
--   local app = obj.win():application()
--   local mainWindow = app:mainWindow()
--
--   local foundWin = mainWindow:otherWindowsAllScreens()[index]
--
--   if index < 1 or not foundWin then
--     warn(fmt("window not found for index %d", index))
--     return
--   end
--
--   app:getWindow(foundWin:title()):focus()
-- end

function obj:entered()
  obj.isOpen = true
  hs.window.highlight.start()
  local frame = hs.window.focusedWindow():frame()

  -- HT: @evantravers
  -- obj.indicator = hs.canvas
  --   .new(frame)
  --   :appendElements({
  --     type = "rectangle",
  --     action = "stroke",
  --     strokeWidth = 2.0,
  --     -- strokeColor = { white = 0.8, alpha = 0.7 },
  --     strokeColor = { hex = "#F74F9E", alpha = 0.7 },
  --     roundedRectRadii = { xRadius = 14.0, yRadius = 14.0 },
  --   })
  --   :show()

  obj.alerts = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local win = hs.window.focusedWindow()

    if win ~= nil then
      if screen == hs.screen.mainScreen() then
        local app_title = win:application():title()
        local image = hs.image.imageFromAppBundle(win:application():bundleID())
        local prompt = fmt("◱ : %s", app_title)
        if image ~= nil then prompt = fmt(": %s", app_title) end
        -- hs.alert.show({ text = prompt, image = image, screen = screen })
        hs.alert.showWithImage(prompt, image, nil, screen)
        self:delayedExit(1)
      end
    else
      obj:exit()
    end

    return self
  end)
end

function obj:exited()
  obj.isOpen = false
  hs.window.highlight.stop()
  hs.fnutils.ieach(obj.alerts, function(id)
    if hs.alert ~= nil then hs.alert.closeSpecific(id) end
    if obj.indicator ~= nil then obj.indicator:delete() end
  end)
  hs.alert.closeAll()
  dbg("exited modal")

  return self
end

function obj:toggle()
  if obj.isOpen then
    obj:exit()
  else
    obj:enter()
  end

  return self
end

-- function obj:init(opts)
--   opts = opts or {}
--   Hyper = L.load("lib.hyper", { id = obj.name }):start()
--
--   hs.window.animationDuration = 0
--   hs.window.highlight.ui.overlay = true
--
--   return self
-- end
--
function obj:start(opts)
  local modalityId = opts["id"] and fmt(".%s", opts["id"]) or ""
  local modalityMods = opts["mods"] or {}
  local modalityKey = opts["key"] or nil

  if modalityKey == nil then
    error(fmt("[ERROR] %s -> unable to start modality for modality%s; missing bind key", self.name, modalityId))
    return self
  end

  local hyper = require("hyper"):start({ id = fmt("modality%s", modalityId) })
  hyper:bind(modalityMods, modalityKey, function() self:toggle() end)

  hs.window.animationDuration = 0
  hs.window.highlight.ui.overlay = true

  info(fmt("[START] %s%s", self.name, modalityId))

  return self
end

function obj:stop()
  self:delete()
  self.alerts = {}
  -- L.unload("lib.hyper", obj.name)

  return self
end

return obj
