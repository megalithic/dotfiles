--- hypemode.lua - Multiple concurrent modal hotkey managers
--- Each modality is independent with its own ID, state, bindings, and indicator.
---
--- Usage:
---   local shadeModality = require("hypemode").new("shade")
---   local wmModality = require("hypemode").new("wm")
---
--- Both can be active simultaneously with separate bindings.

local M = {}
local fmt = string.format

-- Registry of all modality instances by ID
M._registry = {}

-- Default indicator color (can be overridden per-instance)
M.defaultIndicatorColor = "#e39b7b"

---@class Modality
---@field id string Unique identifier for this modality
---@field modal table hs.hotkey.modal instance
---@field isOpen boolean Whether modal is currently active
---@field indicator table|nil hs.canvas indicator (border around window)
---@field indicatorColor string Hex color for indicator border
---@field showIndicator boolean Whether to show border indicator on enter
---@field showAlert boolean Whether to show alert with app name on enter
---@field autoExit boolean|number Whether to auto-exit (true=1s, number=custom delay, false=manual)
---@field alertUuids table|nil Alert UUIDs for cleanup
---@field delayedExitTimer table|nil Timer for auto-exit
---@field customOnEntered function|nil Custom enter callback

--- Create a new modality instance
---@param id string Unique identifier (e.g., "shade", "wm")
---@param opts? table Options: { indicatorColor?: string, showIndicator?: boolean, showAlert?: boolean, autoExit?: boolean|number, on_entered?: function }
---@return Modality
function M.new(id, opts)
  assert(id and type(id) == "string", "modality id must be a string")

  -- Check for duplicate ID
  if M._registry[id] then
    U.log.w(fmt("hypemode: modality '%s' already exists, returning existing instance", id))
    return M._registry[id]
  end

  opts = opts or {}

  -- Create new modal instance
  local modal = hs.hotkey.modal.new({}, nil)

  -- Instance state (isolated per modality)
  -- Indicators default to true (original behavior), but can be disabled
  local instance = {
    id = id,
    modal = modal,
    isOpen = false,
    indicator = nil,
    indicatorColor = opts.indicatorColor or M.defaultIndicatorColor,
    showIndicator = opts.showIndicator ~= true, -- default false
    showAlert = opts.showAlert ~= true, -- default false
    autoExit = opts.autoExit ~= false and (opts.autoExit or 1), -- default 1s, false to disable
    alertUuids = nil,
    delayedExitTimer = nil,
    customOnEntered = opts.on_entered,
  }

  -- Metatable for method access (look up methods on M, not instance)
  local mt = { __index = M }
  setmetatable(instance, mt)

  -- Wire up modal callbacks to instance methods
  function modal:entered() instance:_onEntered() end

  function modal:exited() instance:_onExited() end

  -- Register instance
  M._registry[id] = instance

  return instance
end

--- Get an existing modality by ID
---@param id string
---@return Modality|nil
function M.get(id) return M._registry[id] end

--- List all registered modality IDs
---@return string[]
function M.list()
  local ids = {}
  for id, _ in pairs(M._registry) do
    table.insert(ids, id)
  end
  return ids
end

--- Exit all active modalities
function M.exitAll()
  for _, instance in pairs(M._registry) do
    if instance.isOpen then instance:exit() end
  end
end

-- Instance methods (defined on prototype, called with self)

--- Focus the main window of an app (helper)
---@param bundleID? string Bundle ID or nil for frontmost app
---@param opts? table { h?: number, w?: number, focus?: boolean }
---@return table|nil window
function M.focusMainWindow(bundleID, opts)
  local app
  if bundleID == nil or bundleID == "" then
    app = hs.application.frontmostApplication()
  else
    app = hs.application.find(bundleID)
  end

  if not app then
    U.log.w("focusMainWindow: app not found")
    return nil
  end

  opts = opts or { h = 800, w = 800, focus = true }

  local mainWin = app:mainWindow()
  local win = hs.fnutils.find(app:allWindows(), function(w)
    local isMain = (mainWin == nil) or (mainWin == w)
    return isMain and w:frame().w >= opts.w and w:frame().h >= opts.h
  end)

  if not win and #app:allWindows() > 0 then win = app:allWindows()[1] end

  if win ~= nil and opts.focus then win:focus() end

  local winTitle = win and win:title() or (mainWin and mainWin:title()) or "no window"
  U.log.n(fmt("%s (%s)", app:bundleID() or "unknown", winTitle))

  return win
end

