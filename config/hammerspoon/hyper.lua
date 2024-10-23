local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "hyper"
obj.hyper = nil
obj.key = HYPER

function obj:bindPassThrough(key, app)
  self:bind({}, key, nil, function()
    if hs.application.get(app) then
      hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key)
    else
      hs.application.launchOrFocusByBundleID(app)
      hs.timer.waitWhile(
        function() return not hs.application.get(app) and not hs.application.get(app):isFrontmost() end,
        function() hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key) end
      )
    end
  end)

  return self
end

function obj:init(opts)
  opts = opts or {}

  if not opts["id"] then
    error(fmt("[ERROR] %s -> unable to start this hyper; missing id", obj.name))
    return
  end

  if _G.hypers[opts["id"]] ~= nil then
    warn(fmt("[%s] %s%s (existing)", "INIT", self.name, opts["id"]))

    return _G["hypers"][opts["id"]]
  end

  local hyperId = opts["id"] and fmt(".%s", opts["id"]) or ""

  obj.key = opts["key"] or HYPER

  self.hyper = hs.hotkey.bind({}, obj.key, function() obj:enter() end, function() obj:exit() end)

  _G.hypers[opts["id"]] = self
  info(fmt("[%s] %s%s", "INIT", self.name, hyperId))

  return self
end

function obj:start(opts)
  if opts ~= nil then info(fmt("[%s] %s (%s)", "START", self.name, I(opts))) end

  return self
end

function obj:stop()
  self:delete()
  self.hyper:delete()

  return self
end

return obj
