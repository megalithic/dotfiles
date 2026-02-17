# modules/ — System-level nix-darwin modules

## Structure

```
modules/
├── system.nix          # Core darwin settings (nix config, fonts, env, login shell)
├── brew.nix            # Homebrew cask/formula declarations
└── darwin/
    └── services.nix    # System-level launchd services (limit-maxfiles)
```

## system.nix

Core nix-darwin settings applied to all hosts:
- Nix daemon config, gc, optimise
- Fonts (via home-manager, not system)
- Environment variables
- Login shell setup
- Security (TouchID sudo)

## brew.nix

Homebrew-managed apps. Only for apps that **cannot** be nix-managed:
- Apps needing accessibility permissions (1Password, Karabiner, Raycast, Homerow)
- Apps with kernel extensions or system integration
- Apps where homebrew version is significantly ahead of nixpkgs

Current casks:
- 1password, 1password-cli
- colorsnapper, contexts, figma, hammerspoon, homerow
- karabiner-elements, kitty, microsoft-teams, mouseless
- protonvpn, proton-drive, obs@beta, orcaslicer
- raycast, vial, yubico-authenticator, visual-studio-code, zed

MAS apps: Xcode, Things3

### What's been migrated to nix

These were previously in brew.nix and are now nix-managed:
- Discord → `home/common/programs/discord.nix`
- Slack, IINA, Inkscape → `home/common/packages.nix`
- Ghostty → `home/common/programs/ghostty.nix`
- jordanbaird-ice, macwhisper → removed entirely

## darwin/services.nix

System-level launchd services for all hosts:
- `limit.maxfiles` — Raises file descriptor limit (needed for large nix builds)

Host-specific services go in `hosts/<hostname>.nix`.
User-level services go in `home/common/services.nix`.

## Conventions

- System modules receive `specialArgs` (inputs, username, hostname, paths)
- Prefer home-manager for user-level config
- Homebrew is last resort — check nixpkgs first
- `onActivation.cleanup = "zap"` removes unlisted casks
