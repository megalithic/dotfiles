-- Derived from the PushToTalk Spoon and then heavily modified for my use cases

local log = hs.logger.new('bindings.ptt', 'debug')

local module = {}

module.defaultState = 'push-to-talk'

module.state = module.defaultState
module.defaultInputVolume = 50
module.pushed = false

local function showState()
  local device = hs.audiodevice.defaultInputDevice()
  local iconPath = hs.configdir .. "/assets/"
  local speakIcon = hs.image.imageFromPath(iconPath .. "microphone.pdf"):setSize({ w = 16, h = 16 })
  local mutedIcon = hs.image.imageFromPath(iconPath .. "microphone-slash.pdf"):setSize({ w = 16, h = 16 })

  -- starting point:
  local muted = false
  local inputVolume = module.defaultInputVolume

  if module.state == 'push-to-talk' then
    if module.pushed then
      module.menubar:setIcon(speakIcon)

      muted = false
      inputVolume = module.defaultInputVolume
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

      muted = false
      inputVolume = module.defaultInputVolume
    end
  end

  device:setMuted(muted)
  device:setInputVolume(inputVolume)
  hs.applescript('set volume input volume ' ..inputVolume)
end

function module.setState(s)
  module.state = s

  showState()
end

module.menutable = {
  { title = "Push-to-talk (fn)", fn = function() module.setState('push-to-talk') end },
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

  if module.pushed then
    log.df('Input device: { muted: %s, volume: %s, state: %s, pushed: %s }', device:inputMuted(), device:inputVolume(), module.state, module.pushed)
  end
end

function module:init()
end

function module:start()
  module:stop()
  module.modifierKeys = config.ptt or {'fn'}
  module.eventTapWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, eventTapWatcher)
  module.eventTapWatcher:start()

  module.menubar = hs.menubar.new()
  module.menubar:setMenu(module.menutable)
  module.setState(module.state)
end

function module:stop()
  if module.eventTapWatcher then module.eventTapWatcher:stop() end
  if module.menubar then module.menubar:delete() end
end

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
