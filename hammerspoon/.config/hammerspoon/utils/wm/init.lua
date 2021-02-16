--  ┌─────────────────────────────────────────────────────────────────────────┐
--  │ window management/auto layouts..                                        │
--  │─────────────────────────────────────────────────────────────────────────│
--  │ 1. start                                                                │
--  │ 2. prepare                                                              │
--  │ 3. create new app watcher                                               │
--  │ 4. create running app watcher                                           │
--  │ 5. apply app layout                                                     │
--  │ 6. apply app context                                                    │
--  └─────────────────────────────────────────────────────────────────────────┘

local log = hs.logger.new("[wm]", "warning")

local cache = {
  dock_watcher = {},
  new_app_watcher = {},
  running_app_watcher = {},
  element_event_watcher = {}
}

local M = {
  cache = cache
}

local wh = require("utils.wm.window-handlers")
local fn = require("hs.fnutils")

local gather_windows = function(app)
  if app == nil then
    return
  end

  local app_config = Config.apps[app:bundleID()]
  if app_config == nil then
    return
  end

  -- ignore certain window titles that we apply specific app config rules to
  local ignoredWindowTitles = wh.ignoredWindowTitles(app_config)

  -- only valid windows that fit certain window/app requirements
  local validWindows = wh.validWindows(app)

  -- only managed windows that we want to layout from an "app" level perspective
  -- e.g., no windows that might be getting contextual rules applied
  local managedWindows = wh.managedWindows(app, validWindows, ignoredWindowTitles)

  -- a table of our various windows we might want to use/manipulate
  local windows = {
    all = app:allWindows(),
    valid = validWindows,
    managed = managedWindows
  }

  return windows
end

