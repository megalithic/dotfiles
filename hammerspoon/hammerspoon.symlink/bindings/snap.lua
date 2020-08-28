-- REF: some interesting and useful things:
-- https://github.com/dbmrq/dotfiles/blob/master/home/.hammerspoon/winman.lua

local log = hs.logger.new('[bindings.snap]', 'warning')
local chain = require('ext.window').chain
local wh = require('utils.wm.window-handlers')

local module = {}

module.windowSplitter = function()
  local windows = hs.fnutils.map(wh.validWindows(), function(win)
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
      -- local layout = {}
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
    end
  end)

  chooser
  :placeholderText("Choose window for 50/50 split. Hold ⎇ for 70/30.")
  :searchSubText(true)
  :choices(windows)
  :show()
end

module.start = function()
  -- :: window-manipulation (manual window snapping)
  for _, c in pairs(config.snap) do
    hs.hotkey.bind(c.modifier, c.shortcut, chain(c.locations))
  end

  local hyper = require("bindings.hyper")
  hyper:bind('', 'v', module.windowSplitter)
end

module.stop = function()
  -- nil
end

return module
