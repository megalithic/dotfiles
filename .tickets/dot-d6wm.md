---
id: dot-d6wm
status: closed
deps: [dot-3t42]
links: []
created: 2026-05-18T13:46:06Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Add Hammerspoon ingress extension for Telegram-to-pi routing

Replace current Hammerspoon Telegram forwarding dependence on pinvim/bridge-compatible socket handling with a focused hs.ts ingress extension. Preserve config/hammerspoon/lib/interop/pi.lua behavior: last active session/window, non-ephemeral socket targeting, JSON response parsing, and Telegram source metadata.

## Acceptance Criteria

hs.ts or agreed equivalent owns Hammerspoon-originated inbound messages; config/hammerspoon/lib/interop/pi.lua no longer documents bridge.ts as owner; Telegram forwarding works without pinvim.ts telegram compatibility handler; ephemeral sockets are not auto-selected; tests or smoke command document the socket payload.
