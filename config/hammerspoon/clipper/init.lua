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

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@class ClipperCapture
---@field image hs.image Original captured image
---@field imageData string|nil Raw PNG data for pasting (nil until async load completes)
---@field imagePath string Local file path
---@field imageName string Filename
---@field imageUrl string|nil DO Spaces URL (set after upload)
---@field ocrText string|nil OCR extracted text (lazy loaded)
---@field timestamp number When capture occurred
---@field uploadStatus "idle"|"verifying"|"uploading"|"complete"|"failed"|"gatekeeper" Upload state
---@field ocrStatus "idle"|"processing"|"complete"|"failed" OCR state
---@field gatekeeperReason string|nil Gatekeeper violation reason
---@field fileSizeBytes number|nil Image file size in bytes

---@class ClipperModule
---@field capture ClipperCapture|nil Current capture state
---@field panel HUDPanel|nil Active HUD panel
---@field modal hs.hotkey.modal|nil Modal for single-key actions
---@field hyper table|nil Hyper key binding
---@field config ClipperConfig Configuration
---@field activeTasks table<string, hs.task> Running tasks for cleanup

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
M.isModalActive = false
M.ocrPasteWatcher = nil
M.clickOutsideWatcher = nil
M.appWatcher = nil  -- Track app focus changes to exit modal
M.fullScreenHotkey = nil

-- Configuration
M.config = {
  captureTimeout = 300, -- 5 minutes
  capsPath = os.getenv("HOME") .. "/_screenshots",

  -- Gatekeeper: max image size for Claude API (5MB limit for base64 images)
  maxImageSizeBytes = 5 * 1024 * 1024, -- 5MB
  maxImageSizeMB = 5,

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
        -- Click was outside panel - dismiss
        M.exitModal()
        return true  -- Consume the click
      end
      
      return false  -- Let click through to panel
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

---Show the clipper HUD panel and enter modal mode
function M.showPanel()
  if not M.hasCapture() then return end

  -- Dismiss existing panel if any
  if M.panel then
    M.panel:dismiss()
    M.panel = nil
  end

  -- Create panel (always modal - stays until dismissed)
  M.panel = HUD.panel({
    id = "clipper",
    position = "bottom-center",
    ephemeral = false,
  })

  -- Set media (image)
  if M.capture.image then
    M.panel:setMedia(M.capture.image, {
      minWidth = 320,
      maxWidth = 320,
      maxHeight = 180,
      onClick = function()
        if M.capture and M.capture.imagePath then
          hs.execute(fmt("open '%s'", M.capture.imagePath))
        end
      end,
    })
  end

  -- Set status and cheatsheet
  M.updatePanelStatus()
  M.updatePanelCheatsheet()

  M.panel:show()

  -- Enter modal mode
  M.modal:enter()
  M.isModalActive = true
  
  -- Start watching for clicks outside panel and app focus changes
  M.startClickOutsideWatcher()
  M.startAppWatcher()
end

---Generate and update cheatsheet based on current state
function M.updatePanelCheatsheet()
  if not M.panel then return end

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

  M.panel:setContent(cheatsheet)
end

---Update panel status without recreating
---Shows combined upload + OCR status
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
    local reason = capture.gatekeeperReason or "image too large"
    return "⚠ gatekeeper: " .. reason, "FF9500" -- Orange/amber
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

  M.panel:setStatus(statusText, { color = primaryColor })

  -- Set OCR preview if available
  if M.capture.ocrStatus == "complete" and M.capture.ocrText then
    M.panel:setPreview(M.capture.ocrText, { maxLines = 5 })
  else
    M.panel:setPreview(nil) -- Clear preview
  end

  -- Regenerate cheatsheet (URL bindings may now be available)
  M.updatePanelCheatsheet()
end

---Hide the clipper panel
function M.hidePanel()
  if M.panel then
    M.panel:dismiss()
    M.panel = nil
  end
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
local function formatSize(bytes)
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
    local reason = fmt("%s > %dMB limit", formatSize(sizeBytes), M.config.maxImageSizeMB)
    return false, reason
  end

  return true, nil
end

--------------------------------------------------------------------------------
-- UPLOAD (ASYNC)
--------------------------------------------------------------------------------

---Run gatekeeper verification and upload if passed
---Called from async context after file is saved
---@param imagePath string
function M.verifyAndUpload(imagePath)
  -- Verify this is still the same capture
  if not M.capture or M.capture.imagePath ~= imagePath then return end

  -- Gatekeeper check: verify file size before upload
  local passes, reason = M.checkGatekeeper(imagePath)
  if not passes then
    M.capture.uploadStatus = "gatekeeper"
    M.capture.gatekeeperReason = reason
    M.updatePanelStatus()
    U.log.w(fmt("gatekeeper blocked upload: %s", reason))
    return
  end

  -- Gatekeeper passed - start upload
  M.capture.uploadStatus = "uploading"
  M.updatePanelStatus()

  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    M.activeTasks.upload = nil
    -- Verify this is still the same capture
    if not M.capture or M.capture.imagePath ~= imagePath then return end

    if exitCode == 0 then
      local url = stdOut:match("([^\r\n]+)%s*$")
      M.capture.imageUrl = url
      M.capture.uploadStatus = "complete"
      U.log.i(fmt("uploaded %s", url))
    else
      M.capture.uploadStatus = "failed"
      U.log.e(fmt("upload failed: %s", stdErr))
    end

    M.updatePanelStatus()
  end, { "capper", imagePath })

  M.activeTasks.upload = task
  task:start()
