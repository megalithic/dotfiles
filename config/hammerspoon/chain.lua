--------------------------------------------------------------------------------
-- Chain the specified grid movement positions on the focused window
-- Properly notifies modal to update visuals after window movement
--
-- Based on: https://github.com/wincent/wincent/blob/master/roles/dotfiles/files/.hammerspoon/init.lua
--------------------------------------------------------------------------------

local obj = {}
obj.__index = obj
obj.name = "chain"

obj.lastSeenChain = nil
obj.lastSeenWindow = nil
obj.lastSeenAt = nil

-- Profiling
obj.DEBUG = true

local function profLog(msg, ...)
  if obj.DEBUG then
    U.log.d(string.format("[PERF] chain: " .. msg, ...))
  end
end

--- Chain window positions with proper visual tracking
---@param movements table Array of grid positions
---@param modal table|nil Modality instance (hypemode)
---@param interval number|nil Delay before auto-exit (nil = exit immediately)
---@return function Bound function for hotkey
obj.placeInSequence = function(movements, modal, interval)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local startTime = hs.timer.absoluteTime()
    profLog(">>> chain action started")
    
    local win = hs.window.frontmostWindow()
    if not win then return end
    
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    -- Reset chain if:
    -- - Different chain
    -- - Timeout expired (or first call)
    -- - Different window
    if obj.lastSeenChain ~= movements 
       or not obj.lastSeenAt
       or obj.lastSeenAt < now - chainResetInterval 
       or obj.lastSeenWindow ~= id then
      sequenceNumber = 1
      obj.lastSeenChain = movements
    elseif sequenceNumber == 1 then
      -- At end of chain, restart on next screen
      screen = screen:next()
    end
    
    obj.lastSeenAt = now
    obj.lastSeenWindow = id

    -- Move the window
    local gridStart = hs.timer.absoluteTime()
    hs.grid.set(win, movements[sequenceNumber], screen)
    profLog("hs.grid.set: %.2fms", (hs.timer.absoluteTime() - gridStart) / 1e6)

    -- Advance sequence
    sequenceNumber = sequenceNumber % cycleLength + 1

    -- Update modal visuals AFTER window has moved
    if modal then
      -- Force immediate visual update (bypasses debounce for responsiveness)
      if modal.updateVisuals then
        local updateStart = hs.timer.absoluteTime()
        modal:updateVisuals()
        profLog("updateVisuals: %.2fms", (hs.timer.absoluteTime() - updateStart) / 1e6)
      end
      
      -- Show indicator if available
      local vm = modal.visualManager
      if vm and vm.indicator then
        vm:showIndicator()
      end

      -- Handle exit
      if interval then
        modal:delayedExit(interval)
      else
        modal:exit()
      end
    end
    
    profLog("<<< chain action complete: %.2fms total", (hs.timer.absoluteTime() - startTime) / 1e6)
  end
end

--- Convenience wrapper
---@param movements table Array of grid positions
---@param modal table|nil Modality instance
---@param interval number|nil Auto-exit delay
---@return function
return function(movements, modal, interval)
  return obj.placeInSequence(movements, modal, interval)
end
