--- wm.lua - Window management with visual tracking
---
--- Usage:
---   require("wm").init()
---   -- Then press hyper+l to enter WM mode

local M = {}
local fmt = string.format

local enum = require("hs.fnutils")
local hypemode = require("hypemode")
local chain = require("chain")

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

--- Check if a window title matches an exclusion pattern
local function isExcluded(title, pattern)
  if pattern:sub(1, 1) ~= "!" then return false end
  local excludeTerm = pattern:sub(2):lower()
  return (title or ""):lower():find(excludeTerm, 1, true) ~= nil
end

--- Check if a window should be excluded based on all exclusion rules
local function shouldExcludeWindow(title, rules)
  for _, rule in ipairs(rules) do
    local pattern = rule[1] or ""
    if pattern:sub(1, 1) == "!" and rule[3] == nil then
      if isExcluded(title, pattern) then return true end
    end
  end
  return false
end

--- Check if window title matches a positive pattern
local function matchesPattern(title, pattern)
  if pattern == "" or pattern == nil then return true end
  return (title or ""):lower():find(pattern:lower(), 1, true) ~= nil
end

local GRID_COLS = 60
local GRID_ROWS = 20

local function windowGap() return C.windowGap or 5 end

local function parseGridPosition(pos)
  if type(pos) == "table" then return pos end
  if type(pos) ~= "string" then return nil end

  local x, y, w, h = pos:match("^(%-?%d+),(%-?%d+)%s+(%d+)x(%d+)$")
  if not x then return nil end

  return {
    x = tonumber(x),
    y = tonumber(y),
    w = tonumber(w),
    h = tonumber(h),
  }
end

function M.frameForPosition(pos, screen)
  local grid = parseGridPosition(pos)
  if not grid then return nil end

  screen = screen or hs.screen.primaryScreen()
  local frame = screen:frame()
  local gap = windowGap()

  local x = frame.x + (frame.w * grid.x / GRID_COLS) + gap
  local y = frame.y + (frame.h * grid.y / GRID_ROWS) + gap
  local w = (frame.w * grid.w / GRID_COLS) - (gap * 2)
  local h = (frame.h * grid.h / GRID_ROWS) - (gap * 2)

  return {
    x = math.floor(x + 0.5),
    y = math.floor(y + 0.5),
    w = math.max(1, math.floor(w + 0.5)),
    h = math.max(1, math.floor(h + 0.5)),
  }
end

function M.targetDisplay(hint)
  local displays = hs.screen.allScreens() or {}
  if type(hint) == "number" then
    return displays[hint] or hs.screen.primaryScreen()
  else
    return hs.screen.find(hint)
  end
end

-- Per-window one-shot suppression of the next auto-layout pass.
-- Manual placements (M.place callers: tile, chain, hypemode bindings,
-- browser interop) seed this so the mainWindowChanged/windowCreated event
-- triggered by setFrame doesn't immediately stomp the manual layout.
-- TTL guards against stale entries when no event fires.
M._suppressed = {} -- [winId] = expiryEpochSeconds
M._suppressTTL = 1.0

local function winId(win)
  if not win then return nil end
  local ok, id = pcall(function() return win:id() end)
  if ok then return id end
  return nil
end

function M.suppressNextLayout(win, ttl)
  local id = winId(win)
  if not id then return end
  M._suppressed[id] = hs.timer.secondsSinceEpoch() + (ttl or M._suppressTTL)
end

function M.consumeSuppression(win)
  local id = winId(win)
  if not id then return false end
  local exp = M._suppressed[id]
  if not exp then return false end
  M._suppressed[id] = nil
  return exp > hs.timer.secondsSinceEpoch()
end

function M._placeRaw(pos, screen, win)
  win = win or hs.window.frontmostWindow()
  if not win then return nil end

  screen = screen or win:screen()
  if type(screen) ~= "userdata" then screen = M.targetDisplay(screen) end
  if not screen then return nil end

  local frame = M.frameForPosition(pos, screen)
  if not frame then return nil end

  win:setFrame(frame, 0)
  return win
