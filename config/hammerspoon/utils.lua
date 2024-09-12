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

function obj.truncate(str, width, at_tail)
  local ellipsis = "…"
  local n_ellipsis = #ellipsis

  -- HT: https://github.com/lunarmodules/Penlight/blob/master/lua/pl/stringx.lua#L771-L796
  --- Return a shortened version of a string.
  -- Fits string within w characters. Removed characters are marked with ellipsis.
  -- @string s the string
  -- @int w the maxinum size allowed
  -- @bool tail true if we want to show the end of the string (head otherwise)
  -- @usage ('1234567890'):shorten(8) == '12345...'
  -- @usage ('1234567890'):shorten(8, true) == '...67890'
  -- @usage ('1234567890'):shorten(20) == '1234567890'
  local function shorten(s, w, tail)
    if s == nil then return "" end
    if #s > w then
      if w < n_ellipsis then return ellipsis:sub(1, w) end
      if tail then
        local i = #s - w + 1 + n_ellipsis
        return ellipsis .. s:sub(i)
      else
        return s:sub(1, w - n_ellipsis) .. ellipsis
      end
    end
    return s
  end

  return shorten(str, width, at_tail)
end

---@param status boolean|string|nil dnd status on or off as a boolean to pass to the dnd binary
function obj.dnd(status)
  if type(status) == "boolean" then status = status and "on" or "off" end

  if status ~= nil then
    hs.task.new(obj.dndCmd, function(_exitCode, _stdOut, _stdErr) info("[RUN] dnd/" .. status) end, { status }):start()
  else
    hs.task.new(obj.dndCmd, function(_exitCode, _stdOut, _stdErr) info("[RUN] dnd/toggle") end, { "toggle" }):start()
  end
end

-- TODO:
-- https://github.com/kiooss/dotmagic/blob/master/hammerspoon/slack.lua
---@param status string|nil slack status to pass to the slck binary
function obj.slack(status)
  dbg(status, true)
  if status ~= nil and status ~= "" then
    -- local slck = hs.task.new("/opt/homebrew/bin/zsh", function(exitCode, stdOut, stdErr)
    --   dbg({ exitCode, stdOut, stdErr }, true)
    --   info("[RUN] slack/" .. slackStatus)
    -- end, { "-lc", obj.slckCmd, slackStatus })
    local slck = hs.task.new(obj.slckCmd, function(_exitCode, _stdOut, _stdErr) end, function(stdTask, stdOut, stdErr)
      dbg({ stdTask, stdOut, stdErr }, true)
      local continue = true
      -- info("[SLCK]: " .. slackStatus)
      return continue
    end, { status })

    -- local slck = hs.task.new(
    --   "/opt/homebrew/bin/zsh",
    --   function(_exitCode, _stdOut, _stdErr) end,
    --   function(stdTask, stdOut, stdErr)
    --     dbg({ stdOut, stdErr }, true)
    --     stdOut = string.gsub(stdOut, "^%s*(.-)%s*$", "%1")
    --
    --     local continue = true
    --     -- local continue = stdOut == fmt([[input audio device set to "%s"]], device)
    --     --
    --     -- if continue then success(fmt("[%s] audio input set to %s", obj.name, device)) end
    --
    --     return continue
    --   end,
    --   { "-lc", obj.slckCmd, "-r", slackStatus }
    -- )
    slck:setEnvironment({
      TERM = "xterm-256color",
      HOMEBREW_PREFIX = "/opt/homebrew",
      --   -- HOME = os.getenv("HOME"),
      PATH = os.getenv("PATH") .. ":/opt/homebrew/bin",
    })
    slck:start()

    -- dbg({ slck }, true)
  end
end

function obj.tmux.update()
  hs.task.new("/opt/homebrew/bin/tmux", function() end, { "refresh-client" }):start()
end

function obj.tmux.focusDailyNote()
  local term = hs.application.get(TERMINAL)
  if term then
    hs.application.launchOrFocusByBundleID(TERMINAL)
    -- mimics pressing the tmux prefix `ctrl-space`,
    hs.eventtap.keyStroke({ "ctrl" }, "space", term)
    -- then the daily note binding, `ctrl-o`.
    hs.eventtap.keyStroke({ "ctrl" }, "o", term)
  end
end

return obj
