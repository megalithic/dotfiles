---
id: dot-83dr
status: closed
deps: 4:1:deps: [, dot-ol5u]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Spike Nvim editor embedding and choose adapter

Evaluate and implement first working editor embedding path for shade-next. Compare current Shade/GhosttyKit approach, libghostty-spm, and external Nvim process with socket if needed. Deliver working scratch-buffer embedding with insert-mode startup and app-level key interoperability. File hints: ~/code/shade-next/Sources/ editor adapter modules; reference current integration in ~/.dotfiles/config/hammerspoon/lib/interop/shade.lua and ~/.dotfiles/docs/skills/shade/SKILL.md.

## Acceptance Criteria

1. Chosen embedding path is documented in code comments, ticket note, or lightweight design note.
2. Embedded Nvim scratch buffer launches reliably and starts in insert mode.
3. <Enter> and <Esc> remain normal Nvim keys inside the embedded editor.
4. App-level commands for commit/search/copy remain possible around the embedded editor.
5. Verification includes commands run plus manual notes about focus behavior and input lag.
