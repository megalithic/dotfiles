local cache  = {}
local module = { cache = cache, }

local wh = require('wm.handlers')

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, _)
  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 2, event)
end

return module
