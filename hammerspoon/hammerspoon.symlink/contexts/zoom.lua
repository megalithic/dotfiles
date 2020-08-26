local log = hs.logger.new('[contexts.zoom]', 'info')

-- TODO:
-- 4. Check output/input and set correctly

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')

-- apply(string, hs.window) :: nil
module.apply = function(event, win)
  local app = win:application()
  if app == nil then return end

  log.f("applying [contexts.zoom] for %s (%s)..", event, win:title())

  if hs.fnutils.contains({"windowCreated"}, event) then
    ----------------------------------------------------------------------
    -- handle DND toggling
    log.f("toggling DND for %s..", event)
    wh.dndHandler(win, { enabled = true, mode = "zoom" }, event)

    ----------------------------------------------------------------------
    -- naively handle spotify pause (always pause it, no matter the event)
    log.f("pausing spotify for %s..", event)
    spotify('pause')

    ----------------------------------------------------------------------
    -- mute (PTT) by default
    ptt.setState("push-to-talk")
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
