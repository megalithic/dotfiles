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
