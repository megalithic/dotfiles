local enum = require("hs.fnutils")
local obj = {}

obj.__index = obj
obj.name = "watcher.url"
obj.debug = false

-- custom callbacks per url to be able to run some arbitrary function
obj.callbacks = {
  {
    pattern = "https:?://meet.google.com/*",
    callback = "com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
    -- callback = function(...)
    --   dbg(I(...), true)
    --   req("utils").dnd(true, "zoom")
    --   hs.spotify.pause()
    --   require("ptt").setState("push-to-talk")
    --   -- L.req("lib.watchers.dock").refreshInput("docked")
    --   require("ptt").setAllInputsMuted(true)
    --   hs.urlevent.openURLWithBundle(url, id)
    -- end,
  },
}

local function handle_url_callbacks(fullURL, handler)
  local cb = enum.find(obj.callbacks, function(el) return string.match(fullURL, el.pattern) ~= nil end)
  if cb ~= nil then
    if type(cb.callback) == "function" then
      cb.callback({ app_handler = handler, fullURL = fullURL })
    elseif type(cb.callback) == "string" then
      hs.urlevent.openURLWithBundle(fullURL, cb.callback)
    end
  end
end

-- keeps track of the most recently used browser
local currentHandler = nil
-- callback, called when a url is clicked. Sends the url to the currentHandler.
---   * scheme - A string containing the URL scheme (i.e. "http")
---   * host - A string containing the host requested (e.g. "www.hammerspoon.org")
---   * params - A table containing the key/value pairs of all the URL parameters
---   * fullURL - A string containing the full, original URL
---   * senderPID - An integer containing the PID of the application that opened the URL, if available (otherwise -1)
local function httpCallback(scheme, _host, _params, fullURL, _senderPID)
  local allHandlers = hs.urlevent.getAllHandlersForScheme(scheme)

  local preferredBrowser = hs.application.get(BROWSER)
  local currentBrowserBundleID = preferredBrowser:bundleID()

  local app_handler = enum.find(allHandlers, function(v)
    dbg(v, true)
    return v == currentBrowserBundleID
  end)

  if not app_handler then
    error("Invalid browser handler: " .. (currentHandler or "nil"))
    return
  else
    currentHandler = app_handler
  end

  if not fullURL then
    error("Attempt to open browser without url")
    return
  end

  hs.urlevent.openURLWithBundle(fullURL, app_handler)

  handle_url_callbacks(fullURL, app_handler)
end

function obj:start()
  -- Tracking this issue to get working handoff to default browser:
  -- REF: https://github.com/Hammerspoon/hammerspoon/pull/3635

  -- hs.urlevent.setDefaultHandler("http", BROWSER)
  hs.urlevent.httpCallback = httpCallback
  -- hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
  --   print("URL Director: " .. fullURL)
  --
  --   local screen = hs.screen.mainScreen():frame()
  --   local handlers = hs.urlevent.getAllHandlersForScheme(scheme)
  --   local browsers = hs.fnutils.filter(handlers, function(o, k, i)
  --     local name = hs.application.nameForBundleID(o)
  --     return name == "Chrome" or name == "Firefox"
  --   end)
  --   local numHandlers = #browsers
  --   print(numHandlers)
  --   local modalKeys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
  --
  --   local boxBorder = 10
  --   local iconSize = 72
  --
  --   if numHandlers > 0 then
  --     local appIcons = {}
  --     local appNames = {}
  --     local modalDirector = hs.hotkey.modal.new()
  --     local x = screen.x + (screen.w / 2) - (numHandlers * iconSize / 2)
  --     local y = screen.y + (screen.h / 2) - (iconSize / 2)
  --     local box = hs.drawing.rectangle(
  --       hs.geometry.rect(
  --         x - boxBorder,
  --         y - boxBorder,
  --         (numHandlers * iconSize) + (boxBorder * 2),
  --         iconSize + (boxBorder * 4)
  --       )
  --     )
  --     box:setFillColor({ ["red"] = 0, ["blue"] = 0, ["green"] = 0, ["alpha"] = 0.5 }):setFill(true):show()
  --
  --     local exitDirector = function(bundleID, url)
  --       if bundleID and url then hs.urlevent.openURLWithBundle(url, bundleID) end
  --       for _, icon in pairs(appIcons) do
  --         icon:delete()
  --       end
  --       for _, name in pairs(appNames) do
  --         name:delete()
  --       end
  --       box:delete()
  --       modalDirector:exit()
  --     end
  --
  --     for num, browser in pairs(browsers) do
  --       local appIcon = hs.drawing.appImage(hs.geometry.size(iconSize, iconSize), browser)
  --       local name = hs.application.nameForBundleID(browser)
  --
  --       if appIcon and name and name == "Chrome" or name == "Firefox" then
  --         local appName = hs.drawing.text(hs.geometry.size(iconSize, boxBorder), modalKeys[num] .. " " .. name)
  --
  --         table.insert(appIcons, appIcon)
  --         table.insert(appNames, appName)
  --
  --         appIcon:setTopLeft(hs.geometry.point(x + ((num - 1) * iconSize), y))
  --         appIcon:setClickCallback(function() exitDirector(browser, fullURL) end)
  --         appIcon:orderAbove(box)
  --         appIcon:show()
  --
  --         appName:setTopLeft(hs.geometry.point(x + ((num - 1) * iconSize), y + iconSize))
  --         appName:setTextStyle({
  --           ["size"] = 10,
  --           ["color"] = { ["red"] = 1, ["blue"] = 1, ["green"] = 1, ["alpha"] = 1 },
  --           ["alignment"] = "center",
  --           ["lineBreak"] = "truncateMiddle",
  --         })
  --         appName:orderAbove(box)
  --         appName:show()
  --
  --         modalDirector:bind({}, modalKeys[num], function() exitDirector(browser, fullURL) end)
  --       end
  --     end
  --
  --     modalDirector:bind({}, "Escape", exitDirector)
  --     modalDirector:enter()
  --   end
  -- end
  -- hs.urlevent.setDefaultHandler("http")
  info(fmt("[START] %s", self.name))

  return self
end

function obj:stop()
  hs.urlevent.httpCallback = nil
  currentHandler = nil
  info(fmt("[STOP] %s", self.name))

  return self
end

return obj
