local obj = {}

obj.__index = obj
obj.name = "keyshowr"
obj.debug = false
--[[ CONSTS ]]

local EXTRA_MOD_TO_CHAR = {
  hyper = "󰣙", -- alts: 󰣙✧
}

local MOD_TO_CHAR = {
  ctrl = "⌃",
  alt = "⌥",
  cmd = "⌘",
  shift = "⇧",
}

local CHAR_TO_CHAR = {
  padclear = "⌧",
  padenter = "↵",
  _return = "↩",
  tab = "⇥",
  space = "␣",
  delete = "⌫",
  escape = "⎋",
  help = "?⃝",

  home = "↖",
  pageup = "⇞",
  forwarddelete = "⌦",
  _end = "↘",
  pagedown = "⇟",
  left = "←",
  right = "→",
  down = "↓",
  up = "↑",

  shift = "",
  rightshift = "",
  cmd = "",
  rightcmd = "",
  alt = "",
  rightalt = "",
  ctlr = "",
  rightctrl = "",
  capslock = "⇪",
  fn = "",

  f19 = "hyper ",
}

---@type string[]
local extra_mods = {}

---@type string
local text = ""

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end
--
-- local log = {
--   df = function(...) dbg(..., false) end,
-- }

function obj:init()
  local event_types = hs.eventtap.event.types

  obj.keyshowr = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
  }, function(evt)
    local type = evt:getType()
    local is_down = type == event_types.keyDown
    local is_up = type == event_types.keyUp
    local flags = evt:getFlags()
    local char = hs.keycodes.map[evt:getKeyCode()]

    -- convert f19 to the Hyper mods
    if char == "f19" then
      if is_down then
        extra_mods.hyper = true
      elseif is_up then
        extra_mods.hyper = nil
      end

      char = nil
    end

    for extra_mod, extra_mod_char in pairs(EXTRA_MOD_TO_CHAR) do
      if extra_mods[extra_mod] then
        text = text .. extra_mod_char
        dbg(fmt("extra mods text: %s", text))
      end
    end

    for mod, mod_char in pairs(MOD_TO_CHAR) do
      if flags[mod] then text = text .. mod_char end
    end

    -- on key down, add the char
    if type == event_types.keyDown then
      if char ~= nil then
        char = CHAR_TO_CHAR[char] or CHAR_TO_CHAR["_" .. char] or char
        text = text .. char
      end
    end

    -- if ((not flags.ctrl) and not flags.alt and not flags.cmd) or type(character) ~= "string" then return end
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
        })[char] or char, "^%l", string.upper),
      {
        strokeWidth = 0,
        fillColor = { white = 0.1 },
        textColor = { white = 0.9 },
        textSize = 32,
        radius = 5,
        fadeInDuration = 0,
        atScreenEdge = 1,
      }
    )

    char = nil
    text = ""
    extra_mods = {}
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
  text = ""
  extra_mods = {}
  -- obj.keyshowr = nil
  return self
end

return obj
