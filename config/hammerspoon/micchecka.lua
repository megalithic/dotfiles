--- Micchecka - Unified Voice Control Module
--- Combines push-to-talk (PTT) and push-to-dictate (PTD) with unified menubar
---
--- Keybindings:
---   cmd+opt (hold)           → PTT: Unmute while held
---   cmd+opt+shift (hold)     → PTD: Record while held, transcribe on release
---   cmd+opt+p                → Toggle PTT mode (push-to-talk ↔ push-to-mute)
---   cmd+opt+shift+p          → Toggle PTD mode (push-to-dictate ↔ always-on)
---
--- State Priority (for menubar icon):
---   1. Processing (transcribing) → waveform
---   2. Recording (PTD active)    → red circle
---   3. PTT Unmuted (key held)    → red speak icon
---   4. Muted/Idle                → grey slashed mic

local M = {}
M.__index = M
M.name = "micchecka"

-- State stored in S.micchecka (survives reloads)
local S = nil -- Will be set to _G.S.micchecka in init

-- WhisperDictation spoon reference
local whisper = nil

-- Local state (transient, reset on reload)
local previousMicMuted = nil -- Store mic state to restore after PTD

--------------------------------------------------------------------------------
-- Icon/Menubar Management
--------------------------------------------------------------------------------

--- Convert an SVG string to an hs.image via data URL
--- @param svg string SVG markup string
--- @return hs.image|nil Image or nil on failure
local function svgToImage(svg) return hs.image.imageFromURL("data:image/svg+xml," .. hs.http.encodeForQuery(svg)) end

-- SVG icon templates (16x16, color placeholder: {{COLOR}})
local SVG = {
  -- Microphone with slash (muted)
  muted = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <path fill="{{COLOR}}" d="M8 1a2 2 0 0 0-2 2v4a2 2 0 1 0 4 0V3a2 2 0 0 0-2-2z"/>
    <path fill="{{COLOR}}" d="M4.5 7a.5.5 0 0 0-1 0 4.5 4.5 0 0 0 4 4.473V13H6a.5.5 0 0 0 0 1h4a.5.5 0 0 0 0-1H8.5v-1.527A4.5 4.5 0 0 0 12.5 7a.5.5 0 0 0-1 0 3.5 3.5 0 1 1-7 0z"/>
    <line x1="2" y1="14" x2="14" y2="2" stroke="{{COLOR}}" stroke-width="1.5" stroke-linecap="round"/>
  </svg>]],

  -- Microphone (unmuted/speaking)
  speak = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <path fill="{{COLOR}}" d="M8 1a2 2 0 0 0-2 2v4a2 2 0 1 0 4 0V3a2 2 0 0 0-2-2z"/>
    <path fill="{{COLOR}}" d="M4.5 7a.5.5 0 0 0-1 0 4.5 4.5 0 0 0 4 4.473V13H6a.5.5 0 0 0 0 1h4a.5.5 0 0 0 0-1H8.5v-1.527A4.5 4.5 0 0 0 12.5 7a.5.5 0 0 0-1 0 3.5 3.5 0 1 1-7 0z"/>
  </svg>]],

  -- Solid circle (recording)
  record = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <circle cx="8" cy="8" r="6" fill="{{COLOR}}"/>
  </svg>]],

  -- Waveform (processing/transcribing)
  waveform = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <g fill="none" stroke="{{COLOR}}" stroke-width="1.5" stroke-linecap="round">
      <line x1="2" y1="6" x2="2" y2="10"/>
      <line x1="5" y1="4" x2="5" y2="12"/>
      <line x1="8" y1="2" x2="8" y2="14"/>
      <line x1="11" y1="4" x2="11" y2="12"/>
      <line x1="14" y1="6" x2="14" y2="10"/>
    </g>
  </svg>]],
}

local COLORS = {
  red = "#c43e1f",
  orange = "#f5a623",
  white = "#ffffff",
}

--- Generate an icon image from SVG template with color
--- @param template string SVG template with {{COLOR}} placeholder
--- @param color string Hex color string
--- @return hs.image|nil
local function icon(template, color)
  local svg = template:gsub("{{COLOR}}", color)
  return svgToImage(svg)
end

local function updateMenubar()
  if not S or not S.menubar then return end

  -- Determine if mic is effectively unmuted based on mode and key state
  local isMicUnmuted = false
  if S.pttMode == "push-to-talk" then
    isMicUnmuted = S.isUnmuted  -- unmuted only when key held
  elseif S.pttMode == "push-to-mute" then
    isMicUnmuted = not S.isUnmuted  -- unmuted unless key held
  end

  -- Priority: Processing > Recording > Unmuted > Muted
  if S.isProcessing then
    S.menubar:setIcon(icon(SVG.waveform, COLORS.orange), false)
    S.menubar:setTitle("")
  elseif S.isRecording then
    S.menubar:setIcon(icon(SVG.record, COLORS.red), false)
    S.menubar:setTitle("")
  elseif isMicUnmuted then
    S.menubar:setIcon(icon(SVG.speak, COLORS.red), false)
    S.menubar:setTitle("")
  else
    S.menubar:setIcon(icon(SVG.muted, COLORS.white), false)
    S.menubar:setTitle("")
  end
