local cache = {}
local M = { cache = cache }

local running = require("wm.running")
local wh = require("wm.handlers")
local spotify = require("bindings.media").media_control
local ptt = require("bindings.ptt")
local init_apply_complete = false

---@diagnostic disable-next-line: unused-local
M.apply = function(app, _win, event, log)
  local font_size_factor = 8.0

  log.df("context %s app event %s happening..", app:bundleID(), event)

  if not init_apply_complete then
    if event == running.events.launched or app:isRunning() and #app:allWindows() > 0 then
      local loom = hs.application.get("Loom")

      hs.timer.waitUntil(function()
        return loom:getWindow("Loom Camera")
      end, function()
        -- launch keycastr
        hs.application.launchOrFocus("KeyCastr")

        -- handle DND toggling
        wh.dndHandler(app, { enabled = true, mode = "zoom" }, event)

        -- naively handle spotify pause (always pause it, no matter the event)
        spotify("pause")

        -- unmute (PTM) by default
        ptt.setState("push-to-mute")

        -- increase font-size of kitty instance
        require("controlplane.dock").set_kitty_config(tonumber(Config.docking.docked.fontSize) + font_size_factor)
      end)
    end

    init_apply_complete = true
  end

  if event == running.events.terminated then
    log.wf("executing onAppQuit (event: %s) for: %s", event, app:bundleID())
    ---@diagnostic disable-next-line: unused-local
    -- reenable PTT (mute by default)
    ptt.setState("push-to-talk")

    -- kill keycastr, if it's running
    local keycastr = hs.application.get("KeyCastr")
    if keycastr ~= nil then
      keycastr:kill()
    end

    -- return to default kitty fontSize
    require("controlplane.dock").set_kitty_config(tonumber(Config.docking.docked.fontSize))

    init_apply_complete = false
  end
end

return M