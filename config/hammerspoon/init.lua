local ok, mod_or_err = pcall(require, "preflight")
if not ok then
  error("Error preloading hammerspork; unable to continue...\n" .. mod_or_err)
  return
end
pcall(function() _G.S.resetAll() end)

local ok, mod_or_err = pcall(require, "config")
if not ok then
  error("Error loading hammerspork config; unable to continue...\n" .. mod_or_err)
  return
end

_G.C = mod_or_err
_G.S = require("lib.state")

--- @diagnostic disable-next-line: lowercase-global
function _G.req(mod, ...)
  local ok, reqmod = pcall(require, mod)
  if not ok then
    error(reqmod)

    return false
  else
    if type(reqmod) == "table" and reqmod.init ~= nil and type(reqmod.init) == "function" then reqmod:init(...) end

    return reqmod
  end
end

_G.U = req("utils")
_G.I = hs.inspect -- `i()` to easier inspect in the console

_G.N = req("lib.notifications")
N.init()

_G.HUD = req("lib.hud")

function _G.P(...)
  function callerInfo()
    local info = debug.getinfo(2, "Sl") -- Get info from the caller (level 2)
    if info then
      return string.format("%s:%d", info.short_src, info.currentline)
    else
      print("Could not determine caller information")
    end
  end

  if ... == nil then
    hs.console.printStyledtext(U.ts() .. " => " .. "")

    return
  end

  local contents = ...

  if type(...) ~= "string" then
    contents = hs.inspect(...)
  else
    if select("#", ...) > 1 then
      contents = string.format(...)
    else
      contents = ...
    end
  end

  hs.console.printStyledtext(U.ts() .. " (" .. callerInfo() .. ")" .. " => " .. contents)
end

hs.loadSpoon("EmmyLua")

local watchers = { "audio", "dock", "app", "notification", "url", "pasteboard", "screen", "media-presence" }

req("bindings")
req("watchers", { watchers = watchers })
req("quitter"):start()
req("clipper") -- Auto-inits via req(), starts pasteboard watcher
-- Load shade-next last so its Hyper overrides win for shared chords such as
-- Hyper+Shift+N and Hyper+Ctrl+N.
req("shade_next") -- inert until shade-next is installed

local overrides = require("overrides")
overrides.setupAlertOverride(HUD) -- Replace hs.alert with custom HUD
overrides.setupNotifyOverride(HUD) -- Replace hs.notify with custom HUD
overrides.setupReloadCleanup({
  stopWatchers = function()
    require("watchers"):stop({ watchers = watchers })
    require("quitter"):stop()
    require("clipper"):stop()
  end,
})

hs.shutdownCallback = function()
  require("watchers"):stop({ watchers = watchers })
  require("quitter"):stop()
  require("clipper"):stop()
  if N and N.cleanup then N.cleanup() end
  if HUD and HUD.cleanup then HUD.cleanup() end
end

hs.notify.withdrawAll()
hs.notify.new({ title = "hammerspork", subTitle = "config is loaded.", alwaysPresent = true }):send()
U.log.o("hammerspork loaded")
