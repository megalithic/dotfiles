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

wezterm.on("window-config-reloaded", function(window, pane)
  window:toast_notification("wezterm", "configuration reloaded!", nil, 4000)
end)

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
  local icon = ""

  if dir == nil or dir == "" then
    title = basename(pane.foreground_process_name)
  end

  if dir == basename(wezterm.home_dir) then
    title = "~"
  end

  if tab.is_active then
    icon = tab.active_pane.is_zoomed and " " or "綠"
    return {
      { Text = "" },
      { Text = fmt(" %s %d:%s ", icon, tab.tab_index + 1, title) },
      { Text = "" },
    }
  else
    icon = tab.active_pane.is_zoomed and " " or "○"
    return {
      { Text = "" },
      { Text = fmt(" %s %d:%s ", icon, tab.tab_index + 1, title) },
      { Text = "" },
    }
  end
end)

-- wezterm.on("update-right-status", function(window, pane)
--   local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")

--   local bat = ""
--   for _, b in ipairs(wezterm.battery_info()) do
--     bat = string.format("%.0f%% %0.2f hours", b.state_of_charge * 100, b.time_to_empty / 60 / 60)
--       .. " "
--       .. string.lower(b.state)
--   end

--   if bat == "" then
--     bat = " | "
--   else
--     bat = " | " .. bat .. " | "
--   end

--   log("hi!")
--   window:set_right_status(wezterm.format({
--     { Text = wezterm.hostname() .. bat .. date },
--   }))
-- end)

-- wezterm.on("update-right-status", function(window, pane)
--   local config = window:effective_config()
--   local session_name = "default"
--   local session_color = "#a36666"

--   for i, v in ipairs(config.unix_domains) do
--     if v.name ~= nil and v.name ~= "" then
--       session_name = v.name
--       session_color = "#7fa5bd"
--       break
--     end
--   end

--   window:set_right_status(wezterm.format({
--     { Foreground = { Color = "#ffffff" } },
--     { Text = wezterm.strftime("%H:%M %e %h") },
--     { Attribute = { Intensity = "Bold" } },
--     { Foreground = { Color = session_color } },
--     { Text = " " .. session_name },
--   }))
-- end)

wezterm.on("update-right-status", function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  local config = window:effective_config()
  local session_name = "default"
  local session_color = "#a36666"

  for i, v in ipairs(config.unix_domains) do
    if v.name ~= nil and v.name ~= "" then
      session_name = v.name
      session_color = "#7fa5bd"
      break
    end
  end

  -- Figure out the cwd and host of the current pane.
  -- This will pick up the hostname for the remote host if your
  -- shell is using OSC 7 on the remote host.
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    cwd_uri = cwd_uri:sub(8)
    local slash = cwd_uri:find("/")
    local cwd = ""
    local hostname = ""
    if slash then
      hostname = cwd_uri:sub(1, slash - 1)
      -- Remove the domain name portion of the hostname
      local dot = hostname:find("[.]")
      if dot then
        hostname = hostname:sub(1, dot - 1)
      end
      -- and extract the cwd from the uri
      cwd = cwd_uri:sub(slash)

      table.insert(cells, cwd)
      table.insert(cells, hostname)
    end
  end

  -- I like my date/time in this style: "Wed Mar 3 08:14"
  local date = wezterm.strftime("%H:%M")
  table.insert(cells, date)

  -- local success, utc, _ = wezterm.run_child_process({ "TZ='/usr/share/zoneinfo/UTC' date", "'+%%H:%%M'" })
  -- if success then
  --   table.insert(cells, utc)
  -- end

  -- An entry for each battery (typically 0 or 1 battery)
  for _, b in ipairs(wezterm.battery_info()) do
    table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
  end

  table.insert(
    cells,
    wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { Color = session_color } },
      { Text = " " .. session_name },
    })
  )

  --   local date = wezterm.strftime("%Y-%m-%d %H:%M:%S")

  --   local bat = ""
  --   for _, b in ipairs(wezterm.battery_info()) do
  --     bat = string.format("%.0f%% %0.2f hours", b.state_of_charge * 100, b.time_to_empty / 60 / 60)
  --       .. " "
  --       .. string.lower(b.state)
  --   end

  --   if bat == "" then
  --     bat = " | "
  --   else
  --     bat = " | " .. bat .. " | "
  --   end

  --   log("hi!")
  --   window:set_right_status(wezterm.format({
  --     { Text = wezterm.hostname() .. bat .. date },
  --   }))

  -- The powerline < symbol
  local LEFT_ARROW = utf8.char(0xe0b3)
  -- The filled in variant of the < symbol
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

  -- Color palette for the backgrounds of each cell

  local colors = {
    "#3c474d",
    "#465258",
    "#505a60",
    "#576268",
    "#626262",
  }

  -- Foreground color for the text across the fade
  local text_fg = "#c0c0c0"

  -- The elements to be formatted
  local elements = {}
  -- How many cells have been formatted
  local num_cells = 0

  -- Translate a cell into elements
  function push(text, is_last)
    local cell_no = num_cells + 1
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = " " .. text .. " " })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)

