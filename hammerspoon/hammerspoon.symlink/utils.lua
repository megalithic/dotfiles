-----------------------------------------------------------------------------------
--/ utils and helpers /--
-----------------------------------------------------------------------------------
local utils = {}
utils.log = hs.logger.new('replicant', 'debug') -- debug or info

local lastSeenChain = nil
local lastSeenWindow = nil

-- Chain the specified movement commands.
-- This is like the "chain" feature in Slate, but with a couple of enhancements:
--
--  - Chains always start on the screen the window is currently on.
--  - A chain will be reset after 2 seconds of inactivity, or on switching from
--    one chain to another, or on switching from one app to another, or from one
--    window to another.
--
utils.chain = function (movements)
  local chainResetInterval = 2 -- seconds
  local cycleLength = #movements
  local sequenceNumber = 1

  return function()
    local win = hs.window.frontmostWindow()
    local id = win:id()
    local now = hs.timer.secondsSinceEpoch()
    local screen = win:screen()

    if
      lastSeenChain ~= movements or
      lastSeenAt < now - chainResetInterval or
      lastSeenWindow ~= id
    then
      sequenceNumber = 1
      lastSeenChain = movements
    elseif (sequenceNumber == 1) then
      -- At end of chain, restart chain on next screen.
      screen = screen:next()
    end
    lastSeenAt = now
    lastSeenWindow = id

    hs.grid.set(win, movements[sequenceNumber], screen)
    sequenceNumber = sequenceNumber % cycleLength + 1
  end
end

-- TOGGLE the given app
utils.toggleApp = function (_app)
  -- accepts app name (lowercased), pid, or bundleID; but we ALWAYS use bundleID
  local app = hs.application.find(_app)

  if app ~= nil then
    utils.log.df('[launcher] event; attempting to toggle %s', app:bundleID())
  end

  if not app then
    -- FIXME: this may not be working properly.. creating extraneous PIDs?
    utils.log.df('[launcher] event; launchOrFocusByBundleID(%s) (not PID-managed app?)', _app)
    hs.application.launchOrFocusByBundleID(_app)
  else
    local mainWin = app:mainWindow()
    utils.log.df('[launcher] event; main window: %s', mainWin)
    if mainWin then
      if mainWin == hs.window.focusedWindow() then
        utils.log.df('[launcher] event; hiding %s', app:bundleID())
        mainWin:application():hide()
      else
        utils.log.df('[launcher] event; activating/unhiding/focusing %s', app:bundleID())
        mainWin:application():activate(true)
        mainWin:application():unhide()
        mainWin:focus()
      end
    else
      -- assumes there is no "mainWindow" for the application in question, probably iTerm2
      utils.log.df('[launcher] event; launchOrFocusByBundleID(%s)', app)
      if (app:focusedWindow() == hs.window.focusedWindow()) then
        app:hide()
      else
        app:unhide()
        hs.application.launchOrFocusByBundleID(app:bundleID())
      end
    end
  end
end

utils.handleMediaKeyEvents = function (event, alertText)
  hs.eventtap.event.newSystemKeyEvent(event, true):post()
  utils.log.df('[hotkeys] event; %s', event)

  if alertText then
    hs.alert.closeAll()
    -- hs.alert.show(alertText, 0.5)
    hs.timer.doAfter(0.5, function ()
      hs.alert.show(hs.spotify.getCurrentArtist() .. " - " .. hs.spotify.getCurrentTrack(), 1)
    end)
  end
end

utils.windowsForApp = function (app)
  return app:allWindows()
end

utils.validWindowsForApp = function (app)
  return app:allWindows()
end

utils.validWindowsForWindow = function (window)
  return utils.canManageWindow(window)
end

-- Returns the number of standard, non-minimized windows in the application.
--
-- (For Chrome, which has two windows per visible window on screen, but only one
-- window per minimized window).
utils.windowCount = function (app)
  local count = 0
  if app then
    for _, window in pairs(utils.windowsForApp(app)) do
      if utils.canManageWindow(window) and app:bundleID() ~= 'com.googlecode.iterm2' then
        count = count + 1
      end
    end
  end
  return count
end

-- hides an application
--
utils.hide = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:hide()
  end
end

-- activates/shows an application
--
utils.activate = function (bundleID)
  local app = hs.application.get(bundleID)
  if app then
    app:activate()
  end
end

-- determines if a window is manageable (takes into account iterm2)
--
utils.canManageWindow = function (window)
  local bundleID = window:application():bundleID()

  -- Special handling for iTerm: windows without title bars are
  -- non-standard.
  return window:isStandard() and not window:isMinimized() or
    bundleID == 'com.googlecode.iterm2'
end

-- creates a set for easier traversal and searching
-- - takes an array as a table, e.g. Set {'foo', 'bar'}
utils.Set = function (list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- acts like a switch/case statement
-- UNTESTED
utils.switch = function (c)
  local swtbl = {
    casevar = c,
    caseof = function (self, code)
      local f
      if (self.casevar) then
        f = code[self.casevar] or code.default
      else
        f = code.missing or code.default
      end
      if f then
        if type(f)=="function" then
          return f(self.casevar,self)
        else
          error("case "..tostring(self.casevar).." not a function")
        end
      end
    end
  }
  return swtbl
end

-- global utility functions

function tableKeys(t, sorted)
  local keys={}
  for k, v in pairs(t) do
    table.insert(keys, k)
  end
  return keys
end

keys = hs.stdlib and hs.stdlib.table.keys or tableKeys

function tableSet(t)
  local hash = {}
  local res = {}
  for _, v in ipairs(t) do
    if not hash[v] then
      res[#res + 1] = v
      hash[v] = true
    end
  end
  return res
end

function tableMerge(t1, t2)
  for k, v in pairs(t2) do
    t1[k] = v
  end
  return t1
end

function tableContains(t, key)
  for i, v in ipairs(t) do
    if v == key then return i end
  end
end

function tableSubrange(t, first, last)
  local sub = {}
  for i=first,last do
    sub[#sub + 1] = t[i]
  end
  return sub
end

function tableCompare(t1, t2)
  local t1Keys, t2Keys = tableKeys(t1), tableKeys(t2)
  if #t1Keys ~= #t2Keys then return false end
  for _, key in ipairs(t1Keys) do
    if t1[key] ~= t2[key] then return false end
  end
  return true
end

function queue(t, i) return table.insert(t, i) end

function dequeue(t) return table.remove(t, 1) end

function ppairs(t) for k,v in pairs(t) do print(k,v) end end

function hex(num) return string.format("%x", num) end

return utils
