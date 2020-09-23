local log = hs.logger.new('[urlevent]', 'warning')

local template = require('ext.template')
local fn = require('hs.fnutils')

local M = {}

-- watch for http and https events and open in currently running browser instead of default one
-- click with 'cmd' to open in background, otherwise opens with focus
--  `watchers` globally defined in root init.lua
M.start = function()
  hs.urlevent.setDefaultHandler('http')

  -- REF: handling different urls:
  --  https://github.com/trws/dotfiles/blob/master/hammerspoon/init.lua#L66-L85
  hs.urlevent.httpCallback = function(scheme, host, _, full_url)
    local modifiers          = hs.eventtap.checkKeyboardModifiers()
    local should_refocus = modifiers['cmd']

    local running_browser_name = fn.find(watchers.urlPreference, function(browser_name)
      return hs.application.get(browser_name) ~= nil
    end)

    local current_app  = hs.application.frontmostApplication()
    local current_browser = hs.application.get(running_browser_name)

    log.f("%s -> %s [%s, %s, focus? %s, %s (frontmost? %s)]", current_browser:name(), full_url, scheme, host, should_refocus, current_app:bundleID(), current_app:isFrontmost())

    hs.applescript.applescript(template([[
      tell application "{APP_NAME}"
        open location "{URL}"
      end tell
    ]], {
      APP_NAME = running_browser_name,
      URL      = full_url
    }))

    -- focus back the current app
    if should_refocus then
      current_app:activate()
      log.df("urlevent::activated -> %s", current_app:bundleID())
    end
  end
end

M.stop = function()
  hs.urlevent.httpCallback = nil
end

return M
