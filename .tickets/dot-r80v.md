---
id: dot-r80v
status: closed
deps: 4:1:deps: [, dot-83dr]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Add visual tuning config schema and defaults

In ~/code/shade-next, expose low-friction visual tuning for default launcher/composer shell. Cover at minimum font family, font size, line height if supported, panel padding, compact sizing, expanded sizing, and cheap row density/corner radius knobs. Keep defaults visually close to target Raycast-like shell. File hints: config schema files, app settings model, and shell styling code under ~/code/shade-next/Sources/.

## Acceptance Criteria

1. Config surface exposes font family and font size.
2. Config surface exposes panel padding plus compact and expanded sizing.
3. If supported cheaply, row density/spacing and corner radius are also configurable; if not, ticket note explains deferral.
4. Default values produce visually close launcher/composer shell without code edits.
5. Verification shows how a user changes at least one visual setting without rebuilding app code.
