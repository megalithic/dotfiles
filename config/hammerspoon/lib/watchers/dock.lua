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
    hs.screen.find(Config.displays.external):setPrimary()
  else
    warn("[dock] external display disconnected")
    hs.screen.find(Config.displays.laptop):setPrimary()
  end
  WM.layoutRunningApps(Config.bindings.apps)
end

local function leelooHandler(watcher, path, key, oldValue, isConnected)
  local function setProfile(profile)
    local task = hs.task.new(
      [[/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli]],
      function() end, -- Fake callback
      function(task, stdOut, stdErr)
        if stdErr then
          error(fmt("[dock] error occurred for setProfile: %s", stdErr))
        else
          debug(fmt("[dock] setProfile output: %s", stdOut))
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
    setProfile(DockConfig.docked.profile)
    success("[dock] leeloo connected")
  else
    setProfile(DockConfig.undocked.profile)
    warn("[dock] leeloo disconnected")
  end
end

function obj.setWifi(state)
  hs.execute("networksetup -setairportpower airport " .. state, true)
  success(fmt("[dock] wifi set to %s", state))
end

function obj.setInput(state)
  local bin = hostname() == "megabookpro" and "/opt/homebrew/bin/SwitchAudioSource"
    or "/usr/local/bin/SwitchAudioSource"
  local task = hs.task.new(
    bin,
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      local continue = stdOut == string.format([[input audio device set to "%s"]], state)
      success(fmt("[dock] audio input set to %s", state))
      return continue
    end,
    { "-t", "input", "-s", state }
  )
  task:start()
end

local function dockHandler(watcher, path, key, oldValue, isConnected)
  info("[dock] handling docking state changes")

  local dock = function()
    obj.setWifi(DockConfig.docked.wifi)
    obj.setInput(DockConfig.docked.input)
    -- hs.notify.new({ title = "dock watcher", subTitle = fmt("%s connected", DockConfig.target.productName) }):send()
    success("[dock] dock connected")
    -- WM.layoutRunningApps(Config.bindings.apps)
  end

  local undock = function()
    obj.setWifi(DockConfig.undocked.wifi)
    obj.setInput(DockConfig.undocked.input)
    -- hs.notify.new({ title = "dock watcher", subTitle = fmt("%s disconnected", DockConfig.target.productName) }):send()
    warn("[dock] dock disconnected")
    -- WM.layoutRunningApps(Config.bindings.apps)
  end

  if isConnected then
    if watcher == nil then
      dock()
    else
      hs.timer.doAfter(1, dock)
    end
  else
    if watcher == nil then
      undock()
    else
      hs.timer.doAfter(1, undock)
    end
  end
end

function obj:start()
  obj.watchers.dock = hs.watchable.watch("status.dock", dockHandler)
  obj.watchers.display = hs.watchable.watch("status.display", displayHandler)
  obj.watchers.leeloo = hs.watchable.watch("status.leeloo", leelooHandler)

  -- run dock handler on start
  dockHandler(nil, nil, nil, nil, obj.watchers.dock._active)

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
