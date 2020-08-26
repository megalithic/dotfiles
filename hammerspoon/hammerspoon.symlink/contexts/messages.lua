local log = hs.logger.new('[contexts.messages]', 'info')

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

-- apply(string, hs.window) :: nil
module.apply = function(event, win)
  log.f("applying [contexts.messages] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 2, event)
end

return module
