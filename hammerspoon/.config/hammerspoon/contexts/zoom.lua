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
        local kitty = hs.application.get("kitty")

        hs.timer.waitUntil(
          function()
            return zoom:getWindow("Zoom Meeting")
          end,
          function()
            -- local task =
            --   hs.task.new(
            --   os.getenv("HOME") .. "/.dotfiles/bin/zetty",
            --   function(ec, o, e)
            --     log.wf("exiting task: %s / %s / %s", ec, o, e)
            --     return true
            --   end, -- noop callback
            --   function(t, o, e)
            --     log.wf("launching task: %s / %s / %s", hs.inspect(t), o, e)
            --     return true
            --   end,
            --   {"meeting"}
            -- )
            -- log.wf("task to start: %s", hs.inspect(task))
            -- task:start()

            hs.execute(os.getenv("HOME") .. "/.dotfiles/bin/zetty meeting", true)

            local target_close_window = zoom:getWindow("Zoom")
            if target_close_window ~= nil then
              target_close_window:close()
            end

            local layouts = {
              {"zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, nil, nil},
              {"kitty", "note", hs.screen.primaryScreen():name(), hs.layout.right50, nil, nil}
            }
            hs.layout.apply(layouts)
            kitty:setFrontmost(true)
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

      local kitty = hs.application.get("kitty")
      kitty:setFrontmost(true)

      local layouts = {
        {"kitty", nil, hs.screen.primaryScreen():name(), hs.layout.fullScreen, nil, nil}
      }
      hs.layout.apply(layouts)
    end
  )
end

return M
