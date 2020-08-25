local log = hs.logger.new('[contexts.loom]', 'debug')

-- TODO:
-- 1. DND toggling
-- 3. Spotify pause
-- 4. Check output/input and set correctly
-- 5. Set PTM is on (e.g., unmuted by default)

local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.loom] for %s..", event)

  local app = win:application()
  if app == nil then return end

  ----------------------------------------------------------------------
  -- handle DND toggling
  log.df("toggling DND for %s..", event)
  wh.dndHandler(win, { enabled = true, mode = "zoom" }, event)

  ----------------------------------------------------------------------
  -- naively handle spotify pause (always pause it, no matter the event)
  log.df("pausing spotify for %s..", event)
  spotify('pause')

  if hs.fnutils.contains({"windowDestroyed"}, event) then
    ----------------------------------------------------------------------
    -- mute (PTT) by default
    -- REF: https://github.com/Hammerspoon/hammerspoon/issues/529#issuecomment-136679247
    if not hs.application.find(app:name()) then
      log.df("no longer running! [%s]", hs.application.find(app:name()))
      ptt.setState("push-to-talk")
    else
      log.df("still running! [%s]", hs.application.find(app:name()))
    end
  else
    -- unmute (PTM) by default
    ptt.setState("push-to-mute")
  end
end

return module
