-- REF: some interesting and useful things:
-- https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/winman.lua

local log = hs.logger.new("[bindings.snap]", "info")
local movewindows = hs.hotkey.modal.new()
local alertUuids = {}
local alert = require("ext.alert")

local M = {}

function movewindows:entered()
  log.i("-> entered snap modal..")

  -- hs.window.highlight.start()
  alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
    local win = hs.window.focusedWindow()

    if win ~= nil then
      if screen == hs.screen.mainScreen() then
        local app_title = win:application():title()
        local image = hs.image.imageFromAppBundle(win:application():bundleID())
        local prompt = string.format("◱ : %s", app_title)
        if image ~= nil then
          prompt = string.format(": %s", app_title)
        end
        alert.showOnly({ text = prompt, image = image, screen = screen })
      end
    else
      -- unable to move a specific window. ¯\_(ツ)_/¯
      movewindows:exit()
    end

    return nil
  end)
end

function movewindows:exited()
  -- hs.window.highlight.stop()
  hs.fnutils.ieach(alertUuids, function(uuid)
    hs.alert.closeSpecific(uuid)
  end)

  alert.close()
  log.i("-> exited snap modal..")
end

M.windowSplitter = function()
  local windows = hs.fnutils.map(hs.window.filter.new():getWindows(), function(win)
    if win ~= hs.window.focusedWindow() then
      return {
        text = win:title(),
        subText = win:application():title(),
        image = hs.image.imageFromAppBundle(win:application():bundleID()),
        id = win:id(),
      }
    end
  end)

  local chooser = hs.chooser.new(function(choice)
    if choice ~= nil then
      local focused = hs.window.focusedWindow()
      local toRead = hs.window.find(choice.id)
      if hs.eventtap.checkKeyboardModifiers()["alt"] then
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left70, 0, 0 },
          { nil, toRead, focused:screen(), hs.layout.right30, 0, 0 },
        })
      else
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left50, 0, 0 },
          { nil, toRead, focused:screen(), hs.layout.right50, 0, 0 },
        })
      end
      toRead:raise()
    end
  end)

  chooser
    :placeholderText("Choose window for 50/50 split. Hold ⎇ for 70/30.")
    :searchSubText(true)
    :choices(windows)
    :show()
end

M.start = function()
  local hyper = require("bindings.hyper")

  hyper:bind({}, "l", nil, function()
    movewindows:enter()
  end)

  -- :: window-manipulation (manual window snapping)
  for _, c in pairs(Config.snap) do
    movewindows:bind("", c.shortcut, function()
      require("ext.window").chain(c.locations)(string.format("shortcut: %s", c.shortcut))
      movewindows:exit()
    end)
  end

  movewindows
    :bind("", "v", function()
      M.windowSplitter()
      movewindows:exit()
    end)
    :bind("ctrl", "[", function()
      movewindows:exit()
    end)
    :bind("", "s", function()
      if hs.window.focusedWindow():application():name() == Config.preferred.browsers[1] then
        require("bindings.browser").split()
      end
      movewindows:exit()
    end)
    :bind("", "escape", function()
      movewindows:exit()
    end)
    :bind("shift", "h", function()
      hs.window.focusedWindow():moveOneScreenWest()
      movewindows:exit()
    end)
    :bind("shift", "l", function()
      hs.window.focusedWindow():moveOneScreenEast()
      movewindows:exit()
    end)
    :bind("", "tab", function()
      hs.window.focusedWindow():centerOnScreen()
      movewindows:exit()
    end)
end

M.leftHalf = function()
  require("ext.window").chain(Config.snap.left.locations)("left half")
end
M.rightHalf = function()
  require("ext.window").chain(Config.snap.right.locations)("right half")
end

M.stop = function()
  movewindows:exit()
end

return M