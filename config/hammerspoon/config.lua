local M = {}

HYPER = "F19"
-- BROWSER = "com.nix.brave-browser-nightly-debug"
BROWSER = "com.brave.Browser.nightly"
TERMINAL = "com.mitchellh.ghostty"

---@class NotificationRule
---@field name string                   # Human-readable name for the rule
---@field appBundleID string            # Bundle ID or stacking ID to match
---@field senders? string[]             # Optional: list of sender names to match (exact match)
---@field patterns? table<"low"|"normal"|"high", string[]> # Patterns mapped to priorities (default: normal if no match)
---@field duration? number              # How long to show notification in seconds
---@field alwaysShowInTerminal? boolean # Show even when terminal is focused (high priority only)
---@field showWhenAppFocused? boolean   # Show even when source app is focused (high priority only)
---@field overrideFocusModes? string[]|true  # Focus modes this notification can bypass/override. If undefined: blocks during ANY focus mode. If true: overrides ALL focus modes. If array: shows during those specific focus modes. (always shows when no focus mode active)
---@field appImageID? string            # Custom icon identifier (e.g. "hal9000")

M.displays = {
  internal = "Built-in Retina Display",
  laptop = "Built-in Retina Display",
  external = "LG UltraFine",
}

M.grid = {
  full = "0,0 60x20",
  preview = "0,0 60x2",

  center = {
    large = "6,1 48x18",
    medium = "12,1 36x18",
    small = "16,2 28x16",
    tiny = "18,3 24x12",
    mini = "22,4 16x10",
  },

  sixths = {
    left = "0,0 10x20",
    right = "50,0 10x20",
  },

  thirds = {
    left = "0,0 20x20",
    center = "20,0 20x20",
    right = "40,0 20x20",
  },

  halves = {
    left = "0,0 30x20",
    right = "30,0 30x20",
  },

  twoThirds = {
    left = "0,0 40x20",
    right = "20,0 40x20",
  },

  fiveSixths = {
    left = "0,0 50x20",
    right = "10,0 50x20",
  },
}

