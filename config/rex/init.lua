require("rexd") -- Plugins from rexd. Keep this first, so your own key bindings win.
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

-- ctrl+1..9: tmux window i inside tmux, Rex tab i elsewhere. An action, because
-- only actions can queue client actions.
rex.action{
  name = "tmux_or_tab_goto",
  title = "Go to tmux Window or Tab",
  args = { index = "integer" },
  run = function(ctx, args)
    if in_tmux(ctx) then
      write(ctx, "\0" .. args.index)
    else
      rex.client.queue("client.tab.goto", { index = args.index })
    end
  end,
}
for i = 1, 9 do
  rex.bind("ctrl+" .. i, "tmux_or_tab_goto", { index = i })
end
rex.bind("ctrl+0", function(ctx) -- tmux window 0; Rex tabs count from 1
  return in_tmux(ctx) and write(ctx, "\0" .. 0)
end)

-- ctrl+space is the prefix, as in tmux: inside tmux it goes to tmux, elsewhere
-- it enters the one-shot `prefix` mode. The mode is exclusive, so a key it
-- doesn't bind does nothing; Escape leaves it.
rex.action{
  name = "tmux_or_rex_prefix",
  title = "tmux Prefix or Rex Prefix Mode",
  run = function(ctx)
    if in_tmux(ctx) then
      write(ctx, "\0")
    else
      rex.client.queue("client.mode.enter", { name = "prefix", once = true })
    end
  end,
}
rex.bind("ctrl+space", "tmux_or_rex_prefix")
rex.mode("prefix", { exclusive = true })
-- Launcher/switcher: Rex's session switcher until our own launcher lands.
rex.bind("prefix/space", "session.switch")
rex.bind("prefix/ctrl+space", "session.switch")
rex.bind("prefix/ctrl+t", "client.tab.new")
rex.bind("prefix/ctrl+k", "session.close")

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

-- Pidewave: Cmd+Ctrl+Shift+C (same chord as in Helium) asks the Pi in this block,
-- or in the tmux pane shown in it, to take its Phoenix port's browser link and
-- start Tidewave Inspect. Blocks without such a Pi ignore the chord.
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
rex.bind("ctrl+shift+cmd+c", "pidewave_inspect")

-- Worktree sessions from bin/rwt: Cmd+Shift+R restarts the services pane.
require("rwt")

-- Open @ultimate: jump to the Ultimate running for this session's folder.
require("ultimate")
