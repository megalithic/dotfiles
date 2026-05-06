# Nix Structure Proposal

**Date:** 2026-02-13  
**Purpose:** Consolidate custom libs, adopt community patterns, clean up structure

---

## 1. Ghostty Release Frequency

| Version | Date | Gap |
|---------|------|-----|
| v1.0.0 | Dec 26, 2024 | - |
| v1.1.0 | Jan 30, 2025 | 5 weeks |
| v1.2.0 | Sep 15, 2025 | 7.5 months |
| v1.2.3 | Oct 23, 2025 | 5 weeks (patch) |

**Current:** nixpkgs has v1.2.3, homebrew tip is ~4 months ahead (active commits daily).

**Recommendation:** If you want bleeding edge features, stay with `ghostty@tip`. If stability is fine, switch to `programs.ghostty` with `ghostty-bin`.

---

## 2. Services Per Host

**Yes, fully supported.** Services can live in:

| Location | Scope | Example |
|----------|-------|---------|
| `modules/darwin/services.nix` | All darwin hosts | System daemons (limit-maxfiles) |
| `hosts/<hostname>.nix` | Single host only | Host-specific services |
| `home/common/services.nix` | All users | User agents (ollama) |
| `home/<user>/<host>.nix` | Single user/host | User-specific agents |

```nix
# modules/darwin/services.nix (shared)
{ config, ... }: {
  launchd.daemons.limit-maxfiles = { ... };
}

# hosts/megabookpro.nix (host-specific)
{ config, ... }: {
  launchd.daemons.mega-specific-daemon = { ... };
}
```

---

## 3. WhisperKit-CLI Derivation

**Challenge:** WhisperKit is a Swift package using CoreML and Metal (Apple proprietary frameworks).

**Feasibility:** ⚠️ Difficult but possible

```nix
# Conceptual approach
{ lib, stdenv, darwin, swift }:
stdenv.mkDerivation {
  pname = "whisperkit-cli";
  version = "0.15.0";
  
  nativeBuildInputs = [ swift ];
  buildInputs = with darwin.apple_sdk.frameworks; [
    CoreML
    Metal
    Accelerate
  ];
  
  buildPhase = ''
    swift build -c release --product whisperkit-cli
  '';
}
```

**Problems:**
- Swift PM downloads dependencies at build time (needs network in sandbox)
- CoreML/Metal require macOS SDK (darwin.apple_sdk)
- Code signing may be required

**Recommendation:** Keep in homebrew for now. Creating a proper derivation requires significant effort and may break on SDK updates.

---

## 4. Community Patterns for Custom Packages

Based on research of popular nix-darwin dotfiles:

### Pattern 1: Single `pkgs/` directory (what we have)
```
pkgs/
├── default.nix          # Overlay exporting all packages
├── cli/
│   ├── chrome-devtools-mcp.nix
│   └── some-tool.nix
├── gui/
│   ├── brave-browser-nightly.nix
│   └── fantastical.nix
└── npm/
    └── mcp-servers.nix
```

### Pattern 2: Overlays with inline packages (dustinlyons style)
```
overlays/
├── default.nix          # Composes all overlays
├── custom-app.nix       # Each package is an overlay file
├── another-app.nix
└── README.md
```

### Pattern 3: Separate concerns (ryan4yin style)
```
lib/                     # Helper functions only
├── default.nix
├── mkDarwinHost.nix
└── mkApp.nix

overlays/                # Package modifications
├── default.nix
└── fixes/

pkgs/                    # New packages only
├── default.nix
└── custom/
```

**Recommendation:** Adopt Pattern 1 with subdirectories for clarity.

---

## 5. Proposed New Structure

