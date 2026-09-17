-- Clipper: Screenshot capture, upload, and OCR module
--
-- Features:
-- - Watches pasteboard for new screenshots
-- - Async upload to DigitalOcean Spaces
-- - Vision-based OCR (with tesseract fallback)
-- - HUD panel with media, status, keybindings
-- - Persistent state (survives non-image clipboard changes)
--
-- Keybindings:
-- - HYPER+⇧V: Open clipper modal (full options)
-- - In modal:
--   - v: Paste original image (native behavior)
--   - V: Paste URL
--   - m: Paste markdown
--   - h: Paste HTML tag
--   - p: OCR to clipboard (shows processing status)
--   - e: Edit in Preview
--   - n: Quick capture to notes
--   - N: Full capture with editor
--   - Esc: Dismiss

local fmt = string.format
local shade = require("lib.interop.shade")
local pasteboard = require("watchers.pasteboard")

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@class ClipperCapture
---@field id number Monotonic capture generation
---@field changeCount number|nil Source pasteboard generation
---@field image hs.image Original captured image
---@field imageData string|nil Raw source image data for pasting and async serialization
---@field imageUTI string|nil UTI for imageData
---@field imagePath string Local file path
---@field imageName string Filename
---@field imageUrl string|nil DO Spaces URL (set after upload)
---@field ocrText string|nil OCR extracted text (lazy loaded)
---@field timestamp number When capture occurred
---@field uploadStatus "idle"|"verifying"|"uploading"|"complete"|"failed"|"gatekeeper" Upload state
---@field ocrStatus "idle"|"processing"|"complete"|"failed" OCR state
---@field gatekeeperReason string|nil Gatekeeper violation reason
---@field originalImagePath string|nil Original PNG path before optimization
---@field fileSizeBytes number|nil Image file size in bytes

---@class ClipperModule
---@field capture ClipperCapture|nil Current capture state
---@field panel HUDPanel|nil Active HUD panel
---@field modal hs.hotkey.modal|nil Modal for single-key actions
---@field hyper table|nil Hyper key binding
---@field config ClipperConfig Configuration
---@field activeTasks table<string, hs.task> Running tasks for cleanup
---@field timers table<string, hs.timer> Deferred callbacks for cleanup
---@field nextCaptureId number Last allocated capture generation
---@field nextTaskId number Last allocated per-task identifier

---@class ClipperBinding
---@field key string Key to bind
---@field mods string[] Modifier keys
---@field action string Action name (maps to M.actions)
---@field desc string Description for cheatsheet
---@field requiresUrl? boolean Only available when upload complete

---@class ClipperConfig
---@field captureTimeout number Seconds before capture becomes stale
---@field capsPath string Directory for saved screenshots
---@field bindings ClipperBinding[] Modal keybindings
---@field entryBinding { key: string, mods: string[], desc: string } Entry binding

--------------------------------------------------------------------------------
-- MODULE
--------------------------------------------------------------------------------

---@type ClipperModule
local M = {}

-- State
M.capture = nil
M.panel = nil
M.modal = nil
M.hyper = nil
M.activeTasks = {}  -- Track running hs.task for cleanup
M.timers = {}
M.isModalActive = false
M.ocrPasteWatcher = nil
M.clickOutsideWatcher = nil
M.appWatcher = nil  -- Track app focus changes to exit modal
M.fullScreenHotkey = nil
M.nextCaptureId = 0
M.nextTaskId = 0

-- Configuration
M.config = {
  captureTimeout = 300, -- 5 minutes
  capsPath = os.getenv("HOME") .. "/_screenshots",

  -- Gatekeeper: max image size for Claude API (5MB limit for base64 images)
  maxImageSizeBytes = 5 * 1024 * 1024, -- 5MB
  maxImageSizeMB = 5,
  optimizedImageTargetKB = 4000, -- Conservative upload target after resize/compress

  -- Modal keybindings: { key, mods, action, description, requiresUrl? }
  -- Cheatsheet is auto-generated from this
  -- requiresUrl: only shown/enabled when upload is complete
  bindings = {
    { key = "v", mods = {}, action = "pasteImage", desc = "Paste image" },
    { key = "v", mods = { "shift" }, action = "pasteUrl", desc = "Paste URL", requiresUrl = true },
    { key = "m", mods = {}, action = "pasteMarkdown", desc = "Markdown", requiresUrl = true },
    { key = "h", mods = {}, action = "pasteHtml", desc = "HTML tag", requiresUrl = true },
    { key = "p", mods = {}, action = "ocrToClipboard", desc = "OCR to clipboard" },
    { key = "e", mods = {}, action = "editInPreview", desc = "Edit in Preview" },
    { key = "n", mods = {}, action = "captureQuick", desc = "Quick capture" },
    { key = "n", mods = { "shift" }, action = "captureFull", desc = "Full capture" },
    { key = "escape", mods = {}, action = "exit", desc = "Dismiss" },
  },

  -- Entry binding (outside modal)
  entryBinding = { key = "v", mods = { "shift" }, desc = "Open modal" },
}

