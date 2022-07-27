local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "browser"
obj.debug = true
obj.browsers = Settings.get(CONFIG_KEY).preferred.browsers

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

function obj.splitTab()
  -- Move current window to the left half
  local snap = L.req("lib.wm.snap")
  if snap then snap.send_window_left() end

  hs.timer.doAfter(100 / 1000, function()
    local browser = hs.window.focusedWindow():application()
    local supportedBrowsers = { "Brave Browser", "Brave Browser Dev", "Brave Browser Beta", "Safari" }

    if browser and hs.fnutils.contains(supportedBrowsers, browser:name()) then
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(browser:name(), "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      browser:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if snap then snap.send_window_right() end
    else
      warn(fmt("[snap.browser.splitTab] unsupported browser: %s", browser:name()))
    end
  end)
end

function obj.killTabsByDomain(domain)
  local browser = hs.window.focusedWindow():application()

  if browser and hs.fnutils.contains(obj.browsers, browser:name()) then
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. browser .. [[');
      browser.activate();
      for (win of browser.windows()) {
        for (tab of win.tabs()) {
          if (tab.url().match(/]] .. domain .. [[/)) {
            console.log("found tab to kill", tab.url())
            tab.close()
          }
        }
      }
    })();
    ]])
  end
end

function obj:init() return self end

function obj:start() return self end

function obj:stop() return self end

return obj
