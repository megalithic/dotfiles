local fmt = string.format
local canvasLib = require("lib.canvas")
local notesLib = require("lib.notes")
local shade = require("lib.interop.shade")
local obj = {}

--[[
  Clipper: Screenshot capture, upload, and OCR module

  Features:
  - Watches pasteboard for new screenshots
  - Async upload to DigitalOcean Spaces
  - Vision-based OCR (with tesseract fallback)
  - Modal paste mode with single-key actions
  - Responsive cheatsheet (480w external, 320w internal display)
  - Retina-optimized thumbnail (source scaled ÷4)

  Usage:
  1. Take screenshot with ⌘⌃⇧4 (standard macOS)
  2. Cheatsheet appears showing capture + upload status
  3. Press HYPER+⇧V to enter paste modal
  4. Press single key: v=URL, m=markdown, h=HTML, p=OCR, e=edit
  5. Or wait 1s to auto-paste URL
  6. Can re-invoke modal for additional actions
]]

obj.__index = obj
obj.name = "clipper"
obj.debug = false

-- File paths
obj.capsPath = fmt("%s/_screenshots", os.getenv("HOME"))
obj.tempImage = fmt("%s/tmp/%s_tmp.png", os.getenv("HOME"), obj.name)
obj.tempOcrImage = fmt("%s/tmp/%s_ocr_tmp.png", os.getenv("HOME"), obj.name)

-- Watcher reference
obj.clipWatcher = nil

-- State for active capture (avoids memory leak from dynamic bindings)
obj.activeCapture = {
  image = nil, -- hs.image object
  imagePath = nil, -- Local file path
  imageName = nil, -- Filename
  imageUrl = nil, -- DO Spaces URL (set after upload completes)
  ocrText = nil, -- OCR extracted text (lazy loaded)
  timestamp = 0, -- When capture occurred (for 60s timeout)
  uploadStatus = "idle", -- "idle" | "uploading" | "complete" | "failed"
}

-- Modal state
obj.modal = nil -- hs.hotkey.modal instance
obj.modalTimeout = nil -- Timer for auto-paste
obj.isModalActive = false
obj.currentModalTimeout = nil -- Current timeout value (for display)

-- Cheatsheet canvas reference
obj.cheatsheet = nil
obj.cheatsheetTimer = nil
obj.cheatsheetAnimTimer = nil -- Animation timer
obj.escapeHotkey = nil -- Enabled only when cheatsheet is visible

-- Configuration
obj.config = {
  captureTimeout = 300, -- Seconds before capture becomes inactive (5 minutes)
  cheatsheetDuration = 10, -- Auto-dismiss passive cheatsheet after N seconds
  modalTimeoutQuick = 3, -- Seconds before quick modal (⌘⇧V) auto-pastes URL
  modalTimeoutSlow = 10, -- Seconds before slow modal (HYPER+⇧V) auto-pastes URL
  -- Responsive cheatsheet sizing (external display = larger)
  cheatsheetWidth = {
    external = 480,
    internal = 320,
  },
  thumbnailScaleFactor = 4, -- Divide source image by this for retina (5K = 2x, so 4 = crisp)
  -- Animation settings
  animation = {
    enabled = true,
    duration = 0.25, -- Slide-up duration in seconds
    slideDistance = 40, -- Pixels to slide up from starting position
  },
}

-- ══════════════════════════════════════════════════════════════════════════════
-- State Management
-- ══════════════════════════════════════════════════════════════════════════════

function obj.hasActiveCapture()
  if not obj.activeCapture.image then return false end

  local elapsed = os.time() - obj.activeCapture.timestamp
  return elapsed < obj.config.captureTimeout
end

function obj.clearCapture()
  obj.activeCapture = {
    image = nil,
    imagePath = nil,
    imageName = nil,
    imageUrl = nil,
    ocrText = nil,
    timestamp = 0,
    uploadStatus = "idle",
  }
end

function obj.setCapture(image, imagePath, imageName)
  obj.activeCapture = {
    image = image,
    imagePath = imagePath,
    imageName = imageName,
    imageUrl = nil, -- Set after upload completes
    ocrText = nil, -- Lazy loaded on demand
    timestamp = os.time(),
    uploadStatus = "uploading",
  }
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Color Scheme (follows system dark/light mode)
-- ══════════════════════════════════════════════════════════════════════════════

