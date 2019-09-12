local config = require('config')
local log = hs.logger.new('[layout]', 'debug')

local wf = nil
local isDocked = false

local windowLayouts = config.apps or {
  -- FIXME: superfulous default?
  ['_'] = {
    position = config.grid.centeredMedium,
    handler = function(win) snap(win) end
  }
}

local canLayoutWindow = function(win)
  return win:isStandard() and not win:isFullScreen() and not win:isMinimized()
end

local dndHandler = function(win, dnd, event)
  if dnd == nil then return end
  log.df('found dnd handler for %s..', win:application():bundleID())

  local enabled = dnd.enabled
  local mode = dnd.mode

  if (enabled) then
    if (event == "created") then
      log.df('dnd handler: toggling ON slack status (%s) and dnd mode', mode)
      hs.execute("slack " .. mode, true)
      hs.execute("dnd on", true)
    elseif (event == "destroyed") then
      log.df('dnd handler: toggling OFF slack status and dnd mode')
      hs.execute("slack back", true)
      hs.execute("dnd off", true)
    end
  end
end

local appHandler = function(win, handler)
  if handler == nil then return end
  log.df('found app handler for %s..', win:application():bundleID())

  handler(win)
end

local snap = function(win, position, screen)
  if win == nil then return end
  log.df('window snap (%s): %s', position, win:title())
  hs.grid.set(win, position or hs.grid.get(win), screen)
end

local logWindowInfo = function(win, appName, event)
  log.df('--------------------------------------------------')
  log.df(':: %s (%s) - role: %s - subrole: %s - appName: %s', event, win:title(), win:role(), win:subrole(), appName)
  log.df('Window: - %s', hs.inspect(win))
  log.df('IsStandard: - %s', win:isStandard())
  log.df('Application: - %s', win:application())
end

local highlighActiveWin = function()
  local rctgl = hs.drawing.rectangle(hs.window.focusedWindow():frame())
  rctgl:setStrokeColor({["red"]=1,  ["blue"]=0, ["green"]=0, ["alpha"]=1})
  rctgl:setStrokeWidth(1)
  rctgl:setFill(false)
  rctgl:show()
  hs.timer.doAfter(0.3, function() rctgl:delete() end)
end

local handleWindowLayout = function(win, appName, event)
  if not canLayoutWindow(win) and event ~= "destroyed" then return end

  local appBundleId = win:application():bundleID()
  local appConfig = windowLayouts[appBundleId] or windowLayouts['_']

  log.df('found app config for %s..', appBundleId or "<no app found>")

  snap(win, appConfig.position, appConfig.preferredDisplay)
  dndHandler(win, appConfig.dnd, event)
  appHandler(win, appConfig.handler)
end

local handleWindowCreated = function(win, appName)
  log.df('window created: %s', win:title())
  -- logWindowInfo(win, appName, "created")

  handleWindowLayout(win, appName, "created")
end

local handleWindowDestroyed = function(win, appName)
  log.df('window destroyed: %s', hs.inspect(win))
  -- logWindowInfo(win, appName, "destroyed")

  handleWindowLayout(win, appName, "destroyed")
end

local handleWindowFocused = function(win, appName)
  log.df('window focused: %s', win:title())
  -- logWindowInfo(win, appName, "focused")

  handleWindowLayout(win, appName, "focused")
  hs.timer.doAfter(0.05, highlighActiveWin)
end

local handleWindowMoved = function(win, appName)
  if win == nil then return end
  log.df('window moved: %s', win or appName)

  handleWindowLayout(win, appName, "moved")
end


local handleWindowFullscreened = function(win, appName)
  log.df('window fullscreened: %s for %s', win:title(), appName)

  win:setFullscreen(false)
end

return {
  init = (function(is_docked)
    isDocked = is_docked or false
    log.df('init window layouts (docked: %s)', isDocked)

    -- FIXME: determine if we want to spin up a window.filter for each app?
    wf = hs.window.filter.new()
    hs.window.filter.allowedWindowRoles = {
      AXStandardWindow=true,
      AXDialog=true,
      AXSystemDialog=true,
      -- AXUnknown=true
    }

    for _, name in ipairs(config.ignoredApps) do
      hs.window.filter.ignoreAlways[name] = true
    end

    wf:subscribe(hs.window.filter.windowCreated, handleWindowCreated, true)
    wf:subscribe(hs.window.filter.windowFocused, handleWindowFocused, true)
    wf:subscribe(hs.window.filter.windowMoved, handleWindowMoved, true)
    wf:subscribe(hs.window.filter.windowDestroyed, handleWindowDestroyed, true)
    wf:subscribe(hs.window.filter.windowFullscreened, handleWindowFullscreened, true)
  end),

  teardown = (function()
    log.df('teardown window layouts')

    wf = nil
  end)
}
