local Settings = require("hs.settings")
local Window = require("hs.window")
local Application = require("hs.application")

local obj = {}

obj.__index = obj
obj.name = "launcher"

local function forceFocus(win)
  -- this flickers
  -- win:application():activate()
  win:becomeMain()
  win:raise():focus()
  -- highlightWindow()
end

-- activate frontmost window if exists
obj.activateFrontmost = function()
  local frontmostWindow = Window.frontmostWindow()
  if frontmostWindow then frontmostWindow:raise():focus() end
end

obj.focusOnly = function(appIdentifier)
  local app = Application.find(appIdentifier)
  local appBundleID = app and (app:bundleID() or appIdentifier)

  if app and appIdentifier and appBundleID then app:activate() end
end

-- REF: https://github.com/octplane/hammerspoon-config/blob/master/init.lua#L105
-- +--- possibly more robust app toggler
obj.toggle = function(appIdentifier, shouldHide)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = Application.find(appIdentifier)
  local appBundleID = app and app:bundleID() or appIdentifier

  if not app then
    if appIdentifier ~= nil then
      Application.launchOrFocusByBundleID(appBundleID)
    else
    end
  else
    local mainWin = app:mainWindow()

    if mainWin then
      if mainWin == Window.focusedWindow() then
        if shouldHide then mainWin:application():hide() end
      else
        mainWin:application():activate(true)
        mainWin:application():unhide()
        mainWin:focus()
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      if app:focusedWindow() == Window.focusedWindow() then
        if shouldHide then app:hide() end
      else
        app:unhide()
        Application.launchOrFocusByBundleID(appBundleID)
      end
    end
  end
end

-- FIXME: DEPRECATE
-- force application launch or focus
obj.forceLaunchOrFocus = function(appName)
  local appInstance = Application.get(appName)
  local isRunning = appInstance and appInstance:isRunning()
  local focusTimeout = isRunning and 0.05 or 1.5

  -- first focus/launch with hammerspoon
  Application.launchOrFocus(appName)

  -- clear timer if exists
  if obj.launchTimer then obj.launchTimer:stop() end

  -- wait for window to appear and try hard to show the window
  obj.launchTimer = hs.timer.doAfter(focusTimeout, function()
    local frontmostApp = Application.frontmostApplication()
    local frontmostWindows = hs.fnutils.filter(frontmostApp:allWindows(), function(win) return win:isStandard() end)

    -- break if this app is not frontmost (when/why?)
    if frontmostApp:title() ~= appName then return end

    if #frontmostWindows == 0 then
      if appName == "Hyper" then
        -- otherwise some other Hyper window gets focused
        hs.eventtap.keyStroke({ "cmd" }, "n")
      elseif frontmostApp:findMenuItem({ "Window", appName }) then
        -- check if there's app name in window menu (Calendar, Messages, etc...)
        -- select it, usually moves to space with this window
        frontmostApp:selectMenuItem({ "Window", appName })
      else
        -- otherwise send cmd-n to create new window
        hs.eventtap.keyStroke({ "cmd" }, "n")
      end
    end
  end)
end

-- FIXME: DEPRECATE
-- smart app launch or focus or cycle windows
obj.smartLaunchOrFocus = function(launchApps)
  local frontmostWindow = Window.frontmostWindow()
  local runningWindows = {}

  launchApps = type(launchApps) == "table" and launchApps or { launchApps }

  -- filter running applications by apps array
  local runningApps = hs.fnutils.map(launchApps, function(launchApp) return Application.get(launchApp) end)
  if runningApps then
    -- create table of sorted windows per application
    hs.fnutils.each(runningApps, function(runningApp)
      local standardWindows = hs.fnutils.filter(runningApp:allWindows(), function(win) return win:isStandard() end)

      -- sort by id, so windows don't jump randomly every time
      if standardWindows then
        table.sort(standardWindows, function(a, b) return a:id() > b:id() end)
        -- concat with all running windows
        hs.fnutils.concat(runningWindows, standardWindows)
      end
    end)

    if #runningApps == 0 then
      -- if no apps are running then launch first one in list
      obj.forceLaunchOrFocus(launchApps[1])
    elseif #runningWindows == 0 then
      -- if some apps are running, but no windows - force create one
      obj.forceLaunchOrFocus(runningApps[1]:name())
    else
      -- check if one of windows is already focused
      local currentIndex = hs.fnutils.indexOf(runningWindows, frontmostWindow)

      if not currentIndex then
        -- if none of them is selected focus the first one
        forceFocus(runningWindows[1])
      else
        -- otherwise cycle through all the windows
        local newIndex = currentIndex + 1
        if newIndex > #runningWindows then newIndex = 1 end

        forceFocus(runningWindows[newIndex])
      end
    end
  end
end

return obj
