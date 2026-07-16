---
id: dot-zqvf
status: closed
deps: [dot-89d2]
links: []
created: 2026-05-13T14:27:58Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [sentinel, extensions, auto-fix, ready-for-development]
---

# Keep Sentinel preferred-tool rewrites and remove git-to-jj rewrite

Update Sentinel rewrite behavior to keep only preferred-tool rewrites that still match current repo policy. Keep `grep → rg`, `find → fd`, `rm/rmdir → trash`, and `python -m json.tool → jq`. Remove the old `git → jj` rewrite so Sentinel is Git-first again.

Relevant code:

- `home/common/programs/pi-coding-agent/extensions/sentinel.ts`
- `mise/config/pi-coding-agent/agent/extensions/sentinel.ts`
- `lat.md/programs/pi-coding-agent.md`

Acceptance criteria:

1. `git` commands are no longer blocked or rewritten to `jj` in JJ repositories.
2. `grep`, `find`, `rm`, and `rmdir` still trigger preferred-tool rewrite guidance, including wrapped forms handled by Sentinel parsing.
3. `python -m json.tool` and `python3 -m json.tool` still suggest `jq .`.
4. Rewrite handling is represented as one conceptual classifier where practical, not one runtime rule per command.
5. Existing safety confirms for `git push`, `jj git push`, and destructive history-changing VCS commands remain.
6. Mise twin matches the Home Manager extension after implementation.
7. `devenv shell -- lat check` passes if lat docs change, and `just validate home` passes after extension changes.
