-- rwt.lua: Rex actions for worktree sessions made by bin/rwt. init.lua loads
-- it with require("rwt"). Try it without reloading the config:
--   rex do -s SESSION ~/.config/rex/rwt.lua --action rwt_restart_services
local RWT = os.getenv("HOME") .. "/.dotfiles/bin/rwt"
local TERMINAL = "com.superlogical.terminal"

local function block_cwd(block_id)
  local p = rex.block.call(TERMINAL, "process", { block_id = block_id })
  local proc = p and (p.foreground or p.child)
  return proc and proc.cwd
end

-- The focused pane may be the dead services terminal, which has no process
-- and so no cwd; fall back to any live pane in the session.
local function session_cwd(ctx)
  local cwd = ctx.block_id and block_cwd(ctx.block_id)
  if cwd then return cwd end
  local blocks = rex.session.list_blocks{}
  for _, b in ipairs(blocks and blocks.blocks or {}) do
    cwd = block_cwd(b.block_id)
    if cwd then return cwd end
  end
end

local function rwt(ctx, ...)
  local cwd = session_cwd(ctx)
  if not cwd then error("no pane in this session reports a working directory", 0) end
  local argv = { RWT, ... }
  table.insert(argv, cwd)
  table.insert(argv, "--session")
  table.insert(argv, ctx.session_id)
  table.insert(argv, "--json")
  local r, err = rex.exec(argv, { timeout = 25 })
  if r == nil then error(err, 0) end
  local result = rex.json.decode(r.stdout)
  if not r.ok then error(result and result.error or r.stderr, 0) end
  return result
end

rex.action{
  name = "rwt_restart_services",
  title = "Restart Worktree Services",
  description = "Stop the services pane (Phoenix) of this worktree session and start it again in a fresh terminal.",
  category = "Worktree",
  keywords = "phoenix server restart worktree",
  run = function(ctx) return rwt(ctx, "restart") end,
}

rex.action{
  name = "rwt_status",
  title = "Worktree Status",
  description = "Show the worktree, services, port, and Tidewave state of this session.",
  category = "Worktree",
  run = function(ctx) return rwt(ctx, "status") end,
}

rex.bind("cmd+shift+r", "rwt_restart_services")
