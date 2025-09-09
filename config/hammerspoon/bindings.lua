local wm = req("wm")
local summon = req("summon")
local chain = req("chain")
local enum = req("hs.fnutils")
local utils = require("utils")

local function activateModal(mods, key, timeout)
  timeout = timeout or false
  local modal = hs.hotkey.modal.new(mods, key)
  local timer = hs.timer.new(1, function() modal:exit() end)
  modal:bind("", "escape", nil, function() modal:exit() end)
  modal:bind("ctrl", "c", nil, function() modal:exit() end)
  function modal:entered()
    if timeout then timer:start() end
    print("modal entered")
  end
  function modal:exited()
    if timeout then timer:stop() end
    print("modal exited")
  end
  return modal
end

local function modalBind(modal, key, fn, exitAfter)
  exitAfter = exitAfter or false
  modal:bind("", key, nil, function()
    fn()
    if exitAfter then modal:exit() end
  end)
end

local function registerModalBindings(mods, key, bindings, exitAfter)
  exitAfter = exitAfter or false
  local timeout = exitAfter == true
  local modal = activateModal(mods, key, timeout)

  if bindings ~= nil then
    if utils.tlen(bindings) == 1 then
      modalBind(modal, bindings[1], bindings[2], exitAfter)
    else
      for modalKey, binding in pairs(bindings) do
        modalBind(modal, modalKey, binding, exitAfter)
      end
    end
  end
  return modal
end

-- [ APP LAUNCHERS ] -----------------------------------------------------------

do
  local hyper = req("hyper", { id = "apps" }):start()
  enum.each(LAUNCHERS, function(bindingTable)
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
    if targetWin and targetWin:isStandard() then targetWin:focus() end
  elseif hs.application.find("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan") then
    hs.application.launchOrFocusByBundleID("com.brave.Browser.nightly.app.kjgfgldnnfoeklkmfkjfagphfepbbdan")
  elseif hs.application.find("com.microsoft.teams2") then
    wm.focusMainWindow("com.microsoft.teams2")
  elseif hs.application.find("com.pop.pop.app") then
    wm.focusMainWindow("com.pop.pop.app")

    -- hs.application.launchOrFocusByBundleID("com.pop.pop.app")
    -- local app = hs.application.find("com.pop.pop.app")
    -- local targetWin = enum.find(
    --   app:allWindows(),
    --   function(win)
    --     return app:mainWindow() == win and win:isStandard() and win:frame().w > 1000 and win:frame().h > 1000
    --   end
    -- )

    -- if targetWin ~= nil then targetWin:focus() end
  elseif req("browser").hasTab("meet.google.com|hangouts.google.com.call|www.valant.io|telehealth.px.athena.io") then
    req("browser").jump("meet.google.com|hangouts.google.com.call|www.valant.io|telehealth.px.athena.io")
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
    info(fmt("%s: neither figma.app, nor figma web are opened", "bindings.hyper.figma"))

    focusedApp:activate()
  end
end)

req("hyper", { id = "utils" })
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

-- local tiler = req("hyper", { id = "apps" }):start()
-- tiler:bind({}, "v", function() require("wm").tile() end)

local wmModality = spoon.HyperModal
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
  -- :bind({}, "space", function() wm.place(POSITIONS.preview) end, function() wmModality:exit(0.1) end)
  :bind(
    {},
    "space",
    chain({
      POSITIONS.full,
      POSITIONS.center.large,
      POSITIONS.center.medium,
      POSITIONS.center.small,
      POSITIONS.center.tiny,
      POSITIONS.center.mini,
      POSITIONS.preview,
    }, wmModality, 1.0)
  )
  :bind({}, "return", function() wm.place(POSITIONS.full) end, function() wmModality:exit(0.1) end)
  :bind({ "shift" }, "return", function()
    wm.toNextScreen()
    wm.place(POSITIONS.full)
  end, function() wmModality:exit() end)
  :bind(
    {},
    "h",
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["left"]
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
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["right"]
      end),
      wmModality,
      1.0
    )
  )
  :bind({ "shift" }, "h", function()
    wm.toPrevScreen()
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["left"]
      end),
      wmModality,
      1.0
    )
  end)
  :bind({ "shift" }, "l", function()
    wm.toNextScreen()
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["right"]
      end),
      wmModality,
      1.0
    )
  end)
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
  -- :bind({}, "space", function() wm.place(POSITIONS.preview) end, function() wmModality:exit(0.1) end)
  :bind(
    { "ctrl" },
    "space",
    chain(
      {
        POSITIONS.full,
        POSITIONS.center.large,
        POSITIONS.center.medium,
        POSITIONS.center.small,
        POSITIONS.center.tiny,
        POSITIONS.center.mini,
        POSITIONS.preview,
      }
      -- wmModality, 1.0
    )
    -- function() wm.place(POSITIONS.preview) end
  )
  -- :bind({}, "return", function() wm.place(POSITIONS.full) end, function() wmModality:exit(0.1) end)
  :bind(
    { "ctrl" },
    "return",
    function() wm.place(POSITIONS.full) end
  )
  :bind({ "ctrl", "shift" }, "return", function()
    wm.toNextScreen()
    wm.place(POSITIONS.full)
    -- end, function() wmModality:exit() end)
  end)
  :bind(
    { "ctrl" },
    "l",
    -- function() wm.place(POSITIONS.halves.right) end,
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["right"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- function() wmModality:exit() end
  )
  :bind({ "ctrl", "shift" }, "l", function()
    wm.toNextScreen()
    -- wm.place(POSITIONS.halves.right)
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["right"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- end, function() wmModality:exit() end)
  end)
  :bind(
    { "ctrl" },
    "h",
    -- function() wm.place(POSITIONS.halves.left) end,
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["left"]
      end)
      -- wmModality,
      -- 1.0
    )
    -- function() wmModality:exit() end
  )
  :bind({ "shift" }, "h", function()
    wm.toPrevScreen()
    -- wm.place(POSITIONS.halves.left)
    chain(
      enum.map({ "halves", "thirds", "twoThirds", "fiveSixths", "sixths" }, function(size)
        if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
        return POSITIONS[size]["left"]
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
  --   -- function() wm.place(POSITIONS.center.large) end,
  --   chain(
  --     {
  --       POSITIONS.center.mini,
  --       POSITIONS.center.tiny,
  --       POSITIONS.center.small,
  --       POSITIONS.center.medium,
  --       POSITIONS.center.large,
  --     }
  --     -- wmModality, 1.0
  --   )
  --   -- function() wmModality:exit() end
  -- )
  -- :bind(
  --   {},
  --   "k",
  --   function() wm.place(POSITIONS.center.large) end
  --   -- chain({
  --   --   POSITIONS.center.large,
  --   --   POSITIONS.center.medium,
  --   --   POSITIONS.center.small,
  --   --   POSITIONS.center.tiny,
  --   --   POSITIONS.center.mini,
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

req("snipper")
req("clipper")

info(fmt("[START] %s", "bindings"))
