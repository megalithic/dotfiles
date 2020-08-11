-- local axuiWindowElement = require('hs._asm.axuielement').windowElement
-- local reloadHS          = require('ext.system').reloadHS

local log             = hs.logger.new('[console]', 'warning')

local module = {}

module.init = function()
  -- some global functions for console
  inspect = hs.inspect
  i = hs.inspect
  r  = hs.reload
  c = hs.console.clearConsole
  a = hs.alert
  p = print
  u = hs.checkForUpdates
  help = hs.help
  docs = hs.hsdocs
  settings = hs.openPreferences

  -- reload  = reloadHS

  dumpWindows = function(app)
    windows = app == nil and hs.window.allWindows() or app:allWindows()

    hs.fnutils.each(windows, function(win)
      print(hs.inspect({
        id               = win:id(),
        title            = win:title(),
        app              = win:application():name(),
        bundleID         = win:application():bundleID(),
        role             = win:role(),
        subrole          = win:subrole(),
        frame            = win:frame(),
        isFullScreen     = win:isFullScreen(),
        -- buttonZoom       = axuiWindowElement(win):attributeValue('AXZoomButton'),
        -- buttonFullScreen = axuiWindowElement(win):attributeValue('AXFullScreenButton'),
        -- isResizable      = axuiWindowElement(win):isAttributeSettable('AXSize')
      }))
    end)
  end

  listWindows = dumpWindows

  dumpUsbDevices = function()
    hs.fnutils.each(hs.usb.attachedDevices(), function(usb)
      print(hs.inspect({
        productID           = usb:productID(),
        productName         = usb:productName(),
        vendorID            = usb:vendorID(),
        vendorName          = usb:vendorName()
      }))
    end)
  end

  dumpCurrentInputAudioDevice = function()
    d = hs.audiodevice.defaultInputDevice()
    print(hs.inspect({
      name = d:name(),
      uid = d:uid(),
      muted = d:muted(),
      volume = d:volume(),
      device = d
    }))
  end

  dumpCurrentOutputAudioDevice = function()
    d = hs.audiodevice.defaultOutputDevice()
    print(hs.inspect({
      name = d:name(),
      uid = d:uid(),
      muted = d:muted(),
      volume = d:volume(),
      device = d
    }))
  end

  dumpScreens = function()
    hs.fnutils.each(hs.screen.allScreens(), function(s)
      print(hs.inspect({
        name = s:name(),
        id = s:id(),
        position = s:position(),
        frame = s:frame()
      }))
    end)
  end

  timestamp = function(date)
    date = date or hs.timer.secondsSinceEpoch()
    return os.date("%F %T" .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  end

  local darkMode = true
  local fontStyle = { name = "JetBrainsMono Nerd Font", size = 18 }

  -- console styling

  local darkGrayColor = {
    red   = 26 / 255,
    green = 28 / 255,
    blue  = 39 / 255,
    alpha = 1.0,
  }
  local whiteColor = {
    white = 1.0,
    alpha = 1.0,
  }
  local lightGrayColor = {
    white = 1.0,
    alpha = 0.9,
  }
  local purpleColor = {
    red   = 171 / 255,
    green = 126 / 255,
    blue  = 251 / 255,
    alpha = 1.0,
  }
  local grayColor = {
    red   = 24 * 4 / 255,
    green = 24 * 4 / 255,
    blue  = 24 * 4 / 255,
    alpha = 1.0,
  }
  local blackColor = {
    white = 0.0,
    alpha = 1.0,
  }

  hs.console.darkMode(darkMode)
  hs.console.consoleFont(fontStyle)
  hs.console.alpha(0.985)

  if darkMode then
    hs.console.outputBackgroundColor(darkGrayColor)
    hs.console.consoleCommandColor(whiteColor)
    hs.console.consoleResultColor(purpleColor)
    hs.console.consolePrintColor(grayColor)
  else
    hs.console.consoleCommandColor(blackColor)
    hs.console.consoleResultColor(grayColor)
    hs.console.consolePrintColor(grayColor)
  end

  -- no toolbar
  -- hs.console.toolbar(nil)
end

return module
