local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "_scratch"
obj.debug = true

local function info(...)
  if obj.debug then
    return _G.info(...)
  else
    return print("")
  end
end
local function dbg(...)
  if obj.debug then
    return _G.dbg(...)
  else
    return print("")
  end
end
local function note(...)
  if obj.debug then
    return _G.note(...)
  else
    return print("")
  end
end
local function success(...)
  if obj.debug then
    return _G.success(...)
  else
    return print("")
  end
end

function obj.setInput(state)
  local task = hs.task.new(
    "/usr/local/bin/SwitchAudioSource",
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      dbg(fmt(":: setInput -> task: %s, stdOut: %s, stdErr: %s", task, stdOut, stdErr))
      local continue = stdOut == string.format("input audio device set to \"%s\"", state)
      return continue
    end,
    { "-t", "input", "-s", state }
  )
  task:start()
end

function obj.setProfile(profile)
  local task = hs.task.new(
    [[/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli]],
    function() end, -- Fake callback
    function(task, stdOut, stdErr)
      dbg(fmt(":: setProfile -> task: %s, stdOut: %s, stdErr: %s", task, stdOut, stdErr))
      local continue = stdOut ~= string.format("[error] `%s` is not found.", profile)
      return continue
    end,
    { "--select-profile", profile }
  )
  task:start()
end

function obj:init(opts)
  opts = opts or {}

  return self
end

function obj:start(opts)
  opts = opts or {}

  return self
end

function obj:stop(opts)
  opts = opts or {}

  return self
end

return obj
