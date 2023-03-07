local obj = {}

obj.__index = obj
obj.name = "keyshowr"
obj.debug = false

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

local log = {
  df = function(...) dbg(..., false) end,
}

function obj:init()
  obj.keyshowr = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
  }, function(event)
    local flags = event:getFlags()
    local character = hs.keycodes.map[event:getKeyCode()]
    if ((not flags.ctrl) and not flags.alt and not flags.cmd) or type(character) ~= "string" then return end
    hs.alert.closeAll(0)
    hs.alert(
      (flags.ctrl and "⌃" or "")
        .. (flags.alt and "⌥" or "")
        .. (flags.shift and "⇧" or "")
        .. (flags.cmd and "⌘" or "")
        .. string.gsub(({
          ["return"] = "⏎",
          ["delete"] = "⌫",
          ["escape"] = "⎋",
          ["space"] = "␣",
          ["tab"] = "⇥",
          ["up"] = "↑",
          ["down"] = "↓",
          ["left"] = "←",
          ["right"] = "→",
          ["F19"] = "",
        })[character] or character, "^%l", string.upper),
      {
        strokeWidth = 0,
        fillColor = { white = 0.1 },
        textColor = { white = 0.9 },
        textSize = 13,
        radius = 5,
        fadeInDuration = 0,
        atScreenEdge = 1,
      }
    )
  end)

  return self
end

function obj:start()
  if not obj.keyshowr then obj:init() end
  obj.keyshowr:start()

  return self
end

function obj:stop()
  if obj.keyshowr then obj.keyshowr:stop() end
  -- obj.keyshowr = nil
  return self
end

return obj
