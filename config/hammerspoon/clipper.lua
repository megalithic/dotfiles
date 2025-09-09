local obj = {}
-- TODO/IDEAS:
-- https://github.com/kiooss/dotmagic/blob/master/hammerspoon/clippy.lua

obj.__index = obj
obj.name = "clipper"
obj.debug = false
obj.clipWatcher = {}
obj.clipboardData = {}
obj.capsPath = fmt("%s/screenshots", os.getenv("HOME"))
obj.tempImage = fmt("%s/tmp/%s_tmp.png", os.getenv("HOME"), obj.name)
obj.tempOcrImage = fmt("%s/tmp/%s_ocr_tmp.png", os.getenv("HOME"), obj.name)
obj.helpCanvas = nil

function obj.captureImage(image, openImageUrl)
  image = image or hs.pasteboard.readImage()

  if not image then
    -- warn(fmt("[%s] captureImage: no image on clipboard", obj.name))

    return
  end

  -- clear previous image url
  hs.pasteboard.clearContents("imageUrl")

  local date = hs.execute("zsh -ci 'echo $EPOCHSECONDS'")
  local imageName = fmt("cap_%s.png", date:gsub("\n", ""))
  local capturedImage = fmt("%s/%s", obj.capsPath, imageName)

  if image:saveToFile(capturedImage) then
    local std_out, success, type, rc =
      hs.execute(fmt("%s -ci '%s/.dotfiles/bin/capper %s'", os.getenv("SHELL"), os.getenv("HOME"), capturedImage))

    local std_out_lines = {}
    for s in std_out:gmatch("[^\r\n]+") do
      table.insert(std_out_lines, s)
    end
    local url = std_out_lines[#std_out_lines]

    dbg(fmt("capper:\r\n%s\r\n%s\r\n%s\r\n%s", url, success, type, rc))

    if success then
      hs.pasteboard.setContents(imageName, "imageName")
      hs.pasteboard.setContents(url, "imageUrl")
      hs.pasteboard.setContents(image, "image")
      if openImageUrl then
        hs.urlevent.openURLWithBundle(
          url,
          hs.urlevent.getDefaultHandler("https") or hs.urlevent.getDefaultHandler("http")
        )
      end
    else
      error(fmt("[%s] captureImage: failed to upload image to spaces (%s/%s/%s)", obj.name, url, type, rc))
    end
  else
    error(fmt("[%s] captureImage: file %s doesn't existing for uploading", obj.name, capturedImage))
  end
end

function obj.sendToImgur(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn(fmt("[%s] sendToImgur: no image on clipboard", obj.name))
    return
  end

  -- clear previous image url
  hs.pasteboard.clearContents("imageUrl")

  image:saveToFile(obj.tempImage)
  local b64 = hs.execute("base64 -i " .. obj.tempImage)

  local client_id, success, type, rc = hs.execute("zsh -ci 'echo $IMGUR_CLIENT_ID'")
  dbg("client_id: %s/%s/%s/%s", client_id:gsub("\n", ""), success, type, rc)

  if b64 ~= nil then
    b64 = hs.http.encodeForQuery(string.gsub(b64, "\n", ""))

    local req_url = "https://api.imgur.com/3/upload.json"
    local req_headers = { Authorization = fmt("Client-ID %s", client_id:gsub("\n", "")) }
    local req_payload = "type='base64'&image=" .. b64

    dbg("request: %s/%s", req_url, I(req_headers))

    hs.http.asyncPost(req_url, req_payload, req_headers, function(status, body, headers)
      if status == 200 then
        local response = hs.json.decode(body)
        local imageUrl = response.data.link
        hs.pasteboard.setContents(imageUrl, "imageUrl")
        hs.pasteboard.setContents(image, "image")

        if open_image_url then hs.urlevent.openURLWithBundle(imageUrl, hs.urlevent.getDefaultHandler("https")) end
        hs.execute("rm " .. obj.tempImage)
      else
        error(fmt("[%s] sendToImgur: %s/%s/%s/%s", obj.name, status, body, I(headers)))
      end
    end)
  end
end

function obj.saveOcrText(image)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn(fmt("[%s] saveOcrText: no image on clipboard", obj.name))
    return
  end

  local imagePath = obj.tempOcrImage
  dbg(I(image), true)
  local outputPath = "/tmp/ocr_output.txt"
  dbg(I(imagePath), true)
  dbg(I(outputPath), true)

  if image:saveToFile(imagePath) then
    dbg(I(image), true)

    local output, success, type, rc =
      hs.execute(fmt("/opt/homebrew/bin/zsh -ic '/opt/homebrew/bin/tesseract %s %s'", imagePath, outputPath))

    if success then
      -- Read in OCR result
      local file = io.open(fmt("%s.txt", outputPath), "r")
      local content = file:read("*all")
      dbg("ocrText: %s", content)
      file:close()

      -- Store OCR content in the pasteboard
      hs.pasteboard.setContents(content, "ocrText")

      -- clean up
      hs.execute(fmt("rm %s %s.txt", imagePath, outputPath))
    else
      error(fmt("[%s] saveOcrText: %s/%s/%s/%s", obj.name, output, success, type, rc))
    end
  else
    warn(fmt("[%s] saveOcrText: unable to save image to path (%s)", obj.name, imagePath))
  end
end

--  REF: https://github.com/danielo515/dotfiles/blob/master/chezmoi/dot_hammerspoon/keybinds.lua#L44-L61
function obj.editClipboardImage(image)
  -- Check if an image is in the clipboard
  image = image or hs.pasteboard.readImage()

  if not image then
    warn(fmt("[%s] editClipboardImage: no image on clipboard", obj.name))
    return
  end

  -- Save the image to a temporary file
  local tmpfile = os.tmpname() .. ".png"
  if image ~= nil and tmpfile ~= nil then
    image:saveToFile(tmpfile)

    -- Open the image in Preview and start annotation
    hs.execute("open -a Preview " .. tmpfile)

    -- hs.timer.doAfter(1, function() hs.application.find("Preview"):selectMenuItem({ "Tools", "Annotate", "Arrow" }) end)
    note(fmt("[%s] editClipboardImage: %s", obj.name, obj.clipboardData))
  end
end

function obj:init(opts)
  opts = opts or {}

  obj.clipWatcher = hs.pasteboard.watcher.new(function(pb)
    local browser = hs.application.get(BROWSER)

    -- dbg(pb, true)

    if pb ~= nil and pb ~= "" then
      obj.clipboardData = pb
    else
      obj.clipboardData = hs.pasteboard.readImage()
      obj.captureImage(obj.clipboardData, false)

      local pasteImageUrl = function()
        local imageUrl = hs.pasteboard.getContents("imageUrl")
        hs.eventtap.keyStrokes(imageUrl)
        note(fmt("[%s] imageUrl: %s", obj.name, imageUrl))
      end

      local pasteOcrText = function()
        dbg(I(obj), true)
        dbg(obj.clipboardData, true)
        obj.saveOcrText(obj.clipboardData)
        local ocrText = hs.pasteboard.getContents("ocrText")
        if ocrText == nil or ocrText == "" then
          warn(fmt("[%s] ocrText: no ocr text to paste", obj.name))
        else
          hs.eventtap.keyStrokes(ocrText)
          note(fmt("[%s] ocrText: %s", obj.name, ocrText))
        end
      end

      hs.hotkey.bind({ "cmd", "shift" }, "v", pasteImageUrl)
      hs.hotkey.bind({ "cmd", "ctrl" }, "v", pasteImageUrl)

      -----------------------------------------------------
      -- FIXME: these are presently broken; not sure why...
      hs.hotkey.bind({ "cmd", "shift" }, "p", pasteOcrText)
      hs.hotkey.bind({ "cmd", "shift", "ctrl" }, "p", pasteOcrText)
      -----------------------------------------------------

      hs.hotkey.bind({ "cmd", "shift" }, "e", function()
        obj.editClipboardImage(obj.clipboardData)
        -- local ocr_text = hs.pasteboard.getContents("ocrText")
        -- hs.eventtap.keyStrokes(ocr_text)
        -- dbg("ocrText: %s", ocr_text)
      end)

      if browser and browser == hs.application.frontmostApplication() then
        hs.hotkey.bind({ "ctrl", "shift" }, "v", function()
          local imageUrl = hs.pasteboard.getContents("imageUrl")
          -- local imageName = hs.pasteboard.getContents("imageName")

          local mdImgTag = fmt([[<img src="%s" width="450" />]], imageUrl)
          hs.eventtap.keyStrokes(mdImgTag)
          note(fmt("[%s] mdImgTag: %s", obj.name, mdImgTag))
        end)
      end
    end
  end)

  obj.clipWatcher:start()

  info(fmt("[INIT] bindings.%s", self.name))

  return self
end

return obj
