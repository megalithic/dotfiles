local enum = require("hs.fnutils")
local obj = {}

obj.__index = obj
obj.name = "watcher.url"
obj.debug = false

-- custom callbacks per url to be able to run some arbitrary function
obj.callbacks = {
  {
    pattern = "https:?://meet.google.com/*",
    callback = function(...)
      req("utils").dnd(true, "zoom")
      hs.spotify.pause()
      require("ptt").setState("push-to-talk")
      -- L.req("lib.watchers.dock").refreshInput("docked")
      require("ptt").setAllInputsMuted(true)
    end,
  },
}

local function handle_url_callbacks(fullURL, handler)
  local cb = enum.find(obj.callbacks, function(el) return string.match(fullURL, el.pattern) ~= nil end)
  if cb ~= nil then
    if type(cb.callback) then cb.callback({ arg1 = "arg1 here", app_handler = handler, fullURL = fullURL }) end
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

  local app_handler = enum.find(allHandlers, function(v) return v == currentBrowserBundleID end)

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
  hs.urlevent.httpCallback = httpCallback
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
