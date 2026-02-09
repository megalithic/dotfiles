--- === WhisperDictation ===
---
--- Toggle local Whisper-based dictation with menubar indicator.
--- Records from mic via `sox`, transcribes via multiple backends, copies text to clipboard.
---
--- Features:
--- • Dynamic filename with timestamp
--- • Elapsed time indicator in menubar during recording
--- • Multiple languages (--language option or server restart)
--- • Clipboard copy and character count summary
--- • Multiple transcription backends: whisperkit-cli, whisper-cli, whisper-server
---
--- Usage:
-- wd = hs.loadSpoon("hs_whisperDictation")
-- wd.languages = {"en", "ja", "es", "fr"}
-- wd:bindHotKeys({
--    toggle = {dmg_all_keys, "l"},
--    nextLang = {dmg_all_keys, ";"},
-- })
-- wd:start()
--
-- Requirements:
--      see readme.org

local obj = {}
obj.__index = obj

obj.name = "WhisperDictation"
obj.version = "1.0"
obj.author = "dmg"
obj.license = "MIT"

-- === Icons ===
obj.icons = {
  idle = "🎤",
  recording = "🎙️",
  clipboard = "📋",
  language = "🌐",
  stopped = "🛑",
  transcribing = "⏳",
  error = "❌",
  info = "ℹ️",
}

-- === Recording Indicator Style ===
obj.recordingIndicatorStyle = {
  fillColor = {red = 1, green = 0, blue = 0, alpha = 0.7},
  strokeColor = {red = 1, green = 0, blue = 0, alpha = 1},
  strokeWidth = 2,
}

-- === Config ===
obj.model = "large-v3"
obj.tempDir = "/tmp/whisper_dict"
obj.recordCmd = "/opt/homebrew/bin/sox"
obj.languages = {"en"}
obj.langIndex = 1
obj.showRecordingIndicator = true
obj.timeoutSeconds = 1800  -- Auto-stop recording after 1800 seconds (30 minutes). Set to nil to disable.
obj.retranscribeMethod = "whisperkitcli"  -- Backend used by transcribeLatestAgain()
obj.retranscribeCount = 10                -- Number of recent recordings to show in chooser
obj.defaultHotkeys = {
  toggle = {{"ctrl", "cmd"}, "d"},
  nextLang = {{"ctrl", "cmd"}, "l"},
}

-- === Server Configuration (for whisperserver method) ===
obj.serverConfig = {
  executable = "/path/to/whisper-server",
  modelPath = "/usr/local/whisper/ggml-model.bin",
  modelPathFallback = "/usr/local/whisper/ggml-large-v3-turbo.bin",
  host = "127.0.0.1",
  port = "8080",
  startupTimeout = 10,  -- seconds to wait for server to start
  curlCmd = "/usr/bin/curl",
}

