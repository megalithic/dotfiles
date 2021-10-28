local log = hs.logger.new("[bindings.misc]", "debug")

local module = {}

local alert = require("ext.alert")
-- local setLayoutForAll = require('utils.wm').setLayoutForAll
-- local setLayoutForApp = require('utils.wm').setLayoutForApp
local browser = require("bindings.browser")
local ptt = require("bindings.ptt")

module.start = function()
  -- misc things
  for _, util in pairs(Config.utilities) do
    if util.modifier and util.shortcut ~= nil and util.fn ~= nil then
      hs.hotkey.bind(util.modifier, util.shortcut, util.fn)
    end
  end

  -- additional things that cause cyclical reference issues from Config.lua
  hs.hotkey.bind(Config.modifiers.cmdAlt, "p", function()
    local toggled_to_state = ptt.toggleStates()
    -- local icons = ptt.icons
    alert.show({ text = "Toggling PTT mode to " .. toggled_to_state })
  end)

  -- hs.hotkey.bind(Config.modifiers.mashShift, 'w', function()
  --   alert.show({text="Relayout of all apps"})

  --   setLayoutForAll()
  -- end)

  -- hs.hotkey.bind(Config.modifiers.ctrlShift, 'w', function()
  --   local app = hs.application.frontmostApplication()
  --   alert.show({text="Relayout of single app (" .. app:name() .. ")"})

  --   setLayoutForApp(app)
  -- end)

  -- Snip current highlight text in browser and send to Drafts
  hs.hotkey.bind(Config.modifiers.ctrlShift, "s", function()
    browser.snip()
  end)
end

module.stop = function()
  -- nil
end

return module
