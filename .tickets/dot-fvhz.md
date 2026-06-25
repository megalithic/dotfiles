---
id: dot-fvhz
status: open
deps: []
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Verify Worktrunk fish and JSON runtime contract

Verify the current Worktrunk runtime contract before changing Home Manager fish config. Inspect generated fish integration (`wt config shell init fish`), current `~/.config/fish/config.fish` ordering, and local `wt switch` JSON output. Capture notes in the ticket so later implementation preserves Worktrunk directive behavior and knows the `branch`/`path` schema.

File hints: `home/common/programs/worktrunk/default.nix`, `home/common/programs/fish/default.nix`, generated `~/.config/fish/config.fish`, installed Worktrunk fish integration, `~/.local/share/pi/plans/.dotfiles/worktrunk-smart-hooks_PLAN.md`.

## Acceptance Criteria

1. `wt config shell init fish` is inspected and relevant directive-file behavior is noted.
2. `wt switch @ --no-cd --no-hooks --format=json` output is captured and confirms usable `branch` and `path` fields or documents required parser adjustment.
3. Current fish config ordering is inspected without editing generated files directly.
4. If no-arg picker JSON cannot be safely verified non-interactively, the ticket notes exactly how to verify it manually later.
