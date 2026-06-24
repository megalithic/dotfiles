---
id: mbm-z03i
status: open
deps: []
links: []
created: 2026-06-23T23:50:42Z
type: feature
priority: 2
assignee: Seth Messer
tags: [mise, migration, hostname]
---

# Implement hostname-based configuration for mise bootstrap

Currently install.sh detects and sets hostname but applies identical config to all machines. We need per-hostname overrides for packages, dotfiles, defaults, and launchd agents.

Pattern options (from research):

- Platform branching (macOS/Linux distro) — AllySummers uses case/esac on uname + /etc/os-release
- Hostname branching — our need: megabookpro vs workbookpro
- Mise config includes — if mise supports merging multiple config files

Required for v1:

- llama.cpp tuning: different model params per host (memory/GPU differences)
- WORK_ENV_VARS_SH secret: workbookpro only
- Future: platform support (Linux, Raspberry Pi)

Implementation likely uses either:
a) scripts/mise/ that branch on hostname -s
b) mise.<hostname>.toml override files
c) Host-specific dotfile variants (e.g., mise/dotfiles/fish.<hostname>/)

File hints: scripts/install.sh, mise.toml, scripts/mise/llama-server-launchd, scripts/mise/render-fnox-files

## Acceptance Criteria

1. Hostname detection in install.sh is preserved and drives config selection.
2. At least one host-specific override exists (llama.cpp params or work secrets).
3. Per-host config is documented in lat.md/migration/mise-bootstrap.md.
4. Non-macOS platforms are documented as future goals with the same pattern.
