-- HUD Stack Module
-- Manages multiple HUDs, z-ordering, and stacking behavior
--
-- Rules:
--   - Persistent HUDs render above ephemeral (higher z-index)
--   - Persistent HUDs first in vertical order
--   - When ephemeral appears: persistent slides up to make room
--   - When ephemeral dismisses: persistent slides back down
--

---@class HudStackModule
---@field huds table<string, BaseHUD> Active HUDs by ID
---@field register fun(hud: BaseHUD) Register a HUD with the stack
---@field unregister fun(hud: BaseHUD) Remove a HUD from the stack
---@field getAtAnchor fun(anchor: string): BaseHUD[] Get all HUDs at anchor
---@field restack fun(anchor: string) Recalculate positions at anchor
---@field makeRoom fun(anchor: string, height: number) Slide HUDs to make room
---@field dismissAll fun(opts?: table) Dismiss all HUDs
---@field cleanup fun() Clean up all resources

local M = {}

local position = require("lib.hud.position")
local animator = require("lib.hud.animator")

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------

-- Active HUDs by ID
M.huds = {}

-- HUDs by type for quick lookup
M.ephemeral = {}   -- Auto-dismiss HUDs (alerts, toasts)
M.persistent = {}  -- Stay until dismissed (indicators)

-- Canvas levels
M.LEVELS = {
  ephemeral = "overlay",           -- Standard overlay level
  persistent = "tornOffMenu",      -- Above overlay
}

--------------------------------------------------------------------------------
-- REGISTRATION
--------------------------------------------------------------------------------

--- Register a HUD with the stack manager
---@param hud table HUD instance with { id, type, canvas, anchor, ... }
function M.register(hud)
  if not hud.id then
    error("HUD must have an id")
  end

  -- Remove any existing HUD with same ID
  M.unregister(hud.id)

  -- Store in main registry
  M.huds[hud.id] = hud

  -- Store in type-specific list
  local list = hud.ephemeral == false and M.persistent or M.ephemeral
  table.insert(list, hud)

  -- Set appropriate canvas level
  local level = hud.ephemeral == false and M.LEVELS.persistent or M.LEVELS.ephemeral
  if hud.canvas then
    hud.canvas:level(level)
  end
end

--- Unregister a HUD from the stack manager
---@param hudId string HUD identifier
function M.unregister(hudId)
  local hud = M.huds[hudId]
  if not hud then return end

  -- Remove from main registry
  M.huds[hudId] = nil

  -- Remove from type-specific list
  local list = hud.ephemeral == false and M.persistent or M.ephemeral
  for i, h in ipairs(list) do
    if h.id == hudId then
      table.remove(list, i)
      break
    end
  end
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

--- Get a HUD by ID
---@param hudId string HUD identifier
---@return table|nil HUD instance
function M.get(hudId)
  return M.huds[hudId]
end

--- Get all active HUDs
---@return table Array of HUD instances
function M.getAll()
  local result = {}
  for _, hud in pairs(M.huds) do
    table.insert(result, hud)
  end
  return result
end

--- Get HUDs at a specific anchor position
---@param anchor string Anchor position (e.g., "bottom-center")
---@return table Array of HUD instances at that anchor
function M.getAtAnchor(anchor)
  local result = {}
  for _, hud in pairs(M.huds) do
    if hud.anchor == anchor then
      table.insert(result, hud)
    end
  end
  return result
end

--- Get count of active HUDs
---@return number Total count
function M.count()
  local count = 0
  for _ in pairs(M.huds) do
    count = count + 1
  end
  return count
end

--------------------------------------------------------------------------------
-- STACKING
--------------------------------------------------------------------------------

--- Reposition HUDs at an anchor to stack properly
--- Called when a HUD is added or removed
---@param anchor string Anchor position
function M.restack(anchor)
  local huds = M.getAtAnchor(anchor)
  if #huds == 0 then return end

  -- Sort: persistent first, then by show order (oldest first at bottom)
  table.sort(huds, function(a, b)
    -- Persistent HUDs come first (higher in stack)
    if (a.ephemeral == false) ~= (b.ephemeral == false) then
      return a.ephemeral == false
    end
    -- Otherwise by creation time (older at bottom)
    return (a.createdAt or 0) < (b.createdAt or 0)
  end)

  -- Calculate positions with stacking offset
  for i, hud in ipairs(huds) do
    if hud.canvas and hud.basePosition then
      local offset = position.stackOffset(i - 1, hud.scaledHeight or hud.height or 0, anchor)
      local newY = hud.basePosition.y + offset

      -- Animate the move if HUD is visible
      if hud.visible then
        local currentPos = hud.canvas:topLeft()
        if math.abs(currentPos.y - newY) > 1 then
          -- Quick slide to new position
          animator.animate(150, function(progress)
            local y = currentPos.y + (newY - currentPos.y) * progress
            hud.canvas:topLeft({ x = currentPos.x, y = y })
          end, { easing = animator.easeOutCubic })
        end
      else
        hud.canvas:topLeft({ x = hud.basePosition.x, y = newY })
      end
    end
  end
end

--- Make room for a new HUD at an anchor
--- Slides existing HUDs to accommodate
---@param anchor string Anchor position
---@param height number Height of incoming HUD
function M.makeRoom(anchor, height)
  local huds = M.getAtAnchor(anchor)

  for _, hud in ipairs(huds) do
    if hud.canvas and hud.visible then
      local currentPos = hud.canvas:topLeft()
      local offset = -(height + position.STACK_SPACING)

      animator.animate(200, function(progress)
        if not hud.canvas then return end
        local y = currentPos.y + (offset * progress)
        hud.canvas:topLeft({ x = currentPos.x, y = y })
      end, { easing = animator.easeOutCubic })
    end
  end
end

--------------------------------------------------------------------------------
-- BULK OPERATIONS
--------------------------------------------------------------------------------

--- Dismiss all HUDs
---@param opts? table { animate?: boolean, filter?: function }
function M.dismissAll(opts)
  opts = opts or {}
  local animate = opts.animate ~= false
  local filter = opts.filter

  -- Copy keys to avoid modifying table while iterating
  local ids = {}
  for id in pairs(M.huds) do ids[#ids + 1] = id end

  for _, id in ipairs(ids) do
    local hud = M.huds[id]
    if hud and (not filter or filter(hud)) then
      if hud.dismiss then
        hud:dismiss({ animate = animate })
      else
        -- Fallback: stop timers manually before cleanup
        if hud.timers then
          for name, timer in pairs(hud.timers) do
            if timer then pcall(function() timer:stop() end) end
          end
        end
        M.unregister(id)
        if hud.canvas then
          if animate then
            animator.fadeOut(hud.canvas, { deleteAfter = true })
          else
            hud.canvas:delete(0)
          end
        end
      end
    end
  end
end

--- Dismiss all ephemeral HUDs
---@param opts? table { animate?: boolean }
function M.dismissEphemeral(opts)
  M.dismissAll({
    animate = opts and opts.animate,
    filter = function(hud) return hud.ephemeral ~= false end,
  })
end

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------

--- Clean up all HUDs (call on reload)
function M.cleanup()
  for id, hud in pairs(M.huds) do
    -- Stop all timers first
    if hud.timers then
      for name, timer in pairs(hud.timers) do
        if timer then
          pcall(function() timer:stop() end)
        end
      end
    end
    -- Then delete canvas
    if hud.canvas then
      pcall(function() hud.canvas:delete(0) end)
    end
  end

  M.huds = {}
  M.ephemeral = {}
  M.persistent = {}
end

return M
