# Package Architecture & De-duplication Audit

**Date:** 2026-02-13  
**Status:** Audit complete, changes implemented

---

## Table of Contents

1. [Package Sources Overview](#package-sources-overview)
2. [Custom Package Infrastructure](#custom-package-infrastructure)
3. [De-duplication Analysis](#de-duplication-analysis)
4. [Changes Implemented](#changes-implemented)

---

## Package Sources Overview

Packages come from multiple sources, layered via Nix overlays:

### 1. System Packages (`hosts/*.nix`)

**Location:** `environment.systemPackages`

**Purpose:** Minimal essentials available system-wide or needed before home-manager runs.

```
hosts/
├── common.nix       # Shared: curl, git, vim, coreutils, nix-index, darwin.trash
├── megabookpro.nix  # Personal: rust toolchain, google-cloud-sdk, kanata
└── rxbookpro.nix    # Work: rust toolchain only
```

### 2. Home-Manager Packages (`home/common/packages.nix`)

**Location:** `home.packages`

**Purpose:** User tools, languages, fonts, GUI apps.

```nix
cliPkgs   # amber, delta, dust, ffmpeg, gh, jq, just, etc.
fontPkgs  # nerd-fonts, fira-code, jetbrains-mono, etc.
langPkgs  # nodejs, python, lua, docker, kubernetes tools
guiPkgs   # obsidian, spotify, telegram-desktop, zoom-us
```

### 3. Home-Manager Programs (`programs.*`)

**Location:** Various `home/common/programs/*.nix`

**Purpose:** Auto-installs package when `enable = true`, plus configuration.

| Program | Package Installed | Config Location |
|---------|-------------------|-----------------|
| `programs.bat` | bat + bat-extras | `home/common/default.nix` |
| `programs.eza` | eza | `home/common/default.nix` |
| `programs.fd` | fd | `home/common/default.nix` |
| `programs.fish` | fish | `home/common/programs/fish/` |
| `programs.fzf` | fzf | `home/common/programs/fzf.nix` |
| `programs.jujutsu` | jujutsu | `home/common/programs/jj/` |
| `programs.k9s` | k9s | `home/common/default.nix` |
| `programs.mise` | mise | `home/common/default.nix` |
| `programs.neovim` | nvim-nightly | `home/common/programs/nvim.nix` |
| `programs.ripgrep` | ripgrep | `home/common/default.nix` |
| `programs.starship` | starship | `home/common/default.nix` |
| `programs.zoxide` | zoxide | `home/common/default.nix` |

### 4. Custom Packages (`pkgs/`)

**Location:** `pkgs/default.nix` (overlay)

**Purpose:** Packages built with `mkApp` or `callPackage`.

| Package | Type | Description |
|---------|------|-------------|
| `bloom` | mkApp (DMG) | Finder enhancement |
| `brave-browser-nightly` | mkApp (DMG) | Privacy browser |
| `fantastical` | mkApp (ZIP) | Calendar app |
| `helium-browser` | mkApp (DMG) | Ungoogled Chromium |
| `talktastic` | mkApp (PKG) | Voice dictation |
| `tidewave` | mkApp (DMG) | AI web dev |
| `tidewave-cli` | mkApp (binary) | Tidewave CLI |
| `chrome-devtools-mcp` | callPackage | MCP server |

### 5. Overlays (`overlays/default.nix`)

**Purpose:** External inputs, package sets, and aliases.

```nix
# Package set aliases
pkgs.stable.*      # nixpkgs-stable
pkgs.unstable.*    # nixpkgs-unstable

# Input aliases
pkgs.llm-agents.*  # claude-code, opencode, beads, pi
pkgs.nvim-nightly  # neovim nightly build
pkgs.mcphub        # MCP hub
pkgs.expert        # Expert AI assistant

# External overlays
inputs.nur.overlays.default
inputs.mcp-servers-nix.overlays.default
```

### 6. Homebrew (`modules/darwin/brew.nix`)

**Purpose:** Apps that can't be Nix-packaged (Accessibility, system extensions).

| App | Why Homebrew |
|-----|--------------|
| 1Password | System integration, browser extensions |
| Ghostty | Accessibility permissions |
| Hammerspoon | Accessibility permissions |
| Karabiner-Elements | DriverKit system extensions |
| Raycast | System integration |

---

## Custom Package Infrastructure

### `lib/mkApp.nix` - macOS App Builder

Unified builder for macOS applications from various sources:

```nix
mkApp {
  pname = "myapp";
  version = "1.0";
  src = { url = "..."; sha256 = "..."; };
  
  # Installation method
  installMethod = "extract";  # "extract" | "native" | "mas"
  
  # Artifact type
  artifactType = "app";  # "app" | "pkg" | "binary"
  
  # Where to install
  appLocation = "home-manager";  # "home-manager" | "symlink" | "copy" | "wrapper"
  
  # CLI binaries to expose
  binaries = ["myapp"];
}
```

**Install Methods:**

| Method | Use Case | Example |
|--------|----------|---------|
| `extract` | Most apps - extract .app from DMG/ZIP/PKG | Fantastical, Bloom |
| `native` | Apps requiring system installers | Karabiner (DriverKit) |
| `mas` | Mac App Store apps | Xcode |

**App Locations:**

| Location | Destination | Use Case |
|----------|-------------|----------|
| `home-manager` | `~/Applications/Home Manager Apps/` | Default, most apps |
| `symlink` | `/Applications/` (symlink) | Apps needing /Applications path |
| `copy` | `/Applications/` (copy) | Code-signed apps (Fantastical) |
| `wrapper` | Managed by mkChromiumBrowser | Browsers with CLI args |

### `mkChromiumBrowser` - Browser Wrapper

Creates wrapper apps that launch browsers with command-line arguments:

```nix
programs.chromium-browsers.helium-browser = {
  enable = true;
  package = pkgs.helium-browser;
  darwinWrapperApp = {
    enable = true;
    args = ["--remote-debugging-port=9222"];
  };
  cliWrapper = {
    enable = true;
    name = "helium";
  };
};
```

**Features:**
- Wrapper .app with custom args (e.g., `--remote-debugging-port`)
- CLI wrapper for terminal launching
- Extension management (CRX files with pinned hashes)
- macOS keyboard shortcuts via `NSUserKeyEquivalents`

### `llm-agents` - Node.js AI Tools

External flake providing Node.js-based AI tools:

```nix
pkgs.llm-agents.claude-code    # Claude Code CLI
pkgs.llm-agents.opencode       # OpenCode CLI
pkgs.llm-agents.beads          # Beads task runner
pkgs.llm-agents.pi             # pi-coding-agent
```

**Override pattern for npm hash issues:**

```nix
# overlays/default.nix
llm-agents = let
  upstream = inputs.llm-agents.packages.${system};
in upstream // {
  claude-code = upstream.claude-code.overrideAttrs (old: {
    # Fix maintainer or npm hash issues
  });
};
```

### MCP Servers

Model Context Protocol servers for AI tool integration:

```nix
# Via mcp-servers-nix
inputs.mcp-servers-nix.lib.evalModule pkgs {
  programs = {
    memory.enable = true;
    playwright.enable = true;
  };
}

# Custom MCP servers (pkgs/)
pkgs.chrome-devtools-mcp  # Chrome DevTools Protocol
pkgs.tidewave-cli         # Tidewave web dev
```

---

## De-duplication Analysis

### Duplicates Found

| Package | Was In | Now In | Resolution |
|---------|--------|--------|------------|
| `delta` | system + HM | HM only | Removed from system |
| `ripgrep` | system + HM | programs.ripgrep | Removed from both |
| `jujutsu` | system + programs | programs.jujutsu | Removed from system |
| `nvim-nightly` | system + programs | programs.neovim | Removed from system |
| `bat` | system | programs.bat | Removed from system |
| `eza` | system | programs.eza | Removed from system |
| `fd` | system | programs.fd | Removed from system |
| `starship` | system | programs.starship | Removed from system |
| `yazi` | system | programs.yazi | Removed from system |
| `zoxide` | system | programs.zoxide | Removed from system |

### Packages Moved to Home-Manager

These were in `hosts/megabookpro.nix` system packages, now in `home/common/packages.nix`:

```
dust, jq, just, ldns, libwebp, netcat, yq, inetutils
```

---

## Changes Implemented

### 1. `hosts/megabookpro.nix`

**Before:** 25+ packages  
**After:** Rust toolchain + google-cloud-sdk + kanata

### 2. `hosts/rxbookpro.nix`

**Before:** 20+ packages  
**After:** Rust toolchain only

### 3. `home/common/packages.nix`

**Added:**
```nix
dust        # disk usage analyzer
inetutils   # telnet, ftp, etc.
jq          # JSON processor
just        # command runner
ldns        # DNS tools (drill)
libwebp     # WebP image tools
netcat      # networking utility
yq          # YAML processor
```

**Removed:**
```nix
ripgrep     # Now via programs.ripgrep
```

### 4. Guiding Principles

| Category | Location | Examples |
|----------|----------|----------|
| **System essentials** | `hosts/common.nix` | curl, git, vim, coreutils |
| **Host-specific system** | `hosts/<host>.nix` | Rust toolchain, kanata |
| **User CLI tools** | `home/common/packages.nix` | jq, just, delta, ffmpeg |
| **Configurable tools** | `programs.*` | bat, fzf, starship, neovim |
| **Custom macOS apps** | `pkgs/` + `mkApp` | Fantastical, Bloom, Brave |
| **Accessibility apps** | Homebrew | Hammerspoon, Karabiner |
| **AI tools** | `llm-agents` overlay | claude-code, pi, opencode |

---

## Quick Reference

### Adding a new package

```bash
# CLI tool (no config needed)
# → home/common/packages.nix cliPkgs

# Tool with configuration  
# → home/common/programs/<tool>.nix with programs.<tool>.enable = true

# macOS app from DMG/ZIP
# → pkgs/default.nix with mkApp

# Node.js tool
# → Check llm-agents flake or add to overlays/

# Needs Accessibility/system extensions
# → modules/darwin/brew.nix
```

### Checking for duplicates

```bash
# Find package in all locations
rg "\bpackage-name\b" hosts/ home/common/ pkgs/ --type nix
```
