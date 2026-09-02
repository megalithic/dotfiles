-- HUD Module
-- Unified HUD system for Hammerspoon
--
-- Provides:
--   - alert()     - Simple ephemeral messages (fancy hs.alert replacement)
--   - toast()     - Notification-style with title/message/icon
--   - panel()     - Rich multi-element HUD (for clipper, etc.)
--   - persistent() - Stays visible until dismissed (indicators)
--
-- API:
--   local hud = require("lib.hud")
--
--   hud.alert("Copied!", { icon = checkIcon, duration = 2 })
--
--   hud.toast({
--     title = "Slack",
--     message = "New message from Alice",
--     appBundleID = "com.tinyspeck.slackmacgap",
--     duration = 5,
--   })
--
--   local panel = hud.panel({ id = "clipper", timeout = 5 })
--   panel:setMedia(image)
--   panel:setStatus("Uploading...")
--   panel:show()
--
--   local indicator = hud.persistent({
--     id = "mic-active",
--     content = { icon = micIcon, color = "error" },
--   })
--   indicator:show()
--

--------------------------------------------------------------------------------
-- TYPE DEFINITIONS
--------------------------------------------------------------------------------

---@class HudAlertOpts
---@field icon? hs.image Icon image
---@field iconType? string Icon type: "checkmark", "warning", "error", "info", "gear"
---@field duration? number Auto-dismiss delay in seconds (default: 3)
---@field size? "small"|"medium"|"large" Size preset (default: "medium")
---@field position? string Anchor position (default: "bottom-center")
---@field offset? number Vertical offset from anchor in points
---@field animation? number Animation duration in milliseconds
---@field style? HudStyleOpts Style overrides

---@class HudStyleOpts
---@field fontSize? number Font size in points
---@field color? table|string Color table or theme color name

---@class HudToastOpts
---@field title string Toast title
---@field message? string Toast message body
---@field subtitle? string Toast subtitle
---@field icon? hs.image Icon image
---@field appBundleID? string App bundle ID for icon
---@field duration? number Auto-dismiss delay in seconds
---@field position? string Anchor position
---@field onClick? function Callback on click
---@field onIconClick? function Callback on icon click

---@class HudPanelOpts
---@field id string Unique panel identifier
---@field position? string Anchor position
---@field timeout? number Auto-dismiss delay in seconds
---@field onHover? table Hover options { scale?: number }

---@class HudPersistentOpts
---@field id string Unique identifier
---@field position? string Anchor position
---@field content? table Content options { icon?, text?, color? }

---@class HudModule
---@field theme table Theme submodule
---@field position table Position submodule
---@field animator table Animator submodule
---@field renderer table Renderer submodule
---@field stack table Stack submodule
---@field persistence table Persistence submodule
---@field types table Types submodule
---@field sfsymbol table SF Symbol submodule

---@type HudModule
local M = {}

-- Submodules
M.theme = require("lib.hud.theme")
M.position = require("lib.hud.position")
M.animator = require("lib.hud.animator")
M.renderer = require("lib.hud.renderer")
M.stack = require("lib.hud.stack")
M.persistence = require("lib.hud.persistence")
M.types = require("lib.hud.types")
M.sfsymbol = require("lib.hud.sfsymbol")

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--- Show a simple alert message
--- Replaces hs.alert with better styling and animation
---@param message string Message to display
---@param opts? table { icon?, duration?, position?, animation?, style? }
---@return table Alert HUD instance
---@usage hud.alert("Copied!")
---@usage hud.alert("Error!", { icon = errorIcon, duration = 5 })
function M.alert(message, opts)
  opts = opts or {}
  local alert = M.types.Alert:new(message, opts)
  return alert:show()
end

--- Show a toast notification
--- Replaces sendCanvasNotification with same features
---@param opts table { title, message?, subtitle?, icon?, appBundleID?, duration?, position?, onClick?, onIconClick? }
---@return table Toast HUD instance
---@usage hud.toast({ title = "Slack", message = "New message", appBundleID = "com.tinyspeck.slackmacgap" })
function M.toast(opts)
  opts = opts or {}
  local toast = M.types.Toast:new(opts)
  return toast:show()
end

