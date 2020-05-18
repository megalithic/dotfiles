local log = hs.logger.new('[bindings.misc]', 'debug')

local module = {}

local setLayoutForAll = require('utils.wm').setLayoutForAll
local setLayoutForApp = require('utils.wm').setLayoutForApp

module.start = function()
  -- misc things
  for _, util in pairs(config.utilities) do
    hs.hotkey.bind(util.superKey, util.shortcut, util.fn)
  end


  -- additional things that cause cyclical reference issues from config.lua
  hs.hotkey.bind(config.superKeys.mashShift, 'w', function()
    hs.alert.show("Relayout of all apps")
    setLayoutForAll()
  end)

  hs.hotkey.bind(config.superKeys.ctrlShift, 'w', function()
    local app = hs.application.frontmostApplication()
    hs.alert.show("Relayout of single app (" .. app:name() .. ")")
    setLayoutForApp(app)
  end)
end

module.stop = function()
  -- nil
end

return module
