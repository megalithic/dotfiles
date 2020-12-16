-- REF: some interesting and useful things:
-- https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/winman.lua

-- local log = hs.logger.new('[bindings.snap]', 'warning')
-- local chain = require("ext.window").chain
local wh = require("utils.wm.window-handlers")
local movewindows = hs.hotkey.modal.new()
local alertUuids = {}

local module = {}

function movewindows:entered()
  alertUuids =
    hs.fnutils.map(
    hs.screen.allScreens(),
    function(screen)
      if screen == hs.screen.mainScreen() then
        local prompt = string.format("◱ : %s", hs.window.focusedWindow():application():title())
        return hs.alert.show(prompt, hs.alert.defaultStyle, screen, true)
      end

      return nil
    end
  )
end

function movewindows:exited()
  hs.fnutils.ieach(
    alertUuids,
    function(uuid)
      hs.alert.closeSpecific(uuid)
    end
  )
end

module.windowSplitter = function()
  local windows =
    hs.fnutils.map(
    wh.validWindows(),
    function(win)
      if win ~= hs.window.focusedWindow() then
        return {
          text = win:title(),
          subText = win:application():title(),
          image = hs.image.imageFromAppBundle(win:application():bundleID()),
          id = win:id()
        }
      end
    end
  )

  local chooser =
    hs.chooser.new(
    function(choice)
      if choice ~= nil then
        -- local layout = {}
        local focused = hs.window.focusedWindow()
        local toRead = hs.window.find(choice.id)
        if hs.eventtap.checkKeyboardModifiers()["alt"] then
          hs.layout.apply(
            {
              {nil, focused, focused:screen(), hs.layout.left70, 0, 0},
              {nil, toRead, focused:screen(), hs.layout.right30, 0, 0}
            }
          )
        else
          hs.layout.apply(
            {
              {nil, focused, focused:screen(), hs.layout.left50, 0, 0},
              {nil, toRead, focused:screen(), hs.layout.right50, 0, 0}
            }
          )
        end
        toRead:raise()
      end
    end
  )

  chooser:placeholderText("Choose window for 50/50 split. Hold ⎇ for 70/30."):searchSubText(true):choices(windows):show(

  )
end

module.start = function()
  local hyper = require("bindings.hyper")
  -- hyper:bind('', 'v', module.windowSplitter)
  hyper:bind(
    {},
    "v",
    nil,
    function()
      movewindows:enter()
    end
  )

  -- :: window-manipulation (manual window snapping)
  for _, c in pairs(config.snap) do
    movewindows:bind(
      "",
      c.shortcut,
      function()
        -- chain(c.locations)()
        hs.window.focusedWindow():moveToUnit(c.position)
        movewindows:exit()
      end
    )

    -- hs.hotkey.bind(c.modifier, c.shortcut, chain(c.locations))
  end

  movewindows:bind(
    "",
    "v",
    function()
      module.windowSplitter()
      movewindows:exit()
    end
  ):bind(
    "ctrl",
    "[",
    function()
      movewindows:exit()
    end
  ):bind(
    "",
    "escape",
    function()
      movewindows:exit()
    end
  ):bind(
    "shift",
    "h",
    function()
      hs.window.focusedWindow():moveOneScreenWest()
      movewindows:exit()
    end
  ):bind(
    "shift",
    "l",
    function()
      hs.window.focusedWindow():moveOneScreenEast()
      movewindows:exit()
    end
  ):bind(
    "",
    ",",
    function()
      hs.window.focusedWindow():application():selectMenuItem("Tile Window to Left of Screen")
      movewindows:exit()
    end
  ):bind(
    "",
    ".",
    function()
      hs.window.focusedWindow():application():selectMenuItem("Tile Window to Right of Screen")
      movewindows:exit()
    end
  ):bind(
    "",
    "tab",
    function()
      hs.window.focusedWindow():centerOnScreen()
      movewindows:exit()
    end
  )

  -- hs.fnutils.each(
  --   hyper.grid,
  --   function(entry)
  --     hyper:bind(
  --       "",
  --       entry.key,
  --       function()
  --         hs.window.focusedWindow():moveToUnit(entry.unit)
  --         movewindows:exit()
  --       end
  --     )
  --   end
  -- )
end

module.stop = function()
  movewindows:exit()
end

return module
