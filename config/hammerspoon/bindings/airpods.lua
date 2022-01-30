-- -- Found on: https://gist.githubusercontent.com/daGrevis/79b27b9c156ba828ad52976a118b29e0/raw/0e77383f4eb9301527caac3f0b71350e9499210b/init.lua
-- -- FIXME: look at using https://github.com/dbalatero/dotfiles/blob/master/hammerspoon/headphones.lua

local log = hs.logger.new("[bindings.airpods]", "debug")
local M = {}

local alert = require("ext.alert")

local toggle = function(deviceName)
  local s = [[
    activate application "SystemUIServer"
    tell application "System Events"
      tell process "SystemUIServer"
        set btMenu to (menu bar item 1 of menu bar 1 whose description contains "Bluetooth")
        tell btMenu
          click
  ]] .. 'tell (menu item "' .. deviceName .. '" of menu 1)\n' .. [[
            click
            if exists menu item "Connect" of menu 1 then
              click menu item "Connect" of menu 1
              return "Connecting AirPods..."
            else
              click menu item "Disconnect" of menu 1
              return "Disconnecting AirPods..."
            end if
          end tell
        end tell
      end tell
    end tell
  ]]

  return hs.osascript.applescript(s)
end

M.start = function()
  hs.hotkey.bind(Config.modifiers.cmdCtrl, "a", function()
    local ok, output = toggle("megapods")

    if ok then
      alert.show({ text = output })
    else
      alert.show({ text = "Couldn't connect to AirPods!" })
    end
  end)
end

M.stop = function()
  -- nil
end

return M
