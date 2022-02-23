-- Derived from the PushToTalk Spoon and then heavily modified for my use cases

local log = hs.logger.new("[bindings.ptt]", "debug")

local M = {}

local template = require("ext.template")
local alert = require("ext.alert")

M.defaultState = "push-to-talk"
M.mic = hs.audiodevice.defaultInputDevice()

M.state = M.defaultState
M.defaultInputVolume = 50
M.pushed = false

local iconPath = hs.configdir .. "/assets/"
local speakIcon = hs.image.imageFromPath(iconPath .. "microphone.pdf"):setSize({ w = 16, h = 16 })
local mutedIcon = hs.image.imageFromPath(iconPath .. "microphone-slash.pdf"):setSize({ w = 16, h = 16 })
M.icons = { ["push-to-mute"] = speakIcon, ["push-to-talk"] = mutedIcon }

M.states = function()
  log.df("current module.state from module.states(): %s", M.state)

  return {
    { title = "Push-to-talk", state = "push-to-talk", checked = (M.state == "push-to-talk") },
    { title = "Push-to-mute", state = "push-to-mute", checked = (M.state == "push-to-mute") },
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

local showState = function()
  if M.pushed then
    log.df("device to handle: %s", M.mic)
  end

  -- starting point:
  local muted = false

  if M.state == "push-to-talk" then
    if M.pushed then
      M.menubar:setIcon(speakIcon)
      muted = false
    else
      M.menubar:setIcon(mutedIcon)
      muted = true
    end
  elseif M.state == "push-to-mute" then
    if M.pushed then
      M.menubar:setIcon(mutedIcon)
      muted = true
    else
      M.menubar:setIcon(speakIcon)
      muted = false
    end
  end

  M.mic:setInputMuted(muted)
end

local buildMenu = function()
  local menutable = hs.fnutils.map(M.states(), function(item)
    local title = ""
    if item.checked then
      title = template("{TITLE} ({PTT})", { TITLE = tostring(item.title), PTT = to_psv(Config.ptt) })
    else
      title = item.title
    end

    return {
      title = title,
      fn = function()
        M.setState(item.state)
      end,
      checked = item.checked,
    }
  end)

  return menutable
end

local eventKeysMatchModifiers = function(modifiers)
  local modifiersMatch = true

  for _, key in ipairs(M.modifierKeys) do
    if modifiers[key] ~= true then
      modifiersMatch = false
    end
  end

  return modifiersMatch
end

local eventTapWatcher = function(event)
  local modifiersMatch = eventKeysMatchModifiers(event:getFlags())

  if modifiersMatch then
    M.pushed = true
  else
    M.pushed = false
  end

  showState()
  if M.pushed then
    log.df(
      "Input device PTT: { muted: %s, volume: %s, state: %s, pushed: %s }",
      M.mic:inputMuted(),
      M.mic:inputVolume(),
      M.state,
      M.pushed
    )
  end
end

M.setState = function(s)
  M.state = s
  log.df("Setting PTT state to %s", s)

  if M.menubar ~= nil then
    -- M.menubar:delete()
    -- M.menubar = hs.menubar.new()
    M.menubar:setMenu(buildMenu())
    M.menubar:setIcon(M.icons[M.state])

    showState()
  end
end

M.toggleStates = function()
  local current_state = M.state
  local toggle_to = hs.fnutils.find(M.states(), function(item)
    if not item.checked then
      return item
    end
  end)

  M.setState(toggle_to.state)

  log.df("Toggling PTT state to %s", toggle_to.state, current_state)
  return toggle_to.state
end

M.start = function()
  M.stop()

  M.modifierKeys = Config.ptt
  M.eventTapWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, eventTapWatcher)
  M.eventTapWatcher:start()

  if M.menubar == nil then
    M.menubar = hs.menubar.new()
  end

  M.setState(M.state)

  hs.hotkey.bind(Config.ptt, "p", function()
    local toggled_to_state = M.toggleStates()
    alert.show({ text = "Toggling to mode: " .. toggled_to_state })
  end)
end

M.stop = function()
  if M.eventTapWatcher then
    M.eventTapWatcher:stop()
  end
  if M.menubar then
    M.menubar:delete()
  end
end

return M
