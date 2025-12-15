local enum = req("hs.fnutils")
local fmt = string.format

local M = {}

M.__index = M
M.name = "contexts"
M.contextModals = {}

M.loggableEvents = {
  -- hs.uielement.watcher.windowCreated,
  -- hs.uielement.watcher.elementDestroyed,
  -- hs.uielement.watcher.titleChanged,
  -- hs.uielement.watcher.applicationActivated,
  -- hs.uielement.watcher.applicationDeactivated,
  hs.application.watcher.launched,
  -- hs.application.watcher.activated,
  -- hs.application.watcher.deactivated,
  hs.application.watcher.terminated,
}

function M:run(opts)
  local context = opts["context"]
  local app = opts["appObj"]
  local event = opts["event"]
  local bundleID = opts["bundleID"]
  local metadata = opts["metadata"]
  local contextId = opts["bundleID"] and bundleID or app:bundleID()

  if context == nil or U.tlen(context) == 0 then
    -- U.log.wf("[WARN] %s: No context found for %s", self.name, app:bundleID())
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
      appObj = app,
      bundleID = app:bundleID(),
      metadata = metadata,
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
      appObj = app,
      bundleID = app:bundleID(),
      metadata = metadata,
    })
  end

  if enum.contains(M.loggableEvents, event) then
    U.log.n(fmt("[RUN] %s/%s (%s)", self.name, contextId, U.eventString(event)))
  end

  return self
end

function M.preload()
  U.log.i("preloading")

  local contextsScriptsPath = U.resourcePath("./")

  local iterFn, dirObj = hs.fs.dir(contextsScriptsPath)
  if iterFn then
    for file in iterFn, dirObj do
      if string.sub(file, -3) == "lua" then
        local basenameAndBundleID = string.sub(file, 1, -5)
        local script = dofile(contextsScriptsPath .. file)
        if basenameAndBundleID ~= "init" then
          if script.actions ~= nil then
            script.modal = hs.hotkey.modal.new()
            for _, value in pairs(script.actions) do
              local hotkey = value.hotkey
              if hotkey then
                local mods, key = table.unpack(hotkey)
                script.modal:bind(mods, key, value.action)
              end
            end
          end

          M.contextModals[basenameAndBundleID] = script
        end
      end
    end
  end

  return M.contextModals
end

return M
