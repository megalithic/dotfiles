---
id: dot-wjlb
status: open
deps: [dot-0b8n]
links: []
created: 2026-06-30T16:21:35Z
type: task
priority: 2
assignee: [REDACTED]
tags: [ready-for-development]
---

# Validate dotfiles integration after helium changes

Run narrow validation after all dotfiles changes from tickets dot-gx9h, dot-wu29, dot-kjtr, dot-gvyg, dot-0b8n are complete.

Commands:

1. just validate home — nix evaluation must succeed
2. If activation scripts changed, run just home and monitor output (use PTY)
3. Verify no result symlink remains in repo root
4. Launch Helium via fish helium function — verify it starts with remote debugging on port 9223
5. CDP attach: try connecting chrome-devtools MCP to port 9223

If validation fails: diagnose and fix. Do not proceed to release ticket (dot-??) until this passes.

No code changes expected in this ticket — it's a verification gate. But if justfile recipes need adjustment for the new package shape, those go here.

## Acceptance Criteria

1. just validate home succeeds
2. No result symlink in repo root
3. Helium launches from /Applications with remote debugging on port 9223
4. CDP attach to port 9223 works
5. Any activation failures are diagnosed and fixed
