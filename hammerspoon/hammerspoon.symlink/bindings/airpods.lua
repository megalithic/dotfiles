-- Found on: https://gist.githubusercontent.com/daGrevis/79b27b9c156ba828ad52976a118b29e0/raw/0e77383f4eb9301527caac3f0b71350e9499210b/init.lua
local log = hs.logger.new('bindings.airpods', 'debug')
local module = {}

local toggle = function(deviceName)
  local s = [[
    activate application "SystemUIServer"
    tell application "System Events"
      tell process "SystemUIServer"
        set btMenu to (menu bar item 1 of menu bar 1 whose description contains "bluetooth")
        tell btMenu
          click
  ]]
  ..
  'tell (menu item "' .. deviceName .. '" of menu 1)\n'
  ..
  [[
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

module.start = function()
  hs.hotkey.bind(config.superKeys.cmdCtrl, 'a', function()
    local ok, output = toggle('replipods')

    if ok then
      hs.alert.show(output)
    else
      hs.alert.show("Couldn't connect to AirPods!")
    end
  end)
end

module.stop = function()
  -- nil
end

return module
