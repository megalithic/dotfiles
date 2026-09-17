local fmt = string.format
local M = hs.hotkey.modal.new({}, nil)
_G.Hypers = {}

M.__index = M
M.name = "hyper"
M.hyper = nil
M.key = HYPER

-- Launch/focus an app, then send a keystroke once it is frontmost.
-- Bounded: hs.timer.waitWhile polls forever (1s default) if the app never
-- fronts (launch failure, quit during launch); give up after `timeout`s.
local function sendKeyWhenFrontmost(app, mods, key, timeout)
  hs.application.launchOrFocusByBundleID(app)

  local deadline = hs.timer.secondsSinceEpoch() + (timeout or 10)
  local timedOut = false
  hs.timer.waitWhile(function()
    if hs.timer.secondsSinceEpoch() > deadline then
      timedOut = true
      return false
    end
    local appObj = hs.application.get(app)
    return not appObj or not appObj:isFrontmost()
  end, function()
    if timedOut then
      U.log.wf("gave up waiting for %s to front", app)
      return
    end
    hs.eventtap.keyStroke(mods, key)
  end, 0.1)
end

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
      sendKeyWhenFrontmost(app, passthroughMods, key)
    end
  end)

  return self
end

-- Bind a Hyper chord (mods+key, evaluated inside the Hyper modal) so that it
-- launches/focuses `app` and then sends a clean app-native chord
-- (targetMods+targetKey) to it. Unlike bindPassThrough, the chord delivered to
-- the app is decoupled from Hyper: the app only ever sees its own keybinding.
function M:bindAppChord(mods, key, app, targetMods, targetKey)
  targetMods = targetMods or {}

  self:bind(mods, key, nil, function()
    local appObj = hs.application.get(app)
    if appObj and appObj:isFrontmost() then
      hs.eventtap.keyStroke(targetMods, targetKey)
    else
      sendKeyWhenFrontmost(app, targetMods, targetKey)
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

  -- All ids share this one modal (M is a single hs.hotkey.modal); bind the
  -- physical hyper key only once. Rebinding per id stacked duplicate hotkey
  -- objects on the same key.
  if not self.hyper then
    self.key = opts.key or HYPER
    self.hyper = hs.hotkey.bind({}, self.key, function() self:enter() end, function() self:exit() end)
  elseif opts.key and opts.key ~= self.key then
    U.log.wf("hyper already bound to %s; ignoring key %s for id %s", self.key, opts.key, opts.id)
  end

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
