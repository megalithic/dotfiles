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

-- Notch HUD integration
local notchHUD = nil

-- Local state (transient, reset on reload)
-- (previousMicMuted removed - mic state now restored via applyPTTState)

-- Audio level monitoring
local levelMonitor = nil  -- Lazy loaded
local currentLevel = 0    -- Current audio level 0.0-1.0
local recordingWaveInfo = nil  -- Waveform info for level-driven updates

--------------------------------------------------------------------------------
-- HUD State Machine
--------------------------------------------------------------------------------
-- States: hidden, ptt_active, recording, processing, complete
-- 
-- Transitions:
--   hidden → ptt_active    : mic becomes active
--   hidden → recording     : PTD starts
--   ptt_active → hidden    : mic becomes inactive  
--   ptt_active → recording : PTD starts
--   recording → processing : recording ends, transcription starts
--   processing → complete  : transcription succeeds
--   processing → hidden    : transcription fails (or ptt_active if mic hot)
--   complete → hidden      : after 1.5s delay (or ptt_active if mic hot)
--
-- Priority for derived state: recording > processing > complete > ptt_active > hidden

local HUDState = {
  HIDDEN = "hidden",
  PTT_ACTIVE = "ptt_active",
  RECORDING = "recording",
  PROCESSING = "processing",
  COMPLETE = "complete",
}

local currentHUDState = HUDState.HIDDEN
local completeTimer = nil  -- Timer for auto-hiding after complete

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

--------------------------------------------------------------------------------
-- Notch HUD Visual States
--------------------------------------------------------------------------------

local notch = nil     -- Lazy loaded
local elements = nil  -- Lazy loaded
local animator = nil  -- Lazy loaded

local function loadHUDModules()
  if not notch then
    notch = require("lib.hud.notch")
    elements = require("lib.hud.elements")
    animator = require("lib.hud.animator")
  end
end

local function loadLevelMonitor()
  if not levelMonitor then
    levelMonitor = require("lib.audio.levels")
  end
end

--- Start monitoring audio levels and updating the HUD
---@param canvas hs.canvas Canvas to update
local function startLevelMonitoring(canvas)
  loadLevelMonitor()
  loadHUDModules()
  
  levelMonitor.start(function(level)
    currentLevel = level
    -- Update waveform bars based on actual level
    if recordingWaveInfo and canvas then
      animator.setWaveformLevel(canvas, recordingWaveInfo, level)
    end
    -- Optionally update circle size based on level too
    if canvas and canvas["indicator"] then
      animator.setCircleLevel(canvas, {
        elementId = "indicator",
        baseRadius = 24,
        maxGrowth = 6,
      }, level)
    end
  end)
end

--- Stop level monitoring
local function stopLevelMonitoring()
  if levelMonitor then
    levelMonitor.stop()
  end
  currentLevel = 0
  recordingWaveInfo = nil
end

-- Pulse animation state
local pulseTimer = nil
local pulsePhase = 0

--- Stop pulse animation
local function stopPulseAnimation()
  if pulseTimer then
    pulseTimer:stop()
    pulseTimer = nil
  end
  pulsePhase = 0
end

--- Start breathing/pulsing animation for PTT indicator
---@param canvas hs.canvas Canvas to update
local function startPulseAnimation(canvas)
  stopPulseAnimation()  -- Clean up any existing animation
  loadHUDModules()
  
  pulsePhase = 0
  pulseTimer = hs.timer.doEvery(0.05, function()
    pulsePhase = pulsePhase + 0.15
    -- Breathing pattern: smooth sine wave
    local level = (math.sin(pulsePhase) + 1) / 2  -- 0.0 to 1.0
    -- Add some subtle variation for liveliness
    level = level * 0.6 + 0.4  -- Range: 0.4 to 1.0
    
    if canvas and canvas["indicator"] then
      animator.setCircleLevel(canvas, {
        elementId = "indicator",
        baseRadius = 16,
        maxGrowth = 8,
      }, level)
    end
  end)
end

local function ensureHUD()
  loadHUDModules()
  if not notchHUD then
    notchHUD = notch.new()
  end
  return notchHUD
end

local function destroyHUD()
  if notchHUD then
    notchHUD:destroy()
    notchHUD = nil
  end
end

