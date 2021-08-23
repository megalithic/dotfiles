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
local template = require("ext.template")
local alert = require("ext.alert")

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
	-- TODO: https://github.com/evantravers/hammerspoon-config/blob/master/init.lua#L248-L281
	local app_name = config.preferred.browsers[1]
	log.wf("snipping with appName -> %s", app_name)

	hs.osascript.applescript(template(
		[[
    -- stolen from: https://gist.github.com/gabeanzelini/1931128eb233b0da8f51a8d165b418fa

    if (count of currentSelection()) is greater than 0 then
      set str to "tags: #link\n\n" & currentTitle() & "\n\n> " & currentSelection() & "\n\n[" & currentTitle() & "](" & currentUrl() & ")"
      tell application "Drafts"
        make new draft with properties {content:str, tags: {"link"}}
      end tell
    end if

    on currentUrl()
      tell application "{APP_NAME}" to get the URL of the active tab in the first window
    end currentUrl

    on currentSelection()
      tell application "{APP_NAME}" to execute front window's active tab javascript "getSelection().toString();"
    end currentSelection

    on currentTitle()
      tell application "{APP_NAME}" to get the title of the active tab in the first window
    end currentTitle
  ]],
		{ APP_NAME = app_name }
	))

	hs.notify.show("Snipped!", "The snippet has been sent to Drafts", "")
	alert.show({ text = "Snipped! The url and snippet have been sent to Drafts" })
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
