# pkgs/ — Custom package derivations

## Overview

Custom overlay packages exposed via `pkgs.*` throughout the configuration.

## Key files

- `default.nix` — Overlay entry point, defines all custom packages
- Individual app derivations use `lib.mega.mkApp` for macOS .app bundles

## mkApp pattern

`mkApp` builds .app bundles from various sources (DMG, ZIP, PKG, binary).

Options:
- `appLocation`: "home-manager" (default), "symlink", or "copy"
- `src`: fetchurl derivation
- `format`: "dmg", "zip", "pkg", "binary"

## When to use what

| Source | Use case |
|--------|---------|
| `pkgs/` (mkApp) | macOS apps not in nixpkgs or homebrew |
| `modules/brew.nix` | Apps needing cask install (accessibility, kernel extensions) |
| `home/common/packages.nix` | CLI tools from nixpkgs |
| `home/common/programs/*.nix` | CLI tools that need HM config |
