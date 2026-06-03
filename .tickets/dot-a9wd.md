---
id: dot-a9wd
status: open
deps: []
links: []
created: 2026-06-03T20:10:24Z
type: epic
priority: 1
assignee: Seth Messer
tags: [ready-for-development]
---

# Rewrite pinvim around Nvim-owned Pi sessions and Pi→Nvim editor service

Replace ephemeral/tmux-owned pinvim architecture with explicit Nvim-owned durable main session, registry-as-source-of-truth, and a separate Pi→Nvim editor service.

Plan: ~/.local/share/pi/plans/.dotfiles/pinvim-rewrite_PLAN.md
Branch: pinvim-rewrite (worktree at ~/.dotfiles/.worktrees/pinvim-rewrite)
Supersedes deprecated epic dot-dylm.

## Acceptance Criteria

1. All 16 plan steps land as child tickets and pass their verify commands
2. bin/pinvim-protocol-smoke passes
3. just home and just validate pass
4. lat.md/ updated and lat_check passes
5. main session reuse, child split isolation, and nested Pi safety all manually verified
