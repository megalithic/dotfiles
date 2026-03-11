--- Whisper Dictation Module
--- Integrates WhisperDictation spoon with push-to-talk style keybindings
---
--- Keybindings:
---   cmd+opt+space (hold)     → Push-to-talk dictation (release to transcribe)
---   cmd+opt+space+p          → Toggle always-on dictation mode
---
--- Works alongside ptt.lua (mic mute) without conflicts

local M = {}
M.__index = M

M.name = "ptd"
M.modes = { "push-to-dictate", "always-on" }
M.mode = "push-to-dictate"
M.recording = false
M.pListener = nil  -- eventtap for 'p' key during recording
M.previousMicMuted = nil  -- Store mic state to restore after recording
-- Load the WhisperDictation spoon
local whisper = nil

local function loadSpoon()
  local ok, spoon = pcall(function()
    return hs.loadSpoon("WhisperDictation")
  end)
  if ok and spoon then
    return spoon
  else
    U.log.e("Failed to load WhisperDictation spoon")
    return nil
  end
end


-- Model preflight check
-- Checks if model is downloaded, warns user if not (first run ~3GB download)
local function preflightModelCheck(callback)
  local model = whisper.model or "large-v3"
  local whisperCmd = whisper.transcriptionMethods.whisperkitcli.config.cmd
  
  if not hs.fs.attributes(whisperCmd) then
    U.log.e("whisperkit-cli not found at " .. whisperCmd)
    if callback then callback(false) end
    return
  end
  
  -- Check WhisperKit model cache location
  -- WhisperKit downloads to ~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/
  local modelCacheBase = os.getenv("HOME") .. "/Documents/huggingface/models/argmaxinc/whisperkit-coreml"
  local modelDir = modelCacheBase .. "/openai_whisper-" .. model
  
  -- Check if model directory exists with required components
  local modelAttrs = hs.fs.attributes(modelDir)
  if not modelAttrs then
    U.log.w("📥 Whisper model '" .. model .. "' not downloaded yet")
    U.log.w("📥 First transcription will download ~3GB - this may take several minutes")
    hs.alert.show("📥 Whisper model not cached\nFirst use will download ~3GB", 5)
    if callback then callback(false) end
    return
  end
  
  -- Check for required model components
  local components = {"AudioEncoder.mlmodelc", "TextDecoder.mlmodelc", "MelSpectrogram.mlmodelc"}
  local missing = {}
  for _, comp in ipairs(components) do
    if not hs.fs.attributes(modelDir .. "/" .. comp) then
      table.insert(missing, comp)
    end
  end
  
  if #missing > 0 then
    U.log.w("📥 Model incomplete, missing: " .. table.concat(missing, ", "))
    U.log.w("📥 Will resume download on first transcription")
    if callback then callback(false) end
    return
  end
  
  -- Check for active downloads (.incomplete files)
  local downloadCacheDir = modelCacheBase .. "/.cache/huggingface/download"
  if hs.fs.attributes(downloadCacheDir) then
    local iter, dirObj = hs.fs.dir(downloadCacheDir)
    if iter then
      for filename in iter, dirObj do
        if filename:match("%.incomplete$") then
          U.log.w("📥 Model download in progress...")
          if callback then callback(false) end
          return
        end
      end
    end
  end
  
  U.log.i("✅ Model '" .. model .. "' ready")
  if callback then callback(true) end
end
local function showMode()
  hs.alert.closeAll()
  if M.mode == "push-to-dictate" then
    hs.alert.show("🎤 Push-to-dictate mode")
  else
    hs.alert.show("🎙️ Always-on dictation mode")
  end
end

local function toggleMode()
  if M.mode == "push-to-dictate" then
    M.mode = "always-on"
  else
    M.mode = "push-to-dictate"
    -- If switching back from always-on while recording, stop
    if M.recording and whisper then
      whisper:endTranscribe()
      M.recording = false
    end
  end
  showMode()
end

