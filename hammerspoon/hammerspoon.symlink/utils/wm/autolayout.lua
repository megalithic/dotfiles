local log = hs.logger.new('[wm.autolayout]', 'debug')

local cache = {
  screenWatcher = {},
  windowFilter = {}
}

local module = {
  cache = cache
}

module.numScreens = 0

-- targetDisplay(int) :: hs.screen
-- detect the current number of monitors and return target screen
module.targetDisplay = function(displayInt)
  local displays = hs.screen.allScreens()
  if displays[displayInt] ~= nil then
    return displays[displayInt]
  else
    return hs.screen.primaryScreen()
  end
end

-- module.buildLayout = function()
--   local layout = {}
--   table.insert(
--     layout,
--     {
--       ac.bundleID,
--       window,
--       module.targetDisplay(ac.preferredDisplay),
--       ac.position, -- hs.layout.maximized,
--       nil,
--       nil
--     }
--   )
--   hs.layout.apply(layout)
-- end

-- snap(hs.window, string, int)
-- does the actual hs.grid activities for positioning a given window
module.snap = function(win, position, preferredDisplay)
  if win == nil then return end

  hs.grid.set(win, position or hs.grid.get(win), module.targetDisplay(preferredDisplay))
end

-- snapRelated([table], table)
-- handles positioning of related windows for an app
module.snapRelated = function(windows, appConfig)
  if appConfig == nil or windows == nil then return end

  for index, win in pairs(windows) do
    if win == nil then return end

    if (index % 2 == 0) then -- even index/number
      module.snap(win, config.grid.rightHalf, appConfig.preferredDisplay)
    else -- odd index/number
      module.snap(win, config.grid.leftHalf, appConfig.preferredDisplay)
    end
  end
end

-- applyLayout(hs.window, string, string) :: nil
-- evaluates and applies global config for layout related to the given app
module.applyLayout = function(win, appName, event)
  log.df("applyLayout::%s -> [%s, %s]", event, win, appName)
  local app = win:application()

  if app == nil then return end
  local appConfig = config.apps[app:bundleID()]

  if appConfig == nil then return end
  local windows = app:allWindows()
  log.df("applyLayout::windows -> [%s, %s]", #windows, hs.inspect(windows))

  -- FIXME: when destroying it looks at the destroyed window as the _1_ actual
  -- window, when really it should be ignored.
  if #windows == 1 then
    module.snap(win, appConfig.position, appConfig.preferredDisplay)
  elseif #windows > 1 then
    module.snapRelated(windows, appConfig)
  end

  -- module.applyContext(win, appName, event)
end

-- applyContext(hs.window, string, string) :: nil
-- evaluates and applies global config for contexts related to the given app
module.applyContext = function(win, appName, event)
  log.df("applyContext::%s -> [%s, %s]", event, win, appName)
  local appConfig = config.apps[win:application():bundleID()]

  if appConfig == nil or appConfig.context == nil then return end

  local context = require('contexts.' .. appConfig.context)

  if context == nil then return end
  context.apply(event)
end

-- prepare() :: nil
-- evaluates global config and obeys the rules.
module.prepare = function()
  local appFilters = {}

  for appBundleID, appConfig in pairs(config.apps) do
    if appConfig == nil or appBundleID == "_" then return end

    table.insert(appFilters, appConfig.name)
  end

  log.df("preparing -> [%s]", hs.inspect(appFilters))

  cache.windowFilter = hs.window.filter.new(appFilters)
    :subscribe(hs.window.filter.windowCreated, module.applyLayout, true)
    :subscribe(hs.window.filter.windowDestroyed, module.applyLayout, true)
    :subscribe(hs.window.filter.windowFocused, module.applyContext, true)
    :subscribe(hs.window.filter.windowUnfocused, module.applyContext, true)
end

module.appCleanup = function(app)
  if app == nil then return end
  log.df("unsubscribing window filter events -> %s", app:bundleID())
  cache.windowFilter[app]:unsubcribe()
end

-- initialize watchers
module.start = function()
  log.i("starting..")

  cache.screenWatcher = hs.screen.watcher.new(function()
    if module.numScreens ~= #hs.screen.allScreens() then
      module.prepare()
      module.numScreens = #hs.screen.allScreens()
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
