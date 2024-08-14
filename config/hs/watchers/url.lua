local enum = require("hs.fnutils")
local obj = {}
local browser = req("browser")

obj.__index = obj
obj.name = "watcher.url"
obj.debug = false
obj.browserTabCount = -1

obj.callbacks = {
  {
    pattern = "https:?://meet.google.com/*",
    -- action = "com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
    action = function(opts)
      local handler = opts["handler"]
      local url = opts["url"]
      local urlDomain = url and url:match("([%w%-%.]*%.[%w%-]+%.%w+)")

      local app = hs.application.get(handler) or hs.application.get(BROWSER)

      obj.browserTabCount = browser.tabCount()
      hs.urlevent.openURLWithBundle(url, app:bundleID())

      hs.timer.waitUntil(
        function() return browser.hasTab(urlDomain) end,
        function()
          req("watchers.app").runContextForAppBundleID(
            app:name(),
            hs.application.watcher.activated,
            app,
            { tabCount = obj.browserTabCount, url = urlDomain }
          )
        end
      )
    end,
  },
}

function obj.handleUrlCallback(url, handler)
  local cb = enum.find(obj.callbacks, function(item) return string.match(url, item.pattern) ~= nil end)
  if cb ~= nil then
    if type(cb.action) == "function" then
      cb.action({ handler = handler, url = url })
    elseif type(cb.action) == "string" then
      hs.urlevent.openURLWithBundle(url, cb.action)
    end
  else
    hs.urlevent.openURLWithBundle(url, handler)
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
function obj.handleHttpCallback(scheme, _host, _params, fullURL, _senderPID)
  local allHandlers = hs.urlevent.getAllHandlersForScheme(scheme)

  local preferredBrowser = hs.application.get(BROWSER)
  local currentBrowserBundleID = preferredBrowser:bundleID()

  local app_handler = enum.find(allHandlers, function(v)
    -- dbg(v, true)
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

  obj.handleUrlCallback(fullURL, app_handler)
end

function obj:start()
  -- Tracking this issue to get working handoff to default browser:
  -- REF: https://github.com/Hammerspoon/hammerspoon/pull/3635

  hs.urlevent.httpCallback = self.handleHttpCallback
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
