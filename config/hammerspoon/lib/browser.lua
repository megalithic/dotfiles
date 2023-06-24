local Settings = require("hs.settings")

local obj = {}
local browser = hs.application.get(C.preferred.browser)
local snap = L.req("lib.wm.snap")

obj.__index = obj
obj.name = "browser"
obj.debug = true
obj.browsers = C.preferred.browsers

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

function obj.hasTab(url)
  if browser and hs.fnutils.contains(obj.browsers, browser:name()) then
    local _status, returnedObj, _descriptor = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. browser:name() .. [[');
      const foundTab = browser.windows().filter((win) => {
        const tabIndex = win.tabs().findIndex(tab => tab.url().match(/]] .. string.gsub(url, "/", "\\/") .. [[/));
        return tabIndex !== -1
      })

      return foundTab.length > 0;
    })();
    ]])

    return returnedObj
  end

  return nil
end

function obj.jump(url)
  if browser and hs.fnutils.contains(obj.browsers, browser:name()) then
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. browser:name() .. [[');
      browser.activate();
      for (win of browser.windows()) {
        var tabIndex =
          win.tabs().findIndex(tab => tab.url().match(/]] .. string.gsub(url, "/", "\\/") .. [[/));
        if (tabIndex != -1) {
          win.activeTabIndex = (tabIndex + 1);
          win.index = 1;
        }
      }
    })();
    ]])
  end
end

function obj.splitTab(to_next_window)
  -- Move current window to the left half
  if snap and not to_next_window then snap.send_window_left() end

  hs.timer.doAfter(100 / 1000, function()
    local supportedBrowsers = { "Brave Browser Dev", "Brave Browser", "Brave Browser Beta", "Safari" }

    if browser and hs.fnutils.contains(supportedBrowsers, browser:name()) then
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(browser:name(), "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      browser:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if snap then
        if to_next_window then
          browser:selectMenuItem({ "Window", fmt("Move to %s", C.displays.internal) })
          snap.maximize()
        else
          snap.send_window_right()
        end
      end
    else
      warn(fmt("[snap.browser.splitTab] unsupported browser: %s", browser:name()))
    end
  end)
end

function obj.killTabsByDomain(domain)
  if browser and hs.fnutils.contains(obj.browsers, browser:name()) then
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. browser:name() .. [[');
      browser.activate();
      for (win of browser.windows()) {
        for (tab of win.tabs()) {
          if (tab.url().match(/]] .. string.gsub(domain, "/", "\\/") .. [[/)) {
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
