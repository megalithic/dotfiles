-- HT: https://github.com/evantravers/dotfiles/blob/master/.config/hammerspoon/browserSnip.lua

local fmt = string.format
local obj = {}
obj.__index = obj
obj.name = "snipper"
obj.debug = true
obj.env = "prod"
obj.secrets = hs.settings.get("secrets")

-- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
local function magiclines(s)
  if s:sub(-1) ~= "\n" then s = s .. "\n" end
  return s:gmatch("(.-)\n")
end

local function get_api_url(env)
  env = env and env or obj.env

  if obj.secrets["canonize"]["bookmarksApiUrl"][env] then
    return obj.secrets["canonize"]["bookmarksApiUrl"][env]
  else
    warn("You need to set Canonize bookmarks API URL under secrets.canonize.bookmarksApiUrl." .. env)
  end
end

local function get_api_token(env)
  env = env and env or obj.env

  if obj.secrets["canonize"]["bookmarksApiToken"][env] then
    return obj.secrets["canonize"]["bookmarksApiToken"][env]
  else
    warn("You need to set Canonize bookmarks API Token under secrets.canonize.bookmarksApiToken." .. env)
  end
end

function obj.sendToCanonize(url, title, quote, tags, env)
  local api_url = get_api_url(env)
  local api_token = get_api_token(env)

  hs.http.asyncPost(
    api_url,
    hs.json.encode({
      ["bookmark"] = {
        ["title"] = title,
        ["url"] = url,
        ["highlight"] = quote,
        ["tags"] = tags,
      },
    }),
    {
      ["Content-Type"] = "application/json; charset=UTF-8",
      ["Authorization"] = "Bearer " .. api_token,
    },
    function(status, body, headers)
      dbg({ env, status, url, title, quote, tags })

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

function obj.getSelectedText()
  local element = hs.uielement.focusedElement()
  local selection

  if element then selection = element:selectedText() end

  return selection
end

function obj:init(opts)
  opts = opts or {}

  local function snip(env)
    env = env or obj.env
    local tags = "bookmark"
    local words = {}
    local quote = ""
    local textStart = nil
    local textEnd = nil
    local highlight = nil

    local browser = hs.application.get(BROWSER)
    local frontMostApp = hs.application.frontmostApplication()
    local is_browser_active = browser and browser == frontMostApp

    local win = frontMostApp:mainWindow() or hs.window.focusedWindow()
    local title = is_browser_active and win:title():gsub("- Brave Canary", "") or win:title()

    -- get the highlighted item
    -- hs.eventtap.keyStroke("command", "c")
    -- highlight = hs.pasteboard.readString()

    highlight = obj.getSelectedText()

    -- local _, url = hs.osascript.javascript(
    --   "window.getSelection()"
    -- )

    if highlight ~= nil then
      for word in string.gmatch(highlight, "([^%s]+)") do
        table.insert(words, word)
      end

      -- textStart = hs.http.encodeForQuery(words[1] .. " " .. words[2])
      -- textEnd = hs.http.encodeForQuery(words[#words - 1] .. " " .. words[#words])

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

      -- local template = string.format([[%s%s [%s](%s#:~:text=%s,%s)]], title, quote, title, url, textStart, textEnd)
      -- dbg(template, true)

      obj.sendToCanonize(url, title, quote, tags, env)
    else
      obj.sendToCanonize("", title, quote, tags, env)
    end
  end

  req("hyper", { id = self.name }):start():bind({ "shift" }, "s", nil, function() snip("prod") end)
  req("hyper", { id = self.name }):start():bind({ "ctrl" }, "s", nil, function() snip("dev") end)

  info(string.format("[INIT] bindings.%s", self.name))
end

return obj