end

--------------------------------------------------------------------------------
-- OCR (ASYNC)
--------------------------------------------------------------------------------

---Extract text via OCR asynchronously
---@param callback fun(text: string|nil)
function M.extractOcr(callback)
  if not M.capture then
    callback(nil)
    return
  end

  -- Return cached result
  if M.capture.ocrText then
    callback(M.capture.ocrText)
    return
  end

  local imagePath = M.capture.imagePath
  if not imagePath or not hs.fs.attributes(imagePath) then
    HUD.alert("Still processing...", { iconType = "info" })
    callback(nil)
    return
  end

  -- Update status
  M.capture.ocrStatus = "processing"
  M.updatePanelStatus()

  -- Try Vision OCR first
  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    M.activeTasks.ocr = nil
    -- Verify this is still the same capture
    if not M.capture or M.capture.imagePath ~= imagePath then
      callback(nil)
      return
    end

    if exitCode == 0 and stdOut and #stdOut > 0 then
      M.capture.ocrText = stdOut:gsub("^%s*(.-)%s*$", "%1") -- Trim
      M.capture.ocrStatus = "complete"
      M.updatePanelStatus()
      callback(M.capture.ocrText)
    else
      -- Fallback to tesseract
      M.extractOcrTesseract(imagePath, callback)
    end
  end, { "vision-ocr", imagePath })

  M.activeTasks.ocr = task
  task:start()
end

