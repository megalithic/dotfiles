---
id: dot-l4fn
status: open
deps: [dot-963m, dot-184v, dot-r9fx]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Wire wt target mode to Worktrunk JSON and tmux

Wire fish target mode to Worktrunk JSON output and the tmux helper. In target mode, the fish wrapper should run `wt switch --format=json --no-cd` with hooks enabled, parse the resulting branch/path, and dispatch to `wt-tmux-target` without changing the current shell cwd.

File hints: `home/common/programs/fish/functions.nix`, `bin/wt-tmux-target`, `bin/wt-tail-logs`.

## Acceptance Criteria

1. Target mode invokes the real Worktrunk switch with `--format=json --no-cd` and keeps hooks enabled by default.
2. JSON parsing extracts branch and path robustly, including when Worktrunk emits human text before JSON or fails with an error.
3. Missing or malformed JSON prints clear diagnostic output and does not cd blindly.
4. `wt switch -t session @` and `wt -t session @` open/switch tmux session rooted at the worktree.
5. `wt switch -t window @` works inside tmux and degrades to session behavior outside tmux.