end

-- Manual placement entry point: places the window and suppresses the next
-- auto-layout pass for it. Use M._placeRaw from auto-layout code paths
-- (placeApp) so they don't suppress themselves.
function M.place(pos, screen, win)
  local placed = M._placeRaw(pos, screen, win)
  if placed then M.suppressNextLayout(placed) end
  return placed
end

function M.nextScreen(win)
  win = win or hs.window.frontmostWindow()
  if not win then return nil end
  return win:screen():next()
end

function M.prevScreen(win)
  win = win or hs.window.frontmostWindow()
  if not win then return nil end
  return win:screen():previous()
end

function M.toNextScreen()
  local win = hs.window.frontmostWindow()
  if not win then return nil end
  return win:moveToScreen(M.nextScreen(win))
end

function M.toPrevScreen()
  local win = hs.window.frontmostWindow()
  if not win then return nil end
  return win:moveToScreen(M.prevScreen(win))
end

function M.tile()
  local windows = enum.map(hs.window.orderedWindows(), function(win)
    local app = win and win:application()
    if win and app and win ~= hs.window.focusedWindow() and win:isStandard() then
      return {
        text = win:title(),
        subText = app:title(),
        image = hs.image.imageFromAppBundle(app:bundleID()),
        id = win:id(),
      }
    end
  end)

  local chooser = hs.chooser.new(function(choice)
    if choice ~= nil then
      local focused = hs.window.focusedWindow()
      local alt = hs.window.find(choice.id)
      if not focused or not alt then return end
      local screen = focused:screen()
      if hs.eventtap.checkKeyboardModifiers()["shift"] then
        hs.alert.show("  70 󱪳 30  ")
        M.place("0,0 42x20", screen, focused)
        M.place("42,0 18x20", screen, alt)
      else
        hs.alert.show("  50 󱪳 50  ")
        M.place(C.grid.halves.left, screen, focused)
        M.place(C.grid.halves.right, screen, alt)
      end
      alt:raise()
    end
  end)

  chooser
    :placeholderText("Choose window for 50/50 split. Hold ⇧ for 70/30.")
    :searchSubText(true)
    :choices(windows)
    :show()
end

function M.placeAllApps()
  local apps = enum.filter(hs.application.runningApplications(), function(app) return app:title() ~= "Hammerspoon" end)
  enum.each(apps, function(app) M.placeApp("relayout", app) end)
  hs.notify.new({ title = "hammerspork", subTitle = "layout reflow complete." }):send()
end

