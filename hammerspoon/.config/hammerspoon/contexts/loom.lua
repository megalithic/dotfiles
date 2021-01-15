local cache = {}
local module = {cache = cache}

local fn = require("hs.fnutils")
local wh = require("utils.wm.window-handlers")
local spotify = require("bindings.media").media_control
local ptt = require("bindings.ptt")
local initApplyComplete = false

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, _log)
  local log = hs.logger.new("[loom]", "debug")

  if not initApplyComplete then
    if fn.contains({"windowCreated"}, event) then
      ----------------------------------------------------------------------
      -- handle DND toggling
      log.df("toggling on DND for %s..", event)
      wh.dndHandler(win, {enabled = true, mode = "loom"}, event)

      ----------------------------------------------------------------------
      -- naively handle spotify pause (always pause it, no matter the event)
      log.df("pausing spotify for %s..", event)
      spotify("pause")

      -- unmute (PTM) by default
      log.df("toggling on PTM for %s..", event)
      ptt.setState("push-to-mute")
    end

    initApplyComplete = true
  end

  ----------------------------------------------------------------------
  -- mute (PTT) by default
  wh.onAppQuit(
    win,
    function()
      log.df("toggling on PTT for %s..", event)
      ptt.setState("push-to-talk")
      initApplyComplete = false
    end
  )
end

return module
