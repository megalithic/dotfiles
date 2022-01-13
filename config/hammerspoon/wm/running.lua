-- HT: @folke
--

-- local spaces = require("hs._asm.undocumented.spaces")

local log = hs.logger.new("[wm.run]", "info")
local appw = hs.application.watcher
local M = { apps = {}, observers = {}, windows = {} }

M.appEvents = {
  [appw.activated] = "activated",
  [appw.deactivated] = "deactivated",
  [appw.hidden] = "hidden",
  [appw.launched] = "launched",
  [appw.launching] = "launching",
  [appw.terminated] = "terminated",
  [appw.unhidden] = "unhidden",
}

M.events = {
  focused = "focused",
  framed = "framed",
  closed = "closed",
  created = "created",
  hidden = "hidden",
  launched = "launched",
  terminated = "terminated",
}

M.getWindowsPerSpace = function()
  local ret = {}
  for _, windows in pairs(M.windows) do
    for _, ax in pairs(windows) do
      if ax:isValid() then
        local win = ax:asHSWindow()
        for _, space in pairs(win:spaces()) do
          if ret[space] == nil then
            ret[space] = {}
          end
          ret[space][win:id()] = win
        end
      end
    end
  end
  return ret
end

---@return hs.window[]
M.getWindows = function()
  -- local mySpace = desktop.activeSpace()
  local ret = {}
  for _, windows in pairs(M.windows) do
    for _, ax in pairs(windows) do
      if ax:isValid() then
        local win = ax:asHSWindow()
        local keep = true
        if keep then
          table.insert(ret, win)
        end
      end
    end
  end
  return ret
end

M._addAppWindow = function(app, ax)
  if ax ~= nil and ax.AXSubrole == "AXStandardWindow" then
    local pid = app:pid()
    if M.windows[pid] == nil then
      M.windows[pid] = {}
    end
    local win = ax:asHSWindow()
    if win and not M.windows[pid][win:id()] then
      M.windows[pid][win:id()] = ax
      M.triggerChange(app, win, M.events.created)
    end
  end
end

M._updateAppWindows = function(app, ax)
  if M.windows[app:pid()] == nil then
    M.windows[app:pid()] = {}
  end
  if ax.AXChildren then
    if ax == nil or ax.AXChildren == nil then
      return
    end

    -- 2022-01-05 11:09:35:          [ctx.zoom]: > context:zoom.us (focused)
    -- 2022-01-05 11:09:37: 11:09:37 ERROR:   LuaSkin: hs.axuielement.observer:callback error:attempt to index a nil value
    -- stack traceback:
    --   [C]: in for iterator 'for iterator'
    --   /Users/seth/.config/hammerspoon/wm/running.lua:89: in function 'wm.running._updateAppWindows'
    --   /Users/seth/.config/hammerspoon/wm/running.lua:166: in function </Users/seth/.config/hammerspoon/wm/running.lua:163>
    -- 2022-01-05 11:09:37:            [wm.run]: ->> focused:Brave Browser -- Name.com - Domain Name Registration - Brave
    -- 2022-01-05 11:09:37:            [wm.run]: ->> hidden:
    -- 2022-01-05 11:09:37:            [wm.run]: ->> terminated:zoom.us
    -- 2022-01-05 11:09:37:          [ctx.zoom]: > context:zoom.us (terminated)

    for _, child in ipairs(ax.AXChildren) do
      -- log.f("app is %s", hs.inspect(app))
      -- log.f("child is %s", hs.inspect(child))

      if child ~= nil and child:matchesCriteria("AXWindow") then
        M._addAppWindow(app, child)
      end
    end
  end

  M._addAppWindow(app, ax.AXMainWindow)
  M._addAppWindow(app, ax.AXFocusedWindow)

  for elId, el in pairs(M.windows[app:pid()]) do
    if not el:isValid() then
      M.windows[app:pid()][elId] = nil
      M.triggerChange(app, nil, M.events.closed)
    end
  end
end

M.triggerChange = function(app, win, event)
  local winTitle = ""
  local sep = ""
  local appName = ""

  if win then
    sep = " -- "
    winTitle = win:title()
  end

  if app ~= nil and app:name() ~= nil then
    appName = app:name()
  end

  log.f("->> %s:%s%s%s", event, appName, sep, winTitle)
  for _, fn in ipairs(M._listeners) do
    fn(app, win, event)
    -- hs.timer.doAfter(.01, function() fn(app, win, event) end)
  end
