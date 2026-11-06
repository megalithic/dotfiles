-- Rex Beta config, linked to ~/.config/rex/init.lua by mise [dotfiles].
-- Apply edits with `rex config reload`; Rex does not watch this file.
-- Docs: https://www.superlogical.com/rex/docs/customize/config.md

-- Bind a key to raw bytes typed into the focused terminal, like Ghostty's
-- `keybind = KEY=text:...`. Lua 5.1 has no \x escapes, so bytes are decimal.
local function send(key, data)
  rex.bind(key, function(ctx)
    return rex.block.call("com.superlogical.terminal", "write", {
      block_id = ctx.block_id,
      data = data,
    }) ~= nil
  end)
end

-- tmux: prefix is ctrl+space (NUL), see config/tmux/tmux.conf
for i = 0, 9 do
  send("ctrl+" .. i, "\0" .. i) -- go to tmux window i
end
send("cmd+t", "\0c") -- new tmux window

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
