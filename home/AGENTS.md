# home/ — Home-manager configuration

## Structure

```
home/
├── common/              # Shared config for all users/hosts
│   ├── default.nix      # Imports all common modules
│   ├── lib.nix          # Home-manager helper functions (linkBin, linkConfig)
│   ├── packages.nix     # CLI tools + GUI apps (nixpkgs + custom mkApp)
│   ├── mac-aliases.nix  # Finder alias creation (Spotlight/Launchpad support)
│   ├── mas.nix          # Mac App Store app declarations
│   ├── services.nix     # User-level launchd services (ollama agent)
│   ├── zen-browser.nix  # Zen browser config (WIP)
│   └── programs/        # Per-program config modules
│       ├── ai/          # AI tools (claude-code, ollama, opencode, pi)
│       ├── browsers/    # Browser config (chromium wrapper, firefox)
│       ├── discord.nix  # Discord (migrated from homebrew)
│       ├── email/       # Email clients (aerc, mailmate)
│       ├── fish/        # Fish shell (split into 8 modules)
│       ├── fzf.nix      # FZF fuzzy finder
│       ├── ghostty.nix  # Ghostty terminal (migrated from homebrew)
│       ├── jj/          # Jujutsu VCS (split into 3 modules)
│       ├── nvim.nix     # Neovim (package + LSPs, config lives in config/nvim/)
│       └── shade.nix    # Shade screen dimmer
├── megabookpro.nix      # Personal laptop overrides
├── rxbookpro.nix        # Work laptop overrides
└── kanata.nix-wip       # Kanata keyboard remapper (WIP, not imported)
```

## Package placement

| What | Where | Example |
|------|-------|---------|
| CLI tools from nixpkgs | `packages.nix` | ripgrep, fd, jq |
| GUI apps from nixpkgs | `packages.nix` (guiPkgs) | slack, iina, inkscape |
| Custom .app bundles | `packages.nix` (customApps) | fantastical, bloom |
| Tools with config | `programs/*.nix` | fish, jj, fzf, ghostty |
| Homebrew-only apps | `modules/brew.nix` | 1password, raycast |
| Mac App Store | `mas.nix` | Things3 |

## Key patterns

### programs.* auto-installs

If `programs.X.enable = true`, do NOT also add to packages:
```nix
# WRONG - double install
programs.bat.enable = true;
home.packages = [ pkgs.bat ];

# RIGHT - programs.* handles it
programs.bat.enable = true;
```

### Custom apps with mkApp

Apps in `packages.nix` that come from `pkgs/default.nix` (via mkApp) are
filtered by `appLocation`:
- `"home-manager"` (default) → added to `home.packages`, copied to `~/Applications/Home Manager Apps/`
- `"wrapper"` → managed by a wrapper module (e.g., `mkChromiumBrowser`), NOT added to `home.packages`
- `"symlink"` or `"copy"` → handled by `mkAppActivation`, NOT in `home.packages`

**If a wrapper module manages the app, you MUST set `appLocation = "wrapper"` in
pkgs/default.nix** to avoid duplicate app bundle conflicts.

### Finder aliases (mac-aliases.nix)

After home-manager copies apps, an activation script creates Finder aliases
in `~/Applications/Nix/`. These are real macOS aliases (not symlinks), so
Spotlight, Launchpad, and Dock all work properly.

### Services (services.nix)

User-level launchd services. Currently:
- `ollama-agent` — Ollama model server (configurable per host)

Host-specific services → `home/<hostname>.nix` or `hosts/<hostname>.nix`

## Host overrides

`megabookpro.nix` and `rxbookpro.nix` can override any home-manager option:
```nix
# home/rxbookpro.nix
{ config, pkgs, ... }: {
  home.packages = with pkgs; [ work-specific-tool ];
}
```

## File references in nix modules

Always use `self` (flake root) — never relative paths like `../../../../`:

```nix
# WRONG
source = ../../../../docs/skills/nix.md;

# CORRECT
source = "${self}/docs/skills/nix.md";
```

`self` is available in all modules via `extraSpecialArgs`. Add it to your module
args if needed: `{ self, ... }:`

## Rebuilding

```bash
just rebuild          # full: darwin + home
just home             # HM only (no sudo)
just darwin           # darwin only
just validate         # build both without switching (catches errors)
just bootstrap        # emergency: when just isn't in PATH
```

Always run `just validate` after nix refactors before pushing.
