local Settings = require("hs.settings")
local Config = Settings.get(CONFIG_KEY)
local DockConfig = Config.dock
local DisplaysConfig = Config.displays

local WM = L.req("lib.wm")

local obj = {}

obj.__index = obj
obj.name = "watcher.dock"
obj.debug = true
obj.watchers = {
  dock = {},
  leeloo = {},
  display = {},
}

local function displayHandler(watcher, path, key, oldValue, isConnected)
  if isConnected then
    success("[dock] external display connected")
  else
    warn("[dock] external display disconnected")
  end
end

local function leelooHandler(watcher, path, key, oldValue, isConnected)
  local function setProfile(profile)
    local task = hs.task.new(
      [[/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli]],
      function() end, -- Fake callback
      function(task, stdOut, stdErr)
        -- dbg(fmt(":: setProfile -> task: %s, stdOut: %s, stdErr: %s", task, stdOut, stdErr))
        local continue = stdOut == ""
        return continue
      end,
      { "--select-profile", profile }
    )
    task:start()
  end

  if isConnected then
    success("[dock] leeloo connected")
    setProfile(DockConfig.docked.profile)
  else
    warn("[dock] leeloo disconnected")
    setProfile(DockConfig.undocked.profile)
  end
end

local function dockHandler(watcher, path, key, oldValue, isConnected)
  local function setWifi(state) hs.execute("networksetup -setairportpower airport " .. state, true) end

  local function setInput(state)
    local task = hs.task.new(
      "/usr/local/bin/SwitchAudioSource",
      function() end, -- Fake callback
      function(task, stdOut, stdErr)
        local continue = stdOut == string.format([[input audio device set to "%s"]], state)
        return continue
      end,
      { "-t", "input", "-s", state }
    )
    task:start()
  end

  if isConnected then
    hs.timer.doAfter(2, function()
      setWifi(DockConfig.docked.wifi)
      setInput(DockConfig.docked.input)
      success("[dock] dock connected")
      hs.notify.new({ title = "dock watcher", subTitle = fmt("%s connected", DockConfig.target.productName) }):send()
      WM.layoutRunningApps(Config.bindings.apps)
    end)
  else
    hs.timer.doAfter(2, function()
      setWifi(DockConfig.undocked.wifi)
      setInput(DockConfig.undocked.input)
      warn("[dock] dock disconnected")
      hs.notify.new({ title = "dock watcher", subTitle = fmt("%s disconnected", DockConfig.target.productName) }):send()
      WM.layoutRunningApps(Config.bindings.apps)
    end)
  end
end

function obj:start()
  obj.watchers.dock = hs.watchable.watch("status.dock", dockHandler)
  obj.watchers.display = hs.watchable.watch("status.display", displayHandler)
  obj.watchers.leeloo = hs.watchable.watch("status.leeloo", leelooHandler)

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
