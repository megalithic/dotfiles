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

      -- require("utils/controlplane/dock").set_kitty_config(tonumber(Config.docking.docked.fontSize) + 10.0)
    end

    init_apply_complete = true
  end

  ----------------------------------------------------------------------
  -- mute (PTT) by default
  wh.onAppQuit(app, function()
    -- require("utils/controlplane/dock").set_kitty_config(Config.docking.docked.fontSize)
    ptt.setState("push-to-talk")

    local keycastr = hs.application.get("KeyCastr")
    if keycastr ~= nil then
      keycastr:kill()
    end

    init_apply_complete = false
  end)
end

return M
