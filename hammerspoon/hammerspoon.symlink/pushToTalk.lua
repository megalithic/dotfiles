--
-- Simple Hammerspoon script to create Push-To-Talk functionality
-- Press and hold fn key to talk
--
local log = hs.logger.new('PushToTalk','debug')
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

function updateInputVolumes()
  local activeUids = {}
  for index, device in ipairs(hs.audiodevice.allInputDevices()) do
    activeUids[device:uid()] = true
    if inputVolumes[device:uid()] == nil then
      local inputVolume = device:inputVolume()
      if inputVolume == 0 then
        inputVolume = 75
      end
      inputVolumes[device:uid()] = inputVolume
      log.i("Setting unmuted volume for " .. device:uid() .. ": " .. inputVolumes[device:uid()])
    end
    if not device:watcherIsRunning() then
      device:watcherCallback(onInputDeviceChanged)
      device:watcherStart()
    end
  end
  for uid, volume in pairs(inputVolumes) do
    if activeUids[uid] == nil then
      inputVolumes[uid] = nil
      log.i("Removed unmuted volume for no longer active device " .. uid)
    end
  end
end

function onInputDeviceChanged(uid, name, scope, element)
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
  log.i("User changed unmuted volume for " .. uid .. ": " .. newVolume)
end

function onSystemAudioDeviceChanged(name)
  if name ~= "dev#" then
    return
  end

  updateInputVolumes()
  changeMicrophoneState(muted)
end

function installSystemAudioWatcher()
  hs.audiodevice.watcher.setCallback(onSystemAudioDeviceChanged)
  hs.audiodevice.watcher.start()
end

function changeMicrophoneState(mute)
  if mute then
    log.i('Muting audio')
    for index, device in ipairs(hs.audiodevice.allInputDevices()) do
      device:setInputVolume(0)
    end
    -- Hack to really mute the microphone
    hs.applescript('set volume input volume 0')
    menubarIcon:setIcon(icons.mutedMicrophone)
  else
    for index, device in ipairs(hs.audiodevice.allInputDevices()) do
      if inputVolumes[device:uid()] == nil then
        log.i("Device with unknown inputVolume")
      else
        log.i('Unmuting audio: ' .. inputVolumes[device:uid()])
        device:setInputVolume(inputVolumes[device:uid()])
      end
    end
    -- Hack to really unmute the microphone
    local defaultInputDevice = hs.audiodevice.defaultInputDevice()
    local defaultVolumne = inputVolumes[defaultInputDevice:uid()]
    hs.applescript('set volume input volume ' .. defaultVolumne)
    menubarIcon:setIcon(icons.microphone)
  end
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

function initMenubarIcon()
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
      -- {title = "Disable", checked = not settings.pushToTalk, fn = function()
      --   if settings.pushToTalk == true then
      --     muted = false
      --     changeMicrophoneState(false)
      --     settings.pushToTalk = false
      --   end
      -- end},
      {title = "-"},
      {title = "Hotkey: " .. table.concat(modifierKeys, " + ")}
    }
  end)
end

function loadIcons()
  local iconPath = hs.configdir .. "/assets"
  icons.microphone = hs.image.imageFromPath(iconPath .. "/microphone.pdf"):setSize({w = 16, h = 16})
  icons.mutedMicrophone = hs.image.imageFromPath(iconPath .."/microphone-slash.pdf"):setSize({w = 16, h = 16})
end

function loadSettings()
  local loadedSettings = hs.settings.get('pushToTalk.settings')
  if loadedSettings ~= nil then
    settings = loadedSettings
  end
end

function saveSettings()
  hs.settings.set('pushToTalk.settings', settings)
end

-- Public interface
local pushToTalk = {}
pushToTalk.init = function(modifiers)
  modifierKeys = modifiers or {"fn"}

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
end

return pushToTalk