function M.placeApp(event, app)
  local utils = require("utils")
  local appLayout = C.layouts[app:bundleID()]
  if not (appLayout and appLayout.rules and #appLayout.rules > 0) then return end
  local rules = appLayout.rules

  -- Partition rules: specific (named title) win over catch-all (nil/"").
  -- First catch-all with a position wins. Exclusion-only rules ("!foo")
  -- are consulted by shouldExcludeWindow.
  local specificRules, catchAll = {}, nil
  for _, rule in ipairs(rules) do
    local pattern, _, position = rule[1], rule[2], rule[3]
    pattern = pattern or ""
    if pattern == "" then
      if position ~= nil and catchAll == nil then catchAll = rule end
    elseif pattern:sub(1, 1) ~= "!" then
      table.insert(specificRules, rule)
    end
  end

  enum.each(app:allWindows(), function(w)
    if not (w and w:isStandard()) then return end
    local title = w:title() or ""
    if shouldExcludeWindow(title, rules) then return end

    local matched
    for _, rule in ipairs(specificRules) do
      if matchesPattern(title, rule[1]) then
        matched = rule
        break
      end
    end
    matched = matched or catchAll
    if not matched then return end

    if M.consumeSuppression(w) then
      U.log.df("wm/layouts/%s: skip (suppressed) %q", app:bundleID(), title)
      return
    end

    local _, screenNum, position = table.unpack(matched)
    U.log.n(fmt([[[RUN] wm/layouts/%s/%s: "%s"]], app:bundleID(), utils.eventString(event), title))
    M._placeRaw(position, M.targetDisplay(screenNum), w)
  end)
end

--------------------------------------------------------------------------------
-- MODAL INITIALIZATION
--------------------------------------------------------------------------------

function M.init()
  U.log.i("wm: Initializing")

  local chainExitDelay = 1.25

  -- Create WM modality with all visual features
  local wmModality = hypemode.new("wm", {
    showAlert = true,
    alertPosition = "center",
    showIndicator = true, -- Border around window
    indicatorColor = "#e39b7b", -- Warm orange
    dimWindow = 0.4, -- 40% dim (lighter than before)
    autoExit = 2.0, -- Auto-exit after 2s of inactivity
  })

  -- Pre-create chain closures for Shift+H/L so they maintain state across calls
  local shiftHChain = chain(
    enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
      if type(C.grid[size]) == "string" then return C.grid[size] end
      return C.grid[size]["left"]
    end),
    wmModality,
    chainExitDelay
  )
  local shiftLChain = chain(
    enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
      if type(C.grid[size]) == "string" then return C.grid[size] end
      return C.grid[size]["right"]
    end),
    wmModality,
    chainExitDelay
  )

  wmModality
    :start()
    -- Note: escape binding provided by :start()
    -- Space: cycle through centered sizes
    :bind(
      {},
      "space",
      chain({
        C.grid.full,
        C.grid.center.large,
        C.grid.center.medium,
        C.grid.center.small,
        C.grid.center.tiny,
        C.grid.center.mini,
        C.grid.preview,
      }, wmModality, chainExitDelay)
    ) -- chainExitDelay before auto-exit
    -- Return: fullscreen
    :bind({}, "return", function()
      M.place(C.grid.full)
      wmModality:updateVisuals()
    end, function() wmModality:exit(0.3) end)
    -- Shift+Return: fullscreen on next screen
    :bind({ "shift" }, "return", function()
      M.place(C.grid.full, M.nextScreen())
      wmModality:updateVisuals()
    end, function() wmModality:exit(0.3) end)
    -- H: left side sizes
    :bind(
      {},
      "h",
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["left"]
        end),
        wmModality,
        chainExitDelay
      )
    )
    -- L: right side sizes
    :bind(
      {},
      "l",
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["right"]
        end),
        wmModality,
        chainExitDelay
      )
    )
    -- Shift+H: prev screen + left (uses pre-created chain)
    :bind({ "shift" }, "h", function()
      local screen = M.prevScreen()
      shiftHChain(screen)
    end)
    -- Shift+L: next screen + right (uses pre-created chain)
    :bind({ "shift" }, "l", function()
      local screen = M.nextScreen()
      shiftLChain(screen)
    end)
    -- J: center large
    :bind({}, "j", function()
      M.place(C.grid.center.large)
      wmModality:updateVisuals()
    end, function() wmModality:exit(0.3) end)
    -- K: center medium
    :bind({}, "k", function()
      M.place(C.grid.center.medium)
      wmModality:updateVisuals()
    end, function() wmModality:exit(0.3) end)
    -- V: tile (split with another window)
    :bind({}, "v", function()
      M.tile()
      wmModality:exit()
    end)
    -- R: reflow all windows
    :bind({}, "r", function()
      M.placeAllApps()
      wmModality:exit()
    end)
    -- S: split active browser tab to new window, tile both halves
    :bind({}, "s", function()
      req("lib.interop.browser"):splitTab(false)
      wmModality:exit()
    end)
    -- Shift+S: split active browser tab to next screen (full)
    :bind({ "shift" }, "s", function()
      req("lib.interop.browser"):splitTab(true)
      wmModality:exit()
    end)

  -- Bind to hyper+l for WM mode
  req("hyper", { id = "wm" }):bind({}, "l", function() wmModality:toggle() end)

  U.log.i("wm: initialized (hyper+l to activate)")

  return wmModality
end

return M
