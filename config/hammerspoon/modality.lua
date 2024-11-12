local obj = hs.hotkey.modal.new({}, nil, "modality")

obj.__index = obj
obj.name = "modality"
obj.mods = nil
obj.key = nil
obj.alerts = {}
obj.isOpen = false
obj.debug = false
obj.hyper = {}
obj.initOpts = {}
obj.delayedExitTimer = nil

function obj.cleanModality()
  hs.window.highlight.stop()
  if obj.indicator ~= nil then obj.indicator:delete() end

  hs.fnutils.ieach(obj.alerts, function(id)
    if hs.alert ~= nil then hs.alert.closeSpecific(id) end
  end)

  hs.alert.closeAll()
end

function obj.updateIndicator(win)
  obj.cleanModality()

  hs.window.highlight.start()
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
end

function obj:delayedExit(delay)
  delay = delay or 1

  if self.delayedExitTimer ~= nil then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end

  self.delayedExitTimer = hs.timer.doAfter(delay, function() self:exit() end)

  return self
end

function obj:exited()
  self.isOpen = false
  self.cleanModality()

  if self.delayedExitTimer ~= nil then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end

  return self
end

function obj:entered()
  local win = hs.window.focusedWindow()

  if win == nil then
    self:exit()

    return
  end

  self.isOpen = true
  self.updateIndicator(win)

  return self
end

function obj:toggle(_id)
  if self.isOpen then
    self:exit()
  else
    self:enter()
  end

  return self
end

function obj:init(opts)
  self.initOpts = opts or {}

  if not self.initOpts["id"] then
    error(fmt("[ERROR] %s -> unable to init this modality; missing id", self.name))
    return
  end

  -- if _G.modalities[self.initOpts["id"]] ~= nil then
  --   warn(fmt("[%s] %s%s (existing)", "INIT", self.name, self.initOpts["id"]))

  --   return _G["modalities"][self.initOpts["id"]]
  -- end

  obj.mods = self.initOpts["mods"] or {}
  obj.key = self.initOpts["key"] or nil

  if obj.key == nil and obj.mods == nil then
    error(
      fmt("[ERROR] %s -> unable to start modality.%s; missing binding key or binding mods", self.name, self.initOpts.id)
    )
    return
  end

  obj.hyper = req("hyper", { id = fmt("modality.%s", self.initOpts["id"]) })

  hs.window.animationDuration = 0
  hs.window.highlight.ui.overlay = true

  -- _G.modalities[self.initOpts["id"]] = self
  info(fmt("[INIT] %s.%s", self.name, self.initOpts.id))

  return self
end

function obj:start(opts)
  opts = self.initOpts or opts or {}

  self.hyper:start()
  self.hyper:bind(self.mods, self.key, function()
    self:toggle(opts["id"])
    -- note(
    --   fmt(
    --     "[RUN] %s.%s/toggle/%s (%d)",
    --     self.name,
    --     self.initOpts.id,
    --     obj.isOpen,
    --     req("utils").table.length(_G.modalities)
    --   )
    -- )
  end)

  info(fmt("[START] %s.%s (%s)", self.name, self.initOpts.id, I(opts)))

  return self
end

function obj:stop()
  self.hyper:stop()
  self.alerts = {}
  self:exit()
  self:delete()

  return self
end

return obj
