local obj = hs.hotkey.modal.new({}, nil)

obj.__index = obj
obj.name = "hyper"
obj.hyperBind = nil

function obj:bindPassThrough(key, app)
  self:bind({}, key, nil, function()
    if hs.application.get(app) then
      hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key)
    else
      hs.application.launchOrFocusByBundleID(app)
      hs.timer.waitWhile(
        function() return not hs.application.get(app):isFrontmost() end,
        function() hs.eventtap.keyStroke({ "cmd", "alt", "shift", "ctrl" }, key) end
      )
    end
  end)

  return self
end

function obj:start(opts)
  opts = opts or {}
  local hyperKey = opts["hyperKey"] or HYPER
  local hyperId = opts["id"] and fmt(".%s", opts["id"]) or ""

  self.hyperBind = hs.hotkey.bind({}, hyperKey, function() self:enter() end, function() self:exit() end)

  info(fmt("[START] %s%s", self.name, hyperId))

  return self
end

function obj:stop()
  self:delete()
  self.hyperBind:delete()

  return self
end

return obj
