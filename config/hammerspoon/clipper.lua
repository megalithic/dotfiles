local fmt = string.format
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
obj.modalTimeout = nil -- Timer for 1s auto-paste
obj.isModalActive = false

-- Cheatsheet canvas reference
obj.cheatsheet = nil
obj.cheatsheetTimer = nil
obj.escapeHotkey = nil -- Enabled only when cheatsheet is visible

-- Configuration
obj.config = {
  captureTimeout = 60, -- Seconds before capture becomes inactive
  cheatsheetDuration = 10, -- Auto-dismiss passive cheatsheet after N seconds
  modalTimeout = 5, -- Seconds before modal auto-pastes URL
  -- Responsive cheatsheet sizing (external display = larger)
  cheatsheetWidth = {
    external = 480,
    internal = 320,
  },
  thumbnailScaleFactor = 4, -- Divide source image by this for retina (5K = 2x, so 4 = crisp)
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
    }
  else
    keybindings = {
      { key = "HYPER+⇧V", desc = "Enter paste mode" },
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
  local y = screenFrame.y + screenFrame.h - height - 40

  local canvas = hs.canvas.new({ x = x, y = y, w = width, h = height })

  -- Background
  canvas:appendElements({
    type = "rectangle",
    action = "fill",
    fillColor = colors.background,
    roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    frame = { x = 0, y = 0, w = width, h = height },
  })

  -- Border
  local borderColor = isModalMode
      and { red = 0.3, green = 0.7, blue = 0.4, alpha = 0.9 }
    or colors.border
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
    canvas:appendElements({
      type = "text",
      text = "Auto-pasting URL in 5s...",
      textColor = { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.7 },
      textSize = smallTextSize,
      textFont = ".AppleSystemUIFont",
      frame = { x = margin, y = yPos, w = thumbWidth, h = footerHeight },
      textAlignment = "center",
    })
  end

  canvas:level("overlay")
  canvas:show()

  obj.cheatsheet = canvas

  -- Enable escape hotkey to dismiss
  if obj.escapeHotkey then
    obj.escapeHotkey:enable()
  end

  -- Auto-dismiss timer (only for passive mode)
  if not isModalMode then
    obj.cheatsheetTimer = hs.timer.doAfter(obj.config.cheatsheetDuration, function()
      if not obj.isModalActive then
        obj.hideCheatsheet()
      end
    end)
  end
end

function obj.hideCheatsheet()
  if obj.cheatsheet then
    obj.cheatsheet:delete(0.2) -- Quick fade out
    obj.cheatsheet = nil
  end
  if obj.cheatsheetTimer then
    obj.cheatsheetTimer:stop()
    obj.cheatsheetTimer = nil
  end
  -- Disable escape hotkey when cheatsheet is hidden
  if obj.escapeHotkey then
    obj.escapeHotkey:disable()
  end
end

function obj.updateCheatsheetStatus(status)
  obj.activeCapture.uploadStatus = status

  -- Refresh cheatsheet if visible
  if obj.cheatsheet then
    obj.showCheatsheet(obj.isModalActive)
  end
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Upload to DigitalOcean Spaces
-- ══════════════════════════════════════════════════════════════════════════════

function obj.uploadToSpaces(imagePath, imageName)
  local capperBin = fmt("%s/.dotfiles/bin/capper", os.getenv("HOME"))

  obj.updateCheatsheetStatus("uploading")

  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
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

      U.log.i(fmt("[%s] uploaded: %s", obj.name, url))
    else
      obj.updateCheatsheetStatus("failed")
      U.log.e(fmt("[%s] upload failed: exit=%s stderr=%s", obj.name, exitCode, stdErr))
    end
  end, { "-c", fmt("%s %s", capperBin, imagePath) })

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
    U.log.w(fmt("[%s] OCR: no image path available", obj.name))
    callback(nil)
    return
  end

  local imagePath = obj.activeCapture.imagePath
  local visionOcrBin = fmt("%s/.dotfiles/bin/vision-ocr", os.getenv("HOME"))

  -- Try Vision first
  local task = hs.task.new(visionOcrBin, function(exitCode, stdOut, stdErr)
    if exitCode == 0 and stdOut and #stdOut > 0 then
      obj.activeCapture.ocrText = stdOut:gsub("^%s*(.-)%s*$", "%1") -- Trim
      callback(obj.activeCapture.ocrText)
    else
      -- Fallback to tesseract
      U.log.d(fmt("[%s] Vision OCR failed, trying tesseract", obj.name))
      obj.extractOcrWithTesseract(imagePath, callback)
    end
  end, { imagePath })

  task:start()
end

function obj.extractOcrWithTesseract(imagePath, callback)
  local outputPath = "/tmp/clipper_ocr"

  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
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
      U.log.e(fmt("[%s] tesseract failed: %s", obj.name, stdErr))
      callback(nil)
    end
  end, { "-c", fmt("tesseract '%s' '%s' --psm 6", imagePath, outputPath) })

  task:start()
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Paste Actions
-- ══════════════════════════════════════════════════════════════════════════════

