local M = {}

M.tile = function()
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
      local alt = hs.window.find(choice.id)
      if hs.eventtap.checkKeyboardModifiers()["shift"] then
        hs.alert.show("  70 󱪳 30  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left70, 0, 0 },
          { nil, alt, focused:screen(), hs.layout.right30, 0, 0 },
        })
      else
        hs.alert.show("  50 󱪳 50  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left50, 0, 0 },
          { nil, alt, focused:screen(), hs.layout.right50, 0, 0 },
        })
      end
      alt:raise()
    end
  end)

  chooser
    :placeholderText("Choose window for 50/50 split. Hold ⇧ for 70/30.")
    :searchSubText(true)
    :choices(windows)
    :show()
end

M.toNextScreen = function()
  local win = hs.window.frontmostWindow()
  local next = win:screen():next()
  win:moveToScreen(next)

  return win
end

M.toPrevScreen = function()
  local win = hs.window.frontmostWindow()
  local prev = win:screen():previous()
  win:moveToScreen(prev)

  return win
end

M.place = function(pos)
  local win = hs.window.frontmostWindow()

  hs.grid.set(win, pos)

  return win
end

return M
