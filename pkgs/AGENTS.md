# pkgs/ — Custom package derivations

## Structure

```
pkgs/
├── default.nix            # Overlay: all custom packages
└── chrome-devtools-mcp.nix # Chrome DevTools MCP server (npm-based)
```

## default.nix (overlay)

Defines custom packages available as `pkgs.*` throughout the config.
Applied via `overlays/default.nix`.

### App packages (via mkApp)

These are macOS `.app` bundles built from DMG/ZIP sources:

| Package | Source | Notes |
|---------|--------|-------|
| `bloom` | DMG | Calendar app |
| `brave-browser-nightly` | DMG | Wrapped by mkChromiumBrowser for CLI args |
| `fantastical` | ZIP | Calendar app |
| `helium-browser` | ZIP | Wrapper browser |
| `mailmate` | DMG | Email client |
| `talktastic` | DMG | Communication app |

### Other custom packages

| Package | Type | Notes |
|---------|------|-------|
| `chrome-devtools-mcp` | npm | Chrome DevTools Protocol MCP server |
| `nvim-nightly` | overlay | Neovim nightly from nix-community overlay |

## Adding a new app

Follow the simple nixpkgs pattern (see otahontas/nix for reference):

```nix
my-app = mkApp {
  pname = "my-app";
  version = "1.0";
  appName = "My App.app";
  src = {
    url = "https://example.com/MyApp.dmg";
    sha256 = "...";
  };
  desc = "Description";
  homepage = "https://example.com";
};
```

For ZIP sources, mkApp auto-detects format from the URL.

## When to use what

| Source | Use case |
|--------|---------|
| `pkgs/` (mkApp) | macOS apps not in nixpkgs or homebrew |
| `modules/brew.nix` | Apps needing cask install (accessibility, kernel extensions) |
| `home/common/packages.nix` | CLI/GUI tools from nixpkgs |
| `home/common/programs/*.nix` | Tools with home-manager config (`programs.*.enable`) |

## Future

`mkApp/extract.nix` is ~260 lines but could be simplified to ~30 lines
following the nixpkgs/otahontas pattern (plain `stdenvNoCC.mkDerivation`).