end

M._listeners = {}
M.onChange = function(fn)
  table.insert(M._listeners, fn)
  local win = hs.window.focusedWindow()
  if win ~= nil then
    fn(win:application(), win, M.events.focused)
  end
end

---@param app hs.application
M._watchApp = function(app, force)
  if M.apps[app:pid()] ~= nil then
    return
  end
  local ax = hs.axuielement.applicationElement(app)
  -- when the app just launched, we might have to wait for
  -- the next event to setup the observers
  if ax:isValid() then
    log.f("## watching: " .. app:name())
    M.apps[app:pid()] = app
    M._updateAppWindows(app, ax)
    ---@type hs.axuielement.observer
    local w = hs.axuielement.observer.new(app:pid())
    local addWatcher = function(notif)
      w:addWatcher(ax, notif)
    end
    pcall(addWatcher, "AXFocusedWindowChanged")
    pcall(addWatcher, "AXMainWindowChanged")
    pcall(addWatcher, "AXWindow")
    -- pcall(addWatcher, "AXResized")
    -- pcall(addWatcher, "AXMoved")
    pcall(addWatcher, "AXUIElementDestroyed")

    -- w:addWatcher(ax, "AXUIElementDestroyed")
    w:callback(function(_, axel, notif, _notifData)
      if notif == "AXUIElementDestroyed" then
        if not app:focusedWindow() then
          M._updateAppWindows(app, ax)
        end
        return
      end

      if not axel:matchesCriteria("AXWindow") then
        return
      end

      if type(notif) == "string" then
        log.f("- axui:" .. notif)
      else
        log.f(hs.inspect(notif))
      end

      local win = axel:asHSWindow()
      -- check for all focus changes, or only for the condition below?
      -- and app:kind() > 0
      if notif == "AXFocusedWindowChanged" then
        M._updateAppWindows(app, ax)
        M.triggerChange(app, win, M.events.focused)
      elseif notif == "AXResized" or notif == "AXMoved" then
        M.triggerChange(app, win, M.events.framed)
      end
    end)
    w:start()
    M.observers[app:pid()] = w
  end
end

M._updateRunning = function()
  for _, app in ipairs(hs.application.runningApplications()) do
    M._watchApp(app)
  end
end

M.switcher = function()
  if M._chooser == nil then
    M._chooser = hs.chooser.new(function(choice)
      if choice ~= nil then
        choice.win:focus()
      end
    end):bgDark(true):placeholderText("Switch to Window"):searchSubText(true)
  elseif M._chooser:isVisible() then
    M._chooser:hide()
    return
  end
  local windows = hs.fnutils.map(M.getWindows(), function(win)
    local ret = {
      text = win:title(),
      subText = win:application():title(),
      win = win,
    }
    if win:application():bundleID() then
      ret.image = hs.image.imageFromAppBundle(win:application():bundleID())
    end
    return ret
  end)
  M._chooser:choices(windows):show()
end

M._appWatcher = appw.new(function(appName, event, app)
  if appName == nil then
    appName = ""
  end

  if event == appw.launching then
    return
  end

  if event == appw.terminated then
    local terminated_app = M.apps[app:pid()]

    M.apps[app:pid()] = nil
    if M.observers[app:pid()] ~= nil then
      M.observers[app:pid()]:stop()
      M.observers[app:pid()] = nil
      M.triggerChange(terminated_app, terminated_app:mainWindow(), M.events.terminated)
    end
    return
  end

  if event == appw.launched or TriggerChangeForced then
    local win = app:focusedWindow() or app:mainWindow()
    M.triggerChange(app, win, M.events.launched)
  end

  if M.apps[app:pid()] == nil then
    M._watchApp(app)
  end

  if event == appw.activated or TriggerChangeForced then
    local win = app:focusedWindow()
    if win ~= nil then
      M.triggerChange(app, win, M.events.focused)
    end
  end

  if event == appw.hidden or event == appw.deactivated then
    M.triggerChange(app, app:mainWindow(), M.events.hidden)
  end
end)

M.addToAppWatcher = function(app, force)
  M._watchApp(app, force)
end

M.start = function()
  M._appWatcher:start()
end

return M
