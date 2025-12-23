local obj = {}

obj.__index = obj
obj.name = "summon"

function obj.focus(appIdentifier)
  local app = hs.application.find(appIdentifier)
  local appBundleID = app and (app:bundleID() or appIdentifier)

  if app and appIdentifier and appBundleID then app:activate() end
end

-- Quickly move to and from a specific app
-- (Thanks Teije)
local previousApp = ""

-- REF: https://github.com/jhkuperus/dotfiles/blob/master/hammerspoon/app-management.lua
-- nicely swaps between target app/window to the previously focused app/window
function obj.switchToAndFromApp(bundleID)
  local focusedWindow = hs.window.focusedWindow()

  if focusedWindow == nil then
    hs.application.launchOrFocusByBundleID(bundleID)
  elseif focusedWindow:application():bundleID() == bundleID then
    if previousApp == nil then
      hs.window.switcher.nextWindow()
    else
      previousApp:activate()
    end
  else
    previousApp = focusedWindow:application()
    hs.application.launchOrFocusByBundleID(bundleID)
  end
end

-- REF: https://github.com/octplane/hammerspoon-config/blob/master/init.lua#L105
-- +--- possibly more robust app toggler
function obj.toggle(appId, shouldHide)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(appId)
  local appBundleID = app and app:bundleID() or appId

  if not app then
    if appId ~= nil then hs.application.launchOrFocusByBundleID(appBundleID) end
  else
    local mainWin = app:mainWindow()

    if mainWin ~= nil then
      if mainWin == hs.window.focusedWindow() then
        if shouldHide then mainWin:application():hide() end
      else
        if mainWin:application() ~= nil then
          -- always activate the entire application (brings all windows to the front);
          mainWin:application():activate(true)
          pcall(mainWin:application():unhide())
          pcall(mainWin:focus())
        end
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      if app:focusedWindow() == hs.window.focusedWindow() then
        if shouldHide then app:hide() end
      else
        app:unhide()
        hs.application.launchOrFocusByBundleID(appBundleID)
      end
    end
  end
end

return obj
