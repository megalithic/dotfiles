---
id: dot-76p7
status: open
deps: [dot-963m]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add fish completions for smart Worktrunk switch

Add fish completions for the smart Worktrunk wrapper. Completion should suggest available Worktrunk worktree branches for explicit and implicit switch forms and complete local target values for `-t/--target`, without hiding existing Worktrunk subcommands.

File hints: `home/common/programs/fish/completions.nix`, `home/common/programs/fish/functions.nix`, `wt list --format=json`.

## Acceptance Criteria

1. A fish helper emits existing worktree branch candidates from `wt list --format=json` without using `--full`.
2. `wt switch <TAB>` offers worktree branch completions.
3. `wt -t session <TAB>` and `wt --target session <TAB>` offer worktree branch completions.
4. `-t` and `--target` complete `window` and `session`.
5. Existing Worktrunk subcommands remain available in first-token completion.
