local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "browser"
obj.debug = true

local dbg = function(...)
  if obj.debug then
    return _G.dbg(fmt(...), false)
  else
    return ""
  end
end

obj.splitTab = function()
  -- Move current window to the left half
  local snap = L.load("lib.wm.snap")
  if snap then snap.send_window_left() end

  hs.timer.doAfter(100 / 1000, function()
    local preferred = Settings.get(CONFIG_KEY).preferred.browsers
    local browser = hs.appfinder.appFromName(preferred[1])
    local moveTab = { "Tab", "Move Tab to New Window" }

    if browser then
      browser:selectMenuItem(moveTab)
      -- Move the split tab to the right of the screen
      if snap then snap.send_window_right() end
    end
  end)
end

function obj:init() return self end

function obj:start() return self end

function obj:stop() return self end

return obj
