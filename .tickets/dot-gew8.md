---
id: dot-gew8
status: open
deps: [dot-3t42]
links: []
created: 2026-05-18T13:46:06Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-dylm
tags: [ready-for-development]
---

# Split ntfy/Telegram notification semantics from pinvim socket ingress

Move Telegram conversation suppression and ~/bin/ntfy integration ownership out of ad-hoc bridge/pinvim ingress coupling. Define stable inbound marker or metadata so notify behavior survives bridge.ts removal.

## Acceptance Criteria

ntfy/notify extension owns Telegram suppression state; exact inbound Telegram message format is documented; ~/bin/ntfy outbound Telegram path remains working; pinvim.ts does not need Telegram-specific notification semantics.
