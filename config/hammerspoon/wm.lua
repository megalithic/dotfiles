local enum = req("hs.fnutils")
local utils = req("utils")

local obj = {}
obj.__index = obj
obj.name = "wm"
obj.debug = false

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
  local appLayout = LAYOUTS[app:bundleID()]
  if appLayout ~= nil then
    if appLayout.rules and #appLayout.rules > 0 then
      enum.each(appLayout.rules, function(rule)
        local winTitlePattern, screenNum, position = table.unpack(rule)

        winTitlePattern = (winTitlePattern ~= "") and winTitlePattern or nil
        local win = winTitlePattern == nil and app:mainWindow() or hs.window.find(winTitlePattern)

        if win == nil then
          local standardWindows = enum.filter(app:allWindows(), function(w) return w:isStandard() end)
          if standardWindows ~= nil or #standardWindows > 0 then
            warn(
              fmt(
                "[RUN] %s/layouts/%s (%s): specific window not found; using all standard windows for app.",
                obj.name,
                app:bundleID(),
                utils.eventString(event)
              )
            )
            enum.each(standardWindows, function(w)
              note(fmt([[[RUN] %s/layouts/%s/%s: "%s"]], obj.name, app:bundleID(), utils.eventString(event), w:title()))
              hs.grid.set(w, position, obj.targetDisplay(screenNum))
            end)
          end
        end
        if win ~= nil then
          note(
            fmt(
              [[[RUN] %s/layouts/%s/%s: "%s"]],
              obj.name,
              app:bundleID(),
              utils.eventString(event),
              app:focusedWindow():title()
            )
          )

          dbg(
            fmt(
              "[wm] rules/%s (%s): %s",
              type(elementOrAppName) == "string" and elementOrAppName or I(elementOrAppName),
              win:title(),
              I(appLayout.rules)
            ),
            obj.debug
          )

          hs.grid.set(win, position, obj.targetDisplay(screenNum))
        end
      end)
    end
  end
end

return obj
