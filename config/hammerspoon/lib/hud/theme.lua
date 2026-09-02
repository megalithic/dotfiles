-- HUD Theme Module
-- Color schemes and dark/light mode support
--
-- All colors defined in tables, easy to switch between dark/light mode.
-- Uses hs.host.interfaceStyle() for system appearance detection.
--

---@class HudColor
---@field red number Red component (0-1)
---@field green number Green component (0-1)
---@field blue number Blue component (0-1)
---@field alpha number Alpha component (0-1)

---@class HudColorScheme
---@field background HudColor
---@field backgroundSubtle HudColor
---@field shadow HudColor
---@field border HudColor
---@field borderActive HudColor
---@field title HudColor
---@field subtitle HudColor
---@field message HudColor
---@field timestamp HudColor
---@field muted HudColor
---@field success HudColor
---@field warning HudColor
---@field error HudColor
---@field info HudColor
---@field accent HudColor
---@field accentActive HudColor

---@class HudTheme
---@field colors table<string, HudColorScheme> Color schemes by mode
---@field fonts table Font configuration
---@field sizes table Size configuration
---@field getMode fun(): string Get current mode ("dark" or "light")
---@field getColors fun(): HudColorScheme Get colors for current mode
---@field getColor fun(name: string): HudColor Get specific color by name

local M = {}

--------------------------------------------------------------------------------
-- COLOR SCHEMES
--------------------------------------------------------------------------------

M.colors = {
  dark = {
    -- Backgrounds (match original notifier design #2c2c2e)
    background = { red = 0.17, green = 0.17, blue = 0.18, alpha = 0.95 },
    backgroundSubtle = { red = 0.15, green = 0.15, blue = 0.16, alpha = 0.9 },
    shadow = { red = 0, green = 0, blue = 0, alpha = 0.5 },

    -- Borders
    border = { red = 0.30, green = 0.30, blue = 0.31, alpha = 0.85 },
    borderActive = { red = 0.3, green = 0.7, blue = 0.4, alpha = 0.9 },

    -- Text (match original notifier design)
    title = { red = 0.92, green = 0.92, blue = 0.92, alpha = 1.0 },
    subtitle = { red = 0.92, green = 0.92, blue = 0.92, alpha = 1.0 },  -- Same as title per notifier
    message = { red = 0.96, green = 0.96, blue = 0.97, alpha = 1.0 },  -- #f5f5f7
    timestamp = { red = 0.56, green = 0.56, blue = 0.58, alpha = 0.85 },  -- #8e8e93
    muted = { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.7 },

    -- Semantic colors
    success = { red = 0.4, green = 0.8, blue = 0.4, alpha = 1.0 },
    warning = { red = 1.0, green = 0.7, blue = 0.2, alpha = 1.0 },
    error = { red = 1.0, green = 0.4, blue = 0.4, alpha = 1.0 },
    info = { red = 0.5, green = 0.7, blue = 1.0, alpha = 1.0 },

    -- Accents
    accent = { red = 0.5, green = 0.7, blue = 1.0, alpha = 1.0 },
    accentActive = { red = 0.3, green = 0.9, blue = 0.5, alpha = 1.0 },

    -- Interactive states
    highlight = { red = 0.2, green = 0.25, blue = 0.3, alpha = 1.0 },
    hover = { red = 0.25, green = 0.25, blue = 0.27, alpha = 1.0 },
  },

  light = {
    -- Backgrounds (match original notifier design)
    background = { red = 0.98, green = 0.98, blue = 0.98, alpha = 0.92 },
    backgroundSubtle = { red = 0.95, green = 0.95, blue = 0.95, alpha = 0.9 },
    shadow = { red = 0, green = 0, blue = 0, alpha = 0.3 },

    -- Borders
    border = { red = 0.85, green = 0.85, blue = 0.85, alpha = 0.6 },
    borderActive = { red = 0.1, green = 0.6, blue = 0.3, alpha = 0.9 },

    -- Text (match original notifier design)
    title = { red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0 },
    subtitle = { red = 0.1, green = 0.1, blue = 0.1, alpha = 1.0 },  -- Same as title per notifier
    message = { red = 0.3, green = 0.3, blue = 0.3, alpha = 1.0 },
    timestamp = { red = 0.5, green = 0.5, blue = 0.5, alpha = 0.85 },
    muted = { red = 0.6, green = 0.6, blue = 0.6, alpha = 0.7 },

    -- Semantic colors
    success = { red = 0.2, green = 0.6, blue = 0.2, alpha = 1.0 },
    warning = { red = 0.8, green = 0.5, blue = 0.0, alpha = 1.0 },
    error = { red = 0.8, green = 0.2, blue = 0.2, alpha = 1.0 },
    info = { red = 0.2, green = 0.4, blue = 0.8, alpha = 1.0 },

    -- Accents
    accent = { red = 0.2, green = 0.4, blue = 0.8, alpha = 1.0 },
    accentActive = { red = 0.1, green = 0.6, blue = 0.3, alpha = 1.0 },

    -- Interactive states
    highlight = { red = 0.92, green = 0.94, blue = 0.96, alpha = 1.0 },
    hover = { red = 0.90, green = 0.92, blue = 0.94, alpha = 1.0 },
  },
}

--------------------------------------------------------------------------------
-- FONTS
--------------------------------------------------------------------------------

M.fonts = {
  system = ".AppleSystemUIFont",
  systemBold = ".AppleSystemUIFontBold",
  mono = "Menlo",
}

M.sizes = {
  titleLarge = 18,
  title = 16,
  subtitle = 15,
  body = 14,
  small = 13,
  tiny = 11,
}

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

--- Convert hex color string to color table
---@param hex string Hex color (e.g., "4CD964" or "#4CD964")
---@param alpha? number Alpha value (default 1.0)
---@return table Color table { red, green, blue, alpha }
function M.hexToColor(hex, alpha)
  hex = hex:gsub("#", "")
  return {
    red = tonumber(hex:sub(1, 2), 16) / 255,
    green = tonumber(hex:sub(3, 4), 16) / 255,
    blue = tonumber(hex:sub(5, 6), 16) / 255,
    alpha = alpha or 1.0,
  }
end

--- Get current system appearance
---@return "dark"|"light"
function M.getAppearance()
  local style = hs.host.interfaceStyle()
  return style == "Dark" and "dark" or "light"
end

--- Get color scheme for current appearance
---@return table Colors for current mode
function M.getColors()
  return M.colors[M.getAppearance()]
end

--- Get a specific color, respecting current appearance
---@param name string Color name (e.g., "background", "title", "success")
---@return table|nil Color table or nil if not found
function M.getColor(name)
  local colors = M.getColors()
  return colors[name]
end

--- Get color scheme for a specific appearance
---@param appearance "dark"|"light" Target appearance
---@return table Colors for specified mode
function M.getColorsFor(appearance)
  return M.colors[appearance] or M.colors.dark
end

--- Check if system is in dark mode
---@return boolean
function M.isDarkMode()
  return M.getAppearance() == "dark"
end

return M
