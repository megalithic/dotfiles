-- HT: https://github.com/evantravers/dotfiles/blob/master/.config/hammerspoon/browserSnip.lua

local obj = {}
obj.__index = obj
obj.name = "snipper"
obj.debug = true

-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function magiclines(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

function obj.sendToCanonize(url, title, quote, textStart, textEnd)
  print("url:")
  print(url)
  print("title:")
  print(title)
  print("quote:")
  print(quote)

  -- if b64 ~= nil then
  --   b64 = hs.http.encodeForQuery(string.gsub(b64, "\n", ""))

  --   local req_url = "https://canonize.app/api/snippet"
  --   local req_headers = { Authorization = fmt("Client-ID %s", client_id:gsub("\n", "")) }
  --   local req_payload = "type='base64'&image=" .. b64

  --   dbg("request: %s/%s", req_url, I(req_headers))

  --   hs.http.asyncPost(req_url, req_payload, req_headers, function(status, body, headers)
  --     if status == 200 then
  --       local response = hs.json.decode(body)
  --       local imageUrl = response.data.link
  --       hs.pasteboard.setContents(imageUrl, "imageUrl")
  --       hs.pasteboard.setContents(image, "image")

  --       if open_image_url then hs.urlevent.openURLWithBundle(imageUrl, hs.urlevent.getDefaultHandler("https")) end
  --       hs.execute("rm " .. obj.tempImage)
  --     else
  --       error(fmt("[%s] sendToImgur: %s/%s/%s/%s", obj.name, status, body, I(headers)))
  --     end
  --   end)
  -- end
end

function obj:init(opts)
  opts = opts or {}

  req("hyper", { id = self.name }):start():bind({ "shift" }, "s", nil, function()
    local browser = hs.application.get(BROWSER)
    if not browser or browser ~= hs.application.frontmostApplication() then return end

    local win = hs.window.focusedWindow()
    local title = win:title():gsub("- Brave Canary", "")

    -- get the highlighted item
    hs.eventtap.keyStroke("command", "c")
    local highlight = hs.pasteboard.readString()

    local words = {}
    local quote = ""
    if highlight ~= nil then
      for word in string.gmatch(highlight, "([^%s]+)") do
        table.insert(words, word)
      end

      -- local textStart = hs.http.encodeForQuery(words[1] .. " " .. words[2])
      -- local textEnd = hs.http.encodeForQuery(words[#words - 1] .. " " .. words[#words])

      for line in magiclines(highlight) do
        -- quote = quote .. "> " .. line .. "\n"
        quote = quote .. " " .. line .. "\n"
      end
    end

    local _, url = hs.osascript.applescript(
      "tell application \"" .. browser:name() .. "\" to return URL of active tab of front window"
    )
    url = url:gsub("?utm_source=.*", "")

    obj.sendToCanonize(url, title, quote)
    -- hs.notify.show("Snipped!", "The snippet has been sent to Drafts", "")
  end)

  info(fmt("[INIT] bindings.%s", self.name))
end

return obj
