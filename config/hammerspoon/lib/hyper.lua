local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.modal = nil
obj.hyperBind = nil

local pressed = function() obj.modal:enter() end
local released = function() obj.modal:exit() end

function obj:bind(mod, key, pressedFn, releasedFn)
  P(
    fmt(
      "bind args: {mod: %s, key: %s, msg: %s, pressedFn: %s, releasedFn: %s, repeatedFn:%s}",
      mod,
      key,
      nil,
      pressedFn,
      releasedFn,
      nil
    )
  )

  -- NOTE:
  -- can omit mod; but it breaks if no mod and no pressedFn; so we shift arg assignments;
  -- FIXME: find a safer/better way!
  if not pressedFn and not releasedFn then
    mod = {}
    key = mod
    -- msg = pressedFn
    pressedFn = key
    releasedFn = pressedFn
    -- repeatedFn = nil
  end

  -- call the original modal bind
  obj.modal:bind(mod, key, nil, function()
    if pressedFn ~= nil and type(pressedFn) == "function" then pressedFn() end
  end, function()
    if releasedFn ~= nil and type(releasedFn) == "function" then releasedFn() end
  end, function()
    -- if repeatedFn ~= nil and type(repeatedFn) == "function" then repeatedFn() end
  end)
end

function obj:init(opts)
  opts = opts or {}
  P(fmt("hyper:init(%s) loaded.", hs.inspect(opts)))

  -- gives us a hotkey modal to bind to
  obj.modal = hs.hotkey.modal.new({}, nil)

  return self
end

function obj:start()
  P(fmt("hyper:start() executed."))
  local hyper = Settings.get("_mega_config").keys.hyper

  -- sets up our config'd hyper key as the "trigger" for hyper key things; likely F19
  obj.hyperBind = hs.hotkey.bind({}, hyper, pressed, released)
  return self
end

function obj:stop()
  P(fmt("hyper:stop() executed."))

  if obj.hyperBind ~= nil then obj.hyperBind:delete() end
  if obj.modal ~= nil then obj.modal:delete() end

  return self
end

return obj
