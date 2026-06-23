---
id: mbm-9ov0
status: open
deps: 4:1:deps: 4:1:deps: 4:1:deps: 4:1:deps: 4:1:deps: [, mbm-55qf, mbm-qkmx, mbm-8afn, mbm-buez, mbm-c3sd]
links: [mbm-buez, mbm-c3sd, mbm-ju5m, mbm-xqjv, mbm-m0rs, mbm-55qf, mbm-8afn, mbm-qkmx, mbm-77a2, mbm-sskn, mbm-s5i1]
created: 2026-06-22T21:33:36Z
type: feature
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Design and implement one-command mise bootstrap v1

Replace the README Nix-first installation path with a Mac-first one-command bootstrap once the preflight and critical blockers are ready. The command should be pasteable into Terminal.app, support fresh and partial systems, and repair or clearly report broken setup. File hints: README.md, scripts/install.sh, scripts/aarch64-darwin_bootstrap.sh, scripts/mise/bootstrap-final, scripts/mise/doctor, scripts/mise/ensure-determinate-nix, scripts/mise/ensure-homebrew, mise.toml.

## Acceptance Criteria

1. README documents a single curl/bash command for the mise migration bootstrap, with warnings and expected prompts.
2. Bootstrap detects hostname, prompts to confirm/correct megabookpro or workbookpro, and sets ComputerName, HostName, and LocalHostName.
3. Bootstrap detects Command Line Tools and EULA/MAS gates, automates safe parts, and clearly reports manual gates.
4. Bootstrap supports fresh and partially installed systems by running preflight before mutation and reporting conflicts.
5. Bootstrap is safe to rerun: repeated runs are idempotent or produce clear no-op/manual reports.
6. Mac-first v1 is explicit; UGREEN NAS and Raspberry Pi/Home Assistant are documented as future platform goals, not blockers.
7. No destructive bootstrap is run during implementation without explicit user approval.
