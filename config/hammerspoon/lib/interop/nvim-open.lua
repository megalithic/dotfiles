-- Nvim Open: high-level "open file at line in best running nvim" policy.
--
-- Used by:
--   * hammerspoon://nvim-open URL handler (PLUG_EDITOR / Phoenix dev errors,
--     LiveView devtools "open in editor", browser stacktrace links)
--   * any caller that wants to surface a file:line in the user's current nvim
--
-- Resolution priority (no session param required from caller — it's the wrong
-- signal anyway, since URLs are baked at server-startup time):
--   1. nvim socket where the file is already loaded as a buffer
--   2. nvim socket whose tmux session matches the most-recently-active client
--   3. most-recently-active nvim socket by mtime (any session)
--   4. none — log + bail (no spawn fallback)
--
-- Depends on lib/interop/nvim.lua for low-level RPC primitives.
local nvim = require("lib.interop.nvim")

local M = {}
local fmt = string.format

M.name = "interop.nvim-open"

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

-- PATH prefix for shell commands (Hammerspoon doesn't inherit nix PATH)
local function pathPrefix()
  return PATH and ("PATH='" .. PATH .. "' ") or ""
end

-- Decode percent-encoded URL string (and `+` -> space).
-- Defensive: hs.urlevent already decodes params, but Phoenix's PLUG_EDITOR
-- substitution may double-encode or pass odd chars. Idempotent for plain ASCII.
local function urlDecode(s)
  if not s then return nil end
  s = s:gsub("+", " ")
  s = s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
  return s
end

-- Vim single-quoted string literal with `'` escaped as `''`.
local function vimStr(s)
  return "'" .. s:gsub("'", "''") .. "'"
end

-- Most recently active tmux session across all clients. Returns name or nil.
local function activeTmuxSession()
  local handle = io.popen(pathPrefix() ..
    "tmux list-clients -F '#{client_activity} #{client_session}' 2>/dev/null " ..
    "| sort -rn | head -1 | awk '{print $2}'")
  if not handle then return nil end
  local sess = handle:read("*l")
  handle:close()
  return (sess and sess ~= "") and sess or nil
end

-- Check whether a given nvim instance already has `file` loaded as a buffer.
local function nvimHasFileOpen(socket, file)
  local expr = fmt("bufnr(fnamemodify(%s, ':p'))", vimStr(file))
  local result = nvim.eval(socket, expr)
  return result ~= nil and result ~= "-1"
end

-- Pick the best nvim socket to open `file` in.
-- Returns SocketInfo|nil and a reason string for logging.
local function pickNvimSocket(file)
  local all = nvim.getSockets()
  if next(all) == nil then return nil, "no-sockets" end

  -- 1. file already open
  for _, info in pairs(all) do
    if nvimHasFileOpen(info.socket, file) then
      return info, "file-already-open"
    end
  end

  -- 2. session of most-active tmux client
  local activeSess = activeTmuxSession()
  if activeSess then
    local best, bestMtime = nil, 0
    for id, info in pairs(all) do
      if info.session == activeSess then
        local attrs = hs.fs.attributes(nvim.socketDir .. "/" .. id)
        local m = attrs and attrs.modification or 0
        if m >= bestMtime then
          bestMtime, best = m, info
        end
      end
    end
    if best then return best, "active-tmux-client:" .. activeSess end
  end

  -- 3. most-recent socket by mtime
  local best, bestMtime = nil, 0
  for id, info in pairs(all) do
    local attrs = hs.fs.attributes(nvim.socketDir .. "/" .. id)
    local m = attrs and attrs.modification or 0
    if m >= bestMtime then
      bestMtime, best = m, info
    end
  end
  if best then return best, "most-recent-mtime" end

  return nil, "none"
end

-- Ring tmux bell (BEL to pane tty) on target window.
local function ringBell(target)
  if not (target.session and target.window) then return end
  hs.execute(fmt(
    "%stty=$(tmux display -p -t %s:%d '#{pane_tty}' 2>/dev/null) && printf '\\a' > \"$tty\" 2>/dev/null",
    pathPrefix(), target.session, target.window
  ))
end

-- Raise Ghostty + switch tmux client to the resolved session.
local function focusSession(target)
  local ghostty = hs.application.get("Ghostty")
  if ghostty then ghostty:activate() end
  if target.session then
    hs.execute(fmt("%stmux switch-client -t %s", pathPrefix(), target.session))
  end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Open a file at a given line in the most relevant running nvim instance.
--- Programmatic entry point — callable from URL handlers, hotkeys, Spoons, etc.
---@param file string Absolute file path
---@param line number|nil Line number (defaults to 1)
---@return boolean ok, string reason
function M.open(file, line)
  if not file or file == "" then
    return false, "missing-file"
  end
  line = tonumber(line) or 1

  local target, reason = pickNvimSocket(file)
  if not target then
    U.log.ef("[%s] No running nvim found (%s) — not spawning. file=%s line=%d",
      M.name, reason, file, line)
    return false, reason
  end

  U.log.f("[%s] Resolved nvim via %s: session=%s window=%s pane=%s pid=%d",
    M.name, reason, tostring(target.session), tostring(target.window),
    tostring(target.pane), target.pid)

  -- Open in vertical split via remote-expr. fnameescape handles spaces, %, #
  -- safely; vim '...' string with '' escaping handles single quotes.
  local expr = fmt("execute('vsplit +%d '.fnameescape(%s))", line, vimStr(file))
  local result = nvim.eval(target.socket, expr)
  if result == nil then
    U.log.ef("[%s] eval failed on socket %s", M.name, target.socket)
    return false, "eval-failed"
  end

  U.log.f("[%s] Opened %s:%d in nvim (%s)", M.name, file, line, target.socket)
  ringBell(target)
  focusSession(target)
  return true, reason
end

--- hs.urlevent.bind callback for hammerspoon://nvim-open
--- URL format: hammerspoon://nvim-open?file=/abs/path&line=42
function M.handleURL(_eventName, params, _senderPID, fullURL)
  local file = urlDecode(params.file)
  local line = tonumber(urlDecode(params.line)) or 1

  if not file or file == "" then
    U.log.ef("[%s] Missing file param: %s", M.name, fullURL)
    return
  end

  M.open(file, line)
end

return M
