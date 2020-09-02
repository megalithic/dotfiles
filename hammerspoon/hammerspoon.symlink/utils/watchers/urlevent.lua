local log = hs.logger.new('[urlevent]', 'debug')

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
  hs.urlevent.httpCallback = function(scheme, host, _, fullURL)
    local modifiers          = hs.eventtap.checkKeyboardModifiers()
    local should_focus_calling_app = modifiers['cmd']

    local running_browser_name = fn.find(watchers.urlPreference, function(browser_name)
      return hs.application.get(browser_name) ~= nil
    end)

    local current_app  = hs.application:frontmostApplication()
    local current_browser = hs.application.get(running_browser_name)

    log.f("%s -> %s [%s, %s, focus: %s, %s]", current_browser:name(), fullURL, scheme, host, should_focus_calling_app, current_app:bundleID())

    hs.applescript.applescript(template([[
      tell application "{APP_NAME}"
        {ACTIVATE}
        open location "{URL}"
      end tell
    ]], {
      APP_NAME = running_browser_name,
      URL      = fullURL,
      ACTIVATE = not should_focus_calling_app and 'activate' or '' -- 'activate' brings to front if cmd is clicked
    }))

    -- focus back the current app
    if should_focus_calling_app and current_app:isFrontmost() then
      current_app:activate()
    end

    -- hs.urlevent.openURLWithBundle(fullURL, current_browser:bundleID())

    -- focus back the current app (or browser)
    -- local activationApp = current_browser

    -- if not should_focus_calling_app and not currentApp:isFrontmost() then
    -- if not should_focus_calling_app then
    --   activationApp = currentApp
    -- end

    -- activationApp:activate()

    -- log.df("urlevent::activate -> %s", activationApp:bundleID())
  end
end

M.stop = function()
  hs.urlevent.httpCallback = nil
end

return M
