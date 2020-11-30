-- Window shortcuts originally from @tmiller, now _heavily_ modified.

local movewindows = hs.hotkey.modal.new()

function movewindows:entered()
  alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local prompt = string.format("◱ : %s",
                                 hs.window.focusedWindow():application():title())
    return hs.alert.show(prompt, hs.alert.defaultStyle, screen, true)
  end)
end

function movewindows:exited()
  hs.fnutils.ieach(alertUuids, function(uuid)
    hs.alert.closeSpecific(uuid)
  end)
end

movewindows.grid = {
  { key='j', unit=hs.geometry.rect(0, 0.5, 1, 0.5) },
  { key='k', unit=hs.geometry.rect(0, 0, 1, 0.5) },
  { key='h', unit=hs.layout.left50 },
  { key='l', unit=hs.layout.right50 },

  { key='y', unit=hs.geometry.rect(0, 0, 0.5, 0.5) },
  { key='u', unit=hs.geometry.rect(0.5, 0, 0.5, 0.5) },
  { key='b', unit=hs.geometry.rect(0, 0.5, 0.5, 0.5) },
  { key='n', unit=hs.geometry.rect(0.5, 0.5, 0.5, 0.5) },

  { key='r', unit=hs.layout.left70 },
  { key='t', unit=hs.layout.right30 },

  { key='space', unit=hs.layout.maximized },
}

movewindows.start = function()
  local hyper = require("hyper")
  hs.window.animationDuration = 0

  hyper:bind({}, 'm', nil, function() movewindows:enter() end)

  hs.fnutils.each(movewindows.grid, function(entry)
    movewindows:bind('', entry.key, function()
      hs.window.focusedWindow():moveToUnit(entry.unit)
      movewindows:exit()
    end)
  end)

  movewindows
    :bind('ctrl', '[', function() movewindows:exit() end)
    :bind('', 'escape', function() movewindows:exit() end)
    :bind('shift', 'h', function()
      hs.window.focusedWindow():moveOneScreenWest()
      movewindows:exit()
    end)
    :bind('shift', 'l', function()
      hs.window.focusedWindow():moveOneScreenEast()
      movewindows:exit()
    end)
    :bind('', ',', function()
      hs.window.focusedWindow()
        :application()
        :selectMenuItem("Tile Window to Left of Screen")
      movewindows:exit()
    end)
    :bind('', '.', function()
      hs.window.focusedWindow()
        :application()
        :selectMenuItem("Tile Window to Right of Screen")
      movewindows:exit()
    end)
    :bind('', 'v', function()
      local windows = hs.fnutils.map(hs.window.filter.default:getWindows(), function(win)
        if win ~= hs.window.focusedWindow() then
          return {
            text = win:title(),
            subText = win:application():title(),
            image = hs.image.imageFromAppBundle(win:application():bundleID()),
            id = win:id()
          }
        end
      end)

      local chooser = hs.chooser.new(function(choice)
        if choice ~= nil then
          local layout = {}
          local focused = hs.window.focusedWindow()
          local toRead  = hs.window.find(choice.id)
          if hs.eventtap.checkKeyboardModifiers()['alt'] then
            hs.layout.apply({
              {nil, focused, focused:screen(), hs.layout.left70, 0, 0},
              {nil, toRead, focused:screen(), hs.layout.right30, 0, 0}
            })
          else
            hs.layout.apply({
              {nil, focused, focused:screen(), hs.layout.left50, 0, 0},
              {nil, toRead, focused:screen(), hs.layout.right50, 0, 0}
            })
          end
          toRead:raise()
          focused:focus()
        end
      end)

      chooser
        :placeholderText("Choose window for 50/50 split. Hold ⎇ for 70/30.")
        :searchSubText(true)
        :choices(windows)
        :show()

      movewindows:exit()
    end)
    :bind('', 'tab', function ()
      hs.window.focusedWindow():centerOnScreen()
      movewindows:exit()
    end)
end

return movewindows
