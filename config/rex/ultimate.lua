-- ultimate.lua: jump to the Ultimate whose project contains this session's cwd.
-- Enable with require("ultimate") in init.lua.
local INSTANCE = os.getenv("HOME") .. "/.dotfiles/bin/ultimate-instance"
local TERMINAL = "com.superlogical.terminal"

local function block_cwd(block_id)
  local p = rex.block.call(TERMINAL, "process", { block_id = block_id })
  local proc = p and (p.foreground or p.child)
  return proc and proc.cwd
end

local function session_cwd(ctx)
  local cwd = ctx.block_id and block_cwd(ctx.block_id)
  if cwd then return cwd end
  local blocks = rex.session.list_blocks{}
  for _, b in ipairs(blocks and blocks.blocks or {}) do
    cwd = block_cwd(b.block_id)
    if cwd then return cwd end
  end
end

rex.action{
  name = "ultimate_open",
  title = "Open @ultimate",
  category = "Ultimate",
  run = function(ctx)
    local cwd = session_cwd(ctx)
    if not cwd then error("no pane in this session reports a working directory", 0) end
    local result, err = rex.exec({ INSTANCE, cwd }, { timeout = 5 })
    if not result then error(err, 0) end
    if not result.ok then error("no Ultimate instance runs for " .. cwd, 0) end
    local instance, decode_err = rex.json.decode(result.stdout)
    if not instance then error(decode_err, 0) end

    local sessions, list_err = rex.call("session.list")
    if not sessions then error(list_err, 0) end
    for _, session in ipairs(sessions.sessions or {}) do
      local blocks, blocks_err = rex.session.list_blocks{ session_id = session.session_id }
      if not blocks then error(blocks_err, 0) end
      for _, block in ipairs(blocks.blocks or {}) do
        if block.creator_name == TERMINAL then
          local process = rex.block.call(TERMINAL, "process", { block_id = block.block_id })
          if process and process.foreground and process.foreground.pid == instance.pid then
            local focused, focus_err = rex.session.focus_block{
              session_id = session.session_id, block_id = block.block_id,
            }
            if not focused then error(focus_err, 0) end
            rex.client.queue("session.select", { session_id = session.session_id })
            return
          end
        end
      end
    end
    local opened, open_err = rex.exec({ "/usr/bin/open", instance.url }, { timeout = 5 })
    if not opened then error(open_err, 0) end
    if not opened.ok then error("could not open Ultimate: " .. opened.stderr, 0) end
  end,
}
