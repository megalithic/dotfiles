local M = hs.hotkey.modal.new({}, nil)
local fmt = string.format

M.name = "hypemode"
M.isOpen = false
M.indicator = nil
M.indicatorColor = "#e39b7b"
M.delayedExitTimer = nil

function M.focusMainWindow(bundleID, opts)
  local app
  if bundleID == nil or bundleID == "" then
    app = hs.application.frontmostApplication()
  else
    app = hs.application.find(bundleID)
  end

  opts = opts or { h = 800, w = 800, focus = true }
  local win = hs.fnutils.find(
    app:allWindows(),
    function(win)
      return app:mainWindow() == win and win:isStandard() and win:frame().w >= opts.w and win:frame().h >= opts.h
    end
  )

  if win ~= nil and opts.focus then win:focus() end

  U.log.n(string.format("%s (%s)", app:bundleID(), app:mainWindow():title()))

  return win
end

function M.toggleIndicator(win, terminate)
  win = win or hs.window.focusedWindow()

  if M.indicator == nil and win ~= nil then
    local frame = win:frame()
    M.indicator = hs.canvas.new(frame):appendElements({
      type = "rectangle",
      action = "stroke",
      strokeWidth = 2.0,
      strokeColor = { hex = M.indicatorColor, alpha = 0.7 },
      roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
    })
  end

  if terminate then
    M.indicator:delete()
    M.indicator = nil
  else
    if M.indicator:isShowing() then
      M.indicator:hide()
    else
      M.indicator:show()
    end
  end

  return M.indicator
end

function M:entered()
  if M.customOnEntered ~= nil and type(M.customOnEntered) == "function" then
    M.customOnEntered(M.isOpen)
  else
    local win = M.focusMainWindow() or hs.window.focusedWindow()

    if win ~= nil then
      M.isOpen = true
      M.toggleIndicator(win)
      M.alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
        if screen == hs.screen.mainScreen() then
          local appTitle = win:application():title()
          local appImage = hs.image.imageFromAppBundle(win:application():bundleID())
          local text = fmt("◱ : %s", appTitle)

          M:delayedExit()
          if appImage ~= nil then
            text = fmt(": %s", appTitle)

            return hs.alert.showWithImage(text, appImage, nil, screen)
          end

          return hs.alert.show(text, hs.alert.defaultStyle, screen, true)
        end
      end)
    else
      M:exit()
    end
  end

  return self
end

function M:delayedExit(delay)
  delay = delay or 1

  if M.delayedExitTimer ~= nil then
    M.delayedExitTimer:stop()
    M.delayedExitTimer = nil
  end

  M.delayedExitTimer = hs.timer.doAfter(delay, function() M:exit() end)

  return self
end

function M:exited()
  M.isOpen = false
  if M.alertUuids ~= nil then
    hs.fnutils.ieach(M.alertUuids, function(uuid)
      if uuid ~= nil then hs.alert.closeSpecific(uuid) end
    end)
  end
  M.toggleIndicator(nil, true)

  if M.delayedExitTimer ~= nil then
    M.delayedExitTimer:stop()
    M.delayedExitTimer = nil
  end

  return self
end

function M:toggle()
  if M.isOpen then
    M:exit()
  else
    M:enter()
  end

  return self
end

function M:start(opts)
  opts = opts or { on_entered = nil }
  hs.window.animationDuration = 0
  M.customOnEntered = opts.on_entered

  M:bind("", "escape", function() M:exit() end)

  -- provide alternate escapes
  -- M:bind("ctrl", "[", function()
  --   M:exit()
  -- end):bind("", "escape", function()
  --   M:exit()
  -- end)
  -- M:bind("ctrl", "c", function()
  --   M:exit()
  -- end):bind("", "escape", function()
  --   M:exit()
  -- end)

  return self
end

return M
