local log = hs.logger.new("[bindings.misc]", "debug")

local module = {}

local alert = require("ext.alert")
-- local setLayoutForAll = require('utils.wm').setLayoutForAll
-- local setLayoutForApp = require('utils.wm').setLayoutForApp

module.start = function()
  -- misc things
  for _, util in pairs(Config.utilities) do
    if util.modifier and util.shortcut ~= nil and util.fn ~= nil then
      hs.hotkey.bind(util.modifier, util.shortcut, util.fn)
    end
  end

  -- bind mouse side buttons to forward/back
  hs.eventtap.new({ hs.eventtap.event.types.otherMouseUp }, function(event)
    local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      log.df("pressed other button: %s", button)
    if button == 3 then
      hs.eventtap.keyStroke({ "cmd" }, "[")
    end
    if button == 4 then
      hs.eventtap.keyStroke({ "cmd" }, "]")
    end
  end):start()

  -- hs.hotkey.bind(Config.modifiers.mashShift, 'w', function()
  --   alert.show({text="Relayout of all apps"})

  --   setLayoutForAll()
  -- end)

  -- hs.hotkey.bind(Config.modifiers.ctrlShift, 'w', function()
  --   local app = hs.application.frontmostApplication()
  --   alert.show({text="Relayout of single app (" .. app:name() .. ")"})

  --   setLayoutForApp(app)
  -- end)
end

module.stop = function()
  -- nil
end

return module