M.layouts = {
  --- [bundleID] = { name, bundleID, {{ winTitle, screenNum, gridPosition }} }
  ["com.raycast.macos"] = {
    name = "Raycast",
    bundleID = "com.raycast.macos",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["net.kovidgoyal.kitty"] = {
    bundleID = "net.kovidgoyal.kitty",
    name = "kitty",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.github.wez.wezterm"] = {
    bundleID = "com.github.wez.wezterm",
    name = "wezterm",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.mitchellh.ghostty"] = {
    bundleID = "com.mitchellh.ghostty",
    name = "ghostty",
    rules = {
      { "Software Update", 1, M.grid.center.small },
      { "", 1, M.grid.full },
    },
  },
  ["com.kagi.kagimacOS"] = {
    bundleID = "com.kagi.kagimacOS",
    name = "Orion",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.mozilla.floorp"] = {
    bundleID = "org.mozilla.floorp",
    name = "Floorp",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.brave.Browser.nightly"] = {
    bundleID = "com.brave.Browser.nightly",
    name = "Brave Browser Nightly",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.brave.Browser.dev"] = {
    bundleID = "com.brave.Browser.dev",
    name = "Brave Browser Dev",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.apple.Safari"] = {
    bundleID = "com.apple.Safari",
    name = "Safari",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["com.apple.SafariTechnologyPreview"] = {
    bundleID = "com.apple.SafariTechnologyPreview",
    name = "Safari Technology Preview",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["org.chromium.Thorium"] = {
    bundleID = "org.chromium.Thorium",
    name = "Thorium",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.chromium.Chromium"] = {
    bundleID = "org.chromium.Chromium",
    name = "Chromium",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["org.mozilla.firefoxdeveloperedition"] = {
    bundleID = "org.mozilla.firefoxdeveloperedition",
    name = "Firefox Developer Edition",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["com.kapeli.dashdoc"] = {
    bundleID = "com.kapeli.dashdoc",
    name = "Dash",
    rules = {
      { "", 1, M.grid.full },
    },
  },
  ["com.obsproject.obs-studio"] = {
    bundleID = "com.obsproject.obs-studio",
    name = "OBS Studio",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["co.detail.mac"] = {
    bundleID = "co.detail.mac",
    name = "Detail",
    rules = {
      { "", 2, M.grid.full },
    },
  },
  ["com.freron.MailMate"] = {
    bundleID = "com.freron.MailMate",
    name = "MailMate",
    rules = {
      { nil, 2, M.grid.halves.left },
      { "Inbox", 2, M.grid.full },
      { "All Messages", 2, M.grid.full },
    },
  },
  ["com.apple.finder"] = {
    bundleID = "com.apple.finder",
    name = "Finder",
    rules = {
      { "", 1, M.grid.center.medium },
    },
  },
  ["com.spotify.client"] = {
    bundleID = "com.spotify.client",
    name = "Spotify",
    rules = {
      { "", 2, M.grid.halves.right },
    },
  },
  ["com.electron.postbird"] = {
    bundleID = "com.electron.postbird",
    name = "Postbird",
    rules = {
      { "", 1, M.grid.center.large },
    },
  },
  ["com.apple.MobileSMS"] = {
    bundleID = "com.apple.MobileSMS",
    name = "Messages",
    rules = {
      -- { "", 2, M.grid.full },
      -- { "", 2, M.grid.thirds.left },
      { "", 2, M.grid.halves.left },
    },
  },
  ["org.whispersystems.signal-desktop"] = {
    bundleID = "org.whispersystems.signal-desktop",
    name = "Signal",
    rules = {
      { "", 2, M.grid.halves.right },
    },
  },
  ["com.tinyspeck.slackmacgap"] = {
    bundleID = "com.tinyspeck.slackmacgap",
    name = "Slack",
    rules = {
      { nil, 2, M.grid.full },
    },
  },
  ["com.agilebits.onepassword7"] = {
    bundleID = "com.1password.1password",
    name = "1Password",
    rules = {
      { nil, 1, M.grid.center.medium },
    },
  },
  ["org.hammerspoon.Hammerspoon"] = {
    bundleID = "org.hammerspoon.Hammerspoon",
    name = "Hammerspoon",
    rules = {
      { nil, 1, M.grid.full },
    },
  },
  ["com.dexterleng.Homerow"] = {
    bundleID = "com.dexterleng.Homerow",
    name = "Homerow",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["com.flexibits.fantastical2.mac"] = {
    bundleID = "com.flexibits.fantastical2.mac",
    name = "Fantastical",
    rules = {
      { nil, 1, M.grid.center.large },
    },
  },
  ["com.figma.Desktop"] = {
    bundleID = "com.figma.Desktop",
    name = "Figma",
    rules = {
      { nil, 1, M.grid.full },
    },
  },
  ["com.apple.iphonesimulator"] = {
    bundleID = "com.apple.iphonesimulator",
    name = "iPhone Simulator",
    rules = {
      { nil, 1, M.grid.halves.right },
    },
  },
  ["com.softfever3d.orca-slicer"] = {
    bundleID = "com.softfever3d.orca-slicer",
    name = "OrcaSlicer",
    rules = {
      { "", 1, M.grid.full },
    },
  },
}

-- Quitter Configuration
-- Prevents accidental Cmd+Q quits for important apps
-- Modes:
--   "single" = one Cmd+Q quits (use with nuke=true for instant death)
--   "double" = press Cmd+Q twice within 1s to quit
--   "long"   = hold Cmd+Q for 1s to quit
-- Options:
--   nuke = true means use kill9() (SIGKILL) instead of graceful kill()
M.quitters = {
  -- Zoom gets instant death - one Cmd+Q = NUKE (kill9)
  ["us.zoom.xos"] = { mode = "single", nuke = true },

  -- Browsers: double-tap to quit (graceful)
  ["com.brave.Browser.nightly"] = { mode = "double" },
  ["com.brave.Browser.dev"] = { mode = "double" },
  ["com.brave.Browser"] = { mode = "double" },
  ["net.imput.helium"] = { mode = "double" },
  ["org.chromium.Thorium"] = { mode = "double" },
  ["org.chromium.Chromium"] = { mode = "double" },
  ["com.kagi.kagimacOS"] = { mode = "double" },
  ["org.mozilla.firefoxdeveloperedition"] = { mode = "double" },
  ["com.apple.SafariTechnologyPreview"] = { mode = "double" },
  ["com.apple.Safari"] = { mode = "double" },

  -- Terminals: double-tap to quit (graceful)
  ["com.mitchellh.ghostty"] = { mode = "double" },
  ["net.kovidgoyal.kitty"] = { mode = "double" },
  ["com.github.wez.wezterm"] = { mode = "double" },

  -- Launchers: double-tap to quit (graceful)
  ["com.raycast.macos"] = { mode = "double" },
  ["com.runningwithcrayons.Alfred"] = { mode = "double" },

  -- Other apps
  ["com.pop.pop.app"] = { mode = "double" },
}

-- Reserved Hyper Keys
-- Keys that are globally reserved and cannot be bound to other actions
-- Used to prevent future binding conflicts (e.g., HYPER+Q for force quit)
M.reservedHyperKeys = {
  q = "Force Quit (NUKE IT!)",
}

M.lollygaggers = {
  --- [bundleID] = { hideAfter, quitAfter }
  ["org.hammerspoon.Hammerspoon"] = { 1, nil },
  ["com.flexibits.fantastical2.mac"] = { 1, nil },
  ["com.1password.1password"] = { 1, nil },
  ["com.spotify.client"] = { 1, nil },
}

M.launchers = {
  { "com.brave.Browser.nightly", "j", nil },
  { "com.mitchellh.ghostty", "k", { "`" } },
  -- { "net.kovidgoyal.kitty", "k", nil },
  { "com.apple.MobileSMS", "m", nil }, -- NOOP for now.. TODO: implement a binding feature that let's us require n-presses before we execute
  { "com.apple.finder", "f", nil },
  { "com.spotify.client", "p", nil },
  { "com.freron.MailMate", "e", nil },
  { "com.flexibits.fantastical2.mac", "y", { "'" } },
  { "com.raycast.macos", "space", { "c" } },
  { "com.superultra.Homerow", nil, { ";" } },
  { "com.tinyspeck.slackmacgap", "s", nil },
  { "com.microsoft.teams2", "t", nil },
  { "org.hammerspoon.Hammerspoon", "r", nil },
  -- { "com.kapeli.dashdoc", { { "shift" }, "d" }, { "d" } },
  { "com.electron.postbird", { { "shift" }, "p" }, nil },
  { "com.1password.1password", "1", nil },
  { "commonplace.canonize.app", nil, { { { "shift" }, "s" } } },
  { "com.apple.dt.Xcode", "x", nil, true },
  { "com.obsproject.obs-studio", "o", nil, true },
  { "com.microsoft.VSCode", "v", nil, true },
}

M.dock = {
  target = {
    productID = 39536,
    productName = "LG UltraFine Display Controls",
    vendorID = 1086,
    vendorName = "LG Electronics Inc.",
  },
  target_alt = {
    productID = 21760,
    productName = "TS4 USB3.2 Gen2 HUB",
    vendorID = 8584,
    vendorName = "CalDigit, Inc",
  },
  keyboard = {
    connected = "leeloo",
    disconnected = "internal",
    productID = 24926,
    productName = "Leeloo",
    vendorID = 7504,
    vendorName = "ZMK Project",
  },
  kanata = {
    enabled = false, -- Set to true to enable Kanata profile switching
    connected = "leeloo.kbd",
    disconnected = "internal.kbd",
    configPath = os.getenv("HOME") .. "/.config/kanata",
    daemonLabel = "org.nixos.kanata",
  },
  docked = {
    wifi = "off",
    input = "Samson GoMic",
    output = "megabose",
  },
  undocked = {
    wifi = "on",
    input = "megabose",
    output = "megabose",
  },
}

M.notifier = {
  -- Notification Routing Rules
  -- Rules are evaluated in order. First match wins.
  -- Each rule is a table defining matching criteria and behavior.
  rules = {
    -- Fantastical Calendar Alerts (TIME SENSITIVE = imminent, usually 1-minute warnings)
    -- These get highest priority to ensure you never miss imminent meetings
    -- Note: Fantastical sends "TIME SENSITIVE" as the title for urgent alerts
    {
      name = "Fantastical Urgent Alerts",
      appBundleID = "com.flexibits.fantastical2.mac",
      senders = { "TIME SENSITIVE" }, -- Fantastical marks imminent alerts this way
      duration = 15, -- Show for 15 seconds (urgent!)
      alwaysShowInTerminal = true, -- Interrupt coding for imminent meetings!
      showWhenAppFocused = false, -- Don't double-notify if Fantastical is open
      overrideFocusModes = true, -- Override ALL focus modes
      appImageID = "com.flexibits.fantastical2.mac",
      -- Force high priority for all TIME SENSITIVE alerts
      patterns = {
        high = { "." }, -- Match anything (all TIME SENSITIVE alerts are high priority)
      },
    },

    -- NOTE: Non-urgent Fantastical alerts (15/30 min warnings) are NOT intercepted.
    -- They go through macOS Notification Center normally. Only TIME SENSITIVE alerts
    -- (matched above by sender) are captured and shown via our custom canvas.

    {
      name = "Important Messages",
      appBundleID = "com.apple.MobileSMS",
      senders = { "Abby Messer" },
      duration = 5,
      patterns = {
        high = {
          "%?",
          "👋",
          "❓",
          "‼️",
          "⚠️",
          "urgent",
          "asap",
          "emergency",
          -- "!+$",
          "%?+$",
        },
        -- low = {
        --   "brb",
        --   "ok",
        --   "👍",
        --   "lol",
        -- },
        -- Everything else defaults to "normal"
      },
      alwaysShowInTerminal = true,
      showWhenAppFocused = false,
      overrideFocusModes = true, -- Override ALL focus modes
    },

    -- Example: All other Messages notifications (lower priority)
    {
      name = "Messages",
      appBundleID = "com.apple.MobileSMS",
      -- No overrideFocusModes = blocks during any focus mode
    },

    -- Telegram Desktop notifications
    {
      name = "Telegram",
      appBundleID = "com.tdesktop.Telegram",
      duration = 5,
      patterns = {
        high = {
          "%?",
          "urgent",
          "asap",
          -- "!+$",
          "%?+$",
        },
      },
      alwaysShowInTerminal = true,
      showWhenAppFocused = false,
      -- No overrideFocusModes = blocks during any focus mode
      appImageID = "com.tdesktop.Telegram",
    },

    -- AI Agent Notifications (from ntfy via hs.notify)
    {
      name = "AI Agent Notifications",
      appBundleID = "org.hammerspoon.Hammerspoon",
      duration = 3,
      patterns = {
        high = {
          "error",
          "failed",
          "critical",
          "urgent",
          "question",
          "%?",
          "!+$",
          "‼️",
          "⚠️",
          "%?+$",
        },
        low = {
          "info",
          "debug",
          "starting",
          "completed",
          "finished",
        },
        -- Everything else defaults to "normal"
      },
      alwaysShowInTerminal = true,
      showWhenAppFocused = false,
      overrideFocusModes = { "Personal", "Work" },
      appImageID = "hal9000", -- Special marker for HAL icon
    },

    -- Example: Build notifications with pattern-based priority
    {
      name = "Build System Notifications",
      appBundleID = "com.example.buildapp",
      duration = 3,
      patterns = {
        high = {
          "failed",
          "error",
          "fatal",
          "broke",
        },
        low = {
          "started",
          "building",
          "compiling",
          "running",
        },
        -- "succeeded", "completed" = normal (default)
      },
      overrideFocusModes = { "Work" },
    },
  },

  -- Notification positioning configuration
  -- Vertical offsets (in pixels) from bottom of screen for different programs
  -- These values account for typical prompt heights in each program
  -- NOTE: Programs with expanding UI (thinking indicators, token counters) need extra padding
  offsets = {
    nvim = 100, -- Neovim: minimal offset (statusline at bottom, no prompt)
    vim = 100, -- Vim: same as neovim
    ["nvim-diff"] = 100,
    fish = 350, -- Fish: multiline prompt with git info
    bash = 300, -- Bash: standard prompt
    zsh = 300, -- Zsh: standard prompt
    claude = 155, -- Claude Code: optimized via screenshot testing with expanding UI (prompt + thinking + tokens)
    ["claude-code"] = 155, -- Claude Code: AI coding assistant with expanding prompt UI
    opencode = 155, -- OpenCode: AI coding assistant with expanding prompt UI
    lazygit = 200, -- Lazygit: status bar at bottom
    htop = 150, -- htop: minimal UI at bottom
    btop = 150, -- btop: minimal UI at bottom
    node = 155, -- Node.js (fallback for claude-code, opencode)
    default = 200, -- Default for unknown programs
  },

  -- Whether to apply offset adjustment when tmux is detected
  tmuxShiftEnabled = true,

  -- Default positioning (Neovim-style anchor + position system)
  -- anchor: "screen" | "window" | "app" (coordinate system context)
  -- position: "NW" | "N" | "NE" | "W" | "C" | "E" | "SW" | "S" | "SE" (cardinal direction)
  -- Examples:
  --   anchor="screen", position="SW" → bottom-left of screen (with auto offset)
  --   anchor="window", position="C" → center of focused window
  --   anchor="screen", position="N" → top-center of screen
  defaultAnchor = "screen",
  defaultPosition = "SW",

  -- Minimum offset to ensure notification is always visible
  minOffset = 100,

  -- Default notification duration (in seconds)
  defaultDuration = 3,

  -- Animation settings
  animation = {
    enabled = true, -- Enable slide-up animation from bottom of screen
    duration = 0.3, -- Animation duration in seconds (0.3 = smooth, 0.5 = slower)
  },

  -- Network event icons (nerd font icons or emoji)
  networkIcons = {
    router_connected = "󰱓", -- Nerd font: network icon
    router_disconnected = "󰱟", -- Nerd font: network off icon
    internet_connected = "󰱓", -- Nerd font: network icon
    internet_disconnected = "󰖪", -- Nerd font: wifi off icon (or use 󰱓)
  },

  -- Dismiss notification keybinding (only affects active canvas notifications)
  -- Format: { mods, key } where mods is table of modifiers (e.g., {"shift"}, {})
  dismissBindings = { {}, "escape" }, -- F19+escape to dismiss
  clickDismiss = true, -- Click dimming overlay to dismiss

  -- Color schemes for light and dark mode
  colors = {
    light = {
      shadow = { red = 0.0, green = 0.0, blue = 0.0, alpha = 0.3 },
      background = { red = 0.98, green = 0.98, blue = 0.98, alpha = 0.92 },
      border = { red = 0.85, green = 0.85, blue = 0.85, alpha = 0.6 },
      title = { red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0 },
      message = { red = 0.3, green = 0.3, blue = 0.3, alpha = 1.0 },
      timestamp = { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.85 },
    },
    dark = {
      shadow = { red = 0.0, green = 0.0, blue = 0.0, alpha = 0.5 },
      background = { red = 0.17, green = 0.17, blue = 0.18, alpha = 0.95 }, -- #2c2c2e
      border = { red = 0.30, green = 0.30, blue = 0.31, alpha = 0.85 }, -- Lighter border for better visibility
      title = { red = 0.92, green = 0.92, blue = 0.92, alpha = 1.0 }, -- Slightly darker than pure white
      message = { red = 0.96, green = 0.96, blue = 0.97, alpha = 1.0 }, -- #f5f5f7
      timestamp = { red = 0.56, green = 0.56, blue = 0.58, alpha = 0.85 }, -- #8e8e93
    },
  },

  -- Database retention settings
  retentionDays = 30, -- Keep notifications for 30 days before cleanup

  -- Agent notification settings (used by N.send() API via ntfy CLI)
  agent = {
    -- Urgency → duration mapping (in seconds)
    durations = {
      normal = 5,
      high = 10,
      critical = 15,
    },

    -- Question retry settings (for unanswered questions)
    questionRetry = {
      enabled = true,
      intervalSeconds = 300, -- 5 minutes between retries
      maxRetries = 3, -- Give up after 3 retries
      escalateOnRetry = true, -- Send to phone on retry
    },

    -- Pushover settings (tokens via agenix env vars)
    pushover = {
      enabled = true,
      -- Tokens read from env: PUSHOVER_USER_TOKEN, PUSHOVER_APP_TOKEN
    },

    -- Phone notification settings (iMessage)
    phone = {
      enabled = true,
      -- Phone number read from env: IMESSAGE_PHONE_NUMBER
      cacheTTL = 604800, -- 7 days in seconds for caching phone number
    },
  },
}

local extra_config = {}

local success, _ = pcall(function() extra_config = require("extra_config") end)

if success then
  for key, _ in pairs(M) do
    if extra_config[key] then M[key] = extra_config[key] end
    if M[key] == "" then M[key] = nil end
  end
end

return M
