--  ┌─────────────────────────────────────────────────────────────────────────┐
--  │ window management/auto layouts..                                        │
--  │─────────────────────────────────────────────────────────────────────────│
--  │ 1. start                                                                │
--  │ 2. prepare                                                              │
--  │ 3. applyAutoLayout                                                      │
--  │ 4. applyWindowFilters                                                   │
--  │ 5. handleFilters                                                        │
--  │ 6. applyContext                                                         │
--  └─────────────────────────────────────────────────────────────────────────┘

local log = hs.logger.new("[wm]", "debug")

local cache = {
  dock_watcher = {},
  windowFilter = {}
}

local M = {
  cache = cache
}

local wh = require("utils.wm.window-handlers")
local fn = require("hs.fnutils")

M.numScreens = 0

-- applyLayout(hs.window, hs.application, table, {hs.window, hs.window, hs.window}, string) :: nil
-- evaluates and applies global config for layout related to the given app
M.applyLayout = function(win, app, app_config, windows, event)
  log.df("applyLayout::%s -> [%s, %s(%s)]", event, win, app:bundleID(), #windows)

  wh.snapRelated(app, app_config, windows.valid)
end

-- applyContext(hs.window, hs.application, table, {hs.window, hs.window, hs.window}, string) :: nil
-- evaluates and applies global config for contexts related to the given app
M.applyContext = function(win, bundleID, app_config, windows, event)
  if app_config.context == nil then
    return
  end

  local context = require("contexts")
  if context == nil then
    return
  end

  log.df("applyContext::%s -> [%s, %s(%s)]", event, win, bundleID, #windows.valid)
  context.load(event, win, app_config.context, "info")
end

-- autoLayout(hs.window, string, string) :: nil
-- evaluates and sets up layout and contexts for an app/window
M.handleFilters = function(win, appName, event)
  local app = win:application()
  if app == nil then
    return
  end

  log.df("handleFilters::%s -> [%s, %s, %s]", event, app:bundleID(), appName, win:title())

  local app_config = config.apps[app:bundleID()]
  if app_config == nil then
    return
  end

  -- ignore certain window titles that we apply specific app config rules to
  local ignoredWindowTitles = wh.ignoredWindowTitles(app_config)

  -- only valid windows that fit certain window/app requirements
  local validWindows = wh.validWindows(app)

  -- only managed windows that we want to layout from an "app" level perspective
  -- e.g., no windows that might be getting contextual rules applied
  local managed = wh.managedWindows(app, validWindows, ignoredWindowTitles)

  -- a table of our various windows we might want to use/manipulate
  local windows = {
    all = app:allWindows(),
    valid = validWindows,
    managed = managed
  }

  if #windows.all == 0 then
    log.wf("autoLayout::%s (ignoring) -> no valid windows found [%s (all: %s)]", event, app:bundleID(), #windows.all)
    return
  else
    -- if fn.contains({"windowCreated", "windowDestroyed"}, event) then
    --   M.applyLayout(win, app, app_config, windows, event)
    -- end

    M.applyContext(win, app:bundleID(), app_config, windows, event)
  end
end

-- M.autoLayout = function(win, appName, event)
--   local app = win:application()
--   if app == nil then return end

--   log.df("autoLayout::%s -> [%s, %s, %s]", event, app:bundleID(), appName, win:title())

--   local app_config = config.apps[app:bundleID()]
--   if app_config == nil then return end

--   -- ignore certain window titles that we apply specific app config rules to
--   local ignoredWindowTitles = wh.ignoredWindowTitles(app_config)

--   -- only valid windows that fit certain window/app requirements
--   local validWindows = wh.validWindows(app)

--   -- only managed windows that we want to layout from an "app" level perspective
--   -- e.g., no windows that might be getting contextual rules applied
--   local managed = wh.managedWindows(app, validWindows, ignoredWindowTitles)

--   -- a table of our various windows we might want to use/manipulate
--   local windows = {
--     all = app:allWindows(),
--     valid = validWindows,
--     managed = managed
--   }

--   if #windows.all == 0 then
--     log.wf("autoLayout::%s (ignoring) -> no valid windows found [%s (all: %s)]", event, app:bundleID(), #windows.all)
--     return
--   else
--     if fn.contains({"windowCreated", "windowDestroyed"}, event) then
--       M.applyLayout(win, app, app_config, windows, event)
--     end

--     M.applyContext(win, app, app_config, windows, event)
--   end
-- end

M.setAppLayout = function(app_config)
  local bundleID = app_config["bundleID"]
  if app_config.rules and #app_config.rules > 0 then
    log.wf("applyAutoLayout::%s", bundleID, hs.inspect(app_config.rules))

    fn.map(
      app_config.rules,
      function(rule)
        if rule["title"] ~= nil or rule["action"] ~= nil or rule["position"] ~= nil then
          return
        end

        local title_pattern, screen, position = rule[1], rule[2], rule[3]
        local layout = {
          hs.application.get(bundleID), -- application name
          hs.window.find(title_pattern), -- window title
          wh.targetDisplay(screen), -- screen #
          position, -- layout/postion
          nil,
          nil
        }

        table.insert(M.layouts, layout)
      end
    )
  end
end

M.applyAppLayout = function(app)
  if app ~= nil then
    local app_config = config.apps[app:bundleID()]
    M.setAppLayout(app_config)
    hs.layout.apply(M.layouts)
  end
end

M.applyAutoLayout = function()
  M.layouts = {}

  fn.map(
    config.apps,
    function(app_config)
      M.setAppLayout(app_config)
    end
  )

  hs.layout.apply(M.layouts)
end

M.applyWindowFilters = function()
  local appFilters = M.generateAppFilters()

  log.i("preparing apps for window filtering ->", hs.inspect(appFilters))

  cache.windowFilter =
    hs.window.filter.new(appFilters):subscribe(hs.window.filter.windowCreated, M.handleFilters, true):subscribe(
    hs.window.filter.windowDestroyed,
    M.handleFilters,
    true
  ):subscribe(hs.window.filter.windowFocused, M.handleFilters, true):subscribe(
    hs.window.filter.windowUnfocused,
    M.handleFilters,
    true
  )
end

-- prepare() :: nil
-- evaluates global config and obeys the rules.
M.prepare = function()
  M.applyAutoLayout()
  M.applyWindowFilters()
end

-- generateAppFilters() :: {string}
-- generates a table of application names for applying window filters
M.generateAppFilters = function()
  local appFilters = {}

  for appBundleID, app_config in pairs(config.apps) do
    if app_config == nil or appBundleID == "_" then
      return
    end

    table.insert(appFilters, app_config.name)
  end

  return appFilters
end

-- appCleanup(hs.application) :: nil
-- does app-wide cleanup of window filters
-- FIXME: finish this
M.appCleanup = function(app)
  if app == nil then
    return
  end

  log.df("unsubscribing window filter events -> %s", app:bundleID())
  cache.windowFilter[app:name()]:unsubcribe()
end

-- initialize watchers
M.start = function()
  log.i("starting..")

  -- watch for docking status changes
  cache.dock_watcher = hs.watchable.watch("status.isDocked", M.prepare)
  cache.application_watcher = hs.application.watcher.new(M.applyAppLayout)

  -- initial invocation
  M.prepare()
end

M.stop = function()
  log.i("stopping..")

  cache.windowFilter:unsubscribeAll()
  cache.windowFilter = nil
end

return M
