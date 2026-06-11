---
id: dot-o6bg
status: closed
deps: 4:1:deps: [, dot-satx]
links: []
created: 2026-06-11T11:38:03Z
type: feature
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Restrict automatic pinvim socket resolution

Remove broad automatic socket adoption from normal Nvim sends while preserving manual discovery. File hints: config/nvim/lua/pinvim.lua (Transport.resolve_socket, Transport.list_targets, :PiSessions, :PiTarget, doctor/status socket display). Automatic path should allow explicit PI_SOCKET, buffer target socket, and own registry main socket only.

## Acceptance Criteria

1. Normal Nvim actions do not auto-select manifest-ranked, tmux, or default sockets
2. :PiSessions and :PiTarget still list or select discovered manifest targets manually
3. Without an own registry socket, Nvim proceeds to pimux launch/claim instead of attaching to unrelated sockets
4. Existing pinvim behavior still validates with devenv shell -- just validate home
