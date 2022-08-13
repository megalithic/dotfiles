-- REF:
-- https://github.com/elliotwaite/hammerspoon-config
-- https://github.com/elliotwaite/my-setup/blob/master/scripts/karabiner/update_karabiner_config.py
-- https://github.com/elliotwaite/hammerspoon-config/tree/scroll-events-only

local Settings = require("hs.settings")
local Hyper

local obj = {}

obj.__index = obj
obj.name = "bindings"

local function chooseAppFromGroup(apps, key, tag, groupKey)
  local group = hs.fnutils.filter(
    apps,
    function(app) return app.tags and hs.fnutils.contains(app.tags, tag) and app.bundleID ~= Settings.get(groupKey) end
  )

  local choices = {}
  hs.fnutils.each(group, function(app)
    local text = hs.application.nameForBundleID(app.bundleID) or app.bundleID
    table.insert(choices, {
      text = text,
      image = hs.image.imageFromAppBundle(app.bundleID),
      bundleID = app.bundleID,
    })
  end)

  if #choices == 1 then
    local app = choices[1]

    hs.notify
      .new(nil)
      :title("Switching hyper+" .. key .. " to " .. hs.application.nameForBundleID(app.bundleID))
      :contentImage(hs.image.imageFromAppBundle(app.bundleID))
      :send()

    Settings.set(groupKey, app.bundleID)
    hs.application.launchOrFocusByBundleID(app.bundleID)
  else
    hs.chooser
      .new(function(app)
        if app then
          Settings.set(groupKey, app.bundleID)
          hs.application.launchOrFocusByBundleID(app.bundleID)
        end
      end)
      :placeholderText("Choose an application for hyper+" .. key .. ":")
      :choices(choices)
      :show()
  end
end

local function group(apps, key, tag)
  local groupKey = "group." .. tag

  Hyper:bind({}, key, nil, function()
    if Settings.get(groupKey) == nil then
      chooseAppFromGroup(apps, key, tag, groupKey)
    else
      hs.application.launchOrFocusByBundleID(Settings.get(groupKey))
    end
  end)

  Hyper:bind({ "option" }, key, nil, function() chooseAppFromGroup(apps, key, tag, groupKey) end)
end

local function bind(t, id, bindFn)
  if not t or U.tlen(t) == 0 then
    error(fmt("unable to bind %s (%d); none found", id, U.tlen(t)))
    return
  end

  if not bindFn or not type(bindFn) == "function" then return end

  bindFn(t)
end

local function mouse()
  -- bind mouse side buttons to forward/back
  hs.eventtap
    .new({ hs.eventtap.event.types.otherMouseUp }, function(event)
      local button = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      if button == 3 then hs.eventtap.keyStroke({ "cmd" }, "[") end
      if button == 4 then hs.eventtap.keyStroke({ "cmd" }, "]") end
    end)
    :start()
end

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  return self
end

function obj:start()
  local config = Settings.get(CONFIG_KEY)
  local bindings = config.bindings
  local keys = config.keys

  -- [ application bindings ] --------------------------------------------------

  bind(bindings.apps, "apps", function(t)
    local launcher = L.load("lib.launcher") or {}

    hs.fnutils.each(t, function(cfg)
      local mods = cfg.mods or {}
      if cfg.key then
        Hyper:bind(mods, cfg.key, function()
          if cfg.launchMode ~= nil then
            if cfg.launchMode == "focus" then
              launcher.focusOnly(cfg.bundleID)
            else
              launcher.toggle(cfg.bundleID, false)
            end
          else
            launcher.toggle(cfg.bundleID, false)
          end
        end)
      end
      if cfg.localBindings and #cfg.localBindings > 0 then
        hs.fnutils.each(cfg.localBindings, function(key) Hyper:bindPassThrough(key, cfg.bundleID) end)
      end
    end)
  end)

  -- [ group bindings ] --------------------------------------------------------

  group(bindings.apps, "m", "personal") -- e.g., Messages, Signal, etd
  group(bindings.apps, "j", "browsers") -- e.g., brave, vivaldi, safari, firefox, etc
  group(bindings.apps, "s", "chat") -- e.g., slack, discord, etc

  -- [ utility bindings ] ------------------------------------------------------

  Hyper:bind(keys.mods.caSc, "r", function()
    hs.reload()
    hs.notify.new({ title = "Hammerspoon", subTitle = "Reloading configuration.." }):send()
  end)

  -- bind(bindings.utils, "utils", function(t)
  --   hs.fnutils.each(t, function(cfg)
  --     local mods = cfg.mods or {}
  --     if cfg.key and cfg.fn then
  --       hs.fnutils.each(cfg.fn, function(fn)
  --         Hyper:bind(mods, cfg.key, function() U.tfn(fn) end)
  --       end)
  --     end
  --   end)
  -- end)

  -- [ mouse bindings ] --------------------------------------------------------
  mouse()

  return self
end

function obj:stop()
  L.unload("lib.hyper")

  return self
end

return obj
