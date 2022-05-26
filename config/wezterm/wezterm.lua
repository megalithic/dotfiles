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
local is_tmux = os.getenv("TMUX") ~= ""

-- @note: megaforest
local palette = {
  background = "rgba(50,61,67,1.000)", -- "#323d43", -- #323d43 #273433
  bright_background = "#323d43", -- #3a464d
  foreground = "#d3c6aa", -- #d8cacc
  bright_foreground = "#d8cacc",
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
  bright_black = "#273433",
  bright_red = "#e67e80",
  bright_green = "#a7c080",
  bright_yellow = "#d9bb80",
  bright_blue = "#7fbbb3",
  bright_orange = "#e39b7b",
  bright_purple = "#d39bb6",
  bright_cyan = "#719d7c",
  bright_white = "#cccccc",
}

local function log(msg)
  wezterm.log_info(msg)
end

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local function notifier(opts)
  if opts.window == nil then
    return
  end

  opts = opts or {}
  local title = opts.title or "wezterm"
  local message = opts.message or ""
  local timeout = opts.timeout or 4000
  local window = opts.window

  window:toast_notification(title, message, nil, timeout)
end

local function window_config_reloaded(window, pane)
  notifier({ title = "wezterm", message = "configuration reloaded!", window = window, timeout = 4000 })
end

local function format_tab_title(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local dir = basename(pane.current_working_dir)
  local title = dir
  local icon = ""

  if dir == nil or dir == "" then
    title = basename(pane.foreground_process_name)
  end

  if dir == basename(wezterm.home_dir) then
    title = "~"
  end
  local SUP_IDX = {
    "¹",
    "²",
    "³",
    "⁴",
    "⁵",
    "⁶",
    "⁷",
    "⁸",
    "⁹",
    "¹⁰",
    "¹¹",
    "¹²",
    "¹³",
    "¹⁴",
    "¹⁵",
    "¹⁶",
    "¹⁷",
    "¹⁸",
    "¹⁹",
    "²⁰",
  }

  local NUM_IDX_ACTIVE = {
    "0xf8a3",
    "0xf8a6",
    "0xf8a9",
    "0xf8ac",
    "0xf8af",
    "0xf8b2",
    "0xf8b5",
    "0xf8b8",
    "0xf8bb",
  }
  local NUM_IDX_INACTIVE = {
    "0xf8a5",
    "0xf8a8",
    "0xf8ab",
    "0xf8ae",
    "0xf8b1",
    "0xf8b4",
    "0xf8b7",
    "0xf8ba",
    "0xf8bd",
  }
  local tab_prefix = tab.tab_index == 0 and "  " or " "
  local tab_index = tab.tab_index + 1

  if tab.is_active then
    icon = tab.active_pane.is_zoomed and " " or "綠"
    tab_index = utf8.char(NUM_IDX_ACTIVE[tab.tab_index + 1])

    -- utf8.char(0xf490)
    return {
      { Text = tab_prefix },
      -- { Text = fmt("%s%s:%s ", icon, tab_index, title) },
      { Text = fmt("%s %s ", tab_index, title) },
      { Text = "" },
    }
  else
    icon = tab.active_pane.is_zoomed and " " or "○"
    tab_index = utf8.char(NUM_IDX_INACTIVE[tab.tab_index + 1])
    return {
      { Text = tab_prefix },
      { Text = fmt("%s %s ", tab_index, title) },
      -- { Text = fmt("%s %s:%s ", icon, tab_index, title) },
      { Text = "" },
    }
  end
end

local function update_right_status(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  local config = window:effective_config()
  local session_color = palette.yellow
  local session_name = ""

  -- insert session name
  local session_icon = utf8.char(0xf490)
  for i, v in ipairs(config.unix_domains) do
    if v.name ~= nil and v.name ~= "" then
      session_name = v.name
      break
    else
      session_name = window:active_workspace()
    end
  end
  table.insert(
    cells,
    wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { Color = session_color } },
      { Text = " " .. session_icon .. " " .. session_name },
    })
  )

  -- insert battery percentage
  for _, b in ipairs(wezterm.battery_info()) do
    table.insert(cells, fmt("%.0f%%", b.state_of_charge * 100))
  end

  -- insert local datetime and utc
  local datetime = fmt("%s (UTC %s)", wezterm.strftime("%H:%M"), wezterm.strftime_utc("%H:%M"))
  table.insert(cells, datetime)

  -- The elements to be formatted
  local formatted_cells = {}
  -- How many cells have been formatted
  local formatted_cells_count = 0
  -- Translate a cell into elements
  function push(text, is_last)
    table.insert(formatted_cells, { Text = "" .. text .. "" })
    if not is_last then
      table.insert(formatted_cells, { Text = " ⋮ " })
    end
    formatted_cells_count = formatted_cells_count + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  -- push a spacer cell
  push(" ", #cells == 0)
  window:set_right_status(wezterm.format(formatted_cells))
end

local function trigger_nvim_with_scrollback(window, pane)
  local scrollback = pane:get_lines_as_text()
  local name = os.tmpname()
  local f = io.open(name, "w+")

  if f ~= nil then
    f:write(scrollback)
    f:flush()
    f:close()
    local command = "nvim " .. name
    window:perform_action(
      wezterm.action({ SpawnCommandInNewTab = {
        args = { "/usr/local/bin/zsh", "-l", "-c", command },
      } }),
      pane
    )
    wezterm.sleep_ms(1000)
    os.remove(name)
  end
end

local function trigger_fzf_example(window, pane)
  local command = "cd (ghq root)/(ghq list | fzf +m --reverse --prompt='Project > ') && vim"
  window:perform_action(
    wezterm.action({
      -- SwitchToWorkspace = {
      --   spawn = {
      --     args = { "/usr/local/bin/fish", "-l", "-c", command },
      --   },
      -- },
      SpawnCommandInNewTab = {
        args = { "/usr/local/bin/fish", "-l", "-c", command },
      },
    }),
    pane
  )
end

wezterm.on("window-config-reloaded", window_config_reloaded)
wezterm.on("format-tab-title", format_tab_title)
wezterm.on("update-right-status", update_right_status)
wezterm.on("trigger-nvim-with-scrollback", trigger_nvim_with_scrollback)

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
    weight = "ExtraBold",
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
    { family = "JetBrainsMono Nerd Font Mono", weight = "Medium", italic = true },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = false },
    { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = true },
    "Symbols Nerd Font Mono",
    "codicon",
  }
  return wezterm.font_with_fallback(names, params)
