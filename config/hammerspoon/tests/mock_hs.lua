-- Mock Hammerspoon runtime for lifecycle tests.
-- Build a fresh mock per test: local mock = require("tests.mock_hs").new()
-- The mock installs globals (hs, U, C, req, HYPER, P) and exposes a virtual
-- clock: mock.advance(seconds) fires due timers deterministically.

local M = {}

local function shallowCopy(t)
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

function M.new()
  local mock = {}

  --------------------------------------------------------------------------
  -- Virtual clock + timers
  --------------------------------------------------------------------------
  mock.now = 0
  mock.timers = {} -- array of { at, fn, interval|nil, stopped }

  local function schedule(delay, fn, interval)
    local t = { at = mock.now + delay, fn = fn, interval = interval, stopped = false }
    function t:stop()
      self.stopped = true
      return self
    end
    function t:start() return self end
    function t:running() return not self.stopped end
    table.insert(mock.timers, t)
    return t
  end

  function mock.pendingTimers()
    local n = 0
    for _, t in ipairs(mock.timers) do
      if not t.stopped and t.at ~= nil then n = n + 1 end
    end
    return n
  end

  function mock.advance(seconds)
    local target = mock.now + seconds
    while true do
      -- find earliest due timer
      local nextTimer, nextIdx
      for idx, t in ipairs(mock.timers) do
        if not t.stopped and t.at <= target then
          if not nextTimer or t.at < nextTimer.at then
            nextTimer, nextIdx = t, idx
          end
        end
      end
      if not nextTimer then break end

      mock.now = nextTimer.at
      if nextTimer.interval then
        nextTimer.at = nextTimer.at + nextTimer.interval
      else
        nextTimer.stopped = true
        table.remove(mock.timers, nextIdx)
      end
      nextTimer.fn()
    end
    mock.now = target
  end

  --------------------------------------------------------------------------
  -- Fake applications
  --------------------------------------------------------------------------
  mock.apps = {} -- pid -> app
  mock.frontmost = nil
  mock.keystrokes = {}
  mock.launched = {}

  local nextPid = 1000

  function mock.makeApp(opts)
    opts = opts or {}
    nextPid = nextPid + 1
    local app = {
      _pid = opts.pid or nextPid,
      _bundleID = opts.bundleID,
      _name = opts.name or opts.bundleID or "app",
      _dead = false,
      _windows = opts.windows or {},
      _hidden = false,
      watchers = {},
    }
    function app:pid() return self._pid end
    function app:bundleID()
      if self._dead then return nil end
      return self._bundleID
    end
    function app:name()
      if self._dead then error("attempt to use a dead app") end
      return self._name
    end
    function app:isRunning() return not self._dead end
    function app:isFrontmost() return mock.frontmost == self end
    function app:allWindows() return self._windows end
    function app:mainWindow() return self._windows[1] end
    function app:focusedWindow() return self._windows[1] end
    function app:hide() self._hidden = true end
    function app:unhide() self._hidden = false end
    function app:activate() mock.frontmost = self end
    function app:kill() self._dead = true end
    function app:kill9() self._dead = true end
    function app:newWatcher(fn, userData)
      if self._dead then return nil end
      local w = {
        started = false,
        stopped = false,
        events = nil,
        _fn = fn,
        _userData = userData,
        _app = self,
      }
      function w:start(events)
        self.started = true
        self.events = events
        return self
      end
      function w:stop()
        self.stopped = true
        self.started = false
        return self
      end
      function w:element() return self._app end
      -- test helper: emit a uielement event through the callback
      function w:emit(element, event) self._fn(element, event, self, self._userData) end
      table.insert(self.watchers, w)
      return w
    end
    mock.apps[app._pid] = app
    return app
  end

  --------------------------------------------------------------------------
  -- hs table
  --------------------------------------------------------------------------
  local appWatcherConstants = {
    launching = 0,
    launched = 1,
    terminated = 2,
    hidden = 3,
    unhidden = 4,
    activated = 5,
    deactivated = 6,
  }

  mock.appWatchers = {} -- created hs.application.watcher instances
  mock.hotkeys = {} -- hs.hotkey.bind results
  mock.modals = {} -- hs.hotkey.modal.new results
  mock.alerts = {}

  local hs = {}

  hs.application = {
    watcher = shallowCopy(appWatcherConstants),
    frontmostApplication = function() return mock.frontmost end,
    get = function(hint)
      for _, app in pairs(mock.apps) do
        if not app._dead and (app._bundleID == hint or app._name == hint or app._pid == hint) then return app end
      end
      return nil
    end,
    find = function(hint) return hs.application.get(hint) end,
    launchOrFocusByBundleID = function(bundleID) table.insert(mock.launched, bundleID) end,
    launchOrFocus = function(name) table.insert(mock.launched, name) end,
    runningApplications = function()
      local out = {}
      for _, app in pairs(mock.apps) do
        if not app._dead then table.insert(out, app) end
      end
      return out
    end,
  }
  hs.application.watcher.new = function(fn)
    local w = { _fn = fn, started = false }
    function w:start()
      self.started = true
      return self
    end
    function w:stop()
      self.started = false
      return self
    end
    -- test helper: emit an application-level event
    function w:emit(appName, event, appObj)
      if self.started then self._fn(appName, event, appObj) end
    end
    table.insert(mock.appWatchers, w)
    return w
  end

  hs.uielement = {
    watcher = {
      applicationActivated = "AXApplicationActivated",
      applicationDeactivated = "AXApplicationDeactivated",
      applicationHidden = "AXApplicationHidden",
      applicationShown = "AXApplicationShown",
      mainWindowChanged = "AXMainWindowChanged",
      focusedWindowChanged = "AXFocusedWindowChanged",
      focusedElementChanged = "AXFocusedUIElementChanged",
      windowCreated = "AXWindowCreated",
      windowMoved = "AXWindowMoved",
      windowResized = "AXWindowResized",
      windowMinimized = "AXWindowMiniaturized",
      windowUnminimized = "AXWindowDeminiaturized",
      elementDestroyed = "AXUIElementDestroyed",
      titleChanged = "AXTitleChanged",
    },
  }

  hs.timer = {
    doAfter = function(delay, fn) return schedule(delay, fn) end,
    doEvery = function(interval, fn) return schedule(interval, fn, interval) end,
    secondsSinceEpoch = function() return mock.now end,
    absoluteTime = function() return mock.now * 1e9 end,
    waitWhile = function(predicate, action, interval)
      interval = interval or 1
      local t
      local function tick()
        if not predicate() then
          t:stop()
          action(t)
        end
      end
      t = schedule(interval, tick, interval)
      return t
    end,
    waitUntil = function(predicate, action, interval)
      return hs.timer.waitWhile(function() return not predicate() end, action, interval)
    end,
  }

  hs.hotkey = {
    bind = function(mods, key, pressed, released)
      local hk = { mods = mods, key = key, pressed = pressed, released = released, deleted = false }
      function hk:delete() self.deleted = true end
      function hk:enable() return self end
      function hk:disable() return self end
      table.insert(mock.hotkeys, hk)
      return hk
    end,
  }
  hs.hotkey.modal = {
    new = function()
      local modal = { binds = {}, active = false, deleted = false }
      function modal:bind(mods, key, pressedOrNil, releasedOrNil, repeatOrNil)
        table.insert(self.binds, { mods = mods, key = key, pressed = pressedOrNil, released = releasedOrNil })
        return self
      end
      function modal:enter()
        self.active = true
        if self.entered then self:entered() end
        return self
      end
      function modal:exit()
        self.active = false
        if self.exited then self:exited() end
        return self
      end
      function modal:delete() self.deleted = true end
      table.insert(mock.modals, modal)
      return modal
    end,
  }

  hs.eventtap = {
    keyStroke = function(mods, key) table.insert(mock.keystrokes, { mods = mods, key = key }) end,
    keyStrokes = function(text) table.insert(mock.keystrokes, { text = text }) end,
    checkKeyboardModifiers = function() return {} end,
  }

  hs.alert = {
    show = function(msg) table.insert(mock.alerts, msg) end,
    closeAll = function() end,
  }

  hs.fnutils = {
    contains = function(t, v)
      for _, x in pairs(t) do
        if x == v then return true end
      end
      return false
    end,
    each = function(t, fn)
      for _, x in pairs(t) do
        fn(x)
      end
    end,
    find = function(t, fn)
      for _, x in pairs(t) do
        if fn(x) then return x end
      end
      return nil
    end,
    filter = function(t, fn)
      local out = {}
      for _, x in pairs(t) do
        if fn(x) then table.insert(out, x) end
      end
      return out
    end,
    map = function(t, fn)
      local out = {}
      for _, x in pairs(t) do
        local v = fn(x)
        if v ~= nil then table.insert(out, v) end
      end
      return out
    end,
  }

  hs.fs = {
    dir = function(path)
      local p = io.popen("ls -1 '" .. path .. "' 2>/dev/null")
      local files = {}
      if p then
        for line in p:lines() do
          table.insert(files, line)
        end
        p:close()
      end
      local i = 0
      return function()
        i = i + 1
        return files[i]
      end, nil
    end,
    attributes = function() return nil end,
  }

  hs.inspect = function(v) return tostring(v) end
  hs.console = { printStyledtext = function() end }
  hs.json = { decode = function() return nil end, encode = function() return "{}" end }
  hs.urlevent = { openURL = function() end, bind = function() end }
  hs.window = {
    focusedWindow = function() return mock.frontmost and mock.frontmost:focusedWindow() or nil end,
    frontmostWindow = function() return mock.frontmost and mock.frontmost:focusedWindow() or nil end,
    switcher = { nextWindow = function() end },
    animationDuration = 0,
  }
  hs.canvas = {
    new = function()
      local c = {}
      local function chain() return c end
      setmetatable(c, { __index = function() return chain end })
      return c
    end,
    windowLevels = { floating = 5 },
    windowBehaviors = { transient = 1 },
  }
  hs.image = { imageFromAppBundle = function() return nil end }

  --------------------------------------------------------------------------
  -- Globals expected by the modules under test
  --------------------------------------------------------------------------
  local noop = function() end
  local logStub = setmetatable({}, { __index = function() return noop end })

  mock.hs = hs

  function mock.install()
    _G.hs = hs
    _G.HYPER = "F19"
    _G.P = noop
    _G.C = _G.C or { lollygaggers = {}, quitters = {}, layouts = {} }
    _G.U = _G.U
      or setmetatable({
        log = logStub,
        logFor = function() return logStub end,
        tlen = function(t)
          local n = 0
          for _ in pairs(t or {}) do
            n = n + 1
          end
          return n
        end,
        eventString = function(e) return type(e) == "string" and e or tostring(e) end,
        resourcePath = function() return "./contexts/" end,
      }, { __index = function() return noop end })
    _G.req = function(mod, ...)
      if mod == "hs.fnutils" then return hs.fnutils end
      if mod == "hs.styledtext" then return { new = function(s) return s end } end
      local ok, loaded = pcall(require, mod)
      if not ok then error(loaded) end
      -- Mirror init.lua's req(): run the module's init when present.
      if type(loaded) == "table" and type(loaded.init) == "function" then loaded:init(...) end
      return loaded
    end
    package.preload["hs.styledtext"] = function() return { new = function(s) return s end } end
    return mock
  end

  return mock
end

return M
