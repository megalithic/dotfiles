-----------------------------------------------------------------------------------
--/ events /--
-----------------------------------------------------------------------------------

local events = {}

-- :: imports/requires
local config = require 'config'
local utils = require 'utils'
local wf = hs.window.filter
local eventsWatcher = hs.uielement.watcher
local usbConfig_laptop = require('usb-config-laptop')

-- :: globals
local watchers = {}
local globalAppWatcher = nil
local wifiWatcher = nil
local usbWatcher = nil
local caffeinateWatcher = nil
local screenCount = #hs.screen.allScreens()
local windowBorder = nil


-- window filter event handlers
----------------------------------------------------------------------------
function drawWindowBorder (win)
  -- clean up existing borders
  if windowBorder ~= nil then
    windowBorder:delete()
  end

  local ignoredWindows = utils.Set {'iTerm2', 'Electron Helper', 'TotalFinderCrashWatcher', 'CCXProcess', 'Adobe CEF Helper', 'Hammerspoon'}

  -- avoid drawing borders on "odd" windows, including iTerm2, Contexts, etc
  if win == nil or not utils.canManageWindow(win) or ignoredWindows[win:application():name()] then return end

  local topLeft = win:topLeft()
  local size = win:size()

  windowBorder = hs.drawing.rectangle(hs.geometry.rect(topLeft['x'], topLeft['y'], size['w'], size['h']))

  windowBorder:setStrokeColor({["red"]=.2,["blue"]=.2,["green"]=.1,["alpha"]=.5})
  windowBorder:setRoundedRectRadii(6.0, 6.0)
  windowBorder:setStrokeWidth(2)
  windowBorder:setStroke(true)
  windowBorder:setFill(false)
  windowBorder:setLevel("floating")
  windowBorder:show()
end

