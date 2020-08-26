local log = hs.logger.new('[contexts.loom]', 'info')

local cache  = {}
local module = { cache = cache, }
local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')

-- apply(string, hs.window) :: nil
module.apply = function(event, win)
  local app = win:application()
  if app == nil then return end

  log.f("applying [contexts.loom] for %s (%s)..", event, win:title())

  ----------------------------------------------------------------------
  -- handle DND toggling
  log.f("toggling DND for %s..", event)
  wh.dndHandler(win, { enabled = true, mode = "zoom" }, event)

  ----------------------------------------------------------------------
  -- naively handle spotify pause (always pause it, no matter the event)
  log.f("pausing spotify for %s..", event)
  spotify('pause')


  if hs.fnutils.contains({"windowDestroyed"}, event) then
    ----------------------------------------------------------------------
    -- mute (PTT) by default
    wh.onAppQuit(win, function()
      ptt.setState("push-to-talk")
    end)
  else
    -- unmute (PTM) by default
    ptt.setState("push-to-mute")
  end
end

return module
