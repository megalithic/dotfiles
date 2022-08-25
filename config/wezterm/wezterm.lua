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
--- https://github.com/katsyoshi/dotfiles/blob/master/wezterm/wezterm.lua

local wt = require("wezterm")
local act = wt.action
local mux = wt.mux
local os = require("os")
local homedir = os.getenv("HOME")
local fmt = string.format
local is_tmux = os.getenv("TMUX") ~= ""

-- load our wezterm.on/1 events
require("events")
local mappings = require("keys")
local palette = require("palette")

local function log(msg) wt.log_info(msg) end

--- [ COLORS ] -----------------------------------------------------------------
-- foreground = "#d3c6aa"
-- background = "#2b3339"
-- cursor_bg = "#d3c6aa"
-- cursor_border = "#d3c6aa"
-- cursor_fg = "#2b3339"
-- selection_bg = "#d3c6aa"
-- selection_fg = "#2b3339"

-- ansi = ["#4b565c","#e67e80","#a7c080","#dbbc7f","#7fbbb3","#d699b6","#83c092","#d3c6aa"]
-- brights = ["#4b565c","#e67e80","#a7c080","#dbbc7f","#7fbbb3","#d699b6","#83c092","#d3c6aa"]
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

--- [ FONTS ] ------------------------------------------------------------------
local function font_with_fallback(font, params)
  local names = {
    font,
    -- { family = "Hack Nerd Font Mono", weight = "Regular", stretch = "Normal", style = "Normal", italic = false },
    -- { family = "Hack Nerd Font Mono", weight = "Regular", stretch = "Normal", style = "Italic", italic = true },
    -- { family = "Hack Nerd Font Mono", weight = "Bold", stretch = "Normal", style = "Normal", italic = false },
    -- { family = "Hack Nerd Font Mono", weight = "Bold", stretch = "Normal", style = "Italic", italic = true },
    { family = "JetBrainsMonoMedium Nerd Font Mono", weight = "Medium", italic = true },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = false, weight = "Bold" },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = true, weight = "Bold" },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = false, weight = "ExtraBold" },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = true, weight = "ExtraBold" },
    "Dank Mono",
    "Symbols Nerd Font Mono",
    "codicon",
  }
  return wt.font_with_fallback(names, params)
end

local fonts = {
  font = font_with_fallback({ family = "JetBrainsMonoMedium Nerd Font Mono" }, {}),
  -- font = font_with_fallback({ family = "Hack Nerd Font Mono" }, {}),
  -- font = wezterm.font_with_fallback({ "Dank Mono", "codicon", "JetBrainsMono Nerd Font Mono" }),

  allow_square_glyphs_to_overflow_width = "Always", -- alts: WhenFollowedBySpace, Always
  custom_block_glyphs = true,
  freetype_load_target = "Light",
  freetype_render_target = "HorizontalLcd",
  font_size = 15.0,
  line_height = 1.2,
  warn_about_missing_glyphs = false,
  bold_brightens_ansi_colors = true,
  text_background_opacity = 1.0,
  -- Enable various OpenType features
  -- See https://docs.microsoft.com/en-us/typography/opentype/spec/featurelist
  -- font_shaper = "Harfbuzz",
  -- harfbuzz_features = {
  --   "zero=1", -- Use a slashed zero '0' (instead of dotted)
  --   "kern=1", -- (default) kerning (todo check what is really is)
  --   "liga=1", -- (default) ligatures
  --   "clig=1", -- (default) contextual ligatures
  -- },
  cursor_blink_rate = 0,
  force_reverse_video_cursor = true,
}

--- [ TABS ] -------------------------------------------------------------------
local tabs = {
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = false,
  tab_max_width = 300,
  tab_bar_at_bottom = false,
  tab_bar_style = {},
}

--- [ WINDOWS ] ----------------------------------------------------------------
local windows = {
  window_decorations = "RESIZE",
  initial_cols = 100,
  initial_rows = 20,
  window_background_opacity = 1.0,
  window_padding = {
    left = "15px",
    right = "15px",
    top = "15px",
    bottom = "15px",
  },
  window_close_confirmation = "NeverPrompt",
  adjust_window_size_when_changing_font_size = false,
  window_background_image_hsb = {
    brightness = 1.0,
    hue = 1.0,
    saturation = 1.0,
  },
}

--- [ PANES ] ------------------------------------------------------------------
local panes = {
  inactive_pane_hsb = {
    hue = 1.0,
    saturation = 1.0,
    brightness = 1.0,
  },
}

--- [ DOMAINS ] ----------------------------------------------------------------
local domains = {
  unix_domains = {
    { name = "megabook" },
  },
  ssh_domains = {
    {
      name = "seth-dev",
      remote_address = "127.0.0.1",
    },
  },
}

--- [ MOUSe ] ------------------------------------------------------------------
local mouse = {}

--- [ MISC ] -------------------------------------------------------------------
local misc = {
  default_cwd = homedir .. "/.dotfiles",
  default_prog = { "/usr/local/bin/zsh", "-l" },
  default_workspace = "default",
  -- TODO: figure out why we need this?
  -- @ht: kitten
  mux_env_remove = {
    "SSH_AUTH_SOCK",
    "SSH_CLIENT",
    "SSH_CONNECTION",
    "GPG_TTY",
  },
  set_environment_variables = {
    LANG = "en_US.UTF-8",
    PATH = wt.executable_dir .. ";" .. os.getenv("PATH"),
  },
  scrollback_lines = 5000,
  enable_scroll_bar = false,
  audible_bell = "Disabled",
  check_for_updates = false,
  native_macos_fullscreen_mode = true,
  enable_kitty_graphics = true,
  debug_key_events = true,
  use_ime = true,
  status_update_interval = 10000,
  cell_width = 1,
  quick_select_patterns = {
    "[A-Za-z0-9-_.]{6,100}",
  },
  launch_menu = {
    {
      label = "dotfiles",
      args = { "zsh", "-l" },
      cwd = "~/.dotfiles",
    },
  },
  window_decorations = "RESIZE",
  hyperlink_rules = {
    -- Linkify things that look like URLs and the host has a TLD name.
    {
      regex = "\\b\\w+://[\\w.-]+\\.[a-z]{2,15}\\S*\\b",
      format = "$0",
    },

    -- linkify email addresses
    {
      regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
      format = "mailto:$0",
    },

    -- file:// URI
    {
      regex = [[\bfile://\S*\b]],
      format = "$0",
    },

    -- Linkify things that look like URLs with numeric addresses as hosts.
    -- E.g. http://127.0.0.1:8000 for a local development server,
    -- or http://192.168.1.1 for the web interface of many routers.
    {
      regex = [[\b\w+://(?:[\d]{1,3}\.){3}[\d]{1,3}\S*\b]],
      format = "$0",
    },

    -- Make username/project paths clickable. This implies paths like the following are for GitHub.
    -- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wez/wezterm | "wez/wezterm.git" )
    -- As long as a full URL hyperlink regex exists above this it should not match a full URL to
    -- GitHub or GitLab / BitBucket (i.e. https://gitlab.com/user/project.git is still a whole clickable URL)
    {
      regex = [["([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)"]],
      format = "https://www.github.com/$1/$3",
    },
  },
}

local function merge_all(...)
  local ret = {}
  for _, tbl in ipairs({ ... }) do
    for k, v in pairs(tbl) do
      ret[k] = v
    end
  end
  return ret
end

local config = merge_all(
  misc,
  windows,
  tabs,
  panes,
  domains,
  { colors = colors },
  fonts,
  mappings,
  mouse,
  {} -- so the last table can have an ending comma for git diffs :)
)

return config