--------------------------------------------------------------------------------
-- STATE MANAGEMENT
--------------------------------------------------------------------------------

---Check if we have a valid (non-stale) capture
---@return boolean
function M.hasCapture()
  if not M.capture then return false end
  local elapsed = os.time() - M.capture.timestamp
  return elapsed < M.config.captureTimeout
end

---@param captureId number
---@return boolean
local function isCurrentCapture(captureId)
  return M.capture ~= nil and M.capture.id == captureId
end

---@param name string
local function cancelTask(name)
  local task = M.activeTasks[name]
  if not task then return end

  -- Relinquish ownership before termination because termination can invoke the
  -- callback. A callback may only mutate state while it still owns this slot.
  M.activeTasks[name] = nil
  if task:isRunning() then task:terminate() end
end

local function cancelCaptureTasks()
  for _, name in ipairs({ "save", "upload", "resize", "ocr", "screenshot" }) do
    cancelTask(name)
  end
end

local function stopTimer(name)
  local timer = M.timers[name]
  if not timer then return end
  M.timers[name] = nil
  timer:stop()
end

local function schedule(name, delay, callback)
  stopTimer(name)
  local timer
  timer = hs.timer.doAfter(delay, function()
    if M.timers[name] ~= timer then return end
    M.timers[name] = nil
    callback()
  end)
  M.timers[name] = timer
end

--------------------------------------------------------------------------------
-- HUD PANEL
--------------------------------------------------------------------------------

---Check if a point is inside a frame
---@param point {x: number, y: number}
---@param frame {x: number, y: number, w: number, h: number}
---@return boolean
local function pointInFrame(point, frame)
  return point.x >= frame.x
    and point.x <= frame.x + frame.w
    and point.y >= frame.y
    and point.y <= frame.y + frame.h
end

---Stop the click-outside watcher
function M.stopClickOutsideWatcher()
  if M.clickOutsideWatcher then
    M.clickOutsideWatcher:stop()
    M.clickOutsideWatcher = nil
  end
end

---Start watching for clicks outside the panel
function M.startClickOutsideWatcher()
  M.stopClickOutsideWatcher()
  
  M.clickOutsideWatcher = hs.eventtap.new(
    { hs.eventtap.event.types.leftMouseDown },
    function(event)
      if not M.panel or not M.panel.canvas then return false end
      
      local clickPoint = hs.mouse.absolutePosition()
      local panelFrame = M.panel.canvas:frame()
      
      if not pointInFrame(clickPoint, panelFrame) then
        -- Leaving modal mode must not dismiss the passive processing HUD.
        M.exitModal()
      end

      return false
    end
  )
  M.clickOutsideWatcher:start()
end

---Stop the app focus watcher
function M.stopAppWatcher()
  if M.appWatcher then
    M.appWatcher:stop()
    M.appWatcher = nil
  end
end

---Start watching for app focus changes to exit modal
---When user switches to another app (cmd+tab, click on dock, etc.), exit modal
function M.startAppWatcher()
  M.stopAppWatcher()
  
  M.appWatcher = hs.application.watcher.new(function(appName, eventType, appObj)
    if not M.isModalActive then return end
    
    -- Exit modal when another app is activated
    if eventType == hs.application.watcher.activated then
      -- Hammerspoon itself doesn't count (we're the HUD)
      if appObj and appObj:bundleID() ~= "org.hammerspoon.Hammerspoon" then
        U.log.d(fmt("app focus changed to %s, exiting modal", appName or "unknown"))
        M.exitModal()
      end
    end
  end)
  M.appWatcher:start()
end

---Show or update the passive clipper HUD without entering modal mode.
function M.showPanel()
  if not M.hasCapture() then return end

  if M.panel and not M.panel.visible then M.panel = nil end
  if not M.panel then
    local panel
    panel = HUD.panel({
      id = "clipper",
      position = "bottom-center",
      ephemeral = false,
      onClick = function()
        M.dismissPanel()
        return true
      end,
      onDismiss = function()
        if M.panel == panel and not panel.visible then
          M.panel = nil
          M.exitModal()
        end
      end,
    })
    M.panel = panel
  end

  M.updatePanelStatus()
  M.panel:show()
end

---Generate cheatsheet content based on current state.
local function buildPanelCheatsheet()
  local cheatsheet = {}
  local hasUrl = M.capture and M.capture.uploadStatus == "complete"

  for _, binding in ipairs(M.config.bindings) do
    -- Format key display (uppercase if shift modifier)
    local keyDisplay = binding.key
    if binding.mods and hs.fnutils.contains(binding.mods, "shift") then
      keyDisplay = binding.key:upper()
    end
    if binding.key == "escape" then
      keyDisplay = "Esc"
    end

    -- Mark availability (URL-dependent bindings dimmed until upload complete)
    local available = not binding.requiresUrl or hasUrl

    table.insert(cheatsheet, {
      key = keyDisplay,
      desc = binding.desc,
      available = available,
    })
  end

  return cheatsheet
end

