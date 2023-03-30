-- ---@see:k
-- --- https://github.com/azzamsa/dotfiles/blob/master/wezterm/.config/wezterm/wezterm.lua
-- --- https://github.com/kitten/nix-system/blob/master/config/home/wezterm/init.lua
-- --- https://github.com/kitten/nix-system/blob/master/config/scripts/wezmux.sh
-- --- https://github.com/aca/dotfiles/blob/master/.config/wezterm/wezterm.lua
-- --- https://github.com/aca/wezterm.nvim
-- --- https://github.com/wez/wezterm/issues/1978
-- --- https://github.com/V1RE/dotfiles/blob/main/dot_config/wezterm/wezterm.lua
-- --- https://github.com/Omochice/dotfiles/blob/main/config/wezterm/wezterm.lua
-- --- https://github.com/yutkat/dotfiles/blob/main/.config/wezterm/wezterm.lua
--
local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local os = require("os")
local homedir = os.getenv("HOME")
local fmt = string.format
local is_tmux = os.getenv("TMUX") ~= ""

local function log(msg) wezterm.log_info(msg) end

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s) return string.gsub(s, "(.*[/\\])(.*)", "%2") end

local function notifier(opts)
  if opts.window == nil then return end

  opts = opts or {}
  local title = opts.title or "wezterm"
  local message = opts.message or ""
  local timeout = opts.timeout or 4000
  local window = opts.window

  window:toast_notification(title, message, nil, timeout)
end

wezterm.on(
  "window-config-reloaded",
  function(window, pane)
    notifier({ title = "wezterm", message = "configuration reloaded!", window = window, timeout = 4000 })
  end
)

wezterm.on("toggle-ligature", function(window, pane)
  local overrides = window:get_config_overrides() or {}
  if not overrides.harfbuzz_features then
    -- If we haven't overridden it yet, then override with ligatures disabled
    --- |>
    overrides.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
  else
    -- else we did already, and we should disable out override now
    overrides.harfbuzz_features = nil
  end
  window:set_config_overrides(overrides)
end)

-- @note: megaforest
local palette = {
  background = "#2f3d44",
  bright_background = "#2f3d44",
  foreground = "#d3c6aa", -- #d8cacc
  bright_foreground = "#d3c6aa",
  cursor = "#83b6af",
  visual = "#4e6053",
  split = "#3e4c53",
  -- ansi
  black = "#4b565c",
  red = "#e67e80",
  green = "#a7c080",
  yellow = "#dbbc7f",
  blue = "#83b6af",
  orange = "#e39b7b",
  purple = "#d699b6",
  cyan = "#719d7c",
  white = "#cccccc",
  -- brights
  -- bright_black = "#273433",
  bright_black = "#4b565c",
  bright_red = "#e67e80",
  bright_green = "#a7c080",
  bright_yellow = "#d9bb80",
  bright_blue = "#7fbbb3",
  bright_orange = "#e39b7b",
  bright_purple = "#d39bb6",
  bright_cyan = "#719d7c",
  bright_white = "#cccccc",
}

--- [ COLORS ] -----------------------------------------------------------------
local colors = {}

colors.background = palette.background
colors.foreground = palette.foreground

colors.cursor_fg = palette.black
colors.cursor_bg = palette.cursor
colors.cursor_border = palette.foreground

colors.selection_fg = palette.black
colors.selection_bg = palette.visual

colors.split = palette.split

colors.compose_cursor = palette.orange

colors.ansi = {
  palette.black, -- black
  palette.red, -- red
  palette.green, -- green
  palette.yellow, -- yellow
  palette.blue, -- blue
  palette.purple, -- orange (magentas usually)
  palette.cyan, -- cyan
  palette.white, -- white
}

colors.brights = {
  palette.bright_black, -- black
  palette.bright_red, -- red
  palette.bright_green, -- green
  palette.bright_yellow, -- yellow
  palette.bright_blue, -- blue
  palette.bright_purple, -- orange (magentas usually)
  palette.bright_cyan, -- cyan
  palette.bright_white, -- white
}

colors.tab_bar = {
  background = palette.bright_background, --palette.background,
  active_tab = {
    fg_color = palette.blue,
    bg_color = palette.bright_background,
    intensity = "Bold",
    -- weight = "ExtraBold",
    italic = true,
  },
  inactive_tab_edge = palette.bright_background,
  inactive_tab = {
    fg_color = "#415c6d", --palette.bright_white,
    bg_color = palette.bright_background,
  },
  inactive_tab_hover = {
    fg_color = palette.blue,
    bg_color = palette.bright_background,
  },
  new_tab = {
    fg_color = palette.background,
    bg_color = palette.background,
  },
}

