local obj = {}
local Settings = require("hs.settings")

obj.__index = obj
obj.name = "clipper"
obj.debug = false
obj.clipWatcher = {}
obj.clipboardData = {}
obj.capsPath = fmt("%s/screenshots", os.getenv("HOME"))
obj.tempImage = "/tmp/tmp.png"
obj.tempOcrImage = "/tmp/ocr_tmp.png"

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

function obj.captureImage(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[capper] no image on clipboard")
    return
  end

  -- clear previous image url
  hs.pasteboard.clearContents("imageUrl")

  local date = hs.execute("zsh -ci 'echo $EPOCHSECONDS'")
  local cap_name = fmt("cap_%s.png", date:gsub("\n", ""))
  local cap = fmt("%s/%s", obj.capsPath, cap_name)

  if image:saveToFile(cap) then
    local std_out, success, type, rc =
      hs.execute(fmt("%s -ci '%s/.dotfiles/bin/capper %s'", os.getenv("SHELL"), os.getenv("HOME"), cap))

    local std_out_lines = {}
    for s in std_out:gmatch("[^\r\n]+") do
      table.insert(std_out_lines, s)
    end
    local url = std_out_lines[#std_out_lines]

    dbg("capper:\r\n%s\r\n%s\r\n%s\r\n%s", url, success, type, rc)

    if success then
      hs.pasteboard.setContents(cap_name, "imageName")
      hs.pasteboard.setContents(url, "imageUrl")
      hs.pasteboard.setContents(image, "image")
      if open_image_url then hs.urlevent.openURLWithBundle(url, hs.urlevent.getDefaultHandler("https")) end
    else
      error(fmt("failed to upload image to spaces (%s/%s/%s)..", url, type, rc))
    end
  else
    error(fmt("file %s doesn't exist for uploading to capper.", cap))
  end
end

function obj.sendToImgur(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[send_to_imgur] no image on clipboard")
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
        error(fmt("status: %s, body: %s, headers: %s", status, body, I(headers)))
      end
    end)
  end
end

function obj.saveOcrText(image)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[paste_ocr_text] no image on clipboard")
    return
  end

  local imagePath = obj.tempOcrImage
  local outputPath = "/tmp/ocr_output"
  image:saveToFile(imagePath)

  local output, success, type, rc =
    hs.execute(fmt("zsh -ic '/opt/homebrew/bin/tesseract -l eng %s %s'", imagePath, outputPath))

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
    error(fmt("ocrText [failed]: %s/%s/%s/%s", output, success, type, rc))
  end
end

--  REF: https://github.com/danielo515/dotfiles/blob/master/chezmoi/dot_hammerspoon/keybinds.lua#L44-L61
function obj.edit_clipboard_image(image)
  -- Check if an image is in the clipboard
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[clipper] no image on clipboard")
    return
  end

  -- Save the image to a temporary file
  local tmpfile = os.tmpname() .. ".png"
  image:saveToFile(tmpfile)

  -- Open the image in Preview and start annotation
  hs.execute("open -a Preview " .. tmpfile)

  hs.timer.doAfter(1, function() hs.application.find("Preview"):selectMenuItem({ "Tools", "Annotate", "Arrow" }) end)
  note(fmt("[clipper] editClipboardImage: %s", obj.clipboardData))
end

function obj:init(opts)
  opts = opts or {}
  obj.clipWatcher = hs.pasteboard.watcher.new(function(pb)
    local browser = hs.application.get(BROWSER)

    if pb ~= nil and pb ~= "" then
      obj.clipboardData = pb
    else
      obj.clipboardData = hs.pasteboard.readImage()
      obj.captureImage(obj.clipboardData, false)

      local pasteImageUrl = function()
        local imageUrl = hs.pasteboard.getContents("imageUrl")
        hs.eventtap.keyStrokes(imageUrl)
        note(fmt("[clipper] imageUrl: %s", imageUrl))
      end

      local pasteOcrText = function()
        obj.saveOcrText(obj.clipboardData)
        local ocrText = hs.pasteboard.getContents("ocrText")
        hs.eventtap.keyStrokes(ocrText)
        note(fmt("[clipper] ocrText: %s", ocrText))
      end

      hs.hotkey.bind({ "cmd", "shift" }, "v", pasteImageUrl)
      hs.hotkey.bind({ "cmd", "ctrl" }, "v", pasteImageUrl)
      hs.hotkey.bind({ "cmd", "shift" }, "p", pasteOcrText)
      hs.hotkey.bind({ "cmd", "shift", "ctrl" }, "p", pasteOcrText)
      hs.hotkey.bind({ "cmd", "shift" }, "e", function()
        obj.edit_clipboard_image(obj.clipboardData)
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
          note(fmt("[clipper] mdImgTag: %s", mdImgTag))
        end)
      end
    end
  end)

  obj.clipWatcher:start()

  info(fmt("[INIT] bindings.%s", self.name))

  return self
end

return obj
