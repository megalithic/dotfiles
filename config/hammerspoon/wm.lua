local fmt = string.format
local enum = req("hs.fnutils")
local utils = req("utils")

local obj = {}
obj.__index = obj
obj.name = "wm"

--- Check if a window title matches an exclusion pattern
--- Exclusion patterns start with "!" and match if title contains the rest
---@param title string Window title to test
---@param pattern string Pattern starting with "!"
---@return boolean excluded True if window should be excluded
local function isExcluded(title, pattern)
  if pattern:sub(1, 1) ~= "!" then return false end
  local excludeTerm = pattern:sub(2):lower()
  return (title or ""):lower():find(excludeTerm, 1, true) ~= nil
end

--- Check if a window should be excluded based on all exclusion rules
---@param title string Window title
---@param rules table[] Layout rules array
---@return boolean excluded True if any exclusion rule matches
local function shouldExcludeWindow(title, rules)
  for _, rule in ipairs(rules) do
    local pattern = rule[1] or ""
    -- Exclusion rule: pattern starts with "!" and has no position (or nil position)
    if pattern:sub(1, 1) == "!" and rule[3] == nil then
      if isExcluded(title, pattern) then
        return true
      end
    end
  end
  return false
end

--- Check if window title matches a positive pattern (non-exclusion)
---@param title string Window title
---@param pattern string Pattern to match (case-insensitive contains)
---@return boolean matched
local function matchesPattern(title, pattern)
  if pattern == "" or pattern == nil then return true end
  return (title or ""):lower():find(pattern:lower(), 1, true) ~= nil
end

function obj.focusMainWindow(bundleID, opts)
  local app
  if bundleID == nil and bundleID == "" then
    app = hs.application.frontmostApplication()
  else
    app = hs.application.find(bundleID)
  end

  opts = opts or { h = 800, w = 800 }
  local targetWin = hs.fnutils.find(
    app:allWindows(),
    function(win)
      return app:mainWindow() == win and win:isStandard() and win:frame().w > opts.w and win:frame().h > opts.h
    end
  )

  if targetWin ~= nil then targetWin:focus() end
end

function obj.targetDisplay(hint)
  local displays = hs.screen.allScreens() or {}

  if type(hint) == "number" then
    if displays[hint] ~= nil then
      return displays[hint]
    else
      return hs.screen.primaryScreen()
    end
  else
    return hs.screen.find(hint)
  end
end

obj.tile = function()
  -- local wf = hs.window.filter.default:getWindows(hs.window.filter.sortByFocusedLast)
  -- local windows = enum.map(wf, function(win)
  local windows = enum.map(hs.window.orderedWindows(), function(win)
    -- local windows = enum.map(hs.window.filter.default:getWindows(), function(win)
    -- local windows = enum.map(hs.window.filter.new():getWindows(), function(win)
    if win ~= nil and win ~= hs.window.focusedWindow() and win:isStandard() then
      return {
        text = win:title(),
        subText = win:application():title(),
        image = hs.image.imageFromAppBundle(win:application():bundleID()),
        id = win:id(),
      }
    end
  end)

  local chooser = hs.chooser.new(function(choice)
    if choice ~= nil then
      local focused = hs.window.focusedWindow()
      local alt = hs.window.find(choice.id)
      if hs.eventtap.checkKeyboardModifiers()["shift"] then
        hs.alert.show("  70 󱪳 30  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left70, 0, 0 },
          { nil, alt, focused:screen(), hs.layout.right30, 0, 0 },
        })
      else
        hs.alert.show("  50 󱪳 50  ")
        hs.layout.apply({
          { nil, focused, focused:screen(), hs.layout.left50, 0, 0 },
          { nil, alt, focused:screen(), hs.layout.right50, 0, 0 },
        })
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

obj.toNextScreen = function()
  local win = hs.window.frontmostWindow()
  local next = win:screen():next()
  win:moveToScreen(next)

  return win
end

obj.toPrevScreen = function()
  local win = hs.window.frontmostWindow()
  local prev = win:screen():previous()
  win:moveToScreen(prev)

  return win
end

obj.place = function(pos)
  local win = hs.window.frontmostWindow()

  hs.grid.set(win, pos)

  return win
end

obj.placeAllApps = function()
  local apps = enum.filter(hs.application.runningApplications(), function(app) return app:title() ~= "Hammerspoon" end)
  enum.each(apps, function(app) obj.placeApp(app:name(), "relayout", app) end)
  hs.notify.new({ title = "hammerspork", subTitle = "layout reflow complete." }):send()
end

obj.placeApp = function(elementOrAppName, event, app)
  local appLayout = C.layouts[app:bundleID()]
  if appLayout ~= nil then
    if appLayout.rules and #appLayout.rules > 0 then
      local rules = appLayout.rules

      enum.each(appLayout.rules, function(rule)
        local winTitlePattern, screenNum, position = table.unpack(rule)

        -- Treat nil pattern same as empty string (apply to all windows)
        winTitlePattern = winTitlePattern or ""

        -- Skip exclusion-only rules (they're checked via shouldExcludeWindow)
        -- Exclusion rules have pattern starting with "!" and no position
        if winTitlePattern:sub(1, 1) == "!" and position == nil then
          return -- skip this rule, it's just an exclusion marker
        end

        if winTitlePattern == "" then
          -- Empty pattern: apply to all standard windows NOT excluded
          local standardWindows = enum.filter(app:allWindows(), function(w)
            return w:isStandard() and not shouldExcludeWindow(w:title(), rules)
          end)
          if #standardWindows > 0 then
            enum.each(standardWindows, function(w)
              U.log.n(
                fmt([[[RUN] %s/layouts/%s/%s: "%s"]], obj.name, app:bundleID(), utils.eventString(event), w:title())
              )
              hs.grid.set(w, position, obj.targetDisplay(screenNum))
            end)
          end
        else
          -- Specific pattern: find matching window (also check exclusions)
          local win = hs.window.find(winTitlePattern)
          if win and matchesPattern(win:title(), winTitlePattern) and not shouldExcludeWindow(win:title(), rules) then
            U.log.n(
              fmt(
                [[[RUN] %s/layouts/%s/%s: "%s"]],
                obj.name,
                app:bundleID(),
                utils.eventString(event),
                win:title()
              )
            )
            hs.grid.set(win, position, obj.targetDisplay(screenNum))
          end
        end
      end)
    end
  end
end

return obj
