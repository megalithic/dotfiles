local log = hs.logger.new("[bindings.quitguard]", "debug")

local modal = hs.hotkey.modal.new("cmd", "q")
local cache = { modal = modal }
local module = { cache = cache }

local alert = require("ext.alert")

-- Press Cmd+Q twice to actually quit
local quitAlertText = function(name)
  if name ~= nil then
    return string.format("Press <⌘-q> again to quit %s", name)
  else
    return "Press <⌘-q> again to quit"
  end
end

local enter = function()
  local app = hs.application.frontmostApplication()
  app:kill()
end

local exit = function()
  cache.modal:exit()
end

function cache.modal:entered()
  local app = hs.application.frontmostApplication()
  if app then
    log.f("quitguard::%s -> attempting..", app:bundleID())
  end

  if app == nil then
    log.wf("quitguard::%s ->  frontmost application found..")
    return
  end

  local appConfig = Config.apps[app:bundleID()]

  if appConfig == nil or appConfig.quitGuard == nil then
    log.wf("quitguard::%s -> not configured; quitting..", app:bundleID())
    enter()
  else
    log.df("quitguard::%s -> configured; waiting..", app:bundleID())

    if appConfig.quitGuard then
      alert.show({ text = quitAlertText(app:name()), duration = 1 })
      hs.timer.doAfter(1, function()
        cache.modal:exit()
      end)
    else
      cache.modal:exit()
      log.df("quitguard::%s -> acknowledged; quitting..", app:bundleID())

      enter()
    end
  end
end

module.start = function()
  cache.modal:bind("cmd", "q", enter)
  cache.modal:bind("", "escape", exit)
end

module.stop = function()
  cache.modal:exit()
  cache.modal = nil
end

return module
