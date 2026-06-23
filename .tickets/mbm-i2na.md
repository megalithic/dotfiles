---
id: mbm-i2na
status: open
deps: []
links: []
created: 2026-06-23T14:08:01Z
type: feature
priority: 2
assignee: Seth Messer
tags: [mise, migration, nix]
---

# Prototype megalithic/flakes repo for mise nix backend consumption

Create a separate Nix flakes repository at github.com/megalithic/flakes to hold custom packages currently in pkgs/default.nix that are too complex for Brew/scripts. Consumed by the jbadeau/mise-nix plugin via flake references in mise.toml.

Packages to migrate:

- helium (Widevine-patched browser with custom wrapper)
- kanata + kanata-bar (TCC-sensitive binary + app + sudoers + launchd)
- Other custom packages: brave-browser-nightly, bloom, slk, handy, tidewave, tidewave-cli, chrome-devtools-mcp, whisperkit-cli

Mise usage:
[tools]
"nix:helium@github+megalithic/flakes#helium" = "latest"

Benefits:

- Keeps Nix for complex package builds (Widevine patching, TCC stability, app wrappers)
- Lets mise orchestrate install/update
- Removes these from dotfiles flake, simplifying nix-darwin/HM activation
- Single source of truth for custom app derivations

## Acceptance Criteria

1. github.com/megalithic/flakes repo created with flake.nix exposing packages for helium, kanata, and kanata-bar.
2. jbadeau/mise-nix plugin installed: mise plugin install nix https://github.com/jbadeau/mise-nix.git
3. At least one package verified: mise install "nix:helium@github+megalithic/flakes#helium" succeeds.
4. Custom packages removed from pkgs/default.nix in dotfiles repo (post-validation).
5. mise.toml [tools] updated to reference flakes for migrated packages.
6. lat.md/flakes.md documents the new repo, package list, and mise-nix usage.