function obj.getColors()
  local appearance = hs.host.interfaceStyle()
  if appearance == "Dark" then
    return {
      background = { red = 0.12, green = 0.12, blue = 0.13, alpha = 0.95 },
      border = { red = 0.30, green = 0.30, blue = 0.31, alpha = 0.85 },
      title = { red = 0.92, green = 0.92, blue = 0.92, alpha = 1.0 },
      subtitle = { red = 0.70, green = 0.70, blue = 0.70, alpha = 1.0 },
      keybind = { red = 0.5, green = 0.7, blue = 1.0, alpha = 1.0 }, -- Blue accent
      keybindActive = { red = 0.3, green = 0.9, blue = 0.5, alpha = 1.0 }, -- Green when modal active
      success = { red = 0.4, green = 0.8, blue = 0.4, alpha = 1.0 }, -- Green
      uploading = { red = 1.0, green = 0.7, blue = 0.2, alpha = 1.0 }, -- Orange
      error = { red = 1.0, green = 0.4, blue = 0.4, alpha = 1.0 }, -- Red
      modalHighlight = { red = 0.2, green = 0.25, blue = 0.3, alpha = 1.0 }, -- Subtle highlight
    }
  else
    return {
      background = { red = 0.98, green = 0.98, blue = 0.98, alpha = 0.95 },
      border = { red = 0.85, green = 0.85, blue = 0.85, alpha = 0.6 },
      title = { red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0 },
      subtitle = { red = 0.4, green = 0.4, blue = 0.4, alpha = 1.0 },
      keybind = { red = 0.2, green = 0.4, blue = 0.8, alpha = 1.0 },
      keybindActive = { red = 0.1, green = 0.6, blue = 0.3, alpha = 1.0 },
      success = { red = 0.2, green = 0.6, blue = 0.2, alpha = 1.0 },
      uploading = { red = 0.8, green = 0.5, blue = 0.0, alpha = 1.0 },
      error = { red = 0.8, green = 0.2, blue = 0.2, alpha = 1.0 },
      modalHighlight = { red = 0.92, green = 0.94, blue = 0.96, alpha = 1.0 },
    }
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Cheatsheet Canvas
-- ══════════════════════════════════════════════════════════════════════════════

