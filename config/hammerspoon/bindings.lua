--- REFS:
--- https://github.com/NateEag/dotfiles/blob/master/src/.hammerspoon/init.lua#L505-L537

local M = {}

_G.Hypers = {}

local fmt = string.format
local wm = req("wm")
local summon = req("summon")
local chain = req("chain")
local enum = req("hs.fnutils")
local utils = require("utils")

function M.loadApps()
  local hyper = req("hyper", { id = "apps" }):start()
  enum.each(C.launchers, function(bindingTable)
    local bundleID, globalBind, localBinds, focusOnly = table.unpack(bindingTable)
    if globalBind ~= nil then
      local key = globalBind
      local mods = {}
      local pressCount = nil

      if type(key) == "table" then
        mods, key, pressCount = table.unpack(globalBind)
      end

      if string.match(bundleID, "noop") then
        hyper:bind(mods, key, function() end)
      else
        hyper:bind(mods, key, function()
          if focusOnly ~= nil and focusOnly then
            summon.focus(bundleID)
          else
            summon.toggle(bundleID)
          end
        end)
      end
    end

    if localBinds then
      enum.each(localBinds, function(binds)
        local mods = {}
        local key = binds

        if type(binds) == "table" and #binds == 2 and type(binds[1]) == "table" then
          mods, key = table.unpack(binds)
        end

        hyper:bindPassThrough(mods, key, bundleID)
      end)
    end
  end)
end

-- Generic meeting window finder
-- Searches for windows using U.app.isMeetingWindow for classification
local function findMeetingWindow(app)
  if not app then return nil end

  local windows = app:allWindows()

  -- Pass 1: Find a window confirmed as a meeting by isMeetingWindow
  for _, window in ipairs(windows) do
    if window:isStandard() then
      local isMeeting, _ = U.app.isMeetingWindow(app, window)
      if isMeeting == true then return window end
    end
  end

  -- Pass 2: For unknown windows, use size heuristic (large window on external screen = likely meeting)
  for _, window in ipairs(windows) do
    if window:isStandard() then
      local isMeeting, _ = U.app.isMeetingWindow(app, window)
      local windowScreen = window:screen()
      local screenName = windowScreen and windowScreen:name() or ""
      local isOnExternalScreen = screenName ~= C.displays.internal and screenName ~= ""
      if isMeeting ~= false and isOnExternalScreen then -- unknown or nil, not explicitly settings
        local frame = window:frame()
        if frame.w >= 2000 and frame.h >= 1400 then return window end
      end
    end
  end

  -- Pass 3: Fallback to any standard window
  for _, window in ipairs(windows) do
    if window:isStandard() then return window end
  end

  return nil
end

function M.loadMeeting()
  req("hyper", { id = "meeting" }):start():bind({}, "z", nil, function()
    -- Check native meeting apps in priority order
    local meetingApps = {
      "com.pop.pop.app", -- Pop
      "us.zoom.xos", -- Zoom
      "com.microsoft.teams2", -- Teams
    }

    -- Browser-based meeting URL patterns (regex patterns for JavaScript)
    -- Used by osascript JavaScript, supports standard regex syntax
    local meetingUrlPatterns = {
      "meet.google.com",
      "hangouts.google.com.call",
      "www.valant.io",
      "telehealth.px.athena.io",
      -- Add more patterns as needed (e.g., "teams.microsoft.com", "whereby.com")
    }

    local targetWindow = nil

    -- Check browser-based meetings as fallback
    local urlPattern = table.concat(meetingUrlPatterns, "|")
    if req("browser").hasTab(urlPattern) then
      req("browser").jump(urlPattern)
    else
      -- Find first running meeting app with a valid meeting window
      for _, bundleID in ipairs(meetingApps) do
        local app = hs.application.find(bundleID)
        if app then
          targetWindow = findMeetingWindow(app)
          if targetWindow then
            break -- Found a meeting window, stop searching
          end
        end
      end

      -- Focus the meeting window if found
      if targetWindow then
        targetWindow:focus()
      else
        -- No meeting found
        U.log.w("No active meeting window found")
      end
    end

    -- if hs.application.find("us.zoom.xos") then
    --   local prevWin = hs.window.focusedWindow()
    --   -- hs.application.launchOrFocusByBundleID("us.zoom.xos")
    --   local app = hs.application.find("us.zoom.xos")
    --   local targetWin = app:findWindow("Zoom Meeting")
    --   if targetWin and targetWin:isStandard() then
    --     targetWin:focus()
    --   else
    --     prevWin:focus()
    --   end
    -- -- elseif hs.application.find("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan") then
    -- --   hs.application.launchOrFocusByBundleID("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan")
    -- elseif hs.application.find("com.microsoft.teams2") then
    --   local prevWin = hs.window.focusedWindow()
    --   -- hs.application.launchOrFocusByBundleID("com.microsoft.teams2")
    --   local app = hs.application.find("com.microsoft.teams2")
    --   local targetWin = app:findWindow("Meeting|Launch Deck Standup")
    --   if targetWin then
    --     targetWin:focus()
    --   else
    --     prevWin:focus()
    --   end
    -- elseif hs.application.find("com.pop.pop.app") then
    --   -- wm.focusMainWindow("com.pop.pop.app")
    --
    --   -- hs.application.launchOrFocusByBundleID("com.pop.pop.app")
    --   local app = hs.application.find("com.pop.pop.app")
    --   local targetWin = enum.find(
    --     app:allWindows(),
    --     function(win)
    --       return app:mainWindow() == win and win:isStandard() and win:frame().w > 1000 and win:frame().h > 1000
    --     end
    --   )
    --
    --   if targetWin ~= nil then targetWin:focus() end
    -- elseif req("browser").hasTab("meet.google.com|hangouts.google.com.call|www.valant.io|telehealth.px.athena.io") then
    --   req("browser").jump("meet.google.com|hangouts.google.com.call|www.valant.io|telehealth.px.athena.io")
    -- else
    --   print(fmt("%s: no meeting targets to focus", "bindings.hyper.meeting"))
    --
    --   hs.application.frontmostApplication():activate()
    -- end
  end)
