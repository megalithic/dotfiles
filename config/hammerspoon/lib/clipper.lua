local obj = {}

obj.__index = obj
obj.name = "clipper"
obj.debug = false
obj.clip_watcher = {}
obj.clip_data = {}
obj.caps_dir = fmt("%s/screenshots", os.getenv("HOME"))
obj.temp_image = "/tmp/tmp.png"
obj.temp_ocr_image = "/tmp/ocr_tmp.png"

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

function obj.capper(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[capper] no image on clipboard")
    return
  end

  -- clear previous image url
  hs.pasteboard.clearContents("imageURL")

  local date = hs.execute("zsh -ci 'echo $EPOCHSECONDS'")
  local cap_name = fmt("cap_%s.png", date:gsub("\n", ""))
  local cap = fmt("%s/%s", obj.caps_dir, cap_name)

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
      hs.pasteboard.setContents(url, "imageURL")
      hs.pasteboard.setContents(image, "image")
      if open_image_url then hs.urlevent.openURLWithBundle(url, hs.urlevent.getDefaultHandler("https")) end
    else
      error(fmt("failed to upload image to spaces (%s/%s/%s)..", url, type, rc))
    end
  else
    error(fmt("file %s doesn't exist for uploading to capper.", cap))
  end
end

function obj.send_to_imgur(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[send_to_imgur] no image on clipboard")
    return
  end

  -- clear previous image url
  hs.pasteboard.clearContents("imageURL")

  image:saveToFile(obj.temp_image)
  local b64 = hs.execute("base64 -i " .. obj.temp_image)

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
        local imageURL = response.data.link
        hs.pasteboard.setContents(imageURL, "imageURL")
        hs.pasteboard.setContents(image, "image")

        if open_image_url then hs.urlevent.openURLWithBundle(imageURL, hs.urlevent.getDefaultHandler("https")) end
        hs.execute("rm " .. obj.temp_image)
      else
        error(fmt("status: %s, body: %s, headers: %s", status, body, I(headers)))
      end
    end)
  end
end

-- REF:
-- Slightly modifed version of:
-- https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/ocr-paste.lua
--
function obj.paste_ocr_text(image)
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[paste_ocr_text] no image on clipboard")
    return
  end

  local imagePath = obj.temp_ocr_image
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

function obj.edit_clipboard_image(image)
  -- Check if an image is in the clipboard
  image = image or hs.pasteboard.readImage()

  if not image then
    warn("[edit_clipboard_image] no image on clipboard")
    return
  end

  -- Save the image to a temporary file
  local tmpfile = os.tmpname() .. ".png"
  image:saveToFile(tmpfile)

  -- Open the image in Preview and start annotation
  hs.execute("open -a Preview " .. tmpfile)

  -- hs.timer.doAfter(
  --   1,
  --   function() hs.appfinder.appFromName("Preview"):selectMenuItem({ "Tools", "Annotate", "Arrow" }) end
  -- )
end

function obj:init(opts)
  opts = opts or {}
  obj.clip_watcher = hs.pasteboard.watcher.new(function(pb)
    dbg("clip_data: %s", I(obj.clip_data))

    if pb ~= nil and pb ~= "" then
      obj.clip_data = pb
    else
      obj.clip_data = hs.pasteboard.readImage()
      obj.capper(obj.clip_data, false)

      local pasteImageUrl = function()
        local imageURL = hs.pasteboard.getContents("imageURL")
        hs.eventtap.keyStrokes(imageURL)
        dbg("imageURL: %s", imageURL)
      end
      hs.hotkey.bind({ "cmd", "shift" }, "v", pasteImageUrl)
      hs.hotkey.bind({ "cmd", "ctrl" }, "v", pasteImageUrl)

      local browser = hs.application.get(C.preferred.browser)
      if
        browser
        and hs.fnutils.contains(C.preferred.browsers, browser:name())
        and browser == hs.application.frontmostApplication()
      then
        hs.hotkey.bind({ "ctrl", "shift" }, "v", function()
          local imageURL = hs.pasteboard.getContents("imageURL")
          -- local imageName = hs.pasteboard.getContents("imageName")

          local md_img = fmt([[<img src="%s" width="450" />]], imageURL)
          hs.eventtap.keyStrokes(md_img)
          dbg("markdown_image: %s", md_img)
        end)
      end

      hs.hotkey.bind({ "cmd", "shift" }, "p", function()
        obj.paste_ocr_text(obj.clip_data)
        local ocr_text = hs.pasteboard.getContents("ocrText")
        hs.eventtap.keyStrokes(ocr_text)
        dbg("ocrText: %s", ocr_text)
      end)

      hs.hotkey.bind({ "cmd", "shift" }, "e", function()
        obj.edit_clipboard_image(obj.clip_data)
        -- local ocr_text = hs.pasteboard.getContents("ocrText")
        -- hs.eventtap.keyStrokes(ocr_text)
        -- dbg("ocrText: %s", ocr_text)
      end)
    end
  end)

  obj.clip_watcher:start()

  return self
end

function obj:start(opts)
  opts = opts or {}

  return self
end

function obj:stop(opts)
  opts = opts or {}
  return self
end

return obj
