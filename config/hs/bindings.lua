local wm = require("wm")

-- [ APP LAUNCHERS ] -----------------------------------------------------------

local hyper = require("hyper"):start({ id = "apps" })
hs.fnutils.each(APPS, function(bindingTable)
  local bundleID, globalBind, localBinds = table.unpack(bindingTable)
  if globalBind then hyper:bind({}, globalBind, function() hs.application.launchOrFocusByBundleID(bundleID) end) end
  if localBinds then hs.fnutils.each(localBinds, function(key) hyper:bindPassThrough(key, bundleID) end) end
end)

-- [ MODAL LAUNCHERS ] ---------------------------------------------------------

-- # window management ---------------------------------------------------------
local modality = require("modality"):start({ id = "wm", key = "l" })
modality
  :bind({}, "escape", function() modality:exit() end)
  :bind({}, "return", function() wm.place(POSITIONS.full) end, function() modality:delayedExit(0.1) end)
  :bind({ "shift" }, "return", function() wm.place(POSITIONS.full) end, function() modality:exit() end)
  :bind({}, "l", function() wm.place(POSITIONS.halves.right) end, function() modality:delayedExit(0.1) end)
  :bind({ "shift" }, "l", function()
    wm.toNextScreen()
    wm.place(POSITIONS.halves.right)
  end, function() modality:exit() end)
  :bind({}, "h", function() wm.place(POSITIONS.halves.left) end, function() modality:delayedExit(0.1) end)
  :bind({ "shift" }, "h", function()
    wm.toNextScreen()
    wm.place(POSITIONS.halves.right)
  end, function() modality:exit() end)
  :bind({}, "j", function() wm.toNextScreen() end, function() modality:delayedExit(0.1) end)
  :bind({}, "k", function()
    local chain = require("chain")
    -- wm.place(POSITIONS.center.large)

    dbg(chain)
    chain({
      POSITIONS.center.large,
      POSITIONS.center.medium,
      POSITIONS.center.small,
      POSITIONS.center.tiny,
      POSITIONS.center.mini,
    }, modality)
  end) --, function() modality:delayedExit(0.1) end)
  :bind({}, "v", function()
    wm.tile()
    modality:exit()
  end)
  :bind({}, "s", function()
    require("browser"):splitTab()
    modality:exit()
  end)
  :bind({ "shift" }, "s", function()
    require("browser"):splitTab(true)
    modality:exit()
  end)
  :bind({}, "m", function()
    local app = hs.application.frontmostApplication()
    local menuItemTable = { "Window", "Merge All Windows" }
    if app:findMenuItem(menuItemTable) then
      app:selectMenuItem(menuItemTable)
    else
      warn("Merge All Windows is unsupported for " .. app:bundleID())
    end

    modality:exit()
  end)
  :bind({}, "f", function()
    local focused = hs.window.focusedWindow()
    hs.fnutils.map(focused:otherWindowsAllScreens(), function(win) win:application():hide() end)
    modality:exit()
  end)
  :bind("", "c", function()
    local win = hs.window.focusedWindow()
    local screenWidth = win:screen():frame().w
    hs.window.focusedWindow():move(hs.geometry.rect(screenWidth / 2 - 300, 0, 600, 400))

    modality:exit()
  end)

info(fmt("[START] %s", "bindings"))
