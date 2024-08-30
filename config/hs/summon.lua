local obj = {}

obj.__index = obj
obj.name = "summon"

function obj.focus(appIdentifier)
  local app = hs.application.find(appIdentifier)
  local appBundleID = app and (app:bundleID() or appIdentifier)

  if app and appIdentifier and appBundleID then app:activate() end
end

-- REF: https://github.com/octplane/hammerspoon-config/blob/master/init.lua#L105
-- +--- possibly more robust app toggler
function obj.toggle(appIdentifier, shouldHide)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(appIdentifier)
  local appBundleID = app and app:bundleID() or appIdentifier

  if not app then
    if appIdentifier ~= nil then hs.application.launchOrFocusByBundleID(appBundleID) end
  else
    local mainWin = app:mainWindow()

    if mainWin ~= nil then
      if mainWin == hs.window.focusedWindow() then
        if shouldHide then mainWin:application():hide() end
      else
        if mainWin:application() ~= nil then
          mainWin:application():activate(true)
          mainWin:application():unhide()
          mainWin:focus()
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
