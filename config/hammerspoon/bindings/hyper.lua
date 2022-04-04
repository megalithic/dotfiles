-- TODO: can now use this module in other modules, so extract out these bindings
-- again

local log = hs.logger.new("[bindings.hyper]", "warning")

local module = {}
-- local forceLaunchOrFocus = require('ext.application').forceLaunchOrFocus
-- local smartLaunchOrFocus = require('ext.application').smartLaunchOrFocus
local toggle = require("ext.application").toggle
local focusOnly = require("ext.application").focusOnly
-- local media = require("bindings.spotify_control")

local hyper = hs.hotkey.modal.new({}, nil)

-- Set the key you want to be HYPER to F19 in karabiner or keyboard

local pressed = function()
  hyper:enter()
end

local released = function()
  hyper:exit()
end

local hyperLocalBindingsTap = function(key)
  return hs.eventtap.keyStroke(Config.modifiers.ultra, key)
end

local hyperArrowBindingsTap = function(key)
  return hs.eventtap.keyStroke({}, key)
end

local appLaunchOrFocus = function(app)
  if app.hyper_key then
    log.df("hyper_key found for %s (%s)", app.name, app.hyper_key)
    local mod = app.modifier or {}

    hyper:bind(mod, app.hyper_key, function()
      if app.launchMode ~= nil then
        if app.launchMode == "focus" then
          focusOnly(app.bundleID)
        else
          toggle(app.bundleID, false)
        end
      else
        toggle(app.bundleID, false)
      end
    end)
  end
end

local localBindingLaunchOrFocus = function(app)
  if app.local_bindings then
    for _, key in pairs(app.local_bindings) do
      log.df("hyper local_bindings found for %s (%s)", app.name, hs.inspect(app.local_bindings))

      hyper:bind({}, key, nil, function()
        if hs.application.find(app.bundleID) then
          log.df("hyper local_bindings tap %s (%s)", app.name, app.bundleID)
          hyperLocalBindingsTap(key)
        else
          toggle(app.bundleID, false)
          hs.timer.waitWhile(function()
            return hs.application.find(app.bundleID) == nil
          end, function()
            hyperLocalBindingsTap(key)
          end)
        end
      end)
    end
  end
end

local vimNavigationKeyBindings = function()
  hyper:bind({ "shift" }, "h", nil, function()
    hyperArrowBindingsTap("left")
  end, function()
    hyperArrowBindingsTap("left")
  end)
  hyper:bind({ "shift" }, "j", nil, function()
    hyperArrowBindingsTap("down")
  end, function()
    hyperArrowBindingsTap("down")
  end)
  hyper:bind({ "shift" }, "k", nil, function()
    hyperArrowBindingsTap("up")
  end, function()
    hyperArrowBindingsTap("up")
  end)
  hyper:bind({ "shift" }, "l", nil, function()
    hyperArrowBindingsTap("right")
  end, function()
    hyperArrowBindingsTap("right")
  end)
end

local miscKeyBindings = function(misc)
  if misc.hyper_key and misc.fn ~= nil then
    log.df("hyper_key found for %s (%s)", misc.name, misc.hyper_key)
    hyper:bind(misc.hyper_mod, misc.hyper_key, misc.fn)
  end
end

local hyperGroup = function(key, tag)
  log.df("getting hyperGroup setting for group.%s and key (%s): ", tag, key, hs.settings.get("group" .. tag))
  if hs.settings.get("group" .. tag) == nil then
    log.df("no app set for group.%s", tag)
    local defaultAppForTag = hs.application.get(Config.preferred[tag][1])
    log.df(
      "attempted to set default app for group.%s: %s from %s",
      tag,
      defaultAppForTag:bundleID(),
      Config.preferred[tag][1]
    )
    hs.settings.set("group" .. tag, defaultAppForTag:bundleID())
  end

  hyper:bind({}, key, nil, function()
    toggle(hs.settings.get("group." .. tag), false)
  end)
  hyper:bind({ "option" }, key, nil, function()
    local group = hs.fnutils.filter(Config.apps, function(app)
      return app.tags and hs.fnutils.contains(app.tags, tag) and app.bundleID ~= hs.settings.get("group." .. tag)
    end)

    local choices = {}
    hs.fnutils.each(group, function(app)
      table.insert(choices, {
        text = hs.application.nameForBundleID(app.bundleID),
        image = hs.image.imageFromAppBundle(app.bundleID),
        bundleID = app.bundleID,
      })
    end)

    if #choices == 1 then
      local app = choices[1]

      hs.notify.new(nil)
        :title("Switching hyper+" .. key .. " to " .. hs.application.nameForBundleID(app.bundleID))
        :contentImage(hs.image.imageFromAppBundle(app.bundleID))
        :send()

      hs.settings.set("group." .. tag, app.bundleID)

      toggle(app.bundleID, false)
    else
      hs.chooser.new(function(app)
        if app then
          hs.settings.set("group." .. tag, app.bundleID)
          toggle(app.bundleID, false)
        end
      end):placeholderText("Choose an application for hyper+" .. key .. ":"):choices(choices):show()
    end
  end)
end

module.start = function()
  log.df("starting..")
  hs.hotkey.bind({}, Config.modifiers.hyper, pressed, released)

  -- :: hyper groups
  -- hyperGroup("m", "personal")
  -- hyperGroup("j", "browsers")
  -- hyperGroup("s", "chat")

  for _, app in pairs(Config.apps) do
    -- :: apps
    appLaunchOrFocus(app)

    -- :: local_bindings
    localBindingLaunchOrFocus(app)
  end

  -- :: vim movements
  -- FIXME: figure out why `NSGlobalDomain KeyRepeat -int 1` doesn't affect the repeatfn interval (real slow)
  vimNavigationKeyBindings()

  -- :: misc (utilities)
  for _, misc in pairs(Config.utilities) do
    miscKeyBindings(misc)
  end

  -- -- :: media (spotify/volume)
  -- for _, m in pairs(Config.media) do
  --   hyper:bind(
  --     m.hyper_mod,
  --     m.hyper_key,
  --     function()
  --       media.spotify(m.action, m.label)
  --     end
  --   )
  -- end

  -- -- :: volume control
  -- for _, v in pairs(Config.volume) do
  --   hyper:bind(
  --     v.hyper_mod,
  --     v.hyper_key,
  --     function()
  --       media.adjustVolume(v)
  --     end
  --   )
  -- end
end

module.stop = function()
  log.df("stopping..")
end

function module:bind(mod, key, pressedFn, releasedFn)
  -- can omit mod; but it breaks if no mod and no pressedFn
  if not pressedFn and not releasedFn then
    releasedFn = pressedFn
    pressedFn = key
    key = mod
    mod = {}
  end

  hyper:bind(mod, key, function()
    if pressedFn then
      pressedFn()
    end
  end, function()
    if releasedFn then
      releasedFn()
    end
  end)
end

return module