local function onSpacePressed()
  if not whisper then return end
  
  if M.mode == "push-to-dictate" then
    -- Start recording
    -- Force mic on for recording
    local device = hs.audiodevice.defaultInputDevice()
    if device then
      M.previousMicMuted = device:inputMuted()
      device:setInputMuted(false)
      U.log.i("mic unmuted for recording")
    end
    M.recording = true
    whisper:beginTranscribe()
    
    -- Listen for 'p' key to toggle mode instead
    M.pListener = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(evt)
      local keyCode = evt:getKeyCode()
      if keyCode == hs.keycodes.map["p"] then
        -- Cancel current recording and toggle mode
        if M.recording then
          whisper:endTranscribe()
          M.recording = false
        end
        toggleMode()
        return true  -- consume the event
      end
      return false
    end)
    M.pListener:start()
    
  else
    -- Always-on mode: toggle recording
    -- Force mic on when starting recording
    if not M.recording then
      local device = hs.audiodevice.defaultInputDevice()
      if device then
        M.previousMicMuted = device:inputMuted()
        device:setInputMuted(false)
        U.log.i("mic unmuted for always-on recording")
      end
    else
      -- Restore mic when stopping
      if M.previousMicMuted ~= nil then
        local device = hs.audiodevice.defaultInputDevice()
        if device then
          device:setInputMuted(M.previousMicMuted)
          U.log.i("mic restored")
        end
        M.previousMicMuted = nil
      end
    end
    whisper:toggleTranscribe()
    M.recording = not M.recording
    
    -- Still listen for 'p' to switch back to push-to-dictate
    if M.recording then
      M.pListener = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(evt)
        local keyCode = evt:getKeyCode()
        if keyCode == hs.keycodes.map["p"] then
          toggleMode()
          return true
        end
        return false
      end)
      M.pListener:start()
    end
  end
end

local function onSpaceReleased()
  -- Stop the 'p' listener
  if M.pListener then
    M.pListener:stop()
    M.pListener = nil
  end
  
  if not whisper then return end
  
  if M.mode == "push-to-dictate" and M.recording then
    -- End recording and transcribe
    whisper:endTranscribe()
    M.recording = false
    -- Restore previous mic state
    if M.previousMicMuted ~= nil then
      local device = hs.audiodevice.defaultInputDevice()
      if device then
        device:setInputMuted(M.previousMicMuted)
        U.log.i("mic restored to " .. (M.previousMicMuted and "muted" or "unmuted"))
      end
      M.previousMicMuted = nil
    end
  end
  -- In always-on mode, releasing space does nothing (toggle controls it)
end

--- Initialize the dictation module
--- @param config table Optional config { model = "large-v3", languages = {"en"} }
function M:init(config)
  config = config or {}
  
  whisper = loadSpoon()
  if not whisper then
    U.log.e("Cannot initialize without WhisperDictation spoon")
    return self
  end
  
  -- Configure the spoon
  whisper.transcriptionMethod = "whisperkitcli"
  whisper.model = config.model or "large-v3"
  whisper.languages = config.languages or { "en" }
  
  local function resolveCmd(name)
    local h = io.popen("PATH='" .. (PATH or os.getenv("PATH")) .. "' which " .. name .. " 2>/dev/null")
    if not h then return nil end
    local result = h:read("*l")
    h:close()
    if result and #result > 0 then
      U.log.i("using " .. name .. " at " .. result)
      return result
    end
    U.log.e("" .. name .. " not found in PATH")
    return nil
  end

  whisper.recordCmd = resolveCmd("sox") or whisper.recordCmd
  whisper.transcriptionMethods.whisperkitcli.config.cmd = resolveCmd("whisperkit-cli")
    or whisper.transcriptionMethods.whisperkitcli.config.cmd
  
  return self
end

--- Start the dictation module (binds hotkeys)
function M:start()
  if not whisper then
    U.log.e("Cannot start - spoon not loaded")
    return self
  end
  
  -- Start the spoon (validates paths, sets up menubar)
  whisper:start()
  
  -- Preflight: check/download model
  preflightModelCheck(function(success)
    if success then
      U.log.i("model preflight passed")
    else
      U.log.w("model preflight failed, transcription may not work")
    end
  end)  
  -- Bind cmd+opt+space with press/release handlers
  -- Note: Don't use whisper:bindHotKeys() - we handle it ourselves
  M.hotkey = hs.hotkey.bind(
    { "cmd", "alt" },
    "space",
    onSpacePressed,   -- pressedfn
    onSpaceReleased   -- releasedfn
  )
  
  U.log.i("started, bound cmd+opt+space")
  
  return self
end

--- Stop the dictation module
function M:stop()
  if M.hotkey then
    M.hotkey:delete()
    M.hotkey = nil
  end
  
  if M.pListener then
    M.pListener:stop()
    M.pListener = nil
  end
  
  if whisper then
    whisper:stop()
  end
  
  U.log.i("stopped")
  
  return self
end

--- Get current mode
function M:getMode()
  return M.mode
end

--- Check if currently recording
function M:isRecording()
  return M.recording
end

return M
