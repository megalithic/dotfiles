--- Screen configuration watcher
--- Detects when displays are connected/disconnected or reconfigured

local M = {}
M.name = "screen"

local watcher = nil
local callbacks = {}

---Register a callback for screen changes
---@param id string Unique identifier for this callback
---@param fn function Callback to invoke on screen change
function M.onChange(id, fn)
  callbacks[id] = fn
end

---Remove a callback
---@param id string Callback identifier to remove
function M.removeCallback(id)
  callbacks[id] = nil
end

---@param watchers table Parent watchers table
function M.start(watchers)
  if watcher then
    U.log.w("screen watcher already running")
    return
  end
  
  watcher = hs.screen.watcher.new(function()
    U.log.d("screen configuration changed")
    
    -- Call all registered callbacks
    for id, fn in pairs(callbacks) do
      local ok, err = pcall(fn)
      if not ok then
        U.log.e("screen callback error (" .. id .. "):", tostring(err or "unknown error"))
      end
    end
  end)
  
  watcher:start()
  U.log.i("started")
end

---@param watchers table Parent watchers table
function M.stop(watchers)
  if watcher then
    watcher:stop()
    watcher = nil
  end
  
  callbacks = {}
  U.log.i("stopped")
end

return M
