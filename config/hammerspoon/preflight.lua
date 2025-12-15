local con = hs.console
local fmt = string.format

hs.allowAppleScript(true)
hs.application.enableSpotlightForNameSearches(false)
hs.autoLaunch(true)
hs.automaticallyCheckForUpdates(true)
hs.menuIcon(true)
hs.dockIcon(true)
hs.logger.defaultLogLevel = "error"
hs.hotkey.setLogLevel("error")
hs.hotkey.setLogLevel(0) ---@diagnostic disable-line: undefined-field https://github.com/Hammerspoon/hammerspoon/issues/3491
hs.keycodes.log.setLogLevel("error")
hs.window.animationDuration = 0.0
hs.window.highlight.ui.overlay = false
hs.window.setShadows(false)
-- https://developer.apple.com/documentation/applicationservices/1459345-axuielementsetmessagingtimeout
hs.window.timeout(0.5)
hs.grid.setGrid("60x20")
hs.grid.setMargins("0x0")

---------------------------------------------------------------------------------------------------
DefaultFont = { name = "JetBrainsMono Nerd Font Mono", size = 18 }

function Red(isDark)
  if isDark then
    -- return { red = 1, green = 0, blue = 0 }
    return { hex = "#f6757c", alpha = 1 }
  end
  return { red = 0.7, green = 0, blue = 0 }
end
function Yellow(isDark)
  if isDark then return { red = 1, green = 1, blue = 0 } end
  return { red = 0.7, green = 0.5, blue = 0 }
end
function Orange(isDark) return { hex = "#ef9672", alpha = 1 } end
function Green(isDark) return { hex = "#a7c080", alpha = 1 } end
function Base(isDark)
  if isDark then return { white = 0.6 } end
  return { white = 0.1 }
end
function Grey(isDark)
  if isDark then
    -- return { white = 0.45 }
    return { hex = "#444444", alpha = 1 }
  end
  return { white = 0.55 }
end
function Blue(isDark)
  if isDark then
    -- return { red = 0, green = 0.7, blue = 1 }
    return { hex = "#51afef", alpha = 0.65 }
  end
  return { red = 0, green = 0.1, blue = 0.5 }
end

con.titleVisibility("hidden")
con.toolbar(nil)
hs.consoleOnTop(false) -- buggy?
con.darkMode(true)
con.consoleFont(DefaultFont)
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
-- con.outputBackgroundColor({ hex = "#2c353d" })
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(grayColor)

--- REF: https://github.com/chrisgrieser/.config/blob/main/hammerspoon/appearance/console.lua#L54
---filter console entries, removing logging for enabling/disabling hotkeys,
---useless layout info or warnings, or info on extension loading.
-- HACK to fix https://www.reddit.com/r/hammerspoon/comments/11ao9ui/how_to_suppress_logging_for_hshotkeyenable/
function _G.CleanupConsole()
  local col = hs.console
  local consoleOutput = tostring(col.getConsole())
  col.clearConsole()
  local lines = hs.fnutils.split(consoleOutput, "\n+")
  if not lines then return end

  local isDark = true --U.isDarkMode()

  for _, line in ipairs(lines) do
    -- remove some lines
    local ignore = line:find("Loading extensions?: ")
      or line:find("Lazy extension loading enabled$")
      or line:find("Loading Spoon: RoundedCorners$")
      or line:find("Loading .*/init.lua$")
      or line:find("hs%.canvas:delete")
      or line:find("%-%- Done%.$")
      or line:find("wfilter: .* is STILL not registered") -- FIX https://github.com/Hammerspoon/hammerspoon/issues/3462

    -- colorize timestamp & error levels
    if not ignore then
      local timestamp, msg = line:match("(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d: )(.*)")
      if not msg then msg = line end -- msg without timestamp
      msg = msg
        :gsub("^%s-%d%d:%d%d:%d%d:? ", "") -- remove duplicate timestamp
        :gsub("^%s*", "")

      local color
      local lmsg = msg:lower()
      if msg:find("^> ") then -- user input
        color = Blue(isDark)
      elseif lmsg:find("error") or lmsg:find("fatal") then
        color = Red(isDark)
      elseif lmsg:find("ok") or lmsg:find("success") then
        color = Green(isDark)
      elseif lmsg:find("warn") or lmsg:find("warning") or msg:find("stack traceback") or lmsg:find("abort") then
        color = Orange(isDark)
      else
        color = grayColor
      end

      local coloredLine = hs.styledtext.new(msg, { color = color, font = DefaultFont })
      if timestamp then
        local time = hs.styledtext.new(timestamp, { color = Grey(isDark), font = DefaultFont })
        col.printStyledtext(time, coloredLine)
      else
        col.printStyledtext(coloredLine)
      end
    end
  end
