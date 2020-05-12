local template = require('ext.template')
local module   = {}

-- watch for http and https events and open in currently running browser instead of default one
-- click with 'cmd' to open in background, otherwise opens with focus
module.start = function()
  hs.urlevent.setDefaultHandler('http')

  hs.urlevent.httpCallback = function(_, _, _, fullURL)
    local modifiers          = hs.eventtap.checkKeyboardModifiers()
    local shouldFocusBrowser = not modifiers['cmd']

    local runningBrowser = hs.fnutils.find(watchers.urlPreference, function(browserName)
      return hs.application.get(browserName) ~= nil
    end)

    local browserName = runningBrowser or watchers.urlPreference[1]
    local currentApp  = hs.application:frontmostApplication()

    hs.applescript.applescript(template([[
      tell application "{APP_NAME}"
        {ACTIVATE}
        open location "{URL}"
      end tell
    ]], {
      APP_NAME = browserName,
      URL      = fullURL,
      ACTIVATE = shouldFocusBrowser and 'activate' or '' -- 'activate' brings to front if cmd is clicked
    }))

    -- focus back the current app
    if not shouldFocusBrowser and not currentApp:isFrontmost() then
      currentApp:activate()
    end
  end
end

module.stop = function()
  hs.urlevent.httpCallback = nil
end

return module
