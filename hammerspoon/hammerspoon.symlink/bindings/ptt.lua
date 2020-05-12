-- Derived from the PushToTalk Spoon and then heavily modified for my use cases

local log = hs.logger.new('bindings.ptt', 'warning')

local module = {}
module.__index = module

-- Metadata
module.defaultState = 'push-to-talk'

module.state = module.defaultState
module.defaultInputVolume = 50
module.pushed = false

local function showState()
  local device = hs.audiodevice.defaultInputDevice()
  local iconPath = hs.configdir .. "/assets/"
  local speakIcon = hs.image.imageFromPath(iconPath .. "microphone.pdf"):setSize({ w = 16, h = 16 })
  local mutedIcon = hs.image.imageFromPath(iconPath .. "microphone-slash.pdf"):setSize({ w = 16, h = 16 })
  local muted = false
  local inputVolume = 50

  device:setInputVolume(inputVolume)
  hs.applescript('set volume input volume ' .. inputVolume)

  if module.state == 'unmute' then
    module.menubar:setIcon(iconPath .."record.pdf")
  elseif module.state == 'mute' then
    module.menubar:setIcon(iconPath .."unrecord.pdf")
    muted = true
    inputVolume = 0
  elseif module.state == 'push-to-talk' then
    if module.pushed then
      module.menubar:setIcon(speakIcon)
    else
      module.menubar:setIcon(mutedIcon)
      muted = true
      inputVolume = 0
    end
  elseif module.state == 'push-to-mute' then
    if module.pushed then
      module.menubar:setIcon(mutedIcon)
      muted = true
      inputVolume = 0
    else
      module.menubar:setIcon(speakIcon)
    end
  end

  device:setMuted(muted)
  device:setInputVolume(inputVolume)
  hs.applescript('set volume input volume ' ..inputVolume)

  -- log.df('Device settings: %s', hs.inspect(dumpCurrentInputAudioDevice()))
end

function module.setState(s)
  module.state = s

  showState()
end

module.menutable = {
  { title = "UnMuted", fn = function() module.setState('unmute') end },
  { title = "Muted", fn = function() module.setState('mute') end },
  { title = "Push-to-talk (fn)", fn = function() module.setState('push-to-talk') end, checked = true },
  { title = "Push-to-mute (fn)", fn = function() module.setState('push-to-mute') end },
}

local function eventKeysMatchModifiers(modifiers)
  local modifiersMatch = true

  for index, key in ipairs(module.modifierKeys) do
    if modifiers[key] ~= true then
      modifiersMatch = false
    end
  end

  return modifiersMatch
end

local function eventTapWatcher(event)
  device = hs.audiodevice.defaultInputDevice()
  modifiersMatch = eventKeysMatchModifiers(event:getFlags())

  if modifiersMatch then
    module.pushed = true
  else
    module.pushed = false
  end

  showState()
end

--- PushToTalk:init()
--- Method
--- Initial setup. It's empty currently
function module:init()
end

--- PushToTalk:start()
--- Method
--- Starts menu and key watcher
function module:start()
  module:stop()
  module.modifierKeys = config.ptt or {'fn'}
  module.eventTapWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, eventTapWatcher)
  module.eventTapWatcher:start()

  module.menubar = hs.menubar.new()
  module.menubar:setMenu(module.menutable)
  module.setState(module.state)
end

--- PushToTalk:stop()
--- Method
--- Stops PushToTalk
function module:stop()
  if module.eventTapWatcher then module.eventTapWatcher:stop() end
  if module.menubar then module.menubar:delete() end
end

--- PushToTalk:toggleStates()
--- Method
--- Cycle states in order
---
--- Parameters:
---  * states - A array of states to toggle. For example: `{'push-to-talk', 'push-to-mute'}`
function module:toggleStates(states)
  new_state = states[1]
  for i, v in pairs(states) do
    if v == module.state then
      new_state = states[(i % #states) + 1]
    end
  end
  module.setState(new_state)
end

return module
