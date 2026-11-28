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

-- `rtm inbox`, what waits on you across every Ultimate hub, in a session of
-- its own called `inbox`, kept first so the phone app has it as a tab. rtm
-- reports itself for Program Resume (OSC 7577); the rule lets Rex bring it
-- back after a restart, with no arguments but `inbox`. Rex 2582 gives its
-- terminals no OSC7577_TOKEN yet, so the action also starts rtm again in a
-- session that has lost it. Sessions move and windows open through the rex
-- CLI: from an action, session.move and list_blocks fail while no client is
-- attached to that session (409 "stream is not attached").
rex.set("resume.trust.rtm_inbox", { command = { "rtm", "inbox" } })

local INBOX = "inbox"
local TERMINAL = "com.superlogical.terminal"

-- An action's rex.exec finds no bare `rex`, so env looks it up on PATH.
local function cli(args)
  local argv = { "/usr/bin/env", "rex", "--autostart=false" }
  for _, arg in ipairs(args) do argv[#argv + 1] = arg end
  local result, err = rex.exec(argv, { timeout = 5 })
  if not result then error(err, 0) end
  if not result.ok then error(result.stderr ~= "" and result.stderr or result.stdout, 0) end
  return result.stdout
end

-- Whether some terminal in the session still runs `rtm inbox`.
local function running(session_id)
  local blocks = rex.json.decode(cli({ "block", "ls", "-s", session_id, "--json" }))
  for _, block in ipairs(blocks and blocks.blocks or {}) do
    if block.creator_name == TERMINAL then
      local process = rex.json.decode(cli({ "block", "call", "-b", block.block_id, "process" }))
      if process and process.foreground and process.foreground.name == "rtm" then return true end
    end
  end
  return false
end

rex.action{
  name = "rtm_inbox",
  title = "rtm: Inbox",
  description = "Go to the inbox session, starting it first when it isn't running.",
  category = "Launcher",
  run = function()
    rex.client.queue("client.mode.exit_all")
    local listed = rex.call("session.list")
    local sessions = listed and listed.sessions or {}
    local session_id
    for _, session in ipairs(sessions) do
      if session.label == INBOX then session_id = session.session_id end
    end
    if not session_id then
      local created = rex.json.decode(cli({ "new", INBOX, "--json", "--", RTM, "inbox" }))
      session_id = created.session_id
    elseif not running(session_id) then
      cli({ "window", "new", "-s", session_id, INBOX, "--", RTM, "inbox" })
    end
    if sessions[1] and sessions[1].session_id ~= session_id then
      cli({ "session", "move", session_id, "--index", "1" })
    end
    rex.client.queue("session.select", { session_id = session_id })
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
