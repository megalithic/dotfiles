local cache = {}
local M = {cache = cache}

local fn = require("hs.fnutils")
local wh = require("utils.wm.window-handlers")
local spotify = require("bindings.media").media_control
local ptt = require("bindings.ptt")
-- local browser = require("bindings.browser")
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

      -- FIXME: something is dying/failing with this:
      -- 2020-12-16 11:31:30: -- Loading extension: osascript
      -- 2020-12-16 11:31:30: 11:31:30 ERROR:                 LuaSkin: Unable to initialize script: {
      --   NSLocalizedDescription = "Error on line 29: SyntaxError: Multiline comment was not closed properly";
      --   NSLocalizedFailureReason = "Error on line 29: SyntaxError: Multiline comment was not closed properly";
      --   OSAScriptErrorBriefMessageKey = "Error on line 29: SyntaxError: Multiline comment was not closed properly";
      --   OSAScriptErrorMessageKey = "Error on line 29: SyntaxError: Multiline comment was not closed properly";
      --   OSAScriptErrorNumberKey = "-2700";
      --   OSAScriptErrorRangeKey = "NSRange: {0, 0}";
      -- }

      ----------------------------------------------------------------------
      -- close web browser "zoom launching" tabs
      -- browser.killTabsByDomain("*.zoom.us")

      -- hs.timer.waitWhile(
      --   function()
      --     return not hs.application.get("com.agiletortoise.Drafts-OSX"):isFrontmost()
      --   end,
      --   function()
      local drafts = hs.application("Drafts")
      --       local template = string.format([[%s
      --       %s
      --         [%s](%s)
      --         ]], title, quote, title, url)
      --
      --       -- format and send to drafts
      --       hs.urlevent.openURL("drafts://x-callback-url/create?tag=links&text=" .. hs.http.encodeForQuery(template))
      drafts:setFrontmost()
      drafts:selectMenuItem("Enable Minimal Mode")
      drafts:selectMenuItem("Hide Draft list")
      drafts:selectMenuItem("Hide Filters")

      local layouts = {
        {"Drafts", drafts:mainWindow():title(), hs.screen.primaryScreen():name(), hs.layout.right50, 0, 0},
        {"zoom.us", "Zoom Meeting", hs.screen.primaryScreen():name(), hs.layout.left50, 0, 0}
      }

      hs.layout.apply(layouts)
    end
    --       )
    --     end
    --
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

  ----------------------------------------------------------------------
  -- handle window rules
  --   if app == nil then
  --     return
  --   end
  --
  --   local app_config = config.apps[app:bundleID()]
  --   if app_config == nil or app_config.rules == nil then
  --     return
  --   end
  --
  --   if fn.contains({"windowCreated"}, event) then
  --     -- wh.snapRelated()
  --     wh.applyRules(app_config.rules, win, app_config)
  --   end
end

return M
