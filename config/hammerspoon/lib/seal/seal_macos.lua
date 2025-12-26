-- luacheck: no self
local obj = {}
obj.__index = obj
obj.__name = "seal_macos"
obj.__icon = hs.image.imageFromAppBundle("com.apple.systempreferences")
obj.__logger = hs.logger.new(obj.__name)

function obj.ejectAll()
  local success, _, _ = hs.applescript([[do shell script "umount -A"]])
  if not success then obj.__logger.e("Got an error while ejecting all disks.") end
end

function obj.ejectAllLocal()
  local success, _, _ = hs.applescript( -- luacheck: no max line length

    [[tell application "Finder" to eject (every disk whose ejectable is true and local volume is true and free space is not equal to 0)]]
  )
  if not success then obj.__logger.e("Got an error while ejecting all local disks.") end
end

function obj.emptyTrash()
  local f = function()
    local success, _, _ = hs.applescript([[tell application "Finder" to empty the trash]])
    if not success then obj.__logger.e("Got an error while emptying the trash.") end
  end

  U.spawn(f)
end

function obj.toggleDarkMode()
  local success, is_dark, _ = hs.applescript([[tell application "System Events"
                tell appearance preferences
                        get dark mode
                end tell
        end tell]])

  if not success then
    obj.__logger.e("Got an error while getting dark mode state.")
    return
  end

  local script = [[tell application "System Events"
                tell appearance preferences
                        set dark mode to %s
                end tell
        end tell]]
  if is_dark == true then
    script = script:format("false")
  else
    script = script:format("true")
  end

  success, _, _ = hs.applescript(script)
  if not success then
    obj.__logger.e("Got an error while setting dark mode state.")
    return
  end
end

function obj.lock() hs.eventtap.keyStroke({ "cmd", "ctrl" }, "q") end

function obj.sleep()
  local success, _, _ = hs.applescript([[do shell script "pmset sleepnow"]])
  if not success then obj.__logger.e("Got an error while putting MacOS to sleep.") end
end

function obj.toggleWiFi() hs.wifi.setPower(not hs.wifi.interfaceDetails("en0").power, "en0") end

function obj.toggleBluetooth()
  -- Requires `brew install blueutil` or `nix-env -iA nixpkgs.blueutil`.
  -- Uses hs.task with /usr/bin/env to leverage PATH injection from overrides.lua

  -- First, get current state
  local getStateTask = hs.task.new("/usr/bin/env", function(exitCode, stdOut, _)
    if exitCode ~= 0 then
      obj.__logger.e("Got an error while determining Bluetooth power state.")
      return
    end

    local currentState = (stdOut or ""):gsub("%s+", "")
    local newState = currentState == "1" and "off" or "on"

    -- Now toggle to new state
    local setStateTask = hs.task.new("/usr/bin/env", function(setExitCode, _, _)
      if setExitCode ~= 0 then
        obj.__logger.e("Got an error while setting Bluetooth power state.")
      end
    end, { "blueutil", newState })
    if setStateTask then setStateTask:start() end
  end, { "blueutil" })

  if getStateTask then getStateTask:start() end
end

-- Toggle the menu bar auto-hiding.
function obj.toggleMenuBar()
  local result = hs.osascript.applescript([[
    tell application "System Preferences"
        reveal pane id "com.apple.preference.general"
    end tell
    tell application "System Events" to tell process "System Preferences" to tell window "General"
        click checkbox "Automatically hide and show the menu bar"
    end tell
    delay 1
    quit application "System Preferences"
    ]])
  if not result then obj.__logger.e("Error while toggling the Menu Bar.") end
end

obj.cmds = {
  { text = "Toggle WiFi", type = "toggleWiFi" },
  { text = "Toggle Bluetooth", type = "toggleBluetooth" },
  { text = "Lock", type = "lock" },
  { text = "Sleep", type = "sleep" },
  { text = "Empty Trash", type = "emptyTrash" },
  { text = "Toggle Dark Mode", type = "toggleDarkMode" },
  { text = "Eject All Disks", type = "ejectAll" },
  { text = "Eject All Local Disks", type = "ejectAllLocal" },
  { text = "Toggle Menu Bar", type = "toggleMenuBar" },
}

function obj:commands()
  return {
    mac = {
      cmd = "mac",
      fn = obj.choicesMacOS,
      name = "MacOS command",
      description = "Send a MacOS command",
      plugin = obj.__name,
      icon = obj.__icon,
    },
  }
end

function obj:bare() return nil end

function obj.choicesMacOS(query)
  query = query:lower()
  local choices = {}

  for _, command in pairs(obj.cmds) do
    if string.match(command.text:lower(), query) or string.match((command.subText or ""):lower(), query) then
      command["plugin"] = obj.__name
      command["image"] = obj.__icon
      table.insert(choices, command)
    end
  end
  table.sort(choices, function(a, b) return a["text"] < b["text"] end)

  return choices
end

function obj.completionCallback(row_info)
  if not row_info then return end
  obj[row_info.type]()
end

return obj