end

function M.loadFigma()
  req("hyper", { id = "figma" }):start():bind({ "shift" }, "f", nil, function()
    local focusedApp = hs.application.frontmostApplication()
    if hs.application.find("com.figma.Desktop") then
      hs.application.launchOrFocusByBundleID("com.figma.Desktop")
    elseif req("browser").hasTab("figma.com") then
      req("browser").jump("figma.com")
    else
      print(fmt("%s: neither figma.app, nor figma web are opened", "bindings.hyper.figma"))

      focusedApp:activate()
    end
  end)
end

function M.loadUtils()
  -- FIXME:
  -- Maybe use this? REF: https://github.com/jackieaskins/dotfiles/blob/main/hammerspoon/config/hotkeyStore.lua
  -- local utilsModality = req("modality"):start({ id = "config.utils", key = "r", mods = { "shift" } })
  -- utilsModality
  --   :bind({}, "r", function()
  --     hs.notify.new({ title = "hammerspork", subTitle = "config is reloading..." }):send()
  --     hs.reload()
  --   end, function() utilsModality:delayedExit(0.1) end)
  --   :bind({}, "l", req("wm").placeAllApps, function() utilsModality:delayedExit(0.1) end)
  --   -- WIP
  --   :bind({}, "b", function()
  --     local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
  --     if currentApp == lastApp then
  --       axbrowse.browse() -- try to continue from where we left off
  --     else
  --       lastApp = currentApp
  --       axbrowse.browse(currentApp) -- new app, so start over
  --     end
  --   end, function() utilsModality:delayedExit(0.1) end)
  --   -- WIP
  --   :bind({}, "h", utils.showAvailableHotkeys, function() utilsModality:delayedExit(0.1) end)

  local lastBrowsedApp
  req("hyper", { id = "config.utils" })
    :start()
    :bind({ "shift" }, "r", nil, function()
      hs.notify.new({ title = "hammerspork", subTitle = "config is reloading..." }):send()
      hs.reload()
    end)
    :bind({ "shift", "ctrl" }, "l", nil, req("wm").placeAllApps)
    -- focus daily notes; splitting it 30/70 with currently focused app window
    :bind(
      { "shift" },
      "o",
      nil,
      function() utils.tmux.focusDailyNote(true) end
    )
    -- focus daily note; window layout untouched
    :bind(
      { "ctrl" },
      "o",
      nil,
      function() utils.tmux.focusDailyNote() end
    )
    :bind({ "ctrl" }, "d", nil, function() utils.dnd() end)
    :bind({ "ctrl" }, "b", nil, function()
      local axb = require("axbrowse")
      local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
      if currentApp == lastBrowsedApp then
        axb.browse() -- try to continue from where we left off
      else
        lastBrowsedApp = currentApp
        axb.browse(currentApp) -- new app, so start over
      end
    end)
end

