local Settings = require("hs.settings")
local FNUtils = require("hs.fnutils")
local C = require("config")

local obj = {}

obj.__index = obj
obj.name = "watcher.url"

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

  local preferredBrowser =
    hs.application.get(Settings.get("group.browsers") or C.preferred.browser or C.preferred.browsers[1])
  local currentBrowserBundleID = preferredBrowser:bundleID()

  local handler = hs.fnutils.find(allHandlers, function(v) return v == currentBrowserBundleID end)

  if not handler then
    error("Invalid browser handler: " .. (currentHandler or "nil"))
    return
  end

  if not fullURL then
    error("Attempt to open browser without url")
    return
  end

  hs.urlevent.openURLWithBundle(fullURL, handler)
end

function obj:start()
  hs.urlevent.httpCallback = httpCallback
  return self
end

function obj:stop()
  hs.urlevent.httpCallback = nil
  currentHandler = nil
  return self
end

return obj
