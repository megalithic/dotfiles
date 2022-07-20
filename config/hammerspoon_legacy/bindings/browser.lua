local log = hs.logger.new("[bindings.browser]", "debug")

local cache = {}
local M = { cache = cache }

-- Some utility functions for controlling current defined web browser.
-- Probably would work super similarly on Brave, Chrome and Safari, or any webkit
-- browser.
--
-- NOTE: May require you enable View -> Developer -> Allow Javascript from
-- Apple Events in your browser's menu (e.g. in Brave's menu).
--
--  Hat-tip to @evantravers: https://github.com/evantravers/hammerspoon/blob/master/brave.lua

local fn = require("hs.fnutils")

local runningBrowserName = fn.find(Config.preferred.browsers, function(browserName)
  return hs.application.get(browserName) ~= nil
end)

M.jump = function(url)
  hs.osascript.javascript([[
  (function() {
    var browser = Application(']] .. runningBrowserName .. [[');
    browser.activate();
    for (win of browser.windows()) {
      var tabIndex =
        win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
      if (tabIndex != -1) {
        win.activeTabIndex = (tabIndex + 1);
        win.index = 1;
      }
    }
  })();
  ]])
end

M.killTabsByDomain = function(domain)
  hs.osascript.javascript([[
  (function() {
    var browser = Application(']] .. runningBrowserName .. [[');
    browser.activate();
    for (win of browser.windows()) {
      for (tab of win.tabs()) {
        if (tab.url().match(/]] .. domain .. [[/)) {
          tab.close()
        }
      }
    }
  })();
  ]])
end

-- M.jump = function(url)
--   hs.osascript.javascript([[
--   (function() {
--     var brave = Application('Brave');
--     brave.activate();
--     for (win of brave.windows()) {
--       var tabIndex =
--         win.tabs().findIndex(tab => tab.url().match(/]] .. url .. [[/));
--       if (tabIndex != -1) {
--         win.activeTabIndex = (tabIndex + 1);
--         win.index = 1;
--       }
--     }
--   })();
--   ]])
-- end

-- module.killTabsByDomain = function(domain)
--   hs.osascript.javascript([[
--   (function() {
--     var brave = Application('Brave');
--     for (win of brave.windows()) {
--       for (tab of win.tabs()) {
--         if (tab.url().match(/]] .. string.gsub(domain, "/", "\\/") .. [[/)) {
--           tab.close()
--         }
--       }
--     }
--   })();
--   ]])
-- end

M.snip = function()
  local app_name = Config.preferred.browsers[1]
  log.wf("snipping with %s", app_name)

  -- https://stackoverflow.com/questions/19326368/iterate-over-lines-including-blank-lines
  local function magiclines(s)
    if s:sub(-1) ~= "\n" then
      s = s .. "\n"
    end
    return s:gmatch("(.-)\n")
  end

  -- Snip current highlight
  local win = hs.window.focusedWindow()

  -- get the window title
  local title = win:title():gsub("- Brave", ""):gsub("- Google Chrome", "")
  -- get the highlighted item
  hs.eventtap.keyStroke("command", "c")
  local highlight = hs.pasteboard.readString()
  local quote = ""
  for line in magiclines(highlight) do
    quote = quote .. "> " .. line .. "\n"
  end
  -- get the URL
  hs.eventtap.keyStroke("command", "l")
  hs.eventtap.keyStroke("command", "c")
  local url = hs.pasteboard.readString():gsub("?utm_source=.*", "")
  --
  local template = string.format(
    [[%s

%s
[%s](%s)]],
    title,
    quote,
    title,
    url
  )
  -- format and send to drafts
  hs.urlevent.openURL("drafts://x-callback-url/create?tag=links&text=" .. hs.http.encodeForQuery(template))
  hs.notify.show("Snipped!", "The snippet has been sent to Drafts", "")
end

M.split = function()
  -- Move current window to the left half

  require("bindings.snap").leftHalf()

  hs.timer.doAfter(100 / 1000, function()
    local browser = hs.appfinder.appFromName(Config.preferred.browsers[1])
    local moveTab = { "Tab", "Move Tab to New Window" }

    browser:selectMenuItem(moveTab)

    -- Move it to the right of the screen
    require("bindings.snap").rightHalf()
  end)
end

M.urlsTaggedWith = function(tag)
  return fn.filter(Config.domains, function(domain)
    return domain.tags and fn.contains(domain.tags, tag)
  end)
end

M.launch = function(list)
  fn.map(list, function(tag)
    fn.map(M.urlsTaggedWith(tag), function(site)
      hs.urlevent.openURL("http://" .. site.url)
    end)
  end)
end

M.kill = function(list)
  fn.map(list, function(tag)
    fn.map(M.urlsTaggedWith(tag), function(site)
      M.killTabsByDomain(site.url)
    end)
  end)
end

M.start = function()
  log.df("starting..")

  -- Snip current highlight text in browser and send to Drafts
  hs.hotkey.bind(Config.modifiers.ctrlShift, "s", function()
    M.snip()
  end)
end

M.stop = function()
  log.df("stopping..")
end

return M
