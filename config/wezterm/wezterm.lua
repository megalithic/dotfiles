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
-- TODO: https://wezfurlong.org/wezterm/faq.html#how-do-i-enable-undercurl-curly-underlines
--
local w = require("wezterm")
local act = w.action
local mux = w.mux
local os = require("os")
local homedir = os.getenv("HOME")
local fmt = string.format
local is_tmux = os.getenv("TMUX") ~= ""

-- local function log(msg) w.log_info(msg) end
--
-- -- Equivalent to POSIX basename(3)
-- -- Given "/foo/bar" returns "bar"
-- -- Given "c:\\foo\\bar" returns "bar"
-- local function basename(s) return string.gsub(s, "(.*[/\\])(.*)", "%2") end

local function notify(opts)
  if opts.window == nil then return end

  opts = opts or {}
  local title = opts.title or "wezterm"
  local message = opts.message or ""
  local timeout = opts.timeout or 4000
  local window = opts.window

  window:toast_notification(title, message, nil, timeout)
end

local function log_proc(proc, indent)
  indent = indent or ""
  w.log_info(indent .. "pid=" .. proc.pid .. ", name=" .. proc.name .. ", status=" .. proc.status)
  w.log_info(indent .. "argv=" .. table.concat(proc.argv, " "))
  w.log_info(indent .. "executable=" .. proc.executable .. ", cwd=" .. proc.cwd)
  for _pid, child in pairs(proc.children) do
    log_proc(child, indent .. "  ")
  end
end

-- w.on("gui-startup", function()
--   local _tab, _pane, window = w.mux.spawn_window({})
--   window:gui_window():maximize()
-- end)

w.on(
  "window-config-reloaded",
  function(window, _pane)
    notify({ title = "wezterm", message = "configuration reloaded!", window = window, timeout = 4000 })
  end
)

w.on("mux-is-process-stateful", function(proc)
  log_proc(proc)

  return false -- don't ask for confirmation, nothing stateful here
end)

-- w.on("user-var-changed", function(window, _pane, name, value)
--   notify({
--     title = "wezterm",
--     message = string.format("user-var-changed: %s -> %s", name, value),
--     window = window,
--     timeout = 4000,
--   })
--
--   local overrides = window:get_config_overrides() or {}
--   if name == "SCREEN_SHARE_MODE" then
--     if value == "on" then
--       overrides.font_size = 20
--     else
--       overrides.font_size = nil
--     end
--   end
--
--   window:set_config_overrides(overrides)
-- end)

w.on("user-var-changed", function(window, pane, name, value)
  local profile_data = require("profile_data")
  local wezterm_config_nvim = w.plugin.require("https://github.com/winter-again/wezterm-config.nvim")
  local overrides = window:get_config_overrides() or {}
  overrides = wezterm_config_nvim.override_user_var(overrides, name, value, profile_data)
  window:set_config_overrides(overrides)
end)

-- wezterm.on("user-var-changed", function(window, pane, name, value)
--   local overrides = window:get_config_overrides() or {}
--   if name == "ZEN_MODE" then
--     local incremental = value:find("+")
--     local number_value = tonumber(value)
--     if incremental ~= nil then
--       while number_value > 0 do
--         window:perform_action(wezterm.action.IncreaseFontSize, pane)
--         number_value = number_value - 1
--       end
--       overrides.enable_tab_bar = false
--     elseif number_value < 0 then
--       window:perform_action(wezterm.action.ResetFontSize, pane)
--       overrides.font_size = nil
--       overrides.enable_tab_bar = true
--     else
--       overrides.font_size = number_value
--       overrides.enable_tab_bar = false
--     end
--   end
--   window:set_config_overrides(overrides)
-- end)

--- [ COLORS ] -----------------------------------------------------------------