-- === Transcription Methods ===
-- Method-agnostic transcription system. Users select which method to use.
-- Each method implements: validate(), transcribe(audioFile, lang, callback)
-- callback signature: callback(success, text_or_error)
obj.transcriptionMethods = {
  whisperkitcli = {
    name = "whisperkitcli",
    displayName = "WhisperKit CLI",
    config = {
      cmd = "/opt/homebrew/bin/whisperkit-cli",
      model = "large-v3",
    },
    validate = function(self)
      return hs.fs.attributes(self.config.cmd) ~= nil
    end,
    --- Transcribe audio file using WhisperKit CLI.
    -- @param audioFile (string): Path to the WAV file
    -- @param lang (string): Language code (e.g., "en", "ja")
    -- @param callback (function): Called with (success, text_or_error)
    transcribe = function(self, audioFile, lang, callback)
      local args = {
        "transcribe",
        "--model=" .. self.config.model,
        "--audio-path=" .. audioFile,
        "--language=" .. lang,
      }
      obj.logger:info("Running: " .. self.config.cmd .. " " .. table.concat(args, " "))
      local task = hs.task.new(self.config.cmd, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
          callback(false, stdErr or "whisperkit-cli failed")
          return
        end
        local text = stdOut or ""
        if text == "" then
          callback(false, "Empty transcript output")
          return
        end
        callback(true, text)
      end, args)
      if not task then
        callback(false, "Failed to create hs.task for WhisperKit CLI")
        return
      end
      local ok, err = pcall(function() task:start() end)
      if not ok then
        callback(false, "Failed to start WhisperKit CLI: " .. tostring(err))
      end
    end,
  },

  whispercli = {
    name = "whispercli",
    displayName = "Whisper CLI",
    config = {
      cmd = "/opt/homebrew/bin/whisper-cli",
      modelPath = "/usr/local/whisper/ggml-large-v3.bin",
    },
    validate = function(self)
      return hs.fs.attributes(self.config.cmd) ~= nil
    end,
    --- Transcribe audio file using Whisper CLI (whisper.cpp).
    -- @param audioFile (string): Path to the WAV file
    -- @param lang (string): Language code (e.g., "en", "ja")
    -- @param callback (function): Called with (success, text_or_error)
    transcribe = function(self, audioFile, lang, callback)
      local args = {
        "-np",
        "--model", self.config.modelPath,
        "--language", lang,
        "--output-txt",
        audioFile,
      }
      obj.logger:info("Running: " .. self.config.cmd .. " " .. table.concat(args, " "))
      local task = hs.task.new(self.config.cmd, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
          callback(false, stdErr or "whisper-cli failed")
          return
        end
        -- whisper-cli creates a .txt file with same name as audio (e.g., audio.wav.txt)
        local outputFile = audioFile .. ".txt"
        local f = io.open(outputFile, "r")
        if not f then
          callback(false, "Could not read transcript file: " .. outputFile)
          return
        end
        local text = f:read("*a")
        f:close()
        if not text or text == "" then
          callback(false, "Empty transcript file")
          return
        end
        callback(true, text)
      end, args)
      if not task then
        callback(false, "Failed to create hs.task for Whisper CLI")
        return
      end
      local ok, err = pcall(function() task:start() end)
      if not ok then
        callback(false, "Failed to start Whisper CLI: " .. tostring(err))
      end
    end,
  },

  whisperserver = {
    name = "whisperserver",
    displayName = "Whisper Server",
    config = {}, -- Uses obj.serverConfig
    validate = function(self)
      return hs.fs.attributes(obj.serverConfig.executable) ~= nil
    end,
    --- Transcribe audio file by sending to whisper server via HTTP POST.
    -- @param audioFile (string): Path to the WAV file
    -- @param lang (string): Language code (currently unused, server uses loaded model)
    -- @param callback (function): Called with (success, text_or_error)
    transcribe = function(self, audioFile, lang, callback)
      -- Check server status before transcribing
      if not obj:isServerRunning() then
        if obj.serverStarting then
          -- Server is starting, fail with message
          hs.alert.show("Server is starting, please try again when ready")
          callback(false, "Server is starting, please try again when ready")
          return
        else
          -- Server not running and not starting, start it and fail current request
          hs.alert.show("Server starting... please try again when ready")
          obj:startServer()  -- Start async, no callback needed
          callback(false, "Server starting... please try again when ready")
          return
        end
      end
      local serverUrl = string.format("http://%s:%s/inference",
        obj.serverConfig.host, obj.serverConfig.port)
      local args = {
        "-s", "-X", "POST", serverUrl,
        "-F", string.format("file=@%s", audioFile),
        "-F", "response_format=text",
      }
      obj.logger:info("Running: " .. obj.serverConfig.curlCmd .. " " .. table.concat(args, " "))
      local task = hs.task.new(obj.serverConfig.curlCmd, function(exitCode, stdOut, stdErr)
        if exitCode ~= 0 then
          callback(false, "curl failed: " .. (stdErr or "unknown error"))
          return
        end
        local text = (stdOut or ""):match("^%s*(.-)%s*$") -- trim whitespace
        if text == "" then
          callback(false, "Empty response from server")
          return
        end
        -- Check for server error response
        if text:match('^{"error"') then
          callback(false, "Server error: " .. text)
          return
        end
        -- Post-process: remove leading spaces from each line
        local lines = {}
        for line in text:gmatch("[^\n]+") do
          table.insert(lines, line:match("^%s*(.-)$"))
        end
        callback(true, table.concat(lines, "\n"))
      end, args)
      if not task then
        callback(false, "Failed to create hs.task for curl")
        return
      end
      local ok, err = pcall(function() task:start() end)
      if not ok then
        callback(false, "Failed to start curl: " .. tostring(err))
      end
    end,
  },
}

