local bindings = {}
function disableBindings()
  for index, binding in ipairs(bindings) do
    binding:disable()
  end
end

function enableBindings()
  for index, binding in ipairs(bindings) do
    binding:enable()
  end
end

-- Public interface
local keystrokeToApp = {}
keystrokeToApp.register = function(appName, modifiers, character, stayActive)
  local newBinding = hs.hotkey.new(modifiers, character, function()
    local app = hs.appfinder.appFromName(appName)
      if not app then
        return
      end

      local lastApp = nil
      if not app:isFrontmost() then
        lastApp = hs.application.frontmostApplication()
        app:activate()
      end

      disableBindings()
      hs.timer.doAfter(0, function()
        hs.eventtap.keyStroke(modifiers, character)
        enableBindings()
      end)

      if lastApp and not stayActive then
        lastApp:activate()
      end
  end)

  newBinding:enable()
  table.insert(bindings, newBinding)
end
return keystrokeToApp
