-- Rex Beta config, linked to ~/.config/rex/init.lua by mise [dotfiles].
-- Apply edits with `rex config reload`; Rex does not watch this file.
-- Docs: https://www.superlogical.com/rex/docs/customize/config.md

local TERMINAL = "com.superlogical.terminal"

local function write(ctx, data)
  return rex.block.call(TERMINAL, "write", { block_id = ctx.block_id, data = data }) ~= nil
end

-- Bind a key to raw bytes typed into the focused terminal, like Ghostty's
-- `keybind = KEY=text:...`. Lua 5.1 has no \x escapes, so bytes are decimal.
local function send(key, data)
  rex.bind(key, function(ctx) return write(ctx, data) end)
end

-- tmux keys apply only where tmux runs in the pane, so plain Rex sessions
-- (bin/rwt) keep Rex's own meaning for them. Rex reports the foreground
-- group's leader, which is bash when bin/ftm runs tmux, so search the group.
local function in_tmux(ctx)
  local p = ctx.block_id and rex.block.call(TERMINAL, "process", { block_id = ctx.block_id })
  local fg = p and p.foreground
  if not fg then return false end
  if fg.name == "tmux" then return true end
  local r = rex.exec({ "/usr/bin/pgrep", "-g", tostring(fg.pid), "-x", "tmux" }, { timeout = 2 })
  return r ~= nil and r.ok
end

-- tmux: prefix is ctrl+space (NUL), see config/tmux/tmux.conf
for i = 0, 9 do
  rex.bind("ctrl+" .. i, function(ctx) -- go to tmux window i
    return in_tmux(ctx) and write(ctx, "\0" .. i)
  end)
end

-- New tmux window inside tmux, new Rex tab elsewhere. An action, because only
-- actions can queue client actions.
rex.action{
  name = "tmux_or_tab_new",
  title = "New tmux Window or Tab",
  run = function(ctx)
    if in_tmux(ctx) then write(ctx, "\0c") else rex.client.queue("client.tab.new") end
  end,
}
rex.bind("cmd+t", "tmux_or_tab_new")

-- shift+enter as CSI u so Pi and Claude Code insert a newline; tmux passes it
-- through with extended-keys-format csi-u.
send("shift+enter", "\27[13;2u")

-- Pidewave: Cmd+Shift+C asks the Pi in this block, or in the tmux pane shown
-- in it, to take its Phoenix port's browser link and start Tidewave Inspect.
-- Blocks without such a Pi ignore the chord (like Ghostty's cmd+shift+c=ignore).
rex.action{
  name = "pidewave_inspect",
  title = "Pidewave: Tidewave Inspect",
  run = function(ctx)
    local proc = rex.block.call("com.superlogical.terminal", "process", { block_id = ctx.block_id })
    local argv = { os.getenv("HOME") .. "/.dotfiles/bin/pidewave", "inspect", "--rex-block", ctx.block_id }
    if proc and proc.foreground and proc.foreground.pid then
      table.insert(argv, "--pid")
      table.insert(argv, tostring(proc.foreground.pid))
    end
    rex.exec(argv, { timeout = 5 })
  end,
}
rex.bind("shift+cmd+c", "pidewave_inspect")

-- Worktree sessions from bin/rwt: Cmd+Shift+R restarts the services pane.
require("rwt")