```
~/.dotfiles/
├── lib/
│   ├── default.nix           # Exports lib.mega.* helpers
│   ├── mkDarwinHost.nix      # Host builder
│   ├── mkHome.nix            # Home builder
│   └── builders/             # App/package builders
│       ├── mkApp.nix         # macOS app from DMG/ZIP/PKG
│       ├── mkChromiumApp.nix # Chromium-based browser wrapper
│       └── mkMacOSAlias.nix  # mhanberg's alias pattern
│
├── pkgs/
│   ├── default.nix           # Overlay: exports all custom packages
│   ├── cli/                  # CLI tools
│   │   └── chrome-devtools-mcp.nix
│   ├── gui/                  # macOS GUI apps (mkApp)
│   │   ├── brave-nightly.nix
│   │   ├── fantastical.nix
│   │   ├── bloom.nix
│   │   └── talktastic.nix
│   └── npm/                  # Node.js packages (buildNpmPackage)
│       └── mcp-servers.nix
│
├── overlays/
│   └── default.nix           # Composes: external inputs + fixes + pkgs/
│
└── modules/
    └── darwin/
        └── browsers/         # Browser config (moved from home/)
            ├── default.nix
            └── chromium-wrapper.nix
```

---

## 6. NPM Packages Pattern

Use `buildNpmPackage` in `pkgs/npm/`:

```nix
# pkgs/npm/my-tool.nix
{ lib, buildNpmPackage, fetchFromGitHub }:

buildNpmPackage {
  pname = "my-tool";
  version = "1.0.0";
  
  src = fetchFromGitHub { ... };
  npmDepsHash = "sha256-...";
  
  # For packages with native deps
  nativeBuildInputs = [ python3 ];
  
  meta = { ... };
}
```

Then in `pkgs/default.nix`:
```nix
{ lib }: final: prev: {
  # CLI tools
  chrome-devtools-mcp = prev.callPackage ./cli/chrome-devtools-mcp.nix {};
  
  # NPM packages
  my-npm-tool = prev.callPackage ./npm/my-tool.nix {};
  
  # GUI apps (using mkApp from lib)
  fantastical = lib.mega.mkApp { inherit (prev) pkgs; } { ... };
}
```

---

## 7. Brave Browser Decision

**Keep our mkChromiumBrowser approach.**

Reasons:
1. Nixpkgs brave doesn't pass `commandLineArgs` on Darwin
2. We need `--remote-debugging-port` for MCP/CDP tools
3. We want nightly builds (nixpkgs is stable only)
4. Our wrapper creates proper macOS app bundle with args

**Cleanup:** Move browser builders to `lib/builders/` and browser configs to `modules/darwin/browsers/`.

---

## 8. Consolidation Action Items

### Phase 1: Reorganize lib/
- [ ] Create `lib/builders/` subdirectory
- [ ] Move `mkApp.nix` → `lib/builders/mkApp.nix`
- [ ] Extract chromium wrapper logic → `lib/builders/mkChromiumApp.nix`
- [ ] Add `lib/builders/mkMacOSAlias.nix` (mhanberg pattern)
- [ ] Update `lib/default.nix` to export from builders/

### Phase 2: Reorganize pkgs/
- [ ] Create subdirectories: `cli/`, `gui/`, `npm/`
- [ ] Move `chrome-devtools-mcp.nix` → `pkgs/cli/`
- [ ] Split inline mkApp definitions in `pkgs/default.nix` → `pkgs/gui/`
- [ ] Update `pkgs/default.nix` to callPackage from subdirs

### Phase 3: Move browser module
- [ ] Create `modules/darwin/browsers/`
- [ ] Move `home/common/programs/browsers/` → `modules/darwin/browsers/`
- [ ] Update imports

### Phase 4: Services consolidation
- [ ] Create `modules/darwin/services.nix`
- [ ] Create `home/common/services.nix`
- [ ] Move scattered service configs

---

## 9. User Decisions Summary

**Keep in homebrew (per your input):**
- contexts ✓
- homerow ✓
- proton-drive ✓
- orcaslicer ✓
- kitty ✓
- visual-studio-code ✓

**Remove from evaluate list:**
- jordanbaird-ice (you didn't mention → assume remove)
- macwhisper (you didn't mention → assume remove)

**Update modules/brew.nix** to reflect final list.
