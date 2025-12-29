local ok, mod_or_err = pcall(require, "preflight")
if not ok then
  error("Error preloading hammerspork; unable to continue...\n" .. mod_or_err)
  return
end

--------------------------------------------------------------------------------
-- RELOAD CLEANUP (FALLBACK): Handle partial reload or error recovery
--
-- Primary cleanup is now handled by the hs.reload() wrapper in overrides.lua,
-- which runs BEFORE reload while we still have references to native objects.
--
-- This fallback only helps when:
-- 1. An error occurred during init and user is retrying
-- 2. Config was partially loaded before a crash
-- 3. hs.reload() wrapper wasn't set up yet (shouldn't happen normally)
--
-- In a normal reload, _G.S is nil here (fresh Lua state), so this is a no-op.
--------------------------------------------------------------------------------
local function cleanupPreviousRun()
  if _G.S and _G.S.resetAll then
    _G.S.resetAll()
  end
end

cleanupPreviousRun()

local ok, mod_or_err = pcall(require, "config")
if not ok then
  error("Error loading hammerspork config; unable to continue...\n" .. mod_or_err)
  return
end
_G.C = mod_or_err

-- Centralized state management (replaces scattered _G.* globals)
-- Usage: S.notification.canvas, S.notification.timers.animation, etc.
_G.S = require("lib.state")

--- @diagnostic disable-next-line: lowercase-global
function _G.req(mod, ...)
  -- local function lineTraceHook(event, data)
  --   local lineInfo = debug.getinfo(2, "Snl")
  --   print("TRACE: " .. (lineInfo["short_src"] or "<unknown source>") .. ":" .. (lineInfo["linedefined"] or "<??>"))
  -- end

  local ok, reqmod = pcall(require, mod)
  -- G[mod:sub(5)] = reqmod
  -- print(hs.inspect(G[mod:sub(5)]))

  if not ok then
    -- debug.sethook(lineTraceHook, "l")
    -- hs.alert(reqmod, 5)
    error(reqmod)

    return false
  else
    -- if there is an init function; invoke it first.
    if type(reqmod) == "table" and reqmod.init ~= nil and type(reqmod.init) == "function" then reqmod:init(...) end

    -- always return the module.. we typically end up immediately invoking it.
    return reqmod
  end
end

_G.U = req("utils")
_G.I = hs.inspect -- `i()` to easier inspect in the console

-- Initialize unified notification system
_G.N = req("lib.notifications")
N.init()

-- Backward compatibility (temporary during transition)
_G.NotifyDB = N.db
_G.NotifyMenubar = N.menubar

function _G.P(...)
  -- local function getFnLocation()
  --   local w = debug.getinfo(3, "S")
  --   return w.short_src:gsub(".*/", "") .. ":" .. w.linedefined
  -- end

  local function getLocation()
    local info = debug.getinfo(2, "Snl")
    return string.format("%s:%s", info.short_src, info.currentline)
  end

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
    -- TODO: add line debugging so we can see where blank P statements are

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

-- Development/spike modules (available via Spike.* global)
require("spike-ax-meeting")

-- NOTE: persistent-notification watcher REPLACED by unified action system
-- notification.lua watcher now handles ALL notifications (banners + persistent alerts)
-- Dismissal is now an action in rules (action = "dismiss") instead of separate scanner
local watchers = { "audio", "dock", "app", "notification", "camera" }

-- req("lib.seal")
req("bindings")
req("watchers", { watchers = watchers })
req("ptt", { push = { { "cmd", "alt" }, nil }, toggle = { { "cmd", "alt" }, "p" } }):start()
req("quitter"):start()

-- Setup hs.reload() wrapper for pre-reload cleanup (prevents resource leaks)
-- Must be called AFTER all modules are loaded so we have references to clean up
require("overrides").setupReloadCleanup({
  S = S,
  N = N,
  stopWatchers = function()
    require("watchers"):stop({ watchers = watchers })
    require("quitter"):stop()
  end,
})

hs.shutdownCallback = function()
  require("watchers"):stop({ watchers = watchers })
  require("quitter"):stop()
  if N and N.cleanup then N.cleanup() end
end

hs.notify.withdrawAll()
hs.notify.new({ title = "hammerspork", subTitle = "config is loaded.", alwaysPresent = true }):send()
U.log.o("hammerspork config is loaded")