end

-- clean up console as soon as it is opened
-- M.wf_hsConsole = wf.new("Hammerspoon"):subscribe(wf.windowFocused, function()
--   u.defer(0.1, M.cleanupConsole)
-- end)
-- M.aw_hsConsole = aw.new(function(appName, eventType)
--   if eventType == aw.activated and appName == "Hammerspoon" then
--     u.defer(0.1, M.cleanupConsole)
--   end
-- end):start()
-- Insert a separator in the console log every day at midnight
-- M.timer_dailyConsoleSeparator = hs.timer
--   .doAt("00:01", "01d", function() -- `00:01` to ensure date switched to the next day
--     local date = os.date("%a, %d. %b")
-- 		-- stylua: ignore
-- 		print(("\n------------------------- %s -----------------------------\n"):format(date))
--   end, true)
--   :start()
---------------------------------------------------------------------------------------------------

hs.alert.defaultStyle["textSize"] = 24
hs.alert.defaultStyle["radius"] = 10
hs.alert.defaultStyle["strokeColor"] = {
  white = 1,
  alpha = 0.3,
}
hs.alert.defaultStyle["fillColor"] = {
  red = 9 / 255,
  green = 8 / 255,
  blue = 32 / 255,
  alpha = 0.9,
}
hs.alert.defaultStyle["textColor"] = {
  red = 209 / 255,
  green = 236 / 255,
  blue = 240 / 255,
  alpha = 1,
}
hs.alert.defaultStyle["textFont"] = DefaultFont.name

if not hs.ipc.cliStatus() then hs.ipc.cliInstall() end
require("hs.ipc")

pcall(require, "nix_path")
NIX_PATH = NIX_PATH or nil
if NIX_PATH then
  PATH =
    table.concat({ NIX_PATH, "/opt/homebrew/bin", os.getenv("HOME") .. "/.dotfiles-nix/bin", os.getenv("PATH") }, ":")
else
  PATH = table.concat({ "/opt/homebrew/bin", os.getenv("HOME") .. "/.dotfiles-nix/bin", os.getenv("PATH") }, ":")
end

--- Created by muescha.
--- DateTime: 15.10.24
--- See: https://github.com/Hammerspoon/hammerspoon/issues/3224#issuecomment-2155567633
--- https://github.com/Hammerspoon/hammerspoon/issues/3277
-- local function axHotfix(win, infoText)
--   if not win then
--     win = hs.window.frontmostWindow()
--   end
--   if not infoText then
--     infoText = "?"
--   end
--
--   local axApp = hs.axuielement.applicationElement(win:application())
--   local wasEnhanced = axApp.AXEnhancedUserInterface
--   axApp.AXEnhancedUserInterface = false
--   -- print(" enable hotfix: " .. infoText)
--
--   return function()
--     hs.timer.doAfter(hs.window.animationDuration * 2, function()
--       -- print("disable hotfix: " .. infoText)
--       axApp.AXEnhancedUserInterface = wasEnhanced
--     end)
--   end
-- end
--
-- local function withAxHotfix(fn, position, infoText)
--   if not position then
--     position = 1
--   end
--   return function(...)
--     local revert = axHotfix(select(position, ...), infoText)
--     fn(...)
--     revert()
--   end
-- end
--
-- local windowMT = hs.getObjectMetatable("hs.window")
-- windowMT.setFrame = withAxHotfix(windowMT.setFrame, 1, "setFrame")

