local Settings = require("hs.settings")

local obj = {}
local snap = L.req("lib.wm.snap")

obj.__index = obj
obj.name = "browser"
obj.debug = false
obj.browsers = C.preferred.browsers

-- local browser = nil
-- if Settings.get("group.browsers") ~= nil then
--   browser = hs.application.get(Settings.get("group.browsers"))
-- elseif C.preferred.browser ~= nil then
--   browser = hs.application.get(C.preferred.browser)
-- elseif obj.browsers[1] ~= nil then
--   browser = hs.application.get(obj.browsers[1])
-- end

local get_browser = function()
  local browser = nil
  if Settings.get("group.browsers") ~= nil then
    browser = hs.application.get(Settings.get("group.browsers"))
  elseif C.preferred.browser ~= nil then
    browser = hs.application.get(C.preferred.browser)
  elseif obj.browsers[1] ~= nil then
    browser = hs.application.get(obj.browsers[1])
  end

  return browser
end

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

function obj.hasTab(url)
  local browser = get_browser()
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
  local browser = get_browser()
  if browser and hs.fnutils.contains(obj.browsers, browser:name()) then
    local _success, object, _output = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. browser:name() .. [[');
      browser.activate();
      for (win of browser.windows()) {
        var tabIndex =
          win.tabs().findIndex(tab => tab.url().match(/]] .. string.gsub(url, "/", "\\/") .. [[/));
        if (tabIndex != -1) {
          win.activeTabIndex = (tabIndex + 1);
          win.index = 1;
          return true;
        } else {
          return false;
        }
      }
    })();
    ]])
    return object
  else
    return false
  end
end

function obj.splitTab(to_next_screen)
  if not snap then
    warn("snap module not found..")
    return
  end
  local browser = get_browser()

  -- Move current window to the left half
  if not to_next_screen then snap.left50() end

  hs.timer.doAfter(0.25, function()
    local supportedBrowsers =
      { "Chromium", "Brave Browser Nightly", "Brave Browser Dev", "Brave Browser", "Brave Browser Beta", "Safari" }

    if browser and hs.fnutils.contains(supportedBrowsers, browser:name()) then
      dbg("(splitTab) %s", browser:name())
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(browser:name() or "", "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      browser:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if to_next_screen then
        dbg("(splitTab) to_next_screen: %s", C.displays.internal)
        browser:selectMenuItem({ "Window", fmt("Move to %s", C.displays.internal) })
        snap.maximize()
      else
        snap.right50()
      end
    else
      warn(fmt("[snap.browser.splitTab] unsupported browser: %s", browser:name()))
    end
  end)
end

function obj.killTabsByDomain(domain)
  local browser = get_browser()
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
