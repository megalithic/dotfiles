---
id: dot-42gl
status: open
deps: []
links: []
created: 2026-04-15T16:35:34Z
type: epic
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---
# Refactor AGENTS.md: slim GLOBAL, deduplicate, add core principles

GLOBAL_AGENTS.md is ~450 lines, loaded into every pi session across every project.
~250 lines are system-specific (Hammerspoon, Telegram, IEx, nix-darwin details).
~200 lines are duplicated between GLOBAL and repo AGENTS.md.
Missing behavioral principles (read before edit, verify before done, investigate before fix).

Audit doc: /tmp/agents-md-audit.html
Session context: inline comments > AGENTS.md for file-specific rules.

Goal: GLOBAL ~150 lines (universal only), repo AGENTS.md ~200 lines (repo-specific only),
zero duplication, core principles as opening section, system-specific content relocated
to proper homes.

