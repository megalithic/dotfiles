local obj = {}
local _appObj = nil

obj.__index = obj
obj.name = "context.mailmate"
obj.debug = true

obj.modal = nil
obj.actions = {}
obj.mouseClick = nil

-- HT: https://github.com/muescha/dot_hammerspoon/blob/master/Functions/MailMateFocus.lua
local function checkCmdClickInMailmateAndActivateMailmate(mailmateBundleID)
  local browser = hs.application.get(BROWSER)
  -- Setup the click behaviour:
  -- -> use normal click to come back: false
  -- -> use cmd+click to come back: true
  local enable_cmdClick = false

  if hs.application.frontmostApplication():bundleID() ~= mailmateBundleID then
    --debugInfo(scriptInfo, 'not in MailMate --> exit')
    return false
  end

  if enable_cmdClick then
    if not hs.eventtap.checkKeyboardModifiers()["cmd"] then
      -- debugInfo(scriptInfo, "no modifier `cmd` --> exit")
      return false
    end
  else
    local mousePos = hs.mouse.absolutePosition()
    --debugInfo(scriptInfo,'mousePos ',mousePos)
    local focusedWindow = hs.window.focusedWindow()
    --debugInfo(scriptInfo,'focusedWindow ',focusedWindow)
    if focusedWindow then
      local frame = focusedWindow:frame()
      --debugInfo(scriptInfo,'frame ',frame)
      if
        mousePos.x < frame.x
        or mousePos.y < frame.y
        or mousePos.x > frame.x + frame.w
        or mousePos.y > frame.y + frame.h
      then
        -- Click occurred outside the window
        -- debugInfo(scriptInfo, "Click outside MailMate window --> exit")
        return false
      else
        -- Click occurred inside the MailMate window
        --debugInfo(scriptInfo, "Click inside MailMate window")
      end
    else
      return false
    end
  end

  hs.timer.doAfter(0.5, function()
    if hs.application.frontmostApplication():bundleID() == browser:bundleID() then
      -- debugInfo(scriptInfo, "we are now in Chrome --> switch back")
      hs.application.get(mailmateBundleID):activate()
      -- else
      --   debugInfo(scriptInfo, "no app change --> exit")
    end
  end)
  return false
end

-- it need to be a global variable so this is not garbage collected

function obj:start(opts)
  opts = opts or {}
  local appObj = opts["appObj"]
  local bundleID = opts["bundleID"]
  local event = opts["event"]

  if obj.modal then obj.modal:enter() end

  -- if
  --   (event == hs.application.watcher.launched or event == hs.application.watcher.activated)
  --   and #hs.screen.allScreens() > 1
  -- then
  --   obj.mouseClick = hs.eventtap
  --     .new({ hs.eventtap.event.types.leftMouseDown }, function() checkCmdClickInMailmateAndActivateMailmate(bundleID) end)
  --     :start()
  -- end

  return self
end

function obj:stop(opts)
  opts = opts or {}
  local event = opts["event"]

  if obj.modal then obj.modal:exit() end

  -- if obj.mouseClick then
  --   if _appObj and (event == hs.application.watcher.hidden or event == hs.application.watcher.deactivated) then
  --     obj.mouseClick:stop()
  --   elseif event == hs.application.watcher.terminated then
  --     obj.mouseClick:stop()

  --     require("ptt").setMode("push-to-talk")
  --     require("utils").dnd(false, "back")

  --     do
  --       if hs.application.get(BROWSER) ~= nil then
  --         local browser_win = hs.application.get(BROWSER):mainWindow()
  --         if browser_win ~= nil then browser_win:moveToUnit(hs.layout.maximized) end
  --       end

  --       -- local term = hs.application.get("com.github.wez.wezterm") or hs.application.get("kitty")
  --       -- if term ~= nil then
  --       --   local term_win = term:mainWindow()
  --       --   if term_win ~= nil then term_win:moveToUnit(hs.layout.maximized) end
  --       -- end
  --     end
  --   end
  -- end

  return self
end

return obj