function obj.showCheatsheet(isModalMode)
  -- Dismiss any existing cheatsheet first
  obj.hideCheatsheet()

  local colors = obj.getColors()
  local screen = hs.screen.mainScreen()
  local screenFrame = screen:frame()
  local screenName = screen:name()

  -- Load display config from global config
  local config = req("config")
  local isExternalDisplay = screenName == config.displays.external

  -- Portrait layout: thumbnail on top, status, then shortcuts
  local width = isExternalDisplay and 320 or 240
  local margin = math.floor(width * 0.05) -- 5% margin
  local cornerRadius = math.floor(width * 0.04)

  -- Thumbnail dimensions (wide rectangle, not square)
  local thumbWidth = width - (margin * 2)
  local thumbHeight = math.floor(thumbWidth * 0.6) -- 16:10ish aspect

  -- Text sizes
  local textSize = isExternalDisplay and 13 or 11
  local smallTextSize = isExternalDisplay and 11 or 9

  -- Calculate heights for each section
  local thumbSectionHeight = thumbHeight + margin
  local statusHeight = 24
  local keyRowHeight = isExternalDisplay and 22 or 18

  -- Keybindings
  local keybindings
  if isModalMode then
    keybindings = {
      { key = "v", desc = "Paste URL (default)" },
      { key = "m", desc = "Markdown" },
      { key = "h", desc = "HTML tag" },
      { key = "p", desc = "OCR text" },
      { key = "e", desc = "Edit in Preview" },
      { key = "n", desc = "Quick capture" },
      { key = "N", desc = "Full capture" },
    }
  else
    keybindings = {
      { key = "⌘⇧V", desc = "Quick paste (3s)" },
      { key = "HYPER+⇧V", desc = "Slow paste (10s)" },
      { key = "⌘V", desc = "Paste image directly" },
      { key = "Esc", desc = "Dismiss" },
    }
  end

  local keysHeight = #keybindings * keyRowHeight

  -- Footer (only in modal mode)
  local footerHeight = isModalMode and 20 or 0

  -- Total height
  local height = margin + thumbSectionHeight + statusHeight + keysHeight + footerHeight + margin

  -- Position: bottom-center of screen
  local x = screenFrame.x + (screenFrame.w - width) / 2
  local finalY = screenFrame.y + screenFrame.h - height - 40

  -- Animation setup: start below final position
  local animConfig = obj.config.animation or {}
  local animEnabled = animConfig.enabled ~= false
  local slideDistance = animConfig.slideDistance or 40
  local startY = animEnabled and (finalY + slideDistance) or finalY

  local canvas = hs.canvas.new({ x = x, y = startY, w = width, h = height })

  -- Background
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = colors.background,
    roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    frame = { x = 0, y = 0, w = width, h = height },
  })

  -- Border
  local borderColor = isModalMode and { red = 0.3, green = 0.7, blue = 0.4, alpha = 0.9 } or colors.border
  canvas:appendElements({
    type = "rectangle",
    action = "stroke",
    strokeColor = borderColor,
    strokeWidth = isModalMode and 2 or 1.5,
    roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    frame = { x = 0, y = 0, w = width, h = height },
  })

  -- Track vertical position
  local yPos = margin

  -- Thumbnail at top
  if obj.activeCapture.image then
    local sourceImage = obj.activeCapture.image
    local sourceSize = sourceImage:size()
    local scaleFactor = obj.config.thumbnailScaleFactor
    local scaledWidth = math.floor(sourceSize.w / scaleFactor)
    local scaledHeight = math.floor(sourceSize.h / scaleFactor)
    local scaledImage = sourceImage:copy():size({ w = scaledWidth, h = scaledHeight }, true)

    canvas:appendElements({
      type = "image",
      image = scaledImage,
      frame = { x = margin, y = yPos, w = thumbWidth, h = thumbHeight },
      imageScaling = "scaleProportionally",
      imageAlignment = "center",
    })
  else
    -- Placeholder rectangle when no image
    canvas:appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = { red = 0.2, green = 0.2, blue = 0.2, alpha = 0.3 },
      roundedRectRadii = { xRadius = 6, yRadius = 6 },
      frame = { x = margin, y = yPos, w = thumbWidth, h = thumbHeight },
    })
  end
  yPos = yPos + thumbSectionHeight

  -- Upload status
  local statusText, statusColor
  if obj.activeCapture.uploadStatus == "uploading" then
    statusText = "⏳ Uploading..."
    statusColor = colors.uploading
  elseif obj.activeCapture.uploadStatus == "complete" then
    statusText = "✓ Uploaded"
    statusColor = colors.success
  elseif obj.activeCapture.uploadStatus == "failed" then
    statusText = "✗ Upload failed"
    statusColor = colors.error
  else
    statusText = "Ready"
    statusColor = colors.subtitle
  end

  canvas:appendElements({
    type = "text",
    text = statusText,
    textColor = statusColor,
    textSize = textSize,
    textFont = ".AppleSystemUIFont",
    frame = { x = margin, y = yPos, w = thumbWidth, h = statusHeight },
    textAlignment = "center",
  })
  yPos = yPos + statusHeight

  -- Keybindings
  local keyColWidth = isModalMode and 24 or (isExternalDisplay and 85 or 70)
  local keyColor = isModalMode and colors.keybindActive or colors.keybind

  for i, kb in ipairs(keybindings) do
    -- Key
    canvas:appendElements({
      type = "text",
      text = kb.key,
      textColor = keyColor,
      textSize = smallTextSize,
      textFont = "Menlo",
      frame = { x = margin, y = yPos, w = keyColWidth, h = keyRowHeight },
    })
    -- Description
    canvas:appendElements({
      type = "text",
      text = kb.desc,
      textColor = colors.subtitle,
      textSize = smallTextSize,
      textFont = ".AppleSystemUIFont",
      frame = { x = margin + keyColWidth + 8, y = yPos, w = thumbWidth - keyColWidth - 8, h = keyRowHeight },
    })
    yPos = yPos + keyRowHeight
  end

  -- Footer hint (modal only)
  if isModalMode then
    local timeout = obj.currentModalTimeout or obj.config.modalTimeoutSlow
    canvas:appendElements({
      type = "text",
      text = fmt("Auto-pasting URL in %ds...", timeout),
      textColor = { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.7 },
      textSize = smallTextSize,
      textFont = ".AppleSystemUIFont",
      frame = { x = margin, y = yPos, w = thumbWidth, h = footerHeight },
      textAlignment = "center",
    })
  end

  canvas:level("overlay")

  -- Show with slide-up + fade-in animation
  if animEnabled then
    local animDuration = animConfig.duration or 0.25
    obj.cheatsheetAnimTimer = canvasLib.slideIn(canvas, startY, finalY, { duration = animDuration })
  else
    canvas:show()
  end

  obj.cheatsheet = canvas

  -- Enable escape hotkey to dismiss
  if obj.escapeHotkey then obj.escapeHotkey:enable() end

  -- Auto-dismiss timer (only for passive mode)
  if not isModalMode then
    obj.cheatsheetTimer = hs.timer.doAfter(obj.config.cheatsheetDuration, function()
      if not obj.isModalActive then obj.hideCheatsheet() end
    end)
  end
