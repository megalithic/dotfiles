--- Micchecka - Unified Voice Control Module
--- Keybindings: cmd+opt (PTT), cmd+opt+shift (PTD), +p to toggle modes

local M = {}
M.__index = M
M.name = "micchecka"

local S = nil
local whisper = nil
local notchHUD = nil
local levelMonitor = nil
local currentLevel = 0
local recordingWaveInfo = nil

local HUDState = {
  HIDDEN = "hidden",
  PTT_ACTIVE = "ptt_active",
  RECORDING = "recording",
  PROCESSING = "processing",
  COMPLETE = "complete",
}

local currentHUDState = HUDState.HIDDEN
local completeTimer = nil

local function svgToImage(svg)
  return hs.image.imageFromURL("data:image/svg+xml," .. hs.http.encodeForQuery(svg))
end
local SVG = {
  muted = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <path fill="{{COLOR}}" d="M8 1a2 2 0 0 0-2 2v4a2 2 0 1 0 4 0V3a2 2 0 0 0-2-2z"/>
    <path fill="{{COLOR}}" d="M4.5 7a.5.5 0 0 0-1 0 4.5 4.5 0 0 0 4 4.473V13H6a.5.5 0 0 0 0 1h4a.5.5 0 0 0 0-1H8.5v-1.527A4.5 4.5 0 0 0 12.5 7a.5.5 0 0 0-1 0 3.5 3.5 0 1 1-7 0z"/>
    <line x1="2" y1="14" x2="14" y2="2" stroke="{{COLOR}}" stroke-width="1.5" stroke-linecap="round"/>
  </svg>]],
  speak = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <path fill="{{COLOR}}" d="M8 1a2 2 0 0 0-2 2v4a2 2 0 1 0 4 0V3a2 2 0 0 0-2-2z"/>
    <path fill="{{COLOR}}" d="M4.5 7a.5.5 0 0 0-1 0 4.5 4.5 0 0 0 4 4.473V13H6a.5.5 0 0 0 0 1h4a.5.5 0 0 0 0-1H8.5v-1.527A4.5 4.5 0 0 0 12.5 7a.5.5 0 0 0-1 0 3.5 3.5 0 1 1-7 0z"/>
  </svg>]],
  record = [[<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
    <circle cx="8" cy="8" r="6" fill="{{COLOR}}"/>
  </svg>]],
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

local notch = nil
local elements = nil
local animator = nil

local function loadHUDModules()
  if not notch then
    notch = require("lib.hud.notch")
    elements = require("lib.hud.elements")
    animator = require("lib.hud.animator")
  end
end

local levelCanvas = nil
local levelMode = nil

local function loadLevelMonitor()
  if not levelMonitor then
    levelMonitor = require("lib.audio.levels")
  end
end

local function preloadLevelMonitor()
  loadLevelMonitor()
  levelMonitor.preload()
end

---@param canvas hs.canvas
---@param opts? {mode: "ptt"|"recording"}
local function startLevelMonitoring(canvas, opts)
  loadLevelMonitor()
  loadHUDModules()
  opts = opts or {}
  levelCanvas = canvas
  levelMode = opts.mode or "ptt"
  
  levelMonitor.start(function(level)
    currentLevel = level
    if not levelCanvas then return end
    if recordingWaveInfo then
      animator.setWaveformLevel(levelCanvas, recordingWaveInfo, level)
    end
    if levelCanvas["indicator"] and levelMode == "ptt" then
      animator.setCircleLevel(levelCanvas, {
        elementId = "indicator",
        baseRadius = 6,
        maxGrowth = 26,
        curve = 0.4,
      }, level)
    end
  end)
end

local function stopLevelMonitoring()
  if levelMonitor then
    levelMonitor.stop()
  end
  levelCanvas = nil
  levelMode = nil
  currentLevel = 0
  recordingWaveInfo = nil
end

local function shutdownLevelMonitor()
  stopLevelMonitoring()
  if levelMonitor then
    levelMonitor.shutdown()
  end
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

local function isMicActive()
  if S.pttMode == "push-to-talk" then
    return S.isUnmuted
  elseif S.pttMode == "push-to-mute" then
    return not S.isUnmuted
  end
  return false
end

