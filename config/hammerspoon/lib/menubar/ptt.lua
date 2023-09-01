-- Derived from the PushToTalk Spoon and then heavily modified for my use cases

local obj = {}

obj.__index = obj
obj.name = "ptt"
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

local template = require("utils").template
local alert = require("utils.alert")
local pttKey = C.keys.ptt

obj.defaultState = "push-to-talk"
obj.mic = hs.audiodevice.defaultInputDevice()
obj.inputs = hs.audiodevice.allInputDevices()

obj.state = obj.defaultState
obj.defaultInputVolume = 65
obj.pushed = false

local talkIcon = require("hs.styledtext").new("", { font = { name = defaultFont.name, size = 13 } })
local muteIcon = require("hs.styledtext").new("", { font = { name = defaultFont.name, size = 13 } })
obj.icons = { ["push-to-mute"] = talkIcon, ["push-to-talk"] = muteIcon }

obj.states = function()
  log.df("current module.state from module.states(): %s", obj.state)

  return {
    { title = "Push-to-talk", state = "push-to-talk", checked = (obj.state == "push-to-talk") },
    { title = "Push-to-mute", state = "push-to-mute", checked = (obj.state == "push-to-mute") },
  }
end

-- function to return table values to `+` separated string
local to_psv = function(tbl)
  local s = ""

  for _, p in ipairs(tbl) do
    s = s .. "+" .. p
  end

  return string.sub(s, 2) -- remove first comma
end

function obj.setAllInputsMuted(muted)
  local inputVolume = muted and 0 or obj.defaultInputVolume

  for _i, input in ipairs(obj.inputs) do
    input:setInputMuted(muted)
    input:setInputVolume(inputVolume)
  end

  obj.mic:setInputMuted(muted)
  obj.mic:setInputVolume(inputVolume)
end

-- 2023-07-19 14:16:04: 14:16:04 ERROR:   LuaSkin: hs.timer callback error: /Users/seth/.config/hammerspoon/lib/menubar/ptt.lua:60: ERROR: incorrect type 'nil' for argument 2 (expected boolean)
-- stack traceback:
-- 	[C]: in method 'setMuted'
-- 	/Users/seth/.config/hammerspoon/lib/menubar/ptt.lua:60: in function 'lib.menubar.ptt.setAllInputsMuted'
-- 	...ave.Browser.dev.app.kjgfgldnnfoeklkmfkjfagphfepbbdan.lua:67: in upvalue 'actionFn'
-- 	...mmerspoon.app/Contents/Resources/extensions/hs/timer.lua:125: in function <...mmerspoon.app/Contents/Resources/extensions/hs/timer.lua:122>
--
--
local showState = function()
  if obj.pushed then log.df("device to handle: %s", obj.mic) end

  -- starting point:
  local muted = false

  if obj.state == "push-to-talk" then
    if obj.pushed then
      obj.menubar:setTitle(obj.icons["push-to-mute"])
      muted = false
    else
      obj.menubar:setTitle(obj.icons["push-to-talk"])
      muted = true
    end
  elseif obj.state == "push-to-mute" then
    if obj.pushed then
      obj.menubar:setTitle(obj.icons["push-to-talk"])
      muted = true
    else
      obj.menubar:setTitle(obj.icons["push-to-mute"])
      muted = false
    end
  end

  obj.setAllInputsMuted(muted)
end

local buildMenu = function()
  local menutable = hs.fnutils.map(obj.states(), function(item)
    local title = ""
    if item.checked then
      title = template("{TITLE} ({PTT})", { TITLE = tostring(item.title), PTT = to_psv(pttKey) })
    else
      title = item.title
    end

    return {
      title = title,
      fn = function() obj.setState(item.state) end,
      checked = item.checked,
    }
  end)

  return menutable
end

local eventKeysMatchModifiers = function(modifiers)
  local modifiersMatch = true

  for _, key in ipairs(obj.modifierKeys) do
    if modifiers[key] ~= true then modifiersMatch = false end
  end

  return modifiersMatch
end

local eventTapWatcher = function(event)
  local modifiersMatch = eventKeysMatchModifiers(event:getFlags())

  if modifiersMatch then
    obj.pushed = true
  else
    obj.pushed = false
  end

  showState()
  if obj.pushed then
    log.df(
      "Input device PTT: { muted: %s, volume: %s, state: %s, pushed: %s }",
      obj.mic:inputMuted(),
      obj.mic:inputVolume(),
      obj.state,
      obj.pushed
    )
  end
end

obj.setState = function(s)
  obj.state = s
  log.df("Setting PTT state to %s", s)

  -- local muted = obj.state == "push-to-talk"
  -- hs.audiodevice.defaultInputDevice():setInputMuted(muted)

  if obj.menubar ~= nil then
    obj.menubar:setMenu(buildMenu())
    obj.menubar:setTitle(obj.icons[obj.state])

    showState()
  end
end

obj.toggleStates = function()
  local current_state = obj.state
  local toggle_to = hs.fnutils.find(obj.states(), function(item)
    if not item.checked then return item end
  end) or obj.state

  obj.setState(toggle_to.state)

  log.df("Toggling PTT state to %s", toggle_to.state, current_state)
  return toggle_to.state
end

function obj:init()
  obj:stop()

  obj.modifierKeys = pttKey
  obj.eventTapWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, eventTapWatcher)
  obj.eventTapWatcher:start()

  if obj.menubar == nil then obj.menubar = hs.menubar.new() end

  obj.setState(obj.state)

  hs.hotkey.bind(pttKey, "p", function()
    local toggled_to_state = obj.toggleStates()
    alert.show({ text = "Toggling to mode: " .. toggled_to_state })
  end)

  return self
end

function obj:start() return self end

function obj:stop()
  if obj.eventTapWatcher then obj.eventTapWatcher:stop() end
  -- if obj.menubar then obj.menubar:delete() end
  return self
end

return obj
