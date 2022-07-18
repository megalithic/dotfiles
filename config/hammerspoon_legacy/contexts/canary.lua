local cache = {}
local M = { cache = cache }

local wh = require("wm.handlers")

-- apply(hs.application, hs.window, running.events, hs.logger) :: nil
M.apply = function(app, win, event, log)
  if app == nil then
    return
  end

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(app, 5, event)
end

return M
