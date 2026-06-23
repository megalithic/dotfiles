---
id: mbm-nhdu
status: open
deps: 4:1:deps: [, mbm-55qf]
links: []
created: 2026-06-22T20:32:32Z
type: task
priority: 2
assignee: Seth Messer
tags: [ready-for-development]
---

# Harden mise bootstrap scripts for safe repeated runs

Review and harden the imperative scripts that mise will run for behavior it cannot model declaratively. Scripts must be idempotent, host-aware where needed, safe around running apps/services, and clear about privileged or TCC-sensitive operations.

Context: migration chose mise as orchestration, Brew/MAS for apps, fnox for secrets, direct scripts for special cases, and Nix retained only for legacy/project usage.

File hints: scripts/mise/ensure-determinate-nix, scripts/mise/ensure-homebrew, scripts/mise/install-apps, scripts/mise/install-helium, scripts/mise/setup-pi, scripts/mise/install-pi-tools, scripts/mise/llama-server-launchd, scripts/mise/render-fnox-files, scripts/mise/apply-macos-complex-defaults, scripts/mise/doctor.

## Acceptance Criteria

1. Each script starts with strict shell options and gives clear failure messages.
2. Scripts avoid destructive writes unless guarded by checks/backups or explicit confirmation.
3. Host-specific behavior branches only on documented hostnames (`megabookpro`, `workbookpro`) or safe defaults.
4. Helium install path preserves the migration constraints: upstream release + local script, Widevine handling, signing/TCC safety, and no reinstall while app is running.
5. `scripts/mise/doctor` checks prerequisites and reports missing tools/config without mutating state.
6. Relevant docs in lat.md/migration/mise-bootstrap.md stay in sync; `lat_check` passes.
