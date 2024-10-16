local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "modality"
obj.alerts = {}
obj.isOpen = false
obj.debug = false
obj.modals = {}

function obj:delayedExit(delay)
  delay = delay or 1

  if delayedExitTimer ~= nil then
    delayedExitTimer:stop()
    delayedExitTimer = nil
  end

  delayedExitTimer = hs.timer.doAfter(delay, function()
    self:exit()
    delayedExitTimer = nil
  end)
  -- if obj.indicator ~= nil then obj.indicator:delete() end

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
  local win = hs.window.focusedWindow()

  if win == nil then
    obj:exit()
    return
  end

  obj.isOpen = true

  -- hs.window.highlight.start()
  local frame = win:frame()
  local screen = win:screen()

  -- HT: @evantravers
  obj.indicator = hs.canvas
    .new(frame)
    :appendElements({
      type = "rectangle",
      action = "stroke",
      strokeWidth = 2.0,
      -- strokeColor = { white = 0.8, alpha = 0.7 },
      strokeColor = { hex = "#F74F9E", alpha = 0.7 },
      roundedRectRadii = { xRadius = 14.0, yRadius = 14.0 },
    })
    :show()

  if win ~= nil then
    if screen == hs.screen.mainScreen() then
      local AppTitle = win:application():title()
      local image = hs.image.imageFromAppBundle(win:application():bundleID())
      local prompt = fmt("◱ : %s", AppTitle)
      if image ~= nil then prompt = fmt(": %s", AppTitle) end
      -- hs.alert.show({ text = prompt, image = image, screen = screen })
      hs.alert.showWithImage(prompt, image, nil, screen)
      obj:delayedExit(0.9)
    end
  else
    obj:exit()
  end

  return self
end

function obj:exited()
  obj.isOpen = false
  -- hs.window.highlight.stop()
  if obj.indicator ~= nil then obj.indicator:delete() end

  hs.fnutils.ieach(obj.alerts, function(id)
    if hs.alert ~= nil then hs.alert.closeSpecific(id) end
  end)

  hs.alert.closeAll()

  return self
end

function obj:toggle(_id)
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
  hyper:bind(modalityMods, modalityKey, function() obj:toggle(opts["id"]) end)

  hs.window.animationDuration = 0
  hs.window.highlight.ui.overlay = true

  info(fmt("[START] %s%s", self.name, modalityId))

  return self
end

function obj:stop()
  self:delete()
  self.alerts = {}
  self:exited()

  return self
end

return obj
