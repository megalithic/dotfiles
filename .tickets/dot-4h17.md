---
id: dot-4h17
status: closed
deps: 4:1:deps: [, dot-vo8t]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Implement explicit prefix router and route tests

In ~/code/shade-next, implement deterministic routing for note:, reminder:, event:, calc:, pi:, and search:. Encode route priority after explicit prefixes and add tests for prefix handling plus fallback behavior. File hints: router and preview/result model code under ~/code/shade-next/Sources/ with tests under ~/code/shade-next/Tests/. Use ~/.local/share/pi/plans/.dotfiles/shade-next_TASK.md as routing source of truth.

## Acceptance Criteria

1. Explicit prefixes note:, reminder:, event:, calc:, pi:, and search: resolve deterministically in tests.
2. Route priority beyond explicit prefixes is encoded in code or tests, not left implicit.
3. Fallback note route is covered by tests.
4. Mutation routes expose preview/confirmation hooks instead of publishing immediately.
5. Existing tests still pass.
