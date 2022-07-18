local cache = {}
local M = { cache = cache }

local wh = require("wm.handlers")

-- apply(hs.application, hs.window, running.events, hs.logger) :: nil
M.apply = function(app, win, event, log)
  ----------------------------------------------------------------------
  -- handle hide-after interval
  local hideAfter = Config.apps[app:bundleID()].hideAfter
  if hideAfter ~= nil then
    wh.hideAfterHandler(app, hideAfter, event)
  end
end

return M