--- Create a panel HUD (call :show() to display)
--- For complex multi-element displays like clipper cheatsheet
---@param opts table { id?, position?, timeout?, onHover? }
---@return table Panel HUD instance (call :show() to display)
---@usage local p = hud.panel({ id = "clipper", timeout = 10 })
---@usage p:setMedia(img):setStatus("Ready"):show()
function M.panel(opts)
  opts = opts or {}
  return M.types.Panel:new(opts)
end

--- Create a persistent HUD (call :show() to display)
--- For indicators that stay until explicitly dismissed
---@param opts table { id, content = { icon?, text?, color? }, position?, onClick? }
---@return table Persistent HUD instance (call :show() to display)
---@usage local mic = hud.persistent({ id = "mic", content = { icon = micIcon, color = "error" } })
---@usage mic:show()
function M.persistent(opts)
  opts = opts or {}
  return M.types.Persistent:new(opts)
end

--------------------------------------------------------------------------------
-- MANAGEMENT API
--------------------------------------------------------------------------------

--- Dismiss all active HUDs
---@param opts? table { animate?, type? }
function M.dismissAll(opts)
  opts = opts or {}
  if opts.type == "ephemeral" then
    M.stack.dismissEphemeral({ animate = opts.animate })
  else
    M.stack.dismissAll({ animate = opts.animate })
  end
end

--- Get all active HUDs
---@return table Array of HUD instances
function M.getActive()
  return M.stack.getAll()
end

--- Get a specific HUD by ID
---@param hudId string HUD identifier
---@return table|nil HUD instance
function M.get(hudId)
  return M.stack.get(hudId)
end

--- Dismiss a specific HUD by ID
---@param hudId string HUD identifier
---@param opts? table { animate? }
function M.dismiss(hudId, opts)
  local hud = M.stack.get(hudId)
  if hud then
    hud:dismiss(opts)
  end
end

--------------------------------------------------------------------------------
-- CONVENIENCE API
--------------------------------------------------------------------------------

--- Show a success alert
---@param message string Message
---@param opts? table Additional options
function M.success(message, opts)
  opts = opts or {}
  opts.iconType = opts.iconType or "checkmark"
  opts.style = opts.style or {}
  opts.style.color = opts.style.color or M.theme.getColor("success")
  return M.alert(message, opts)
end

--- Show a warning alert
---@param message string Message
---@param opts? table Additional options
function M.warning(message, opts)
  opts = opts or {}
  opts.iconType = opts.iconType or "warning"
  opts.style = opts.style or {}
  opts.style.color = opts.style.color or M.theme.getColor("warning")
  return M.alert(message, opts)
end

--- Show an error alert
---@param message string Message
---@param opts? table Additional options
function M.error(message, opts)
  opts = opts or {}
  opts.iconType = opts.iconType or "error"
  opts.style = opts.style or {}
  opts.style.color = opts.style.color or M.theme.getColor("error")
  return M.alert(message, opts)
end

--- Show an info alert
---@param message string Message
---@param opts? table Additional options
function M.info(message, opts)
  opts = opts or {}
  opts.iconType = opts.iconType or "info"
  opts.style = opts.style or {}
  opts.style.color = opts.style.color or M.theme.getColor("info")
  return M.alert(message, opts)
end

--------------------------------------------------------------------------------
-- SF SYMBOLS
--------------------------------------------------------------------------------

--- Get an SF Symbol image (cached)
---@param name string SF Symbol name (e.g., "checkmark", "gearshape", "bell.fill")
---@param opts? table { color = "hex", size = number }
---@return hs.image|nil
---@usage local icon = hud.sfSymbol("checkmark", { color = "4CD964", size = 32 })
function M.sfSymbol(name, opts)
  return M.sfsymbol.image(name, opts)
end

--------------------------------------------------------------------------------
-- ICON RESOLUTION
--------------------------------------------------------------------------------

--- Resolve an app icon from identifier
--- Handles special cases like "hal9000" and bundle IDs
---@param identifier string Bundle ID or special identifier
---@return hs.image|nil
---@usage local icon = hud.resolveIcon("hal9000")
---@usage local icon = hud.resolveIcon("com.apple.Finder")
function M.resolveIcon(identifier)
  return M.renderer.getAppIcon(identifier)
end

--------------------------------------------------------------------------------
-- CLEANUP
--------------------------------------------------------------------------------

--- Clean up all HUDs (call on reload)
function M.cleanup()
  M.stack.cleanup()
end

return M