---Fallback OCR via tesseract
---@param imagePath string
---@param callback fun(text: string|nil)
function M.extractOcrTesseract(imagePath, callback)
  local outputPath = "/tmp/clipper_ocr"

  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    M.activeTasks.ocr = nil
    -- Verify this is still the same capture
    if not M.capture or M.capture.imagePath ~= imagePath then
      callback(nil)
      return
    end

    if exitCode == 0 then
      local file = io.open(outputPath .. ".txt", "r")
      if file then
        local content = file:read("*all")
        file:close()
        os.remove(outputPath .. ".txt")

        M.capture.ocrText = content:gsub("^%s*(.-)%s*$", "%1")
        M.capture.ocrStatus = "complete"
        M.updatePanelStatus()
        callback(M.capture.ocrText)
        return
      end
    end

    M.capture.ocrStatus = "failed"
    M.updatePanelStatus()
    U.log.e(fmt("tesseract failed: %s", stdErr))
    callback(nil)
  end, { "tesseract", imagePath, outputPath, "--psm", "6" })

  M.activeTasks.ocr = task
  task:start()
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

  -- If imageData not ready yet (async still processing), use the image object directly
  if M.capture.imageData then
    hs.pasteboard.clearContents()
    hs.pasteboard.writeDataForUTI("public.png", M.capture.imageData)
  elseif M.capture.image then
    hs.pasteboard.clearContents()
    hs.pasteboard.writeObjects({ M.capture.image })
  else
    U.log.w("no image data available")
    return false
  end

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
  M.extractOcr(function(text)
    if text and #text > 0 then
      hs.pasteboard.setContents(text)
      -- Update panel to show result (guard against cleared capture)
      if M.capture then
        M.capture.ocrStatus = "complete"
        M.capture.ocrText = text
        M.updatePanelStatus()
      end
      U.log.n(fmt("OCR copied %d chars", #text))

      -- Stop any existing watcher before creating new one
      M.stopOcrPasteWatcher()

      -- Watch for Cmd+V to exit modal and allow paste
      M.ocrPasteWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
        local mods = event:getFlags()
        local key = hs.keycodes.map[event:getKeyCode()]
        if mods.cmd and not mods.shift and not mods.alt and not mods.ctrl and key == "v" then
          -- Stop watcher and exit modal
          M.stopOcrPasteWatcher()
          M.exitModal()
          -- Return false to let the paste through
          return false
        end
        return false
      end)
      M.ocrPasteWatcher:start()
    else
      HUD.alert("No text found", { iconType = "warning" })
      if M.capture then
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

  hs.execute(fmt("open -a Preview '%s'", M.capture.imagePath))
  U.log.n("opened in Preview")
  return true
end

--------------------------------------------------------------------------------
-- FULL SCREEN CAPTURE (WITH AUTO-RESIZE)
--------------------------------------------------------------------------------

---Capture full screen and resize if needed to stay under gatekeeper limit
---Uses ImageMagick for resize if image exceeds limit
function M.captureFullScreen()
  local screen = hs.screen.mainScreen()
  local image = screen:snapshot()

  if not image then
    HUD.alert("Screenshot failed", { iconType = "error" })
    U.log.e("failed to capture screen")
    return
  end

  -- Generate temp path to check size
  local tmpPath = "/tmp/clipper_fullscreen.png"
  image:saveToFile(tmpPath)

  -- Check size
  local sizeBytes = getFileSizeBytes(tmpPath)
  local needsResize = sizeBytes and sizeBytes > M.config.maxImageSizeBytes

  if needsResize then
    U.log.i(fmt("full screen capture %s exceeds limit, resizing...", formatSize(sizeBytes)))

    -- Resize using ImageMagick (25% like file-size-guard recommends)
    local resizedPath = "/tmp/clipper_fullscreen_resized.png"
    local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
      M.activeTasks.resize = nil  -- Clear task reference
      if exitCode == 0 then
        -- Load resized image
        local resizedImage = hs.image.imageFromPath(resizedPath)
        if resizedImage then
          -- Put on clipboard and trigger normal flow
          hs.pasteboard.clearContents()
          hs.pasteboard.writeObjects({ resizedImage })
          -- handleCapture will be called by pasteboard watcher
          U.log.i(fmt("resized full screen capture from %s", formatSize(sizeBytes)))
        else
          HUD.alert("Resize failed", { iconType = "error" })
          U.log.e("failed to load resized image")
        end

        -- Cleanup temp files
        os.remove(tmpPath)
        os.remove(resizedPath)
      else
        HUD.alert("Resize failed", { iconType = "error" })
        U.log.e(fmt("magick resize failed: %s", stdErr))
        os.remove(tmpPath)
      end
    end, { "magick", tmpPath, "-resize", "25%", resizedPath })

    M.activeTasks.resize = task
    task:start()
  else
    -- Image is small enough, put on clipboard directly
    hs.pasteboard.clearContents()
    hs.pasteboard.writeObjects({ image })
    -- handleCapture will be called by pasteboard watcher
    U.log.i(fmt("full screen capture %s (no resize needed)", formatSize(sizeBytes or 0)))
    os.remove(tmpPath)
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
    shade.launch(function()
      hs.timer.doAfter(0.5, trigger)
    end)
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
    hs.timer.doAfter(0.1, function() shade.show() end)
    U.log.i("full capture sent to Shade")
  end

  if shade.isRunning() then
    trigger()
  else
    shade.launch(function()
      hs.timer.doAfter(0.5, trigger)
    end)
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
  M.isModalActive = false
  M.stopOcrPasteWatcher()
  M.stopClickOutsideWatcher()
  M.stopAppWatcher()
  if M.modal then M.modal:exit() end
  M.hidePanel()
  U.log.d("exited modal")
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

---Handle new image on pasteboard
---@param image hs.image
function M.handleCapture(image)
  if not image then return end

  -- Generate filename
  local date = os.date("%Y-%m-%dT%H-%M-%S%z")
  local imageName = fmt("cap_%s.png", date)
  local imagePath = fmt("%s/%s", M.config.capsPath, imageName)

  -- Set initial capture state immediately (with image for HUD preview)
  -- File operations happen async below
  M.capture = {
    image = image,
    imageData = nil, -- Set async
    imagePath = imagePath,
    imageName = imageName,
    imageUrl = nil,
    ocrText = nil,
    timestamp = os.time(),
    uploadStatus = "verifying",
    ocrStatus = "idle",
    gatekeeperReason = nil,
    fileSizeBytes = nil, -- Set async
  }

  -- Show panel IMMEDIATELY with image preview and "Gatekeeper verifying..." status
  M.showPanel()
  U.log.i(fmt("captured %s (processing async)", imageName))

  -- All file I/O happens async - doesn't block anything
  hs.timer.doAfter(0, function()
    -- Verify this is still the same capture (another screenshot may have arrived)
    if not M.capture or M.capture.imagePath ~= imagePath then return end

    -- Save raw PNG data for later pasting
    local imageData = image:encodeAsURLString()
    if imageData then
      imageData = imageData:match("base64,(.+)$")
      if imageData then
        imageData = hs.base64.decode(imageData)
      end
    end

    -- Fallback: read from UTI if encodeAsURLString failed
    if not imageData then
      local tmpPath = "/tmp/clipper_capture.png"
      image:saveToFile(tmpPath)
      local f = io.open(tmpPath, "rb")
      if f then
        imageData = f:read("*all")
        f:close()
      end
      os.remove(tmpPath)
    end

    -- Save to permanent location
    local saved = image:saveToFile(imagePath)
    if not saved then
      U.log.e(fmt("failed to save %s", imagePath))
      -- Verify still same capture before updating state
      if M.capture and M.capture.imagePath == imagePath then
        M.capture.uploadStatus = "failed"
        M.capture.gatekeeperReason = "failed to save file"
        M.updatePanelStatus()
      end
      return
    end

    -- Verify still same capture before updating state
    if not M.capture or M.capture.imagePath ~= imagePath then return end

    M.capture.imageData = imageData
    M.capture.fileSizeBytes = getFileSizeBytes(imagePath)

    -- Start gatekeeper verification and upload
    M.verifyAndUpload(imagePath)
  end)
end

--------------------------------------------------------------------------------
-- PASTEBOARD HOOK
--------------------------------------------------------------------------------

local pasteboard = require("watchers.pasteboard")

---Register pasteboard hook for images
function M.registerHook()
  pasteboard.addHook("image", function(image)
    M.handleCapture(image)
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
  exit = function() M.exitModal() end,
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

  -- Stop watchers
  M.stopOcrPasteWatcher()
  M.stopClickOutsideWatcher()
  M.stopAppWatcher()

  -- Terminate any running tasks
  for name, task in pairs(M.activeTasks) do
    if task and task:isRunning() then
      task:terminate()
      U.log.d(fmt("terminated task: %s", name))
    end
  end
  M.activeTasks = {}

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