end

--------------------------------------------------------------------------------
-- Mic Control
--------------------------------------------------------------------------------

local function setMicMuted(muted)
  local device = hs.audiodevice.defaultInputDevice()
  if device then
    device:setInputMuted(muted)
    -- Fire hooks
    for _, hook in ipairs(S.hooks.onMuteChange) do
      pcall(hook, muted)
    end
  end
end

local function getMicMuted()
  local device = hs.audiodevice.defaultInputDevice()
  return device and device:inputMuted()
end

--------------------------------------------------------------------------------
-- PTT (Push-to-Talk) Logic
--------------------------------------------------------------------------------

local function applyPTTState()
  local shouldMute = true

  if S.pttMode == "push-to-talk" then
    -- Muted unless key held OR recording
    shouldMute = not S.isUnmuted and not S.isRecording
  elseif S.pttMode == "push-to-mute" then
    -- Unmuted unless key held
    shouldMute = S.isUnmuted
  elseif S.pttMode == "disabled" then
    -- No PTT control
    return
  end

  setMicMuted(shouldMute)
  updateMenubar()
end

local function onPTTKeyDown()
  S.isUnmuted = true
  applyPTTState()
end

local function onPTTKeyUp()
  S.isUnmuted = false
  applyPTTState()
end

local function togglePTTMode()
  if S.pttMode == "push-to-talk" then
    S.pttMode = "push-to-mute"
  else
    S.pttMode = "push-to-talk"
  end

  hs.alert.closeAll()
  hs.alert.show("PTT: " .. S.pttMode)
  applyPTTState()
end

--------------------------------------------------------------------------------
-- PTD (Push-to-Dictate) Logic
--------------------------------------------------------------------------------

local function loadWhisperSpoon()
  local ok, spoon = pcall(function() return hs.loadSpoon("WhisperDictation") end)
  if ok and spoon then
    return spoon
  else
    U.log.e("Failed to load WhisperDictation spoon")
    return nil
  end
end

local function startRecording()
  if not whisper then return end

  -- Store current mic state and unmute for recording
  previousMicMuted = getMicMuted()
  setMicMuted(false)

  -- Spoon callbacks handle state updates
  whisper:beginTranscribe()
end

local function stopRecording()
  if not whisper or not S.isRecording then return end

  -- Spoon callbacks handle state updates
  whisper:endTranscribe()

  -- Restore previous mic state after transcription completes
  if previousMicMuted ~= nil then
    hs.timer.doAfter(0.1, function()
      if not S.isRecording then
        setMicMuted(previousMicMuted)
        previousMicMuted = nil
      end
    end)
  end
end

local function onPTDKeyDown()
  if S.ptdMode == "push-to-dictate" then
    startRecording()
  elseif S.ptdMode == "always-on" then
    -- Toggle recording
    if S.isRecording then
      stopRecording()
    else
      startRecording()
    end
  end
end

local function onPTDKeyUp()
  if S.ptdMode == "push-to-dictate" and S.isRecording then stopRecording() end
  -- In always-on mode, releasing key does nothing
end

local function togglePTDMode()
  if S.ptdMode == "push-to-dictate" then
    S.ptdMode = "always-on"
  else
    S.ptdMode = "push-to-dictate"
    -- If switching from always-on while recording, stop
    if S.isRecording then stopRecording() end
  end

  hs.alert.closeAll()
  hs.alert.show("PTD: " .. S.ptdMode)
end

--------------------------------------------------------------------------------
-- Hook Registration
--------------------------------------------------------------------------------

--- Register a hook for mute state changes
--- @param callback function Called with (muted: boolean)
function M.onMuteChange(callback) table.insert(S.hooks.onMuteChange, callback) end

--- Register a hook for recording start
--- @param callback function Called when recording starts
function M.onRecordStart(callback) table.insert(S.hooks.onRecordStart, callback) end

--- Register a hook for recording end
--- @param callback function Called when recording ends
function M.onRecordEnd(callback) table.insert(S.hooks.onRecordEnd, callback) end

--- Register a hook for transcription completion
--- @param callback function Called with (success: boolean, text: string|nil)
function M.onTranscribe(callback) table.insert(S.hooks.onTranscribe, callback) end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Set PTT mode
--- @param mode "push-to-talk"|"push-to-mute"|"disabled"
function M.setPTTMode(mode)
  S.pttMode = mode
  applyPTTState()
end

--- Get current PTT mode
function M.getPTTMode() return S.pttMode end

