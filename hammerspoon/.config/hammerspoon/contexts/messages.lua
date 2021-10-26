local cache = {}
local M = { cache = cache }

local wh = require("utils.wm.window-handlers")

-- apply(hs.application, hs.window, running.events, hs.logger) :: nil
M.apply = function(app, win, event, log)
  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(app, 1, event)
end

return M
