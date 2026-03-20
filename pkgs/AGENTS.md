# pkgs/ — Custom package derivations

## Structure

```
pkgs/
├── default.nix              # Overlay: imports all custom packages
├── chrome-devtools-mcp.nix  # Chrome DevTools MCP server (npm-based)
├── fantastical.nix          # Fantastical calendar (ZIP, appLocation=copy)
├── bloom.nix                # Bloom Finder replacement (DMG)
├── brave-browser-nightly.nix # Brave Nightly (DMG, appLocation=wrapper)
├── tidewave.nix             # Tidewave app (DMG)
└── tidewave-cli.nix         # Tidewave CLI (binary)
```

## default.nix (overlay)

Defines custom packages available as `pkgs.*` throughout the config.
Applied via `overlays/default.nix`.

### App packages (via mkApp)

Each mkApp package lives in its own file, taking `{mkApp}:` as argument:

| Package | File | Source | Notes |
|---------|------|--------|-------|
| `fantastical` | `fantastical.nix` | ZIP | `appLocation = "copy"` (code signing) |
| `bloom` | `bloom.nix` | DMG | Finder replacement; default appLocation |
| `brave-browser-nightly` | `brave-browser-nightly.nix` | DMG | `appLocation = "wrapper"` (managed by mkChromiumBrowser) |
| `tidewave` | `tidewave.nix` | DMG | No CLI binaries |
| `tidewave-cli` | `tidewave-cli.nix` | Binary | `artifactType = "binary"` |

### Other custom packages

| Package | Type | Notes |
|---------|------|-------|
| `chrome-devtools-mcp` | npm (callPackage) | Chrome DevTools Protocol MCP server |

## Adding a new mkApp package

1. Create `pkgs/my-app.nix`:

```nix
{mkApp}:

mkApp {
  pname = "my-app";
  version = "1.0";
  appName = "My App.app";
  src = {
    url = "https://example.com/MyApp.dmg";
    sha256 = "...";
  };
  desc = "Description";
  homepage = "https://example.com";
}
```

2. Add to `pkgs/default.nix`:

```nix
my-app = callMkApp ./my-app.nix;
```

## When to use what

| Source | Use case |
|--------|---------|
| `pkgs/` (mkApp) | macOS apps not in nixpkgs or homebrew |
| `modules/brew.nix` | Apps needing cask install (accessibility, kernel extensions) |
| `home/common/packages.nix` | CLI/GUI tools from nixpkgs |
| `home/common/programs/*.nix` | Tools with home-manager config (`programs.*.enable`) |
