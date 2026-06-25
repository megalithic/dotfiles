---
id: dot-963m
status: open
deps: [dot-z5k8]
links: []
created: 2026-06-25T20:12:53Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Add implicit switch and target parsing to wt fish wrapper

Add smart argument normalization to the Home Manager-managed fish `wt` function. Implement implicit switch (`wt foo` -> `wt switch foo`) when no known Worktrunk command is present, and parse local `-t/--target window|session` before invoking the real Worktrunk binary.

File hints: `home/common/programs/fish/functions.nix`. Use findings from the runtime verification ticket for JSON/directive details.

## Acceptance Criteria

1. Known Worktrunk commands (`switch`, `list`, `remove`, `merge`, `select`, `step`, `hook`, `config`) and help/version flags pass through without becoming implicit switches.
2. `wt @` normalizes to switch behavior and preserves normal cwd-changing semantics.
3. `wt -t session @`, `wt switch -t session @`, and `wt @ -t session` strip local target flags and select target mode.
4. Invalid target values print a clear error and return nonzero.
5. Non-target mode preserves upstream directive behavior from the local wrapper.
