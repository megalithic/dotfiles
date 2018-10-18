-- Press Cmd+Q twice to actually quit

local quitModal = hs.hotkey.modal.new('cmd','q')

local function doQuit(app)
  local appToQuit = app or hs.application.frontmostApplication()
  appToQuit:kill()
end

function quitModal:entered()
  local app = hs.application.frontmostApplication()
  if (config.applications[app:name()] ~= nil) then
    log.df("[app-quit-guard] - attempting to quit for %s, and quitGuard is %s", app:name(), config.applications[app:name()].quitGuard)

    if config.applications[app:name()].quitGuard then
      hs.alert.show("Press Cmd+Q again to quit", 1)
      hs.timer.doAfter(1, function() quitModal:exit() end)
    else
      quitModal:exit()
      doQuit()
    end
  else
    log.df("[app-quit-guard] - unable to determine how to handle this app, %s; it likely isn't configured.", app:name())
    doQuit()
  end
end

quitModal:bind('cmd', 'q', doQuit)

quitModal:bind('', 'escape', function() quitModal:exit() end)