-- Select active transcription method (default to whispercli)
obj.transcriptionMethod = "whispercli"

-- === Logger ===
local Logger = {}
Logger.__index = Logger

function Logger.new()
  local self = setmetatable({}, Logger)
  self.logFile = os.getenv("HOME") .. "/.hammerspoon/Spoons/hs_whisperDictation/whisper.log"
  self.levels = {
    DEBUG = 0,
    INFO = 1,
    WARN = 2,
    ERROR = 3,
  }
  self.levelNames = {
    [0] = "DEBUG",
    [1] = "INFO",
    [2] = "WARN",
    [3] = "ERROR",
  }
  self.currentLevel = self.levels.INFO
  self.enableConsole = true
  self.enableFile = false
  return self
end

function Logger:_formatMessage(level, msg)
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  local levelName = self.levelNames[level]
  return string.format("[%s] [%s] %s", timestamp, levelName, msg)
end

function Logger:_writeToFile(formatted)
  local ok, f = pcall(io.open, self.logFile, "a")
  if ok and f then
    f:write(formatted .. "\n")
    f:close()
  end
end

function Logger:_log(level, msg, showAlert)
  if level < self.currentLevel then
    return
  end

  local formatted = self:_formatMessage(level, msg)

  if self.enableConsole then
    print("[WhisperDictation] " .. formatted)
  end

  if self.enableFile then
    self:_writeToFile(formatted)
  end

  if showAlert then
    local icon = level == self.levels.ERROR and obj.icons.error or obj.icons.info
    hs.alert.show(icon .. " " .. msg)
  end
end

function Logger:debug(msg)
  self:_log(self.levels.DEBUG, msg, false)
end

function Logger:info(msg, showAlert)
  self:_log(self.levels.INFO, msg, showAlert or false)
end

function Logger:warn(msg, showAlert)
  self:_log(self.levels.WARN, msg, showAlert or true)
end

function Logger:error(msg, showAlert)
  self:_log(self.levels.ERROR, msg, showAlert or true)
end

function Logger:setLevel(level)
  if self.levels[level] then
    self.currentLevel = self.levels[level]
  end
end



-- === Internal ===
obj.logger = Logger.new()

obj.recTask = nil
obj.menubar = nil
obj.hotkeys = {}
obj.timer = nil
obj.timeoutTimer = nil
obj.startTime = nil
obj.currentAudioFile = nil
obj.recordingIndicator = nil
obj.transcriptionCallback = nil

-- Server state (for whisperserver method)
obj.serverProcess = nil
obj.serverCurrentLang = nil  -- Track language to detect when restart is needed
obj.serverStarting = false   -- Track if server is currently starting (for async startup)

-- === Helpers ===
local function ensureDir(path)
  hs.fs.mkdir(path)
end

local function timestampedFile(baseDir, prefix, ext)
  local t = os.date("%Y%m%d-%H%M%S")
  return string.format("%s/%s-%s.%s", baseDir, prefix, t, ext)
end

local function currentLang()
  return obj.languages[obj.langIndex]
end