---Update panel status with one canvas render.
---Shows combined upload + OCR status
local formatSize
-- Status display handlers
local ocrStatusHandlers = {
  processing = function()
    return "Processing OCR...", "5AC8FA" -- Blue
  end,
  complete = function(capture)
    if capture.ocrText then
      -- Set preview in panel (handled separately)
      return "✓ Copied · Cmd+V to paste", "4CD964" -- Green
    end
    return nil -- Fall through to upload status
  end,
  failed = function()
    return "✗ OCR failed", "FF3B30" -- Red
  end,
}

local uploadStatusHandlers = {
  verifying = function()
    return "Gatekeeper verifying...", "5AC8FA" -- Blue
  end,
  uploading = function()
    return "Uploading...", "FFA500" -- Orange
  end,
  complete = function()
    return "✓ Uploaded", "4CD964" -- Green
  end,
  failed = function()
    return "✗ Upload failed", "FF3B30" -- Red
  end,
  gatekeeper = function(capture)
    return U.case(capture.gatekeeperReason, {
      {
        "image too large",
        function()
          return fmt("⚠ too large (%s), resizing..", formatSize(capture.fileSizeBytes or 0)), "FF9500"
        end,
      },
    }, function(reason)
      return "⚠ gatekeeper: " .. (reason or "blocked"), "FF9500" -- Orange/amber
    end)
  end,
}

function M.updatePanelStatus()
  if not M.panel or not M.capture then return end

  local statusText, primaryColor

  -- OCR status takes precedence
  local ocrHandler = ocrStatusHandlers[M.capture.ocrStatus]
  if ocrHandler then
    statusText, primaryColor = ocrHandler(M.capture)
  end

  -- Fall back to upload status
  if not statusText then
    local uploadHandler = uploadStatusHandlers[M.capture.uploadStatus]
    if uploadHandler then
      statusText, primaryColor = uploadHandler(M.capture)
    else
      statusText, primaryColor = "Ready", "8E8E93"
    end
  end

  local preview = false
  if M.capture.ocrStatus == "complete" and M.capture.ocrText then
    preview = M.capture.ocrText
  end

  M.panel:setState({
    media = M.capture.image,
    mediaOpts = {
      minWidth = 320,
      maxWidth = 320,
      maxHeight = 180,
      onClick = function()
        if M.capture and M.capture.imagePath then hs.open(M.capture.imagePath) end
      end,
    },
    status = statusText,
    statusColor = primaryColor,
    preview = preview,
    previewOpts = { font = "JetBrainsMono Nerd Font Mono", maxLines = 5 },
    content = buildPanelCheatsheet(),
  })
end

---Hide the clipper panel explicitly.
function M.hidePanel()
  local panel = M.panel
  M.panel = nil
  if panel then panel:dismiss() end
end

function M.dismissPanel()
  M.exitModal()
  M.hidePanel()
end

--------------------------------------------------------------------------------
-- GATEKEEPER (FILE SIZE CHECK)
--------------------------------------------------------------------------------

---Get file size in bytes
---@param path string
---@return number|nil size in bytes, or nil if file doesn't exist
local function getFileSizeBytes(path)
  local attrs = hs.fs.attributes(path)
  if attrs then
    return attrs.size
  end
  return nil
end

---Format bytes as human-readable string
---@param bytes number
---@return string
function formatSize(bytes)
  if bytes < 1024 then
    return fmt("%d bytes", bytes)
  elseif bytes < 1024 * 1024 then
    return fmt("%.1f KB", bytes / 1024)
  else
    return fmt("%.1f MB", bytes / (1024 * 1024))
  end
end

---Check if image passes gatekeeper (file size limit)
---@param imagePath string
---@return boolean passes, string|nil reason
function M.checkGatekeeper(imagePath)
  local sizeBytes = getFileSizeBytes(imagePath)
  if not sizeBytes then
    return true, nil -- Can't check, let it through
  end

  if sizeBytes > M.config.maxImageSizeBytes then
    return false, "image too large"
  end

  return true, nil
end

--------------------------------------------------------------------------------
-- UPLOAD (ASYNC)
--------------------------------------------------------------------------------

