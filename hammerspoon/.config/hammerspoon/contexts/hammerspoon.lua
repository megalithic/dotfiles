local cache = {}
local module = {cache = cache}

local wh = require("utils.wm.window-handlers")

-- apply(string, hs.application, hs.logger) :: nil
module.apply = function(event, app, _)
  if app == nil then
    return
  end

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(app, 1, event)
end

return module
