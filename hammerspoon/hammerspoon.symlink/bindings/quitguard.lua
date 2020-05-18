local log = hs.logger.new('[bindings.quitguard]', 'debug')
local module = {}

local quitModal = hs.hotkey.modal.new('cmd','q')
-- Press Cmd+Q twice to actually quit
local quitAlertText = "Press Cmd+Q again to quit"

local quit = function(app)
  local appToQuit = app or hs.application.frontmostApplication()
  appToQuit:kill()
end

function quitModal:entered()
  local app = hs.application.frontmostApplication()
  if app == nil then return end

  local appBundleID = app:bundleID()
  local appConfig = config.apps[appBundleID]

  if (appConfig == nil or appConfig.quitGuard == nil) then
    log.wf("QuitGuard not configured for %s (%s)..", app:name(), appBundleID)
    quit()
  else
    log.df("Starting to quit app, %s (%s), with QuitGuard..", app:name(), appBundleID)

    if appConfig.quitGuard then
      hs.alert.show(quitAlertText, 1)
      hs.timer.doAfter(1, function() quitModal:exit() end)
    else
      quitModal:exit()
      log.df("Quitting app, %s (%s), with QuitGuard..", app:name(), appBundleID)
      quit()
    end
  end
end

module.start = function()
  quitModal:bind('cmd', 'q', quit)
  quitModal:bind('', 'escape', function() quitModal:exit() end)
end

module.stop = function()
  -- nil
end

return module
