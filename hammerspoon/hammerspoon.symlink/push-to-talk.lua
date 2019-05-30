local log = require('log')
local settings = {
  pushToTalk = true
}

local modifierKeys = {}
local inputVolumes = {}
local muted = false
local menubarIcon = nil
local icons = {
  microphone = nil,
  mutedMicrophone = nil
}
local preferredVolume = 100

local onInputDeviceChanged = function(uid, name, scope, element)
  if name ~= "vmvc" then
    return
  end

  if scope ~= "inpt" then
    return
  end

  local device = hs.audiodevice.findDeviceByUID(uid)
  local newVolume = device:inputVolume()

  if newVolume == 0 or newVolume == inputVolumes[uid] then
    return
  end

  inputVolumes[uid] = newVolume
  log.i("[push-to-talk] User changed unmuted volume for " .. uid .. ": " .. newVolume)
end

local updateInputVolumes = function()
  local activeUids = {}
  for _, device in ipairs(hs.audiodevice.allInputDevices()) do
    activeUids[device:uid()] = true
    if inputVolumes[device:uid()] == nil then
      local inputVolume = device:inputVolume()
      if inputVolume == 0 then
        inputVolume = preferredVolume
      end
      inputVolumes[device:uid()] = inputVolume
      log.i("[push-to-talk] Setting unmuted volume for " .. device:uid() .. ": " .. inputVolumes[device:uid()])
    end
    if not device:watcherIsRunning() then
      device:watcherCallback(onInputDeviceChanged)
      device:watcherStart()
    end
  end
  for uid, _ in pairs(inputVolumes) do
    if activeUids[uid] == nil then
      inputVolumes[uid] = nil
      log.i("[push-to-talk] Removed unmuted volume for no longer active device " .. uid)
    end
  end
end

local changeMicrophoneState = function(mute)
  if mute then
    log.i('[push-to-talk] Muting audio')
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
      device:setInputVolume(0)
      device:setInputMuted(true)
    end
    -- Hack to really mute the microphone
    hs.applescript('set volume input volume 0')
    menubarIcon:setIcon(icons.mutedMicrophone)
  else
    for _, device in ipairs(hs.audiodevice.allInputDevices()) do
      if inputVolumes[device:uid()] == nil then
        log.wf("[push-to-talk] Device with unknown inputVolume")
      else
        log.i('[push-to-talk] Unmuting audio: ' .. inputVolumes[device:uid()])
        device:setInputMuted(false)
        device:setInputVolume(inputVolumes[device:uid()])
      end
    end
    -- Hack to really unmute the microphone
    local defaultInputDevice = hs.audiodevice.defaultInputDevice()
    local defaultVolume = inputVolumes[defaultInputDevice:uid()]
    -- defaultVolume = preferredVolume
    -- FIXME: osascript call fails here (maybe when switching docking mode?)
    hs.applescript('set volume input volume ' .. defaultVolume)
    menubarIcon:setIcon(icons.microphone)
  end
end

local onSystemAudioDeviceChanged = function(name)
  log.i("[push-to-talk] System audio device change event occurred for", name)

  if name ~= "dev#" then
    return
  end

  updateInputVolumes()
  changeMicrophoneState(muted)
end

local installSystemAudioWatcher = function()
  hs.audiodevice.watcher.setCallback(onSystemAudioDeviceChanged)
  hs.audiodevice.watcher.start()
end

local keyPressed = false
local modifiersChangedTap = hs.eventtap.new(
  {hs.eventtap.event.types.flagsChanged},
  function(event)
    local modifiers = event:getFlags()
    local stateChanged = false

    local modifiersMatch = true
    for index, key in ipairs(modifierKeys) do
      if modifiers[key] ~= true then
        modifiersMatch = false
      end
    end

    if modifiersMatch then
      if keyPressed ~= true then
        stateChanged = true
      end
      keyPressed = true
    else
      if keyPressed ~= false then
        stateChanged = true
      end
      keyPressed = false
    end

    if stateChanged then
      if keyPressed then
        muted = not settings.pushToTalk
        changeMicrophoneState(muted)
      else
        muted = settings.pushToTalk
        changeMicrophoneState(muted)
      end
    end
  end
  )

local initMenubarIcon = function()
  menubarIcon = hs.menubar.new()
  menubarIcon:setIcon(icons.microphone)
  menubarIcon:setMenu(function()
    return {
      {title = "Push to talk", checked = settings.pushToTalk, fn = function()
          if settings.pushToTalk == false then
            muted = true
            changeMicrophoneState(true)
            settings.pushToTalk = true
          end
        end},
        {title = "Push to mute", checked = not settings.pushToTalk, fn = function()
            if settings.pushToTalk == true then
              muted = false
              changeMicrophoneState(false)
              settings.pushToTalk = false
            end
          end},
          {title = "-"},
          {title = "Hotkey: " .. table.concat(modifierKeys, " + ")}
        }
      end)
    end

    local loadIcons = function()
      local iconPath = hs.configdir .. "/assets"
      icons.microphone = hs.image.imageFromPath(iconPath .. "/microphone.pdf"):setSize({w = 16, h = 16})
      icons.mutedMicrophone = hs.image.imageFromPath(iconPath .."/microphone-slash.pdf"):setSize({w = 16, h = 16})
    end

    local loadSettings = function()
      local loadedSettings = hs.settings.get('pushToTalk.settings')
      if loadedSettings ~= nil then
        settings = loadedSettings
      end
    end

    local saveSettings = function()
      hs.settings.set('pushToTalk.settings', settings)
    end

    return {
      init = (function(modifiers)
        modifierKeys = modifiers or {"fn"}

        log.i("[push-to-talk] setting up audio watchers and menubar items with modifiers", hs.inspect(modifierKeys))

        loadSettings()
        loadIcons()

        initMenubarIcon()

        updateInputVolumes()
        installSystemAudioWatcher()
        changeMicrophoneState(settings.pushToTalk)

        modifiersChangedTap:start()

        local oldShutdownCallback = hs.shutdownCallback
        hs.shutdownCallback = function()
          if oldShutdownCallback ~= nil then
            oldShutdownCallback()
          end

          saveSettings()
          changeMicrophoneState(false)
        end
      end),
      teardown = (function(_)
        log.i("[push-to-talk] tearing down audio watchers")
        hs.audiodevice.watcher.stop()
      end),
      mute = (function() changeMicrophoneState(true) end),
      unmute = (function() changeMicrophoneState(false) end)
    }
