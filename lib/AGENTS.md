# lib/ — Nix library functions and builders

## Structure

```
lib/
├── default.nix      # Entry point, extends nixpkgs lib with lib.mega.*
├── paths.nix        # Centralized path definitions (home, dotfiles, icloud)
├── mkDarwinHost.nix # Darwin system builder (nix-darwin + modules)
├── mkHome.nix       # Standalone home-manager builder
├── mkInit.nix       # Shared init/arg setup for both builders
├── mkSystem.nix     # System package composition
├── mkApp.nix        # Custom macOS app derivation builder (DMG/ZIP/PKG)
├── mkApp/
│   └── extract.nix  # App extraction logic (unzip, undmg, etc.)
└── builders/
    ├── create-macos-alias.swift  # Swift script for Finder aliases
    ├── mkMacOSAlias.nix          # nix-darwin module: Finder aliases for system apps
    └── mkWrapperApp.nix          # Reusable .app wrapper (launch with custom args)
```

## lib.mega.* namespace

All helpers are exposed via `lib.mega.*` in the configuration:

```nix
lib.mega.paths username    # Path definitions
lib.mega.mkApp { ... }     # Build .app from DMG/ZIP/PKG
lib.mega.mkApps { ... }    # Build multiple apps
lib.mega.mkAppActivation   # Home-manager activation for custom apps
```

## Key files

### paths.nix

```nix
let paths = lib.mega.paths "seth"; in
paths.home       # /Users/seth
paths.dotfiles   # /Users/seth/.dotfiles
paths.notes      # iCloud notes path
```

### mkDarwinHost.nix

```nix
mkDarwinHost { hostname = "megabookpro"; username = "seth"; }
```

Composes:
- `hosts/common.nix` + `hosts/<hostname>.nix`
- `modules/system.nix` + `modules/darwin/services.nix`
- `lib/builders/mkMacOSAlias.nix` (Finder aliases)
- `modules/brew.nix` (homebrew)
- Agenix (secrets)
- **Note:** home-manager is NOT included — use `just home` separately

### mkHome.nix

```nix
mkHome { hostname = "megabookpro"; username = "seth"; }
```

Standalone HM: `home-manager switch --flake .#seth@megabookpro`

### mkApp.nix

Builds macOS `.app` bundles from DMG/ZIP/PKG sources.
Used in `pkgs/default.nix` for apps not in nixpkgs.

```nix
mkApp {
  pname = "fantastical";
  version = "3.8.5";
  appName = "Fantastical.app";
  src = { url = "..."; sha256 = "..."; };
}
```

**Note:** mkApp is extract-only now. Native PKG installers → use homebrew.
MAS apps → `home/common/mas.nix` (inline, no framework).

### builders/mkWrapperApp.nix

Creates a real `.app` bundle that launches another app with custom CLI args.
Used by `mkChromiumBrowser` for Brave Nightly (needs `--remote-debugging-port`).

```nix
mkWrapperApp {
  name = "Brave Browser Nightly";
  originalApp = "${pkgs.brave-browser-nightly}/Applications/Brave Browser Nightly.app";
  executableName = "Brave Browser Nightly";
  args = [ "--remote-debugging-port=9222" ];
}
```

### builders/mkMacOSAlias.nix

nix-darwin module that creates Finder aliases (not symlinks) for nix-managed apps.
Aliases are indexed by Spotlight, visible in Launchpad, and persist in Dock.

Enabled automatically via `mkDarwinHost.nix`:
```nix
services.mac-aliases = {
  enable = true;
  userName = "seth";
  userHome = "/Users/seth";
};
```

Home-manager counterpart: `home/common/mac-aliases.nix`

## Conventions

- All helpers go through `lib.mega.*` namespace
- Prefer `paths` over computing paths inline
- Darwin-only (no NixOS abstractions)
- Keep builders simple — follow nixpkgs patterns where possible
