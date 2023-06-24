-- REF:
-- https://github.com/elliotwaite/hammerspoon-config
-- https://github.com/elliotwaite/my-setup/blob/master/scripts/karabiner/update_karabiner_config.py
-- https://github.com/elliotwaite/hammerspoon-config/tree/scroll-events-only

local Settings = require("hs.settings")
local Hyper
hs.loadSpoon("Seal")

local obj = {}

obj.__index = obj
obj.name = "bindings"
obj.mouseBindings = {}
obj.debug = false

local dbg = function(str, ...)
  str = string.format(":: [%s] %s", obj.name, str)
  if obj.debug then return _G.dbg(string.format(str, ...), false) end
end

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

function obj:init(opts)
  opts = opts or {}
  Hyper = L.load("lib.hyper", { id = obj.name }):start()

  return self
end

function obj:start()
  local bindings = C.bindings
  local keys = C.keys

  -- [ mouse bindings ] --------------------------------------------------------
  -- bind mouse side buttons to forward/back
  -- FIXME: move these allowed bundleIDs to config?
  local allowedMouseBindingApps = {}
  obj.mouseBindings = hs.eventtap.new({ hs.eventtap.event.types.otherMouseDown }, function(tapEvent)
    if hs.fnutils.contains(allowedMouseBindingApps, hs.application.frontmostApplication():bundleID()) then
      local buttonIndex = tapEvent:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
      if buttonIndex == 3 then
        hs.eventtap.keyStroke({ "cmd" }, "[")
      elseif buttonIndex == 4 then
        hs.eventtap.keyStroke({ "cmd" }, "]")
      end
    end
  end)
  obj.mouseBindings:start()

  -- [ launcher bindings ] -----------------------------------------------------

  bind(bindings.launchers, "launchers", function(launcher)
    local launch = L.load("lib.launcher") or {}

    hs.fnutils.each(launcher, function(spec)
      -- dbg(I(spec))
      local key = spec.key
      local mods = spec.mods or {}
      local target = spec.target
      local mode = spec.mode or "launch"
      local B = require("lib.browser")

      if key and target then
        Hyper:bind(mods, key, function()
          dbg("key/mode/type/target: %s/%s/%s/%s", key, mode, type(target), I(target))
          -- we've only passed a string, assuming an application's bundleID
          if type(target) == "string" then
            if mode == "focus" then
              launch.focusOnly(target)
            else
              launch.toggle(target, false)
            end
            -- we've got a table to use various extra properties
          elseif type(target) == "table" then
            local foundTarget = hs.fnutils.reduce(target, function(acc, el)
              local targetId = el[1]
              local isUrl = targetId:match("[a-z]*://[^ >,;]*")
              local targetRunning = hs.application.find(targetId) ~= nil
              local targetType = nil

              if targetRunning and not isUrl then
                targetType = "bundleID"
              elseif not targetRunning and isUrl and B.hasTab(targetId) then
                targetType = "url"
              end

              if targetType ~= nil then return hs.fnutils.concat(acc, { targetType, targetId }) end

              return acc
            end, {})

            local launchType = foundTarget[1]
            local launchTarget = foundTarget[2]

            if #foundTarget > 0 then
              dbg("launch type/target: %s/%s", I(launchType), I(launchTarget))

              if launchType == "bundleID" then
                hs.fnutils.each(target, function(t)
                  local locals = t.locals
                  if locals and #locals > 0 then
                    hs.fnutils.each(locals, function(k)
                      dbg("binding local passthroughs: %s/%s", k, launchTarget)

                      Hyper:bindPassThrough(k, launchTarget)
                    end)
                  end
                end)

                if mode == "focus" then
                  launch.focusOnly(launchTarget)
                else
                  dbg("toggle/launch %s", launchTarget)
                  launch.toggle(launchTarget, false)
                end
              elseif launchType == "url" then
                B.jump(launchTarget)
              end
            end
          end
        end)
      else
        error("No key or targets given for this launcher..")
      end
    end)
  end)

  -- [ application bindings ] --------------------------------------------------

  bind(bindings.apps, "apps", function(t)
    local launcher = L.load("lib.launcher") or {}

    hs.fnutils.each(t, function(cfg)
      local mods = cfg.mods or {}
      if cfg.key then
        Hyper:bind(mods, cfg.key, function()
          -- if cfg.launcher ~= nil then
          --   cfg.launcher()
          -- else
          if cfg.launchMode ~= nil then
            if cfg.launchMode == "focus" then
              launcher.focusOnly(cfg.bundleID)
            else
              launcher.toggle(cfg.bundleID, false)
            end
          else
            launcher.toggle(cfg.bundleID, false)
          end
          -- end
        end)
      end

      if cfg.localBindings and #cfg.localBindings > 0 then
        hs.fnutils.each(cfg.localBindings, function(key) Hyper:bindPassThrough(key, cfg.bundleID) end)
      end
    end)
  end)

  -- [ group bindings ] --------------------------------------------------------

  group(bindings.apps, "m", "personal") -- e.g., Messages, etd
  group(bindings.apps, "j", "browsers") -- e.g., brave, vivaldi, safari, firefox, etc
  group(bindings.apps, "s", "chat") -- e.g., slack, discord, signal, etc

  -- [ utility bindings ] ------------------------------------------------------

  Hyper:bind(keys.mods.caSc, "r", function()
    hs.reload()
    hs.notify.new({ title = "Hammerspoon", subTitle = "Reloading configuration.." }):send()
  end)

  -- local axbrowse = require("axbrowse")
  -- local lastApp
  --
  -- hs.hotkey.bind(keys.mods.CasC, "b", function()
  --   local currentApp = hs.axuielement.applicationElement(hs.application.frontmostApplication())
  --   if currentApp == lastApp then
  --     axbrowse.browse() -- try to continue from where we left off
  --   else
  --     lastApp = currentApp
  --     axbrowse.browse(currentApp) -- new app, so start over
  --   end
  -- end)

  -- Hyper:bind({}, "space", function() spoon.Seal:toggle("") end)

  -- FIXME: config in settings module can't serialize functions :/
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
  obj.mouseBindings:stop()

  return self
end

return obj
