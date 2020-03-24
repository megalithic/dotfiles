-- Press Cmd+Q twice to actually quit
local log = hs.logger.new('[quit]', 'debug')
local config = require('config')

local quitModal = hs.hotkey.modal.new('cmd','q')
local quitAlertText = "Press Cmd+Q again to quit"

local function doQuit(app)
  local appToQuit = app or hs.application.frontmostApplication()
  appToQuit:kill()
end

function quitModal:entered()
  local app = hs.application.frontmostApplication()
  if app == nil then return end

  local appBundleID = app:bundleID()
  local appConfig = config.apps[appBundleID]

  if (appConfig == nil or appConfig.quitGuard == nil) then
    log.df("unable to quit the app, %s, with quitGuard; likely not configured..", appBundleID)
    doQuit()
  else
    log.df("quitting app, %s, with quitGuard (%s)..", appBundleID, appConfig.quitGuard)

    if appConfig.quitGuard then
      hs.alert.show(quitAlertText, 1)
      hs.timer.doAfter(1, function() quitModal:exit() end)
    else
      quitModal:exit()
      doQuit()
    end
  end
end

quitModal:bind('cmd', 'q', doQuit)
quitModal:bind('', 'escape', function() quitModal:exit() end)
