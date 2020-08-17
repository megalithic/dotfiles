local log = hs.logger.new('[bindings.misc]', 'debug')

local module = {}

local alert           = require('ext.alert')
local setLayoutForAll = require('utils.wm').setLayoutForAll
local setLayoutForApp = require('utils.wm').setLayoutForApp
local template        = require('ext.template')
local ptt             = require('bindings.ptt')

module.start = function()
  -- misc things
  for _, util in pairs(config.utilities) do

    if util.modifier and util.shortcut ~= nil and util.fn ~= nil then
      hs.hotkey.bind(util.modifier, util.shortcut, util.fn)
    end
  end


  -- additional things that cause cyclical reference issues from config.lua
  hs.hotkey.bind(config.modifiers.cmdAlt, 'p', function()
    toggled_to_state = ptt.toggleStates()

    alert.show({text="Toggling PTT mode to " .. toggled_to_state})
  end)

  hs.hotkey.bind(config.modifiers.mashShift, 'w', function()
    alert.show({text="Relayout of all apps"})

    setLayoutForAll()
  end)

  hs.hotkey.bind(config.modifiers.ctrlShift, 'w', function()
    local app = hs.application.frontmostApplication()
    alert.show({text="Relayout of single app (" .. app:name() .. ")"})

    setLayoutForApp(app)
  end)

  -- Snip current highlight text in browser and send to Drafts
  hs.hotkey.bind(config.modifiers.ctrlShift, 's', function()
    local appName = config.preferred.browsers[1]

    hs.osascript.applescript(template([[
      -- stolen from: https://gist.github.com/gabeanzelini/1931128eb233b0da8f51a8d165b418fa

      if (count of currentSelection()) is greater than 0 then
        set str to "tags: #link\n\n" & currentTitle() & "\n\n> " & currentSelection() & "\n\n[" & currentTitle() & "](" & currentUrl() & ")"
        tell application "Drafts"
          make new draft with properties {content:str, tags: {"link"}}
        end tell
      end if

      on currentUrl()
        tell application "{APP_NAME}" to get the URL of the active tab in the first window
      end currentUrl

      on currentSelection()
        tell application "{APP_NAME}" to execute front window's active tab javascript "getSelection().toString();"
      end currentSelection

      on currentTitle()
        tell application "{APP_NAME}" to get the title of the active tab in the first window
      end currentTitle
    ]], { APP_NAME = appName }))

    hs.notify.show("Snipped!", "The snippet has been sent to Drafts", "")
  end)
end

module.stop = function()
  -- nil
end

return module
