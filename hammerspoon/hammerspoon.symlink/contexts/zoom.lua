local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')
local browser = require('bindings.browser')

-- apply(string, hs.window, hs.logger) :: nil
module.apply = function(event, win, log)
  local app = win:application()
  if app == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
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
  elseif hs.fnutils.contains({"windowDestroyed"}, event) then
    ----------------------------------------------------------------------
    -- mute (PTT) by default
    wh.onAppQuit(win, function()
      ptt.setState("push-to-talk")
    end)
  end

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil or appConfig.rules == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    wh.applyRules(appConfig.rules, win, appConfig)
  end
end

return module