end

function obj.hideCheatsheet()
  -- Stop any running animation timer
  if obj.cheatsheetAnimTimer then
    obj.cheatsheetAnimTimer:stop()
    obj.cheatsheetAnimTimer = nil
  end

  -- Stop auto-dismiss timer
  if obj.cheatsheetTimer then
    obj.cheatsheetTimer:stop()
    obj.cheatsheetTimer = nil
  end

  -- Animate slide-down + fade-out, then cleanup
  if obj.cheatsheet then
    local canvas = obj.cheatsheet
    obj.cheatsheet = nil -- Clear reference immediately to prevent double-dismiss

    local animConfig = obj.config.animation or {}
    local animEnabled = animConfig.enabled ~= false

    if animEnabled then
      canvasLib.slideOut(canvas, {
        duration = 0.25,
        deleteAfter = true,
      })
    else
      canvas:delete(0.2)
    end
  end

  -- Disable escape hotkey when cheatsheet is hidden
  if obj.escapeHotkey then obj.escapeHotkey:disable() end
end

function obj.updateCheatsheetStatus(status)
  obj.activeCapture.uploadStatus = status

  -- Refresh cheatsheet if visible
  if obj.cheatsheet then obj.showCheatsheet(obj.isModalActive) end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Upload to DigitalOcean Spaces
-- ══════════════════════════════════════════════════════════════════════════════

function obj.uploadToSpaces(imagePath, imageName)
  -- Uses /usr/bin/env to leverage PATH injection from overrides.lua
  -- This finds capper via the Nix/Homebrew/dotfiles PATH
  obj.updateCheatsheetStatus("uploading")

  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      -- Extract URL from last line of output
      local lines = {}
      for line in stdOut:gmatch("[^\r\n]+") do
        table.insert(lines, line)
      end
      local url = lines[#lines]

      -- Update active capture state
      obj.activeCapture.imageUrl = url
      obj.updateCheatsheetStatus("complete")

      -- Also update named pasteboards for compatibility
      hs.pasteboard.setContents(imageName, "imageName")
      hs.pasteboard.setContents(url, "imageUrl")

      U.log.i(fmt("uploaded: %s", url))
    else
      obj.updateCheatsheetStatus("failed")
      U.log.e(fmt("upload failed: exit=%s stderr=%s", exitCode, stdErr))
    end
  end, { "capper", imagePath })

  task:start()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- OCR (Vision with tesseract fallback)
-- ══════════════════════════════════════════════════════════════════════════════

