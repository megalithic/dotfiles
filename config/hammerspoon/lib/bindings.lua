local Settings = require("hs.settings")
local Hyper

local obj = {}

obj.__index = obj
obj.name = "bindings"

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

  -- [ utility bindings ] ------------------------------------------------------

  Hyper:bind({ "shift" }, "r", function()
    hs.reload()
    hs.notify.new({ title = "Hammerspoon", subTitle = "Configuration reloaded" }):send()
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
