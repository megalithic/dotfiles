local log = hs.logger.new('[contexts.whatsapp]', 'info')

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')

-- apply(string, hs.window) :: nil
module.apply = function(event, win)
  log.f("applying [contexts.whatsapp] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(win, 1, event)
end

return module
