local log = hs.logger.new('[bindings.browser]', 'debug')

local cache  = {}
local module = { cache = cache }

-- Some utility functions for controlling current defined web browser.
-- Probably would work super similarly on Brave, Chrome and Safari, or any webkit
-- browser.
--
-- NOTE: May require you enable View -> Developer -> Allow Javascript from
-- Apple Events in your browser's menu (e.g. in Brave's menu).
--
--  Hat-tip to @evantravers: https://github.com/evantravers/hammerspoon/blob/master/brave.lua

local fn   = require('hs.fnutils')

local runningBrowserName = fn.find(watchers.urlPreference, function(browserName)
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
    fn.map(module.urlsTaggedWith(tag), function(site) module.killTabsByDomain(site.url) end)
  end)
end

module.killTabsByDomain = function(domain)
  if runningBrowserName ~= nil and domain ~= nil then
    hs.osascript.javascript([[
    (function() {
      var browser = Application(']] .. runningBrowserName .. [[');
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
end

module.start = function()
  log.df("starting..")
end

module.stop = function()
  log.df("stopping..")
end


return module
