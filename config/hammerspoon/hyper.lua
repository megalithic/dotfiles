local fmt = string.format
local M = hs.hotkey.modal.new({}, nil)
_G.Hypers = {}

M.__index = M
M.name = "hyper"
M.hyper = nil
M.key = HYPER

function M:bindPassThrough(mods, key, app)
  -- Build the passthrough modifiers: hyper + any additional mods
  local passthroughMods = { "cmd", "alt", "shift", "ctrl" }
  if mods and #mods > 0 then
    -- Add any extra mods that aren't already in hyper
    for _, mod in ipairs(mods) do
      local found = false
      for _, hyperMod in ipairs(passthroughMods) do
        if mod == hyperMod then found = true; break end
      end
      if not found then
        table.insert(passthroughMods, mod)
      end
    end
  end

  self:bind(mods, key, nil, function()
    if hs.application.get(app) then
      hs.eventtap.keyStroke(passthroughMods, key)
    else
      hs.application.launchOrFocusByBundleID(app)
      hs.timer.waitWhile(
        function()
          local appObj = hs.application.get(app)
          return not appObj or not appObj:isFrontmost()
        end,
        function() hs.eventtap.keyStroke(passthroughMods, key) end
      )
    end
  end)

  return self
end

function M:init(opts)
  opts = opts or {}

  if not opts.id then
    U.log.e("unable to start this instance; missing id")
    return
  end

  if _G.Hypers[opts.id] ~= nil then
    U.log.w(fmt("%s used", _G.Hypers[opts.id].id))

    return _G["Hypers"][opts.id]
  end

  self.id = opts.id
  self.key = opts.key or HYPER
  self.hyper = hs.hotkey.bind({}, self.key, function() self:enter() end, function() self:exit() end)

  _G.Hypers[opts.id] = self

  U.log.i(fmt("%s initialized", _G.Hypers[opts.id].id))

  return self
end

function M:start(opts) return self end

function M:stop()
  -- Remove from global registry using correct key (self.id, not self)
  if self.id and _G.Hypers[self.id] then
    _G.Hypers[self.id] = nil
  end

  -- Delete hotkey bindings
  if self.hyper then
    pcall(function() self.hyper:delete() end)
  end
  pcall(function() self:delete() end)

  return self
end

return M
