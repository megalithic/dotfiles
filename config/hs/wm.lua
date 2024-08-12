local enum = req("hs.fnutils")
local utils = req("utils")

local obj = {}
obj.__index = obj
obj.name = "wm"
obj.debug = false

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
  local windows = hs.fnutils.map(hs.window.filter.new():getWindows(), function(win)
    if win ~= hs.window.focusedWindow() then
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

obj.placeApp = function(elementOrAppName, event, appObj)
  local appLayout = LAYOUTS[appObj:bundleID()]
  if appLayout ~= nil then
    if appLayout.rules and #appLayout.rules > 0 then
      enum.each(appLayout.rules, function(rule)
        local winTitlePattern, screenNum, position = table.unpack(rule)

        winTitlePattern = (winTitlePattern ~= "") and winTitlePattern or nil
        local win = winTitlePattern == nil and appObj:mainWindow() or hs.window.find(winTitlePattern)

        if win == nil then
          warn(fmt("[wm] layouts/%s (%s): %s not found", appObj:bundleID(), utils.eventEnums(event), I(win)))
        end

        if win ~= nil then
          note(
            fmt("[wm] layouts/%s (%s): %s", appObj:bundleID(), utils.eventEnums(event), appObj:focusedWindow():title())
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
