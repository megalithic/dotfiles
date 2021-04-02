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
      log.df("toggling DND for event %s..", event)
      wh.dndHandler(app, {enabled = true, mode = "zoom"}, event)

      ----------------------------------------------------------------------
      -- pause spotify
      log.df("pausing spotify for event %s..", event)
      spotify("pause")

      ----------------------------------------------------------------------
      -- mute (PTT) by default
      ptt.setState("push-to-talk")

      ----------------------------------------------------------------------
      -- close web browser "zoom launching" tabs
      browser.killTabsByDomain("zoom.us")

      do
        -- local kitty = hs.application.get("kitty")
        local zoom = hs.application.get("zoom.us")
        -- local drafts = hs.application.get("Drafts")

        -- local buttonValue, inputValue =
        --   hs.dialog.textPrompt(
        --   "Meeting Note Title",
        --   "If you don't enter anything we'll just use the derived data from the calendar"
        -- )

        -- log.wf("dialog input -> buttonValue: %s, inputValue: %s", buttonValue, inputValue)

        -- local hammerspoon = hs.application.get("Hammerspoon")
        -- hammerspoon:activate(true)

        hs.timer.waitUntil(
          function()
            return zoom:getWindow("Zoom Meeting")
            -- and buttonValue == "OK"
          end,
          function()
            local task =
              hs.task.new(
              os.getenv("HOME") .. "/.dotfiles/bin/zetty",
              function()
              end, -- Fake callback
              function(t, o, e)
                log.wf("launching kitty in new note mode: %s / %s / %s", t, o, e)

                local target_close_window = zoom:getWindow("Zoom")
                if target_close_window ~= nil then
                  target_close_window:close()
                end

                local layouts = {
                  {"kitty", "Meeting Note", hs.screen.primaryScreen():name(), hs.layout.right50, 0, 0},
                  -- {"Drafts", drafts:mainWindow():title(), hs.screen.primaryScreen():name(), hs.layout.right50, 0, 0},
                  {"zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, 0, 0}
                }
                hs.layout.apply(layouts)

                -- drafts:setFrontmost()
                return true
              end,
              {"meeting", ""}
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
    end
  )
end

return M
