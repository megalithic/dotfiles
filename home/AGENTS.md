# home/ — Home-manager configuration

## Structure

```
home/
├── common/              # Shared config for all users/hosts
│   ├── default.nix      # Imports all common modules
│   ├── lib.nix          # Home-manager helper functions (linkBin, linkConfig)
│   ├── accounts.nix     # Email accounts + shared mail utilities
│   ├── packages.nix     # CLI tools + GUI apps (nixpkgs + custom mkApp)
│   ├── mac-aliases.nix  # Finder alias creation (Spotlight/Launchpad support)
│   ├── mas.nix          # Mac App Store app declarations
│   ├── services.nix     # User-level launchd services (omlx default, ollama opt-in)
│   └── programs/        # Per-program config modules — one dir per program,
│                        # each with default.nix (and optional support files)
│       ├── aerc/                  # Email TUI client
│       ├── agenix/                # Secrets management
│       ├── brave-browser-nightly/ # Brave Browser Nightly
│       ├── claude-code/           # Claude Code (+ mcp.nix)
│       ├── discord/               # Discord
│       ├── firefox/               # Firefox (placeholder)
│       ├── fish/                  # Fish shell (split into 8 sub-modules)
│       ├── fzf/                   # FZF fuzzy finder
│       ├── ghostty/               # Ghostty terminal
│       ├── helium-browser/        # Helium browser
│       ├── jj/                    # Jujutsu VCS (split into 3 sub-modules)
│       ├── khard/                 # CLI address book
│       ├── mailmate/              # Email GUI client
│       ├── mbsync/                # IMAP→maildir sync
│       ├── msmtp/                 # SMTP send + queue
│       ├── notmuch/               # Mail indexing/tagging
│       ├── nvim/                  # Neovim (package + LSPs)
│       ├── ollama/                # Local LLM inference (legacy, opt-in via services.ollamaAgent)
│       ├── omlx/                  # Apple Silicon LLM inference (default ON)
│       ├── pi-coding-agent/       # pi agent harness
│       ├── shade/                 # Shade screen dimmer
│       ├── starship/              # Cross-shell prompt
│       └── worktrunk/             # (disabled)
├── megabookpro.nix      # Personal laptop overrides
└── rxbookpro.nix        # Work laptop overrides
```

## Package placement

| What | Where | Example |
|------|-------|---------|
| CLI tools from nixpkgs | `packages.nix` | ripgrep, fd, jq |
| GUI apps from nixpkgs | `packages.nix` (guiPkgs) | slack, iina, inkscape |
| Custom .app bundles | `packages.nix` (customApps) | fantastical, bloom |
| Tools with config | `programs/<name>/default.nix` | fish, jj, fzf, ghostty |
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
- `omlx-agent` — oMLX model server (default ON; ollama is opt-in via `services.ollamaAgent`)

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
