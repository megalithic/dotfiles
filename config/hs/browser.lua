local Settings = require("hs.settings")
local wm = require("wm")

local obj = {}
obj.__index = obj
obj.name = "browser"
obj.debug = false

local get_browser = function()
  local browser = nil
  if BROWSER ~= nil then
    hs.application.get(BROWSER)
  elseif Settings.get("group.browsers") ~= nil then
    browser = hs.application.get(Settings.get("group.browsers"))
  elseif C.preferred.browser ~= nil then
    browser = hs.application.get(C.preferred.browser)
  elseif obj.browsers[1] ~= nil then
    browser = hs.application.get(obj.browsers[1])
  end

  dbg(browser)

  return browser
end
obj.browser = get_browser()

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", "browser", str)
  if true then return print(string.format(str, ...)) end
end

function obj.hasTab(url)
  if obj.browser and hs.fnutils.contains(obj.browsers, obj.browser:name()) then
    local _status, returnedObj, _descriptor = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. obj.browser:name() .. [[');
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
  if obj.browser and hs.fnutils.contains(obj.browsers, obj.browser:name()) then
    local _success, object, _output = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. obj.browser:name() .. [[');
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

function obj:splitTab(to_next_screen)
  -- Move current window to the left half
  if not to_next_screen then wm.place(POSITIONS.halves.left) end

  dbg(I(self))
  hs.timer.doAfter(0.25, function()
    dbg(I(self))
    local supportedBrowsers =
      { "Chromium", "Brave Browser Nightly", "Brave Browser Dev", "Brave Browser", "Brave Browser Beta", "Safari" }

    if self.browser and hs.fnutils.contains(supportedBrowsers, self.browser:name()) then
      dbg("(splitTab) %s", self.browser:name())
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(self.browser:name() or "", "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      self.browser:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if to_next_screen then
        dbg("(splitTab) to_next_screen: %s", C.displays.internal)
        self.browser:selectMenuItem({ "Window", fmt("Move to %s", C.displays.internal) })
        wm.place(POSITIONS.full)
      else
        wm.place(POSITIONS.halves.right)
      end
    else
      warn(fmt("[browser.splitTab] unsupported browser: %s", self.browser:name()))
    end
  end)
end

function obj.killTabsByDomain(domain)
  if obj.browser and hs.fnutils.contains(obj.browsers, obj.browser:name()) then
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. obj.browser:name() .. [[');
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

function obj:init()
  info(fmt("[INIT] %s", self.name))
  return self
end

function obj:start() return self end

function obj:stop() return self end

return obj:init()
