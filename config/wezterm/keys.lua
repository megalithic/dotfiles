---@see:
--- https://github.com/azzamsa/dotfiles/blob/master/wezterm/.config/wezterm/wezterm.lua
--- https://github.com/kitten/nix-system/blob/master/config/home/wezterm/init.lua
--- https://github.com/kitten/nix-system/blob/master/config/scripts/wezmux.sh
--- https://github.com/aca/dotfiles/blob/master/.config/wezterm/wezterm.lua
--- https://github.com/aca/wezterm.nvim
--- https://github.com/wez/wezterm/issues/1978
--- https://github.com/V1RE/dotfiles/blob/main/dot_config/wezterm/wezterm.lua
--- https://github.com/Omochice/dotfiles/blob/main/config/wezterm/wezterm.lua
--- https://github.com/yutkat/dotfiles/blob/main/.config/wezterm/wezterm.lua

local wt = require("wezterm")
local act = wt.action
local mux = wt.mux
local os = require("os")
local homedir = os.getenv("HOME")
local fmt = string.format
local is_tmux = os.getenv("TMUX") ~= ""

local move_around = function(window, pane, direction_wez, direction_nvim)
  local result =
    os.execute("env NVIM_LISTEN_ADDRESS=/tmp/nvim" .. pane:pane_id() .. " wezterm.nvim.navigator " .. direction_nvim)
  if result then
    window:perform_action(act({ SendString = "\x17" .. direction_nvim }), pane)
  else
    window:perform_action(act({ ActivatePaneDirection = direction_wez }), pane)
  end
end

wt.on("move-left", function(window, pane) move_around(window, pane, "Left", "h") end)
wt.on("move-right", function(window, pane) move_around(window, pane, "Right", "l") end)
wt.on("move-up", function(window, pane) move_around(window, pane, "Up", "k") end)
wt.on("move-down", function(window, pane) move_around(window, pane, "Down", "j") end)

--- [ MAPPINGS ] ---------------------------------------------------------------
-- local tmux_map = function() end

local mappings = {
  -- tmux-style leader prefix <C-space>
  leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = {
    -- { key = "x", mods = "ALT", action = "ShowLauncher" },
    -- { key = "w", mods = "CTRL", action = "QuickSelect" },

    -- Font Size
    { key = "0", mods = "SUPER", action = "ResetFontSize" },
    { key = "+", mods = "SUPER", action = "IncreaseFontSize" },
    { key = "-", mods = "SUPER", action = "DecreaseFontSize" },

    -- Copy Mode/Select
    { key = " ", mods = "LEADER", action = "ActivateCopyMode" },
    { key = "f", mods = "LEADER|CTRL", action = "QuickSelect" },

    -- tabs
    { key = "t", mods = "SUPER", action = act({ SpawnTab = "CurrentPaneDomain" }) },
    { key = "w", mods = "LEADER|CTRL", action = act({ CloseCurrentTab = { confirm = true } }) },
    { key = "x", mods = "LEADER|CTRL", action = act({ CloseCurrentPane = { confirm = true } }) },
    { key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },

    -- panes
    {
      key = "v",
      mods = "LEADER",
      action = act({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
    },
    { key = "h", mods = "LEADER", action = act({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
    {
      key = "z",
      mods = "LEADER|CTRL",
      action = act.TogglePaneZoomState,
    },
    {
      key = "h",
      mods = "CTRL",
      action = act.ActivatePaneDirection("Left"),
    },
    {
      key = "l",
      mods = "CTRL",
      action = act.ActivatePaneDirection("Right"),
    },
    {
      key = "k",
      mods = "CTRL",
      action = act.ActivatePaneDirection("Up"),
    },
    {
      key = "j",
      mods = "CTRL",
      action = act.ActivatePaneDirection("Down"),
    },

    -- pane move(vim aware)
    { key = "h", mods = "CTRL", action = act({ EmitEvent = "move-left" }) },
    { key = "l", mods = "CTRL", action = act({ EmitEvent = "move-right" }) },
    { key = "k", mods = "CTRL", action = act({ EmitEvent = "move-up" }) },
    { key = "j", mods = "CTRL", action = act({ EmitEvent = "move-down" }) },

    -- launchers
    {
      key = " ",
      mods = "LEADER|CTRL",
      action = act({
        ShowLauncherArgs = {
          flags = "FUZZY|WORKSPACES",
        },
      }),
    },
    { key = "n", mods = "LEADER|CTRL", action = act.SwitchWorkspaceRelative(1) },
    { key = "p", mods = "LEADER|CTRL", action = act.SwitchWorkspaceRelative(-1) },
    { key = "b", mods = "LEADER|CTRL", action = act({ EmitEvent = "trigger-nvim-with-scrollback" }) },
    { key = "d", mods = "LEADER|CTRL", action = act.ShowDebugOverlay },

    { key = "Enter", mods = "LEADER|CTRL", action = "QuickSelect" },
    { key = "/", mods = "LEADER|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
    {
      key = "O",
      mods = "CMD",
      action = act({
        QuickSelectArgs = {
          patterns = {
            "https?://\\S+",
          },
          action = wt.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wt.log_info("opening: " .. url)
            wt.open_with(url)
          end),
        },
      }),
    },
  },
}

-- map tab activation keys
for i = 0, 9 do
  if i + 1 >= 10 then break end
  local key_string = tostring(i + 1)
  table.insert(mappings.keys, {
    key = key_string,
    mods = "CTRL",
    action = act({ ActivateTab = i }),
  })
end

return mappings
