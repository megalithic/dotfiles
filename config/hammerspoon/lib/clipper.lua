local obj = {}

obj.__index = obj
obj.name = "clipper"
obj.debug = false
obj.clip_watcher = {}
obj.clip_data = {}
obj.tempfile = "/tmp/tmp.png"

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

function obj.send_to_imgur(image, open_image_url)
  image = image or hs.pasteboard.readImage()

  if image then
    image:saveToFile(obj.tempfile)
    local b64 = hs.execute("base64 -i " .. obj.tempfile)
    local client_id = hs.execute("zsh -ci 'echo $IMGUR_CLIENT_ID'")

    if b64 ~= nil then
      b64 = hs.http.encodeForQuery(string.gsub(b64, "\n", ""))

      local req_url = "https://api.imgur.com/3/upload.json"
      local req_headers = { Authorization = fmt("Client-ID %s", client_id) }
      local req_payload = "type='base64'&image=" .. b64

      hs.http.asyncPost(req_url, req_payload, req_headers, function(status, body, _headers)
        if status == 200 then
          local response = hs.json.decode(body)
          local imageURL = response.data.link
          hs.pasteboard.setContents(imageURL, "imageURL")
          hs.pasteboard.setContents(image, "image")

          if open_image_url then hs.urlevent.openURLWithBundle(imageURL, hs.urlevent.getDefaultHandler("http")) end
        end
      end)
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
