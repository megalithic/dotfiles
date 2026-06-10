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

-- Minimal JSON string escape for values we send over the socket.
local function jsonEscape(s)
  s = string.gsub(s or "", "\\", "\\\\")
  s = string.gsub(s, '"', '\\"')
  return s
end

-- Percent-encode a query value for the URL fallback.
local function urlEncode(s)
  return (string.gsub(s or "", "[^%w%-_%.~]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

-- Launch/focus shade-next prefilled with `text` (optionally routed).
-- Reuses a running instance via the control socket; otherwise opens the
-- shade-next:// URL (which launches the app, then prefills).
local function prefill(frag, text, route, focus)
  text = text or ""
  local bundleID = frag.app.bundle_id
  local socket = frag.launch and frag.launch.socket

  if socket and hs.application.get(bundleID) then
    -- Running: send a socket prefill (no duplicate window).
    local payload = string.format(
      '{"method":"prefill","params":{"text":"%s","route":%s,"focus":%s}}',
      jsonEscape(text),
      route and ('"' .. jsonEscape(route) .. '"') or "null",
      focus and "true" or "false"
    )
    local cmd = string.format(
      "printf '%%s\\n' %s | /usr/bin/nc -U %s",
      string.format("%q", payload),
      string.format("%q", socket)
    )
    hs.task.new("/bin/sh", nil, { "-c", cmd }):start()
  else
    -- Not running: launch via URL scheme (handler prefills on launch).
    local url = string.format(
      "%sprefill?text=%s&focus=%s",
      frag.app.url_scheme,
      urlEncode(text),
      focus and "1" or "0"
    )
    if route then url = url .. "&route=" .. urlEncode(route) end
    hs.urlevent.openURL(url)
  end
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

  -- Prefill chords: hyper(+mods)+key -> open shade-next prefilled with a route.
  for _, p in ipairs(frag.prefills or {}) do
    hyper:bind(p.mods or {}, p.key, nil, function()
      prefill(frag, p.text or "", p.route, p.focus ~= false)
    end)
    U.log.i("shade-next: bound hyper+" .. p.key .. " -> prefill " .. (p.route or ""))
  end

  return self
end

return M
