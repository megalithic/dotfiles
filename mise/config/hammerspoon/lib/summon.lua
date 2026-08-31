local obj = {}

obj.__index = obj
obj.name = "summon"

-- Helper to detect if string is a bundle ID (has dots like "com.apple.Safari")
-- vs an app name (like "Safari")
local function isBundleID(str)
  return str and str:find("%.") ~= nil
end

-- Get the aliased bundle ID (for wrapper apps that launch apps with different bundle IDs)
-- e.g., com.nix.brave-browser-nightly -> com.brave.Browser.nightly
local function getAliasedBundleID(bundleID)
  if C and C.bundleIdAliases and C.bundleIdAliases[bundleID] then
    return C.bundleIdAliases[bundleID]
  end
  return nil
end

-- Find app by bundle ID, checking aliases if needed
-- Returns the app if found by either the original or aliased bundle ID
local function findAppWithAlias(appHint)
  -- First try direct lookup
  local app = hs.application.find(appHint)
  if app then
    return app
  end

  -- If it's a bundle ID, try the alias
  if isBundleID(appHint) then
    local aliasedID = getAliasedBundleID(appHint)
    if aliasedID then
      app = hs.application.find(aliasedID)
      if app then
        return app
      end
    end
  end

  return nil
end

-- Launch or focus app using appropriate method based on identifier type.
-- opts.launchCommand (string or argv table) overrides the cold-start method:
-- LaunchServices forwards no command-line flags, so launchers that need them
-- (e.g. Helium's --remote-debugging-port=9223 via bin/helium-launch) spawn a
-- detaching launcher script instead. Callers only pass opts when the app is
-- not running; focus/cycle of a live app never respawns.
local function launchOrFocusApp(appHint, opts)
  local launchCommand = opts and opts.launchCommand
  if launchCommand then
    if type(launchCommand) == "string" then
      launchCommand = { launchCommand }
    end
    local args = { table.unpack(launchCommand, 2) }
    hs.task.new(launchCommand[1], nil, args):start()
    return
  end

  if isBundleID(appHint) then
    hs.application.launchOrFocusByBundleID(appHint)
  else
    hs.application.launchOrFocus(appHint)
  end
end

-- Get bundle ID from app hint (resolves app name to bundle ID if needed)
local function resolveBundleID(appHint)
  if isBundleID(appHint) then
    return appHint
  end
  -- Try to find the app and get its bundle ID
  local app = hs.application.find(appHint)
  return app and app:bundleID() or nil
end

-- Indicator canvas and timer for showing brief focus feedback
local indicatorCanvas = nil
local indicatorTimer = nil
local INDICATOR_COLOR = "#e39b7b" -- Match hypemode default
local INDICATOR_DURATION = 0.25

-- Show a brief indicator border around the focused window
local function showIndicator(win)
  if not win then
    return
  end

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
    strokeColor = { hex = INDICATOR_COLOR, alpha = 0.5 },
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
  local app = findAppWithAlias(appIdentifier)
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

local function usableWindows(app)
  local result = {}
  if not app then
    return result
  end
  for _, win in ipairs(app:allWindows() or {}) do
    local ok, standard = pcall(function()
      return win:isStandard()
    end)
    local visible = true
    pcall(function()
      visible = win:isVisible()
    end)
    if ok and standard and visible then
      table.insert(result, win)
    end
  end
  table.sort(result, function(a, b)
    return a:id() < b:id()
  end)
  return result
end

function obj.cycleWindows(appIdentifier, opts)
  local app = findAppWithAlias(appIdentifier)
  if not app then
    launchOrFocusApp(appIdentifier, opts)
    hs.timer.doAfter(0.3, function()
      local launchedApp = findAppWithAlias(appIdentifier)
      if launchedApp then
        showIndicator(launchedApp:focusedWindow() or launchedApp:mainWindow())
      end
    end)
    return
  end

  local wins = usableWindows(app)
  if #wins == 0 then
    obj.toggle(appIdentifier, nil, opts)
    return
  end

  -- Cycle only when the app is already frontmost AND has more than one
  -- window. Otherwise this is a plain app switch: activate and raise,
  -- never cycle (cycling with a single window forced double keypresses).
  local focused = hs.window.focusedWindow()
  local appIsFrontmost = focused and focused:application() and focused:application():bundleID() == app:bundleID()

  local target
  if appIsFrontmost and #wins > 1 then
    target = wins[1]
    for idx, win in ipairs(wins) do
      if win:id() == focused:id() then
        target = wins[(idx % #wins) + 1]
        break
      end
    end
  elseif appIsFrontmost then
    -- Single window and (apparently) already focused: don't cycle, but
    -- still activate/raise below — the focused-window read can be stale
    -- right after a switch, and re-activating is idempotent.
    target = focused
  else
    target = app:focusedWindow() or app:mainWindow() or wins[1]
  end

  app:activate(true)
  pcall(app.unhide, app)
  pcall(target.focus, target)
  hs.timer.doAfter(0.05, function()
    showIndicator(target)
  end)
end

-- Quickly move to and from a specific app
-- (Thanks Teije)
local previousApp = ""

-- REF: https://github.com/jhkuperus/dotfiles/blob/master/hammerspoon/app-management.lua
-- nicely swaps between target app/window to the previously focused app/window
-- appHint can be a bundle ID (e.g., "com.apple.Safari") or app name (e.g., "Safari")
-- Supports bundle ID aliases for wrapper apps (see C.bundleIdAliases)
function obj.switchToAndFromApp(appHint)
  local focusedWindow = hs.window.focusedWindow()
  local targetBundleID = resolveBundleID(appHint)
  -- Also check aliased bundle ID for comparison
  local aliasedBundleID = getAliasedBundleID(appHint)

  if focusedWindow == nil then
    launchOrFocusApp(appHint)
  else
    local focusedBundleID = focusedWindow:application():bundleID()
    local isTargetApp = (targetBundleID and focusedBundleID == targetBundleID)
      or (aliasedBundleID and focusedBundleID == aliasedBundleID)

    if isTargetApp then
      if previousApp == nil then
        hs.window.switcher.nextWindow()
      else
        previousApp:activate()
      end
    else
      previousApp = focusedWindow:application()
      launchOrFocusApp(appHint)
    end
  end
end

-- REF: https://github.com/octplane/hammerspoon-config/blob/master/init.lua#L105
-- +--- possibly more robust app toggler
-- appHint can be a bundle ID (e.g., "com.apple.Safari") or app name (e.g., "Safari")
-- Supports bundle ID aliases for wrapper apps (see C.bundleIdAliases)
function obj.toggle(appHint, shouldHide, opts)
  local app = findAppWithAlias(appHint)

  if not app then
    if appHint ~= nil then
      launchOrFocusApp(appHint, opts)
      -- Show indicator after app launches
      hs.timer.doAfter(0.3, function()
        local launchedApp = findAppWithAlias(appHint)
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
        if shouldHide then
          mainWin:application():hide()
        else
          -- Re-activate anyway: focused-window reads can be stale right
          -- after a switch; a no-op here would eat the keypress.
          mainWin:application():activate(true)
        end
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
        if shouldHide then
          app:hide()
        end
      else
        app:unhide()
        launchOrFocusApp(appHint)
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
