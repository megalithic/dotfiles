local log = hs.logger.new('[contexts.zoom]', 'debug')

-- TODO:
-- 1. DND toggling
-- 2. Window layout and closing
-- 3. Spotify pause
-- 4. Check output/input and set correctly
-- 5. Set PTT is on (e.g., mute by default)

local cache  = {}
local module = { cache = cache, }

local wh = require('utils.wm.window-handlers')
local spotify = require('bindings.media').spotify
local ptt = require('bindings.ptt')

local rules = {
  {title = 'Zoom', action = 'quit'},
  {title = 'Zoom Meeting', action = 'snap'},
}

-- apply(string, hs.window)
module.apply = function(event, win)
  log.df("applying [contexts.zoom] for %s..", event)

  local app = win:application()
  if app == nil then return end

  if hs.fnutils.contains({"windowCreated"}, event) then
    ----------------------------------------------------------------------
    -- handle DND toggling
    log.df("toggling DND for %s..", event)
    wh.dndHandler(win, { enabled = true, mode = "zoom" }, event)

    ----------------------------------------------------------------------
    -- naively handle spotify pause (always pause it, no matter the event)
    log.df("pausing spotify for %s..", event)
    spotify('pause')

    ----------------------------------------------------------------------
    -- mute (PTT) by default
    ptt.setState("push-to-talk")
  elseif hs.fnutils.contains({"windowDestroyed"}, event) then
    if not hs.application.find(app:name()) then
      log.df("no longer running! [%s]", hs.application.find(app:name()))
      ptt.setState("push-to-talk")
    end
  end

  ----------------------------------------------------------------------
  -- handle window rules
  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil then return end

  if not hs.fnutils.contains({"windowDestroyed"}, event) then
    wh.applyRules(rules, win, appConfig)
  end
end

return module
