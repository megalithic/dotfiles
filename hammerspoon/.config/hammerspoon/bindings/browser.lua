local log = hs.logger.new("[bindings.browser]", "debug")

local cache = {}
local module = { cache = cache }

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

module.jump = function(url)
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

module.killTabsByDomain = function(domain)
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

module.snip = function()
  local app_name = config.preferred.browsers[1]
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

module.split = function()
  -- Move current window to the left half

  require("bindings.snap").leftHalf()

  hs.timer.doAfter(100 / 1000, function()
    -- -- Pop out the current tab
    -- hs.application.launchOrFocus('/Applications/Google Chrome.app')

    -- local chrome = hs.appfinder.appFromName("Google Chrome")
    local browser = hs.appfinder.appFromName(Config.preferred.browsers[1])
    local moveTab = { "Tab", "Move Tab to New Window" }

    browser:selectMenuItem(moveTab)

    -- Move it to the right of the screen
    require("bindings.snap").rightHalf()
  end)
end

module.urlsTaggedWith = function(tag)
  return fn.filter(config.domains, function(domain)
    return domain.tags and fn.contains(domain.tags, tag)
  end)
end

module.launch = function(list)
  fn.map(list, function(tag)
    fn.map(module.urlsTaggedWith(tag), function(site)
      hs.urlevent.openURL("http://" .. site.url)
    end)
  end)
end

module.kill = function(list)
  fn.map(list, function(tag)
    fn.map(module.urlsTaggedWith(tag), function(site)
      module.killTabsByDomain(site.url)
    end)
  end)
end

module.start = function()
  log.df("starting..")
end

module.stop = function()
  log.df("stopping..")
end

return module