---Resize/compress an oversized capture before upload.
---@param imagePath string
---@param captureId number
function M.resizeForUpload(imagePath, captureId)
  if not isCurrentCapture(captureId) or M.capture.imagePath ~= imagePath then return end

  cancelTask("resize")
  M.nextTaskId = M.nextTaskId + 1
  local basePath = imagePath:gsub("%.[^/%.]+$", "")
  local outputPath = fmt("%s_resized_%d_%d.jpg", basePath, captureId, M.nextTaskId)
  local imageName = outputPath:gsub(".*/", "")

  local task
  task = hs.task.new("/usr/bin/env", function(exitCode, _stdOut, stdErr)
    if M.activeTasks.resize ~= task then
      os.remove(outputPath)
      return
    end
    M.activeTasks.resize = nil
    if not isCurrentCapture(captureId) or M.capture.imagePath ~= imagePath then
      os.remove(outputPath)
      return
    end

    if exitCode ~= 0 then
      M.capture.gatekeeperReason = "resize failed"
      M.updatePanelStatus()
      U.log.e(fmt("magick resize failed: %s", stdErr))
      return
    end

    local resizedSizeBytes = getFileSizeBytes(outputPath)
    if not resizedSizeBytes then
      M.capture.gatekeeperReason = "resize produced no file"
      M.updatePanelStatus()
      U.log.w(M.capture.gatekeeperReason)
      return
    end

    if resizedSizeBytes > M.config.maxImageSizeBytes then
      M.capture.gatekeeperReason = fmt(
        "resize too large: %s > %dMB limit",
        formatSize(resizedSizeBytes),
        M.config.maxImageSizeMB
      )
      M.updatePanelStatus()
      U.log.w(M.capture.gatekeeperReason)
      return
    end

    M.capture.originalImagePath = imagePath
    M.capture.imagePath = outputPath
    M.capture.imageName = imageName
    M.capture.fileSizeBytes = resizedSizeBytes
    M.capture.gatekeeperReason = nil
    U.log.i(fmt("resized capture to %s", formatSize(resizedSizeBytes)))

    M.verifyAndUpload(outputPath, captureId)
  end, {
    "magick",
    imagePath,
    "-auto-orient",
    "-strip",
    "-background",
    "white",
    "-alpha",
    "remove",
    "-alpha",
    "off",
    "-resize",
    "3000x3000>",
    "-define",
    fmt("jpeg:extent=%dKB", M.config.optimizedImageTargetKB),
    outputPath,
  })

  if not task then
    M.capture.gatekeeperReason = "resize task failed to start"
    M.updatePanelStatus()
    return
  end

  M.activeTasks.resize = task
  if not task:start() then
    M.activeTasks.resize = nil
    M.capture.gatekeeperReason = "resize task failed to start"
    M.updatePanelStatus()
  end
end

---Run gatekeeper verification and upload if passed.
---@param imagePath string
---@param captureId number
function M.verifyAndUpload(imagePath, captureId)
  if not isCurrentCapture(captureId) or M.capture.imagePath ~= imagePath then return end

  local passes, reason = M.checkGatekeeper(imagePath)
  if not passes then
    M.capture.uploadStatus = "gatekeeper"
    M.capture.gatekeeperReason = reason
    M.updatePanelStatus()
    U.log.w(fmt("gatekeeper blocked upload: %s", reason))

    if reason == "image too large" then M.resizeForUpload(imagePath, captureId) end
    return
  end

  M.capture.uploadStatus = "uploading"
  M.updatePanelStatus()
  cancelTask("upload")

  local task
  task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if M.activeTasks.upload ~= task then return end
    M.activeTasks.upload = nil
    if not isCurrentCapture(captureId) or M.capture.imagePath ~= imagePath then return end

    local url = stdOut and stdOut:match("([^\r\n]+)%s*$") or nil
    if exitCode == 0 and url then
      M.capture.imageUrl = url
      M.capture.uploadStatus = "complete"
      U.log.i(fmt("uploaded %s", url))
    else
      M.capture.uploadStatus = "failed"
      U.log.e(fmt("upload failed: %s", stdErr))
    end

    M.updatePanelStatus()
  end, { "capper", imagePath })

  if not task then
    M.capture.uploadStatus = "failed"
    M.updatePanelStatus()
    return
  end

  M.activeTasks.upload = task
  if not task:start() then
    M.activeTasks.upload = nil
    M.capture.uploadStatus = "failed"
    M.updatePanelStatus()
  end
end

--------------------------------------------------------------------------------
-- OCR (ASYNC)
--------------------------------------------------------------------------------

---Extract text via OCR asynchronously.
---@param callback fun(text: string|nil)
function M.extractOcr(callback)
  if not M.capture then
    callback(nil)
    return
  end

  if M.capture.ocrText then
    callback(M.capture.ocrText)
    return
  end

  local captureId = M.capture.id
  local imagePath = M.capture.imagePath
  if not imagePath or not hs.fs.attributes(imagePath) then
    HUD.alert("Still processing...", { iconType = "info" })
    callback(nil)
    return
  end

  cancelTask("ocr")
  M.capture.ocrStatus = "processing"
  M.updatePanelStatus()

  local task
  task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, _stdErr)
    if M.activeTasks.ocr ~= task then return end
    M.activeTasks.ocr = nil
    if not isCurrentCapture(captureId) then return end

    local text = stdOut and stdOut:gsub("^%s*(.-)%s*$", "%1") or ""
    if exitCode == 0 and #text > 0 then
      M.capture.ocrText = text
      M.capture.ocrStatus = "complete"
      M.updatePanelStatus()
      callback(text)
    else
      M.extractOcrTesseract(imagePath, captureId, callback)
    end
  end, { "vision-ocr", imagePath })

  if not task then
    M.extractOcrTesseract(imagePath, captureId, callback)
    return
  end

  M.activeTasks.ocr = task
  if not task:start() then
    M.activeTasks.ocr = nil
    M.extractOcrTesseract(imagePath, captureId, callback)
  end
end

