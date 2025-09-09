local enum = require("hs.fnutils")
local obj = {}
local browser = req("browser")
local uri = hs.http.urlParts

obj.__index = obj
obj.name = "watcher.url"
obj.debug = false
obj.browserTabCount = -1
obj.currentHandler = nil

obj.callbacks = {
  {
    pattern = "https:?://pop.com/*",
    action = function(opts)
      local handler = opts["handler"]
      local url = opts["url"]
      local urlDomain = url and uri(url).host

      if hs.urlevent.openURLWithBundle(url, hs.application.get(handler):bundleID()) then
        local app = hs.application.get("com.pop.pop.app")

        hs.timer.waitUntil(
          function() return browser.hasTab(urlDomain) and hs.application.get(app) ~= nil end,
          function()
            req("watchers.app").runContextForAppBundleID(app:name(), hs.application.watcher.launched, app, {
              tabCount = obj.browserTabCount,
              url = urlDomain,
              onOpen = function()
                -- if browser.tabCount() == metadata.tabCount + 1 and browser.hasTab(metadata.url) then
                hs.spotify.pause()
                req("utils").dnd(true)
                req("ptt").setMode("push-to-talk")
                req("watchers.dock").refreshInput("docked")
              end,
              onClose = function()
                req("utils").dnd(false)
                req("ptt").setMode("push-to-talk")
              end,
            })
          end
        )
      end
    end,
  },
  {
    pattern = "https:?://meet.google.com/*",
    action = function(opts)
      local handler = opts["handler"]
      local url = opts["url"]
      local urlDomain = url and uri(url).host
      local app = hs.application.get(handler) or hs.application.get(BROWSER)

      dbg(handler)
      dbg(app:bundleID())

      -- NOTE: order of this tabCount check matters!
      obj.browserTabCount = browser.tabCount()
      hs.urlevent.openURLWithBundle(url, app:bundleID())

      hs.timer.waitUntil(function() return browser.hasTab(urlDomain) end, function()
        req("watchers.app").runContextForAppBundleID(app:name(), hs.application.watcher.activated, app, {
          tabCount = obj.browserTabCount,
          url = urlDomain,
          onOpen = function()
            -- if browser.tabCount() == metadata.tabCount + 1 and browser.hasTab(metadata.url) then
            hs.spotify.pause()
            req("utils").dnd(true)
            req("ptt").setMode("push-to-talk")
            req("watchers.dock").refreshInput("docked")
          end,
          onClose = function()
            req("utils").dnd(false)
            req("ptt").setMode("push-to-talk")
          end,
        })
      end)
    end,
  },
  {
    pattern = "https:?://open.spotify.com/*",
    action = "com.spotify.client",
  },
  -- {
  --   pattern = "https:?://www.figma.com/proto/*",
  --   action = "com.figma.Desktop",
  -- },
  -- {
  --   pattern = "https:?://www.figma.com/file/*",
  --   action = "com.figma.Desktop",
  -- },
  -- {
  --   -- FIXME: ignore certain parts of a pattern here.. (e.g., ignore `/app_auth/` path)
  --   pattern = "https:?://www.figma.com/*",
  --   action = function(opts) print(I(opts)) end,
  -- },
  -- {
  --   -- FIXME: ignore certain parts of a pattern here.. (e.g., ignore `/app_auth/` path)
  --   pattern = "https:?://*.figma.com/*",
  --   -- action = "com.figma.Desktop",
  --   action = function(opts) print(I(opts)) end,
  -- },
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
  local appHandler = enum.find(allHandlers, function(v) return v == BROWSER end)

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
