local obj = {}
local cache = { timers = {} }

obj.__index = obj
obj.name = "lollygagger"
obj.debug = true
obj.cache = cache

local dbg = function(...)
  if obj.debug then return _G.dbg(fmt(...), false) end
end

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
        note(fmt("[lollygagger.quit(%s)] will quit %s after %sm", U.eventName(event), app:bundleID(), interval))
        cache.timers[bundleID] = hs.timer.doAfter((interval * 60), function()
          killApp(app)
          note(fmt("[lollygagger.quit] killing %s", app:bundleID()))
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
        note(fmt("[lollygagger.hide(%s)] will hide %s after %sm", U.eventName(event), app:bundleID(), interval))
        cache.timers[bundleID] = hs.timer.doAfter((interval * 60), function()
          app:hide()
          note(fmt("[lollygagger.hide] hiding %s", app:bundleID()))
        end)
      end
    end
  else
    return
  end
end

return obj
