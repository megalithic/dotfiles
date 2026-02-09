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
    U.log.e("ptd: Failed to load WhisperDictation spoon")
    return nil
  end
end


-- Model preflight check
-- Downloads the model if not present (first run ~3GB download)
local function preflightModelCheck(callback)
  local model = whisper.model or "large-v3"
  local whisperCmd = whisper.transcriptionMethods.whisperkitcli.config.cmd
  
  if not hs.fs.attributes(whisperCmd) then
    U.log.e("ptd: whisperkit-cli not found at " .. whisperCmd)
    if callback then callback(false) end
    return
  end
  
  -- Check if model is cached by doing a quick test transcribe
  -- WhisperKit caches models in ~/Library/Caches/huggingface/
  local cacheDir = os.getenv("HOME") .. "/Library/Caches/huggingface/hub"
  
  -- Quick check - if huggingface cache exists and has content, likely good
  local cacheExists = hs.fs.attributes(cacheDir)
  if cacheExists then
    U.log.i("ptd: model cache directory exists, assuming model ready")
    if callback then callback(true) end
    return
  end
  
  -- Need to download - create silent audio and trigger download
  U.log.i("ptd: model not cached, triggering download...")
  
  -- Create a short silent WAV file for test
  local testAudio = "/tmp/whisper-preflight-test.wav"
  local soxCmd = whisper.recordCmd or "sox"
  
  -- Generate 0.5s of silence
  local silenceTask = hs.task.new(soxCmd, function(exitCode, _, _)
    if exitCode ~= 0 then
      U.log.e("ptd: failed to create test audio")
      if callback then callback(false) end
      return
    end
    
    -- Now run whisperkit-cli which will download the model
    U.log.i("ptd: running whisperkit-cli to trigger model download...")
    local args = {
      "transcribe",
      "--model=" .. model,
      "--audio-path=" .. testAudio,
      "--language=en",
    }
    
    local downloadTask = hs.task.new(whisperCmd, function(dlExitCode, stdOut, stdErr)
      -- Clean up test file
      os.remove(testAudio)
      
      if dlExitCode ~= 0 then
        U.log.e("ptd: model download/test failed: " .. (stdErr or "unknown error"))
        if callback then callback(false) end
        return
      end
      
      U.log.i("ptd: model ready!")
      if callback then callback(true) end
    end, function(task, stdOut, stdErr)
      -- Streaming callback - log progress
      if stdOut and stdOut ~= "" then
        U.log.i("ptd: " .. stdOut)
      end
      if stdErr and stdErr ~= "" then
        U.log.i("ptd: " .. stdErr)
      end
      return true
    end, args)
    
    if downloadTask then
      downloadTask:start()
    else
      U.log.e("ptd: failed to create download task")
      if callback then callback(false) end
    end
  end, {"-n", "-r", "16000", "-c", "1", testAudio, "trim", "0", "0.5"})
  
  if silenceTask then
    silenceTask:start()
  else
    U.log.e("ptd: failed to create silence generation task")
    if callback then callback(false) end
  end
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
      U.log.i("ptd: mic unmuted for recording")
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
        U.log.i("ptd: mic unmuted for always-on recording")
      end
    else
      -- Restore mic when stopping
      if M.previousMicMuted ~= nil then
        local device = hs.audiodevice.defaultInputDevice()
        if device then
          device:setInputMuted(M.previousMicMuted)
          U.log.i("ptd: mic restored")
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
        U.log.i("ptd: mic restored to " .. (M.previousMicMuted and "muted" or "unmuted"))
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
    U.log.e("ptd: Cannot initialize without WhisperDictation spoon")
    return self
  end
  
  -- Configure the spoon
  whisper.transcriptionMethod = "whisperkitcli"
  whisper.model = config.model or "large-v3"
  whisper.languages = config.languages or { "en" }
  
  -- Configure paths
  -- Sox: try nix paths first, then homebrew
  local soxPaths = {
    "/etc/profiles/per-user/" .. os.getenv("USER") .. "/bin/sox",
    "/run/current-system/sw/bin/sox",
    os.getenv("HOME") .. "/.nix-profile/bin/sox",
    "/opt/homebrew/bin/sox",
    "/usr/local/bin/sox",
  }
  for _, path in ipairs(soxPaths) do
    if hs.fs.attributes(path) then
      whisper.recordCmd = path
      U.log.i("ptd: using sox at " .. path)
      break
    end
  end
  if not whisper.recordCmd or whisper.recordCmd == "" then
    U.log.e("ptd: sox not found")
  end
  
  -- WhisperKit CLI (homebrew)
  whisper.transcriptionMethods.whisperkitcli.config.cmd = "/opt/homebrew/bin/whisperkit-cli"
  U.log.i("ptd: initialized with whisperkit-cli")
  
  return self
end

--- Start the dictation module (binds hotkeys)
function M:start()
  if not whisper then
    U.log.e("ptd: Cannot start - spoon not loaded")
    return self
  end
  
  -- Start the spoon (validates paths, sets up menubar)
  whisper:start()
  
  -- Preflight: check/download model
  preflightModelCheck(function(success)
    if success then
      U.log.i("ptd: model preflight passed")
    else
      U.log.w("ptd: model preflight failed, transcription may not work")
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
  
  U.log.i("ptd: started, bound cmd+opt+space")
  
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
  
  U.log.i("ptd: stopped")
  
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