-- Colors for copy_mode and quick_select
-- available since: 20220807-113146-c2fee766
-- In copy_mode, the color of the active text is:
-- 1. copy_mode_active_highlight_* if additional text was selected using the mouse
-- 2. selection_* otherwise
-- colors.copy_mode_active_highlight_bg = { Color = "#000000" }
-- -- use `AnsiColor` to specify one of the ansi color palette values
-- -- (index 0-15) using one of the names "Black", "Maroon", "Green",
-- --  "Olive", "Navy", "Purple", "Teal", "Silver", "Grey", "Red", "Lime",
-- -- "Yellow", "Blue", "Fuchsia", "Aqua" or "White".
-- colors.copy_mode_active_highlight_fg = { AnsiColor = "Black" }
-- colors.copy_mode_inactive_highlight_bg = { Color = "#52ad70" }
-- colors.copy_mode_inactive_highlight_fg = { AnsiColor = "White" }
--
-- -- https://megalithic.io
-- colors.quick_select_label_bg = { "#52ad70" }
-- colors.quick_select_label_fg = { Color = "#ffffff" }
-- colors.quick_select_match_bg = { AnsiColor = "Navy" }
-- colors.quick_select_match_fg = { Color = "#ffffff" }

local font = {
  JetBrainsMono = {
    Normal = { family = "JetBrains Mono", weight = "Medium" },
    Italic = { family = "JetBrains Mono", italic = true },
    Bold = { family = "JetBrains Mono", weight = "ExtraBlack" },
    BoldItalic = { family = "JetBrains Mono", italic = true, weight = "ExtraBlack" },
  },
  JetBrainsMonoNerdFont = {
    Normal = { family = "JetBrainsMono Nerd Font Mono", weight = "Regular" },
    Italic = { family = "JetBrainsMono Nerd Font Mono", italic = true },
    Bold = { family = "JetBrainsMono Nerd Font Mono", weight = "ExtraBlack" },
    BoldItalic = { family = "JetBrainsMono Nerd Font Mono", italic = true, weight = "ExtraBlack" },
  },
}

