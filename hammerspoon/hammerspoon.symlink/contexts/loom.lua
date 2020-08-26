local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()
  if app == nil then return end

  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    ----------------------------------------------------------------------
    -- handle DND toggling
    log.df("toggling DND for %s..", event)
    wh.dndHandler(win, { enabled = true, mode = "loom" }, event)

    ----------------------------------------------------------------------
    -- naively handle spotify pause (always pause it, no matter the event)
    log.df("pausing spotify for %s..", event)
    spotify('pause')

    -- unmute (PTM) by default
    ptt.setState("push-to-mute")
  elseif hs.fnutils.contains({"windowDestroyed"}, event) then
    ----------------------------------------------------------------------
    -- mute (PTT) by default
    -- FIXME: not working here, but it does for Zoom.. :shrug:
    wh.onAppQuit(win, function()
      ptt.setState("push-to-talk")
    end)
  end
end

return module
