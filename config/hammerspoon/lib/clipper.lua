local obj = {}

obj.__index = obj
obj.name = "clipper"
obj.debug = false
obj.clip_watcher = {}
obj.clip_data = {}
obj.temp_image = "/tmp/tmp.png"
obj.temp_ocr_image = "/tmp/ocr_tmp.png"

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

function obj.send_to_imgur(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if image then
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

          if open_image_url then hs.urlevent.openURLWithBundle(imageURL, hs.urlevent.getDefaultHandler("http")) end
          hs.execute("rm " .. obj.temp_image)
        else
          error(fmt("status: %s, body: %s, headers: %s", status, body, I(headers)))
        end
      end)
    end
  end
end

-- REF:
-- Slightly modifed version of:
-- https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/ocr-paste.lua
--
function obj.paste_ocr_text(image)
  image = image or hs.pasteboard.readImage()

  if image then
    -- local imagePath = "/tmp/ocr_image.png"
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
end

function obj:init(opts)
  opts = opts or {}
  obj.clip_watcher = hs.pasteboard.watcher.new(function(pb)
    dbg("clip_data: %s", I(obj.clip_data))

    if pb ~= nil and pb ~= "" then
      obj.clip_data = pb
    else
      obj.clip_data = hs.pasteboard.readImage()
      obj.send_to_imgur(obj.clip_data, false)

      hs.hotkey.bind({ "cmd", "shift" }, "v", function()
        local imageURL = hs.pasteboard.getContents("imageURL")
        hs.eventtap.keyStrokes(imageURL)
        dbg("imageURL: %s", imageURL)
      end)

      hs.hotkey.bind({ "cmd", "shift" }, "p", function()
        obj.paste_ocr_text(obj.clip_data)
        local ocr_text = hs.pasteboard.getContents("ocrText")
        hs.eventtap.keyStrokes(ocr_text)
        dbg("ocrText: %s", ocr_text)
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