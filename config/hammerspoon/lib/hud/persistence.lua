-- HUD Persistence Module
-- Stores and retrieves HUD preferences via hs.settings
--
-- Persists:
--   - Position preferences per HUD type/id
--   - Mode/state for stateful HUDs
--
-- All keys are prefixed with "hud." to avoid conflicts
--
local M = {}

--------------------------------------------------------------------------------
-- CONSTANTS
--------------------------------------------------------------------------------

M.PREFIX = "hud."

--------------------------------------------------------------------------------
-- LOW-LEVEL API
--------------------------------------------------------------------------------

--- Get a setting value
---@param key string Setting key (without prefix)
---@return any|nil Value or nil if not set
function M.get(key)
  return hs.settings.get(M.PREFIX .. key)
end

--- Set a setting value
---@param key string Setting key (without prefix)
---@param value any Value to store (nil to clear)
---@return boolean Success
function M.set(key, value)
  if value == nil then
    hs.settings.clear(M.PREFIX .. key)
  else
    hs.settings.set(M.PREFIX .. key, value)
  end
  return true
end

--- Clear a setting
---@param key string Setting key (without prefix)
function M.clear(key)
  hs.settings.clear(M.PREFIX .. key)
end

--------------------------------------------------------------------------------
-- POSITION PERSISTENCE
--------------------------------------------------------------------------------

--- Get saved position for a HUD
---@param hudId string HUD identifier (e.g., "clipper", "miccheck-ptm")
---@return string|nil Anchor position or nil if not saved
function M.getPosition(hudId)
  return M.get("position." .. hudId)
end

--- Save position for a HUD
---@param hudId string HUD identifier
---@param position string Anchor position (e.g., "bottom-center")
function M.setPosition(hudId, position)
  M.set("position." .. hudId, position)
end

--- Clear saved position for a HUD
---@param hudId string HUD identifier
function M.clearPosition(hudId)
  M.clear("position." .. hudId)
end

--------------------------------------------------------------------------------
-- STATE PERSISTENCE
--------------------------------------------------------------------------------

--- Get saved state for a HUD
---@param hudId string HUD identifier
---@return table|nil State table or nil if not saved
function M.getState(hudId)
  return M.get("state." .. hudId)
end

--- Save state for a HUD
---@param hudId string HUD identifier
---@param state table State to save
function M.setState(hudId, state)
  M.set("state." .. hudId, state)
end

--- Clear saved state for a HUD
---@param hudId string HUD identifier
function M.clearState(hudId)
  M.clear("state." .. hudId)
end

--- Merge state (update specific keys without overwriting others)
---@param hudId string HUD identifier
---@param updates table Keys to update
function M.mergeState(hudId, updates)
  local current = M.getState(hudId) or {}
  for k, v in pairs(updates) do
    current[k] = v
  end
  M.setState(hudId, current)
end

--------------------------------------------------------------------------------
-- BULK OPERATIONS
--------------------------------------------------------------------------------

--- Get all HUD settings
---@return table All settings with hud.* prefix
function M.getAll()
  local all = {}
  local keys = hs.settings.getKeys() or {}

  for _, key in ipairs(keys) do
    if key:sub(1, #M.PREFIX) == M.PREFIX then
      local shortKey = key:sub(#M.PREFIX + 1)
      all[shortKey] = hs.settings.get(key)
    end
  end

  return all
end

--- Clear all HUD settings
function M.clearAll()
  local keys = hs.settings.getKeys() or {}

  for _, key in ipairs(keys) do
    if key:sub(1, #M.PREFIX) == M.PREFIX then
      hs.settings.clear(key)
    end
  end
end

return M
