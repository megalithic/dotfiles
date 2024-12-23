-- HT: https://github.com/evantravers/dotfiles/blob/master/.config/hammerspoon/browserSnip.lua

local fmt = string.format
local obj = {}
obj.__index = obj
obj.name = "snipper"
obj.debug = true

-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function magiclines(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

function obj.sendToCanonize(url, title, quote, tags)
  local api_url = os.getenv("CANONIZE_SNIPPET_URL")

  hs.http.asyncPost(
    api_url,
    hs.json.encode({
      ["snippet"] = {
        ["title"] = title,
        ["url"] = url,
        ["highlight"] = quote,
        ["tags"] = tags,
      },
    }),
    {
      ["Content-Type"] = "application/json; charset=UTF-8",
      ["Authorization"] = "Bearer foo",
    },
    function(status, body, headers)
      if status == 200 or status == 201 then
        local response = hs.json.decode(body)
        success(response)
      else
        error(string.format("[%s] %s\r\n%s", obj.name, status, require("utils").truncate(body, 100)))
      end

      hs.pasteboard.clearContents()
    end
  )
end

local function copyToClipboard(app)
  if app:bundleID() == "com.mitchellh.ghostty" then
    hs.eventtap.keyStroke("", "y")
  else
    hs.eventtap.keyStroke("command", "c")
  end
end

function obj:init(opts)
  opts = opts or {}

  req("hyper", { id = self.name }):start():bind({ "shift" }, "s", nil, function()
    local tags = "snippets"
    local words = {}
    local quote = ""
    local highlight = nil

    local browser = hs.application.get(BROWSER)
    local frontMostApp = hs.application.frontmostApplication()
    local is_browser_active = browser and browser == frontMostApp

    local win = hs.window.focusedWindow()
    local title = is_browser_active and win:title():gsub("- Brave Canary", "") or win:title()

    print(is_browser_active)
    print(title)

    -- get the highlighted item
    -- hs.pasteboard.clearContents()
    hs.eventtap.keyStroke("command", "c")
    -- copyToClipboard(frontMostApp)

    highlight = hs.pasteboard.readString()
    print(highlight)

    if highlight ~= nil then
      for word in string.gmatch(highlight, "([^%s]+)") do
        table.insert(words, word)
      end

      -- local textStart = hs.http.encodeForQuery(words[1] .. " " .. words[2])
      -- local textEnd = hs.http.encodeForQuery(words[#words - 1] .. " " .. words[#words])

      for line in magiclines(highlight) do
        quote = quote .. " " .. line .. "\n"
      end

      tags = tags .. ",quote"
    end

    if is_browser_active then
      local _, url = hs.osascript.applescript(
        "tell application \"" .. browser:name() .. "\" to return URL of active tab of front window"
      )
      url = url:gsub("?utm_source=.*", "")
      tags = tags .. ",bookmark"

      print(url)

      obj.sendToCanonize(url, title, quote, tags)
    else
      obj.sendToCanonize("", title, quote, tags)
    end
  end)

  info(string.format("[INIT] bindings.%s", self.name))
end

return obj
