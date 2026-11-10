-- rwt-layout.lua: the default Rex layout for one worktree session.
--
-- rwt runs it after setup succeeds:
--   rex do -s SESSION rwt-layout.lua --args '{"cwd": ..., "services": true, ...}'
--
-- To change the layout for one project without touching the repo, copy this
-- file to <repo>/.config/rex/layout.lua (.config/ is globally git-ignored and
-- listed in .worktreeinclude, so every new worktree gets the copy). Keep the
-- block label "services": rwt restart/logs/status find the server by it.
--
-- args: cwd, rwt, services (bool), services_cmd (argv), agent_input (text
-- typed into the agent shell, empty for no agent).
local a = rex.args
local SHELL = "com.superlogical.terminal.shell"

local function term(label, opts)
  opts = opts or {}
  opts.cwd = a.cwd
  return { block = { flavor = SHELL, label = label, options = opts } }
end

local out = { windows = {}, blocks = {} }

local function window(label, layout, names)
  local w, err = rex.session.new_window{ window_label = label, layout = layout, focus = false }
  if err ~= nil then error(label .. ": " .. err, 0) end
  out.windows[label] = w.window_id
  for i, name in ipairs(names) do out.blocks[name] = w.block_ids[i] end
end

window("code", term("code"), { "code" })

if a.services then
  -- The server is the block's own program, never typed into a shell, so a
  -- restart replaces the whole terminal. exit.on_completion=false keeps the
  -- last output on screen after a crash or Ctrl+C.
  window("services", term("services", {
    command = a.services_cmd,
    exit = { on_completion = false },
  }), { "services" })
end

if a.agent_input ~= "" then
  -- An interactive shell with the agent typed in, so quitting Pi drops you
  -- at a prompt in the worktree instead of closing the tab.
  window("agent", term("agent", { initial_input = a.agent_input }), { "agent" })
end

rex.session.focus_window{ window_id = out.windows.agent or out.windows.code }
return out
