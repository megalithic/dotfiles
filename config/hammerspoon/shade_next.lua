-- shade-next Hyper bindings.
--
-- Loads the Nix-generated, data-only fragment at
-- ~/.local/share/hammerspoon/fragments/shade-next.lua. Hyper+return toggles
-- shade-next directly through its control channel; Hyper+n enters a shade-next
-- modal where keys like p/n prefill specific routes.
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

-- Percent-encode a query value for the URL fallback.
local function urlEncode(s)
  return (string.gsub(s or "", "[^%w%-_%.~]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

local function sendControl(frag, method, params)
  local socket = frag.launch and frag.launch.socket
  if not socket or not hs.application.get(frag.app.bundle_id) then return false end

  local payload = hs.json.encode({ method = method, params = params or {} })
  if not payload then return false end

  local cmd = string.format(
    "printf '%%s\\n' %s | /usr/bin/nc -U %s",
    string.format("%q", payload),
    string.format("%q", socket)
  )
  hs.task.new("/bin/sh", nil, { "-c", cmd }):start()
  return true
end

local function openActionUrl(frag, action, query)
  local parts = {}
  for key, value in pairs(query or {}) do
    if value ~= nil then table.insert(parts, key .. "=" .. urlEncode(tostring(value))) end
  end
  local suffix = #parts > 0 and ("?" .. table.concat(parts, "&")) or ""
  hs.urlevent.openURL(frag.app.url_scheme .. action .. suffix)
end

local function toggle(frag)
  if sendControl(frag, "toggle") then return end
  openActionUrl(frag, "toggle")
end

-- Launch/focus shade-next prefilled with `text` (optionally routed).
-- Reuses a running instance via the control socket; otherwise opens the
-- shade-next:// URL (which launches the app, then prefills).
local function prefill(frag, text, route, focus)
  if sendControl(frag, "prefill", { text = text or "", route = route, focus = focus ~= false }) then return end
  openActionUrl(frag, "prefill", { text = text or "", route = route, focus = focus and "1" or "0" })
end

local function fallbackContextText()
  local app = hs.application.frontmostApplication()
  if app and app:bundleID() == "io.shade.next" then app = nil end
  local win = hs.window.frontmostWindow()
  local lines = { "Context:" }
  if app then
    table.insert(lines, "- App: " .. (app:name() or "Unknown"))
    if app:bundleID() then table.insert(lines, "- Bundle: " .. app:bundleID()) end
  end
  if win and win:title() and win:title() ~= "" then
    table.insert(lines, "- Window: " .. win:title())
  end
  table.insert(lines, "")
  table.insert(lines, "")
  return table.concat(lines, "\n")
end

local function quickCaptureNote(frag, withContext)
  -- shade-next owns context gathering. Hammerspoon only passes a lightweight
  -- fallback because it sees the frontmost app before shade-next is focused.
  local fallback = withContext and fallbackContextText() or nil
  if sendControl(frag, "captureNote", { context = withContext, fallback_context = fallback, focus = true }) then return end
  prefill(frag, fallback or "", "note", true)
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
  local mode = require("hypemode").new("shade-next", {
    autoExit = 1,
    dim = false,
  }):start()

  -- hyper+enter -> launch/toggle shade-next through its native control channel.
  hyper:bind({}, "return", nil, function() toggle(frag) end)
  U.log.i("shade-next: bound hyper+return -> toggle " .. frag.app.bundle_id)

  -- hyper+shift+n -> new quick-capture note.
  hyper:bind({ "shift" }, "n", nil, function() quickCaptureNote(frag, false) end)
  U.log.i("shade-next: bound hyper+shift+n -> quick capture note")

  -- hyper+ctrl+n -> new context-filled quick-capture note.
  hyper:bind({ "ctrl" }, "n", nil, function() quickCaptureNote(frag, true) end)
  U.log.i("shade-next: bound hyper+ctrl+n -> context quick capture note")

  -- hyper+n -> enter shade-next route modal.
  hyper:bind({}, "n", nil, function() mode:toggle() end)
  U.log.i("shade-next: bound hyper+n -> route modal")

  -- Modal prefill chords: hyper+n,p -> pi route; hyper+n,n -> note route.
  for _, p in ipairs(frag.prefills or {}) do
    mode:bind(p.mods or {}, p.key, function()
      prefill(frag, p.text or "", p.route, p.focus ~= false)
      mode:exit(0.1)
    end)
    U.log.i("shade-next: bound hyper+n," .. p.key .. " -> prefill " .. (p.route or ""))
  end

  return self
end

return M