function obj.extractOcrText(callback)
  -- Return cached OCR if available
  if obj.activeCapture.ocrText then
    callback(obj.activeCapture.ocrText)
    return
  end

  if not obj.activeCapture.imagePath then
    U.log.w(fmt("OCR: no image path available"))
    callback(nil)
    return
  end

  local imagePath = obj.activeCapture.imagePath

  -- Uses /usr/bin/env to leverage PATH injection from overrides.lua
  -- Try Vision OCR first (finds vision-ocr via Nix/Homebrew/dotfiles PATH)
  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if exitCode == 0 and stdOut and #stdOut > 0 then
      obj.activeCapture.ocrText = stdOut:gsub("^%s*(.-)%s*$", "%1") -- Trim
      callback(obj.activeCapture.ocrText)
    else
      -- Fallback to tesseract
      U.log.d(fmt("Vision OCR failed, trying tesseract"))
      obj.extractOcrWithTesseract(imagePath, callback)
    end
  end, { "vision-ocr", imagePath })

  task:start()
end

function obj.extractOcrWithTesseract(imagePath, callback)
  local outputPath = "/tmp/clipper_ocr"

  -- Uses /usr/bin/env to leverage PATH injection from overrides.lua
  -- This finds tesseract via the Nix/Homebrew PATH
  local task = hs.task.new("/usr/bin/env", function(exitCode, stdOut, stdErr)
    if exitCode == 0 then
      local file = io.open(outputPath .. ".txt", "r")
      if file then
        local content = file:read("*all")
        file:close()
        obj.activeCapture.ocrText = content:gsub("^%s*(.-)%s*$", "%1") -- Trim

        -- Cleanup
        os.remove(outputPath .. ".txt")

        callback(obj.activeCapture.ocrText)
      else
        callback(nil)
      end
    else
      U.log.e(fmt("tesseract failed: %s", stdErr))
      callback(nil)
    end
  end, { "tesseract", imagePath, outputPath, "--psm", "6" })

  task:start()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Paste Actions
-- ══════════════════════════════════════════════════════════════════════════════

function obj.pasteRawUrl()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("URL not yet available (still uploading?)"))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  hs.eventtap.keyStrokes(obj.activeCapture.imageUrl)
  U.log.n(fmt("pasted URL: %s", obj.activeCapture.imageUrl))
  return true
end

function obj.pasteMarkdown()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("URL not yet available (still uploading?)"))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  local md = fmt("![screenshot](%s)", obj.activeCapture.imageUrl)
  hs.eventtap.keyStrokes(md)
  U.log.n(fmt("pasted markdown: %s", md))
  return true
end

function obj.pasteHtmlTag()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("URL not yet available (still uploading?)"))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  local html = fmt([[<img src="%s" width="450" />]], obj.activeCapture.imageUrl)
  hs.eventtap.keyStrokes(html)
  U.log.n(fmt("pasted HTML: %s", html))
  return true
end

