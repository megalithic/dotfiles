local cache = {}
local M = {cache = cache}

local fn = require("hs.fnutils")
local wh = require("utils.wm.window-handlers")
local spotify = require("bindings.media").media_control
local ptt = require("bindings.ptt")
local browser = require("bindings.browser")
local init_apply_complete = false

-- apply(string, hs.application, hs.logger) :: nil
M.apply = function(event, app, log)
  -- prevents excessive actions on multiple window creations
  if not init_apply_complete then
    if fn.contains({"windowCreated", hs.application.watcher.launched}, event) or app:isRunning() then
      ----------------------------------------------------------------------
      -- handle DND toggling
      wh.dndHandler(app, {enabled = true, mode = "zoom"}, event)

      ----------------------------------------------------------------------
      -- pause spotify
      spotify("pause")

      ----------------------------------------------------------------------
      -- mute (PTT) by default
      ptt.setState("push-to-talk")

      ----------------------------------------------------------------------
      -- close web browser "zoom launching" tabs
      browser.killTabsByDomain("zoom.us")

      do
        local zoom = hs.application.get("zoom.us")
        hs.timer.waitUntil(
          function()
            return zoom:getWindow("Zoom Meeting")
          end,
          function()
            local task =
              hs.task.new(
              os.getenv("HOME") .. "/.dotfiles/bin/zetty",
              function()
              end, -- noop callback
              function(t, o, e)
                log.df("launching kitty in new note mode: %s / %s / %s", hs.inspect(t), hs.inspect(o), hs.inspect(e))

                local target_close_window = zoom:getWindow("Zoom")
                if target_close_window ~= nil then
                  target_close_window:close()
                end

                local layouts = {
                  {"kitty", nil, hs.screen.primaryScreen():name(), hs.layout.right50, 0, 0},
                  {"zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, 0, 0}
                }
                hs.layout.apply(layouts)

                return true
              end,
              {"meeting"}
            )
            task:start()
          end
        )
      end
    end

    init_apply_complete = true
  end

  ----------------------------------------------------------------------
  -- things to do on app exit
  wh.onAppQuit(
    app,
    function()
      ptt.setState("push-to-talk")
      init_apply_complete = false
      local layouts = {
        {"kitty", nil, hs.screen.primaryScreen():name(), hs.layout.fullScreen, 0, 0}
      }
      hs.layout.apply(layouts)
    end
  )
end

return M
