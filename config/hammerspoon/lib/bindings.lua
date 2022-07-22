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
  hs.fnutils.each(
    group,
    function(app)
      table.insert(choices, {
        text = hs.application.nameForBundleID(app.bundleID),
        image = hs.image.imageFromAppBundle(app.bundleID),
        bundleID = app.bundleID,
      })
    end
  )

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

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  return self
end

function obj:start()
  local bindings = Settings.get(CONFIG_KEY).bindings

  -- [ application bindings ] --------------------------------------------------

  bind(bindings.apps, "apps", function(t)
    hs.fnutils.each(t, function(cfg)
      local mods = cfg.mods or {}
      if cfg.key then Hyper:bind(mods, cfg.key, function() hs.application.launchOrFocusByBundleID(cfg.bundleID) end) end
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

  Hyper:bind({ "shift" }, "r", function()
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

  return self
end

function obj:stop()
  L.unload("lib.hyper")

  return self
end

return obj
