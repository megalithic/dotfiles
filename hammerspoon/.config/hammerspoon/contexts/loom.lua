local cache = {}
local M = { cache = cache }

local running = require("utils.wm.running")
local wh = require("utils.wm.window-handlers")
local spotify = require("bindings.media").media_control
local ptt = require("bindings.ptt")
local init_apply_complete = false

-- apply(hs.application, hs.window, running.events, hs.logger) :: nil
M.apply = function(app, win, event, log)
  if not init_apply_complete then
    log.f("app: %s", hs.inspect(app))
    log.f("win: %s", hs.inspect(win))
    log.f("event: %s", hs.inspect(event))

    if event == running.events.launched or app:isRunning() then
      ----------------------------------------------------------------------
      -- naively handle spotify pause (always pause it, no matter the event)
      spotify("pause")

      -- unmute (PTM) by default
      ptt.setState("push-to-mute")
    end

    init_apply_complete = true
  end

  ----------------------------------------------------------------------
  -- mute (PTT) by default
  wh.onAppQuit(app, function()
    ptt.setState("push-to-talk")
    hs.application.get("KeyCastr"):kill()
    init_apply_complete = false
  end)
end

return M
