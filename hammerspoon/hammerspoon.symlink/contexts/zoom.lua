local log = hs.logger.new('[contexts.zoom]', 'debug')

-- TODO:
-- 1. DND toggling
-- 2. Window layout and closing
-- 3. Spotify pause
-- 4. Check output/input and set correctly
-- 5. Set PTT is on (e.g., mute by default)

local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify

module.localBindings = function()
  return {
  }
end

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.zoom] for %s..", event)

  local app = win:application()
  if app == nil then return end

  -- handle DND toggling
  log.df("toggling DND for %s..", event)
  wh.dndHandler(win, { enabled = true }, event)

  -- naively handle spotify pause (always pause it, no matter the event)
  log.df("pausing spotify for %s..", event)
  spotify('pause')
end

return module
