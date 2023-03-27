-- [ GLOBALS ] -----------------------------------------------------------------

_G.mega = _G.mega or {
  __loaded_modules = {},
}
_G.L = require("utils.loader")
_G.U = require("utils")
_G.ts = function(date)
  date = date or hs.timer.secondsSinceEpoch()
  -- return os.date("%Y-%m-%d %H:%M:%S " .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  return os.date("%Y-%m-%d %H:%M:%S", math.floor(date))
end
_G.fmt = string.format
_G.P = function(...)
  if ... == nil then
    hs.rawprint("")
    print("")
    return
  end

  local contents = ...

  if type(...) == "table" then
    contents = tostring(...)
  else
    contents = fmt(...)
  end

  hs.rawprint(...)
  hs.console.printStyledtext(ts() .. " -> " .. contents)
end
_G.I = hs.inspect.inspect
_G.defaultFont = { name = "JetBrainsMono Nerd Font", size = 18 }

local stext = require("hs.styledtext").new
local getInfo = function()
  local info = debug.getinfo(2, "Sl")
  local lineinfo = fmt("%s:%s: ", info.short_src, info.currentline)
  return ""
end
function _G.info(msg, tag)
  tag = tag and "[INFO] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#51afef", alpha = 0.65 },
    font = defaultFont,
  }))
end

function _G.success(msg, tag)
  tag = tag and "[OK] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#a7c080", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.error(msg, tag)
  tag = tag and "[ERROR] " or ""

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
    color = { hex = "#c43e1f", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.warn(msg, tag)
  tag = tag and "[WARN] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#FF922B", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.dbg(msg, tag)
  if not _G.debug_enabled then return end

  tag = tag and "[DEBUG] " or "[DEBUG] "
  msg = type(msg) == "table" and I(msg) or msg

  -- hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#dddddd", alpha = 1 },
    backgroundColor = { hex = "#222222", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.note(msg, tag)
  tag = tag and "[NOTE] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#444444", alpha = 1 },
    font = defaultFont,
  }))
end

function _G.windows()
  local app
  if type(app) == "string" then app = hs.application.get(app) end
  local windows = app == nil and hs.window.allWindows() or app:allWindows()

  hs.fnutils.each(windows, function(win)
    info(fmt("[WIN] %s (%s)", win:title(), win:application():bundleID()))
    note(I({
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
  end)
end

function _G.screens()
  hs.fnutils.each(
    hs.screen.allScreens(),
    function(s)
      print(hs.inspect({
        name = s:name(),
        id = s:id(),
        position = s:position(),
        frame = s:frame(),
      }))
    end
  )
end

function _G.usb()
  hs.fnutils.each(
    hs.usb.attachedDevices(),
    function(d)
      print(hs.inspect({
        productID = d.productID,
        productName = d.productName,
        vendorID = d.vendorID,
        vendorName = d.vendorName,
      }))
    end
  )
end

function _G.audioInput()
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
  warn("current input device: ")
  print(hs.inspect({
    name = d:name(),
    uid = d:uid(),
    muted = d:muted(),
    volume = d:volume(),
    device = d,
  }))
end

function _G.audioOutput()
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
  warn("current output device: ")
  print(hs.inspect({
    name = d:name(),
    uid = d:uid(),
    muted = d:muted(),
    volume = d:volume(),
    device = d,
  }))
end

function _G.hostname()
  local hostname = ""
  local handle = io.popen("hostname")

  if handle then
    hostname = handle:read("*l")
    handle:close()
  end

  return hostname
end

_G.CONFIG_KEY = "_mega_config"

-- _G.application_events = function(e)
--   local t = type(e)
--
--   local a = hs.application.watcher
--
--   local enum_tbl = {
--     [0] = a.launching,
--     [1] = a.launched,
--     [2] = a.terminated,
--     [3] = a.hidden,
--     [4] = a.unhidden,
--     [5] = a.activated,
--     [6] = a.deactivated,
--   }
--
--   return enum_tbl[e]
-- end

-- [ CONSOLE SETTINGS ] ---------------------------------------------------------

local con = require("hs.console")
con.darkMode(true)
con.consoleFont(defaultFont)
con.alpha(0.985)
local darkGrayColor = { red = 26 / 255, green = 28 / 255, blue = 39 / 255, alpha = 1.0 }
local whiteColor = { white = 1.0, alpha = 1.0 }
local lightGrayColor = { white = 1.0, alpha = 0.9 }
local grayColor = { red = 24 * 4 / 255, green = 24 * 4 / 255, blue = 24 * 4 / 255, alpha = 1.0 }
con.outputBackgroundColor(darkGrayColor)
con.consoleCommandColor(whiteColor)
con.consoleResultColor(lightGrayColor)
con.consolePrintColor(grayColor)
