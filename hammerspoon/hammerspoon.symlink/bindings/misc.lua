local log = hs.logger.new('[bindings.misc]', 'debug')

local module = {}

local setLayoutForAll = require('utils.wm').setLayoutForAll
local setLayoutForApp = require('utils.wm').setLayoutForApp
local alert = require('ext.alert')

module.start = function()
  -- misc things
  for _, util in pairs(config.utilities) do
    hs.hotkey.bind(util.modifier, util.shortcut, util.fn)
  end


  -- additional things that cause cyclical reference issues from config.lua
  hs.hotkey.bind(config.modifiers.mashShift, 'w', function()
    alert.show({text="Relayout of all apps"})
    setLayoutForAll()
  end)

  hs.hotkey.bind(config.modifiers.ctrlShift, 'w', function()
    local app = hs.application.frontmostApplication()
    alert.show({text="Relayout of single app (" .. app:name() .. ")"})
    setLayoutForApp(app)
  end)
end

module.stop = function()
  -- nil
end

return module
