-- local axuiWindowElement = require('hs._asm.axuielement').windowElement
-- local reloadHS          = require('ext.system').reloadHS

local module = {}

module.init = function()
  -- some global functions for console
  inspect = hs.inspect
  -- reload  = reloadHS

  dumpWindows = function()
    hs.fnutils.each(hs.window.allWindows(), function(win)
      print(hs.inspect({
        id               = win:id(),
        title            = win:title(),
        app              = win:application():name(),
        role             = win:role(),
        subrole          = win:subrole(),
        frame            = win:frame(),
        -- buttonZoom       = axuiWindowElement(win):attributeValue('AXZoomButton'),
        -- buttonFullScreen = axuiWindowElement(win):attributeValue('AXFullScreenButton'),
        -- isResizable      = axuiWindowElement(win):isAttributeSettable('AXSize')
      }))
    end)
  end

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

  -- console styling
  local grayColor = {
    red   = 24 * 4 / 255,
    green = 24 * 4 / 255,
    blue  = 24 * 4 / 255,
    alpha = 1
  }

  local blackColor = {
    red   = 24 / 255,
    green = 24 / 255,
    blue  = 24 / 255,
    alpha = 1
  }

  local whiteColor = {
    red   = 255 / 255,
    green = 255 / 255,
    blue  = 255 / 255,
    alpha = 1
  }

  hs.console.consoleCommandColor(whiteColor)
  hs.console.consoleResultColor(grayColor)
  hs.console.consolePrintColor(grayColor)
  hs.console.darkMode(true)

  -- no toolbar
  -- hs.console.toolbar(nil)
end

return module
