_G.DefaultFont = { name = "JetBrainsMono Nerd Font", size = 18 }
_G.fmt = string.format
_G.ts = function(date)
  date = date or hs.timer.secondsSinceEpoch()
  -- return os.date("%Y-%m-%d %H:%M:%S " .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  return os.date("%Y-%m-%d %H:%M:%S", math.floor(date))
end
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

-- function tableFlip(t)
--   n = {}
--
--   for k, v in pairs(t) do
--     n[v] = k
--   end
--
--   return n
-- end
--
-- --------------------------------------------------------------------------------
-- -- Modal Helpers
-- --------------------------------------------------------------------------------
--
-- function activateModal(mods, key, timeout)
--   timeout = timeout or false
--   local modal = hs.hotkey.modal.new(mods, key)
--   local timer = hs.timer.new(1, function() modal:exit() end)
--   modal:bind("", "escape", nil, function() modal:exit() end)
--   modal:bind("ctrl", "c", nil, function() modal:exit() end)
--   function modal:entered()
--     if timeout then timer:start() end
--     print("modal entered")
--   end
--   function modal:exited()
--     if timeout then timer:stop() end
--     print("modal exited")
--   end
--   return modal
-- end
--
-- function modalBind(modal, key, fn, exitAfter)
--   exitAfter = exitAfter or false
--   modal:bind("", key, nil, function()
--     fn()
--     if exitAfter then modal:exit() end
--   end)
-- end
--
-- --------------------------------------------------------------------------------
-- -- Binding Helpers
-- --------------------------------------------------------------------------------
--
-- function registerKeyBindings(mods, bindings)
--   for key, binding in pairs(bindings) do
--     hs.hotkey.bind(mods, key, binding)
--   end
-- end
--
-- function registerModalBindings(mods, key, bindings, exitAfter)
--   exitAfter = exitAfter or false
--   local timeout = exitAfter == true
--   local modal = activateModal(mods, key, timeout)
--   for modalKey, binding in pairs(bindings) do
--     modalBind(modal, modalKey, binding, exitAfter)
--   end
--   return modal
-- end
--
-- function getPositions(sizes, leftOrRight, topOrBottom)
--   local applyLeftOrRight = function(size)
--     if type(POSITIONS[size]) == "string" then return POSITIONS[size] end
--     return POSITIONS[size][leftOrRight]
--   end
--
--   local applyTopOrBottom = function(position)
--     local h = math.floor(string.match(position, "x([0-9]+)") / 2)
--     position = string.gsub(position, "x[0-9]+", "x" .. h)
--     if topOrBottom == "bottom" then
--       local y = math.floor(string.match(position, ",([0-9]+)") + h)
--       position = string.gsub(position, ",[0-9]+", "," .. y)
--     end
--     return position
--   end
--
--   if topOrBottom then return hs.fnutils.map(hs.fnutils.map(sizes, applyLeftOrRight), applyTopOrBottom) end
--
--   return hs.fnutils.map(sizes, applyLeftOrRight)
-- end
