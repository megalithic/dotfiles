# Builders & Modules Code Review

**Date:** 2026-02-13  
**Purpose:** Deep audit of all custom builders and modules

---

## Executive Summary

We're **over-engineering** in several areas. The core `mkApp` extract path is useful but bloated. The `native` and `mas` paths are barely used and add significant complexity. The `mkChromiumBrowser` module is solid but misplaced. Several modules solve problems we don't actually have.

---

## 1. `lib/mkApp.nix` + `lib/mkApp/extract.nix`

### What it does
Unified macOS app builder with 3 install methods: extract (DMG/ZIP/PKG), native (system PKG installer), and MAS (App Store).

### What uses it
- `pkgs/default.nix`: fantastical, bloom, brave-browser-nightly, helium-browser, talktastic, tidewave, tidewave-cli (7 packages)

### Assessment: ⚠️ Overcomplicated, needs simplification

**Good:**
- Handles DMG, ZIP, PKG extraction in one function
- `appLocation` passthru for controlling where apps land
- Binary artifact support (tidewave-cli)

**Problems:**
- **260 lines** of extract.nix for what nixpkgs does in 3 lines:
  ```nix
  # How nixpkgs packages iina (the ENTIRE derivation):
  sourceRoot = "IINA.app";
  installPhase = ''
    mkdir -p $out/{bin,Applications/IINA.app}
    cp -R . "$out/Applications/IINA.app"
    ln -s "$out/Applications/IINA.app/Contents/MacOS/iina-cli" "$out/bin/iina"
  '';
  ```
- Pulls in 10+ nativeBuildInputs (7zz, fd, rg, xar, cpio, pbzx, gnused) when most apps just need `undmg`
- Fallback chains for archive detection are fragile
- PKG extraction logic is complex (pbzx, xar, cpio chain)
- `appLocation` adds 3 code paths for something that should be handled by the config, not the builder

**Recommendation:** 
- Simplify to match nixpkgs pattern: one `stdenv.mkDerivation` per app
- For DMG apps: `undmg` handles unpack, then `installPhase` copies
- For PKG apps: keep a small helper, but the current one is over-engineered
- For binaries: just `install -Dm755`
- Remove `appLocation` from the builder - handle at the config level

---

## 2. `lib/mkApp/native.nix`

### What it does
Creates a "marker" derivation that stores install/uninstall scripts for native PKG installers (apps needing sudo).

