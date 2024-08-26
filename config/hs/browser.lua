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
    dbg(url, true)
    local _status, hasTab, _descriptor = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. app:name() .. [[');
      const foundTab = browser.windows().filter((win) => {
        const tabIndex = win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
        return tabIndex !== -1
      })

      return foundTab.length > 0;
    })();
    ]])

    return hasTab
  end

  return false
end

function obj.jump(url)
  local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

  if app and enum.contains(supportedBrowsers, app:name()) then
    -- win.tabs().findIndex(tab => tab.url().match(/]] .. string.gsub(url, "/", "\\/") .. [[/));
    -- win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
    local success, jumpedTab, output = hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. app:name() .. [[');
      var foundTabUrl = "";
      browser.activate();
      const foundTab = browser.windows().find((win) => {
        const tabIndex = win.tabs().findIndex(tab =>  {
          if (tab.url().match(/]] .. url .. [[/) !== null)
            foundTabUrl = tab.url();
          return tab.url().match(/]] .. url .. [[/) !== null;
        });
        if (tabIndex !== -1) win.activeTabIndex = (tabIndex + 1);

        return tabIndex !== -1
      })

      return foundTabUrl;
    })();
    ]])

    info(fmt("[%s.jump] %s (%s)", obj.name, app:name(), jumpedTab or url))
    return jumpedTab
  else
    return nil
  end
end

function obj:splitTab(to_next_screen)
  -- Move current window to the left half
  if not to_next_screen then wm.place(POSITIONS.halves.left) end

  hs.timer.doAfter(0.25, function()
    local app = hs.application.get(BROWSER) or hs.application.frontmostApplication()

    if app and enum.contains(supportedBrowsers, app:name()) then
      local moveTab = { "Tab", "Move Tab to New Window" }
      if string.match(app:name() or "", "Safari") then moveTab = { "Window", "Move Tab to New Window" } end
      app:selectMenuItem(moveTab)

      -- Move the split tab to the right of the screen
      if to_next_screen then
        app:selectMenuItem({ "Window", fmt("Move to %s", DISPLAYS.internal) })
        wm.place(POSITIONS.full)
        info(fmt("[%s.splitTab] %s (next screen, full)", obj.name, app:name()))
      else
        wm.place(POSITIONS.halves.right)
        info(fmt("[%s.splitTab] %s (same screen, half)", obj.name, app:name()))
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

function obj.updateBrowserTabBar()
  local previousCount = -1
  local countDir = "-"
  local openTabsBar = hs.menubar.new(true)

  local function updateOpenTabs()
    local count = obj.tabCount()

    if count ~= previousCount then
      if count > previousCount and previousCount ~= -1 then countDir = "▲" end
      if count < previousCount then countDir = "▼" end

      previousCount = count
    end

    TARGET = 50
    styled = hs.styledtext.new({
      "  " .. count .. "  " .. countDir .. "  ",
      tonumber(count) > TARGET and {
        starts = 2,
        attributes = {
          backgroundColor = { red = 1 },
          color = { white = 1 },
        },
      },
    })

    openTabsBar:setTitle(styled)
  end

  if openTabsBar then
    icon = [[ASCII:
    ............
    ............
    ............
    ..C......D..
    ............
    ............
    ............
    A.B......E.F
    H..........I
    K..........L
    ............
    ............]]
    openTabsBar:setIcon(icon)

    -- if you don't assign to a global the timer will be garbage collected
    tabTimer = hs.timer.doEvery(3, updateOpenTabs)
  end
end

function obj:init()
  info(fmt("[INIT] %s", self.name))
  -- self.updateBrowserTabBar()

  return self
end

function obj:start() return self end

function obj:stop() return self end

return obj:init()
