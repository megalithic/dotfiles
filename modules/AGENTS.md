# modules/ — System-level nix-darwin modules

## Key files

- `system.nix` — Core darwin settings (nix config, fonts, env vars, login shell)
- `brew.nix` — Homebrew cask/formula declarations
- `native-pkg-installer.nix` — Custom module for .pkg installers

## Conventions

- System modules receive `specialArgs` (inputs, username, hostname, paths, etc.)
- Prefer home-manager for user-level config; system modules for machine-wide settings
- Homebrew is only for apps that MUST be casks (1Password, Ghostty, Hammerspoon, etc.)