--- Is the mic currently active (unmuted)?
--- In push-to-talk: active when key held
--- In push-to-mute: active when key NOT held
--- In disabled: never active (no HUD feedback)
local function isMicActive()
  if S.pttMode == "push-to-talk" then
    return S.isUnmuted
  elseif S.pttMode == "push-to-mute" then
    return not S.isUnmuted
  else
    return false  -- disabled mode
  end
end

--- Render HUD for recording state: red pulsing circle with animated waveform
--- Note: Uses simulated animation during recording because WhisperDictation owns the mic
local function renderRecordingHUD(hud)
  local waveInfo
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "indicator",
      x = cx,
      y = cy,
      radius = 24,
      color = { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
    })
    waveInfo = elements.waveformBars(canvas, {
      x = cx,
      y = cy,
      barCount = 5,
      barWidth = 3,
      maxHeight = 16,
      spacing = 2,
      color = { white = 1, alpha = 1 },
    })
  end)
  
  local canvas = hud:getCanvas()
  
  -- Use simulated animation during recording (WhisperDictation owns the mic)
  hud:addTimer("pulse", animator.pulse(canvas, {
    elementId = "indicator",
    baseRadius = 24,
    pulseAmount = 4,
  }))
  hud:addTimer("waveform", animator.waveform(canvas, waveInfo))
  
  hud:show()
end

--- Render HUD for processing state: dark circle with orange waveform
local function renderProcessingHUD(hud)
  local waveInfo
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "indicator",
      x = cx,
      y = cy,
      radius = 24,
      color = { red = 0.1, green = 0.1, blue = 0.12, alpha = 1 },
    })
    waveInfo = elements.waveformBars(canvas, {
      x = cx,
      y = cy,
      barCount = 5,
      barWidth = 3,
      maxHeight = 16,
      spacing = 2,
      color = { red = 1, green = 0.58, blue = 0, alpha = 1 },
    })
  end)
  
  local canvas = hud:getCanvas()
  hud:addTimer("waveform", animator.waveform(canvas, {
    barCount = waveInfo.barCount,
    maxHeight = waveInfo.maxHeight,
    baseY = waveInfo.baseY,
    barWidth = waveInfo.barWidth,
    idPrefix = waveInfo.idPrefix,
    interval = 0.08,
  }))
  hud:show()
end

--- Render HUD for complete state: green checkmark
local function renderCompleteHUD(hud)
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "bg",
      x = cx,
      y = cy,
      radius = 24,
      color = { red = 0.2, green = 0.78, blue = 0.35, alpha = 1 },
    })
    elements.sfSymbol(canvas, {
      x = cx,
      y = cy,
      size = 28,
      symbol = "checkmark",
      color = "FFFFFF",
    })
  end)
  hud:show({ animate = false })
end

--- Render HUD for PTT active state: pulsing indicator
--- Shows a breathing/pulsing circle to indicate mic is open
--- Note: We don't use actual audio levels here because capturing audio
--- via sox/AVFoundation conflicts with mic muting operations
local function renderPTTActiveHUD(hud)
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "indicator",
      x = cx,
      y = cy,
      radius = 16,
      color = { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
    })
  end)
  
  local canvas = hud:getCanvas()
  recordingWaveInfo = nil  -- No waveform bars in PTT mode
  
  -- Start breathing/pulsing animation instead of real audio levels
  -- This avoids conflicts with mic state changes
  startPulseAnimation(canvas)
  
  hud:show()
end

--- Cancel the complete timer if running
local function cancelCompleteTimer()
  if completeTimer then
    completeTimer:stop()
    completeTimer = nil
  end
end

