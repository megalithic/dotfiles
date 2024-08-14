local enum = require("hs.fnutils")
local obj = {}
local browser = req("browser")

obj.__index = obj
obj.name = "watcher.url"
obj.debug = false
obj.browserTabCount = -1
obj.currentHandler = nil

obj.callbacks = {
  {
    pattern = "https:?://meet.google.com/*",
    -- FIXME: if the url passed to the PWA google meet app worked,
    --  we'd not need to fiddle with this hackiness. :sadpanda:
    -- action = "com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan",
    action = function(opts)
      local handler = opts["handler"]
      local url = opts["url"]
      local urlDomain = url and url:match("([%w%-%.]*%.[%w%-]+%.%w+)")

      local app = hs.application.get(handler) or hs.application.get(BROWSER)

      -- NOTE: order of this tabCount check matters!
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
function obj.handleHttpCallback(scheme, _host, _params, fullURL, _senderPID)
  local allHandlers = hs.urlevent.getAllHandlersForScheme(scheme)
  local currentBrowserBundleID = hs.application.get(BROWSER):bundleID()
  local appHandler = enum.find(allHandlers, function(v) return v == currentBrowserBundleID end)

  if not appHandler then
    warn(fmt("[%s] invalid browser handler: %s", obj.name, obj.currentHandler))
    return
  else
    obj.currentHandler = appHandler
  end

  if not fullURL then
    error("Attempt to open browser without url")
    return
  end

  obj.handleUrlCallback(fullURL, appHandler)
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
  obj.currentHandler = nil
  info(fmt("[STOP] %s", self.name))

  return self
end

return obj