--- Scan tempDir for recent .wav recordings, sorted by modification time (newest first).
-- @param n (number): Maximum number of entries to return
-- @return (table): Array of { path, filename } tables
local function getRecentRecordings(n)
  local recordings = {}
  local iter, dirObj = hs.fs.dir(obj.tempDir)
  if not iter then
    return recordings
  end
  for filename in iter, dirObj do
    if filename:match("%.wav$") then
      local fullPath = obj.tempDir .. "/" .. filename
      local attrs = hs.fs.attributes(fullPath)
      if attrs then
        table.insert(recordings, {
          path = fullPath,
          filename = filename,
          modified = attrs.modification,
          size = attrs.size,
        })
      end
    end
  end
  table.sort(recordings, function(a, b) return a.modified > b.modified end)
  local result = {}
  for i = 1, math.min(n, #recordings) do
    result[i] = recordings[i]
  end
  return result
end

local function updateMenu(title, tip)
  if obj.menubar then
    obj.menubar:setTitle(title)
    obj.menubar:setTooltip(tip)
  end
end

local function resetMenuToIdle()
  updateMenu(obj.icons.idle .. " (" .. currentLang() .. ")", "Idle")
end

local function updateElapsed()
  if obj.startTime then
    local elapsed = os.difftime(os.time(), obj.startTime)
    updateMenu(string.format(obj.icons.recording .. " %ds (%s)", elapsed, currentLang()), "Recording...")
  end
end

local function showRecordingIndicator()
  if obj.recordingIndicator then return end

  local focusedWindow = hs.window.focusedWindow()
  local screen = focusedWindow and focusedWindow:screen() or hs.screen.mainScreen()
  local frame = screen:frame()
  local centerX = frame.x + frame.w / 2
  local centerY = frame.y + frame.h / 2
  local radius = frame.h / 20

  obj.recordingIndicator = hs.drawing.circle(
    hs.geometry.rect(
      centerX - radius,
      centerY - radius,
      radius * 2,
      radius * 2
    )
  )

  local style = obj.recordingIndicatorStyle
  obj.recordingIndicator:setFillColor(style.fillColor)
  obj.recordingIndicator:setStrokeColor(style.strokeColor)
  obj.recordingIndicator:setStrokeWidth(style.strokeWidth)
  obj.recordingIndicator:show()
end

local function hideRecordingIndicator()
  if obj.recordingIndicator then
    obj.recordingIndicator:delete()
    obj.recordingIndicator = nil
  end
end

local function startRecordingSession()
  -- Start elapsed time display timer
  obj.startTime = os.time()
  if obj.timer then obj.timer:stop() end
  obj.timer = hs.timer.doEvery(1, updateElapsed)

  -- Start auto-stop timeout timer if configured
  if obj.timeoutSeconds and obj.timeoutSeconds > 0 then
    if obj.timeoutTimer then obj.timeoutTimer:stop() end
    obj.timeoutTimer = hs.timer.doAfter(obj.timeoutSeconds, function()
      if obj.recTask then
        obj.logger:warn(obj.icons.stopped .. " Recording auto-stopped due to timeout (" .. obj.timeoutSeconds .. "s)", true)
        obj:toggleTranscribe()
      end
    end)
  end

  -- Show recording indicator if enabled
  if obj.showRecordingIndicator then
    showRecordingIndicator()
  end
end

local function stopRecordingSession()
  -- Terminate recording task
  if obj.recTask then
    obj.logger:info(obj.icons.stopped .. " Recording stopped")
    obj.recTask:terminate()
    obj.recTask = nil
  end

  -- Stop elapsed time display timer
  if obj.timer then
    obj.timer:stop()
    obj.timer = nil
  end
  obj.startTime = nil

  -- Stop auto-stop timeout timer
  if obj.timeoutTimer then
    obj.timeoutTimer:stop()
    obj.timeoutTimer = nil
  end

  -- Hide recording indicator
  hideRecordingIndicator()

  -- Reset menu to idle state
  resetMenuToIdle()
end

-- === Server Lifecycle Methods ===

--- Get the best available model path.
-- Checks primary path first, falls back to fallback path.
-- @return (string|nil): Model path or nil if neither exists
local function getServerModelPath()
  if hs.fs.attributes(obj.serverConfig.modelPath) then
    return obj.serverConfig.modelPath
  end
  return nil
end

--- Check if a whisper server is responding on the configured port.
-- @return (boolean): true if server is healthy (regardless of who started it)
function obj:isServerRunning()
  -- Health check via curl (synchronous, fast)
  -- In Lua 5.2+, os.execute returns: true/nil, "exit"/"signal", code
  local serverUrl = string.format("http://%s:%s", self.serverConfig.host, self.serverConfig.port)
  local ok = os.execute(string.format(
    "%s -s -o /dev/null --connect-timeout 1 %s 2>/dev/null",
    self.serverConfig.curlCmd, serverUrl
  ))
  -- If server is not responding but we have a process handle, clean it up
  if ok ~= true and self.serverProcess then
    if not self.serverProcess:isRunning() then
      self.serverProcess = nil
    end
  end
  return ok == true
end

--- Start the whisper server asynchronously.
-- If a server is already running on the port (externally started), adopts it.
-- @param callback (function|nil): Optional callback called with (success, error_message) when server is ready or fails
-- @return (boolean, string|nil): success (immediate check), error message on failure
function obj:startServer(callback)
  if self:isServerRunning() then
    -- Server already running - could be ours or external
    if self.serverProcess then
      self.logger:info("Whisper server already running (managed by this spoon)")
    else
      self.logger:info("Whisper server already running (external process)")
    end
    self.serverCurrentLang = currentLang()
    if callback then callback(true, nil) end
    return true, nil
  end

  -- Check if server is already starting
  if self.serverStarting then
    hs.alert.show("Server already starting...")
    self.logger:info("Server startup already in progress")
    return false, "Server already starting"
  end

  local modelPath = getServerModelPath()
  if not modelPath then
    local err = "Whisper model not found at " .. self.serverConfig.modelPath
    self.logger:error(err, true)
    if callback then callback(false, err) end
    return false, err
  end

  if not hs.fs.attributes(self.serverConfig.executable) then
    local err = "Whisper server executable not found at " .. self.serverConfig.executable
    self.logger:error(err, true)
    if callback then callback(false, err) end
    return false, err
  end

  local args = {
    "-m", modelPath,
    "--host", self.serverConfig.host,
    "--port", self.serverConfig.port,
  }

  self.logger:info("Starting whisper server with model " .. modelPath)
  self.serverProcess = hs.task.new(self.serverConfig.executable, function(exitCode, stdOut, stdErr)
    self.logger:warn("Whisper server exited with code " .. tostring(exitCode))
    if stdErr and #stdErr > 0 then
      self.logger:debug("Server stderr: " .. stdErr)
    end
    self.serverProcess = nil
    self.serverStarting = false
  end, args)

  if not self.serverProcess then
    local err = "Failed to create server task"
    self.logger:error(err, true)
    if callback then callback(false, err) end
    return false, err
  end

  local ok, err = pcall(function() self.serverProcess:start() end)
  if not ok then
    self.serverProcess = nil
    local errMsg = "Failed to start server: " .. tostring(err)
    self.logger:error(errMsg, true)
    if callback then callback(false, errMsg) end
    return false, errMsg
  end

  -- Mark server as starting and show alert
  self.serverStarting = true
  self.serverCurrentLang = currentLang()
  hs.alert.show("Starting whisper server...")

  -- Start async polling to check when server is ready
  local pollInterval = 0.5
  local maxAttempts = math.ceil(self.serverConfig.startupTimeout / pollInterval)
  local attempts = 0

  local pollTimer
  pollTimer = hs.timer.doEvery(pollInterval, function()
    attempts = attempts + 1
    if self:isServerRunning() then
      -- Server is ready
      pollTimer:stop()
      self.serverStarting = false
      self.logger:info("Whisper server ready")
      hs.alert.show("Whisper server ready")
      if callback then callback(true, nil) end
    elseif attempts >= maxAttempts then
      -- Timeout reached
      pollTimer:stop()
      self.serverStarting = false
      local errMsg = "Server failed to start after " .. self.serverConfig.startupTimeout .. " seconds"
      self.logger:error(errMsg, true)
      if callback then callback(false, errMsg) end
    elseif not self.serverProcess or not self.serverProcess:isRunning() then
      -- Server process died
      pollTimer:stop()
      self.serverStarting = false
      local errMsg = "Server process exited unexpectedly"
      self.logger:error(errMsg, true)
      if callback then callback(false, errMsg) end
    end
  end)

  return true, nil
end

--- Stop the whisper server (only if managed by this spoon).
-- External servers are not stopped.
function obj:stopServer()
  if self.serverProcess and self.serverProcess:isRunning() then
    self.logger:info("Stopping whisper server")
    self.serverProcess:terminate()
    self.serverProcess = nil
    self.serverCurrentLang = nil
    self.serverStarting = false
  elseif self:isServerRunning() then
    self.logger:info("External whisper server running - not stopping (not managed by this spoon)")
  end
end

--- Ensure the whisper server is running, starting it if needed.
-- This is now an async function that uses a callback.
-- @param callback (function): Called with (success, error_message) when server is ready or fails
function obj:ensureServer(callback)
  if self:isServerRunning() then
    if callback then callback(true, nil) end
    return
  end

  if self.serverStarting then
    if callback then callback(false, "Server is starting...") end
    return
  end

  -- Start the server asynchronously
  self:startServer(callback)
end

--- Restart the server if language has changed.
-- Only relevant for whisperserver method.
-- Note: External servers cannot be restarted - a warning is logged.
-- Note: Server startup is async - returns true if restart was initiated, server will notify when ready.
-- @return (boolean): true if restart was initiated or not needed, false on immediate failure
function obj:restartServerIfNeeded()
  if self.transcriptionMethod ~= "whisperserver" then
    return true
  end
  if self.serverCurrentLang == currentLang() then
    return true  -- No restart needed
  end
  if not self.serverProcess and self:isServerRunning() then
    -- External server - can't restart it
    self.logger:warn("Language changed but using external server - cannot restart. Transcription may use wrong language.")
    self.serverCurrentLang = currentLang()
    return true
  end
  if not self.serverProcess then
    return true  -- No server running, will be started on next transcription
  end

  self.logger:info("Language changed, restarting server")
  self:stopServer()
  local started, _ = self:startServer()
  return started
end

-- === Transcription Handling ===

--- Handle transcription result from any method.
-- @param success (boolean): Whether transcription succeeded
-- @param textOrError (string): Transcribed text on success, error message on failure
-- @param audioFile (string): Path to the audio file (for saving transcript)
local function handleTranscriptionResult(success, textOrError, audioFile)
  local method = obj.transcriptionMethods[obj.transcriptionMethod]

  if not success then
    obj.logger:error(method.displayName .. ": " .. textOrError, true)
    resetMenuToIdle()
    return
  end

  local text = textOrError

  -- Save transcript to file
  local outputFile = audioFile:gsub("%.wav$", ".txt")
  local f, err = io.open(outputFile, "w")
  if f then
    f:write(text)
    f:close()
    obj.logger:debug("Transcript written to file: " .. outputFile)
  else
    obj.logger:warn("Could not save transcript file: " .. tostring(err))
  end

  -- Call the callback if one was provided
  if obj.transcriptionCallback then
    local ok, callbackErr = pcall(obj.transcriptionCallback, text)
    if not ok then
      obj.logger:error("Callback error: " .. tostring(callbackErr))
    end
    obj.transcriptionCallback = nil
  else
    -- Only copy to clipboard if no callback was provided (preserves default behavior)
    local ok, errPB = pcall(hs.pasteboard.setContents, text)
    if not ok then
      obj.logger:error("Failed to copy to clipboard: " .. tostring(errPB), true)
      resetMenuToIdle()
      return
    end
    obj.logger:info(obj.icons.clipboard .. " Copied to clipboard (" .. #text .. " chars)")
  end

  resetMenuToIdle()
end

--- Transcribe an audio file using the selected method.
-- @param audioFile (string): Path to the WAV file to transcribe
local function transcribe(audioFile)
  local method = obj.transcriptionMethods[obj.transcriptionMethod]
  if not method then
    obj.logger:error("Unknown transcription method: " .. obj.transcriptionMethod, true)
    resetMenuToIdle()
    return
  end

  obj.logger:info(obj.icons.transcribing .. " Transcribing (" .. currentLang() .. ")...", true)
  updateMenu(obj.icons.idle .. " (" .. currentLang() .. " T)", "Transcribing...")

  -- Call the method's transcribe function with callback
  method:transcribe(audioFile, currentLang(), function(success, textOrError)
    handleTranscriptionResult(success, textOrError, audioFile)
  end)
end


local function showLanguageChooser()
  local choices = {}
  for i, lang in ipairs(obj.languages) do
    table.insert(choices, {
      text = lang,
      subText = (i == obj.langIndex and "✓ Selected" or ""),
      lang = lang,
      index = i,
    })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      obj.langIndex = choice.index
      obj.logger:info(obj.icons.language .. " Language switched to: " .. choice.lang, true)
      -- Restart server if using whisperserver method and language changed
      obj:restartServerIfNeeded()
      resetMenuToIdle()
    end
  end)

--  chooser:width(0.3)
  chooser:choices(choices)
  chooser:show()
end

--- Re-transcribe a previously recorded audio file using the retranscribe backend.
-- @param audioFile (string): Path to the WAV file
-- @param lang (string): Language code extracted from the filename
-- @param callback (function|nil): Optional callback receiving transcribed text
local function retranscribe(audioFile, lang, callback)
  local method = obj.transcriptionMethods[obj.retranscribeMethod]
  if not method then
    obj.logger:error("Unknown retranscription method: " .. obj.retranscribeMethod, true)
    return
  end

  obj.transcriptionCallback = callback
  local savedMethod = obj.transcriptionMethod
  obj.transcriptionMethod = obj.retranscribeMethod

  obj.logger:info(obj.icons.transcribing .. " Re-transcribing with " .. method.displayName .. " (" .. lang .. ")...", true)
  updateMenu(obj.icons.idle .. " (" .. lang .. " T)", "Re-transcribing...")

  method:transcribe(audioFile, lang, function(success, textOrError)
    obj.transcriptionMethod = savedMethod
    handleTranscriptionResult(success, textOrError, audioFile)
  end)
end

--- Show a chooser with recent recordings for re-transcription.
-- @param callback (function|nil): Optional callback receiving transcribed text
local function showRetranscribeChooser(callback)
  local recordings = getRecentRecordings(obj.retranscribeCount)
  if #recordings == 0 then
    obj.logger:warn("No recent recordings found in " .. obj.tempDir, true)
    return
  end

  local choices = {}
  for _, rec in ipairs(recordings) do
    -- Parse filename pattern: {lang}-{YYYYMMDD-HHMMSS}.wav
    local lang, dateStr, timeStr = rec.filename:match("^(%w+)-(%d%d%d%d%d%d%d%d)-(%d%d%d%d%d%d)%.wav$")
    local displayText = rec.filename
    if lang and dateStr and timeStr then
      local y = dateStr:sub(1, 4)
      local m = dateStr:sub(5, 6)
      local d = dateStr:sub(7, 8)
      local hh = timeStr:sub(1, 2)
      local mm = timeStr:sub(3, 4)
      local ss = timeStr:sub(5, 6)
      local timestamp = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d),
                                  hour=tonumber(hh), min=tonumber(mm), sec=tonumber(ss)})
      displayText = lang .. " - " .. os.date("%b %d, %Y %H:%M:%S", timestamp)
    end

    table.insert(choices, {
      text = displayText,
      subText = rec.filename .. string.format(" (%.1f MB)", rec.size / (1024 * 1024)),
      path = rec.path,
      lang = lang or "en",
    })
  end

  local chooser = hs.chooser.new(function(choice)
    if choice then
      retranscribe(choice.path, choice.lang, callback)
    end
  end)

  chooser:choices(choices)
  chooser:show()
