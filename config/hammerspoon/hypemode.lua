--- hypemode.lua - Modal hotkey manager with real-time window tracking
--- 
--- Features:
---   - Window movement/resize tracking via fast polling (20fps)
---   - Immediate overlay/indicator updates, deferred alert recreation
---   - Overlay, indicator, and alert follow window in real-time
---   - Cleaner separation of visual management
---
--- Usage:
---   local hypemode = require("hypemode")
---   local wmModality = hypemode.new("wm", {
---     showAlert = true,
---     showIndicator = true,
---     dimWindow = 0.5,
---   })

local M = {}
local fmt = string.format

-- Registry of all modality instances by ID
M._registry = {}

-- Default indicator color
M.defaultIndicatorColor = "#e39b7b"

-- Update throttle (seconds) - debounce interval for visual updates
M.UPDATE_INTERVAL = 0.008  -- ~120fps, feels instant

--------------------------------------------------------------------------------
-- PROFILING / DEBUG TIMING
--------------------------------------------------------------------------------

M.DEBUG = true  -- Set to false to disable timing logs

local profileStart = {}

--- Start a profiling timer
---@param name string Timer name
local function profStart(name)
  if not M.DEBUG then return end
  profileStart[name] = hs.timer.absoluteTime()
end

--- End a profiling timer and log result
---@param name string Timer name
---@param threshold? number Only log if exceeds this many ms (default: 0)
local function profEnd(name, threshold)
  if not M.DEBUG then return end
  threshold = threshold or 0
  local startTime = profileStart[name]
  if not startTime then return end
  
  local elapsed = (hs.timer.absoluteTime() - startTime) / 1e6  -- ns to ms
  profileStart[name] = nil
  
  if elapsed >= threshold then
    U.log.d(fmt("[PERF] %s: %.2fms", name, elapsed))
  end
end

--------------------------------------------------------------------------------
-- VISUAL MANAGER
-- Handles overlay, indicator, and alert as a coordinated unit
--------------------------------------------------------------------------------

local VisualManager = {}
VisualManager.__index = VisualManager

function VisualManager.new(opts)
  local self = setmetatable({}, VisualManager)
  
  self.targetWindow = nil
  self._pollTimer = nil  -- Polling timer for window tracking
  self._trackedWindow = nil
  self._lastFrame = nil
  
  -- Visual elements
  self.dimOverlay = nil
  self.indicator = nil
  self.hudAlert = nil
  
  -- Configuration
  self.dimEnabled = opts.dimWindow ~= nil and opts.dimWindow ~= false
  self.dimAlpha = type(opts.dimWindow) == "number" and opts.dimWindow or 0.5
  self.indicatorEnabled = opts.showIndicator == true
  self.indicatorColor = opts.indicatorColor or M.defaultIndicatorColor
  self.alertEnabled = opts.showAlert == true
  self.alertPosition = opts.alertPosition or "center"
  
  -- Debounce state
  self.updateTimer = nil
  self.settleTimer = nil
  self.pendingUpdate = false
  self._alertNeedsUpdate = false
  
  return self
end

--- Attach to a window and create visual elements
function VisualManager:attach(win)
  profStart("attach:total")
  
  if not win then return false end
  
  self.targetWindow = win
  local frame = win:frame()
  
  -- Create dim overlay
  if self.dimEnabled then
    profStart("attach:dimOverlay")
    self.dimOverlay = hs.canvas.new(frame)
    self.dimOverlay:appendElements({
      type = "rectangle",
      action = "fill",
      fillColor = { red = 0, green = 0, blue = 0, alpha = self.dimAlpha },
      roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
    })
    self.dimOverlay:level(hs.canvas.windowLevels.floating)
    self.dimOverlay:behavior(hs.canvas.windowBehaviors.transient)
    self.dimOverlay:show()
    profEnd("attach:dimOverlay")
  end
  
  -- Create indicator border
  if self.indicatorEnabled then
    profStart("attach:indicator")
    self.indicator = hs.canvas.new(frame)
    self.indicator:appendElements({
      type = "rectangle",
      action = "stroke",
      strokeWidth = 3.0,
      strokeColor = { hex = self.indicatorColor, alpha = 0.9 },
      roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
    })
    self.indicator:level(hs.canvas.windowLevels.floating + 1)
    self.indicator:behavior(hs.canvas.windowBehaviors.transient)
    self.indicator:show()
    profEnd("attach:indicator")
  end
  
  -- Create HUD alert
  if self.alertEnabled then
    profStart("attach:alert")
    self:_createAlert(win)
    profEnd("attach:alert")
  end
  
  -- Set up window tracking
  profStart("attach:tracking")
  self:_startTracking(win)
  profEnd("attach:tracking")
  
  profEnd("attach:total")
  return true
