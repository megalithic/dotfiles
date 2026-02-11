# lib/ — Nix library functions

## Overview

Custom library extensions exposed as `lib.mega.*` throughout the configuration.

## Key files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point, extends `nixpkgs.lib` with `lib.mega.*` |
| `paths.nix` | Centralized path definitions (home, dotfiles, icloud, etc.) |
| `mkDarwinHost.nix` | Darwin system builder (includes home-manager) |
| `mkHome.nix` | Standalone home-manager builder |
| `mkApp.nix` + `mkApp/` | Custom app derivation builder (DMG/ZIP/PKG) |
| `mkMas.nix` | Mac App Store pseudo-package helper |

## Usage patterns

### paths.nix
```nix
let paths = lib.mega.paths username; in
paths.home       # /Users/seth
paths.dotfiles   # /Users/seth/.dotfiles
paths.notes      # iCloud notes path
```

### mkDarwinHost
```nix
mkDarwinHost { hostname = "megabookpro"; username = "seth"; }
```
- Composes: `hosts/common.nix` + `hosts/<hostname>.nix` + home-manager
- Passes `paths` to all modules via `specialArgs`

### mkHome
```nix
mkHome { hostname = "megabookpro"; username = "seth"; }
```
- Standalone HM: `home-manager switch --flake .#seth@megabookpro`
- Same config as bundled HM in darwin, just independent

### mkApp
- Builds `.app` bundles from DMG/ZIP/PKG/binary sources
- Used in `pkgs/default.nix` for Brave Nightly, Fantastical, etc.
- Options: `appLocation` ("home-manager" | "symlink" | "copy")

## Conventions

- All helper functions go through `lib.mega.*` namespace
- Prefer passing `paths` over computing paths inline
- No NixOS abstractions (darwin-only, YAGNI)
