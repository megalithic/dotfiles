---
id: dot-ol5u
status: closed
deps: 4:1:deps: [, dot-4h17]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Build adaptive panel shell scaffold

In ~/code/shade-next, build initial app shell for centered floating panel with compact launcher, expanded composer, and shared results/history region. Use placeholder content where needed, but preserve keyboard-first layout assumptions from plan. File hints: SwiftUI/AppKit shell files under ~/code/shade-next/Sources/ plus any app-window configuration files. Reference current look-and-feel requirement in ~/.local/share/pi/plans/.dotfiles/shade-next_TASK.md.

## Acceptance Criteria

1. App opens in a centered floating shell visually aimed at Raycast-like compact launcher proportions.
2. Shell can represent compact and expanded states without switching to separate window architecture.
3. Results/history region exists in the same shell, even if backed by placeholder data initially.
4. Focus defaults to input region on open.
5. Verification includes screenshots or notes for compact and expanded shell states.