local function renderRecordingHUD(hud)
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "indicator",
      x = cx,
      y = cy,
      radius = 24,
      color = { red = 1, green = 0.58, blue = 0, alpha = 1 },
    })
    recordingWaveInfo = elements.waveformBars(canvas, {
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
  startLevelMonitoring(canvas, { mode = "recording" })
  
  hud:show()
end

local sfsymbol = nil
local processingImages = nil

local PROCESSING_SYMBOLS = { "rays", "slowmo", "timelapse" }
local PROCESSING_COLOR = "FF9500"

local function loadProcessingImages()
  if processingImages then return processingImages end
  if not sfsymbol then sfsymbol = require("lib.hud.sfsymbol") end
  
  processingImages = {}
  for _, name in ipairs(PROCESSING_SYMBOLS) do
    processingImages[name] = sfsymbol.image(name, { color = PROCESSING_COLOR, size = 32 })
  end
  return processingImages
end

local function renderProcessingHUD(hud)
  local images = loadProcessingImages()
  local currentIndex = 1
  
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "bg",
      x = cx,
      y = cy,
      radius = 24,
      color = { red = 0.1, green = 0.1, blue = 0.12, alpha = 1 },
    })
    
    local img = images[PROCESSING_SYMBOLS[1]]
    if img then
      local sz = img:size()
      canvas:insertElement({
        id = "symbol",
        type = "image",
        image = img,
        frame = { x = cx - sz.w / 2, y = cy - sz.h / 2, w = sz.w, h = sz.h },
        imageAlignment = "center",
        imageScaling = "none",
      })
    end
  end)
  
  local canvas = hud:getCanvas()
  
  hud:addTimer("symbolMorph", hs.timer.doEvery(0.4, function()
    if not canvas then return end
    
    local newIndex
    repeat
      newIndex = math.random(1, #PROCESSING_SYMBOLS)
    until newIndex ~= currentIndex or #PROCESSING_SYMBOLS == 1
    currentIndex = newIndex
    
    local img = images[PROCESSING_SYMBOLS[currentIndex]]
    if img and canvas["symbol"] then
      canvas["symbol"].image = img
    end
  end))
  
  hud:show()
end

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

local function renderPTTActiveHUD(hud)
  hud:setContent(function(canvas, cx, cy)
    elements.circle(canvas, {
      id = "indicator",
      x = cx,
      y = cy,
      radius = 6,
      color = { red = 1, green = 0.23, blue = 0.19, alpha = 1 },
    })
  end)
  
  local canvas = hud:getCanvas()
  recordingWaveInfo = nil
  startLevelMonitoring(canvas, { mode = "ptt" })
  
  hud:show()
end

local function cancelCompleteTimer()
  if completeTimer then
    completeTimer:stop()
    completeTimer = nil
  end
end

local function setHUDState(newState)
  if currentHUDState == newState then return end
  
  local oldState = currentHUDState
  currentHUDState = newState
  
  if oldState == HUDState.COMPLETE then
    cancelCompleteTimer()
  end
  if oldState == HUDState.PTT_ACTIVE then
    stopLevelMonitoring()
  end
  if oldState == HUDState.RECORDING then
    stopLevelMonitoring()
  end
  
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
      completeTimer = hs.timer.doAfter(1.5, function()
        completeTimer = nil
        if not S then
          setHUDState(HUDState.HIDDEN)
          return
        end
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

local function computeHUDState()
  if S.isRecording then return HUDState.RECORDING end
  if S.isProcessing then return HUDState.PROCESSING end
  if currentHUDState == HUDState.COMPLETE then return HUDState.COMPLETE end
  if isMicActive() then
    return HUDState.PTT_ACTIVE
  end
  
  return HUDState.HIDDEN
end

local function updateHUD()
  setHUDState(computeHUDState())
end

local function showComplete()
  setHUDState(HUDState.COMPLETE)
end

local function icon(template, color)
  local svg = template:gsub("{{COLOR}}", color)
  return svgToImage(svg)
end

local function updateMenubar()
  if not S or not S.menubar then return end

  local isMicUnmuted = false
  if S.pttMode == "push-to-talk" then
    isMicUnmuted = S.isUnmuted
  elseif S.pttMode == "push-to-mute" then
    isMicUnmuted = not S.isUnmuted
  end

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

local function setMicMuted(muted)
  local device = hs.audiodevice.defaultInputDevice()
  if device then
    device:setInputMuted(muted)
    for _, hook in ipairs(S.hooks.onMuteChange) do
      pcall(hook, muted)
    end
  end
end

local function applyPTTState()
  local shouldMute = true

  if S.pttMode == "push-to-talk" then
    shouldMute = not S.isUnmuted and not S.isRecording
  elseif S.pttMode == "push-to-mute" then
    shouldMute = S.isUnmuted
  elseif S.pttMode == "disabled" then
    return
  end

  setMicMuted(shouldMute)
  updateMenubar()
end

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

  S.isUnmuted = false
  applyPTTState()
  updateHUD()
end

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
  setMicMuted(false)
  whisper:beginTranscribe()
end

local function stopRecording()
  if not whisper or not S.isRecording then return end
  whisper:endTranscribe()
end

local function onPTDKeyDown()
  if S.ptdMode == "push-to-dictate" then
    startRecording()
  elseif S.ptdMode == "always-on" then
    if S.isRecording then
      stopRecording()
    else
      startRecording()
    end
  end
end

local function onPTDKeyUp()
  if S.ptdMode == "push-to-dictate" and S.isRecording then stopRecording() end
end

local function togglePTDMode()
  if S.ptdMode == "push-to-dictate" then
    S.ptdMode = "always-on"
  else
    S.ptdMode = "push-to-dictate"
    if S.isRecording then stopRecording() end
  end
end

---@param callback fun(muted: boolean)
function M.onMuteChange(callback) table.insert(S.hooks.onMuteChange, callback) end

---@param callback fun()
function M.onRecordStart(callback) table.insert(S.hooks.onRecordStart, callback) end

---@param callback fun()
function M.onRecordEnd(callback) table.insert(S.hooks.onRecordEnd, callback) end

---@param callback fun(success: boolean, text: string?)
function M.onTranscribe(callback) table.insert(S.hooks.onTranscribe, callback) end

---@param mode "push-to-talk"|"push-to-mute"|"disabled"
function M.setPTTMode(mode)
  S.pttMode = mode
  applyPTTState()
end

function M.getPTTMode() return S.pttMode end

---@param mode "push-to-dictate"|"always-on"|"disabled"
function M.setPTDMode(mode) S.ptdMode = mode end

function M.getPTDMode() return S.ptdMode end

function M.isRecording() return S.isRecording end

function M.isProcessing() return S.isProcessing end

function M.setMuted(muted)
  setMicMuted(muted)
  updateMenubar()
end

---@param config? {model?: string, languages?: string[]}
function M:init(config)
  config = config or {}
  S = _G.S.micchecka
  whisper = loadWhisperSpoon()
  if whisper then
    whisper.transcriptionMethod = "whisperkitcli"
    whisper.model = config.model or "large-v3"
    whisper.languages = config.languages or { "en" }
    whisper.showMenubar = false
    whisper.showRecordingIndicator = false

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
      S.isUnmuted = false
      setMicMuted(true)
      updateMenubar()
      if success then
        showComplete()
      else
        updateHUD()
      end
      for _, hook in ipairs(S.hooks.onTranscribe) do
        pcall(hook, success, text)
      end
    end

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

function M:start()
  _G.S.resetMicchecka()
  S = _G.S.micchecka
  S.menubar = hs.menubar.new()
  S.menubar:setMenu({
    { title = "Push-to-talk", fn = function() M.setPTTMode("push-to-talk") end },
    { title = "Push-to-mute", fn = function() M.setPTTMode("push-to-mute") end },
    { title = "-" },
    { title = "Push-to-dictate", fn = function() M.setPTDMode("push-to-dictate") end },
    { title = "Always-on dictation", fn = function() M.setPTDMode("always-on") end },
  })

  S.hotkeys.modifierTap = hs.eventtap.new({ hs.eventtap.event.types.flagsChanged }, function(evt)
    local flags = evt:getFlags()
    local cmdOpt = flags.cmd and flags.alt and not flags.shift and not flags.ctrl
    local cmdOptShift = flags.cmd and flags.alt and flags.shift and not flags.ctrl

    if cmdOptShift and not S.isRecording then
      onPTDKeyDown()
    elseif not cmdOptShift and S.isRecording and S.ptdMode == "push-to-dictate" then
      onPTDKeyUp()
    end

    if cmdOpt and not S.isUnmuted and not S.isRecording then
      onPTTKeyDown()
    elseif not cmdOpt and not cmdOptShift and S.isUnmuted then
      onPTTKeyUp()
    end

    return false
  end)
  S.hotkeys.modifierTap:start()

  S.hotkeys.pttToggle = hs.hotkey.bind({ "cmd", "alt" }, "p", togglePTTMode)
  S.hotkeys.ptdToggle = hs.hotkey.bind({ "cmd", "alt", "shift" }, "p", togglePTDMode)

  if whisper then
    whisper:start()
    
    -- Check model status at startup and log
    local method = whisper.transcriptionMethods.whisperkitcli
    if method and method.checkModelStatus then
      local ready, status = method:checkModelStatus()
      if ready then
        U.log.i("✅ Whisper model ready")
      else
        if status == "not_downloaded" then
          U.log.w("📥 Whisper model not downloaded - first use will download ~3GB")
        elseif status == "downloading" then
          U.log.w("📥 Whisper model download in progress...")
        elseif status == "incomplete" then
          U.log.w("📥 Whisper model incomplete - will resume download")
        else
          U.log.w("📥 Whisper model status: " .. tostring(status))
        end
      end
    end
  end
  preloadLevelMonitor()
  applyPTTState()
  updateHUD()

  -- Register for screen changes to reposition notch
  local screenWatcher = require("watchers.screen")
  screenWatcher.onChange("micchecka", function()
    if notchHUD and notchHUD.reposition then
      -- Skip reposition if HUD is actively showing (avoid interrupting PTT/recording)
      if currentHUDState ~= HUDState.HIDDEN then
        U.log.d("notchHUD: skipping reposition during active state:", currentHUDState)
        return
      end
      local ok, err = pcall(function() notchHUD:reposition() end)
      if not ok then
        U.log.w("notchHUD reposition failed:", tostring(err or "unknown error"))
      end
    end
  end)

  U.log.i("started")
  return self
end

function M:stop()
  _G.S.resetMicchecka()

  if whisper then whisper:stop() end
  
  -- Unregister screen change callback
  local ok, screenWatcher = pcall(require, "watchers.screen")
  if ok then
    screenWatcher.removeCallback("micchecka")
  end
  
  shutdownLevelMonitor()
  cancelCompleteTimer()
  currentHUDState = HUDState.HIDDEN
  destroyHUD()

  U.log.i("stopped")
  return self
end

return M
