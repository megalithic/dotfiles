local cache = {}

local module = {cache = cache}
local wh = require("utils.wm.window-handlers")
-- local log = hs.logger.new("[slack]", "debug")
local init_apply_complete = false

local enter = function(app, log)
  log.wf("entering slack hotkey modal..")

  cache.modal:bind(
    {"ctrl"},
    "j",
    function()
      hs.eventtap.keyStroke({"alt"}, "down", app)
    end
  )
  cache.modal:bind(
    {"ctrl"},
    "k",
    function()
      hs.eventtap.keyStroke({"alt"}, "up", app)
    end
  )
  cache.modal:bind(
    {"ctrl", "shift"},
    "j",
    function()
      hs.eventtap.keyStroke({"alt", "shift"}, "down", app)
    end
  )
  cache.modal:bind(
    {"ctrl", "shift"},
    "k",
    function()
      hs.eventtap.keyStroke({"alt", "shift"}, "up", app)
    end
  )
  cache.modal:bind(
    {"cmd"},
    "w",
    function()
      hs.eventtap.keyStroke({}, "escape", app)
    end
  )
  cache.modal:bind(
    {"cmd"},
    "r",
    function()
      hs.eventtap.keyStroke({}, "escape", app)
    end
  )
  cache.modal:bind(
    {"ctrl"},
    "g",
    function()
      hs.eventtap.keyStroke({"cmd"}, "k", app)
    end
  )

  cache.modal:enter()
end

local exit = function(app, log)
  log.wf("exiting slack hotkey modal..")

  cache.modal:exit()
end

-- apply(string, hs.application, hs.logger) :: nil
module.apply = function(event, app, log)
  if not init_apply_complete then
    -- FIXME: figure out why/where/how/when to instantiate our modal for correct
    -- enabling/disabling of bindings for our various window events. Presently, it
    -- works, but we're instantiating THREE TIMES!!1!1!
    cache.modal = hs.hotkey.modal.new({}, nil)
    -- log.df("setting up context for %s [%s]", hs.inspect(app), event)

    ----------------------------------------------------------------------
    -- set-up hotkey modal
    if hs.fnutils.contains({"windowFocused", hs.application.watcher.activated, hs.application.watcher.unhidden, 5}, event) then
      if app:isFrontmost() then
        -- cache.modal = hs.hotkey.modal.new({}, nil)
        enter(app, log)
        log.wf("enabled bindings -> %s", #cache.modal.keys)
      end
    elseif hs.fnutils.contains({"windowUnfocused", hs.application.watcher.deactivated, hs.application.watcher.hidden, 6}, event) then
      if not app:isFrontmost() then
        exit(app, log)
        log.wf("disabled bindings -> %s", #cache.modal.keys)
      -- cache.modal = hs.hotkey.modal.new({}, nil)
      end
    end
    init_apply_complete = true
  end

  wh.onAppQuit(
    app,
    function()
      exit(app, log)
      init_apply_complete = false
    end
  )

  ----------------------------------------------------------------------
  -- handle hide-after interval
  wh.hideAfterHandler(app, 5, event)

  ----------------------------------------------------------------------
  -- handle window rules
  --   if app == nil then return end
  --
  --   local appConfig = config.apps[app:bundleID()]
  --   if appConfig == nil or appConfig.rules == nil then return end
  --
  --   if hs.fnutils.contains({"windowCreated"}, event) then
  --     wh.applyRules(appConfig.rules, win, appConfig)
  --   end
end

return module