--- Transition to a new HUD state
local function setHUDState(newState)
  if currentHUDState == newState then return end
  
  local oldState = currentHUDState
  currentHUDState = newState
  
  -- Cleanup when leaving states
  if oldState == HUDState.COMPLETE then
    cancelCompleteTimer()
  end
  if oldState == HUDState.PTT_ACTIVE then
    stopPulseAnimation()
  end
  -- Note: RECORDING state cleanup is handled by notch.lua (stops timers on hide)
  
  -- Render new state
  if newState == HUDState.HIDDEN then
    if notchHUD then notchHUD:hide() end
  else
    local hud = ensureHUD()
    if newState == HUDState.RECORDING then
      renderRecordingHUD(hud)
    elseif newState == HUDState.PROCESSING then
      renderProcessingHUD(hud)
    elseif newState == HUDState.COMPLETE then
      renderCompleteHUD(hud)
      -- Start timer to auto-transition out of complete
      completeTimer = hs.timer.doAfter(1.5, function()
        completeTimer = nil
        -- Guard against module being stopped during timer
        if not S then
          setHUDState(HUDState.HIDDEN)
          return
        end
        -- Transition to appropriate state after complete
        if S.isRecording then
          setHUDState(HUDState.RECORDING)
        elseif S.isProcessing then
          setHUDState(HUDState.PROCESSING)
        elseif isMicActive() then
          setHUDState(HUDState.PTT_ACTIVE)
        else
          setHUDState(HUDState.HIDDEN)
        end
      end)
    elseif newState == HUDState.PTT_ACTIVE then
      renderPTTActiveHUD(hud)
    end
  end
end

--- Compute desired HUD state from current conditions
local function computeHUDState()
  -- Recording and processing always take priority (active operations)
  if S.isRecording then
    return HUDState.RECORDING
  end
  
  if S.isProcessing then
    return HUDState.PROCESSING
  end
  
  -- Complete state is sticky until timer expires
  -- (but recording/processing can interrupt it - handled above)
  if currentHUDState == HUDState.COMPLETE then
    return HUDState.COMPLETE
  end
  
  -- PTT/PTM mic state
  if isMicActive() then
    return HUDState.PTT_ACTIVE
  end
  
  return HUDState.HIDDEN
end

--- Update HUD based on current state
local function updateHUD()
  setHUDState(computeHUDState())
end

--- Enter complete state (called on successful transcription)
local function showComplete()
  setHUDState(HUDState.COMPLETE)
end

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

--------------------------------------------------------------------------------
-- PTT Event Handlers
--------------------------------------------------------------------------------

local function onPTTKeyDown()
  S.isUnmuted = true
  applyPTTState()
  updateHUD()
end

local function onPTTKeyUp()
  S.isUnmuted = false
  applyPTTState()
  updateHUD()
end

local function togglePTTMode()
  if S.pttMode == "push-to-talk" then
    S.pttMode = "push-to-mute"
  else
    S.pttMode = "push-to-talk"
  end

  -- Reset key state on mode toggle
  -- The modifier keys are still held (to press +p), but their "meaning" changes
  -- In PTT: held = unmuting. In PTM: held = muting.
  -- We reset to false so the next key release doesn't cause unexpected state
  S.isUnmuted = false

  applyPTTState()
  updateHUD()
  
  -- In push-to-mute: mic active (unmuted) when key NOT held → HUD shows
  -- In push-to-talk: mic inactive (muted) when key NOT held → HUD hides
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

  -- Unmute for recording (will be restored via applyPTTState after transcription)
  setMicMuted(false)

  -- Spoon callbacks handle state updates
  whisper:beginTranscribe()
end

local function stopRecording()
  if not whisper or not S.isRecording then return end

  -- Spoon callbacks handle state updates
  -- Mic state will be restored via applyPTTState in onTranscribeEnd
  whisper:endTranscribe()
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
      updateHUD()
      for _, hook in ipairs(S.hooks.onRecordStart) do
        pcall(hook)
      end
    end

    whisper.onRecordingEnd = function()
      S.isRecording = false
      updateMenubar()
      -- HUD will transition to processing (onTranscribeStart) or back to PTT state
      updateHUD()
      for _, hook in ipairs(S.hooks.onRecordEnd) do
        pcall(hook)
      end
    end

    whisper.onTranscribeStart = function()
      S.isProcessing = true
      updateMenubar()
      updateHUD()
    end

    whisper.onTranscribeEnd = function(success, text)
      S.isProcessing = false
      applyPTTState()  -- Restore mic to correct state based on mode/key
      if success then
        showComplete()  -- Show checkmark, then auto-transition after delay
      else
        updateHUD()  -- Back to appropriate state
      end
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
  updateHUD()

  U.log.i("started")
  return self
end

--- Stop the module
function M:stop()
  _G.S.resetMicchecka()

  if whisper then whisper:stop() end
  
  -- Clean up HUD state
  stopLevelMonitoring()
  stopPulseAnimation()
  cancelCompleteTimer()
  currentHUDState = HUDState.HIDDEN
  destroyHUD()

  U.log.i("stopped")
  return self
end

return M
