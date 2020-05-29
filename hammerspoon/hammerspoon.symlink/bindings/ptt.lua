-- Derived from the PushToTalk Spoon and then heavily modified for my use cases

local log = hs.logger.new('[bindings.ptt]', 'debug')

local module = {}

local template = require('ext.template')

module.defaultState = 'push-to-talk'

module.state = module.defaultState
module.defaultInputVolume = 50
module.pushed = false

module.states = function ()
  log.df("current module.state from module.states(): %s", module.state)

  return {
    {title = 'Push-to-talk', state = 'push-to-talk', checked = (module.state == 'push-to-talk')},
    {title = 'Push-to-mute', state = 'push-to-mute', checked = (module.state == 'push-to-mute')},
  }
end

-- function to return table values to `+` separated string
local to_psv = function(tbl)
  local s = ""

  for _, p in ipairs(tbl) do
    s = s .. "+" .. p
  end

  return string.sub(s, 2)      -- remove first comma
end

local showState = function()
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

local buildMenu = function()
  local menutable = hs.fnutils.map(module.states(), function(item)
    local title = ""
    if item.checked then
      title = template("{TITLE} ({PTT})", {TITLE = tostring(item.title), PTT = to_psv(config.ptt)})
    else
      title = item.title
    end

    return { title = title, fn = function() setState(item.state) end, checked = item.checked }
  end)

  return menutable
end

local setState = function(s)
  module.state = s
  log.df('Setting PTT state to: %s', s)

  module.menubar:delete()
  module.menubar = hs.menubar.new()
  module.menubar:setMenu(buildMenu())
  showState()

  showState()
end

local eventKeysMatchModifiers = function(modifiers)
  local modifiersMatch = true

  for index, key in ipairs(module.modifierKeys) do
    if modifiers[key] ~= true then
      modifiersMatch = false
    end
  end

  return modifiersMatch
end

local eventTapWatcher = function(event)
  device = hs.audiodevice.defaultInputDevice()
  modifiersMatch = eventKeysMatchModifiers(event:getFlags())

  if modifiersMatch then
    module.pushed = true
  else
    module.pushed = false
  end

  showState()

  if module.pushed then
    log.df('Input device PTT: { muted: %s, volume: %s, state: %s, pushed: %s }', device:inputMuted(), device:inputVolume(), module.state, module.pushed)
  end
end

module.toggleStates = function()
  local current_state = module.state
  local toggle_to = hs.fnutils.find(module.states(), function(item)
    if not item.checked then
      return item
    end
  end)

  setState(toggle_to.state)

  log.df('Toggling PTT state to %s from %s', toggle_to.state, current_state)
  return toggle_to.state
end

module.start = function()
  module.stop()

  module.modifierKeys = config.ptt
  module.eventTapWatcher = hs.eventtap.new({hs.eventtap.event.types.flagsChanged}, eventTapWatcher)
  module.eventTapWatcher:start()

  module.menubar = hs.menubar.new()
  module.menubar:setMenu(buildMenu())
  setState(module.state)
end

module.stop = function()
  if module.eventTapWatcher then module.eventTapWatcher:stop() end
  if module.menubar then module.menubar:delete() end
end

return module
