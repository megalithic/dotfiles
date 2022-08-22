-- TODO: presently unused;

local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
  -- allow `wezterm start -- something` to affect what we spawn
  -- in our initial window
  local args = {}
  if cmd then args = cmd.args end

  -- Set a workspace for coding on a current project
  -- Top pane is for the editor, bottom pane is for the build tool
  local project_dir = wezterm.home_dir .. "/.dotfiles"
  local tab, build_pane, window = mux.spawn_window({
    workspace = "mega",
    cwd = project_dir,
    args = args,
  })
  local editor_pane = build_pane:split({
    direction = "Top",
    size = 0.6,
    cwd = project_dir,
  })
  -- may as well kick off a build in that pane
  build_pane:send_text("echo \"hi in coding\"\n")

  -- A workspace for interacting with a local machine that
  -- runs some docker containners for home automation
  -- local tab, pane, window = mux.spawn_window({
  --   workspace = "automation",
  --   args = { "ssh", "vault" },
  -- })

  -- We want to startup in the coding workspace
  mux.set_active_workspace("coding")
end)

return {}
