---
id: dot-184v
status: open
deps: [dot-fvhz]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add tmux target helper for Worktrunk worktrees

Create the tmux navigation helper used by Worktrunk target mode. The helper should create or reuse a per-worktree tmux session with `code` and `services` windows, create/reuse current-session windows for window target, and degrade window target to session behavior outside tmux.

File hints: new `bin/wt-tmux-target`, existing `bin/ftm` for tmux style/reference, `lat.md/home-configs.md` tmux layout notes.

## Acceptance Criteria

1. `bin/wt-tmux-target --target session --branch <branch> --path <path>` creates or reuses a tmux session rooted at the worktree path.
2. Session target ensures `code` and `services` windows exist without duplicating them on repeated runs.
3. Inside tmux, session target switches the current client; outside tmux, it attaches or creates the session.
4. Window target inside tmux creates/selects one current-session window rooted at the worktree path and reuses it on repeated runs.
5. Window target outside tmux delegates to session behavior.