return {
  window_close_confirmation = "NeverPrompt",
  disable_default_key_bindings = true,
  front_end = "WebGpu", -- OpenGL, WebGpu, Software
  window_decorations = "RESIZE",
  use_cap_height_to_scale_fallback_fonts = true,
  warn_about_missing_glyphs = false,
  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
  bold_brightens_ansi_colors = true,
  font_size = 14.5,
  line_height = 1.1,
  text_blink_rate = 100,
  cursor_blink_rate = 500,
  cursor_blink_ease_in = "Constant",
  cursor_blink_ease_out = "Constant",
  freetype_load_flags = "NO_HINTING",
  freetype_load_target = "Light",
  freetype_render_target = "HorizontalLcd",
  font = wezterm.font_with_fallback({
    font.JetBrainsMono.Normal,
    font.JetBrainsMonoNerdFont.Normal,
    { family = "Symbols Nerd Font Mono", scale = 0.8 },
  }),
  font_rules = {
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font_with_fallback({
        font.JetBrainsMono.BoldItalic,
        font.JetBrainsMonoNerdFont.BoldItalic,
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
    {
      italic = true,
      font = wezterm.font_with_fallback({
        font.JetBrainsMono.Italic,
        font.JetBrainsMonoNerdFont.Italic,
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
    {
      intensity = "Bold",
      font = wezterm.font_with_fallback({
        font.JetBrainsMono.Bold,
        font.JetBrainsMonoNerdFont.Bold,
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
  },
  hide_tab_bar_if_only_one_tab = true,
  colors = colors,
  -- leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = {
    -- mimic my kitty bindings for direct interaction with tmux..
    { key = "1", mods = "CTRL", action = act.SendString("\x00\x31") },
    { key = "2", mods = "CTRL", action = act.SendString("\x00\x32") },
    { key = "3", mods = "CTRL", action = act.SendString("\x00\x33") },
    { key = "4", mods = "CTRL", action = act.SendString("\x00\x34") },
    { key = "5", mods = "CTRL", action = act.SendString("\x00\x35") },
    { key = "6", mods = "CTRL", action = act.SendString("\x00\x36") },
    { key = "7", mods = "CTRL", action = act.SendString("\x00\x37") },
    { key = "8", mods = "CTRL", action = act.SendString("\x00\x38") },
    { key = "9", mods = "CTRL", action = act.SendString("\x00\x39") },
    -- {
    --   key = "e",
    --   mods = "CTRL",
    --   action = act.EmitEvent("toggle-ligature"),
    -- },
    { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
    { key = "d", mods = "CMD|CTRL", action = act.ShowDebugOverlay },
    {
      key = "o",
      mods = "CMD|CTRL",
      action = act({
        QuickSelectArgs = {
          label = "open url",
          patterns = {
            "https?://\\S+",
            "git://\\S+",
            "ssh://\\S+",
            "ftp://\\S+",
            "file://\\S+",
            "mailto://\\S+",
          },
          action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info("opening: " .. url)
            wezterm.open_with(url)
          end),
        },
      }),
    },
    {
      key = "u",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({
        label = "copy url",
        patterns = {
          "https?://\\S+",
          "git://\\S+",
          "ssh://\\S+",
          "ftp://\\S+",
          "file://\\S+",
          "mailto://\\S+",
        },
      }),
    },
    {
      key = "c",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({
        label = "copy command line",
        patterns = {
          "❯ [^│↲]+[^[:space:]│↲]",
          "sudo [^│↲]+[^[:space:]│↲]",
          "b?[as]sh [^│↲]+[^[:space:]│↲]",
          "if [^│↲]+[^[:space:]│↲]",
          "for [^│↲]+[^[:space:]│↲]",
          "docker-compose [^│↲]+[^[:space:]│↲]",
          "docker [^│↲]+[^[:space:]│↲]",
          "git [^│↲]+[^[:space:]│↲]",
          "ls [^│↲]+[^[:space:]│↲]",
          "cd [^│↲]+[^[:space:]│↲]",
          "mkdir [^│↲]+[^[:space:]│↲]",
          "cat [^│↲]+[^[:space:]│↲]",
          "n?vim? [^│↲]+[^[:space:]│↲]",
          "c?make [^│↲]+[^[:space:]│↲]",
          "cargo [^│↲]+[^[:space:]│↲]",
          "rust[cu]?p? [^│↲]+[^[:space:]│↲]",
          "python[23]? [^│↲]+[^[:space:]│↲]",
          "pip[23]? [^│↲]+[^[:space:]│↲]",
          "pytest [^│↲]+[^[:space:]│↲]",
          "apt [^│↲]+[^[:space:]│↲]",
          "php [^│↲]+[^[:space:]│↲]",
          "node [^│↲]+[^[:space:]│↲]",
          "np[mx] [^│↲]+[^[:space:]│↲]",
          "p?grep [^│↲]+[^[:space:]│↲]",
          "p?kill [^│↲]+[^[:space:]│↲]",
          "fd [^│↲]+[^[:space:]│↲]",
          "rg [^│↲]+[^[:space:]│↲]",
          "echo [^│↲]+[^[:space:]│↲]",
          "g?awk [^│↲]+[^[:space:]│↲]",
          "curl [^│↲]+[^[:space:]│↲]",
          "sed [^│↲]+[^[:space:]│↲]",
          "basename [^│↲]+[^[:space:]│↲]",
          "dirname [^│↲]+[^[:space:]│↲]",
          "head [^│↲]+[^[:space:]│↲]",
          "tail [^│↲]+[^[:space:]│↲]",
        },
      }),
    },
    {
      key = "i",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({
        label = "copy ip",
        patterns = {
          "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+",
          "[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}\z
    :[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}",
        },
      }),
    },

    { key = "p", mods = "CMD|CTRL", action = act.QuickSelect }, -- select path
    { key = "l", mods = "CMD|CTRL", action = act.QuickSelectArgs({ patterns = { "^.+$" } }) }, -- select line
    {
      key = "s",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({ label = "copy sha1", patterns = { "[0-9a-f]{7,40}" } }),
    }, -- select sha1
    -- { key = "s", mods = "CMD|CTRL", action = act.Search({ Regex = "" }) }, -- search mode
    -- { key = "G", mods = "CMD|CTRL", action = act.ActivateCopyMode }, -- copy mode
  },
}