-- @note: megaforest
local palette = {
  background = "#323d43", -- #2f3d44, #323d43
  bright_background = "#2f3d44",
  -- background = "",
  -- bright_background = "",
  foreground = "#d3c6aa", -- #d8cacc
  bright_foreground = "#d3c6aa",
  cursor = "#83b6af",
  -- cursor = "#d8cacc",
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

local colors = {}

colors.background = palette.background
colors.foreground = palette.foreground

colors.cursor_fg = palette.black
colors.cursor_bg = palette.cursor
colors.cursor_border = palette.foreground

colors.selection_fg = palette.fg
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

--- [ FONTS ] ------------------------------------------------------------------

-- local harfbuzz_features = { "calt", "liga", "dlig", "ss01", "ss02", "ss03", "ss04", "ss05", "ss06", "ss07", "ss08" }
-- local harfbuzz_features =
--   { "calt=1", "liga=1", "dlig=1", "ss01=1", "ss02=1", "ss03=1", "ss04=1", "ss05=1", "ss06=1", "ss07=1", "ss08=1" }
local harfbuzz_features = nil
local maplemono_harfbuzz_features = {
  "calt=1", -- no ligatures => ===
  "cv01=1", -- fully attached @ # $ etc.
  "cv02=0", -- curly i
  "cv03=1", -- upper arm on a
  "cv04=1", -- @ rounded
  "ss01=1", -- == !=, etc
  "ss02=1", -- [info]
  "ss03=1", -- --
  "ss04=1", -- >= <= tight
  "ss05=1", -- {{  }} tight
}
local font = {
  JetBrainsMono = {
    Normal = { family = "JetBrains Mono", weight = "Medium", harfbuzz_features },
    Italic = { family = "JetBrains Mono", italic = true, harfbuzz_features },
    Bold = { family = "JetBrains Mono", weight = "ExtraBlack", harfbuzz_features },
    BoldItalic = { family = "JetBrains Mono", italic = true, weight = "ExtraBlack", harfbuzz_features },
  },
  JetBrainsMonoNerdFont = {
    Normal = { family = "JetBrainsMono Nerd Font Mono", weight = "Medium", harfbuzz_features },
    Italic = { family = "JetBrainsMono Nerd Font Mono", italic = true, harfbuzz_features },
    Bold = { family = "JetBrainsMono Nerd Font Mono", weight = "ExtraBlack", harfbuzz_features },
    BoldItalic = { family = "JetBrainsMono Nerd Font Mono", italic = true, weight = "ExtraBlack", harfbuzz_features },
  },
  VictorMonoNerdFont = {
    Normal = { family = "VictorMono Nerd Font Mono", weight = "Medium", harfbuzz_features },
    Italic = { family = "VictorMono Nerd Font Mono", italic = true, harfbuzz_features },
    Bold = { family = "VictorMono Nerd Font Mono", weight = "ExtraBlack", harfbuzz_features },
    BoldItalic = { family = "VictorMono Nerd Font Mono", italic = true, weight = "ExtraBlack", harfbuzz_features },
  },
  MapleMono = {
    Normal = { family = "Maple Mono", weight = "Medium", maplemono_harfbuzz_features },
    Italic = { family = "Maple Mono", italic = true, maplemono_harfbuzz_features },
    Bold = { family = "Maple Mono", weight = "ExtraBlack", maplemono_harfbuzz_features },
    BoldItalic = { family = "Maple Mono", italic = true, weight = "ExtraBlack", maplemono_harfbuzz_features },
  },
}

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == "true"
end

-- if you *ARE* lazy-loading smart-splits.nvim (not recommended)
-- you have to use this instead, but note that this will not work
-- in all cases (e.g. over an SSH connection). Also note that
-- `pane:get_foreground_process_name()` can have high and highly variable
-- latency, so the other implementation of `is_vim()` will be more
-- performant as well.
-- local function is_vim(pane)
--   -- This gsub is equivalent to POSIX basename(3)
--   -- Given "/foo/bar" returns "bar"
--   -- Given "c:\\foo\\bar" returns "bar"
--   local process_name = string.gsub(pane:get_foreground_process_name(), "(.*[/\\])(.*)", "%2")
--   return process_name == "nvim" or process_name == "vim"
-- end

local direction_keys = {
  Left = "h",
  Down = "j",
  Up = "k",
  Right = "l",
  -- reverse lookup
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "META" or "CTRL",
    action = w.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

return {
  term = "wezterm",
  audible_bell = "Disabled",
  -- send_composed_key_when_left_alt_is_pressed = true,
  -- send_composed_key_when_right_alt_is_pressed = false,
  adjust_window_size_when_changing_font_size = false,
  exit_behavior = "Close",
  exit_behavior_messaging = "None",

  swallow_mouse_click_on_pane_focus = true,
  swallow_mouse_click_on_window_focus = true,

  -- Terminate WezTerm?
  -- Detach and close all panes and terminate wezterm?
  -- https://github.com/wez/wezterm/pull/4420
  window_close_confirmation = "NeverPrompt",
  disable_default_key_bindings = true,
  front_end = "WebGpu", -- OpenGL, WebGpu, Software
  webgpu_power_preference = "HighPerformance",
  window_decorations = "RESIZE",
  macos_window_background_blur = 10,
  -- window_background_opacity = 0.95,
  force_reverse_video_cursor = true,
  use_cap_height_to_scale_fallback_fonts = true,
  warn_about_missing_glyphs = false,
  unicode_version = 15,
  custom_block_glyphs = true,
  allow_square_glyphs_to_overflow_width = "WhenFollowedBySpace",
  bold_brightens_ansi_colors = true,
  cell_width = 1,
  font_size = 14,
  line_height = 1.1,

  text_blink_rate = 100,
  cursor_blink_rate = 300,
  cursor_blink_ease_in = "Linear", -- alts: Constant
  cursor_blink_ease_out = "Linear", -- alts: Constant
  default_cursor_style = "BlinkingBar",

  freetype_load_flags = "NO_HINTING",
  freetype_load_target = "Light",
  freetype_render_target = "HorizontalLcd",
  font = w.font_with_fallback({
    -- "Maple Mono",
    font.JetBrainsMonoNerdFont.Normal,
    { family = "Rec Mono Duotone", weight = "Medium" },
    -- charset fallbacks ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ (ﾉಥ益ಥ）ﾉ︵┻━┻
    "Apple Color Emoji",
    "Noto Color Emoji",
    "Material Icons Rounded",
    "Noto Sans Mono", -- linux + smallcaps
    "Monaco", -- mac + smallcaps
    { family = "Symbols Nerd Font Mono", scale = 0.8 },
    { family = "Unifont", scale = 1.2 }, -- bitmap fallback with a lot of unicode
    -- emoji fallback 👉 👀 😁 💩 ✅
    "Noto Color Emoji",
  }),
  window_padding = {
    left = "20px",
    right = "10px",
    top = "20px",
    bottom = "10px",
  },
  font_rules = {
    {
      intensity = "Bold",
      italic = true,
      font = w.font_with_fallback({
        -- font.MapleMono.BoldItalic,
        font.JetBrainsMono.BoldItalic,
        font.JetBrainsMonoNerdFont.BoldItalic,
        { family = "Rec Mono Duotone", weight = "ExtraBlack", italic = true },
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
    {
      italic = true,
      font = w.font_with_fallback({
        -- font.MapleMono.Italic,
        font.JetBrainsMono.Italic,
        font.JetBrainsMonoNerdFont.Italic,
        { family = "Rec Mono Duotone", italic = true },
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
    {
      intensity = "Bold",
      font = w.font_with_fallback({
        -- font.MapleMono.Bold,
        font.JetBrainsMono.Bold,
        font.JetBrainsMonoNerdFont.Bold,
        { family = "Rec Mono Duotone", weight = "ExtraBlack", italic = false },
        { family = "Symbols Nerd Font Mono", scale = 0.8 },
      }),
    },
  },
  hide_tab_bar_if_only_one_tab = true,
  colors = colors,
  leader = { key = "Space", mods = "CTRL|SHIFT" },
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
    { key = "t", mods = "CMD", action = act.SendString("\x00\x63") },
    {
      key = "e",
      mods = "CMD|CTRL|SHIFT",
      action = act.EmitEvent("toggle-ligature"), -- TEST: |>
    },
    { key = "q", mods = "CMD", action = act.QuitApplication },
    { key = "w", mods = "CMD", action = w.action.CloseCurrentTab({ confirm = false }) },
    { key = "+", mods = "CMD", action = w.action.IncreaseFontSize },
    { key = "-", mods = "CMD", action = w.action.DecreaseFontSize },
    { key = "0", mods = "CMD", action = w.action.ResetFontSize },
    { key = "=", mods = "CMD", action = w.action.ResetFontSize },
    { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
    { key = "d", mods = "CMD|CTRL", action = act.ShowDebugOverlay },
    { key = "n", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
    {
      key = "n",
      mods = "LEADER",
      action = w.action.SpawnCommandInNewWindow({
        domain = "CurrentPaneDomain",
        args = { "zsh", "-ic", "nvim", "-c", "'+Neorg journal today'" },
        position = {
          x = 600,
          y = 400,
          -- Optional origin to use for x and y.
          -- Possible values:
          -- * "ScreenCoordinateSystem" (this is the default)
          -- * "MainScreen" (the primary or main screen)
          -- * "ActiveScreen" (whichever screen hosts the active/focused window)
          -- * {Named="HDMI-1"} - uses a screen by name. See wezterm.gui.screens()
          origin = "ActiveScreen",
        },
      }),
    },
    {
      key = "o",
      mods = "CMD|CTRL",
      action = act({
        QuickSelectArgs = {
          label = "OPEN URL",
          patterns = {
            "https?://\\S+",
            "git://\\S+",
            "ssh://\\S+",
            "ftp://\\S+",
            "file://\\S+",
            "mailto://\\S+",
            [[h?t?t?p?s?:?/?/?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}\b[-a-zA-Z0-9@:%_\+.~#?&/=]*]],
            [[h?t?t?p?:?/?/?localhost:?[0-9]*/?\b[-a-zA-Z0-9@:%_\+.~#?&/=]*]],
          },
          action = w.action_callback(function(window, pane)
            local url = window:get_selection_text_for_pane(pane)
            w.log_info("opening: " .. url)
            w.open_with(url)
          end),
        },
      }),
    },
    {
      key = "u",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({
        label = "COPY URL",
        patterns = {
          "https?://\\S+",
          "git://\\S+",
          "ssh://\\S+",
          "ftp://\\S+",
          "file://\\S+",
          "mailto://\\S+",
          [[h?t?t?p?s?:?/?/?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}\b[-a-zA-Z0-9@:%_\+.~#?&/=]*]],
          [[h?t?t?p?:?/?/?localhost:?[0-9]*/?\b[-a-zA-Z0-9@:%_\+.~#?&/=]*]],
        },
      }),
    },
    {
      key = "M",
      mods = "CMD|CTRL",
      action = act({
        QuickSelectArgs = {
          label = "COPY GOOGLE MEET ID",
          patterns = {
            "https?://meet.google.com/\\S+",
          },
          action = w.action_callback(function(window, pane)
            local selection = window:get_selection_text_for_pane(pane)
            local id = string.gsub(selection, "https?://meet.google.com/", "")
            window:copy_to_clipboard(id, "ClipboardAndPrimarySelection")
          end),
        },
      }),
    },
    {
      key = "m",
      mods = "CMD|CTRL",
      action = act({
        QuickSelectArgs = {
          label = "OPEN AND COPY GOOGLE MEET ID",
          patterns = {
            "https?://meet.google.com/\\S+",
          },
          action = w.action_callback(function(window, pane)
            local selection = window:get_selection_text_for_pane(pane)
            local id = string.gsub(selection, "https?://meet.google.com/", "")
            window:copy_to_clipboard(id, "ClipboardAndPrimarySelection")
            w.open_with(selection)
          end),
        },
      }),
    },
    {
      key = "c",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({
        label = "COPY CMDLINE",
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
        label = "COPY IP",
        patterns = {
          "[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+",
          "[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}\z
    :[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}:[0-9a-fA-F]{0,4}",
        },
      }),
    },

    { key = "p", mods = "CMD|CTRL", action = act.QuickSelect }, -- select path
    { key = "l", mods = "CMD|CTRL", action = act.QuickSelectArgs({ label = "COPY LINE", patterns = { "^.+$" } }) },
    {
      key = "s",
      mods = "CMD|CTRL",
      action = act.QuickSelectArgs({ label = "COPY SHA1", patterns = { "[0-9a-f]{7,40}" } }),
    },
    -- { key = "s", mods = "CMD|CTRL", action = act.Search({ Regex = "" }) }, -- search mode
    -- { key = "g", mods = "CMD|CTRL", action = act.ActivateCopyMode }, -- copy mode
    -- move between split panes
    -- split_nav("move", "h"),
    -- split_nav("move", "j"),
    -- split_nav("move", "k"),
    -- split_nav("move", "l"),
    -- -- resize panes
    -- split_nav("resize", "h"),
    -- split_nav("resize", "j"),
    -- split_nav("resize", "k"),
    -- split_nav("resize", "l"),
  },
}
