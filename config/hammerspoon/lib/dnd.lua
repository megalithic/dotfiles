local Settings = require("hs.settings")

local obj = {}

obj.__index = obj
obj.name = "dnd"
obj.cmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"
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

-- M.dndHandler = function(app, dndConfig, event)
--   if dndConfig == nil then
--     return
--   end

--   local mode = dndConfig.mode

--   if dndConfig.enabled then
--     -- FIXME: hs.task.new .. i hate you; i cannot get env variables and such in
--     -- to my script. :/
--     -- local slackCmd = os.getenv("HOME") .. "/.dotfiles/bin/slack"
--     local dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"

--     if event == running.events.created or event == running.events.launched then
--       log.df("DND Handler: on/" .. mode)

--       cmd_updater(dndCmd .. " on", false)
--       -- cmd_updater(slackCmd .. " -sv " .. mode, false)

--       M.onAppQuit(app, function()
--         cmd_updater(dndCmd .. " off", false)
--         -- cmd_updater(slackCmd .. " -sv back", false)
--       end)
--     elseif event == event == running.events.terminated then
--       M.onAppQuit(app, function()
--         cmd_updater(dndCmd .. " off", false)
--         -- cmd_updater(slackCmd .. " -sv back", false)
--       end)
--     elseif type(event) == "table" and event.which ~= nil then
--       cmd_updater(string.format("%s %s", dndCmd, event.which)) -- which: on | off
--     end
--   end
-- end

-- local function run(args, use_prefix)
--   local function split(str)
--     local t = {}
--     for token in string.gmatch(str, "[^%s]+") do
--       table.insert(t, token)
--     end
--     return t
--   end

--   if args ~= nil then
--     local cmd
--     local cmd_args = split(args)

--     if use_prefix ~= nil and use_prefix then
--       cmd = "/usr/local/bin/zsh"
--       table.insert(cmd_args, 1, "-ic")
--     else
--       cmd = table.remove(cmd_args, 1)
--     end

--     -- spews errors, BUT, it seems to work async! yay?
--     local task = hs.task.new(cmd, function(stdTask, stdOut, stdErr) end, cmd_args):start()

--     return task

--     -- NOTE: keep this in case hs.task fails again
--     -- return hs.execute(args, true)
--   end

--   return nil
-- end

function obj.on()
  local task = hs.task.new(obj.cmd, function(stdTask, stdOut, stdErr) dbg("dnd on") end, { "on" })
  task:start()
end

function obj.off()
  local task = hs.task.new(obj.cmd, function(stdTask, stdOut, stdErr) dbg("dnd off") end, { "off" })
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
