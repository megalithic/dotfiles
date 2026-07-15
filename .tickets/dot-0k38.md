---
id: dot-0k38
status: open
deps: [dot-89d2, dot-zqvf]
links: []
created: 2026-07-15T17:04:41Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [sentinel, extensions, validation, ready-for-development]
---

# Validate Sentinel simplification, docs, and mise mirror

Finish the Sentinel simplification by validating runtime behavior, docs, and the mise twin after classifier refactor work lands. Use ~/.local/share/pi/plans/.dotfiles/sentinel-simplification_PLAN.md as context. Relevant files: home/common/programs/pi-coding-agent/extensions/sentinel.ts, mise/config/pi-coding-agent/agent/extensions/sentinel.ts, lat.md/programs/pi-coding-agent.md, home/common/programs/pi-coding-agent/default.nix.

## Acceptance criteria

1. Home Manager Sentinel extension and mise twin have equivalent contents after simplification.
2. lat.md/programs/pi-coding-agent.md describes the classifier-based design, removed git-to-jj rewrite, managed-config framing, and softer package-install wording.
3. devenv shell -- lat check passes.
4. just validate home passes.
5. After activation, pi --help reports a substantially lower Sentinel rule count than 58.
6. Manual spot checks cover one hard block, one confirm override, one preferred-tool rewrite, and one allowed Git command.