--- [ COLORS ] -----------------------------------------------------------------
-- @note: megaforest
local palette = {
  background = "#323d43",
  bright_background = "#3a464d",
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
    bg_color = palette.bright_background,
    fg_color = palette.blue,
    intensity = "Bold",
    italic = true,
    underline = "Single",
  },
  inactive_tab_edge = palette.bright_background,
  inactive_tab = {
    bg_color = palette.bright_background,
    fg_color = palette.bright_white,
  },
  inactive_tab_hover = {
    bg_color = palette.bright_background,
    fg_color = palette.blue,
  },
  new_tab = {
    bg_color = palette.visual,
    fg_color = palette.background,
  },
}

-- A helper function for my fallback fonts
local function font_with_fallback(font, params)
  local names = {
    font,
    "codicon",
  }
  return wezterm.font_with_fallback(names, params)
end

--- [ FONTS ] ------------------------------------------------------------------
local fonts = {
  font = font_with_fallback({ family = "JetBrainsMonoMedium Nerd Font Mono" }),
  font_rules = {
    {
      italic = true,
      font = font_with_fallback("JetBrainsMono Nerd Font Mono"),
    },
    {
      italic = true,
      intensity = "Bold",
      font = font_with_fallback("JetBrainsMonoExtraBold Nerd Font Mono"),
    },
    {
      intensity = "Bold",
      font = font_with_fallback("JetBrainsMonoExtraBold Nerd Font Mono"),
    },
  },
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
  font_shaper = "Harfbuzz",
  harfbuzz_features = {
    "zero=1", -- Use a slashed zero '0' (instead of dotted)
    "kern=1", -- (default) kerning (todo check what is really is)
    "liga=1", -- (default) ligatures
    "clig=1", -- (default) contextual ligatures
  },
  cursor_blink_rate = 0,
}

--- [ MAPPINGS ] ---------------------------------------------------------------
local mappings = {
  -- tmux-style leader prefix <C-space>
  leader = { key = " ", mods = "CTRL", timeout_milliseconds = 1000 },
  keys = {
    { key = "x", mods = "ALT", action = "ShowLauncher" },
    { key = "w", mods = "CTRL", action = "QuickSelect" },
    { key = "w", mods = "LEADER|CTRL", action = "QuickSelect" },
    { key = " ", mods = "LEADER|CTRL", action = "ShowLauncher" },
  },
}

--- [ TABS ] -------------------------------------------------------------------
local tabs = {
  use_fancy_tab_bar = true,
  hide_tab_bar_if_only_one_tab = false,
  tab_max_width = 200,
  tab_bar_at_bottom = false,
  tab_bar_style = {},
}

--- [ WINDOWS ] ----------------------------------------------------------------
local windows = {
  window_decorations = "RESIZE",
  initial_cols = 100,
  initial_rows = 20,
  window_background_opacity = 1.0,
  window_frame = {
    font = font_with_fallback({ family = "JetBrainsMono Nerd Font Mono", weight = "Medium" }),
    font_size = 15.0,
    active_titlebar_bg = "#323d43",
    inactive_titlebar_bg = "#323d43",
  },
  window_padding = {
    left = "15px",
    right = "15px",
    top = "0px",
    bottom = "0px",
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
  unix_domains = nil,
}

--- [ MOUSe ] ------------------------------------------------------------------
local mouse = {}

--- [ MISC ] -------------------------------------------------------------------
local misc = {
  scrollback_lines = 5000,
  enable_scroll_bar = false,

  check_for_updates = false,
  native_macos_fullscreen_mode = true,
  default_prog = { "/usr/local/bin/zsh" },
  enable_kitty_graphics = true,
  debug_key_events = true,
  use_ime = true,
  status_update_interval = 10000,
  set_environment_variables = {
    -- This fails to find wezterm.nvim.navigator
    PATH = os.getenv("PATH") .. ":/usr/local/bin" .. ":" .. homedir .. "/.bin" .. ":" .. homedir .. "/bin",
  },

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
