--  ┌─────────────────────────────────────────────────────────────────────────┐
--  │ window management/auto layouts..                                        │
--  │─────────────────────────────────────────────────────────────────────────│
--  │ 1. start                                                                │
--  │ 2. prepare                                                              │
--  │ 3. autoLayout                                                           │
--  │ 3. applyLayout | applyContext                                           │
--  └─────────────────────────────────────────────────────────────────────────┘

local log = hs.logger.new('[wm]', 'info')

local cache = {
  screenWatcher = {},
  windowFilter = {}
}

local module = {
  cache = cache
}

local wh = require("utils.wm.window-handlers")

module.numScreens = 0


-- applyLayout(hs.window, hs.application, table, {hs.window}, string) :: nil
-- evaluates and applies global config for layout related to the given app
module.applyLayout = function(win, app, appConfig, windows, event)
  log.df("applyLayout::%s -> [%s, %s(%s)]", event, win, app:bundleID(), #windows)

  wh.snapRelated(app, appConfig, windows)
end


-- applyContext(hs.window, hs.application, table, {hs.window}, string) :: nil
-- evaluates and applies global config for contexts related to the given app
module.applyContext = function(win, app, appConfig, windows, event)
  if appConfig.context == nil then return end

  local context = require('contexts')
  if context == nil then return end

  log.df("applyContext::%s -> [%s, %s(%s)]", event, win, app:bundleID(), #windows)
  context.load(event, win, appConfig.context, "info")
end


-- autoLayout(hs.window, string, string) :: nil
-- evaluates and sets up layout and contexts for an app/window
module.autoLayout = function(win, appName, event)
  local app = win:application()
  if app == nil then return end

  log.df("autoLayout::%s -> [%s, %s, %s]", event, app:bundleID(), appName, win:title())

  local appConfig = config.apps[app:bundleID()]
  if appConfig == nil then return end

  -- ignore certain window titles that we apply specific app config rules to
  local ignoredWindowTitles = wh.ignoredWindowTitles(appConfig)

  -- only valid windows that fit certain window/app requirements
  local validWindows = wh.validWindows(app)

  -- only managed windows that we want to layout from an "app" level perspective
  -- e.g., no windows that might be getting contextual rules applied
  local windows = wh.managedWindows(app, validWindows, ignoredWindowTitles)

  if #validWindows == 0 then
    log.wf("autoLayout::%s (ignoring) -> no valid windows found [%s]", event, app:bundleID())
    return
  else
    if hs.fnutils.contains({"windowCreated", "windowDestroyed"}, event) then
      module.applyLayout(win, app, appConfig, windows, event)
    end

    module.applyContext(win, app, appConfig, windows, event)
  end
end


-- prepare() :: nil
-- evaluates global config and obeys the rules.
module.prepare = function()
  local appFilters = module.generateAppFilters()

  log.i("preparing apps ->", hs.inspect(appFilters))

  cache.windowFilter = hs.window.filter.new(appFilters)
    :subscribe(hs.window.filter.windowCreated, module.autoLayout, true)
    :subscribe(hs.window.filter.windowDestroyed, module.autoLayout, true)
    :subscribe(hs.window.filter.windowFocused, module.autoLayout, true)
    :subscribe(hs.window.filter.windowUnfocused, module.autoLayout, true)
end


-- generateAppFilters() :: {string}
-- generates a table of application names for applying window filters
module.generateAppFilters = function()
  local appFilters = {}

  for appBundleID, appConfig in pairs(config.apps) do
    if appConfig == nil or appBundleID == "_" then return end

    table.insert(appFilters, appConfig.name)
  end

  return appFilters
end


-- appCleanup(hs.application) :: nil
-- does app-wide cleanup of window filters
-- FIXME: finish this
module.appCleanup = function(app)
  if app == nil then return end
  log.df("unsubscribing window filter events -> %s", app:bundleID())
  cache.windowFilter[app:name()]:unsubcribe()
end


-- initialize watchers
module.start = function()
  log.i("starting..")

  cache.screenWatcher = hs.screen.watcher.new(function()
    if module.numScreens ~= #hs.screen.allScreens() then
      module.numScreens = #hs.screen.allScreens()
      module.prepare()
    end
  end):start()

  -- initial invocation
  module.prepare()
end

module.stop = function()
  log.i("stopping..")

  cache.screenWatcher:stop()
  cache.screenWatcher = nil

  cache.windowFilter:unsubscribeAll()
  cache.windowFilter = nil
end

return module