end

-- === Public API ===
function obj:beginTranscribe(callback)
  if self.recTask ~= nil then
    self.logger:warn("Recording already in progress", true)
    return self
  end

  ensureDir(self.tempDir)
  local audioFile = timestampedFile(self.tempDir, currentLang(), "wav")
  self.logger:info(self.icons.recording .. " Recording started (" .. currentLang() .. ") - " .. audioFile, true)
  self.logger:info("Running: " .. self.recordCmd .. "-q -d " .. audioFile)
  self.recTask = hs.task.new(self.recordCmd, nil, {"-q", "-d", audioFile})

  if not self.recTask then
    self.logger:error("Failed to create recording task", true)
    resetMenuToIdle()
    return self
  end

  local ok, err = pcall(function() self.recTask:start() end)
  if not ok then
    self.logger:error("Failed to start recording: " .. tostring(err), true)
    self.recTask = nil
    resetMenuToIdle()
    return self
  end

  self.currentAudioFile = audioFile
  self.transcriptionCallback = callback
  startRecordingSession()
  return self
end

function obj:endTranscribe()
  if self.recTask == nil then
    self.logger:warn("No recording in progress", true)
    return self
  end

  stopRecordingSession()
  if self.currentAudioFile then
    if not hs.fs.attributes(self.currentAudioFile) then
      self.logger:error("Recording file was not created: " .. self.currentAudioFile, true)
      self.currentAudioFile = nil
      return self
    end
    self.logger:info("Processing audio file: " .. self.currentAudioFile)
    transcribe(self.currentAudioFile)
    self.currentAudioFile = nil
  end
  return self
