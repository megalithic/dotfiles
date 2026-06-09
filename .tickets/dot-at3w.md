---
id: dot-at3w
status: open
deps: 4:1:deps: [, dot-mv1h]
links: []
created: 2026-06-09T15:10:55Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development, shade-next]
---

# Implement explicit search mode and sectioned results

In ~/code/shade-next, add explicit search mode backed by SQLite FTS for Shade-managed data and rg-backed search for vault markdown. Present drafts, history, and vault hits in sectioned results inside same adaptive shell. File hints: search modules and result view code under ~/code/shade-next/Sources/; vault search reference via rg and note paths from ~/.dotfiles.

## Acceptance Criteria

1. Search mode is explicit and does not conflict with action routing.
2. SQLite FTS covers Shade-managed text such as drafts/history or equivalent internal records.
3. Vault markdown search uses rg or a documented equivalent lexical search path.
4. Results render in clear sections inside existing panel shell.
5. Verification demonstrates at least one result from internal Shade data and one from vault markdown, or documents any temporary fixture-based substitute.
