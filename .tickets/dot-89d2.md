---
id: dot-89d2
status: closed
deps: []
links: []
created: 2026-05-13T14:27:58Z
type: task
priority: 1
assignee: Seth Messer
parent: dot-0fjk
tags: [sentinel, extensions, refactor, ready-for-development]
---

# Collapse Sentinel rules into conceptual classifiers

Refactor `home/common/programs/pi-coding-agent/extensions/sentinel.ts` so Sentinel no longer expands command tables into dozens of per-command runtime rules. Keep one managed extension file and mirror the final source to `mise/config/pi-coding-agent/agent/extensions/sentinel.ts`.

Current runtime loads 58 rules. Target roughly 10–15 conceptual classifier rules while preserving existing safety behavior. Use `~/.local/share/pi/plans/.dotfiles/sentinel-simplification_PLAN.md` as the working plan.

Relevant code:

- `home/common/programs/pi-coding-agent/extensions/sentinel.ts`
- `mise/config/pi-coding-agent/agent/extensions/sentinel.ts`
- `lat.md/programs/pi-coding-agent.md`

Acceptance criteria:

1. Runtime rule count drops substantially from 58 by replacing per-command loop-generated `Rule` objects with classifier rules.
2. Interactive command coverage remains for editors, pagers, REPLs, database shells, Docker/Kubernetes interactive flags, and `nix repl`.
3. Security hard blocks remain for secret tools, gatekeeper secret findings, destructive system/home recursive deletes, and unsafe `nix build` output links.
4. Confirm rules remain for security-sensitive bash, remote effects, destructive history changes, unscoped `tccutil reset`, and package installs.
5. Session write/execute correlation, investigation-mode guard, and pipe/redirect timeout enforcement still work.
6. Mise twin matches the Home Manager extension after implementation.
7. `lat.md/programs/pi-coding-agent.md` documents the classifier-based design and updated runtime rule count.
8. `devenv shell -- lat check` passes if lat docs change, and `just validate home` passes after extension changes.
