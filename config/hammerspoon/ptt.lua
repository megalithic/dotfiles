local M = {}
M.__index = M

M.name = "ptt"
M.defaultState = "push-to-talk"
M.push_mappings = {}
M.toggle_mappings = {}
M.state = M.defaultState
M.states = { "push-to-talk", "push-to-mute" }
M.pushed = false
M.inputVolume = 75
--- PushToTalk.app_switcher
--- Variable
--- Takes mapping from application name to mic state.
--- For example this `{ ['zoom.us'] = 'push-to-talk' }` will switch mic to `push-to-talk` state when Zoom app starts.
M.app_switcher = {}

local function showState()
  local device = hs.audiodevice.defaultInputDevice()
  local muted = false

  if M.state == "unmute" then
    M.menubar:setIcon(hs.image.imageFromPath("assets/speak.pdf"))
  elseif M.state == "mute" then
    M.menubar:setIcon(hs.image.imageFromPath("assets/muted.pdf"))
    muted = true
  elseif M.state == "push-to-talk" then
    if M.pushed then
      M.menubar:setIcon(hs.image.imageFromPath("assets/record.pdf"), false)
      M.menubar:setTitle(hs.styledtext.new("", {
        color = { hex = "#c43e1f" },
        font = { name = "Symbols Nerd Font Mono", size = 15 },
      }))
    else
      M.menubar:setIcon(hs.image.imageFromPath("assets/unrecord.pdf"))
      M.menubar:setTitle(hs.styledtext.new(" ", {
        color = { hex = "#aaaaaa" },
        font = { name = "Symbols Nerd Font Mono", size = 14 },
      }))
      muted = true
    end
  elseif M.state == "push-to-mute" then
    if M.pushed then
      M.menubar:setIcon(hs.image.imageFromPath("assets/unrecord.pdf"))

      M.menubar:setTitle(hs.styledtext.new("", {
        color = { hex = "#aaaaaa" },
        font = { name = "Symbols Nerd Font Mono", size = 15 },
      }))
      muted = true
    else
      M.menubar:setIcon(hs.image.imageFromPath("assets/record.pdf"), false)

      M.menubar:setTitle(hs.styledtext.new("", {
        color = { hex = "#c43e1f" },
        font = { name = "Symbols Nerd Font Mono", size = 15 },
      }))
    end
  end

  M.toggleInputState(device, muted)
end

function M.toggleInputState(device, state)
  device:setInputMuted(state)
  device:setInputVolume(M.inputVolume)
end

function M.setState(s)
  M.state = s
  showState()
end

M.menutable = {
  {
    title = "push-to-talk (fn)",
    fn = function() M.setState("push-to-talk") end,
  },
  {
    title = "push-to-mute (fn)",
    fn = function() M.setState("push-to-mute") end,
  },
  {
    title = "unmuted",
    fn = function() M.setState("unmute") end,
  },
  {
    title = "muted",
    fn = function() M.setState("mute") end,
  },
}

local function appWatcher(appName, eventType, appObject)
  local new_app_state = M.app_switcher[appName]
  if new_app_state then
    if eventType == hs.application.watcher.launching then
      M.setState(new_app_state)
    elseif eventType == hs.application.watcher.terminated then
      M.setState(M.defaultState)
    end
  end
end

local function eventTapWatcher(evt)
  local push_mods, _push_key = table.unpack(M.push_mappings)
  local modifiersMatch = function(modifiers)
    local match = true

    for _, key in ipairs(push_mods) do
      if modifiers[key] ~= true then match = false end
    end

    return match
  end

  M.pushed = modifiersMatch(evt:getFlags())

  -- if modifiersMatch(evt:getFlags()) then
  --   M.pushed = true
  -- else
  --   M.pushed = false
  -- end

  showState()
end

--- PushToTalk:init()
--- Method
--- Initial setup. It's empty currently
function M:init(mappings)
  if mappings and type(mappings) == "table" and U.tlen(mappings) > 0 then
    M.push_mappings = mappings["push"]
    M.toggle_mappings = mappings["toggle"]

    U.log.i("started")
  else
    U.log.e("no mappings to capture")
  end

  return self
end

--- PushToTalk:init()
--- Method
--- Starts menu and key watcher
function M:start()
  local push_mods, push_key = table.unpack(M.push_mappings)
  local toggle_mods, toggle_key = table.unpack(M.toggle_mappings)

  self:stop()
  M.appWatcher = hs.application.watcher.new(appWatcher)
  M.appWatcher:start()

  if push_key == nil then
    M.eventTapWatcher = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, eventTapWatcher)
    M.eventTapWatcher:start()
  else
    M.pushHotkey = hs.hotkey.bind(push_mods, push_key, function() showState() end)
  end

  self.toggleHotkey = hs.hotkey.bind(toggle_mods, toggle_key, function() self:toggleStates() end)

  M.menubar = hs.menubar.new()
  M.menubar:setMenu(M.menutable)
  M.setState(M.state)

  return self
end

--- PushToTalk:stop()
--- Method
--- Stops PushToTalk
function M:stop()
  if M.appWatcher then M.appWatcher:stop() end
  if M.eventTapWatcher then M.eventTapWatcher:stop() end
  if M.menubar then M.menubar:delete() end
  if M.pushHotkey then M.pushHotkey:delete() end
  if M.toggleHotkey then M.toggleHotkey:delete() end

  return self
end

--- PushToTalk:toggleStates()
--- Method
--- Cycle states in order
---
--- Parameters:
---  * states - A array of states to toggle. For example: `{'push-to-talk', 'push-to-mute'}`
function M:toggleStates(states)
  states = states or M.states
  local updatedState = states[1]
  for i, v in pairs(states) do
    if v == M.state then updatedState = states[(i % #states) + 1] end
  end
  M.setState(updatedState)

  hs.alert.closeAll()
  hs.alert.show("toggled to -> " .. updatedState)
end

return M
