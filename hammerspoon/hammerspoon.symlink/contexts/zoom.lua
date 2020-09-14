local cache  = {}
local M = { cache = cache, }

local fn = require('hs.fnutils')
local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')
local browser = require('bindings.browser')
local init_apply_complete = false

-- apply(string, hs.window, hs.logger) :: nil
M.apply = function(event, win, log)
  local app = win:application()

  -- prevents excessive actions on multiple window creations
  if not init_apply_complete then
    if fn.contains({"windowCreated"}, event) then
      ----------------------------------------------------------------------
      -- handle DND toggling
      log.df("toggling DND for %s..", event)
      wh.dndHandler(win, { enabled = true, mode = "zoom" }, event)

      ----------------------------------------------------------------------
      -- pause spotify
      log.df("pausing spotify for %s..", event)
      spotify('pause')

      ----------------------------------------------------------------------
      -- mute (PTT) by default
      ptt.setState("push-to-talk")

      ----------------------------------------------------------------------
      -- close web browser "zoom launching" tabs
      browser.killTabsByDomain("zoom.us")
    end

    init_apply_complete = true
  end

  ----------------------------------------------------------------------
  -- things to do on app exit
  wh.onAppQuit(win, function()
    ptt.setState("push-to-talk")
    init_apply_complete = false
  end)

  ----------------------------------------------------------------------
  -- handle window rules
  if app == nil then return end

  local app_config = config.apps[app:bundleID()]
  if app_config == nil or app_config.rules == nil then return end

  if fn.contains({"windowCreated"}, event) then
    wh.applyRules(app_config.rules, win, app_config)
  end
end

return M
