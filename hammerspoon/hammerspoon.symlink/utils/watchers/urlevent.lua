local log = hs.logger.new('[urlevent]', 'debug')

local template = require('ext.template')
local fn   = require('hs.fnutils')

local module   = {}

-- watch for http and https events and open in currently running browser instead of default one
-- click with 'cmd' to open in background, otherwise opens with focus
--  `watchers` globally defined in root init.lua
module.start = function()
  hs.urlevent.setDefaultHandler('http')

  -- REF: handling different urls:
  --  https://github.com/trws/dotfiles/blob/master/hammerspoon/init.lua#L66-L85
  hs.urlevent.httpCallback = function(scheme, host, params, fullURL)
    local modifiers          = hs.eventtap.checkKeyboardModifiers()
    local shouldFocusBrowser = not modifiers['cmd']

    local runningBrowserName = fn.find(watchers.urlPreference, function(browserName)
      return hs.application.get(browserName) ~= nil
    end)

    local currentApp  = hs.application:frontmostApplication()
    local currentBrowser = hs.application.get(runningBrowserName)

    log.f("urlevent::%s -> %s [%s, %s, %s]", currentBrowser:name(), fullURL, scheme, host, hs.inspect(params), currentApp:bundleID())

    hs.applescript.applescript(template([[
      tell application "{APP_NAME}"
        {ACTIVATE}
        open location "{URL}"
      end tell
    ]], {
      APP_NAME = runningBrowserName,
      URL      = fullURL,
      ACTIVATE = shouldFocusBrowser and 'activate' or '' -- 'activate' brings to front if cmd is clicked
    }))

    -- hs.urlevent.openURLWithBundle(fullURL, currentBrowser:bundleID())

    -- focus back the current app (or browser)
    -- local activationApp = currentBrowser

    -- if not shouldFocusBrowser and not currentApp:isFrontmost() then
    -- if not shouldFocusBrowser then
    --   activationApp = currentApp
    -- end

    -- activationApp:activate()

    -- log.df("urlevent::activate -> %s", activationApp:bundleID())
  end
end

module.stop = function()
  hs.urlevent.httpCallback = nil
end

return module
