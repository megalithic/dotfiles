--------------------------------------------------------------------------------
-- Chain the specified grid movement positions on the focused window
--
-- Courtesy of: https://github.com/wincent/wincent/blob/master/roles/dotfiles/files/.hammerspoon/init.lua
-- By way of: https://github.com/jesseleite/dotfiles/blob/master/hammerspoon/chain.lua
--------------------------------------------------------------------------------

-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.

local obj = {}
obj.__index = obj
obj.name = "chain"
obj.debug = false

obj.lastSeenChain = nil
obj.lastSeenWindow = nil
obj.lastSeenAt = nil

obj.placeInSequence = function(movements, modal, interval)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if obj.lastSeenChain ~= movements or obj.lastSeenAt < now - chainResetInterval or obj.lastSeenWindow ~= id then
      sequenceNumber = 1
      obj.lastSeenChain = movements
    elseif sequenceNumber == 1 then
      -- At end of chain, restart chain on next screen.
      screen = screen:next()
    end
    obj.lastSeenAt = now
    obj.lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber])

    sequenceNumber = sequenceNumber % cycleLength + 1

    if modal ~= nil then
      if interval ~= nil then
        modal:delayedExit(interval)
      else
        modal:exit()
      end
    end

    if modal ~= nil then modal.toggleIndicator(win, true) end
  end
end

return function(...) return obj.placeInSequence(...) end