-- apply_context(hs.application, hs.application, table, {hs.window, hs.window, hs.window}, string) :: nil
-- evaluates and applies global config for contexts related to the given app
M.apply_context = function(app, bundleID, app_config, windows, event)
  if app_config.context == nil then
    log.wf("no context received; skipping -> %s", bundleID)
    return
  end

  if event == nil then
    log.wf("no event received; skipping -> %s", bundleID)
    return
  end

  local context = require("contexts")
  if context == nil then
    return
  end

  log.wf("apply_context[%s] -> %s - %s(%s)]", event, app, bundleID, #windows.valid)
  context.load(event, app, app_config.context, "info")
end

M.set_app_layout = function(app_config)
  if app_config == nil then
    return
  end

  local bundleID = app_config["bundleID"]
  local layouts = {}

  if app_config.rules and #app_config.rules > 0 then
    log.df("set_app_layout::%s", bundleID, hs.inspect(app_config.rules))

    fn.map(
      app_config.rules,
      function(rule)
        if rule["title"] ~= nil or rule["action"] ~= nil or rule["position"] ~= nil then
          return
        end

        local title_pattern, screen, position = rule[1], rule[2], rule[3]
        local layout = {
          hs.application.get(bundleID), -- application name
          title_pattern, -- window title
          wh.targetDisplay(screen), -- screen #
          position, -- layout/postion
          nil,
          nil
        }

        table.insert(layouts, layout)
      end
    )
  end

  return layouts
end

-- hs.uielement.watcher for an window
M.handle_window_element_event = function(element, event, window_watcher, info)
  log.wf("handle window element event for %s", hs.inspect(info))

  -- presently just handling the closed-window case
  if event == cache.element_event_watcher.elementDestroyed then
    -- FIXME:
    -- do we re-layout things for the given app?
    log.df("window %s destroyed for %s", info.id, element:application():bundleID())
    window_watcher:stop()
    -- nil that window in our watched windows for the running app
    cache.running_app_watcher[info.pid].windows[info.id] = nil
  else
    log.wf("window element event error; unexpected window event (%d) received", event)
  end
end

-- hs.uielement.watcher for an app
M.handle_app_element_event = function(element, event)
  -- presently just handling the opened-window case
  if event == cache.element_event_watcher.windowCreated then
    M.watch_existing_window(element)
  else
    log.wf("app element event error; unexpected window event (%d) received", event)
  end
end

-- standard hs.application.watcher
M.handle_app_event = function(app_name, event, app)
  -- presently just handling launched and terminated apps
  if event == hs.application.watcher.launched then
    log.df("app launched -> %s", app:bundleID())
    M.watch_running_app(app, event)
  elseif event == hs.application.watcher.terminated then
    -- Only the PID is set for terminated apps, so can't log bundleID.
    local pid = app:pid()
    log.df("app (%s) terminated -> %d", app_name, pid)
    M.unwatch_running_app(pid)
  end
end

-- gathers layout for a found app_config and applies it
M.apply_app_layout = function(app_name, app)
  log.df("attempting to apply layout for %s -> %s", app_name, hs.inspect(app))

  if app then
    local app_config = Config.apps[app:bundleID()]
    log.df("applying layout for %s -> %s", app_name, hs.inspect(app_config))

    local layouts = M.set_app_layout(app_config)
    if layouts ~= nil then
      log.df("apply_app_layout: app configs to layout: %s", hs.inspect(layouts))
      hs.layout.apply(layouts)
    end
  end
end

-- watches existing windows to deal with them being closed/terminated
M.watch_existing_window = function(window)
  local app = window:application()
  local bundleID = app:bundleID()
  local pid = app:pid()
  local watched_windows = cache.running_app_watcher[pid].windows
  local window_id = window:id()

  -- log.wf("watching existing window -> %s", hs.inspect(window))

  -- Watch for window-closed events, if a window with an ID exists..
  if window_id then
    if not watched_windows[window_id] then
      local window_watcher =
        window:newWatcher(
        M.handle_window_element_event,
        {
          id = window_id,
          pid = pid
        }
      )
      watched_windows[window_id] = window_watcher
      window_watcher:start({cache.element_event_watcher.elementDestroyed})
    end
  else
    log.wf("unable to watch window [%s - %s, %s]", window_id, bundleID, window:title())
  end
end

-- watches running apps to deal with new app windows being opened/created
M.watch_running_app = function(app, event)
  if not app then
    log.ef("app not found -> %s", hs.inspect(app))
    return
  end

  local pid = app:pid()
  local bundleID = app:bundleID()
  local app_name = app:name()
  log.df("running app watcher -> %s (%s [%s])", app_name, bundleID, pid)

  -- verify we don't already have this pid and app being watched; if so, ignore
  if cache.running_app_watcher[pid] then
    log.wf("running app watcher -> app (%s [%s]) already watched; ignoring.", bundleID, pid)
    return
  end

  -- begin watching for new/opened/created windows..
  -- create a special watcher on the app and its pid; we'll also watch it's
  -- windows, too.
  local app_watcher = app:newWatcher(M.handle_app_element_event)
  cache.running_app_watcher[pid] = {
    watcher = app_watcher,
    windows = {}
  }
  -- start up a special hs.uielement.watcher for windows and watch specifically
  -- for newly created windows.
  app_watcher:start({cache.element_event_watcher.windowCreated})

  -- begin watching for existing windows..
  -- TODO: determine if we want to handle on specific windows defined in our
  -- Config.apps configs..
  for _, window in pairs(app:allWindows()) do
    M.watch_existing_window(window)
  end

  -- an app config exists for app; e.g. it's managed in our Config.apps;
  -- apply the app layout..
  local app_config = Config.apps[bundleID]
  if app_config then
    log.df("attempting to apply app layout for %s -> %s", app_name, hs.inspect(app))
    M.apply_app_layout(app_name, app)

    log.df("attempting to apply context for %s -> %s", app_name, hs.inspect(app))
    -- gather_windows gets us interesting info about windows we have
    M.apply_context(app, bundleID, app_config, gather_windows(app), event)
  end
end

-- handles the removal and "unwatching" of an app for its given pid
M.unwatch_running_app = function(pid)
  local app_watcher = cache.running_app_watcher[pid]

  -- attempted to unwatch a non-managed app, perhaps?
  if not app_watcher then
    log.wf("attempted to unwatch a non-managed/unknown app with PID: %d", pid)
    return
  end

  -- otherwise, stop our watched app
  app_watcher.watcher:stop()
  for _, window_watcher in pairs(app_watcher.windows) do
    -- and, stop watching this app's windows, too.
    window_watcher:stop()
  end

  cache.running_app_watcher[pid] = nil
end

-- prepare(...) :: nil
-- evaluates global config and obeys the rules.
M.prepare = function()
  -- watch newly launched apps..
  cache.new_app_watcher = hs.application.watcher.new(M.handle_app_event)
  cache.new_app_watcher:start()

  -- watch running apps..
  local all_running_apps = hs.application.runningApplications()
  for _, app in pairs(all_running_apps) do
    local managed_app = Config.apps[app:bundleID()]
    -- we actually only want to watch running apps that have an app_config, aka,
    -- considered to be "managed".
    if managed_app ~= nil then
      log.df("found managed and running app -> %s (%s)", app:name(), app:bundleID())
      M.watch_running_app(app)
    end
  end
end

-- initialize watchers
M.start = function()
  log.i("starting..")

  -- watch for docking status changes..
  cache.dock_watcher = hs.watchable.watch("status.isDocked", M.prepare)
end

M.stop = function()
  log.i("stopping..")

  if cache.new_app_watcher then
    cache.new_app_watcher:stop()
  end

  for pid, _ in pairs(cache.running_app_watcher) do
    M.unwatch_running_app(pid)
  end
end

return M
