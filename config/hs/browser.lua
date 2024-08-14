local wm = require("wm")
local enum = require("hs.fnutils")

local obj = {}
obj.__index = obj
obj.name = "browser"
obj.debug = false

local supportedBrowsers =
  { "Chromium", "Brave Browser Nightly", "Brave Browser Dev", "Brave Browser", "Brave Browser Beta", "Safari" }

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", "browser", str)
  if true then return print(string.format(str, ...)) end
end

function obj.tabCount()
  local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

  if app and enum.contains(supportedBrowsers, app:name()) then
    local _bool, count, _desc = hs.osascript.javascript([[
      const browser = new Application("/Applications/]] .. app:name() .. [[.app")
      let count = 0;

      if(browser.running())
      for (i in browser.windows) count += browser.windows[i].tabs.length;

      count
    ]])
    return count
  end

  return nil
end

function obj.hasTab(url)
  local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

  if app and enum.contains(supportedBrowsers, app:name()) then
    url = string.gsub(url, "/", "\\/")
    local _status, returnedObj, _descriptor = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. app:name() .. [[');
      const foundTab = browser.windows().filter((win) => {
        const tabIndex = win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
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
  local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

  if app and enum.contains(supportedBrowsers, app:name()) then
    info("(jump) %s", app:name())

    -- win.tabs().findIndex(tab => tab.url().match(/]] .. string.gsub(url, "/", "\\/") .. [[/));
    -- win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
    local _success, object, _output = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. app:name() .. [[');
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

  hs.timer.doAfter(0.25, function()
    local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

    if app and enum.contains(supportedBrowsers, app:name()) then
      dbg("(splitTab) %s", app:name())
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(app:name() or "", "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      app:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if to_next_screen then
        dbg("(splitTab) to_next_screen: %s", DISPLAYS.internal)
        app:selectMenuItem({ "Window", fmt("Move to %s", DISPLAYS.internal) })
        wm.place(POSITIONS.full)
      else
        wm.place(POSITIONS.halves.right)
      end
    else
      warn(fmt("[browser.splitTab] unsupported browser: %s", app:name()))
    end
  end)
end

function obj.killTabsByDomain(domain)
  local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()
  if app and enum.contains(supportedBrowsers, app:name()) then
    -- if (tab.url().match(/]] .. string.gsub(domain, "/", "\\/") .. [[/)) {
    -- if (tab.url().match(/]] .. domain .. [[/)) {
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. app:name() .. [[');
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
