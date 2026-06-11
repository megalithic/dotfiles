---
id: dot-ubjx
status: closed
deps: 4:1:deps: [, dot-eb3t]
links: []
created: 2026-06-11T11:38:03Z
type: task
priority: 2
assignee: Seth Messer
parent: dot-a9wd
tags: [ready-for-development]
---

# Validate strict pinvim pairing end to end

Run final build, doc, and manual E2E checks for strict pairing. File hints: no code changes expected; use task context and pinvim-kitty-test skill if helpful for real Nvim/Pi/tmux matrix.

## Acceptance Criteria

1. devenv shell -- just validate home passes
2. lat_check passes
3. Manual same-window A/B strict pairing matrix passes: A opens Pi A; B opens/uses Pi B, not Pi A
4. Dead/stale same-window claim and live mismatch reject/spawn-own behavior are verified
5. Other tmux window/session and non-tmux strict fallback behavior are verified
6. shade-next fill_prompt and :PiTarget ownership-neutral behavior are verified
