local obj = { tmux = {} }

obj.__index = obj
obj.name = "utils"
obj.debug = false

obj.dndCmd = os.getenv("HOME") .. "/.dotfiles/bin/dnd"
obj.slckCmd = os.getenv("HOME") .. "/.dotfiles/bin/slck"

function obj.template(template, vars) return string.gsub(template, "{(.-)}", vars) end

--- utils.scriptPath([n]) -> string
--- Function
--- Return path of the current spoon.
---
--- Parameters:
---  * n - (optional) stack level for which to get the path. Defaults to 2, which will return the path of the spoon which called `scriptPath()`
---
--- Returns:
---  * String with the path from where the calling code was loaded.
function obj.scriptPath(n)
  if n == nil then n = 2 end
  local str = debug.getinfo(n, "S").source:sub(2)
  return str:match("(.*/)")
end

--- utils.resourcePath(partial) -> string
--- Function
--- Return full path of an object within a spoon directory, given its partial path.
---
--- Parameters:
---  * partial - path of a file relative to the Spoon directory. For example `images/img1.png` will refer to a file within the `images` directory of the Spoon.
---
--- Returns:
---  * Absolute path of the file. Note: no existence or other checks are done on the path.
function obj.resourcePath(partial) return (obj.scriptPath(3) .. partial) end

function obj.eventString(e)
  local a = hs.application.watcher

  if type(e) == "string" then return e end

  local enum_tbl = {
    [0] = { "launching", a.launching },
    [1] = { "launched", a.launched },
    [2] = { "terminated", a.terminated },
    [3] = { "hidden", a.hidden },
    [4] = { "unhidden", a.unhidden },
    [5] = { "activated", a.activated },
    [6] = { "deactivated", a.deactivated },
  }

  return table.unpack(enum_tbl[e])
end

function obj.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end

---@param dndStatus boolean|string dnd status on or off as a boolean to pass to the dnd binary
---@param slackStatus string|nil slack status to pass to the slck binary
function obj.dnd(dndStatus, slackStatus)
  if type(dndStatus) == "boolean" then dndStatus = dndStatus and "on" or "off" end

  if dndStatus ~= nil then
    hs.task
      .new(obj.dndCmd, function(_exitCode, _stdOut, _stdErr) info("[RUN] dnd/" .. dndStatus) end, { dndStatus })
      :start()
  end

  -- if slackStatus ~= nil and slackStatus ~= "" then obj.slack(slackStatus) end
end

-- TODO:
-- https://github.com/kiooss/dotmagic/blob/master/hammerspoon/slack.lua
function obj.slack(slackStatus)
  if slackStatus ~= nil and slackStatus ~= "" then
    local slck = hs.task.new("/opt/homebrew/bin/zsh", function(exitCode, stdOut, stdErr)
      dbg({ exitCode, stdOut, stdErr }, true)
      info("[RUN] slack/" .. slackStatus)
    end, { "-lc", obj.slckCmd, slackStatus })
    -- local slck = hs.task.new(obj.slckCmd, function(stdTask, stdOut, stdErr)
    --   dbg({ stdTask, stdOut, stdErr }, true)
    --   info("[SLCK]: " .. slackStatus)
    -- end, { slackStatus })
    slck:setEnvironment({
      TERM = "xterm-256color",
      -- HOMEBREW_PREFIX = "/opt/homebrew",
      -- HOME = os.getenv("HOME"),
      -- PATH = os.getenv("PATH") .. ":/opt/homebrew/bin",
    })

    slck:start()

    dbg({ slck }, true)
  end
end

function obj.tmux.update()
  hs.task.new("/opt/homebrew/bin/tmux", function() end, { "refresh-client" }):start()
end

return obj
