--  ┌─────────────────────────────────────────────────────────────────────────┐
--  │ window management/auto layouts..                                        │
--  │─────────────────────────────────────────────────────────────────────────│
--  │ 1. start                                                                │
--  │ 2. prepare                                                              │
--  │ 3. create new app watcher                                               │
--  │ 4. create running app watcher                                           │
--  │ 5. apply app layout                                                     │
--  │ 6. set layouts for app                                                  │
--  │ 7. apply app context (if exists)                                        │
--  └─────────────────────────────────────────────────────────────────────────┘

local log = hs.logger.new("[wm]", "info")

local cache = {
  dock_watcher = {},
}

local M = {
  cache = cache,
}

local wh = require("wm.handlers")
local fn = require("hs.fnutils")
local running = require("wm.running")

-- return true if title matches pattern
local function match_title(title, pattern)
  if title == nil then
    return
  end

  -- if pattern starts with ! then reverse match
  if string.sub(pattern, 1, 1) == "!" then
    local actual_pattern = string.sub(pattern, 2, string.len(pattern))
    return not string.match(title, actual_pattern)
  else
    return string.match(title, pattern)
  end
end

M._set_app_layout = function(app_config)
  if app_config == nil then
    return
  end

  local bundleID = app_config["bundleID"]
  local layouts = {}

  if app_config.rules and #app_config.rules > 0 then
    log.df("set_app_layout::%s", bundleID, hs.inspect(app_config.rules))

    fn.map(app_config.rules, function(rule)
      -- hold-over to protect from old app configs
      -- TODO: remove if not needed
      if rule["title"] ~= nil or rule["action"] ~= nil or rule["position"] ~= nil then
        return
      end

      local title_pattern, screen, position = rule[1], rule[2], rule[3]

      log.df("set_app_layout::%s | %s, %s, %s", bundleID, title_pattern, screen, position)

      local layout = {
        hs.application.get(bundleID), -- application name
        title_pattern, -- window title
        -- hs.window.get(title_pattern), -- window title NOTE: this doesn't
        -- handle `nil` window title instances
        function()
          wh.targetDisplay(screen)
        end, -- screen #
        position, -- layout/postion
        nil,
        nil,
      }

      table.insert(layouts, layout)
    end)
  end

  return layouts
end

-- apply_context(hs.application, hs.application, table, {hs.window, hs.window, hs.window}, string) :: nil
-- evaluates and applies global config for contexts related to the given app
M.apply_app_context = function(app, win, event)
  local app_config = Config.apps[app:bundleID()]
  if app_config ~= nil then
    local context = app_config.context
    if context == nil then
      log.df("no context received; skipping -> %s", app:bundleID())
      return
    end

    if event == nil then
      log.df("no event received; skipping -> %s", app:bundleID())
      return
    end

    require("contexts").load(app, win, event, context, "info")
  end
end

-- gathers layout for a found app_config and applies it
M.apply_app_layout = function(app, _, event) -- app, win, event
  -- only apply app layout for launched apps
  if event == running.events.launched then
    -- if event == running.events.launched or event == running.events.created then
    log.df("attempting to apply layout for %s -> %s", app:name(), hs.inspect(app))

    if app then
      local app_config = Config.apps[app:bundleID()]
      log.df("applying layout for %s -> %s", app:name(), hs.inspect(app_config))

      local layouts_for_app = M._set_app_layout(app_config)
      if layouts_for_app ~= nil then
        log.df("apply_app_layout: app configs to layout: %s", hs.inspect(layouts_for_app))
        log.f("> layout:" .. app:name())

        hs.layout.apply(layouts_for_app, string.match)
      end
    end
  end
end

-- prepare(...) :: nil
-- evaluates global config and obeys the rules.
M.prepare = function(force_run)
  -- handle running app events
  running.onChange(M.apply_app_layout)
  running.onChange(M.apply_app_context)

  -- add configured apps to running app watcher
  for _, configured_app in pairs(Config.apps) do
    if configured_app ~= nil then
      local app = hs.application.find(configured_app.bundleID)
      if app ~= nil then
        log.df("-> adding configured app: %s (%s)", app:name(), app:bundleID())
        running.addToAppWatcher(app)

        if force_run then
          M.apply_app_layout(app, app:mainWindow(), running.events.launched)
          M.apply_app_context(app, app:mainWindow(), running.events.launched)
        end
      end
    end
  end
end

M.prepare_app = function(app_name)
  local app = hs.application.find(app_name)
  running.addToAppWatcher(app)
end

-- initialize watchers
M.start = function()
  log.f("starting..")
  PreventLayoutChange = false

  -- monitor all window/app events
  running.start()

  -- watch for docking status changes..
  cache.dock_watcher = hs.watchable.watch("status.isDocked", function(_, _, _, old, new) -- watcher, path, key, old, new
    log.f("___ preparing app layouts and contexts.. (o: %s, n: %s)", old, new)
    M.prepare()
  end)

  M.prepare(true)
end

M.stop = function()
  log.f("stopping..")
  PreventLayoutChange = false

  -- if cache.new_app_watcher then
  --   cache.new_app_watcher:stop()
  -- end

  -- for pid, _ in pairs(cache.running_app_watcher) do
  --   M.unwatch_running_app(pid)
  -- end
end

return M