end

--- Create or recreate the HUD alert at window position
function VisualManager:_createAlert(win)
  profStart("createAlert")
  
  -- Dismiss existing alert
  if self.hudAlert then
    profStart("createAlert:dismiss")
    self.hudAlert:dismiss({ animate = false })
    self.hudAlert = nil
    profEnd("createAlert:dismiss")
  end
  
  if not win then 
    profEnd("createAlert")
    return 
  end
  
  local app = win:application()
  if not app then 
    profEnd("createAlert")
    return 
  end
  
  profStart("createAlert:icon")
  local appIcon = hs.image.imageFromAppBundle(app:bundleID())
  profEnd("createAlert:icon")
  
  profStart("createAlert:HUD.alert")
  self.hudAlert = HUD.alert(app:title(), {
    icon = appIcon,
    position = self.alertPosition,
    window = win,
    duration = 0, -- Manual dismiss
  })
  profEnd("createAlert:HUD.alert")
  
  profEnd("createAlert")
end

--- Start tracking window movement/resize via polling (AX watcher had API issues)
function VisualManager:_startTracking(win)
  self:_stopTracking()
  
  -- Store reference to tracked window
  self._trackedWindow = win
  self._lastFrame = win:frame()
  
  -- Use fast polling to detect window changes (every 50ms = 20fps)
  -- This is simpler and more reliable than AX watchers
  self._pollTimer = hs.timer.doEvery(0.05, function()
    if not self._trackedWindow or not self._trackedWindow:isVisible() then
      return
    end
    
    local currentFrame = self._trackedWindow:frame()
    if not self._lastFrame 
       or currentFrame.x ~= self._lastFrame.x 
       or currentFrame.y ~= self._lastFrame.y
       or currentFrame.w ~= self._lastFrame.w 
       or currentFrame.h ~= self._lastFrame.h then
      self._lastFrame = currentFrame
      self:_scheduleUpdate()
    end
  end)
end

--- Stop tracking
function VisualManager:_stopTracking()
  -- Stop poll timer
  if self._pollTimer then
    self._pollTimer:stop()
    self._pollTimer = nil
  end
  self._trackedWindow = nil
  self._lastFrame = nil
end

--- Schedule a debounced update (coalesces rapid events)
function VisualManager:_scheduleUpdate()
  -- Cancel settle timer if movement continues
  if self.settleTimer then
    self.settleTimer:stop()
    self.settleTimer = nil
  end
  
  -- If cooldown timer exists, just mark pending - don't reschedule
  if self.updateTimer then
    self.pendingUpdate = true
    return
  end
  
  -- For first event, update immediately then start cooldown
  self:_performUpdate()
  
  -- Brief cooldown to coalesce rapid-fire events
  self.updateTimer = hs.timer.doAfter(M.UPDATE_INTERVAL, function()
    self.updateTimer = nil
    -- If more updates came during cooldown, do one final update
    if self.pendingUpdate then
      self.pendingUpdate = false
      self:_performUpdate()
    end
    
    -- Schedule settle timer for expensive operations (alert recreation)
    self.settleTimer = hs.timer.doAfter(0.1, function()
      self.settleTimer = nil
      self:_finalizeUpdate()
    end)
  end)
end

