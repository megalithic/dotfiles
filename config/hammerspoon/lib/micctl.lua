--- micctl - control the miccheck menubar app (miccheckd) over its unix socket.
--- Replaces the in-process require("miccheck").setPTTMode(...) calls.
---
--- Socket: ~/.local/state/miccheck/sock, line-delimited JSON.
--- Commands: {"cmd":"set-mode","mode":"push-to-talk"|"push-to-mute"},
---           {"cmd":"toggle-mode"}, {"cmd":"get"}, {"cmd":"quit"}

local M = {}

local SOCK = os.getenv("HOME") .. "/.local/state/miccheck/sock"

---@param payload table command table, e.g. { cmd = "set-mode", mode = "push-to-talk" }
function M.send(payload)
  local ok, json = pcall(hs.json.encode, payload)
  if not ok or not json then return end
  -- JSON contains only double quotes; single-quoted shell string is safe.
  local cmd = string.format("printf '%%s\\n' '%s' | /usr/bin/nc -w 1 -U '%s'", json, SOCK)
  hs.task.new("/bin/sh", nil, { "-c", cmd }):start()
end

---@param mode "push-to-talk"|"push-to-mute"
function M.setPTTMode(mode) M.send({ cmd = "set-mode", mode = mode }) end

function M.toggleMode() M.send({ cmd = "toggle-mode" }) end

return M
