local enum = req("hs.fnutils")
local fmt = string.format

local M = {}

M.__index = M
M.name = "contexts"
M.contextModals = {}

-- Global flags for runtime control via console/CLI
-- Disable at runtime: _G.APP_MODALS_ENABLED = false
-- Enable debug: _G.DEBUG = true
if _G.DEBUG == nil then _G.DEBUG = false end
if _G.APP_MODALS_ENABLED == nil then _G.APP_MODALS_ENABLED = true end

-- Events that trigger context activation
M.activationEvents = {
  hs.application.watcher.activated,
  hs.application.watcher.launched,
  hs.uielement.watcher.windowCreated,
  hs.uielement.watcher.titleChanged,
  hs.uielement.watcher.applicationActivated,
}

-- Events that trigger context deactivation
M.deactivationEvents = {
  hs.application.watcher.terminated,
  hs.application.watcher.deactivated,
  hs.uielement.watcher.elementDestroyed,
  hs.uielement.watcher.titleChanged,
  hs.uielement.watcher.applicationDeactivated,
}

M.loggableEvents = {
  hs.application.watcher.launched,
  hs.application.watcher.terminated,
}

-- Helper: check if event is activation type
local function isActivationEvent(event)
  return enum.contains(M.activationEvents, event)
end

-- Helper: check if event is deactivation type
local function isDeactivationEvent(event)
  return enum.contains(M.deactivationEvents, event)
end

-- Helper: exit ALL active modals (defensive cleanup)
-- Ensures no stale modals remain active when switching apps
local function exitAllActiveModals(exceptContextId)
  for bundleID, ctx in pairs(M.contextModals) do
    if bundleID ~= exceptContextId and ctx.modal and ctx._modalActive then
      ctx._modalActive = false
      ctx.modal:exit()
      U.log.df("[CTX] CLEANUP: exited stale modal for %s", bundleID)
    end
  end
end

function M:run(opts)
  local context = opts["context"]
  local app = opts["appObj"]
  local event = opts["event"]
  local bundleID = opts["bundleID"]
  local metadata = opts["metadata"]
  local contextId = opts["bundleID"] and bundleID or app:bundleID()

  if context == nil or U.tlen(context) == 0 then
    return self
  end

  local eventStr = U.eventString(event) or tostring(event)

  -- DEBUG: Log all incoming events
  U.log.df("[CTX] EVENT: %s | app=%s | modal=%s | _modalActive=%s",
    eventStr, contextId, context.modal and "yes" or "no", tostring(context._modalActive))

  local callOpts = {
    event = event,
    appObj = app,
    bundleID = app:bundleID(),
    metadata = metadata,
  }

  if isActivationEvent(event) then
    -- DEBUG: Log activation attempt
    U.log.df("[CTX] ACTIVATION: %s | modalsEnabled=%s", contextId, tostring(_G.APP_MODALS_ENABLED))

    -- Centralized modal management (disable at runtime: _G.APP_MODALS_ENABLED = false)
    if _G.APP_MODALS_ENABLED and context.modal and not context._modalActive then
      -- Defensive cleanup: exit any other active modals first
      exitAllActiveModals(contextId)
      context._modalActive = true
      context.modal:enter()
      U.log.df("[CTX] MODAL ENTERED: %s", contextId)
    end

    -- Call context's custom activation hook if defined
    if context.onActivate then
      context:onActivate(callOpts)
    -- Backward compatibility: call start() if no onActivate
    elseif context.start then
      context:start(callOpts)
    end

  elseif isDeactivationEvent(event) then
    -- DEBUG: Log deactivation attempt
    U.log.df("[CTX] DEACTIVATION: %s | modalsEnabled=%s", contextId, tostring(_G.APP_MODALS_ENABLED))

    -- Centralized modal management (disable at runtime: _G.APP_MODALS_ENABLED = false)
    if _G.APP_MODALS_ENABLED and context.modal and context._modalActive then
      context._modalActive = false
      context.modal:exit()
      U.log.df("[CTX] MODAL EXITED: %s", contextId)
    end

    -- Call context's custom deactivation hook if defined
    if context.onDeactivate then
      context:onDeactivate(callOpts)
    -- Backward compatibility: call stop() if no onDeactivate
    elseif context.stop then
      context:stop(callOpts)
    end
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
          -- Create modal if context has actions defined
          if script.actions ~= nil then
            script.modal = hs.hotkey.modal.new()
            script._modalActive = false -- Initialize guard flag

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
