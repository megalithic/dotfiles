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

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
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

local function window_config_reloaded(window, pane)
  notifier({ title = "wezterm", message = "configuration reloaded!", window = window, timeout = 4000 })
end

local function format_tab_title(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local dir = basename(pane.current_working_dir)
  local title = dir
  local icon = ""

  if dir == nil or dir == "" then title = basename(pane.foreground_process_name) end

  if dir == basename(wezterm.home_dir) then title = "~" end
  -- local SUP_IDX = {
  --   "¹",
  --   "²",
  --   "³",
  --   "⁴",
  --   "⁵",
  --   "⁶",
  --   "⁷",
  --   "⁸",
  --   "⁹",
  --   "¹⁰",
  --   "¹¹",
  --   "¹²",
  --   "¹³",
  --   "¹⁴",
  --   "¹⁵",
  --   "¹⁶",
  --   "¹⁷",
  --   "¹⁸",
  --   "¹⁹",
  --   "²⁰",
  -- }

  -- local NUM_IDX_ACTIVE = {
  --   "0xf8a3",
  --   "0xf8a6",
  --   "0xf8a9",
  --   "0xf8ac",
  --   "0xf8af",
  --   "0xf8b2",
  --   "0xf8b5",
  --   "0xf8b8",
  --   "0xf8bb",
  -- }
  -- local NUM_IDX_INACTIVE = {
  --   "0xf8a5",
  --   "0xf8a8",
  --   "0xf8ab",
  --   "0xf8ae",
  --   "0xf8b1",
  --   "0xf8b4",
  --   "0xf8b7",
  --   "0xf8ba",
  --   "0xf8bd",
  -- }
  local tab_prefix = tab.tab_index == 0 and "  " or " "
  local tab_index = tab.tab_index + 1

  if tab.is_active then
    icon = tab.active_pane.is_zoomed and "" or ""
    -- tab_index = utf8.char(NUM_IDX_ACTIVE[tab.tab_index + 1])

    -- utf8.char(0xf490)
    return {
      { Text = tab_prefix },
      -- { Text = fmt("%s%s:%s ", icon, tab_index, title) },
      -- { Text = fmt("%s:%s ", tab.tab_index + 1, title) },
      { Text = fmt("%s %s:%s ", icon, tab_index, title) },
      { Text = "" },
    }
  end

  -- local has_unseen_output = false
  -- for _, pane in ipairs(tab.panes) do
  --   if pane.has_unseen_output then
  --     has_unseen_output = true
  --     break
  --   end
  -- end
  -- if has_unseen_output then
  --   return {
  --     { Background = { Color = "Orange" } },
  --     { Text = " " .. tab.active_pane.title .. " " },
  --   }
  -- end

  icon = tab.active_pane.is_zoomed and "" or ""
  return {
    { Text = tab_prefix },
    -- { Text = fmt("%s %s ", tab_index, title) },
    { Text = fmt("%s %s:%s ", icon, tab_index, title) },
    { Text = "" },
  }
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
  session_name = window:active_workspace()
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
    if not is_last then table.insert(formatted_cells, { Text = " ⋮ " }) end
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

-- This produces a window split horizontally into three equal parts
wezterm.on("gui-startup", function()
  wezterm.log_info("doing gui startup")
  local tab, pane, window = mux.spawn_window({})
  mux.split_pane(pane, { size = 0.3 })
  mux.split_pane(pane, { size = 0.5 })
end)

-- this is called by the mux server when it starts up.
-- It makes a window split top/bottom
wezterm.on("mux-startup", function()
  wezterm.log_info("doing mux startup")
  local tab, pane, window = mux.spawn_window({})
  mux.split_pane(pane, { direction = "Top" })
end)

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

--- [ FONTS ] ------------------------------------------------------------------
-- local function font_with_fallback(font, params)
--   local names = {
--     font,
--     { family = "JetBrainsMono Nerd Font Mono", weight = "Medium", italic = true },
--     { family = "JetBrainsMono Nerd Font Mono", italic = true },
--     { family = "JetBrainsMono Nerd Font Mono", weight = "ExtraBold" },
--     { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = false, weight = "ExtraBold" },
--     { family = "JetBrainsMonoExtraBold Nerd Font Mono", italic = true, weight = "ExtraBold" },
--     "Dank Mono",
--     "Symbols Nerd Font Mono",
--     "codicon",
--   }
--   return wezterm.font_with_fallback(names, params)
-- end

local fonts = {
  -- font = font_with_fallback({ family = "JetBrainsMono Nerd Font Mono", weight = "Bold" }, {}),

  font = wezterm.font("JetBrainsMono Nerd Font Mono", { weight = "Medium", stretch = "Normal", style = "Normal" }),
  font_rules = {
    {
      italic = true,
      font = wezterm.font("JetBrainsMono Nerd Font Mono", { weight = "Medium", stretch = "Normal", style = "Italic" }),
    },
    {
      intensity = "Bold",
      font = wezterm.font(
        "JetBrainsMono Nerd Font Mono",
        { weight = "ExtraBold", stretch = "Normal", style = "Normal" }
      ),
    },
    {
      intensity = "Bold",
      italic = true,
      font = wezterm.font(
        "JetBrainsMono Nerd Font Mono",
        { weight = "ExtraBold", stretch = "Normal", style = "Italic" }
      ),
    },
    {
      intensity = "Half",
      font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Thin" }),
    },
  },
  harfbuzz_features = { "calt=0", "clig=0", "liga=0" },
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

--- [ MAPPINGS ] ---------------------------------------------------------------
-- local tmux_map = function() end

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
    { key = "t", mods = "SUPER", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
    { key = "w", mods = "CTRL", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
    { key = "x", mods = "LEADER|CTRL", action = act({ CloseCurrentPane = { confirm = true } }) },

    { key = "1", mods = "LEADER|CTRL", action = act({ ActivateTab = 0 }) },
    { key = "2", mods = "LEADER|CTRL", action = act({ ActivateTab = 1 }) },
    { key = "3", mods = "LEADER|CTRL", action = act({ ActivateTab = 2 }) },
    { key = "4", mods = "LEADER|CTRL", action = act({ ActivateTab = 3 }) },
    { key = "5", mods = "LEADER|CTRL", action = act({ ActivateTab = 4 }) },
    { key = "6", mods = "LEADER|CTRL", action = act({ ActivateTab = 5 }) },
    { key = "7", mods = "LEADER|CTRL", action = act({ ActivateTab = 6 }) },
    { key = "8", mods = "LEADER|CTRL", action = act({ ActivateTab = 7 }) },
    { key = "9", mods = "LEADER|CTRL", action = act({ ActivateTab = 8 }) },

    { key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },

    -- panes
    {
      key = "v",
      mods = "LEADER",
      action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
    },
    { key = "h", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
    {
      key = "z",
      mods = "LEADER|CTRL",
      action = wezterm.action.TogglePaneZoomState,
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
    { key = "n", mods = "LEADER|CTRL", action = wezterm.action.SwitchWorkspaceRelative(1) },
    { key = "p", mods = "LEADER|CTRL", action = wezterm.action.SwitchWorkspaceRelative(-1) },
    { key = "b", mods = "LEADER|CTRL", action = wezterm.action({ EmitEvent = "trigger-nvim-with-scrollback" }) },
    { key = "d", mods = "LEADER|CTRL", action = wezterm.action.ShowDebugOverlay },

    { key = "Enter", mods = "LEADER|CTRL", action = "QuickSelect" },
    { key = "/", mods = "LEADER|CTRL", action = act.Search("CurrentSelectionOrEmptyString") },
    {
      key = "O",
      mods = "CMD",
      action = wezterm.action({
        QuickSelectArgs = {
          patterns = {
            "https?://\\S+",
          },
          action = wezterm.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            wezterm.log_info("opening: " .. url)
            wezterm.open_with(url)
          end),
        },
      }),
    },
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
  -- window_frame = {
  --   font = wezterm.font({ family = "JetBrainsMono NF" }),
  --   font_size = 9,
  -- },
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

-- local ssh_domains = {}
-- for host, _config in pairs(wezterm.enumerate_ssh_hosts()) do
--   table.insert(ssh_domains, {
--     name = host,
--     remote_address = host,
--   })
-- end

local misc = {
  front_end = "WebGpu",
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

  -- ssh_domains = ssh_domains,
  -- font = wezterm.font_with_fallback({
  --   family = "JetBrainsMono Nerd Font Mono",
  --   weight = "Medium",
  -- }),
  -- font_size = 14,
  max_fps = 120,
  -- line_height = 1.1,
  disable_default_key_bindings = true,
  show_new_tab_button_in_tab_bar = false,
  inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.75, --is_dark() and 0.75 or 0.85,
  },
  exit_behavior = "Close",
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
  windows,
  tabs,
  panes,
  -- domains,
  { colors = colors },
  fonts,
  -- mappings,
  mouse,
  misc,
  {} -- so the last table can have an ending comma for git diffs :)
)

return config

-- local wezterm = require("wezterm")
--
-- local prog = "/usr/local/bin/zsh"
-- --
-- -- if wezterm.hostname() == "Eriks-MBP" or wezterm.hostname() == "DESKTOP-BL0DJVK.localdomain" then
-- -- 	prog = "/opt/homebrew/bin/fish"
-- -- end
-- -- if wezterm.hostname() == "DESKTOP-7DQK874" then
-- -- 	prog = "wsl.exe"
-- -- end
--
-- return {
--   default_prog = { prog },
--   -- font = wezterm.font("Fira Code"),
--   font = wezterm.font("JetBrainsMono Nerd Font Mono"),
--   window_padding = {
--     bottom = 0,
--     left = "0.2cell",
--     right = "0.2cell",
--     top = "0.4cell",
--   },
--   send_composed_key_when_left_alt_is_pressed = true,
--   color_scheme = "tokyonight",
--   keys = {
--     {
--       key = "r",
--       mods = "CMD|SHIFT",
--       action = wezterm.action.ReloadConfiguration,
--     },
--   },
-- }
--
-- local ssh_domains = {}
-- for host, _config in pairs(wezterm.enumerate_ssh_hosts()) do
--   table.insert(ssh_domains, {
--     name = host,
--     remote_address = host,
--   })
-- end
--
-- return {
--   ssh_domains = ssh_domains,
--   font = wezterm.font_with_fallback({
--     family = "JetBrainsMono Nerd Font Mono",
--     weight = "Medium",
--   }),
--   font_size = 14,
--   max_fps = 120,
--   line_height = 1.1,
--   disable_default_key_bindings = true,
--   show_new_tab_button_in_tab_bar = false,
--   inactive_pane_hsb = {
--     saturation = 0.8,
--     brightness = 0.75, --is_dark() and 0.75 or 0.85,
--   },
--   exit_behavior = "Close",
--   pane_focus_follows_mouse = false,
--   warn_about_missing_glyphs = false,
--   show_update_window = false,
--   check_for_updates = false,
--   exit_behavior = "Close",
--   window_decorations = "TITLE",
--   window_close_confirmation = "NeverPrompt",
--   audible_bell = "Disabled",
--   window_padding = {
--     left = 0,
--     right = 0,
--     top = 0,
--     bottom = 0,
--   },
--   initial_cols = 148,
--   initial_rows = 40,
--   inactive_pane_hsb = {
--     saturation = 0.8,
--     brightness = 0.75, --is_dark() and 0.75 or 0.85,
--   },
--   enable_scroll_bar = false,
--   tab_bar_at_bottom = true,
--   use_fancy_tab_bar = false,
--   show_new_tab_button_in_tab_bar = false,
--   window_background_opacity = 0.9,
--   tab_max_width = 50,
--   hide_tab_bar_if_only_one_tab = true,
--   disable_default_key_bindings = true,
--   colors = colors,
--   -- color_scheme = is_dark() and "Dracula" or "Dracula",
--   -- colors = {
--   --   cursor_fg = is_dark() and colors.base or colors.crust,
--   --   tab_bar = {
--   --     background = "#282a36",
--   --     active_tab = {
--   --       bg_color = "#414868",
--   --       fg_color = "#c0caf5",
--   --       intensity = "Normal",
--   --       underline = "None",
--   --       italic = false,
--   --       strikethrough = false,
--   --     },
--   --     inactive_tab = {
--   --       bg_color = "#282a36",
--   --       fg_color = "#a9b1d6",
--   --     },
--   --     inactive_tab_hover = {
--   --       bg_color = "#6272a4",
--   --       fg_color = "#f8f8f2",
--   --       italic = true,
--   --     },
--   --     new_tab = {
--   --       bg_color = "#282a36",
--   --       fg_color = "#f8f8f2",
--   --     },
--   --     new_tab_hover = {
--   --       bg_color = "#ff79c6",
--   --       fg_color = "#f8f8f2",
--   --       italic = true,
--   --     },
--   --   },
--   -- },
--   keys = mappings.keys,
--   -- keys = {
--   --   { key = "v", mods = "SHIFT|CTRL", action = "Paste" },
--   --   { key = "c", mods = "SHIFT|CTRL", action = "Copy" },
--   --   { key = "x", mods = "ALT", action = wezterm.action.ActivateCopyMode },
--   --
--   --   { key = "n", mods = "ALT", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
--   --   { key = "c", mods = "ALT", action = wezterm.action({ CloseCurrentPane = { confirm = false } }) },
--   --   { key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action({ ActivateTabRelative = -1 }) },
--   --   { key = "Tab", mods = "CTRL", action = wezterm.action({ ActivateTabRelative = 1 }) },
--   --   { key = "PageUp", mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(-1) },
--   --   { key = "PageDown", mods = "CTRL|SHIFT", action = wezterm.action.MoveTabRelative(1) },
--   --
--   --   { key = "F11", mods = "", action = wezterm.action.ToggleFullScreen },
--   --   { key = "=", mods = "ALT", action = wezterm.action.IncreaseFontSize },
--   --   { key = "-", mods = "ALT", action = wezterm.action.DecreaseFontSize },
--   --   { key = "L", mods = "CTRL", action = wezterm.action.ShowDebugOverlay },
--   --
--   --   { key = "LeftArrow", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 1 }) },
--   --   { key = "DownArrow", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 1 }) },
--   --   { key = "UpArrow", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 1 }) },
--   --   { key = "RightArrow", mods = "ALT|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 1 }) },
--   --
--   --   { key = "LeftArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Left") },
--   --   { key = "DownArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Down") },
--   --   { key = "UpArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Up") },
--   --   { key = "RightArrow", mods = "ALT", action = wezterm.action.ActivatePaneDirection("Right") },
--   --
--   --   { key = "v", mods = "ALT", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
--   --   { key = "s", mods = "ALT", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
--   --
--   --   { key = "1", mods = "ALT", action = wezterm.action({ ActivateTab = 0 }) },
--   --   { key = "2", mods = "ALT", action = wezterm.action({ ActivateTab = 1 }) },
--   --   { key = "3", mods = "ALT", action = wezterm.action({ ActivateTab = 2 }) },
--   --   { key = "4", mods = "ALT", action = wezterm.action({ ActivateTab = 3 }) },
--   --   { key = "5", mods = "ALT", action = wezterm.action({ ActivateTab = 4 }) },
--   --   { key = "6", mods = "ALT", action = wezterm.action({ ActivateTab = 5 }) },
--   --   { key = "7", mods = "ALT", action = wezterm.action({ ActivateTab = 6 }) },
--   --   { key = "8", mods = "ALT", action = wezterm.action({ ActivateTab = 7 }) },
--   --   { key = "9", mods = "ALT", action = wezterm.action({ ActivateTab = 8 }) },
--   -- },
-- }