---Fallback OCR via tesseract. Using stdout avoids shared temporary paths.
---@param imagePath string
---@param captureId number
---@param callback fun(text: string|nil)
function M.extractOcrTesseract(imagePath, captureId, callback)
  if not isCurrentCapture(captureId) then return end

  local task
  task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if M.activeTasks.ocr ~= task then return end
    M.activeTasks.ocr = nil
    if not isCurrentCapture(captureId) then return end

    local text = stdOut and stdOut:gsub("^%s*(.-)%s*$", "%1") or ""
    if exitCode == 0 and #text > 0 then
      M.capture.ocrText = text
      M.capture.ocrStatus = "complete"
      M.updatePanelStatus()
      callback(text)
      return
    end

    M.capture.ocrStatus = "failed"
    M.updatePanelStatus()
    U.log.e(fmt("tesseract failed: %s", stdErr))
    callback(nil)
  end, { "tesseract", imagePath, "stdout", "--psm", "6" })

  if not task then
    M.capture.ocrStatus = "failed"
    M.updatePanelStatus()
    callback(nil)
    return
  end

  M.activeTasks.ocr = task
  if not task:start() then
    M.activeTasks.ocr = nil
    M.capture.ocrStatus = "failed"
    M.updatePanelStatus()
    callback(nil)
  end
end

--------------------------------------------------------------------------------
-- PASTE ACTIONS
--------------------------------------------------------------------------------

---Paste original image binary (native behavior)
---@return boolean success
function M.pasteImage()
  if not M.capture then
    U.log.w("no capture available")
    return false
  end

  local written = false
  if M.capture.imageData and M.capture.imageUTI then
    written = hs.pasteboard.writeDataForUTI(M.capture.imageUTI, M.capture.imageData)
  elseif M.capture.image then
    written = hs.pasteboard.writeObjects({ M.capture.image })
  end

  if not written then
    U.log.w("no image data available")
    return false
  end

  -- Suppress only this exact generation. Later external writes must still run.
  pasteboard.ignoreChangeCount(hs.pasteboard.changeCount())
  hs.eventtap.keyStroke({ "cmd" }, "v")
  U.log.n("pasted image")
  return true
end

---Paste URL
---@return boolean success
function M.pasteUrl()
  if not M.capture or not M.capture.imageUrl then
    U.log.w("URL not available (still uploading?)")
    HUD.alert("Still uploading...", { iconType = "warning" })
    return false
  end

  hs.eventtap.keyStrokes(M.capture.imageUrl)
  U.log.n(fmt("pasted URL %s", M.capture.imageUrl))
  return true
end

---Paste markdown image tag
---@return boolean success
function M.pasteMarkdown()
  if not M.capture or not M.capture.imageUrl then
    HUD.alert("Still uploading...", { iconType = "warning" })
    return false
  end

  local md = fmt("![screenshot](%s)", M.capture.imageUrl)
  hs.eventtap.keyStrokes(md)
  U.log.n(fmt("pasted markdown"))
  return true
end

---Paste HTML img tag
---@return boolean success
function M.pasteHtml()
  if not M.capture or not M.capture.imageUrl then
    HUD.alert("Still uploading...", { iconType = "warning" })
    return false
  end

  local html = fmt([[<img src="%s" width="450" />]], M.capture.imageUrl)
  hs.eventtap.keyStrokes(html)
  U.log.n("pasted HTML")
  return true
end

