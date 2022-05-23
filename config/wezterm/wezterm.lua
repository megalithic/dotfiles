---@see:
--- https://github.com/azzamsa/dotfiles/blob/master/wezterm/.config/wezterm/wezterm.lua
--- https://github.com/kitten/nix-system/blob/master/config/home/wezterm/init.lua
--- https://github.com/kitten/nix-system/blob/master/config/scripts/wezmux.sh
--- https://github.com/aca/dotfiles/blob/master/.config/wezterm/wezterm.lua
--- https://github.com/aca/wezterm.nvim
--- https://github.com/wez/wezterm/issues/1978
--- https://github.com/V1RE/dotfiles/blob/main/dot_config/wezterm/wezterm.lua
--- https://github.com/Omochice/dotfiles/blob/main/config/wezterm/wezterm.lua

local wezterm = require("wezterm")
local os = require("os")
local homedir = os.getenv("HOME")
local fmt = string.format

-- wezterm.on("window-config-reloaded", function(window, pane)
--   window:toast_notification("wezterm", "configuration reloaded!", nil, 4000)
-- end)

local function log(msg)
  wezterm.log_info(msg)
end

-- local inTmux = true
-- if os.getenv("TMUX") ~= "" then
--   inTmux = false
-- end

-- wezterm.on("update-right-status", function(window, pane)
--   local status = ""
--   if window:dead_key_is_active() then
-- if window:dead_key_is_active() then
--     status = "COMPOSE"
--   end
--   window:set_right_status(status)
-- end);

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local dir = basename(pane.current_working_dir)
  local title = dir

  if dir == nil or dir == "" then
    title = basename(pane.foreground_process_name)
  end

  if dir == basename(wezterm.home_dir) then
    title = "~"
  end

  return {
    { Text = fmt("○ %d:%s", tab.tab_index + 1, title) },
    -- { Text = " [" .. title .. "] " },
  }
end)

wezterm.on("update-right-status", function(window, pane)
  local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")

  local bat = ""
  for _, b in ipairs(wezterm.battery_info()) do
    bat = string.format("%.0f%% %0.2f hours", b.state_of_charge * 100, b.time_to_empty / 60 / 60)
      .. " "
      .. string.lower(b.state)
  end

  if bat == "" then
    bat = " | "
  else
    bat = " | " .. bat .. " | "
  end

  window:set_right_status(wezterm.format({
    { Text = wezterm.hostname() .. bat .. date },
  }))
end)

-- A helper function for my fallback fonts
local function font_with_fallback(name, params)
  local names = {
    name,
    "JetBrainsMono Nerd Font",
    "JetBrains Mono",
    "codicon",
  }
  return wezterm.font_with_fallback(names, params)
end

local config = {
  -- tab bar
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  tab_max_width = 100,
  tab_bar_at_bottom = false,

  -- window
  window_decorations = "NONE", -- "RESIZE|MOVE"
  -- window_padding = {
  --   left = 15,
  --   right = 15,
  --   top = 15,
  --   bottom = 15,
  -- },
  initial_cols = 100,
  initial_rows = 20,
  -- window_background_opacity = 1,

  tab_bar_style = {
    active_tab_left = "",
    active_tab_right = "",
    inactive_tab_left = "",
    inactive_tab_right = "",
    inactive_tab_hover_left = "",
    inactive_tab_hover_right = "",
  },

  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 1.0,
  },

  window_frame = {
    font = font_with_fallback({ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" }),
    font_size = 14.0,
    active_titlebar_bg = "#000000",
    inactive_titlebar_bg = "#000000",
  },

  window_padding = {
    left = "15px",
    right = "15px",
    top = "0px",
    bottom = "0px",
  },

  -- performance issue, use tmux instead....
  scrollback_lines = 5000,
  font = font_with_fallback({ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" }),
  allow_square_glyphs_to_overflow_width = "Always",
  font_antialias = "Subpixel",
  custom_block_glyphs = false,
  freetype_load_target = "Light",
  freetype_render_target = "HorizontalLcd",
  font_size = 15.0,
  line_height = 1.2,
  enable_scroll_bar = false,
  check_for_updates = false,
  window_close_confirmation = "NeverPrompt",
  native_macos_fullscreen_mode = true,
  warn_about_missing_glyphs = false,
  bold_brightens_ansi_colors = true,
  adjust_window_size_when_changing_font_size = false,
  default_prog = { "/usr/local/bin/zsh" },
  enable_kitty_graphics = true,
  debug_key_events = true,
  set_environment_variables = {
    -- This fails to find wezterm.nvim.navigator
    PATH = os.getenv("PATH") .. ":/usr/local/bin" .. ":" .. homedir .. "/.bin" .. ":" .. homedir .. "/bin",
    -- prompt = "$E]7;file://localhost/$P$E\\$E]1;$P$E\\$E[32m$T$E[0m $E[35m$P$E[36m$_$G$E[0m ",
  },

  colors = {
    ansi = { "#2f2e2d", "#a36666", "#90a57d", "#d7af87", "#7fa5bd", "#c79ec4", "#8adbb4", "#d0d0d0" },
    -- background = "#1c1c1c",
    background = "#000000",
    brights = { "#4a4845", "#d78787", "#afbea2", "#e4c9af", "#a1bdce", "#d7beda", "#b1e7dd", "#efefef" },
    cursor_bg = "#e4c9af",
    cursor_border = "#e4c9af",
    cursor_fg = "#000000",
    foreground = "#d0d0d0",
    selection_bg = "#4d4d4d",
    selection_fg = "#ffffff",
  },

  -- colors = {
  --   foreground = "#ffffff",
  --   background = "#000000",
  --   cursor_bg = "#7f7f7f",
  --   cursor_border = "#7f7f7f",
  --   cursor_fg = "#7f7f7f",
  --   selection_bg = "#cb392e",
  --   selection_fg = "#ffffff",
  --   ansi = {"#2e2e2e","#fc6d26","#3eb383","#fca121","#db3b21","#380d75","#6e49cb","#ffffff"},
  --   brights = {"#464646","#ff6517","#53eaa8","#fca013","#db501f","#441090","#7d53e7","#ffffff"},
  -- },
  use_ime = true,
  status_update_interval = 10000,

  -- TODO
  quick_select_patterns = {
    "[A-Za-z0-9-_.]{6,100}",
  },

  -- mimicks tmux prefix of <C-space>
  leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = {
    { key = "x", mods = "ALT", action = "ShowLauncher" },
    { key = "w", mods = "CTRL", action = "QuickSelect" },
    { key = "w", mods = "LEADER|CTRL", action = "QuickSelect" },
    { key = " ", mods = "LEADER|CTRL", action = "ShowLauncher" },
  },

  color_scheme = "nord",
  launch_menu = {
    {
      label = "dotfiles",
      args = { "zsh", "-l" },
      cwd = "~/.dotfiles",
    },
  },
}

return config
