local obj = {}

obj.__index = obj
obj.name = "summon"

-- Indicator canvas and timer for showing brief focus feedback
local indicatorCanvas = nil
local indicatorTimer = nil
local INDICATOR_COLOR = "#e39b7b"  -- Match hypemode default
local INDICATOR_DURATION = 0.75

-- Show a brief indicator border around the focused window
local function showIndicator(win)
  if not win then return end
  
  -- Clean up existing indicator
  if indicatorTimer then
    indicatorTimer:stop()
    indicatorTimer = nil
  end
  if indicatorCanvas then
    indicatorCanvas:delete()
    indicatorCanvas = nil
  end
  
  local frame = win:frame()
  
  indicatorCanvas = hs.canvas.new(frame)
  indicatorCanvas:appendElements({
    type = "rectangle",
    action = "stroke",
    strokeWidth = 3.0,
    strokeColor = { hex = INDICATOR_COLOR, alpha = 0.9 },
    roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
  })
  indicatorCanvas:level(hs.canvas.windowLevels.floating + 1)
  indicatorCanvas:behavior(hs.canvas.windowBehaviors.transient)
  indicatorCanvas:show()
  
  -- Auto-hide after duration
  indicatorTimer = hs.timer.doAfter(INDICATOR_DURATION, function()
    if indicatorCanvas then
      indicatorCanvas:delete()
      indicatorCanvas = nil
    end
    indicatorTimer = nil
  end)
end

function obj.focus(appIdentifier)
  local app = hs.application.find(appIdentifier)
  local appBundleID = app and (app:bundleID() or appIdentifier)

  if app and appIdentifier and appBundleID then
    app:activate()
    -- Show indicator after brief delay for window to focus
    hs.timer.doAfter(0.05, function()
      local win = app:focusedWindow() or app:mainWindow()
      showIndicator(win)
    end)
  end
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
    if appId ~= nil then
      hs.application.launchOrFocusByBundleID(appBundleID)
      -- Show indicator after app launches
      hs.timer.doAfter(0.3, function()
        local launchedApp = hs.application.find(appBundleID)
        if launchedApp then
          local win = launchedApp:focusedWindow() or launchedApp:mainWindow()
          showIndicator(win)
        end
      end)
    end
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
          -- Show indicator
          hs.timer.doAfter(0.05, function()
            showIndicator(mainWin)
          end)
        end
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      if app:focusedWindow() == hs.window.focusedWindow() then
        if shouldHide then app:hide() end
      else
        app:unhide()
        hs.application.launchOrFocusByBundleID(appBundleID)
        -- Show indicator
        hs.timer.doAfter(0.1, function()
          local win = app:focusedWindow()
          showIndicator(win)
        end)
      end
    end
  end
end

return obj
