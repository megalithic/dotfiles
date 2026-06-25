---
id: dot-6urx
status: open
deps: [dot-5095]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Validate smart Worktrunk wrapper end to end

Run final build, activation, docs, and runtime checks for the smart Worktrunk wrapper. This ticket should verify Home Manager builds/applies, lat docs pass, normal Worktrunk behavior still works, and tmux target flows work inside and outside tmux where practical.

File hints: `justfile`, `home/common/programs/worktrunk/default.nix`, `home/common/programs/fish/functions.nix`, `home/common/programs/fish/completions.nix`, `bin/wt-tmux-target`, `bin/wt-tail-logs`, `lat.md/home-configs.md`.

## Acceptance Criteria

1. `devenv shell -- just validate home` passes.
2. `devenv shell -- just home` completes successfully after Home Manager changes.
3. `lat check` passes.
4. Fresh fish shell verifies `wt switch @`, `wt @`, `wt list`, `wt config show`, and `wt hook show`.
5. Tmux checks verify `wt switch -t session @`, `wt -t session @`, inside-tmux `wt switch -t window @` reuse, and outside-tmux window-to-session fallback, or document any manual checks that cannot be automated.
