local hyper = require("hyper")
local screenMode = hs.hotkey.modal.new()
local window  = hs.window
      window.animationDuration = 0

hyper:bind({}, 'm', nil, function() screenMode:enter() end)

function screenMode:entered()
  alertUuids = hs.fnutils.imap(hs.screen.allScreens(), function(screen)
    local prompt = string.format("◱ : %s",
                                 window.focusedWindow():application():title())
    return hs.alert.show(prompt, hs.alert.defaultStyle, screen, true)
  end)
end

function screenMode:exited()
  hs.fnutils.ieach(alertUuids, function(uuid)
    hs.alert.closeSpecific(uuid)
  end)
end

grid = {
  { key='j', unit=hs.geometry.rect(0, 0.5, 1, 0.5) },
  { key='k', unit=hs.geometry.rect(0, 0, 1, 0.5) },
  { key='h', unit=hs.layout.left50 },
  { key='l', unit=hs.layout.right50 },

  { key='y', unit=hs.geometry.rect(0, 0, 0.5, 0.5) },
  { key='u', unit=hs.geometry.rect(0.5, 0, 0.5, 0.5) },
  { key='b', unit=hs.geometry.rect(0, 0.5, 0.5, 0.5) },
  { key='n', unit=hs.geometry.rect(0.5, 0.5, 0.5, 0.5) },

  { key='space', unit=hs.layout.maximized },
}

hs.fnutils.each(grid, function(entry)
  screenMode:bind('', entry.key, function()
    window.focusedWindow():moveToUnit(entry.unit)
    screenMode:exit()
  end)
end)

screenMode:bind('ctrl', '[', function() screenMode:exit() end)
screenMode:bind('', 'escape', function() screenMode:exit() end)

screenMode:bind('shift', 'h', function()
  window.focusedWindow():moveOneScreenWest()
  screenMode:exit()
end)

screenMode:bind('shift', 'l', function()
  window.focusedWindow():moveOneScreenEast()
  screenMode:exit()
end)

screenMode:bind('', 'tab', function ()
  window:focusedWindow():centerOnScreen()
  screenMode:exit()
end)