--- REF: https://github.com/skrypka/hammerspoon_config/blob/master/init.lua#L26C1-L51C56
local function axHotfix(win)
  if not win then win = hs.window.frontmostWindow() end

  local axApp = hs.axuielement.applicationElement(win:application())
  local wasEnhanced = axApp.AXEnhancedUserInterface
  axApp.AXEnhancedUserInterface = false

  return function()
    hs.timer.doAfter(hs.window.animationDuration * 2, function() axApp.AXEnhancedUserInterface = wasEnhanced end)
  end
end

local function withAxHotfix(fn, position)
  if not position then position = 1 end
  return function(...)
    local revert = axHotfix(select(position, ...))
    fn(...)
    revert()
  end
end

local windowMT = hs.getObjectMetatable("hs.window")
windowMT.maximize = withAxHotfix(windowMT.maximize)
windowMT.moveToUnit = withAxHotfix(windowMT.moveToUnit)

function Windows(appString)
  local app
  if appString ~= nil and type(appString) == "string" then app = hs.application.find(appString) end

  local windows = app == nil and hs.window.allWindows() or app:allWindows()

  hs.fnutils.each(windows, function(win)
    U.log.i(fmt("[WIN] %s (%s)", win:title(), win:application():bundleID()))
    U.log.n(I({
      id = win:id(),
      title = win:title(),
      app = win:application():name(),
      bundleID = win:application():bundleID(),
      role = win:role(),
      subrole = win:subrole(),
      frame = win:frame(),
      isFullScreen = win:isFullScreen(),
      isStandard = win:isStandard(),
      isMinimized = win:isMinimized(),
      -- buttonZoom       = axuiWindowElement(win):attributeValue('AXZoomButton'),
      -- buttonFullScreen = axuiWindowElement(win):attributeValue('AXFullScreenButton'),
      -- isResizable      = axuiWindowElement(win):isAttributeSettable('AXSize')
    }))

    return win
  end)

  if app then return app end

  return windows
end

function Screens()
  return hs.fnutils.each(hs.screen.allScreens(), function(s)
    print(hs.inspect({
      name = s:name(),
      id = s:id(),
      position = s:position(),
      frame = s:frame(),
    }))
    return s
  end)
end

function Usb()
  return hs.fnutils.each(hs.usb.attachedDevices(), function(d)
    print(hs.inspect({
      productID = d.productID,
      productName = d.productName,
      vendorID = d.vendorID,
      vendorName = d.vendorName,
    }))
    return d
  end)
end

function AudioInput()
  hs.fnutils.each(
    hs.audiodevice.allInputDevices(),
    function(d)
      print(hs.inspect({
        name = d:name(),
        uid = d:uid(),
        muted = d:muted(),
        volume = d:volume(),
        device = d,
      }))
    end
  )
  local d = hs.audiodevice.defaultInputDevice()
  U.log.w("current input device: ")
  U.log.d(hs.inspect({
    name = d:name(),
    uid = d:uid(),
    muted = d:muted(),
    volume = d:volume(),
    device = d,
  }))
end

function AudioOutput()
  hs.fnutils.each(
    hs.audiodevice.allOutputDevices(),
    function(d)
      print(hs.inspect({
        name = d:name(),
        uid = d:uid(),
        muted = d:muted(),
        volume = d:volume(),
        device = d,
      }))
    end
  )
  local d = hs.audiodevice.defaultOutputDevice()
  U.log.w("current output device: ")
  U.log.d(hs.inspect({
    name = d:name(),
    uid = d:uid(),
    muted = d:muted(),
    volume = d:volume(),
    device = d,
  }))
end

function Audio()
  local i = hs.audiodevice.current(true)
  local o = hs.audiodevice.current()

  U.log.w("current input device: ")
  U.log.d(hs.inspect({
    name = i.name,
    uid = i.uid,
    muted = i.muted,
    volume = i.volume,
  }))

  U.log.w("\r\ncurrent output device: ")
  U.log.d(hs.inspect({
    name = o.name,
    uid = o.uid,
    muted = o.muted,
    volume = o.volume,
    device = o,
  }))
end

function Hostname()
  local hostname = ""
  local handle = io.popen("hostname")

  if handle then
    hostname = handle:read("*l")
    handle:close()
  end

  return hostname
end