### What uses it
- `pkgs/karabiner-elements.nix` (1 package, and it's managed by homebrew anyway)

### Assessment: ❌ Remove entirely

**Problems:**
- Karabiner-Elements is **already in homebrew** in `modules/brew.nix`
- The native install runs `sudo /usr/sbin/installer` during activation - this is fragile and surprising
- Version tracking via `/var/lib/nix-native-pkgs/` is custom state outside nix
- Only 1 user, and that user is redundant with homebrew

**Recommendation:** Delete. Karabiner is a homebrew app. If we ever need native PKG install again, it's a ~30 line script, not a framework.

---

## 3. `modules/native-pkg-installer.nix`

### What it does
Darwin module that auto-discovers packages with `isNativeInstaller = true` and runs their install scripts during activation.

### What uses it
- Imported by `lib/mkDarwinHost.nix`
- Only consumer is karabiner-elements (which is also in homebrew)

### Assessment: ❌ Remove entirely

**Problems:**
- 97 lines of module code for exactly 1 package
- That 1 package is already managed by homebrew
- Running `sudo installer` during system activation is an anti-pattern
- Generates a `nix-native-pkg-install` CLI tool nobody uses

**Recommendation:** Delete along with `native.nix`. If you need native PKG install, just use homebrew - that's literally what it's for.

---

## 4. `lib/mkMas.nix`

### What it does
Generates a shell script that installs Mac App Store apps via `mas` CLI.

### What uses it
- `home/common/mas.nix` (1 app: Xcode)

### Assessment: ⚠️ Keep but simplify

**Problems:**
- 95 lines with colored output, retry logic, search-by-name fallback
- Only installs Xcode
- The retry/search logic is over-engineered for a one-time setup task
- Running `mas install` in activation is slow and can fail silently

**Good:**
- MAS apps genuinely need a mechanism outside nix
- The concept is sound - just overbuilt

**Recommendation:** Simplify to ~20 lines. Drop the retry logic. Keep it simple:
```nix
# Simplified approach
home.activation.installMasApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
  if ! ${pkgs.mas}/bin/mas list | rg -q "^497799835 "; then
    echo "Installing Xcode from App Store..."
    ${pkgs.mas}/bin/mas install 497799835 || echo "Failed - install manually"
  fi
'';
```

---

## 5. `lib/mkProjectClaude.nix`

### What it does
Generates AI agent config files (.claude/settings.local.json and opencode.local.json) for projects.

### What uses it
- Nothing currently imports it (only referenced in `lib/default.nix`)

### Assessment: ❌ Remove or move out

**Problems:**
- Not used anywhere in this repo
- Designed for project flakes that import dotfiles - but no projects actually do this
- OpenCode format support is speculative
- If needed, this belongs in a separate flake/template, not dotfiles

**Recommendation:** Delete. If you need project-specific AI configs, create them per-project.

---

## 6. `home/common/programs/browsers/mkChromiumBrowser.nix`

### What it does
Home-manager module that creates `programs.<browser>` options for Chromium-based browsers with:
- Extension management
- Command-line args
- macOS wrapper .app bundles (for Finder launching with args)
- Keyboard shortcuts via NSUserKeyEquivalents

### What uses it
- `chromium.nix`: Helium Browser and Brave Browser Nightly

### Assessment: ✅ Keep, but it's not a "builder"

**Good:**
- Solves a real problem: nixpkgs can't pass `commandLineArgs` on Darwin
- Extension management works well
- Wrapper .app pattern is clever and necessary
- macOS keyboard shortcuts integration is useful

**Problems:**
- 400+ lines - could be trimmed
- Not a "builder" - it's a home-manager module, correctly placed in `programs/`
- The `mkWrapperApp` helper inside it IS a builder that could be extracted
- `customActivation` option is deprecated but still there

**Recommendation:** 
- Keep where it is (it's a HM module, not a lib builder)
- Extract `mkWrapperApp` to `lib/builders/` if we want to reuse it
- Remove deprecated `customActivation` option
- Consider renaming file to match what it is: a chromium programs module

---

## 7. `pkgs/karabiner-elements.nix`

### What it does
Karabiner-Elements with native PKG installer.

### Assessment: ❌ Remove

**Already managed by homebrew.** This is dead code.

---

## 8. `lib/mkInit.nix`

### What it does
Creates a nix app that runs a bootstrap script.

### Assessment: Need to check usage

```
5 lines of code - creates a simple wrapper
```

**Recommendation:** Keep if used, it's tiny and harmless.

---

## 9. `lib/mkSystem.nix`

### What it does
Creates NixOS (not darwin) system configurations for VMs.

### Assessment: Keep if you use NixOS VMs, otherwise remove.

---

## Mhanberg's Alias Pattern

### What it solves
Spotlight/Finder can't index nix store symlinks. macOS aliases (Finder bookmarks) work where symlinks don't.

### Should we adopt?
**Yes, but as a small utility, not a framework.** It's a Swift script (~20 lines) that creates a macOS alias. We'd call it from activation scripts.

```nix
# All it needs to be:
mkMacOSAlias = pkgs.runCommand "create-alias" {} ''
  cat > $out/bin/create-alias << 'EOF'
  #!/usr/bin/swift
  import Foundation
  let src = URL(fileURLWithPath: CommandLine.arguments[1])
  let dest = URL(fileURLWithPath: CommandLine.arguments[2])
  let data = try src.bookmarkData(options: .suitableForBookmarkFile, ...)
  try URL.writeBookmarkData(data, to: dest)
  EOF
  chmod +x $out/bin/create-alias
'';
```

---

## Recommended Actions

### Delete (dead code / unused)
1. `lib/mkApp/native.nix` - only user is karabiner (in homebrew)
2. `modules/native-pkg-installer.nix` - activation module for native.nix
3. `pkgs/karabiner-elements.nix` - redundant with homebrew
4. `lib/mkProjectClaude.nix` - unused

### Simplify
5. `lib/mkApp.nix` + `lib/mkApp/extract.nix` - strip down to match nixpkgs patterns
6. `lib/mkMas.nix` - reduce to ~20 lines inline in `home/common/mas.nix`

### Keep as-is
7. `home/common/programs/browsers/mkChromiumBrowser.nix` - real HM module, well-placed
8. `lib/mkInit.nix` - tiny, harmless
9. `lib/mkDarwinHost.nix`, `mkHome.nix`, `mkSystem.nix` - config builders, fine

### Add
10. `lib/builders/mkMacOSAlias.nix` - small Swift-based alias creator

---

## Simplified mkApp Proposal

Replace the 260-line extract.nix with per-app derivations that follow nixpkgs patterns:

```nix
# pkgs/gui/fantastical.nix - follows nixpkgs pattern exactly
{ lib, stdenvNoCC, fetchurl, undmg, _7zz }:

stdenvNoCC.mkDerivation {
  pname = "fantastical";
  version = "4.1.7";

  src = fetchurl {
    url = "https://cdn.flexibits.com/Fantastical_4.1.7.zip";
    sha256 = "sha256-w2XE8HQfqmM4gcsyni8qj6tPRcDWZ+HIHCg5K3cGjCA=";
  };

  sourceRoot = "Fantastical.app";
  nativeBuildInputs = [ undmg ];

  installPhase = ''
    mkdir -p $out/Applications/Fantastical.app
    cp -R . "$out/Applications/Fantastical.app"
  '';

  meta = {
    description = "Calendar and tasks app";
    homepage = "https://flexibits.com/fantastical";
    platforms = lib.platforms.darwin;
  };
}
```

**If we still want a helper** (to avoid repeating boilerplate), make it thin:

```nix
# lib/builders/mkDarwinApp.nix - thin wrapper, ~30 lines
{ lib, stdenvNoCC, fetchurl, undmg, unzip, _7zz }:

{ pname, version, src, appName ? "${pname}.app", description ? "", homepage ? "" }:

stdenvNoCC.mkDerivation {
  inherit pname version;
  src = fetchurl src;
  sourceRoot = appName;
  nativeBuildInputs = [ undmg unzip _7zz ];
  
  installPhase = ''
    mkdir -p $out/Applications/${appName}
    cp -R . "$out/Applications/${appName}"
  '';

  meta = {
    inherit description homepage;
    platforms = lib.platforms.darwin;
  };
}
```

That's it. No appLocation, no artifact type detection, no binary handling, no PKG extraction chains. Each special case gets handled in its own derivation.

---

## External Tools to Evaluate

### `kmein/wrappers` (github.com/kmein/wrappers)

Nix library to create wrapped executables via the module system. Could potentially replace our `mkChromiumBrowser` wrapper approach for passing `commandLineArgs` to Brave.

**What it does:**
- `lib.wrapPackage`: Low-level function to wrap packages with flags, env vars, runtime deps
- `lib.wrapModule`: High-level module system for type-safe wrapper configs
- Pre-built modules for common packages (mpv, notmuch, etc.)

**Potential use case:**
```nix
# Could this replace mkWrapperApp for Brave?
(wrappers.lib.wrapPackage {
  inherit pkgs;
  package = pkgs.brave-browser-nightly;
  flags = {
    "--remote-debugging-port" = "9222";
    "--no-first-run" = true;
  };
}).wrapper
```

**Unknowns:**
- Does it handle macOS `.app` bundles? (likely Linux-focused)
- Does it create a proper `.app` wrapper for Finder/Spotlight?
- Maintained? (check activity)

**Status:** Needs deeper evaluation. If it works on Darwin, could simplify our browser wrapper significantly. If not, our `mkWrapperApp` in `mkChromiumBrowser.nix` is already solving this.
