---
id: dot-piht
status: closed
deps: [dot-3fyc]
links: []
created: 2026-04-14T19:46:57Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-kts9
tags: [ready-for-development]
---
# Update Hammerspoon pi.lua: replace nc with hs.socket.new() for bidirectional comms

Migrate Hammerspoon's pi interop from fire-and-forget nc to persistent
bidirectional socket connection using hs.socket.new().

## Changes

- Replace io.popen nc calls with hs.socket.new() persistent connection
- Parse JSON responses from bridge.ts
- Handle connection lifecycle (connect, disconnect, reconnect)
- Keep existing: session targeting, Telegram forwarding, socket discovery
- Add connection status tracking (for HUD/menubar display)

## Key files

- config/hammerspoon/lib/interop/pi.lua

## Current approach (replace)

local function sendToSocket(socketPath, payload)
  local json = hs.json.encode(payload)
  local cmd = string.format("echo '%s' | nc -U %s", json, socketPath)
  hs.execute(cmd)
end

## New approach

local socket = hs.socket.new()
socket:connect(socketPath, function()
  socket:write(json .. '\n')
  socket:read('\n', function(data)
    local response = hs.json.decode(data)
    -- handle ok/error
  end)
end)

## Acceptance Criteria

1. Hammerspoon pi.lua uses hs.socket.new() instead of nc/io.popen
2. JSON responses parsed from bridge.ts
3. Connection auto-reconnects on loss
4. Telegram message forwarding still works
5. Tell/delegate message forwarding still works
6. Session targeting still works (lastActiveSession)
7. No nc or io.popen calls remain in pi.lua