--- Set PTD mode
--- @param mode "push-to-dictate"|"always-on"|"disabled"
function M.setPTDMode(mode) S.ptdMode = mode end

--- Get current PTD mode
function M.getPTDMode() return S.ptdMode end

--- Check if currently recording
function M.isRecording() return S.isRecording end

--- Check if currently processing (transcribing)
function M.isProcessing() return S.isProcessing end

--- Force mute state (for context switching)
function M.setMuted(muted)
  setMicMuted(muted)
  updateMenubar()
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

--- Initialize the module
--- @param config table Optional config { model = "large-v3", languages = {"en"} }
function M:init(config)
  config = config or {}

  -- Get state reference
  S = _G.S.micchecka

  -- Load WhisperDictation spoon
  whisper = loadWhisperSpoon()
  if whisper then
    whisper.transcriptionMethod = "whisperkitcli"
    whisper.model = config.model or "large-v3"
    whisper.languages = config.languages or { "en" }
    whisper.showMenubar = false -- We manage our own menubar
    whisper.showRecordingIndicator = false -- We handle visual feedback

    -- State change callbacks
    whisper.onRecordingStart = function()
      S.isRecording = true
      updateMenubar()
      for _, hook in ipairs(S.hooks.onRecordStart) do
        pcall(hook)
      end
    end

    whisper.onRecordingEnd = function()
      S.isRecording = false
      updateMenubar()
      for _, hook in ipairs(S.hooks.onRecordEnd) do
        pcall(hook)
      end
    end

    whisper.onTranscribeStart = function()
      S.isProcessing = true
      updateMenubar()
    end

    whisper.onTranscribeEnd = function(success, text)
      S.isProcessing = false
      updateMenubar()
      for _, hook in ipairs(S.hooks.onTranscribe) do
        pcall(hook, success, text)
      end
    end

    -- Resolve paths
    local function resolveCmd(name)
      local h = io.popen("PATH='" .. (PATH or os.getenv("PATH")) .. "' which " .. name .. " 2>/dev/null")
      if not h then return nil end
      local result = h:read("*l")
      h:close()
      if result and #result > 0 then
        U.log.i("using " .. name .. " at " .. result)
        return result
      end
      return nil
    end

    whisper.recordCmd = resolveCmd("sox") or whisper.recordCmd
    whisper.transcriptionMethods.whisperkitcli.config.cmd = resolveCmd("whisperkit-cli")
      or whisper.transcriptionMethods.whisperkitcli.config.cmd
  end

  U.log.i("initialized")
  return self
end

--- Start the module (create menubar, bind hotkeys)
function M:start()
  -- Reset transient state
  _G.S.resetMicchecka()
  S = _G.S.micchecka

  -- Create menubar
  S.menubar = hs.menubar.new()
  S.menubar:setMenu({
    { title = "Push-to-talk", fn = function() M.setPTTMode("push-to-talk") end },
    { title = "Push-to-mute", fn = function() M.setPTTMode("push-to-mute") end },
    { title = "-" },
    { title = "Push-to-dictate", fn = function() M.setPTDMode("push-to-dictate") end },
    { title = "Always-on dictation", fn = function() M.setPTDMode("always-on") end },
  })

  -- Combined eventtap for PTT (cmd+opt) and PTD (cmd+opt+shift) modifier-only hotkeys
  S.hotkeys.modifierTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(evt)
    local flags = evt:getFlags()
    local cmdOpt = flags.cmd and flags.alt and not flags.shift and not flags.ctrl
    local cmdOptShift = flags.cmd and flags.alt and flags.shift and not flags.ctrl

    -- PTD: cmd+opt+shift (takes priority over PTT)
    if cmdOptShift and not S.isRecording then
      onPTDKeyDown()
    elseif not cmdOptShift and S.isRecording and S.ptdMode == "push-to-dictate" then
      onPTDKeyUp()
    end

    -- PTT: cmd+opt (only when not recording)
    if cmdOpt and not S.isUnmuted and not S.isRecording then
      onPTTKeyDown()
    elseif not cmdOpt and not cmdOptShift and S.isUnmuted then
      onPTTKeyUp()
    end

    return false -- Don't consume the event
  end)
  S.hotkeys.modifierTap:start()

  -- PTT toggle: cmd+opt+p
  S.hotkeys.pttToggle = hs.hotkey.bind({ "cmd", "alt" }, "p", togglePTTMode)

  -- PTD toggle: cmd+opt+shift+p
  S.hotkeys.ptdToggle = hs.hotkey.bind({ "cmd", "alt", "shift" }, "p", togglePTDMode)

  -- Start WhisperDictation spoon (but don't bind its hotkeys)
  if whisper then whisper:start() end

  -- Apply initial state
  applyPTTState()

  U.log.i("started")
  return self
end

--- Stop the module
function M:stop()
  _G.S.resetMicchecka()

  if whisper then whisper:stop() end

  U.log.i("stopped")
  return self
end

return M
