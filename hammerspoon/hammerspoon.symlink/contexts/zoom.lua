local cache  = {}
local module = { cache = cache, }

local fn = require('hs.fnutils')
local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')
local browser = require('bindings.browser')
local initApplyComplete = false

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()

  -- prevents excessive actions on multiple window creations
  if not initApplyComplete then
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
      browser.killTabsByDomain("enbala.zoom.us")
    end

    initApplyComplete = true
  end

  ----------------------------------------------------------------------
  -- mute (PTT) by default
  wh.onAppQuit(win, function()
    ptt.setState("push-to-talk")
    initApplyComplete = false
  end)

  ----------------------------------------------------------------------
  -- handle window rules
  if app == nil then return end

  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if fn.contains({"windowCreated"}, event) then
    wh.applyRules(appConfig.rules, win, appConfig)
  end
end

return module