end

function obj:toggleTranscribe()
  if self.recTask == nil then
    self:beginTranscribe()
  else
    self:endTranscribe()
  end
  return self
end

--- Show a chooser with recent recordings and re-transcribe the selected one.
-- @param callback (function|nil): Optional callback receiving transcribed text. If nil, copies to clipboard.
-- @return self
function obj:transcribeLatestAgain(callback)
  showRetranscribeChooser(callback)
  return self
end

function obj:start()
  obj.logger:info("Starting WhisperDictation")
  local errorSuffix = " WhisperDictation not started"

  -- Validate recording command
  if not hs.fs.attributes(obj.recordCmd) then
    obj.logger:error("recording command not found: " .. obj.recordCmd .. errorSuffix, true)
    return
  end

  -- Validate transcription method
  local method = obj.transcriptionMethods[obj.transcriptionMethod]
  if not method then
    obj.logger:error("Unknown transcription method: " .. obj.transcriptionMethod .. errorSuffix, true)
    return
  end

  if not method:validate() then
    -- Build appropriate error message based on method type
    local details = method.config.cmd or obj.serverConfig.executable
    obj.logger:error(method.displayName .. " not found: " .. details .. errorSuffix, true)
    return
  end

  ensureDir(obj.tempDir)

  if not obj.menubar then
    obj.menubar = hs.menubar.new()
    obj.menubar:setClickCallback(function() obj:toggleTranscribe() end)
  end

  -- Start server if using whisperserver method
  if obj.transcriptionMethod == "whisperserver" then
    obj.logger:info("Starting whisper server...")
    local started, err = obj:startServer()
    if not started then
      obj.logger:warn("Server not started: " .. tostring(err) .. " (will retry on first transcription)")
    end
  end

  resetMenuToIdle()
  obj.logger:info("WhisperDictation ready using " .. method.displayName .. " (" .. currentLang() .. ")")
