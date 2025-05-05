local obj = hs.hotkey.modal.new({}, nil)

obj.name = "HyperModal"
obj.version = "0.0.2"
obj.author = "Evan Travers <evantravers@gmail.com>"
obj.contributor = "Seth Messer <seth.messer@gmail.com>"
obj.license = "MIT <https://opensource.org/licenses/MIT>"
obj.homepage = "https://github.com/megalithic/dotfiles/config/hammerspoon/Spoons/HyperModal/"

obj.isOpen = false
obj.indicator = nil
obj.indicatorColor = "#e39b7b"
obj.delayedExitTimer = nil

function obj.toggleIndicator(win, terminate)
  win = win or hs.window.focusedWindow()

  if obj.indicator == nil and win ~= nil then
    local frame = win:frame()
    obj.indicator = hs.canvas.new(frame):appendElements({
      type = "rectangle",
      action = "stroke",
      strokeWidth = 2.0,
      strokeColor = { hex = obj.indicatorColor, alpha = 0.7 },
      roundedRectRadii = { xRadius = 12.0, yRadius = 12.0 },
    })
  end

  if terminate then
    obj.indicator:delete()
    obj.indicator = nil
  else
    if obj.indicator:isShowing() then
      obj.indicator:hide()
    else
      obj.indicator:show()
    end
  end

  return obj.indicator
end

function obj:entered()
  if obj.custom_on_entered ~= nil and type(obj.custom_on_entered) == "function" then
    obj.custom_on_entered(obj.isOpen)
  else
    local win = hs.window.focusedWindow()

    if win ~= nil then
      obj.isOpen = true
      obj.toggleIndicator(win)
      obj.alertUuids = hs.fnutils.map(hs.screen.allScreens(), function(screen)
        if screen == hs.screen.mainScreen() then
          local app_title = win:application():title()
          local image = hs.image.imageFromAppBundle(win:application():bundleID())
          local prompt = fmt("◱ : %s", app_title)

          obj:delayedExit()
          if image ~= nil then
            prompt = fmt(": %s", app_title)

            return hs.alert.showWithImage(prompt, image, nil, screen)
          end

          return hs.alert.show(prompt, hs.alert.defaultStyle, screen, true)
        end
      end)
    else
      obj:exit()
    end
  end

  return self
end

function obj:delayedExit(delay)
  delay = delay or 1

  if obj.delayedExitTimer ~= nil then
    obj.delayedExitTimer:stop()
    obj.delayedExitTimer = nil
  end

  obj.delayedExitTimer = hs.timer.doAfter(delay, function() obj:exit() end)

  return self
end

function obj:exited()
  obj.isOpen = false
  if obj.alertUuids ~= nil then
    hs.fnutils.ieach(obj.alertUuids, function(uuid)
      if uuid ~= nil then hs.alert.closeSpecific(uuid) end
    end)
  end
  obj.toggleIndicator(nil, true)

  if obj.delayedExitTimer ~= nil then
    obj.delayedExitTimer:stop()
    obj.delayedExitTimer = nil
  end

  return self
end

function obj:toggle()
  if obj.isOpen then
    obj:exit()
  else
    obj:enter()
  end

  return self
end

function obj:start(on_entered)
  hs.window.animationDuration = 0
  obj.custom_on_entered = on_entered

  -- provide alternate escapes
  obj:bind("ctrl", "[", function() obj:exit() end):bind("", "escape", function() obj:exit() end)
  obj:bind("ctrl", "c", function() obj:exit() end):bind("", "escape", function() obj:exit() end)

  return self
end

function obj:bindHotKeys(mapping)
  local spec = {
    toggle = hs.fnutils.partial(self.toggle, self),
  }

  hs.spoons.bindHotkeysToSpec(spec, mapping)

  return self
end

return obj
