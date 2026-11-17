-- rtm.lua: the rtm launcher (github.com/megalithic/rtm) in a floating layer.
-- init.lua loads it with require("rtm"). rtm comes from mise; RTM_BIN in the
-- Rex server's environment points at a development build instead.
local M = {}
local RTM = os.getenv("RTM_BIN") or (os.getenv("HOME") .. "/.local/share/mise/shims/rtm")

-- The rtm layer open in each session, so the key closes it again.
local open_layers = {}

-- A layer closes itself when rtm exits, and closing what is gone reports no
-- error, so look for it.
local function is_open(session_id, layer_id)
  local view = rex.session.view{ session_id = session_id }
  for _, window in ipairs(view and view.windows or {}) do
    for _, layer in ipairs(window.layers or {}) do
      if layer.layer_id == layer_id then return true end
    end
  end
  return false
end

-- Leave the prefix mode first, or its exclusive keys eat what rtm should get.
local function float(ctx, bounds, argv)
  rex.client.queue("client.mode.exit_all")
  local created = rex.session.new_layer{
    bounds = bounds,
    focus = true,
    layout = rex.layout.block{
      flavor = "com.superlogical.terminal.shell",
      options = { command = argv },
    },
  }
  local block_id = created and created.block_ids and created.block_ids[1]
  if block_id then rex.session.focus_block{ session_id = ctx.session_id, block_id = block_id } end
  return created
end

rex.action{
  name = "rtm",
  title = "rtm: Sessions and Agents",
  description = "List Ultimate instances and Rex sessions, what needs you first, and jump to one.",
  category = "Launcher",
  run = function(ctx)
    local session = ctx.session_id or ""
    local open = open_layers[session]
    open_layers[session] = nil
    if open and is_open(ctx.session_id, open) then
      rex.client.queue("client.mode.exit_all")
      rex.session.close_layer{ session_id = ctx.session_id, layer_id = open }
      return
    end
    local created = float(ctx, { 0.07, 0.07, 0.86, 0.86 },
      { RTM, "pick", ctx.client_id or "", ctx.block_id or "" })
    open_layers[session] = created and created.layer_id
    return created
  end,
}

-- Same prompt as ctrl+k in rtm: `kill <session>?`, y runs `rwt down`, which
-- stops the session's processes and keeps its worktree.
rex.action{
  name = "rtm_kill",
  title = "Kill Session (keep worktree)",
  description = "Stop this session's processes and close it; the worktree stays.",
  category = "Launcher",
  run = function(ctx)
    return float(ctx, { 0.3, 0.42, 0.4, 0.16 }, { RTM, "kill", ctx.session_id or "", ctx.client_id or "" })
  end,
}

-- The prefix key is the best sign Rex gives of the session in front of you:
-- it reports no "session shown" event. Kept in memory, so a key press costs
-- nothing; rtm reads it with `rex do rtm_seen` and keeps it in its own store.
local seen = {}
function M.seen(session_id)
  if session_id then seen[session_id] = os.time() * 1000 end
end

rex.action{
  name = "rtm_seen",
  title = "rtm: Sessions Seen",
  description = "When the prefix key was last pressed in each session (epoch ms).",
  category = "Launcher",
  run = function() return seen end,
}

return M
