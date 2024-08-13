local wm = req("wm")
local summon = req("summon")

-- [ APP LAUNCHERS ] -----------------------------------------------------------

do
  local hyper = req("hyper"):start({ id = "apps" })
  hs.fnutils.each(LAUNCHERS, function(bindingTable)
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

    if localBinds then hs.fnutils.each(localBinds, function(key) hyper:bindPassThrough(key, bundleID) end) end
  end)
end

-- [ OTHER LAUNCHERS ] -----------------------------------------------------------

do
  local hyper = req("hyper"):start({ id = "meeting" })
  -- hyper:bind({}, "z", function() hs.application.launchOrFocusByBundleID(bundleID) end)
  Z_count = 0
  hyper:bind({}, "z", nil, function()
    Z_count = Z_count + 1

    hs.timer.doAfter(0.2, function() Z_count = 0 end)

    -- if Z_count == 2 then
    --   spoon.ElgatoKey:toggle()
    -- else
    -- start a timer
    -- if not pressed again then
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
    elseif req("browser").jump("meet.google.com|hangouts.google.com.call") then
      local jumped = req("browser").jump("meet.google.com|hangouts.google.com.call")
      info(I(jumped))
    else
      info(fmt("%s: No hyper meeting targets to focus", "bindings.hyper.meeting"))
    end
    -- end
  end)
end

do
  local hyper = req("hyper"):start({ id = "utils" })
  -- hyper:bind({}, "z", function() hs.application.launchOrFocusByBundleID(bundleID) end)
  hyper:bind({ "shift" }, "r", nil, function()
    hs.notify.new({ title = "hammerspork", subTitle = "config is reloading..." }):send()
    hs.reload()
  end)
end

-- [ MODAL LAUNCHERS ] ---------------------------------------------------------

-- # window management ---------------------------------------------------------
local modality = req("modality"):start({ id = "wm", key = "l" })
modality
  :bind({}, "escape", function() modality:exit() end)
  :bind({}, "return", function() wm.place(POSITIONS.full) end, function() modality:delayedExit(0.1) end)
  :bind({ "shift" }, "return", function()
    wm.toNextScreen()
    wm.place(POSITIONS.full)
  end, function() modality:delayedExit(0.1) end)
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
    wm.place(POSITIONS.center.large)
    modality:exit()

    -- local chain = req("chain")
    -- -- wm.place(POSITIONS.center.large)
    --
    -- chain({
    --   POSITIONS.center.large,
    --   POSITIONS.center.medium,
    --   POSITIONS.center.small,
    --   POSITIONS.center.tiny,
    --   POSITIONS.center.mini,
    -- }, modality)
  end) --, function() modality:delayedExit(0.1) end)
  :bind({}, "v", function()
    wm.tile()
    modality:exit()
  end)
  :bind({}, "s", function()
    req("browser"):splitTab()
    modality:exit()
  end)
  :bind({ "shift" }, "s", function()
    req("browser"):splitTab(true)
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
