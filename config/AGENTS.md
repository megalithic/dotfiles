# config/ — Out-of-store application configs

## Overview

Application configurations that are symlinked (not copied) into place.
Changes take effect immediately without rebuilding.

## Pattern

Home-manager creates out-of-store symlinks via `linkConfig`:
```
~/.config/hammerspoon -> ~/.dotfiles/config/hammerspoon  (live)
~/.config/nvim -> ~/.dotfiles/config/nvim                (live)
~/.config/tmux -> ~/.dotfiles/config/tmux                (live)
```

## Key directories

- `hammerspoon/` — Window management, hotkeys, voice modules, automation
- `nvim/` — Neovim config (Lua, plugins managed by lazy.nvim)
- `tmux/` — Terminal multiplexer config
- `kitty/` — Terminal emulator config
- `ghostty/` — Terminal emulator config
- `ssh/` — SSH client config

## Conventions

- These are NOT nix-managed (no `.nix` files here)
- Lua/toml/yaml configs live here and are edited directly
- Nix only provides the symlink and runtime dependencies
- See subdirectory AGENTS.md for app-specific conventions