function obj.pasteRawUrl()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("[%s] URL not yet available (still uploading?)", obj.name))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  hs.eventtap.keyStrokes(obj.activeCapture.imageUrl)
  U.log.n(fmt("[%s] pasted URL: %s", obj.name, obj.activeCapture.imageUrl))
  return true
end

function obj.pasteMarkdown()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("[%s] URL not yet available (still uploading?)", obj.name))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  local md = fmt("![screenshot](%s)", obj.activeCapture.imageUrl)
  hs.eventtap.keyStrokes(md)
  U.log.n(fmt("[%s] pasted markdown: %s", obj.name, md))
  return true
end

function obj.pasteHtmlTag()
  if not obj.activeCapture.imageUrl then
    U.log.w(fmt("[%s] URL not yet available (still uploading?)", obj.name))
    hs.alert.show("Still uploading...", 1)
    return false
  end

  local html = fmt([[<img src="%s" width="450" />]], obj.activeCapture.imageUrl)
  hs.eventtap.keyStrokes(html)
  U.log.n(fmt("[%s] pasted HTML: %s", obj.name, html))
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
            U.log.d(fmt("[%s] restored image data to clipboard", obj.name))
          elseif obj.activeCapture.image then
            -- Fallback: restore from hs.image object
            hs.pasteboard.writeObjects({ obj.activeCapture.image })
            U.log.d(fmt("[%s] restored image object to clipboard (fallback)", obj.name))
          end
        end)
      end)

      U.log.n(fmt("[%s] pasted OCR text (clipboard): %d chars", obj.name, #text))
    else
      U.log.w(fmt("[%s] no text found in image", obj.name))
      hs.alert.show("No text found", 2)
    end
  end)
  return true
end

function obj.editInPreview()
  if obj.activeCapture.imagePath then
    hs.execute(fmt("open -a Preview '%s'", obj.activeCapture.imagePath))
    U.log.n(fmt("[%s] opened in Preview: %s", obj.name, obj.activeCapture.imagePath))
  elseif obj.activeCapture.image then
    -- Save to temp file and open
    local tmpfile = os.tmpname() .. ".png"
    obj.activeCapture.image:saveToFile(tmpfile)
    hs.execute(fmt("open -a Preview '%s'", tmpfile))
    U.log.n(fmt("[%s] opened temp file in Preview", obj.name))
  end
  return true
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Modal Mode
-- ══════════════════════════════════════════════════════════════════════════════

function obj.enterModal()
  if not obj.hasActiveCapture() then
    U.log.w(fmt("[%s] no active capture for modal", obj.name))
    hs.alert.show("No recent screenshot", 1)
    return
  end

  obj.isModalActive = true

  -- Show modal cheatsheet
  obj.showCheatsheet(true)

  -- Enter the modal hotkey mode
  obj.modal:enter()

  -- Start 1s timeout for auto-paste URL
  obj.modalTimeout = hs.timer.doAfter(obj.config.modalTimeout, function()
    if obj.isModalActive then
      obj.pasteRawUrl()
      obj.exitModal()
    end
  end)

  U.log.d(fmt("[%s] entered modal mode", obj.name))
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

  U.log.d(fmt("[%s] exited modal mode", obj.name))
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
    U.log.e(fmt("[%s] failed to save image to %s", obj.name, imagePath))
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

  U.log.i(fmt("[%s] captured: %s", obj.name, imageName))
end

-- ══════════════════════════════════════════════════════════════════════════════
-- Setup Bindings
-- ══════════════════════════════════════════════════════════════════════════════

function obj.setupBindings()
  -- Create modal for single-key paste actions
  obj.modal = hs.hotkey.modal.new()

  -- Modal bindings (active only when modal is entered)
  obj.modal:bind({}, "v", function()
    obj.modalAction(obj.pasteRawUrl)
  end)

  obj.modal:bind({}, "m", function()
    obj.modalAction(obj.pasteMarkdown)
  end)

  obj.modal:bind({}, "h", function()
    obj.modalAction(obj.pasteHtmlTag)
  end)

  obj.modal:bind({}, "p", function()
    obj.modalAction(obj.pasteOcrTextViaClipboard)
  end)

  obj.modal:bind({}, "e", function()
    obj.modalAction(obj.editInPreview)
  end)

  obj.modal:bind({}, "escape", function()
    obj.exitModal()
  end)

  -- Entry binding: HYPER+⇧V
  local hyper = req("hyper", { id = "clipper" })
  hyper:start():bind({ "shift" }, "v", function()
    obj.enterModal()
  end)

  -- Escape to dismiss cheatsheet (only active when cheatsheet is visible)
  obj.escapeHotkey = hs.hotkey.new({}, "escape", function()
    if obj.isModalActive then
      obj.exitModal()
    elseif obj.cheatsheet then
      obj.hideCheatsheet()
    end
  end)
  -- Starts disabled, enabled when cheatsheet shows

  U.log.d(fmt("[%s] bindings set up", obj.name))
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
      if image then
        obj.handleNewCapture(image)
      end
    end
  end)

  obj.clipWatcher:start()

  U.log.i(fmt("[%s] initialized", obj.name))

  return self
end

return obj
