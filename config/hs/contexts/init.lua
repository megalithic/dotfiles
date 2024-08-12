local enum = require("hs.fnutils")
local utils = require("utils")
local obj = {}

obj.__index = obj
obj.name = "contexts"
obj.debug = false

obj.loggableEvents = {
  hs.application.watcher.activated,
  hs.application.watcher.launched,
  hs.uielement.watcher.windowCreated,
  hs.uielement.watcher.applicationActivated,
  hs.application.watcher.deactivated,
  hs.application.watcher.terminated,
  hs.uielement.watcher.applicationDeactivated,
}

function obj:run(opts)
  local context = opts["context"]
  local appObj = opts["appObj"]
  local event = opts["event"]
  local bundleID = opts["bundleID"]
  local contextId = opts["bundleID"] and bundleID or appObj:bundleID()

  if not context then
    -- warn(fmt("[WARN] %s: No context found for %s", self.name, bundleID))
    return self
  end

  if
    enum.contains({
      hs.application.watcher.activated,
      hs.application.watcher.launched,
      hs.uielement.watcher.windowCreated,
      hs.uielement.watcher.titleChanged,
      hs.uielement.watcher.applicationActivated,
    }, event)
  then
    context:start({
      event = event,
      appObj = appObj,
      bundleID = appObj:bundleID(),
    })
  elseif
    enum.contains({
      hs.application.watcher.deactivated,
      hs.uielement.watcher.elementDestroyed,
      hs.uielement.watcher.titleChanged,
      hs.uielement.watcher.applicationDeactivated,
    }, event)
  then
    context:stop({
      event = event,
      appObj = appObj,
      bundleID = appObj:bundleID(),
    })
  end

  if enum.contains(obj.loggableEvents, event) then
    note(fmt("[RUN] %s/%s (%s)", self.name, contextId, utils.eventEnums(event)))
  end

  return self
end

function obj:start()
  info(fmt("[START] %s", self.name))
  return self
end

function obj:stop()
  info(fmt("[STOP] %s", self.name))
  return self
end

return obj
