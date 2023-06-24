local Settings = require("hs.settings")

local WM = L.req("lib.wm")
local alert = require("utils.alert")

local obj = {}

obj.__index = obj
obj.name = "watcher.dock"
obj.debug = false
obj.watchers = {
  dock = {},
  leeloo = {},
  display = {},
}

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

local function displayHandler(_watcher, _path, _key, _oldValue, isConnected)
  if isConnected then
    success("[watcher.dock] external display connected")
    hs.screen.find(C.displays.external):setPrimary()
  else
    warn("[watcher.dock] external display disconnected")
    -- FIXME: errors here occassionally
    local internal = hs.screen.find(C.displays.internal)
    if internal ~= nil then internal:setPrimary() end
  end
end

local function leelooHandler(_watcher, _path, _key, _oldValue, isConnected)
  local function setProfile(profile)
    dbg("attempting to set profile to: %s", profile)
    local task = hs.task.new(
      [[/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli]],
      function() end, -- Fake callback
      function(task, stdOut, stdErr)
        if stdErr then
          error(fmt("[watcher.dock] error occurred for setProfile: %s", stdErr))
        else
          dbg("setProfile output: %s", stdOut)
        end
        -- dbg(fmt(":: setProfile -> task: %s, stdOut: %s, stdErr: %s", task, stdOut, stdErr))
        local continue = stdOut == ""
        return continue
      end,
      { "--select-profile", profile }
    )
    task:start()
  end

  if isConnected then
    setProfile(C.dock.keyboard.connected)
    success(fmt("[watcher.dock] leeloo connected (%s)", C.dock.keyboard.connected))
  else
    setProfile(C.dock.keyboard.disconnected)
    warn(fmt("[watcher.dock] leeloo disconnected (%s)", C.dock.keyboard.disconnected))
  end
end

function obj.setWifi(state)
  hs.execute("networksetup -setairportpower airport " .. state, true)
  success(fmt("[watcher.dock] wifi set to %s", state))
end

function obj.setInput(state)
  local bin = hostname() == "megabookpro" and "/opt/homebrew/bin/SwitchAudioSource"
    or "/usr/local/bin/SwitchAudioSource"
  local task = hs.task.new(
    bin,
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local continue = stdOut == string.format([[input audio device set to "%s"]], state)
      success(fmt("[watcher.dock] audio input set to %s", state))
      return continue
    end,
    { "-t", "input", "-s", state }
  )
  task:start()
end

---@param dockState "docked"|"undocked"
function obj.refreshInput(dockState)
  dockState = dockState or "docked"
  local state = C.dock[dockState].input
  local bin = hostname() == "megabookpro" and "/opt/homebrew/bin/SwitchAudioSource"
    or "/usr/local/bin/SwitchAudioSource"
  local task = hs.task.new(
    bin,
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local continue = stdOut == string.format([[input audio device set to "%s"]], state)
      success(fmt("[watcher.dock] audio input set to %s", state))
      return continue
    end,
    { "-t", "input", "-s", state }
  )
  task:start()
end

local function dockHandler(watcher, _path, _key, _oldValue, isConnected)
  local connectedState = isConnected and "docked" or "undocked"
  local notifier = isConnected and _G.success or _G.warn
  local icon = isConnected and "🖥️" or "💻"

  info(fmt("[dock] handling docking state changes (%s)", connectedState))

  local function processDockedState(state)
    obj.setWifi(C.dock[state].wifi)
    obj.setInput(C.dock[state].input)
    notifier(fmt("[watcher.dock] %s transitioned to %s state", icon, state))

    alert.close()
    alert.show(fmt("%s Transitioned to %s state", icon, state))
  end

  -- if watcher == nil then
  processDockedState(connectedState)
  -- else
  --   hs.timer.doAfter(1, function() processDockedState(connectedState) end)
  -- end

  hs.timer.doAfter(1, function() WM.layoutRunningApps(C.bindings.apps) end)
  -- WM.layoutRunningApps(C.bindings.apps)
end

function obj:start()
  obj.watchers.dock = hs.watchable.watch("status.dock", dockHandler)
  obj.watchers.display = hs.watchable.watch("status.display", displayHandler)
  obj.watchers.leeloo = hs.watchable.watch("status.leeloo", leelooHandler)

  -- run dock handler on start
  -- dockHandler(nil, nil, nil, nil, obj.watchers.dock._active)

  return self
end

function obj:stop()
  if obj.watchers then
    hs.fnutils.each(obj.watchers, function(watcher)
      if watcher then watcher:release() end
    end)
  end

  return self
end

return obj
