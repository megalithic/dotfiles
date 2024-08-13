local enum = require("hs.fnutils")
local utils = require("utils")
local obj = {}

obj.__index = obj
obj.name = "contexts"
obj.debug = false
obj.contextsPath = utils.resourcePath("./")
obj.contextModals = {}

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
      hs.application.watcher.terminated,
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

function obj.prepareContextScripts(contextsScriptsPath)
  contextsScriptsPath = contextsScriptsPath or obj.contextsPath
  local iterFn, dirObj = hs.fs.dir(contextsScriptsPath)
  if iterFn then
    for file in iterFn, dirObj do
      if string.sub(file, -3) == "lua" then
        local basenameAndBundleID = string.sub(file, 1, -5)
        local script = dofile(contextsScriptsPath .. file)
        if basenameAndBundleID ~= "init" then
          if script.modal then script.modal = hs.hotkey.modal.new() end

          if script.actions ~= nil then
            for _, value in pairs(script.actions) do
              local hotkey = value.hotkey
              if hotkey then
                local mods, key = table.unpack(hotkey)
                script.modal:bind(mods, key, value.action)
              end
            end
          end

          obj.contextModals[basenameAndBundleID] = script
        end
      end
    end
  end

  return obj.contextModals
end

function obj:start()
  info(fmt("[START] %s", self.name))

  return self.prepareContextScripts()
end

return obj