--- Actually update visual positions
function VisualManager:_performUpdate()
  profStart("performUpdate")
  
  local win = self.targetWindow
  if not win then 
    profEnd("performUpdate")
    return 
  end
  
  -- Check window still exists
  if not win:id() then
    self:detach()
    profEnd("performUpdate")
    return
  end
  
  profStart("performUpdate:getFrame")
  local frame = win:frame()
  profEnd("performUpdate:getFrame")
  
  -- Update dim overlay (instant - just moves canvas)
  if self.dimOverlay then
    profStart("performUpdate:dimOverlay")
    self.dimOverlay:frame(frame)
    profEnd("performUpdate:dimOverlay")
  end
  
  -- Update indicator (instant - just moves canvas)
  if self.indicator then
    profStart("performUpdate:indicator")
    self.indicator:frame(frame)
    profEnd("performUpdate:indicator")
  end
  
  -- Alert: defer recreation until movement settles (expensive operation)
  -- We'll recreate it in _finalizeUpdate called after debounce settles
  if self.alertEnabled and self.hudAlert then
    -- Just hide during movement for now
    if self.hudAlert.canvas then
      self.hudAlert.canvas:hide()
    end
    self._alertNeedsUpdate = true
  end
  
  profEnd("performUpdate")
end

--- Called when movement has settled - recreate expensive elements
function VisualManager:_finalizeUpdate()
  if self._alertNeedsUpdate and self.alertEnabled then
    self._alertNeedsUpdate = false
    self:_createAlert(self.targetWindow)
  end
end

--- Force immediate update (for explicit moves via chain/wm)
function VisualManager:updateNow()
  -- Cancel any pending timers
  if self.updateTimer then
    self.updateTimer:stop()
    self.updateTimer = nil
  end
  if self.settleTimer then
    self.settleTimer:stop()
    self.settleTimer = nil
  end
  self.pendingUpdate = false
  
  -- Update overlay/indicator immediately
  self:_performUpdate()
  
  -- Also finalize (recreate alert) since this is an explicit call
  self:_finalizeUpdate()
end

--- Detach from window and clean up
function VisualManager:detach()
  -- Stop tracking
  self:_stopTracking()
  
  -- Cancel pending updates
  if self.updateTimer then
    self.updateTimer:stop()
    self.updateTimer = nil
  end
  if self.settleTimer then
    self.settleTimer:stop()
    self.settleTimer = nil
  end
  
  -- Clean up dim overlay
  if self.dimOverlay then
    self.dimOverlay:delete()
    self.dimOverlay = nil
  end
  
  -- Clean up indicator
  if self.indicator then
    self.indicator:delete()
    self.indicator = nil
  end
  
  -- Dismiss HUD alert
  if self.hudAlert then
    self.hudAlert:dismiss()
    self.hudAlert = nil
  end
  
  self.targetWindow = nil
end

--- Show indicator (for chain cycling)
function VisualManager:showIndicator()
  if self.indicator then
    self.indicator:show()
  end
end

--------------------------------------------------------------------------------
-- MODALITY CLASS
--------------------------------------------------------------------------------

---@class ModalityV2
---@field id string Unique identifier
---@field modal table hs.hotkey.modal instance
---@field isOpen boolean Whether modal is active
---@field visualManager VisualManager Visual element manager
---@field autoExit boolean|number Auto-exit setting
---@field delayedExitTimer table|nil Timer for auto-exit
---@field customOnEntered function|nil Custom enter callback

--- Create a new modality instance
---@param id string Unique identifier (e.g., "wm", "shade")
---@param opts? table Options
---@return ModalityV2
function M.new(id, opts)
  assert(id and type(id) == "string", "modality id must be a string")
  opts = opts or {}
  
  -- Update existing instance on reload
  if M._registry[id] then
    local existing = M._registry[id]
    -- Clean up old visual manager before replacing
    existing.visualManager:detach()
    existing.visualManager = VisualManager.new(opts)
    existing.autoExit = opts.autoExit ~= false and (opts.autoExit or 1)
    existing.customOnEntered = opts.on_entered
    return existing
  end
  
  -- Create modal
  local modal = hs.hotkey.modal.new({}, nil)
  
  local instance = {
    id = id,
    modal = modal,
    isOpen = false,
    visualManager = VisualManager.new(opts),
    autoExit = opts.autoExit ~= false and (opts.autoExit or 1),
    delayedExitTimer = nil,
    customOnEntered = opts.on_entered,
  }
  
  setmetatable(instance, { __index = M })
  
  -- Wire up modal callbacks
  function modal:entered() instance:_onEntered() end
  function modal:exited() instance:_onExited() end
  
  M._registry[id] = instance
  return instance