--- Toggle indicator border around window
---@param self Modality
---@param win? table Window to indicate
---@param terminate? boolean If true, destroy indicator
function M._toggleIndicator(self, win, terminate)
  win = win or hs.window.focusedWindow()

  if self.indicator == nil and win ~= nil then
    local frame = win:frame()
    self.indicator = hs.canvas.new(frame):appendElements({
      type = "rectangle",
      action = "stroke",
      strokeWidth = 2.0,
      strokeColor = { hex = self.indicatorColor, alpha = 0.7 },
      roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
    })
  end

  if terminate then
    if self.indicator then
      self.indicator:delete()
      self.indicator = nil
    end
  else
    if self.indicator then
      if self.indicator:isShowing() then
        self.indicator:hide()
      else
        self.indicator:show()
      end
    end
  end

  return self.indicator
end

--- Internal: called when modal is entered
---@param self Modality
function M._onEntered(self)
  if self.customOnEntered ~= nil and type(self.customOnEntered) == "function" then
    self.customOnEntered(self.isOpen, self)
  else
    local win = M.focusMainWindow() or hs.window.focusedWindow()

    if win ~= nil then
      self.isOpen = true

      -- Show border indicator if enabled
      if self.showIndicator then self:_toggleIndicator(win) end

      -- Show alert with app name if enabled
      if self.showAlert then
        self.alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
          if screen == hs.screen.mainScreen() then
            local appTitle = win:application():title()
            local appImage = hs.image.imageFromAppBundle(win:application():bundleID())
            local text = fmt("◱ %s: %s", self.id, appTitle)

            if appImage ~= nil then
              text = fmt("%s: %s", self.id, appTitle)
              return hs.alert.showWithImage(text, appImage, nil, screen)
            end

            return hs.alert.show(text, hs.alert.defaultStyle, screen, true)
          end
        end)
      end

      -- Auto-exit after delay if enabled (independent of alerts)
      if self.autoExit then
        local delay = type(self.autoExit) == "number" and self.autoExit or 1
        self:delayedExit(delay)
      end
    else
      self:exit()
    end
  end
end

--- Internal: called when modal is exited
---@param self Modality
function M._onExited(self)
  self.isOpen = false
  if self.alertUuids ~= nil then
    hs.fnutils.ieach(self.alertUuids, function(uuid)
      if uuid ~= nil then hs.alert.closeSpecific(uuid) end
    end)
    self.alertUuids = nil
  end
  self:_toggleIndicator(nil, true)

  if self.delayedExitTimer ~= nil then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end
end

--- Schedule automatic exit after delay
---@param self Modality
---@param delay? number Seconds (default 1)
---@return Modality self for chaining
function M.delayedExit(self, delay)
  delay = delay or 1

  if self.delayedExitTimer ~= nil then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end

  self.delayedExitTimer = hs.timer.doAfter(delay, function() self:exit() end)

  return self
end

--- Toggle modal on/off
---@param self Modality
---@return Modality self for chaining
function M.toggle(self)
  if self.isOpen then
    self:exit()
  else
    self:enter()
  end
  return self
end

--- Start the modality (initialize with default bindings)
---@param self Modality
---@param opts? table { on_entered?: function }
---@return Modality self for chaining
function M.start(self, opts)
  opts = opts or {}
  hs.window.animationDuration = 0

  if opts.on_entered then self.customOnEntered = opts.on_entered end

  -- Default escape binding
  self:bind("", "escape", function() self:exit() end)

  return self
end

--- Bind a hotkey to this modality
---@param self Modality
---@param mods string|table Modifier keys
---@param key string Key
---@param pressedfn? function Called on key press
---@param releasedfn? function Called on key release
---@param repeatfn? function Called on key repeat
---@return Modality self for chaining
function M.bind(self, mods, key, pressedfn, releasedfn, repeatfn)
  self.modal:bind(mods, key, pressedfn, releasedfn, repeatfn)
  return self
end

--- Enter the modal state
---@param self Modality
---@return Modality self for chaining
function M.enter(self)
  self.modal:enter()
  return self
end

--- Exit the modal state
---@param self Modality
---@param delay? number Optional delay before exit
---@return Modality self for chaining
function M.exit(self, delay)
  if delay then
    self:delayedExit(delay)
  else
    self.modal:exit()
  end
  return self
end

--- Destroy this modality (cleanup and unregister)
---@param self Modality
function M.destroy(self)
  self:exit()
  if self.indicator then
    self.indicator:delete()
    self.indicator = nil
  end
  M._registry[self.id] = nil
end

return M