function handleCreated (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleDestroyed (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleFocused (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s (%s)', eventType, win:title(), appName, hs.application(appName):bundleID())
  -- drawWindowBorder(win)
end

function handleMoved (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleUnfocused (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleOnScreen (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleNotOnScreen (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end

function handleNotVisible (win, appName, eventType)
  utils.log.df('[wf] event "%s"; %s for %s', eventType, win:title(), appName)
  -- drawWindowBorder(win)
end


-- window filter subscriptions
----------------------------------------------------------------------------
-- allWindows = wf.new(nil, 'allWindows')
-- allWindows:subscribe(wf.windowCreated, handleCreated)
-- allWindows:subscribe(wf.windowDestroyed, handleDestroyed)
-- allWindows:subscribe(wf.windowFocused, handleFocused)
-- allWindows:subscribe(wf.windowMoved, handleMoved)
-- allWindows:subscribe(wf.windowUnfocused, handleUnfocused)
-- allWindows:subscribe(wf.windowOnScreen, handleOnScreen)
-- allWindows:subscribe(wf.windowNotOnScreen, handleNotOnScreen)
-- allWindows:subscribe(wf.windowNotVisible, handleNotVisible)
-- allWindows:subscribe(wf.windowsChanged, handleWindowsChanged)


-- event handlers
----------------------------------------------------------------------------
function handleGlobalAppEvent(name, eventType, app)
  if eventType == hs.application.watcher.launched then
    utils.log.df('[global] app event; launched %s', app:bundleID())
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  elseif eventType == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    utils.log.df('[global] app event; terminated PID %d', pid)
    unwatchApp(pid)
  end
end

function handleAppEvent(element, event)
  if event == eventsWatcher.windowCreated then
    if pcall(function()
      utils.log.df('[app] event; window %s created for %s', element:id(), element:application():bundleID())
    end) then
      watchWindow(element)
    else
      utils.log.wf('[error] app error; thrown trying to access element (%s) in handleAppEvent', element)
    end
  else
    utils.log.wf('[error] app error; unexpected app event (%d) received', event)
  end
end

function handleWindowEvent(window, event, watcher, info)
  utils.log.df('[window] event; new window event (%s) for %s (%s)', event, window:application():bundleID(), info.id)

  if event == eventsWatcher.elementDestroyed then
    utils.log.df('[window] event; %s destroyed for %s', info.id, window:application():bundleID())
    watcher:stop()
    watchers[info.pid].windows[info.id] = nil
  else
    utils.log.wf('[error] window error; unexpected window event (%d) received', event)
  end
end

function handleScreenEvent()
  -- Make sure that something noteworthy (display count) actually
  -- changed. We no longer check geometry because we were seeing spurious
  -- events.
  local screens = hs.screen.allScreens()

  utils.log.df('[screen] event; new screens (%s), previous screens (%s)', #screens, screenCount)

  if #screens ~= screenCount then
    screenCount = #screens
    config.applyLayout(screenCount)
  end
end

function watchApp(app)
  local pid = app:pid()
  if watchers[pid] or app:bundleID() == 'org.hammerspoon.Hammerspoon' or app:bundleID() == 'com.contextsformac.Contexts' then
    utils.log.wf('[warning] app warning; attempted watch for already-watched app PID %d', pid)
    return
  end

  -- Watch for new windows.
  local watcher = app:newWatcher(handleAppEvent)
  watchers[pid] = {
    watcher = watcher,
    windows = {},
  }
  watcher:start({eventsWatcher.windowCreated})

  -- Watch already-existing windows.
  for _, window in pairs(app:allWindows()) do
    watchWindow(window)
  end
end

function unwatchApp(pid)
  local appWatcher = watchers[pid]
  if not appWatcher then
    utils.log.wf('[warning] app warning; attempted unwatch for unknown app PID %d', pid)
    return
  end

  appWatcher.watcher:stop()
  for _, watcher in pairs(appWatcher.windows) do
    watcher:stop()
  end
  watchers[pid] = nil
end

function watchWindow(window)
  local application = window:application()
  local bundleID = application:bundleID()
  local pid = application:pid()
  local windows = watchers[pid].windows
  if utils.canManageWindow(window) then

    -- Do initial layout-handling.
    local bundleID = application:bundleID()
    local id = window:id()

    if config.layout[bundleID] then
      utils.log.df('[window] event; watching %s (window %s, ID %s, %s windows) and applying layout for window/app', bundleID, window:title(), id, utils.windowCount(application))
      config.layout[bundleID](window)
    end

    -- Watch for window-closed events.
    if id then
      if not windows[id] then
        local watcher = window:newWatcher(handleWindowEvent, {
          id = id,
          pid = pid,
        })
        windows[id] = watcher
        watcher:start({eventsWatcher.elementDestroyed})
      end
    end
  else
    utils.log.df('[window] event; unable to watch unmanageable %s (window %s, ID %s, %s windows)', bundleID, window:title(), id, utils.windowCount(application))
  end
end

-- WIFI
function handleWifiEvent ()
  newSSID = hs.wifi.currentNetwork()
  local homeSSID = config.homeSSID
  local lastSSID = config.lastSSID

  utils.log.df('[wifi] event; old SSID (%s), new SSID (%s)', lastSSID or "nil", newSSID or "nil")

  if newSSID == homeSSID and lastSSID ~= homeSSID then
    -- home_arrived()
  elseif newSSID ~= homeSSID and lastSSID == homeSSID then
    -- home_departed()
  end

  lastSSID = newSSID
end

-- USB
function handleUsbEvent (data)
  utils.log.df('[usb] event; raw data %s', hs.inspect(data))
end

-- CAFFEINATE
function handleCaffeinateEvent (eventType)
  utils.log.df('[caffeine] event; event type %s', eventType)

  if (eventType == hs.caffeinate.watcher.screensDidSleep) then
    -- turn off office lamp
    utils.log.df('[caffeine] event; attempting to turn off office lamp')
    hs.execute('~/.dotfiles/bin/hs-to-ha script.hammerspoon_office_lamp_off', true)
  elseif (eventType == hs.caffeinate.watcher.screensDidWake) then
    -- turn on office lamp
    utils.log.df('[caffeine] event; attempting to turn on office lamp')
    hs.execute('~/.dotfiles/bin/hs-to-ha script.hammerspoon_office_lamp_on', true)

    config.applyLayout(2)
  end
end


-- INIT ALL THE EVENTS
function events.initEventHandling ()
  utils.log.df('[init] event; initializing watchers')

  -- Watch for screen changes
  screenWatcher = hs.screen.watcher.new(handleScreenEvent)
  screenWatcher:start()

  -- Watch for application-level events
  globalAppWatcher = hs.application.watcher.new(handleGlobalAppEvent)
  globalAppWatcher:start()

  local ignoredApps = utils.Set {'org.hammerspoon.Hammerspoon', 'com.contextsformac.Contexts'}

  -- Watch already-running applications
  local apps = hs.application.runningApplications()
  for _, app in pairs(apps) do
    -- if not ignoredApps(app:bundleID()) then
    if app:bundleID() ~= 'org.hammerspoon.Hammerspoon' or app:bundleID() ~= 'com.contextsformac.Contexts' then
      watchApp(app)
    end
  end

  -- Only init these watchers for my laptop (replibook, SMesserBook, etc)
  if (config.hostname ~= 'replibox') then
    -- Watch for wifi/ssid changes
    wifiWatcher = hs.wifi.watcher.new(handleWifiEvent)
    wifiWatcher:start()

    -- usb watcher for laptop, specifically
    usbConfig_laptop.init()
  end

  -- Only init these watchers for my desktop
  if (config.hostname == 'replibox') then
    -- usb watcher for desktop, specifically
    usbWatcher = hs.usb.watcher.new(handleUsbEvent)
    usbWatcher:start()
  end

  -- Watch for screen energy mode changes
  caffeinateWatcher = hs.caffeinate.watcher.new(handleCaffeinateEvent)
  caffeinateWatcher:start()

  config.applyLayout()
end

-- TEAR DOWN ALL THE EVENTS
function events.tearDownEventHandling ()
  utils.log.df('[teardown] event; tearing down watchers')

  globalAppWatcher:stop()
  globalAppWatcher = nil

  for pid, _ in pairs(watchers) do
    unwatchApp(pid)
  end

  screenWatcher:stop()
  screenWatcher = nil

  if (config.hostname ~= 'replibox') then
    wifiWatcher:stop()
    wifiWatcher = nil
  end

  if (config.hostname == 'replibox') then
    usbWatcher:stop()
    usbWatcher = nil

    caffeinateWatcher:stop()
    caffeinateWatcher = nil
  end

  -- potentially a bad thing to do this..
  -- allWindows:unsubscribeAll()
end

return events