end

--- Get existing modality by ID
function M.get(id)
  return M._registry[id]
end

--- List all registered modality IDs
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
    if instance.isOpen then
      instance:exit()
    end
  end
end

--------------------------------------------------------------------------------
-- INSTANCE METHODS
--------------------------------------------------------------------------------

--- Focus main window of an app
function M.focusMainWindow(bundleID, opts)
  local app
  if bundleID == nil or bundleID == "" then
    app = hs.application.frontmostApplication()
  else
    app = hs.application.find(bundleID)
  end
  
  if not app then
    U.log.w("focusMainWindow - app not found")
    return nil
  end
  
  opts = opts or { h = 800, w = 800, focus = true }
  
  local mainWin = app:mainWindow()
  local win = hs.fnutils.find(app:allWindows(), function(w)
    local isMain = (mainWin == nil) or (mainWin == w)
    return isMain and w:frame().w >= opts.w and w:frame().h >= opts.h
  end)
  
  if not win and #app:allWindows() > 0 then
    win = app:allWindows()[1]
  end
  
  if win and opts.focus then
    win:focus()
  end
  
  return win
end

--- Called when modal is entered
function M:_onEntered()
  profStart("modal:onEntered")
  
  if self.customOnEntered then
    self.customOnEntered(self.isOpen, self)
    profEnd("modal:onEntered")
    return
  end
  
  profStart("modal:focusMainWindow")
  local win = M.focusMainWindow() or hs.window.focusedWindow()
  profEnd("modal:focusMainWindow")
  
  if not win then
    self:exit()
    profEnd("modal:onEntered")
    return
  end
  
  self.isOpen = true
  
  -- Attach visual manager to window
  profStart("modal:attachVisuals")
  self.visualManager:attach(win)
  profEnd("modal:attachVisuals")
  
  -- Auto-exit after delay
  if self.autoExit then
    local delay = type(self.autoExit) == "number" and self.autoExit or 1
    self:delayedExit(delay)
  end
  
  profEnd("modal:onEntered")
end

--- Called when modal is exited
function M:_onExited()
  profStart("modal:onExited")
  
  self.isOpen = false
  
  -- Detach visual manager
  profStart("modal:detachVisuals")
  self.visualManager:detach()
  profEnd("modal:detachVisuals")
  
  -- Cancel auto-exit timer
  if self.delayedExitTimer then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end
  
  profEnd("modal:onExited")
end

--- Schedule exit after delay
function M:delayedExit(delay)
  delay = delay or 1
  
  if self.delayedExitTimer then
    self.delayedExitTimer:stop()
    self.delayedExitTimer = nil
  end
  
  self.delayedExitTimer = hs.timer.doAfter(delay, function()
    self:exit()
  end)
  
  return self
end

--- Toggle modal on/off
function M:toggle()
  if self.isOpen then
    self:exit()
  else
    self:enter()
  end
  return self
end

--- Start the modality
function M:start(opts)
  opts = opts or {}
  hs.window.animationDuration = 0
  
  if opts.on_entered then
    self.customOnEntered = opts.on_entered
  end
  
  -- Default escape binding
  self:bind({}, "escape", function() self:exit() end)
  
  return self
end

--- Bind a hotkey
function M:bind(mods, key, pressedfn, releasedfn, repeatfn)
  self.modal:bind(mods, key, pressedfn, releasedfn, repeatfn)
  return self
end

--- Enter modal state
function M:enter()
  self.modal:enter()
  return self
end

--- Exit modal state
function M:exit(delay)
  if delay then
    self:delayedExit(delay)
  else
    self.modal:exit()
  end
  return self
end

--- Force update visuals (call after programmatic window move)
function M:updateVisuals()
  if self.isOpen then
    self.visualManager:updateNow()
  end
  return self
end

--- Get the visual manager (for advanced usage)
function M:getVisualManager()
  return self.visualManager
end

--- Destroy this modality
function M:destroy()
  self:exit()
  self.visualManager:detach()
  M._registry[self.id] = nil
end

return M