-- Paste OCR text via clipboard (preserves formatting better)
-- Temporarily swaps clipboard, pastes, then restores the original image data
function obj.pasteOcrTextViaClipboard()
  -- Show loading indicator
  hs.alert.show("Extracting text...", 1)

  -- Save the raw image data from clipboard (not hs.image object)
  -- This preserves the exact format that apps like Claude expect
  local savedImageData = hs.pasteboard.readDataForUTI("public.png")
  if not savedImageData then
    -- Fallback: try TIFF format
    savedImageData = hs.pasteboard.readDataForUTI("public.tiff")
  end
  local savedUTI = savedImageData and "public.png" or nil

  obj.extractOcrText(function(text)
    if text and #text > 0 then
      -- Put OCR text on clipboard
      hs.pasteboard.setContents(text)

      -- Small delay to ensure clipboard is set, then paste
      hs.timer.doAfter(0.05, function()
        hs.eventtap.keyStroke({ "cmd" }, "v")

        -- Restore the original image data to clipboard after paste completes
        hs.timer.doAfter(0.15, function()
          if savedImageData and savedUTI then
            hs.pasteboard.clearContents()
            hs.pasteboard.writeDataForUTI(savedUTI, savedImageData)
            U.log.d(fmt("restored image data to clipboard"))
          elseif obj.activeCapture.image then
            -- Fallback: restore from hs.image object
            hs.pasteboard.writeObjects({ obj.activeCapture.image })
            U.log.d(fmt("restored image object to clipboard (fallback)"))
          end
        end)
      end)

      U.log.n(fmt("pasted OCR text (clipboard): %d chars", #text))
    else
      U.log.w(fmt("no text found in image"))
      hs.alert.show("No text found", 2)
    end
  end)
  return true
end

function obj.editInPreview()
  if obj.activeCapture.imagePath then
    hs.execute(fmt("open -a Preview '%s'", obj.activeCapture.imagePath))
    U.log.n(fmt("opened in Preview: %s", obj.activeCapture.imagePath))
  elseif obj.activeCapture.image then
    -- Save to temp file and open
    local tmpfile = os.tmpname() .. ".png"
    obj.activeCapture.image:saveToFile(tmpfile)
    hs.execute(fmt("open -a Preview '%s'", tmpfile))
    U.log.n(fmt("opened temp file in Preview"))
  end
  return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Note Capture Actions
-- ══════════════════════════════════════════════════════════════════════════════

--- Quick capture: screenshot to note, linked in daily (fire-and-forget)
function obj.captureQuick()
  if not obj.activeCapture.imagePath then
    U.log.w("captureQuick: no image path available")
    hs.alert.show("No screenshot available", 1)
    return false
  end

  local imagePath = obj.activeCapture.imagePath
  local imageUrl = obj.activeCapture.imageUrl

  -- Perform quick capture
  local success, err = notesLib.captureQuick(imagePath, imageUrl)

  if success then
    hs.alert.show("Quick capture saved", 1.5)
    U.log.i("captureQuick: completed")
    -- Clear active capture since files are moved/deleted
    obj.clearCapture()
  else
    hs.alert.show(fmt("Capture failed: %s", err or "unknown error"), 3)
    U.log.w(fmt("captureQuick: %s", err or "unknown error"))
  end

  return success
end

--- Full capture: screenshot to note with floating editor (interactive)
function obj.captureFull()
  if not obj.activeCapture.imagePath then
    U.log.w("captureFull: no image path available")
    hs.alert.show("No screenshot available", 1)
    return false
  end

  local imagePath = obj.activeCapture.imagePath
  local imageUrl = obj.activeCapture.imageUrl

  -- Create capture note (same as quick capture but opens editor)
  local success, captureFilename, err = notesLib.captureFull(imagePath, imageUrl)

  if success then
    local notePath = notesLib.getCaptureNotePath(captureFilename)
    U.log.i(fmt("captureFull: created %s", notePath))

    -- Open capture note in shade (Swift floating panel)
    shade.openFile(notePath, function(opened)
      if opened then
        -- Small delay to let nvim load the file
        hs.timer.doAfter(0.1, function() shade.show() end)
      else
        hs.alert.show("Failed to open capture note", 2)
      end
    end)

    -- Clear active capture since files are moved/deleted
    obj.clearCapture()
  else
    hs.alert.show(fmt("Capture failed: %s", err or "unknown error"), 3)
    U.log.w(fmt("captureFull: %s", err or "unknown error"))
  end

  return success
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Modal Mode
-- ══════════════════════════════════════════════════════════════════════════════

function obj.enterModal(timeout)
  if not obj.hasActiveCapture() then
    U.log.w(fmt("no active capture for modal"))
    hs.alert.show("No recent screenshot", 1)
    return
  end

  -- Use provided timeout or default to slow
  timeout = timeout or obj.config.modalTimeoutSlow
  obj.currentModalTimeout = timeout -- Store for cheatsheet display

  obj.isModalActive = true

  -- Show modal cheatsheet
  obj.showCheatsheet(true)

  -- Enter the modal hotkey mode
  obj.modal:enter()

  -- Start timeout for auto-paste URL
  obj.modalTimeout = hs.timer.doAfter(timeout, function()
    if obj.isModalActive then
      obj.pasteRawUrl()
      obj.exitModal()
    end
  end)

  U.log.d(fmt("entered modal mode (timeout=%ds)", timeout))
end

function obj.exitModal()
  obj.isModalActive = false

  -- Cancel timeout
  if obj.modalTimeout then
    obj.modalTimeout:stop()
    obj.modalTimeout = nil
  end

  -- Exit modal hotkey mode
  obj.modal:exit()

  -- Hide cheatsheet
  obj.hideCheatsheet()

  U.log.d(fmt("exited modal mode"))
end

function obj.modalAction(action)
  -- Cancel the auto-paste timeout
  if obj.modalTimeout then
    obj.modalTimeout:stop()
    obj.modalTimeout = nil
  end

  -- Perform the action
  local success = action()

  -- Exit modal
  obj.exitModal()

  return success
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Capture Handler (called by pasteboard watcher)
-- ══════════════════════════════════════════════════════════════════════════════

function obj.handleNewCapture(image)
  if not image then return end

  -- Generate filename
  local date = hs.execute([[date +"%Y-%m-%dT%H:%M:%S%z"]], true)
  local imageName = fmt("cap_%s.png", date:gsub("\n", ""))
  local imagePath = fmt("%s/%s", obj.capsPath, imageName)

  -- Save to disk
  local saved = image:saveToFile(imagePath)
  if not saved then
    U.log.e(fmt("failed to save image to %s", imagePath))
    return
  end

  -- Update state
  obj.setCapture(image, imagePath, imageName)

  -- Keep image on clipboard for immediate paste
  hs.pasteboard.setContents(image, "image")

  -- Start async upload
  obj.uploadToSpaces(imagePath, imageName)

  -- Show passive cheatsheet (not in modal mode)
  obj.showCheatsheet(false)

  U.log.i(fmt("captured: %s", imageName))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Setup Bindings
-- ══════════════════════════════════════════════════════════════════════════════

function obj.setupBindings()
  -- Create modal for single-key paste actions
  obj.modal = hs.hotkey.modal.new()

  -- Modal bindings (active only when modal is entered)
  obj.modal:bind({}, "v", function() obj.modalAction(obj.pasteRawUrl) end)

  obj.modal:bind({}, "m", function() obj.modalAction(obj.pasteMarkdown) end)

  obj.modal:bind({}, "h", function() obj.modalAction(obj.pasteHtmlTag) end)

  obj.modal:bind({}, "p", function() obj.modalAction(obj.pasteOcrTextViaClipboard) end)

  obj.modal:bind({}, "e", function() obj.modalAction(obj.editInPreview) end)

  -- Note capture bindings
  obj.modal:bind({}, "n", function() obj.modalAction(obj.captureQuick) end)
  obj.modal:bind({ "shift" }, "n", function() obj.modalAction(obj.captureFull) end)

  obj.modal:bind({}, "escape", function() obj.exitModal() end)

  -- Entry bindings for paste modal
  -- ⌘⇧V: Quick paste (3s timeout) - fast action
  hs.hotkey.bind({ "cmd", "shift" }, "v", function() obj.enterModal(obj.config.modalTimeoutQuick) end)

  -- HYPER+⇧V: Slow paste (10s timeout) - deliberate selection
  local hyper = req("hyper", { id = "clipper" })
  hyper:start():bind({ "shift" }, "v", function() obj.enterModal(obj.config.modalTimeoutSlow) end)

  -- Escape to dismiss cheatsheet (only active when cheatsheet is visible)
  obj.escapeHotkey = hs.hotkey.new({}, "escape", function()
    if obj.isModalActive then
      obj.exitModal()
    elseif obj.cheatsheet then
      obj.hideCheatsheet()
    end
  end)
  -- Starts disabled, enabled when cheatsheet shows

  U.log.d(fmt("bindings set up"))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Initialization
-- ══════════════════════════════════════════════════════════════════════════════

function obj:init(opts)
  opts = opts or {}

  -- Set up bindings and modal
  obj.setupBindings()

  -- Set up pasteboard watcher
  obj.clipWatcher = hs.pasteboard.watcher.new(function(pb)
    -- pb is nil when clipboard contains image (not text)
    if pb == nil or pb == "" then
      local image = hs.pasteboard.readImage()
      if image then obj.handleNewCapture(image) end
    end
  end)

  obj.clipWatcher:start()

  U.log.i(fmt("initialized"))

  return self
end

return obj
