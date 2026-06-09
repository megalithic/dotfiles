-- shade-next Hyper bindings.
--
-- Loads the Nix-generated, data-only fragment at
-- ~/.local/share/hammerspoon/fragments/shade-next.lua and binds the default
-- Hyper chord (hyper+enter) to launch/toggle shade-next using its own
-- app-native chord (via hyper:bindAppChord).
--
-- This module stays INERT until shade-next is actually built/installed, so the
-- current `shade` workflow is unaffected during the transition.

local M = {}

local FRAGMENT = os.getenv("HOME") .. "/.local/share/hammerspoon/fragments/shade-next.lua"

local function loadFragment()
  local f = io.open(FRAGMENT, "r")
  if not f then return nil end
  f:close()
  local ok, data = pcall(dofile, FRAGMENT)
  if ok and type(data) == "table" then return data end
  return nil
end

local function binaryInstalled(frag)
  local bins = frag.launch and frag.launch.binaries
  if not bins then return false end
  for _, path in pairs({ bins.release, bins.debug }) do
    if path then
      local f = io.open(path, "r")
      if f then
        f:close()
        return true
      end
    end
  end
  return false
end

function M:init(_)
  local frag = loadFragment()
  if not frag or not frag.app or not frag.app.bundle_id then
    U.log.i("shade-next: no fragment found; skipping Hyper bindings")
    return self
  end

  -- Keep current `shade` untouched until shade-next is real.
  if not binaryInstalled(frag) then
    U.log.i("shade-next: binary not installed; Hyper bindings inert")
    return self
  end

  local hyper = req("hyper", { id = "shade-next" }):start()
  local toggle = (frag.chords and frag.chords.toggle) or { mods = { "cmd" }, key = "return" }

  -- hyper+enter -> launch/toggle shade-next, delivering its native chord.
  hyper:bindAppChord({}, "return", frag.app.bundle_id, toggle.mods, toggle.key)
  U.log.i("shade-next: bound hyper+return -> " .. frag.app.bundle_id)

  return self
end

return M
