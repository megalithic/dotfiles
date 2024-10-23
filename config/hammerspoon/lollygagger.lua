local enum = req("hs.fnutils")
local utils = req("utils")

local obj = {}
local cache = { timers = {} }

obj.__index = obj
obj.name = "lollygagger"
obj.debug = true
obj.cache = cache

local function killApp(app)
  if app == nil then return end
  app:kill()
end

local function killWin(win)
  if win == nil then return end
  win:close()
end

obj.quitAfter = function(app, interval, event)
  if interval ~= nil then
    local bundleID = app:bundleID()

    if bundleID and app:isRunning() then
      if cache.timers[bundleID] ~= nil then cache.timers[bundleID]:stop() end

      if event == hs.application.watcher.deactivated then
        note(fmt("[RUN] %s/%s/quitting in %sm", obj.name, app:bundleID(), interval))
        cache.timers[bundleID] = hs.timer.doAfter((interval * 60), function()
          killApp(app)
          note(fmt("[RUN] %s/%s/quit", obj.name, app:bundleID()))
        end)
      end
    end
  else
    return
  end
end

obj.hideAfter = function(app, interval, event)
  if interval ~= nil then
    local bundleID = app:bundleID()

    if bundleID and app:isRunning() then
      if cache.timers[bundleID] ~= nil then cache.timers[bundleID]:stop() end

      if event == hs.application.watcher.deactivated then
        note(fmt("[RUN] %s/%s/hiding in %sm", obj.name, app:bundleID(), interval))
        cache.timers[bundleID] = hs.timer.doAfter((interval * 60), function()
          app:hide()
          note(fmt("[RUN] %s/%s/hidden", obj.name, app:bundleID(), interval))
        end)
      end
    end
  else
    return
  end
end

function obj:run(_elementOrAppName, event, app)
  local config = LOLLYGAGGERS[app:bundleID()]

  if config then
    local hideAfter, quitAfter = table.unpack(config)
    if hideAfter then self.hideAfter(app, hideAfter, event) end
    if quitAfter then self.quitAfter(app, quitAfter, event) end
  end
end
function obj:start() info(fmt("[START] %s", self.name)) end

return obj