end

function obj:stop()
  obj.logger:info("Stopping WhisperDictation")

  -- Stop the whisper server if running
  obj:stopServer()

  if obj.menubar then
    obj.menubar:delete()
    obj.menubar = nil
  end
  for _, hk in pairs(obj.hotkeys) do hk:delete() end
  obj.hotkeys = {}
  stopRecordingSession()
  obj.logger:info("WhisperDictation stopped", true)
end

function obj:bindHotKeys(mapping)
  obj.logger:debug("Binding hotkeys")
  local map = hs.fnutils.copy(mapping or obj.defaultHotkeys)
  for name, spec in pairs(map) do
    if obj.hotkeys[name] then obj.hotkeys[name]:delete() end
    if name == "toggle" then
      obj.hotkeys[name] = hs.hotkey.bind(spec[1], spec[2], function() obj:toggleTranscribe() end)
      obj.logger:debug("Bound hotkey: toggle to " .. table.concat(spec[1], "+") .. "+" .. spec[2])
    elseif name == "nextLang" then
      obj.hotkeys[name] = hs.hotkey.bind(spec[1], spec[2], showLanguageChooser)
      obj.logger:debug("Bound hotkey: nextLang to " .. table.concat(spec[1], "+") .. "+" .. spec[2])
    elseif name == "retranscribe" then
      obj.hotkeys[name] = hs.hotkey.bind(spec[1], spec[2], function() obj:transcribeLatestAgain() end)
      obj.logger:debug("Bound hotkey: retranscribe to " .. table.concat(spec[1], "+") .. "+" .. spec[2])
    end
  end
  return self
end

return obj