---OCR and copy to clipboard (don't paste immediately)
---Stays in modal until user presses Cmd+V or Escape
---@return boolean success
function M.ocrToClipboard()
  local captureId = M.capture and M.capture.id
  M.extractOcr(function(text)
    if not captureId or not isCurrentCapture(captureId) then return end

    if text and #text > 0 then
      hs.pasteboard.setContents(text)
      U.log.n(fmt("OCR copied %d chars", #text))

      if M.isModalActive then
        M.stopOcrPasteWatcher()

        -- Watch for Cmd+V to leave modal mode while allowing the paste through.
        M.ocrPasteWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
          local mods = event:getFlags()
          local key = hs.keycodes.map[event:getKeyCode()]
          if mods.cmd and not mods.shift and not mods.alt and not mods.ctrl and key == "v" then
            M.stopOcrPasteWatcher()
            M.exitModal()
          end
          return false
        end)
        M.ocrPasteWatcher:start()
      end
    else
      HUD.alert("No text found", { iconType = "warning" })
      if isCurrentCapture(captureId) then
        M.capture.ocrStatus = "idle"
        M.updatePanelStatus()
      end
    end
  end)
  return true
end

---Open image in Preview
---@return boolean success
function M.editInPreview()
  if not M.capture or not M.capture.imagePath then
    return false
  end

  -- Check if file exists (async save might not be complete)
  if not hs.fs.attributes(M.capture.imagePath) then
    HUD.alert("Still processing...", { iconType = "info" })
    return false
  end

  cancelTask("open")
  local task
  task = hs.task.new("/usr/bin/open", function()
    if M.activeTasks.open == task then M.activeTasks.open = nil end
  end, { "-a", "Preview", M.capture.imagePath })
  if not task then return false end

  M.activeTasks.open = task
  if not task:start() then
    M.activeTasks.open = nil
    return false
  end

  U.log.n("opened in Preview")
  return true
end

--------------------------------------------------------------------------------
-- FULL SCREEN CAPTURE (WITH AUTO-RESIZE)
--------------------------------------------------------------------------------

local PASTE_PNG_JXA = [[
ObjC.import("AppKit")
ObjC.import("Foundation")
function run(argv) {
  const path = $(argv[0])
  if (!$.NSFileManager.defaultManager.fileExistsAtPath(path)) {
    throw new Error("unable to read PNG")
  }
  const data = $.NSData.dataWithContentsOfFile(path)
  const pasteboard = $.NSPasteboard.generalPasteboard
  pasteboard.clearContents
  if (!pasteboard.setDataForType(data, $("public.png"))) {
    throw new Error("unable to write PNG to pasteboard")
  }
  return "ok"
}
]]

local function removeFiles(paths)
  for _, path in ipairs(paths) do
    os.remove(path)
  end
end

local function publishFullScreenCapture(imagePath, sizeBytes, cleanupPaths)
  local task
  task = hs.task.new("/usr/bin/osascript", function(exitCode, _stdOut, stdErr)
    removeFiles(cleanupPaths)
    if M.activeTasks.screenshot ~= task then return end
    M.activeTasks.screenshot = nil

    if exitCode ~= 0 then
      HUD.alert("Screenshot failed", { iconType = "error" })
      U.log.e(fmt("pasteboard write failed: %s", stdErr))
      return
    end

    -- This write is intentionally not suppressed: the pasteboard watcher owns
    -- creating the normal capture state, preview HUD, save, and upload tasks.
    U.log.i(fmt("full screen capture %s", formatSize(sizeBytes)))
  end, { "-l", "JavaScript", "-e", PASTE_PNG_JXA, "--", imagePath })

  if not task then
    M.activeTasks.screenshot = nil
    removeFiles(cleanupPaths)
    HUD.alert("Screenshot failed", { iconType = "error" })
    return
  end

  M.activeTasks.screenshot = task
  if not task:start() then
    M.activeTasks.screenshot = nil
    removeFiles(cleanupPaths)
    HUD.alert("Screenshot failed", { iconType = "error" })
  end
end

---Capture the main screen in a subprocess so the hotkey callback never blocks.
function M.captureFullScreen()
  cancelTask("screenshot")

  local taskId = hs.host.uuid()
  local capturePath = fmt("/tmp/clipper_fullscreen_%s.png", taskId)
  local resizedPath = fmt("/tmp/clipper_fullscreen_%s_resized.png", taskId)
  local captureTask
  captureTask = hs.task.new("/usr/sbin/screencapture", function(exitCode, _stdOut, stdErr)
    if M.activeTasks.screenshot ~= captureTask then
      removeFiles({ capturePath, resizedPath })
      return
    end

    local sizeBytes = getFileSizeBytes(capturePath)
    if exitCode ~= 0 or not sizeBytes then
      M.activeTasks.screenshot = nil
      removeFiles({ capturePath, resizedPath })
      HUD.alert("Screenshot failed", { iconType = "error" })
      U.log.e(fmt("screencapture failed: %s", stdErr))
      return
    end

    if sizeBytes <= M.config.maxImageSizeBytes then
      publishFullScreenCapture(capturePath, sizeBytes, { capturePath })
      return
    end

    U.log.i(fmt("full screen capture %s exceeds limit, resizing...", formatSize(sizeBytes)))
    local resizeTask
    resizeTask = hs.task.new("/usr/bin/env", function(resizeExitCode, _stdOut, resizeErr)
      if M.activeTasks.screenshot ~= resizeTask then
        removeFiles({ capturePath, resizedPath })
        return
      end

      local resizedSize = getFileSizeBytes(resizedPath)
      if resizeExitCode ~= 0 or not resizedSize then
        M.activeTasks.screenshot = nil
        removeFiles({ capturePath, resizedPath })
        HUD.alert("Resize failed", { iconType = "error" })
        U.log.e(fmt("magick resize failed: %s", resizeErr))
        return
      end

      publishFullScreenCapture(resizedPath, resizedSize, { capturePath, resizedPath })
    end, { "magick", capturePath, "-resize", "25%", resizedPath })

    if not resizeTask then
      M.activeTasks.screenshot = nil
      removeFiles({ capturePath, resizedPath })
      HUD.alert("Resize failed", { iconType = "error" })
      return
    end

    M.activeTasks.screenshot = resizeTask
    if not resizeTask:start() then
      M.activeTasks.screenshot = nil
      removeFiles({ capturePath, resizedPath })
      HUD.alert("Resize failed", { iconType = "error" })
    end
  end, { "-x", "-m", "-t", "png", capturePath })

  if not captureTask then
    removeFiles({ capturePath, resizedPath })
    HUD.alert("Screenshot failed", { iconType = "error" })
    return
  end

  M.activeTasks.screenshot = captureTask
  if not captureTask:start() then
    M.activeTasks.screenshot = nil
    removeFiles({ capturePath, resizedPath })
    HUD.alert("Screenshot failed", { iconType = "error" })
  end
end

--------------------------------------------------------------------------------
-- NOTE CAPTURE (SHADE INTEGRATION)
--------------------------------------------------------------------------------

---Quick capture to notes (fire-and-forget)
---@return boolean success
function M.captureQuick()
  if not M.capture or not M.capture.imagePath then
    HUD.alert("No screenshot available", { iconType = "warning" })
    return false
  end

  -- Check if file exists (async save might not be complete)
  if not hs.fs.attributes(M.capture.imagePath) then
    HUD.alert("Still processing...", { iconType = "info" })
    return false
  end

  local ctx = {
    tempImagePath = M.capture.imagePath,
    appType = "screenshot",
    appName = "Screenshot",
  }

  if not shade.writeContext(ctx) then
    HUD.alert("Capture failed", { iconType = "error" })
    return false
  end

  local function trigger()
    hs.distributednotifications.post("io.shade.note.capture.image", nil, nil)
    HUD.alert("Quick capture saved", { iconType = "checkmark" })
    U.log.i("quick capture sent to Shade")
  end

  if shade.isRunning() then
    trigger()
  else
    shade.launch()
    schedule("shadeCapture", 1.5, trigger)
  end

  return true
end

---Full capture with editor panel
---@return boolean success
function M.captureFull()
  if not M.capture or not M.capture.imagePath then
    HUD.alert("No screenshot available", { iconType = "warning" })
    return false
  end

  -- Check if file exists (async save might not be complete)
  if not hs.fs.attributes(M.capture.imagePath) then
    HUD.alert("Still processing...", { iconType = "info" })
    return false
  end

  local ctx = {
    tempImagePath = M.capture.imagePath,
    appType = "screenshot",
    appName = "Screenshot",
  }

  if not shade.writeContext(ctx) then
    HUD.alert("Capture failed", { iconType = "error" })
    return false
  end

  local function trigger()
    hs.distributednotifications.post("io.shade.note.capture.image", nil, nil)
    schedule("shadeShow", 0.1, function() shade.show() end)
    U.log.i("full capture sent to Shade")
  end

  if shade.isRunning() then
    trigger()
  else
    shade.launch()
    schedule("shadeCapture", 1.5, trigger)
  end

  return true
end

--------------------------------------------------------------------------------
-- MODAL
--------------------------------------------------------------------------------

---Enter modal mode
function M.enterModal()
  if not M.hasCapture() then
    HUD.alert("No recent screenshot", { iconType = "info" })
    return
  end

  M.showPanel()
  if M.isModalActive then return end

  M.modal:enter()
  M.isModalActive = true
  M.startClickOutsideWatcher()
  M.startAppWatcher()
  U.log.d("entered modal")
end

---Stop OCR paste watcher if running
function M.stopOcrPasteWatcher()
  if M.ocrPasteWatcher then
    M.ocrPasteWatcher:stop()
    M.ocrPasteWatcher = nil
  end
end

---Exit modal mode
function M.exitModal()
  local wasActive = M.isModalActive
  M.isModalActive = false
  M.stopOcrPasteWatcher()
  M.stopClickOutsideWatcher()
  M.stopAppWatcher()
  if M.modal then M.modal:exit() end
  if wasActive then U.log.d("exited modal") end
end

---Execute action and exit modal
---@param action function
function M.modalAction(action)
  action()
  M.exitModal()
end

--------------------------------------------------------------------------------
-- CAPTURE HANDLER
--------------------------------------------------------------------------------

---Handle a new image from the pasteboard watcher.
---@param image hs.image
---@param metadata PasteboardMetadata
function M.handleCapture(image, metadata)
  if not image then return end

  M.exitModal()
  cancelCaptureTasks()
  M.nextCaptureId = M.nextCaptureId + 1

  local captureId = M.nextCaptureId
  local sourceId = metadata and metadata.changeCount or captureId
  local date = os.date("%Y-%m-%dT%H-%M-%S")
  local zone = os.date("%z")
  local imageName = fmt("cap_%s-%d%s.png", date, sourceId, zone)
  local imagePath = fmt("%s/%s", M.config.capsPath, imageName)
  local imageData = metadata and metadata.imageData or nil
  local imageUTI = metadata and metadata.imageUTI or nil

  M.capture = {
    id = captureId,
    changeCount = metadata and metadata.changeCount or nil,
    image = image,
    imageData = imageData,
    imageUTI = imageUTI,
    imagePath = imagePath,
    imageName = imageName,
    imageUrl = nil,
    ocrText = nil,
    timestamp = os.time(),
    uploadStatus = "verifying",
    ocrStatus = "idle",
    gatekeeperReason = nil,
    originalImagePath = nil,
    fileSizeBytes = nil,
  }

  -- This is the complete synchronous capture boundary: state assignment and
  -- one passive HUD render. Rasterization and disk I/O happen in magick.
  M.showPanel()
  U.log.i(fmt("captured %s (processing async)", imageName))

  if not imageData then
    M.capture.uploadStatus = "failed"
    M.capture.gatekeeperReason = "image bytes unavailable"
    M.updatePanelStatus()
    U.log.e("pasteboard image had no supported raw representation")
    return
  end

  local task
  task = hs.task.new("/usr/bin/env", function(exitCode, _stdOut, stdErr)
    if M.activeTasks.save ~= task then
      os.remove(imagePath)
      return
    end
    M.activeTasks.save = nil
    if not isCurrentCapture(captureId) then
      os.remove(imagePath)
      return
    end

    if exitCode ~= 0 then
      M.capture.uploadStatus = "failed"
      M.capture.gatekeeperReason = "failed to save file"
      M.updatePanelStatus()
      U.log.e(fmt("failed to save %s: %s", imagePath, stdErr))
      return
    end

    M.capture.fileSizeBytes = getFileSizeBytes(imagePath)
    M.verifyAndUpload(imagePath, captureId)
  end, { "magick", "-", imagePath })

  if not task then
    M.capture.uploadStatus = "failed"
    M.capture.gatekeeperReason = "save task failed to start"
    M.updatePanelStatus()
    return
  end

  M.activeTasks.save = task
  task:setInput(imageData)
  if not task:start() then
    M.activeTasks.save = nil
    M.capture.uploadStatus = "failed"
    M.capture.gatekeeperReason = "save task failed to start"
    M.updatePanelStatus()
  end
end

--------------------------------------------------------------------------------
-- PASTEBOARD HOOK
--------------------------------------------------------------------------------

---Register pasteboard hook for images
function M.registerHook()
  pasteboard.addHook("image", function(image, metadata)
    M.handleCapture(image, metadata)
  end, { id = "clipper", priority = 10 })
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

-- Action lookup table
M.actions = {
  pasteImage = function() M.modalAction(M.pasteImage) end,
  pasteUrl = function() M.modalAction(M.pasteUrl) end,
  pasteMarkdown = function() M.modalAction(M.pasteMarkdown) end,
  pasteHtml = function() M.modalAction(M.pasteHtml) end,
  ocrToClipboard = function() M.ocrToClipboard() end, -- Don't exit modal (async)
  editInPreview = function() M.modalAction(M.editInPreview) end,
  captureQuick = function() M.modalAction(M.captureQuick) end,
  captureFull = function() M.modalAction(M.captureFull) end,
  exit = function() M.dismissPanel() end,
}

---Initialize clipper module
---@return ClipperModule self
function M:init()
  -- Create modal
  M.modal = hs.hotkey.modal.new()

  -- Bind from config
  for _, binding in ipairs(M.config.bindings) do
    local action = M.actions[binding.action]
    if action then
      M.modal:bind(binding.mods or {}, binding.key, action)
    else
      U.log.w(fmt("unknown action '%s'", binding.action))
    end
  end

  -- Entry binding: HYPER+⇧V
  M.hyper = req("hyper", { id = "clipper" })
  local entry = M.config.entryBinding
  M.hyper:start():bind(entry.mods or {}, entry.key, function() M.enterModal() end)

  -- Full screen capture with auto-resize: cmd+shift+5
  -- Captures full screen and auto-resizes if > 5MB (gatekeeper limit)
  M.fullScreenHotkey = hs.hotkey.bind({ "cmd", "shift" }, "5", function()
    M.captureFullScreen()
  end)

  -- Register pasteboard hook (watcher started via watchers system)
  M.registerHook()

  U.log.i("initialized")
  return self
end

---Cleanup and stop clipper
---@return ClipperModule self
function M:stop()
  -- Reset state
  M.isModalActive = false

  -- Stop watchers and deferred callbacks.
  M.stopOcrPasteWatcher()
  M.stopClickOutsideWatcher()
  M.stopAppWatcher()
  local timers = M.timers
  M.timers = {}
  for _, timer in pairs(timers) do
    timer:stop()
  end

  -- Relinquish every task slot before terminating. Termination callbacks may
  -- run immediately and must see that they no longer own module state.
  local activeTasks = M.activeTasks
  M.activeTasks = {}
  for name, task in pairs(activeTasks) do
    if task and task:isRunning() then
      task:terminate()
      U.log.d(fmt("terminated task: %s", name))
    end
  end

  -- Exit and clean up modal
  if M.modal then
    M.modal:exit()
    M.modal:delete()
    M.modal = nil
  end

  -- Stop and clean up hyper binding
  if M.hyper then
    M.hyper:stop()
    M.hyper = nil
  end

  -- Clean up full screen hotkey
  if M.fullScreenHotkey then
    M.fullScreenHotkey:delete()
    M.fullScreenHotkey = nil
  end

  -- Dismiss panel
  M.hidePanel()

  -- Remove our hook (watcher stopped via watchers system)
  pasteboard.removeHook("clipper")

  -- Clear capture state
  M.capture = nil

  U.log.i("stopped")
  return self
end

return M
