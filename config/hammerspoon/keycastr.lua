local obj = {}

obj.__index = obj
obj.name = "keycastr"
obj.debug = false

local TEXT_SIZE = 42
local CANVAS_HEIGHT = 56
local V_MARGIN = 32

local H_PADDING = 6
local FILL_COLOR = { white = 1.0, alpha = 0.3 }

local MOD_TO_CHAR = {
  hyper = "⍟", -- alts: 󰫣󱙫󰦤󰣙✧ ●■□▪▫
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
  help = "󰘥",

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
  f19 = "",
}

obj.canvas = nil
obj.modsEventTap = nil
obj.keysEventTap = nil

local mods = {}
local curr_key_str = nil

local releasing_chord = false
local chord_release_timer = nil

local event_types = hs.eventtap.event.types

local function maybe_update_canvas()
  if releasing_chord then
    assert(chord_release_timer)
    return
  end

  local text = ""

  for mod_name, _ in pairs(mods) do
    text = text .. MOD_TO_CHAR[mod_name]
  end

  if curr_key_str ~= nil then text = text .. curr_key_str end

  if text == "" then
    obj.canvas:hide()
    return
  end
  local text_elem_size = obj.canvas:minimumTextSize(2, text)
  obj.canvas:size({
    w = text_elem_size.w + 2 * H_PADDING,
    h = CANVAS_HEIGHT,
  })
  obj.canvas[2].text = text
  obj.canvas:show()
end

local function on_down()
  releasing_chord = false
  if chord_release_timer then
    chord_release_timer:stop()
    chord_release_timer = nil
  end
end

local function on_up()
  if releasing_chord then
    assert(chord_release_timer)
    return
  end
  assert(chord_release_timer == nil)
  if curr_key_str == nil then
    -- it's not a proper "chord" we're releasing if not regular key
    -- was pressed; it's just some combo of modifiers
    return
  end
  releasing_chord = true
  chord_release_timer = hs.timer.doAfter(0.25, function()
    releasing_chord = false
    chord_release_timer = nil
    maybe_update_canvas()
  end)
end

---@param new_value boolean?
local function on_down_up(new_value)
  if new_value then
    on_down()
  else
    on_up()
  end
end

---@param mod_name string
---@param new_value boolean?
local function set_mod(mod_name, new_value)
  new_value = new_value or nil
  local old_value = mods[mod_name]
  mods[mod_name] = new_value
  if new_value ~= old_value then on_down_up(new_value) end
end

local function handle_mod_event(e)
  local e_flags = e:getFlags()
  for _, mod_name in pairs({ "ctrl", "alt", "cmd", "shift" }) do
    set_mod(mod_name, e_flags[mod_name])
  end
  maybe_update_canvas()
end

local function handle_key_event(e)
  local is_down = e:getType() == event_types.keyDown
  local e_key_code = e:getKeyCode()

  -- convert f19 to the Hyper mod
  if e_key_code == hs.keycodes.map.f19 then
    set_mod("hyper", is_down)
    maybe_update_canvas()
  end

  local e_key_str = hs.keycodes.map[e_key_code]
  e_key_str = (CHAR_TO_CHAR[e_key_str] or CHAR_TO_CHAR["_" .. e_key_str] or e_key_str)
  -- modifiers are translated to empty strings, so don't
  -- use those to update curr_key_str
  if e_key_str == "" then return end

  on_down_up(is_down)
  curr_key_str = is_down and e_key_str or nil
  maybe_update_canvas()
end

function obj:start()
  local screen = hs.screen.primaryScreen()
  local screen_frame = screen:frame()

  self.canvas = hs.canvas.new({
    x = screen_frame.x2 / 2, -- centered'ish
    y = screen_frame.y2 - V_MARGIN - CANVAS_HEIGHT,
  })
  self.canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = FILL_COLOR,
    roundedRectRadii = { xRadius = 4, yRadius = 4 },
  })
  self.canvas:appendElements({
    type = "text",
    textFont = "JetBrainsMono Nerd Font",
    textSize = TEXT_SIZE,
    textAlignment = "center",
  })

  self.modsEventTap = hs.eventtap
    .new({
      event_types.flagsChanged,
    }, handle_mod_event)
    :start()

  self.keysEventTap = hs.eventtap
    .new({
      event_types.keyDown,
      event_types.keyUp,
    }, handle_key_event)
    :start()

  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop(delay)
  if delay then
    hs.timer.doAfter(delay, function()
      if obj.modsEventTap then obj.modsEventTap:stop() end
      if obj.keysEventTap then obj.keysEventTap:stop() end
      if obj.canvas then obj.canvas:hide() end
    end)
  else
    if obj.modsEventTap then obj.modsEventTap:stop() end
    if obj.keysEventTap then obj.keysEventTap:stop() end
    if obj.canvas then obj.canvas:hide() end
  end

  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
