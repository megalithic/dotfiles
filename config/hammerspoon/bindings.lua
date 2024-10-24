local wm = req("wm")
local summon = req("summon")
local chain = req("chain")
local enum = req("hs.fnutils")
local utils = require("utils")

-- [ APP LAUNCHERS ] -----------------------------------------------------------

do
  local hyper = req("hyper", { id = "apps" }):start()
  enum.each(LAUNCHERS, function(bindingTable)
    local bundleID, globalBind, localBinds, focusOnly = table.unpack(bindingTable)
    if globalBind ~= nil then
      local key = globalBind
      local mods = {}
      if type(key) == "table" then
        mods, key = table.unpack(globalBind)
      end

      hyper:bind(mods, key, function()
        if focusOnly ~= nil and focusOnly then
          summon.focus(bundleID)
        else
          summon.toggle(bundleID)
        end
      end)
    end

    if localBinds then enum.each(localBinds, function(key) hyper:bindPassThrough(key, bundleID) end) end
  end)
end

-- [ OTHER LAUNCHERS ] -----------------------------------------------------------

req("hyper", { id = "meeting" }):start():bind({}, "z", nil, function()
  local focusedApp = hs.application.frontmostApplication()
  if hs.application.find("us.zoom.xos") then
    hs.application.launchOrFocusByBundleID("us.zoom.xos")
    local app = hs.application.find("us.zoom.xos")
    local targetWin = app:findWindow("Zoom Meeting")
    if targetWin:isStandard() then targetWin:focus() end
  elseif hs.application.find("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan") then
    hs.application.launchOrFocusByBundleID("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan")
  elseif hs.application.find("com.pop.pop.app") then
    hs.application.launchOrFocusByBundleID("com.pop.pop.app")
    local app = hs.application.find("com.pop.pop.app")
    local targetWin = app:mainWindow()
    if targetWin:isStandard() and targetWin:frame().w > 1000 and targetWin:frame().h > 1000 then targetWin:focus() end
  elseif req("browser").hasTab("meet.google.com|hangouts.google.com.call") then
    req("browser").jump("meet.google.com|hangouts.google.com.call")
  else
    info(fmt("%s: no meeting targets to focus", "bindings.hyper.meeting"))

    focusedApp:activate()
  end
end)

req("hyper", { id = "figma" }):start():bind({ "shift" }, "f", nil, function()
  local focusedApp = hs.application.frontmostApplication()
  if hs.application.find("com.figma.Desktop") then
    hs.application.launchOrFocusByBundleID("com.figma.Desktop")
  elseif req("browser").hasTab("figma.com") then
    req("browser").jump("figma.com")
  else
    info(fmt("%s: no meeting targets to focus", "bindings.hyper.meeting"))

    focusedApp:activate()
  end
end)

local axbrowse = req("axbrowse")
local lastApp
req("hyper", { id = "utils" })
  :start()
  :bind({ "shift" }, "r", nil, function()
    hs.notify.new({ title = "hammerspork", subTitle = "config is reloading..." }):send()
    hs.reload()
  end)
  :bind({ "shift", "ctrl" }, "l", nil, req("wm").placeAllApps)
  -- WIP
  :bind({ "shift" }, "b", nil, function()
    local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
    if currentApp == lastApp then
      axbrowse.browse() -- try to continue from where we left off
    else
      lastApp = currentApp
      axbrowse.browse(currentApp) -- new app, so start over
    end
  end)
  -- focus daily notes; splitting it 30/70 with currently focused app window
  :bind(
    { "shift" },
    "o",
    nil,
    function() utils.tmux.focusDailyNote(true) end
  )
  -- focus daily note; window layout untouched
  :bind({ "ctrl" }, "o", nil, function() utils.tmux.focusDailyNote() end)
  :bind({ "ctrl" }, "d", nil, function() utils.dnd() end)

-- FIXME:
-- Maybe use this? REF: https://github.com/jackieaskins/dotfiles/blob/main/hammerspoon/config/hotkeyStore.lua
-- local utilsModality = req("modality"):start({ id = "utils", key = "r", mods = { "shift" } })
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

-- [ MODAL LAUNCHERS ] ---------------------------------------------------------

-- # wm/window management ---------------------------------------------------------
local wmModality = req("modality", { id = "wm", key = "l" }):start()
wmModality
  :bind({}, "r", req("wm").placeAllApps, function() wmModality:exit(0.1) end)
  :bind({}, "escape", function() wmModality:exit() end)
  :bind({}, "space", function() wm.place(POSITIONS.preview) end, function() wmModality:exit(0.1) end)
  :bind({}, "return", function() wm.place(POSITIONS.full) end, function() wmModality:exit(0.1) end)
  :bind({ "shift" }, "return", function()
    wm.toNextScreen()
    wm.place(POSITIONS.full)
  end, function() wmModality:exit() end)
  :bind(
    {},
    "l",
    function() wm.place(POSITIONS.halves.right) end,
    -- chain(
    --   enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
    --     if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
    --     return POSITIONS[size]["right"]
    --   end),
    --   wmModality,
    --   1.0
    -- )
    function() wmModality:exit() end
  )
  :bind({ "shift" }, "h", function()
    wm.toPrevScreen()
    wm.place(POSITIONS.halves.left)
  end, function() wmModality:exit() end)
  :bind(
    {},
    "h",

    function() wm.place(POSITIONS.halves.left) end,
    -- chain(
    --   enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
    --     if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
    --     return POSITIONS[size]["left"]
    --   end),
    --   wmModality,
    --   1.0
    -- )
    function() wmModality:exit() end
  )
  :bind({ "shift" }, "l", function()
    wm.toNextScreen()
    wm.place(POSITIONS.halves.right)
  end, function() wmModality:exit() end)
  -- :bind({}, "j", function() wm.toNextScreen() end, function() wmModality:delayedExit(0.1) end)
  :bind(
    {},
    "j",
    function() wm.place(POSITIONS.center.large) end,
    -- chain({
    --   POSITIONS.center.mini,
    --   POSITIONS.center.tiny,
    --   POSITIONS.center.small,
    --   POSITIONS.center.medium,
    --   POSITIONS.center.large,
    -- }, wmModality, 1.0)
    function() wmModality:exit() end
  )
  :bind(
    {},
    "k",
    function() wm.place(POSITIONS.center.medium) end,
    -- chain({
    --   POSITIONS.center.large,
    --   POSITIONS.center.medium,
    --   POSITIONS.center.small,
    --   POSITIONS.center.tiny,
    --   POSITIONS.center.mini,
    -- }, wmModality, 1.0)
    function() wmModality:exit() end
  )
  :bind({}, "v", function()
    wm.tile()
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
  :bind("", "c", function()
    local win = hs.window.focusedWindow()
    local screenWidth = win:screen():frame().w
    hs.window.focusedWindow():move(hs.geometry.rect(screenWidth / 2 - 300, 0, 600, 400))

    wmModality:exit()
  end)

req("clipper")

info(fmt("[START] %s", "bindings"))
