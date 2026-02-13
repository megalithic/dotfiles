# GUI Apps & Services Research

**Date:** 2026-02-13  
**Goal:** Reduce homebrew reliance, consolidate services, evaluate unused tools

---

## Table of Contents

1. [Current State](#current-state)
2. [Research Findings](#research-findings)
3. [Homebrew Reduction Plan](#homebrew-reduction-plan)
4. [Services Consolidation](#services-consolidation)
5. [Unused Tools Evaluation](#unused-tools-evaluation)
6. [Implementation Roadmap](#implementation-roadmap)

---

## Current State

### Homebrew Casks - Complete Evaluation

**Legend:**
- ✅ Nix = Available in nixpkgs with darwin support
- 🍺 Brew = Must stay in homebrew (no nix pkg, darwin-only app, or needs system access)
- ❓ Evaluate = Ask user if still needed

| App | Status | Nixpkgs | Notes |
|-----|--------|---------|-------|
| 1password | 🍺 Brew | - | System integration, browser extensions, Accessibility |
| 1password-cli | ✅ Nix | `_1password-cli` | aarch64-darwin ✓ |
| colorsnapper | 🍺 Brew | - | macOS-only color picker, not in nixpkgs |
| contexts | ❓ Evaluate | - | macOS-only, not in nixpkgs. Still using? |
| discord | ✅ Nix | `discord` | aarch64-darwin ✓ |
| figma | 🍺 Brew | - | `figma-linux` exists but Linux-only |
| ghostty@tip | ✅ Nix | `ghostty-bin` | Use `-bin` variant (darwin), not `ghostty` (linux) |
| hammerspoon | 🍺 Brew | - | Accessibility permissions required |
| homerow | ❓ Evaluate | - | macOS-only, not in nixpkgs. Still using? |
| iina | ✅ Nix | `iina` | aarch64-darwin ✓ |
| inkscape | ✅ Nix | `inkscape` | aarch64-darwin ✓ |
| jordanbaird-ice | ❓ Evaluate | - | macOS-only menu bar manager. Still using? |
| karabiner-elements | 🍺 Brew | - | DriverKit system extensions, must be homebrew |
| kitty | ✅ Nix | `kitty` | aarch64-darwin ✓ - but using Ghostty now? |
| macwhisper | ❓ Evaluate | - | macOS-only. Using TalkTastic instead? |
| microsoft-teams | ✅ Nix | `teams` | aarch64-darwin ✓ |
| mouseless | 🍺 Brew | `mouseless` | Linux-only in nixpkgs |
| protonvpn | 🍺 Brew | `protonvpn-gui` | Linux-only in nixpkgs |
| proton-drive | ❓ Evaluate | - | Not in nixpkgs. Still using? |
| obs@beta | 🍺 Brew | `obs-studio` | **Linux-only** in nixpkgs ([#411190](https://github.com/NixOS/nixpkgs/issues/411190)) |
| orcaslicer | ❓ Evaluate | `prusa-slicer` | Alternative available (darwin ✓). Still 3D printing? |
| raycast | 🍺 Brew | - | System integration, Accessibility |
| slack | ✅ Nix | `slack` | aarch64-darwin ✓ |
| vial | 🍺 Brew | `vial` | Linux-only in nixpkgs |
| yubico-authenticator | 🍺 Brew | `yubioath-flutter` | **Linux-only** in nixpkgs |
| visual-studio-code | ✅ Nix | `vscode` | aarch64-darwin ✓ - but needed? |
| zed | ✅ Nix | `zed-editor` | aarch64-darwin ✓ |

### Homebrew Brews (1)

| Brew | Can Replace? | Notes |
|------|--------------|-------|
| whisperkit-cli | ❌ Keep | Apple Silicon native, not in nixpkgs |

### Mac App Store (2)

| App | Notes |
|-----|-------|
| Xcode | Required for development |
| Things3 | Task manager |

---

## Research Findings

### 1. mhanberg's macOS Alias Approach

**Source:** [github.com/mhanberg/.dotfiles](https://github.com/mhanberg/.dotfiles)

Instead of symlinks, they create **macOS Finder aliases** (bookmark files) which:
- Work properly with Spotlight indexing
- Don't confuse apps that check their bundle path
- Behave like native apps in Finder

**Implementation:**
```nix
# nix/darwin/link-apps/default.nix
# Creates macOS bookmark aliases at ~/Applications/Nix
# Uses Swift script to create aliases via URL.bookmarkData()
```

**Swift script:** Creates real macOS aliases (like Finder's "Make Alias"):
```swift
let data = try url.bookmarkData(options: .suitableForBookmarkFile, ...)
try URL.writeBookmarkData(data, to: aliasUrl)
```

**Should we adopt?** ✅ Yes - better than symlinks for apps that validate paths.

**Implementation for our setup:**

```nix
# lib/mkMacOSAlias.nix
{ pkgs, lib, ... }:
let
  createMacOSAlias = pkgs.stdenv.mkDerivation {
    name = "create-macos-alias";
    src = ./create-macos-alias.swift;
    dontUnpack = true;
    dontConfigure = true;
    dontBuild = true;
    installPhase = ''
      install -D -m755 $src $out/bin/create-macos-alias
    '';
  };
in {
  # Use in activation script
  aliasApp = src: dest: ''
    ${createMacOSAlias}/bin/create-macos-alias "${src}" "${dest}"
  '';
}
```

**Benefits over symlinks:**
- Spotlight indexes aliases properly
- Apps don't see nix store path in their bundle location
- Finder treats them as real apps
- Code signing validation works correctly

### 2. otahontas Ghostty via Nix

**Source:** [github.com/otahontas/nix](https://github.com/otahontas/nix)

```nix
programs.ghostty = {
  enable = true;
  package = pkgs.ghostty-bin;  # Pre-built binary
  settings = {
    macos-option-as-alt = "left";
  };
};

# Symlink config to macOS location
home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/config";
```

**Packages available:**
- `pkgs.ghostty` - Built from source (v1.2.3)
- `pkgs.ghostty-bin` - Pre-built binary (v1.2.3)

**Related nixpkgs activity:**
- [#455142](https://github.com/NixOS/nixpkgs/issues/455142) - Merge ghostty with ghostty-bin (open)
- [#453416](https://github.com/NixOS/nixpkgs/issues/453416) - nixos/ghostty: init (open)

**home-manager support:** Full `programs.ghostty` module with:
- `settings` - Key-value config options
- `themes` - Custom theme definitions
- `clearDefaultKeybinds` - Reset keybindings

**Caveats:**
- Accessibility permissions still need manual System Settings approval
- Currently using `ghostty@tip` (homebrew tip channel) - may have newer features
- home-manager symlinks to `~/.config/ghostty/config`, need symlink for macOS path

**Migration path:**
1. Switch from `ghostty@tip` cask to `programs.ghostty.package = pkgs.ghostty-bin`
2. Convert `config/ghostty/config` to nix `settings` attribute set
3. Add macOS config path symlink

### 3. Brave Browser Customization (home-manager)

**Finding:** `programs.brave` exists in home-manager with:
- `commandLineArgs` option
- `extensions` support (crx paths or Chrome Web Store IDs)

```nix
programs.brave = {
  enable = true;
  commandLineArgs = [
    "--remote-debugging-port=9222"
    "--enable-features=WebRTC"
  ];
  extensions = [
    { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; }  # uBlock Origin
  ];
};
```

**⚠️ CRITICAL ISSUE: Darwin wrapper doesn't use commandLineArgs**

Verified in `make-brave.nix`:
- **Linux:** Uses `gappsWrapperArgs` to add `--add-flags ${commandLineArgs}`
- **Darwin:** Simple `makeWrapper` with NO commandLineArgs support

```nix
# Darwin installPhase (line 242-250) - MISSING commandLineArgs!
lib.optionalString stdenv.hostPlatform.isDarwin ''
  mkdir -p $out/{Applications,bin}
  cp -r . "$out/Applications/Brave Browser.app"
  makeWrapper "...Brave Browser" $out/bin/brave  # NO --add-flags!
''
```

**Related Issues/PRs:**
- [#136591](https://github.com/NixOS/nixpkgs/pull/136591) - Added commandLineArgs (Linux only)
- [#202555](https://github.com/NixOS/nixpkgs/pull/202555) - Fixed commandLineArgs visibility
- Neither addressed Darwin wrapper

**Solutions (ranked):**

1. **Submit upstream PR** to fix Darwin wrapper:
   ```nix
   makeWrapper "...Brave Browser" $out/bin/brave \
     --add-flags ${lib.escapeShellArg commandLineArgs}
   ```

2. **Override brave locally** with fixed wrapper:
   ```nix
   brave = prev.brave.overrideAttrs (old: {
     installPhase = old.installPhase + ''
       wrapProgram $out/bin/brave --add-flags "${commandLineArgs}"
     '';
   });
   ```

3. **Keep mkChromiumBrowser** for Brave Nightly (current approach)
   - Pros: Full control, nightly builds, works now
   - Cons: We manage updates manually

**Recommended:** Option 2 for stable Brave, keep mkChromiumBrowser for Nightly.
Could also submit Option 1 as upstream PR.

---

## Homebrew Reduction Plan

### Phase 1: Easy Wins (9 apps)

**Verified available on aarch64-darwin:**

| Homebrew | Nixpkgs | Status |
|----------|---------|--------|
| 1password-cli | `pkgs._1password-cli` | ✅ aarch64-darwin |
| discord | `pkgs.discord` | ✅ aarch64-darwin |
| iina | `pkgs.iina` | ✅ aarch64-darwin |
| inkscape | `pkgs.inkscape` | ✅ aarch64-darwin |
| microsoft-teams | `pkgs.teams` | ✅ aarch64-darwin |
| slack | `pkgs.slack` | ✅ aarch64-darwin |
| visual-studio-code | `pkgs.vscode` | ✅ aarch64-darwin |
| zed | `pkgs.zed-editor` | ✅ aarch64-darwin |
| kitty | `pkgs.kitty` | ✅ aarch64-darwin (if still needed) |

```nix
# home/common/packages.nix
home.packages = with pkgs; [
  _1password-cli
  discord
  iina
  inkscape
  slack
  teams
  vscode  # if needed
  zed-editor
];
```

**⚠️ NOT available on darwin (must stay homebrew):**
- `yubioath-flutter` - Linux-only
- `obs-studio` - Linux-only ([#411190](https://github.com/NixOS/nixpkgs/issues/411190))
- `protonvpn-gui` - Linux-only
- `mouseless` - Linux-only
- `vial` - Linux-only

### Phase 2: Ghostty Migration

**Important:** Use `ghostty-bin` NOT `ghostty` - the build-from-source variant is Linux-only!

```nix
# home/common/programs/ghostty.nix
programs.ghostty = {
  enable = true;
  package = pkgs.ghostty-bin;  # MUST use -bin for darwin
  settings = {
    # Import existing config/ghostty/config
    macos-option-as-alt = true;
    shell-integration = "fish";
    # ... rest of settings
  };
};

# Symlink config to macOS location (Ghostty looks here)
home.file."Library/Application Support/com.mitchellh.ghostty/config".source =
  config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/ghostty/config";
```

**Note:** We currently use `ghostty@tip` (homebrew tip channel). The nixpkgs version is stable releases only (v1.2.3). May want to keep homebrew for bleeding edge.

### Phase 3: Evaluate & Remove

Apps to evaluate (ask user if still needed):
- colorsnapper
- contexts
- figma
- homerow
- jordanbaird-ice
- kitty (we use ghostty?)
- macwhisper (we use talktastic?)
- mouseless
- proton-drive
- orcaslicer
- vial

### Phase 4: Must Stay in Homebrew (12+ apps)

**System integration / Accessibility required:**
- 1password (system integration, browser extensions)
- hammerspoon (accessibility permissions)
- karabiner-elements (DriverKit system extensions)
- raycast (system integration)

**Not in nixpkgs for darwin:**
- obs@beta (Linux-only in nixpkgs - [#411190](https://github.com/NixOS/nixpkgs/issues/411190))
- yubico-authenticator (`yubioath-flutter` Linux-only)
- protonvpn (GUI Linux-only)
- mouseless (Linux-only)
- vial (Linux-only)

**macOS-only apps (no nixpkgs equivalent):**
- colorsnapper
- figma (official app, `figma-linux` doesn't work on darwin)
- macwhisper (if still using)

**Brews (CLI tools):**
- whisperkit-cli (Apple Silicon native, not in nixpkgs)

---

## Services Consolidation

### Current Services

| Service | Location | Type |
|---------|----------|------|
| limit-maxfiles | `modules/system.nix` | launchd daemon |
| ollama | `home/common/programs/ai/ollama.nix` | launchd agent |
| agenix | `home/common/programs/agenix.nix` | launchd agent (via module) |
| jankyborders | `hosts/common.nix` | nix-darwin service |
| native-pkg-installer | `modules/native-pkg-installer.nix` | activation script |

### Proposed Consolidation

Create `modules/darwin/services.nix`:

```nix
{ config, lib, pkgs, ... }: {
  # System-wide services (launchd daemons)
  launchd.daemons = {
    # File descriptor limits for nix builds
    limit-maxfiles = {
      serviceConfig = {
        Label = "limit.maxfiles";
        ProgramArguments = ["launchctl" "limit" "maxfiles" "524288" "524288"];
        RunAtLoad = true;
      };
    };
  };

  # Optional services
  services.jankyborders = {
    enable = false;
    # ...
  };
}
```

Create `home/common/services.nix`:

```nix
{ config, lib, pkgs, ... }: {
  # User services (launchd agents)
  launchd.agents = {
    ollama = {
      enable = true;
      config = {
        ProgramArguments = ["${pkgs.ollama}/bin/ollama" "serve"];
        RunAtLoad = true;
        KeepAlive = true;
        # ...
      };
    };
  };
}
```

**Benefits:**
- Single place to see all services
- Easier to enable/disable per-host
- Clear separation: system daemons vs user agents

---

## Unused Tools Evaluation

### Questions for User

**GUI Apps (homebrew):**
1. **colorsnapper** - Using for color picking?
2. **contexts** - Still using for window switching?
3. **figma** - Active design work?
4. **homerow** - Using keyboard navigation?
5. **jordanbaird-ice** - Menu bar management?
6. **kitty** - Or fully on Ghostty now?
7. **macwhisper** - Or using TalkTastic?
8. **mouseless** - Keyboard shortcut trainer?
9. **proton-drive** - Cloud storage active?
10. **orcaslicer** - 3D printing active?
11. **vial** - Keyboard configuration?
12. **visual-studio-code** - Or fully on nvim/zed?

**CLI Tools (packages.nix):**
1. **amber** - Secret manager - active use?
2. **devbox** - Development environments - using?
3. **espanso** - Text expansion - active?
4. **transcrypt** - Git encryption - active repos?
5. **w3m** - Terminal browser - using?

**Languages (packages.nix):**
1. **harper** - Grammar checker - using?
2. **vue-language-server** - Vue development?

---

## Implementation Roadmap

### Immediate (This Session)

1. ✅ Document findings
2. [ ] Get user input on unused apps
3. [ ] Create services consolidation modules

### Short Term (Next Session)

1. [ ] Migrate easy-win apps from homebrew to nix
2. [ ] Set up `programs.ghostty` to replace cask
3. [ ] Implement mhanberg's alias approach for better app linking
4. [ ] Remove confirmed unused apps

### Medium Term

1. [ ] Fix Brave browser nixpkgs darwin wrapper (upstream PR?)
2. [ ] Evaluate if we can use nixpkgs brave + wrapper instead of mkApp
3. [ ] Test all migrated apps for functionality

### Long Term

1. [ ] Reduce homebrew to absolute minimum (5-6 apps)
2. [ ] Document which apps truly need homebrew and why