end

local fonts = {
  font = font_with_fallback({ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" }, {}),
  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace", -- "Always"
  custom_block_glyphs = false,
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

--- [ MAPPINGS ] ---------------------------------------------------------------
local mappings = {
  -- tmux-style leader prefix <C-space>
  leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = {
    { key = "x", mods = "ALT", action = "ShowLauncher" },
    { key = "w", mods = "CTRL", action = "QuickSelect" },

    -- Font Size
    { key = "0", mods = "SUPER", action = "ResetFontSize" },
    { key = "+", mods = "SUPER", action = "IncreaseFontSize" },
    { key = "-", mods = "SUPER", action = "DecreaseFontSize" },

    -- Copy Mode/Select
    { key = " ", mods = "LEADER", action = "ActivateCopyMode" },
    { key = "f", mods = "LEADER|CTRL", action = "QuickSelect" },

    -- tabs
    { key = "t", mods = "CTRL", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
    { key = "w", mods = "CTRL", action = wezterm.action({ CloseCurrentTab = { confirm = false } }) },

    -- panes
    {
      key = "v",
      mods = "LEADER",
      action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
    },
    { key = "h", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },

    -- launchers
    {
      key = " ",
      mods = "LEADER|CTRL",
      action = wezterm.action({
        ShowLauncherArgs = {
          flags = "FUZZY|WORKSPACES",
        },
      }),
    },
    { key = "b", mods = "LEADER", action = wezterm.action({ EmitEvent = "trigger-nvim-with-scrollback" }) },
  },
}

--- [ TABS ] -------------------------------------------------------------------
local tabs = {
  use_fancy_tab_bar = false,
  hide_tab_bar_if_only_one_tab = true,
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
    right = "10px",
    top = "10px",
    bottom = "10px",
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
  -- unix_domains = nil,
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
    PATH = wezterm.executable_dir .. ";" .. os.getenv("PATH"),
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
