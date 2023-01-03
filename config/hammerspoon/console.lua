-- local axuiWindowElement = require('hs._asm.axuielement').windowElement
-- local reloadHS          = require('ext.system').reloadHS

local log = hs.logger.new("[console]", "warning")

local obj = {}

obj.__index = obj
obj.name = "config"


function obj:init(opts)
  opts = opts or {}

-- some global functions for console
  I = hs.inspect
  R = hs.reload
  CC = hs.console.clearConsole
  A = hs.alert
  P = print
  H = hs.help
  D = hs.hsdocs
  S = hs.openPreferences

  -- reload  = reloadHS

  Windows = function(app)
    if type(app) == "string" then
      app = hs.application.get(app)
    end

    local windows = app == nil and hs.window.allWindows() or app:allWindows()

    hs.fnutils.each(
      windows,
      function(win)
        print(
          hs.inspect(
            {
              id = win:id(),
              title = win:title(),
              app = win:application():name(),
              bundleID = win:application():bundleID(),
              role = win:role(),
              subrole = win:subrole(),
              frame = win:frame(),
              isFullScreen = win:isFullScreen(),
              isStandard = win:isStandard(),
              isMinimized = win:isMinimized()
              -- buttonZoom       = axuiWindowElement(win):attributeValue('AXZoomButton'),
              -- buttonFullScreen = axuiWindowElement(win):attributeValue('AXFullScreenButton'),
              -- isResizable      = axuiWindowElement(win):isAttributeSettable('AXSize')
            }
          )
        )
      end
    )
  end

  Usb = function()
    hs.fnutils.each(
      hs.usb.attachedDevices(),
      function(usb)
        print(hs.inspect(usb))
        -- print(
        --   hs.inspect(
        --     {
        --       productID = usb:productID(),
        --       productName = usb:productName(),
        --       vendorID = usb:vendorID(),
        --       vendorName = usb:vendorName()
        --     }
        --   )
        -- )
      end
    )
  end

  AudioInput = function()
    local d = hs.audiodevice.defaultInputDevice()
    print(
      hs.inspect(
        {
          name = d:name(),
          uid = d:uid(),
          muted = d:muted(),
          volume = d:volume(),
          device = d
        }
      )
    )
  end

  AudioOutput = function()
    local d = hs.audiodevice.defaultOutputDevice()
    print(
      hs.inspect(
        {
          name = d:name(),
          uid = d:uid(),
          muted = d:muted(),
          volume = d:volume(),
          device = d
        }
      )
    )
  end

  Screens = function()
    hs.fnutils.each(
      hs.screen.allScreens(),
      function(s)
        print(
          hs.inspect(
            {
              name = s:name(),
              id = s:id(),
              position = s:position(),
              frame = s:frame()
            }
          )
        )
      end
    )
  end

  Time = function(date)
    date = date or hs.timer.secondsSinceEpoch()
    return os.date("%F %T" .. ((tostring(date):match("(%.%d+)$")) or ""), math.floor(date))
  end

  local darkMode = true
  local fontStyle = {name = "JetBrainsMono Nerd Font", size = 15}

  -- console styling

  local darkGrayColor = {
    red = 26 / 255,
    green = 28 / 255,
    blue = 39 / 255,
    alpha = 1.0
  }
  local whiteColor = {
    white = 1.0,
    alpha = 1.0
  }
  local lightGrayColor = {
    white = 1.0,
    alpha = 0.9
  }
  local purpleColor = {
    red = 171 / 255,
    green = 126 / 255,
    blue = 251 / 255,
    alpha = 1.0
  }
  local grayColor = {
    red = 24 * 4 / 255,
    green = 24 * 4 / 255,
    blue = 24 * 4 / 255,
    alpha = 1.0
  }
  local blackColor = {
    white = 0.0,
    alpha = 1.0
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

  return self
end

function obj:stop()
  Settings.clear(CONFIG_KEY)
  obj.settings = {}

  return self
end

return obj
