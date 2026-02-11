# bin/ — User scripts

## Overview

Shell scripts symlinked to `~/bin/` via home-manager's `linkBin` helper.

## Conventions

- Scripts should be executable (`chmod +x`)
- Prefer bash or fish; use `#!/usr/bin/env bash` shebang
- Keep scripts focused (single purpose)
- Use `~/bin/ntfy` for notifications (handles routing automatically)

## Key scripts

- `darwin-switch` — Wrapper for `nh darwin switch` with pre/post hooks
- `ntfy` — Notification routing (Telegram, macOS alerts)
- `pinvim` / `pisock` — Pi coding agent wrappers with socket support

## Nix management

These files live in `~/.dotfiles/bin/` (source of truth).
Home-manager symlinks them to `~/bin/` via `config.lib.mega.linkBin`.
Changes take effect immediately (out-of-store symlink).