function M.loadWm()
  -- [ MODAL C.launchers ] ---------------------------------------------------------

  -- # wm/window management ---------------------------------------------------------

  -- local tiler = req("hyper", { id = "apps" }):start()
  -- tiler:bind({}, "v", function() require("wm").tile() end)

  -- local wmModality = spoon.HyperModal
  local wmModality = require("hypemode")
  wmModality
    :start()
    -- local wmModality = req("modality", { id = "wm", key = "l" }):start()
    -- wmModality
    :bind(
      {},
      "r",
      req("wm").placeAllApps,
      function() wmModality:exit(0.1) end
    )
    :bind({}, "escape", function() wmModality:exit() end)
    -- :bind({}, "space", function() wm.place(C.grid.preview) end, function() wmModality:exit(0.1) end)
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
      }, wmModality, 1.0)
    )
    :bind({}, "return", function() wm.place(C.grid.full) end, function() wmModality:exit(0.1) end)
    :bind({ "shift" }, "return", function()
      wm.toNextScreen()
      wm.place(C.grid.full)
    end, function() wmModality:exit() end)
    :bind(
      {},
      "h",
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["left"]
        end),
        wmModality,
        1.0
      )
    )
    :bind(
      {},
      "l",
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["right"]
        end),
        wmModality,
        1.0
      )
    )
    :bind({ "shift" }, "h", function()
      wm.toPrevScreen()
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["left"]
        end),
        wmModality,
        1.0
      )
    end)
    :bind({ "shift" }, "l", function()
      wm.toNextScreen()
      chain(
        enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
          if type(C.grid[size]) == "string" then return C.grid[size] end
          return C.grid[size]["right"]
        end),
        wmModality,
        1.0
      )
    end)
    -- :bind({}, "j", function() wm.toNextScreen() end, function() wmModality:delayedExit(0.1) end)
    :bind(
      {},
      "j",
      function() wm.place(C.grid.center.large) end,
      -- chain({
      --   C.grid.center.mini,
      --   C.grid.center.tiny,
      --   C.grid.center.small,
      --   C.grid.center.medium,
      --   C.grid.center.large,
      -- }, wmModality, 1.0)
      function() wmModality:exit() end
    )
    :bind(
      {},
      "k",
      function() wm.place(C.grid.center.medium) end,
      -- chain({
      --   C.grid.center.large,
      --   C.grid.center.medium,
      --   C.grid.center.small,
      --   C.grid.center.tiny,
      --   C.grid.center.mini,
      -- }, wmModality, 1.0)
      function() wmModality:exit() end
    )
    :bind({}, "v", function()
      require("wm").tile()
      wmModality:exit()
    end)
    :bind({}, "s", function()
      req("browser"):splitTab()
      wmModality:exit()
    end)
    :bind({ "shift" }, "s", function()
      req("browser"):splitTab(true)
      wmModality:exit()
    end)
    :bind({}, "m", function()
      local app = hs.application.frontmostApplication()
      local menuItemTable = { "Window", "Merge All Windows" }
      if app:findMenuItem(menuItemTable) then
        app:selectMenuItem(menuItemTable)
      else
        warn("Merge All Windows is unsupported for " .. app:bundleID())
      end

      wmModality:exit()
    end)
    :bind({}, "f", function()
      local focused = hs.window.focusedWindow()
      enum.map(focused:otherWindowsAllScreens(), function(win) win:application():hide() end)
      wmModality:exit()
    end)
    :bind({}, "c", function()
      local win = hs.window.focusedWindow()
      local screenWidth = win:screen():frame().w
      hs.window.focusedWindow():move(hs.geometry.rect(screenWidth / 2 - 300, 0, 600, 400))
      -- resizes to a small console window at the top middle

      wmModality:exit()
    end)
    :bind({}, "b", function()
      local wip = require("wip")
      wip.bowser()
    end)
  -- :bind({}, "b", function()
  --   hs.timer.doAfter(5, function()
  --     local focusedWindow = hs.window.focusedWindow()

  --     if focusedWindow then
  --       local axWindow = hs.axuielement.windowElement(focusedWindow)

  --       function printAXElements(element, indent)
  --         indent = indent or ""

  --         print(indent .. "Element: " .. tostring(element))

  --         local attributes = element:attributeNames()
  --         for _, attr in ipairs(attributes) do
  --           local value = element:attributeValue(attr)
  --           print(indent .. "  " .. attr .. ": " .. tostring(value))
  --         end

  --         local children = element:childElements()
  --         if children then
  --           for _, child in ipairs(children) do
  --             printAXElements(child, indent .. "  ")
  --           end
  --         end
  --       end

  --       print("AX Elements for Focused Window:")
  --       printAXElements(axWindow)
  --     else
  --       print("No focused window found.")
  --     end
  --   end)
  -- end)

  req("hyper", { id = "wm" }):bind({}, "l", function() wmModality:toggle() end)

  --[[]
req("hyper", { id = "wm" })
  :bind({ "ctrl", "shift" }, "r", req("wm").placeAllApps)
  -- :bind({}, "escape", function() wmModality:exit() end)
  -- :bind({}, "space", function() wm.place(C.grid.preview) end, function() wmModality:exit(0.1) end)
  :bind(
    { "ctrl" },
    "space",
    chain(
      {
        C.grid.full,
        C.grid.center.large,
        C.grid.center.medium,
        C.grid.center.small,
        C.grid.center.tiny,
        C.grid.center.mini,
        C.grid.preview,
      }
      -- wmModality, 1.0
    )
    -- function() wm.place(C.grid.preview) end
  )
  -- :bind({}, "return", function() wm.place(C.grid.full) end, function() wmModality:exit(0.1) end)
  :bind(
    { "ctrl" },
    "return",
    function() wm.place(C.grid.full) end
  )
  :bind({ "ctrl", "shift" }, "return", function()
    wm.toNextScreen()
    wm.place(C.grid.full)
    -- end, function() wmModality:exit() end)
  end)
  :bind(
    { "ctrl" },
    "l",
    -- function() wm.place(C.grid.halves.right) end,
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(C.grid[size]) == "string" then return C.grid[size] end
        return C.grid[size]["right"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- function() wmModality:exit() end
  )
  :bind({ "ctrl", "shift" }, "l", function()
    wm.toNextScreen()
    -- wm.place(C.grid.halves.right)
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(C.grid[size]) == "string" then return C.grid[size] end
        return C.grid[size]["right"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- end, function() wmModality:exit() end)
  end)
  :bind(
    { "ctrl" },
    "h",
    -- function() wm.place(C.grid.halves.left) end,
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(C.grid[size]) == "string" then return C.grid[size] end
        return C.grid[size]["left"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- function() wmModality:exit() end
  )
  :bind({ "shift" }, "h", function()
    wm.toPrevScreen()
    -- wm.place(C.grid.halves.left)
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(C.grid[size]) == "string" then return C.grid[size] end
        return C.grid[size]["left"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- end, function() wmModality:exit() end)
  end)
  -- :bind({}, "j", function() wm.toNextScreen() end, function() wmModality:delayedExit(0.1) end)
  -- :bind(
  --   {},
  --   "j",
  --   -- function() wm.place(C.grid.center.large) end,
  --   chain(
  --     {
  --       C.grid.center.mini,
  --       C.grid.center.tiny,
  --       C.grid.center.small,
  --       C.grid.center.medium,
  --       C.grid.center.large,
  --     }
  --     -- wmModality, 1.0
  --   )
  --   -- function() wmModality:exit() end
  -- )
  -- :bind(
  --   {},
  --   "k",
  --   function() wm.place(C.grid.center.large) end
  --   -- chain({
  --   --   C.grid.center.large,
  --   --   C.grid.center.medium,
  --   --   C.grid.center.small,
  --   --   C.grid.center.tiny,
  --   --   C.grid.center.mini,
  --   -- }, wmModality, 1.0)
  --   -- function() wmModality:exit() end
  -- )
  :bind(
    { "ctrl" },
    "v",
    function()
      wm.tile()
      -- wmModality:exit()
    end
  )
  :bind({ "ctrl" }, "s", function()
    req("browser"):splitTab()
    -- wmModality:exit()
  end)
  :bind({ "ctrl", "shift" }, "s", function()
    req("browser"):splitTab(true)
    -- wmModality:exit()
  end)
-- :bind({}, "m", function()
--   local app = hs.application.frontmostApplication()
--   local menuItemTable = { "Window", "Merge All Windows" }
--   if app:findMenuItem(menuItemTable) then
--     app:selectMenuItem(menuItemTable)
--   else
--     warn("Merge All Windows is unsupported for " .. app:bundleID())
--   end

--   wmModality:exit()
-- end)
-- :bind({}, "f", function()
--   local focused = hs.window.focusedWindow()
--   enum.map(focused:otherWindowsAllScreens(), function(win) win:application():hide() end)
--   wmModality:exit()
-- end)
-- :bind("", "c", function()
--   local win = hs.window.focusedWindow()
--   local screenWidth = win:screen():frame().w
--   hs.window.focusedWindow():move(hs.geometry.rect(screenWidth / 2 - 300, 0, 600, 400))

--   wmModality:exit()
-- end)
]]
  --
end

function M.loadNotifications()
  -- Dismiss active canvas notification with F19+escape
  local dismissBindings = C.notifier.dismissBindings
  if dismissBindings then
    local mods, key = table.unpack(dismissBindings)
    req("hyper", { id = "notifications" }):start():bind(mods, key, nil, function()
      -- Only dismiss if notification is active
      if _G.activeNotificationCanvas then
        local notifier = require("lib.notifications.notifier")
        notifier.dismissNotification()
      end
    end)
  end
end

function M:init()
  M.loadApps()
  M.loadMeeting()
  M.loadFigma()
  M.loadUtils()
  M.loadWm()
  M.loadNotifications()

  -- req("snipper")
  req("clipper")
  U.log.i("initialized")
end

return M
