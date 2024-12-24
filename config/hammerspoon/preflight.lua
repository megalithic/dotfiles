if not hs.ipc.cliStatus() then hs.ipc.cliInstall() end
require("hs.ipc")

hs.settings.set("secrets", hs.json.read(".secrets.json"))

-- _G["modalities"] = {}
_G["hypers"] = {}
_G.DefaultFont = { name = "JetBrainsMono Nerd Font", size = 18 }
_G.fmt = string.format
_G.ts = function(date)
  date = date or hs.timer.secondsSinceEpoch()
  -- return os.date("%Y-%m-%d %H:%M:%S " .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  return os.date("%Y-%m-%d %H:%M:%S", math.floor(date))
end

function P(...)
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
I = hs.inspect.inspect

local stext = require("hs.styledtext").new
local getInfo = function()
  local info = debug.getinfo(2, "Sl")
  local lineinfo = fmt("%s:%s: ", info.short_src, info.currentline)
  return ""
end

function _G.note(msg, tag1, tag2)
  local tag = tag2 and "[NOTE] " or ""
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#444444", alpha = 1 },
    font = DefaultFont,
  }))
end

function _G.info(msg, tag1, tag2)
  local tag = tag2 and "[INFO] " or ""
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#51afef", alpha = 0.65 },
    font = DefaultFont,
  }))
end

function _G.success(msg, tag1, tag2)
  local tag = tag2 and "[SUCCESS] " or ""
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#a7c080", alpha = 1 },
    font = DefaultFont,
  }))
end

function _G.error(msg, tag1, tag2)
  local tag = tag2 and "[ERROR] " or ""
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
    color = { hex = "#c43e1f", alpha = 1 },
    font = DefaultFont,
  }))
end

function _G.warn(msg, tag1, tag2)
  local tag = tag2 and "[WARN] " or ""
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  -- tag = tag and "[WARN] " or ""
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#FF922B", alpha = 1 },
    font = DefaultFont,
  }))
end

function _G.dbg(msg, force, tag1, tag2)
  if type(force) == "boolean" then
    if force then
      _G.debug_enabled = true
    else
      _G.debug_enabled = false
    end
  else
    tag1 = force
    tag2 = tag1
  end

  if not _G.debug_enabled then return end

  local tag = tag2 and "[DEBUG] " or "[DEBUG] "
  tag1 = type(tag1) == "table" and I(tag1) or tag1
  msg = type(msg) == "table" and I(msg) or string.format("%s%s", msg, tag1 and " " .. tag1 or "")

  -- hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. getInfo() .. msg, {
  hs.console.printStyledtext(stext(ts() .. " -> " .. tag .. msg, {
    color = { hex = "#dddddd", alpha = 1 },
    backgroundColor = { hex = "#222222", alpha = 1 },
    font = DefaultFont,
  }))
end

function Windows()
  local app
  if type(app) == "string" then app = hs.application.get(app) end
  local windows = app == nil and hs.window.allWindows() or app:allWindows()

  return hs.fnutils.each(windows, function(win)
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
    return win
  end)
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
  warn("current input device: ")
  print(hs.inspect({
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
  warn("current output device: ")
  print(hs.inspect({
    name = d:name(),
    uid = d:uid(),
    muted = d:muted(),
    volume = d:volume(),
    device = d,
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

info(fmt("[START] %s", "preflight"))
