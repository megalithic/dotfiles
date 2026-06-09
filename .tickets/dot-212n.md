---
id: dot-212n
status: closed
deps: 4:1:deps: [, dot-xwa4]
links: []
created: 2026-06-09T15:10:56Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Run shade-next dogfood pass and migration-readiness checks

After prior implementation tickets land, run end-to-end dogfood validation across app repo and dotfiles integration. Confirm current shade still works, shade-next launcher/composer/history states work, and migration-readiness metadata/path assumptions hold. File hints: ~/code/shade-next, ~/.dotfiles/home/common/programs/shade-next/default.nix, Hammerspoon files, and note/capture integration references.

## Acceptance Criteria

1. Dogfood validation covers compact launcher, expanded composer, and history/results states.
2. Current shade remains usable alongside shade-next during transition.
3. Migration-readiness notes cover app namespace, schema version, created_by, and path assumptions.
4. Validation includes commands run plus screenshots or manual notes for key UI states.
5. Any residual risks are captured explicitly for follow-up tickets.
