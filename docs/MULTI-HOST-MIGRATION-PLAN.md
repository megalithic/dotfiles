# Multi-Host Multi-User Nix-Darwin Migration Plan

**Epic**: Expand nix-darwin setup to support multiple Darwin-based computers with different users

**Status**: Planning Phase  
**Created**: 2026-01-12  
**Last Updated**: 2026-01-12

---

## Executive Summary

Good sir, we're about to reintroduce proper multi-host support to your dotfiles. You previously had this working with `mkSystem`, but simplified it when you consolidated to a single MacBook Pro (megabookpro) and single user (seth). Now you need to support a second laptop with its own user, while sharing most configuration.

**Key Requirements**:
- Support multiple Darwin (macOS) hosts
- Support multiple users (each host may have different primary user)
- Share ~95% of configuration between hosts
- Allow host-specific and user-specific customization
- Maintain clean, maintainable code structure
- Keep the excellent patterns you've already established (lib.mega, mkApp, etc.)
- **Bootstrap via `nix run github:megalithic/dotfiles` (mhanberg pattern)**
- **Idempotent test builds on current machine (prevent breaking prod)**

---

## Current State Analysis

### What You Have Now (Simplified Single-Host Setup)

**flake.nix**: Direct host configuration
```nix
let
  username = "seth";           # Hardcoded
  arch = "aarch64-darwin";     # Hardcoded
  hostname = "megabookpro";    # Hardcoded
  version = "25.11";
in {
  darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
    specialArgs = { inherit self inputs username arch hostname version overlays lib; };
    modules = [
      ./hosts/${hostname}.nix
      ./modules/system.nix
      ./modules/native-pkg-installer.nix
      agenix.darwinModules.default
      nix-homebrew.darwinModules.nix-homebrew
      (brew_config { inherit username; })
      (import ./modules/brew.nix)
      home-manager.darwinModules.default {
        home-manager.users.${username} = import ./home;
        home-manager.extraSpecialArgs = { inherit inputs username arch hostname version overlays lib; };
      }
    ];
  };
}
```

**Structure**:
```
.dotfiles/
├── flake.nix              # Single host config
├── hosts/
│   └── megabookpro.nix    # Seth's MacBook Pro host config
├── home/                  # Seth's home-manager config (no user separation)
│   ├── default.nix
│   ├── programs/
│   └── ...
├── modules/
│   ├── system.nix         # System-wide darwin config
│   ├── brew.nix
│   └── ...
└── lib/
    ├── mkSystem.nix       # EXISTS but unused
    └── ...
```

**Strengths**:
✅ Clean custom library system (`lib.mega`)  
✅ Excellent mkApp pattern for macOS apps  
✅ Well-organized home-manager modules  
✅ Out-of-store symlinks for live config reloading  
✅ Solid secrets management with agenix

**Limitations**:
❌ Hardcoded username/hostname/arch in flake.nix  
❌ No user separation in `home/` directory  
❌ Cannot easily add new hosts without flake.nix surgery  
❌ mkSystem exists but isn't used  
❌ Host-specific config mixed with system-wide config

### What You Had Before (Original mkSystem)

**lib/mkSystem.nix**: Multi-host/multi-user abstraction
```nix
{ nixpkgs, overlays, inputs }:
hostname:
{ system, user, darwin ? false, wsl ? false, version ? "25.05" }:
let
  # Path conventions for modularization
  machineConfig = ../machines/${hostname}.nix;
  userOSConfig = ../users/${user}/${if darwin then "darwin" else "nixos"}.nix;
  userHMConfig = ../users/${user}/home.nix;
in
  systemFunc rec {
    modules = [
      machineConfig
      userOSConfig
      home-manager.users.${user} = import userHMConfig;
    ];
  }
```

**Expected structure (from mkSystem)**:
```
.dotfiles/
├── machines/
│   ├── ${hostname}.nix    # Per-machine config
├── users/
│   └── ${user}/
│       ├── darwin.nix     # User's darwin-specific config
│       └── home.nix       # User's home-manager config
```

**This is solid foundation but we can modernize it.**

---

## Proposed Architecture

### Design Principles

1. **Convention over Configuration** - Predictable file locations
2. **Composition over Duplication** - Share config through modules
3. **Explicit over Implicit** - Clear separation of concerns
4. **Gradual Migration** - Keep existing setup working during transition

### Directory Structure

```
.dotfiles/
├── flake.nix                    # Multi-host orchestration
├── flake.lock
│
├── lib/
│   ├── default.nix              # Custom lib.mega extensions (keep existing)
│   ├── mkSystem.nix             # MODERNIZE: Multi-host builder function
│   ├── mkApp.nix                # Keep as-is
│   └── ...
│
├── hosts/                       # Per-host hardware/system configuration
│   ├── common.nix               # NEW: Shared host config
│   ├── megabookpro/             # RENAME: megabookpro.nix → megabookpro/default.nix
│   │   ├── default.nix          # Host-specific config
│   │   └── hardware.nix         # Optional hardware-specific config
│   └── ${newlaptop}/            # NEW: Second laptop
│       └── default.nix
│
├── users/                       # NEW: Per-user configuration
│   ├── common/                  # NEW: Shared user config
│   │   ├── darwin.nix           # Shared darwin system config
│   │   └── home.nix             # Shared home-manager config
│   ├── seth/
│   │   ├── darwin.nix           # Seth's darwin overrides (imports common)
│   │   ├── home.nix             # Seth's home-manager overrides (imports common)
│   │   └── packages.nix         # Seth-specific packages
│   └── ${newuser}/
│       ├── darwin.nix
│       ├── home.nix
│       └── packages.nix
│
├── modules/                     # System-wide reusable modules
│   ├── darwin/                  # NEW: Darwin-specific modules
│   │   ├── system.nix           # MOVE: from modules/system.nix
│   │   ├── brew.nix             # MOVE: from modules/brew.nix
│   │   └── defaults.nix         # macOS defaults (extracted from system.nix)
│   └── shared/                  # NEW: Cross-platform modules
│       └── nix.nix              # Nix settings (extracted from system.nix)
│
└── home/                        # TRANSITION: Move to users/common/ gradually
    ├── programs/                # KEEP: These become shared modules
    └── ...
```

### Migration Strategy: Gradual Transition

**Key insight**: We don't move everything at once. We transition gradually while keeping the system bootable at every step.

**Phase 1**: Introduce mkSystem without breaking current setup
- Restore mkSystem.nix with modern enhancements
- Create `hosts/common.nix` with shared host config
- Create `users/common/` with migrated `home/` content
- Create `users/seth/` that imports from `users/common/`
- Update flake.nix to use mkSystem for megabookpro
- **Validation**: Rebuild megabookpro - should produce identical result

**Phase 2**: Add the new laptop
- Create `hosts/${newlaptop}/default.nix`
- Create `users/${newuser}/` with user-specific overrides
- Add new host to flake.nix using mkSystem
- **Validation**: New laptop can rebuild successfully

**Phase 3**: Refactor modules for better sharing
- Extract common patterns from `modules/system.nix`
- Split into `modules/darwin/{system,brew,defaults}.nix`
- Create `modules/shared/` for cross-platform code
- **Validation**: Both hosts rebuild successfully

**Phase 4**: Cleanup and documentation
- Remove deprecated `home/` directory (fully migrated to `users/`)
- Archive old `hosts/megabookpro.nix` (replaced by `hosts/megabookpro/default.nix`)
- Update README and CLAUDE.md
- **Validation**: Clean build, no warnings

---

## Bootstrap Strategy (mhanberg Pattern)

### Current Bootstrap Mechanism

**Your existing bootstrap** (`scripts/aarch64-darwin_bootstrap.sh`):
1. Detects hostname via `hostname -s`
2. Clones repo to `~/.dotfiles`
3. Runs `sudo nix run nix-darwin -- switch --flake ~/.dotfiles#$FLAKE`

**Problem**: Requires hostname to match a `darwinConfigurations` key exactly

### Modernized Bootstrap with mkInit

**Inspired by mhanberg's pattern**, we'll use `mkInit` to create installable apps for each architecture:

**File**: `flake.nix` (apps section - UPDATED)

```nix
{
  outputs = { ... }:
  let
    # Helper to create bootstrap apps (mhanberg pattern)
    mkInit = {
      arch,
      script ? ''
        echo "no default app init script set."
      '',
    }: let
      pkgs = nixpkgs.legacyPackages.${arch};
      init = pkgs.writeShellApplication {
        name = "init";
        text = script;
      };
    in {
      type = "app";
      program = "${init}/bin/init";
    };
  in {
    # Bootstrap apps for each architecture
    apps."aarch64-darwin".default = mkInit {
      arch = "aarch64-darwin";
      script = ''
        #!/usr/bin/env bash
        set -Eueo pipefail
        
        # Detect or prompt for hostname
        HOSTNAME=$(hostname -s)
        echo "Detected hostname: $HOSTNAME"
        
        # Validate hostname exists in flake
        if ! nix flake show github:megalithic/dotfiles 2>/dev/null | grep -q "darwinConfigurations.$HOSTNAME"; then
          echo "ERROR: No configuration found for hostname '$HOSTNAME'"
          echo "Available configurations:"
          nix flake show github:megalithic/dotfiles 2>/dev/null | grep "darwinConfigurations"
          echo ""
          read -p "Enter hostname to use: " HOSTNAME
        fi
        
        # Clone dotfiles
        if [ -d "$HOME/.dotfiles" ]; then
          BACKUP_DIR="$HOME/.dotfiles.backup-$(date +%s)"
          echo "Backing up existing dotfiles to $BACKUP_DIR"
          mv "$HOME/.dotfiles" "$BACKUP_DIR"
        fi
        
        echo "Cloning dotfiles..."
        git clone https://github.com/megalithic/dotfiles "$HOME/.dotfiles"
        cd "$HOME/.dotfiles"
        
        # Configure git hooks
        git config core.hooksPath .githooks
        
        # Install nix-darwin
        echo "Installing nix-darwin for $HOSTNAME..."
        sudo nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --option eval-cache false --flake .#$HOSTNAME
        
        echo "✅ Installation complete!"
        echo "You can now run 'just rebuild' to rebuild your system"
      '';
    };
    
    apps."x86_64-darwin".default = mkInit {
      arch = "x86_64-darwin";
      script = builtins.readFile scripts/x86_64-darwin_bootstrap.sh;  # If needed
    };
    
    # ... darwinConfigurations, etc.
  };
}
```

### Installation Process (User-Facing)

**New installation instructions** (for README):

```bash
# 1. Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Source nix to make it available
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 3. Run the installer (auto-detects hostname)
nix run github:megalithic/dotfiles

# Or explicitly specify a host:
# HOSTNAME=megabookpro nix run github:megalithic/dotfiles
```

**Key improvements**:
- ✅ Auto-detects hostname
- ✅ Validates hostname exists in flake configurations
- ✅ Prompts for hostname if detection fails
- ✅ Works for any architecture (ARM/Intel)
- ✅ Single command installation
- ✅ No manual flake.nix editing before first build

---

## Testing Strategy (Idempotent Test Builds)

**Problem**: How do we test new host configurations on the current machine without breaking the production system?

### Solution: Test Configurations in darwinConfigurations

**Add test hosts** that can be built (but not activated) on your current machine:

**File**: `flake.nix` (darwinConfigurations - UPDATED)

```nix
{
  darwinConfigurations = {
    # Production hosts
    megabookpro = mkSystem {
      hostname = "megabookpro";
      system = "aarch64-darwin";
      user = "seth";
      version = "25.11";
      extraModules = [
        (brew_config { username = "seth"; })
        (import ./modules/brew.nix)
      ];
    };
    
    # TESTING: Hypothetical new laptop config (can build but not activate)
    testlaptop = mkSystem {
      hostname = "testlaptop";
      system = "aarch64-darwin";  # Match current machine arch
      user = "testuser";
      version = "25.11";
      extraModules = [
        (brew_config { username = "testuser"; })
        (import ./modules/brew.nix)
      ];
    };
  };
}
```

### Justfile Test Recipes

**File**: `justfile` (ADDITIONS)

```bash
# Test build a host configuration without activating
test-build host:
  @echo "Testing build for {{host}}..."
  nix build .#darwinConfigurations.{{host}}.system -o /tmp/nix-test-{{host}} --show-trace
  @echo "✅ Build successful for {{host}}"
  @echo "Output: /tmp/nix-test-{{host}}"

# Test build and show diff against current system
test-diff host:
  @echo "Building {{host}} and diffing against current system..."
  nix build .#darwinConfigurations.{{host}}.system -o /tmp/nix-test-{{host}}
  nix store diff-closures /run/current-system /tmp/nix-test-{{host}}

# Validate flake for all hosts
test-flake:
  @echo "Validating flake..."
  nix flake check
  @echo "✅ Flake validation passed"

# Test eval (faster than build, just checks syntax)
test-eval host:
  @echo "Evaluating {{host}} configuration..."
  nix eval .#darwinConfigurations.{{host}}.config.system.build.toplevel --no-allow-import-from-derivation
  @echo "✅ Evaluation successful for {{host}}"

# Clean up test artifacts
test-clean:
  rm -f /tmp/nix-test-* /tmp/nix-result-test
  @echo "✅ Cleaned up test artifacts"

# Full test suite for a new host config
test-host host: (test-eval host) (test-build host)
  @echo "✅ All tests passed for {{host}}"
```

### Testing Workflow

**Before committing new host config**:

```bash
# 1. Create test configuration for new laptop
#    (in flake.nix under darwinConfigurations)

# 2. Validate syntax (fast)
just test-eval testlaptop

# 3. Full build test (slower, but complete validation)
just test-build testlaptop

# 4. Check what would change vs current system
just test-diff testlaptop

# 5. Validate entire flake
just test-flake

# 6. If all pass, commit
jj describe -m "feat: add testlaptop host configuration"

# 7. Clean up test artifacts
just test-clean
```

**Benefits**:
- ✅ **Idempotent** - Doesn't modify current system
- ✅ **Fast iteration** - Test without activating
- ✅ **Diff validation** - See what would change
- ✅ **CI-ready** - Can run in GitHub Actions
- ✅ **Multi-arch** - Build tests work on any architecture
- ✅ **Removable** - Clean up with `just test-clean`

### CI/CD Integration (Future)

**File**: `.github/workflows/test-hosts.yaml`

```yaml
name: Test Host Configurations

on:
  pull_request:
    paths:
      - 'flake.nix'
      - 'flake.lock'
      - 'hosts/**'
      - 'users/**'
      - 'modules/**'

jobs:
  test:
    runs-on: macos-latest
    strategy:
      matrix:
        host: [megabookpro, testlaptop]  # Add more as needed
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: DeterminateSystems/magic-nix-cache-action@main
      
      - name: Validate flake
        run: nix flake check
      
      - name: Test build ${{ matrix.host }}
        run: |
          nix build .#darwinConfigurations.${{ matrix.host }}.system \
            -o /tmp/test-${{ matrix.host }}
```

---

## Detailed Implementation Plan

### Phase 1: Restore and Modernize mkSystem (Non-Breaking)

**Goal**: Introduce multi-host infrastructure without breaking existing setup

#### Step 1.1: Modernize lib/mkSystem.nix

**File**: `lib/mkSystem.nix`

**Changes**:
```nix
{ nixpkgs, overlays, inputs }:

# MODERNIZED: More flexible parameters
{ hostname
, system
, user
, darwin ? true          # Default to darwin (you're all-darwin now)
, version ? "25.11"
, extraUsers ? []        # Support multiple users per host
, extraModules ? []      # Allow host-specific module injection
}:

let
  isWSL = false;  # Not using WSL anymore
  
  systemFunc = if darwin 
    then inputs.nix-darwin.lib.darwinSystem 
    else nixpkgs.lib.nixosSystem;
    
  home-manager = if darwin 
    then inputs.home-manager.darwinModules 
    else inputs.home-manager.nixosModules;
  
  # Path conventions (note: hosts/ not machines/)
  hostConfig = ../hosts/${hostname};  # Can be .nix or /default.nix
  
  # User configs
  userDarwinConfig = ../users/${user}/darwin.nix;
  userHomeConfig = ../users/${user}/home.nix;
  
  # Multi-user home-manager configs
  allUsers = [user] ++ extraUsers;
  hmUsers = nixpkgs.lib.genAttrs allUsers (u: 
    import ../users/${u}/home.nix
  );
in
nixpkgs.lib.makeOverridable systemFunc rec {
  inherit system;
  
  # Use specialArgs for cleaner module access
  specialArgs = { 
    inherit inputs user username hostname version overlays lib;
    inherit (inputs) self;
    arch = system;  # Alias for compatibility
  };
  
  modules = [
    # Global overlays
    { nixpkgs.overlays = overlays; }
    { nixpkgs.config.allowUnfree = true; }
    { nixpkgs.config.allowUnfreePredicate = _: true; }
    
    # System config revision tracking
    { system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null; }
    
    # Host configuration (machine-specific)
    hostConfig
    
    # Shared darwin modules (system-wide)
    ../modules/darwin/system.nix      # Will create in Step 1.2
    ../modules/darwin/brew.nix
    ../modules/native-pkg-installer.nix
    
    # User's darwin-specific config
    userDarwinConfig
    
    # Integrations
    inputs.agenix.darwinModules.default
    inputs.nix-homebrew.darwinModules.nix-homebrew
    
    # Home-manager with multi-user support
    home-manager.home-manager {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users = hmUsers;
      home-manager.backupFileExtension = "hm-backup";
      home-manager.extraSpecialArgs = specialArgs;
    }
  ] ++ extraModules;
}
```

**Rationale**: 
- Maintains backwards compatibility with your existing patterns
- Adds flexibility for multi-user scenarios
- Uses `makeOverridable` for testing/CI variants (modern practice)
- Uses `specialArgs` instead of `_module.args` (cleaner, more explicit)
- Supports both `hosts/foo.nix` and `hosts/foo/default.nix` patterns

#### Step 1.2: Create Host Common Config

**File**: `hosts/common.nix`

**Purpose**: Extract shared configuration from `hosts/megabookpro.nix`

**Content** (initial - extracted from megabookpro.nix):
```nix
{ inputs, pkgs, config, lib, username, arch, hostname, version, ... }:
{
  # Common to ALL Darwin hosts
  
  # User creation (parameterized by username)
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.fish;
  };
  
  networking.hostName = lib.mkDefault hostname;  # Allow override
  system.defaults.smb.NetBIOSName = lib.mkDefault hostname;
  
  time.timeZone = lib.mkDefault "America/New_York";
  ids.gids.nixbld = 30000;
  
  # System-wide paths
  environment.systemPath = [ "/opt/homebrew/bin" ];
  environment.pathsToLink = [ "/Applications" ];
  environment.shells = [ pkgs.fish pkgs.zsh ];
  
  # Common environment variables (parameterized by username)
  environment.variables = {
    SHELL = "${pkgs.fish}/bin/fish";
    EDITOR = "${pkgs.nvim-nightly}/bin/nvim";
    VISUAL = "$EDITOR";
    # ... (extract from megabookpro.nix)
  };
  
  # Common packages (most users want these)
  environment.systemPackages = with pkgs; [
    # ... (extract from megabookpro.nix)
  ];
  
  # Nix settings
  nix = {
    enable = false;  # Using Determinate Nix installer
    package = pkgs.nixVersions.latest;
    settings = {
      trusted-users = [ "@admin" "root" "${username}" ];
      experimental-features = [
        "nix-command"
        "flakes"
        "extra-platforms = aarch64-darwin x86_64-darwin"
      ];
      # ... (extract from megabookpro.nix)
    };
  };
  
  # Common programs
  programs = {
    zsh.enable = true;
    bash.enable = true;
    fish = {
      enable = true;
      useBabelfish = true;
    };
  };
  
  nixpkgs.hostPlatform = arch;
}
```

#### Step 1.3: Create User Directory Structure

**Files**:
```
users/
├── common/
│   ├── darwin.nix    # Shared darwin system config
│   └── home.nix      # Shared home-manager config
└── seth/
    ├── darwin.nix    # Seth's overrides
    ├── home.nix      # Seth's overrides
    └── packages.nix  # Seth-specific packages
```

**File**: `users/common/darwin.nix`
```nix
{ inputs, pkgs, config, lib, username, ... }:
{
  # Common darwin system config for all users
  # (Initially empty or minimal - host config handles most of this)
  
  # User-level darwin settings that apply to all users
  # Example: default shell, home directory patterns, etc.
}
```

**File**: `users/common/home.nix`
```nix
{ config, pkgs, lib, inputs, username, arch, hostname, version, ... }:
{
  # THIS IS YOUR CURRENT home/default.nix
  # Copy the entire contents here, replacing hardcoded "seth" with ${username}
  
  imports = [
    ./lib.nix         # Copy from home/lib.nix
    ./packages.nix    # Copy from home/packages.nix
    ./programs/ai
    ./programs/agenix.nix
    # ... all your current imports
  ];
  
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = version;
  
  # Everything else from home/default.nix
  # ...
}
```

**File**: `users/seth/darwin.nix`
```nix
{ ... }:
{
  # Seth-specific darwin system config
  # Initially just imports common
  imports = [ ../common/darwin.nix ];
  
  # Seth's overrides go here
  # Example:
  # time.timeZone = "America/Los_Angeles";  # If Seth is in different timezone
}
```

**File**: `users/seth/home.nix`
```nix
{ config, pkgs, lib, ... }:
{
  # Seth-specific home-manager config
  imports = [ ../common/home.nix ];
  
  # Seth's overrides go here
  # Example:
  # programs.git.userEmail = "seth@megalithic.io";
  
  # Initially empty - all config is in common
}
```

**File**: `users/seth/packages.nix`
```nix
{ pkgs, ... }:
{
  # Seth-specific packages
  # Initially empty - can add packages Seth wants but other users don't
  
  home.packages = with pkgs; [
    # Example: seth-specific tools
  ];
}
```

#### Step 1.4: Update flake.nix to Use mkSystem

**File**: `flake.nix`

**Changes**:
```nix
{
  outputs = { self, nixpkgs, nix-darwin, home-manager, agenix, nix-homebrew, fenix, ... } @ inputs:
  let
    # Extend nixpkgs lib with our custom functions
    lib = nixpkgs.lib.extend (import ./lib/default.nix inputs);
    overlays = import ./overlays { inherit inputs lib; };
    
    # MODERNIZED: mkSystem builder
    mkSystem = import ./lib/mkSystem.nix { inherit nixpkgs overlays inputs; };
    
    # Brew config helper (parameterized)
    brew_config = { username }: {
      nix-homebrew = {
        enable = true;
        enableRosetta = true;
        autoMigrate = true;
        mutableTaps = false;
        user = username;
        taps = {
          "homebrew/core" = inputs.homebrew-core;
          "homebrew/cask" = inputs.homebrew-cask;
        };
      };
    };
  in {
    inherit (self) outputs;
    
    # Bootstrap app (keep as-is)
    apps."aarch64-darwin".default = mkInit {
      arch = "aarch64-darwin";
      script = builtins.readFile scripts/aarch64-darwin_bootstrap.sh;
    };
    
    # Rust env (keep as-is)
    packages.aarch64-darwin.default = fenix.packages.aarch64-darwin.minimal.toolchain;
    
    # MODERNIZED: Use mkSystem for hosts
    darwinConfigurations = {
      megabookpro = mkSystem {
        hostname = "megabookpro";
        system = "aarch64-darwin";
        user = "seth";
        darwin = true;
        version = "25.11";
        extraModules = [
          # Host-specific modules that aren't in mkSystem
          (brew_config { username = "seth"; })
          (import ./modules/brew.nix)
        ];
      };
      
      # FUTURE: Add new laptop here
      # ${newlaptop} = mkSystem {
      #   hostname = "${newlaptop}";
      #   system = "aarch64-darwin";
      #   user = "${newuser}";
      #   version = "25.11";
      #   extraModules = [
      #     (brew_config { username = "${newuser}"; })
      #     (import ./modules/brew.nix)
      #   ];
      # };
    };
  };
}
```

#### Step 1.5: Restructure hosts/megabookpro

**Changes**:
1. Rename `hosts/megabookpro.nix` → `hosts/megabookpro/default.nix`
2. Import common config
3. Keep only megabookpro-specific overrides

**File**: `hosts/megabookpro/default.nix`
```nix
{ inputs, pkgs, config, lib, username, arch, hostname, version, ... }:
{
  imports = [
    ../common.nix  # Import shared host config
  ];
  
  # Megabookpro-specific overrides only
  
  # Example: If megabookpro has specific hardware quirks
  # networking.computerName = "Seth's MacBook Pro";
  
  # Example: If megabookpro needs specific services
  # services.yabai.enable = true;
  
  # Most config is now in hosts/common.nix
}
```

#### Step 1.6: Validation

**Test Plan**:
```bash
# 1. Verify flake evaluation
nix flake check

# 2. Build without activating
nix build .#darwinConfigurations.megabookpro.system -o /tmp/nix-result-test

# 3. Diff with current system
nix store diff-closures /run/current-system /tmp/nix-result-test

# Expected: NO DIFFERENCES (or only trivial path changes)

# 4. If diff looks good, rebuild
just rebuild

# 5. Verify everything works
jj status
bd ready
# Test key apps: nvim, hammerspoon, ghostty, etc.
```

**Rollback Plan**:
```bash
# If something breaks
jj op restore <previous-operation>  # Jujutsu operation restore
just rebuild  # Rebuild from restored state
```

---

### Phase 2: Add New Laptop

**Goal**: Add second Darwin host with different user

**Prerequisites**: Phase 1 completed successfully

#### Step 2.1: Gather New Laptop Info

**Information needed**:
- Hostname: `${newlaptop}` (e.g., "worklaptop", "airlaptop")
- Username: `${newuser}` (e.g., "workuser", "alice")
- Architecture: Likely `aarch64-darwin` (Apple Silicon) or `x86_64-darwin` (Intel)
- macOS version: For `version` parameter

**How to gather on the new laptop**:
```bash
# Hostname
scutil --get LocalHostName

# Username
whoami

# Architecture
uname -m  # arm64 = aarch64-darwin, x86_64 = x86_64-darwin

# macOS version
sw_vers
```

#### Step 2.2: Create New Host Config

**File**: `hosts/${newlaptop}/default.nix`

```nix
{ inputs, pkgs, config, lib, username, arch, hostname, version, ... }:
{
  imports = [
    ../common.nix  # Shared host config
  ];
  
  # New laptop-specific overrides
  
  # Example: Different timezone
  # time.timeZone = "America/Los_Angeles";
  
  # Example: Different networking setup
  # networking.computerName = "${newuser}'s Work Laptop";
  
  # Example: Specific services needed for this laptop
  # services.some-work-specific-service.enable = true;
}
```

#### Step 2.3: Create New User Config

**Files**:
```
users/${newuser}/
├── darwin.nix
├── home.nix
└── packages.nix
```

**File**: `users/${newuser}/darwin.nix`
```nix
{ ... }:
{
  imports = [ ../common/darwin.nix ];
  
  # New user's darwin-specific config
  # Most is inherited from common, add overrides here
}
```

**File**: `users/${newuser}/home.nix`
```nix
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [ 
    ../common/home.nix  # Inherit 95% of config from Seth
  ];
  
  # User-specific overrides
  
  # Git config
  programs.git = {
    userName = "${newuser}";
    userEmail = "${newuser}@example.com";
  };
  
  # Different browser as default?
  # programs.chromium.enable = false;
  # programs.firefox.enable = true;
}
```

**File**: `users/${newuser}/packages.nix`
```nix
{ pkgs, ... }:
{
  # New user's specific packages
  
  home.packages = with pkgs; [
    # Example: work-specific tools
    # docker
    # kubernetes-helm
    # terraform
  ];
}
```

#### Step 2.4: Add New Host to flake.nix

**File**: `flake.nix` (add to `darwinConfigurations`)

```nix
darwinConfigurations = {
  megabookpro = mkSystem { ... };  # Existing
  
  # NEW: Second laptop
  ${newlaptop} = mkSystem {
    hostname = "${newlaptop}";
    system = "aarch64-darwin";  # Or x86_64-darwin
    user = "${newuser}";
    version = "25.11";
    extraModules = [
      (brew_config { username = "${newuser}"; })
      (import ./modules/brew.nix)
    ];
  };
};
```

#### Step 2.5: Initial Setup on New Laptop

**On the new laptop**:
```bash
# 1. Install Nix (Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone dotfiles
git clone git@github.com:megalithic/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 3. Build the configuration
nix build .#darwinConfigurations.${newlaptop}.system -o /tmp/result-${newlaptop}

# 4. If build succeeds, activate
/tmp/result-${newlaptop}/sw/bin/darwin-rebuild switch --flake .#${newlaptop}

# 5. Verify
echo $USER  # Should be ${newuser}
hostname    # Should be ${newlaptop}
```

#### Step 2.6: Validation

**Test both laptops**:

**On megabookpro (Seth)**:
```bash
cd ~/.dotfiles
just rebuild  # Should work exactly as before
```

**On ${newlaptop} (${newuser})**:
```bash
cd ~/.dotfiles
just rebuild  # Should work with new user config
```

**Verify independence**:
- Changes to Seth's config shouldn't affect new user
- Changes to common config should affect both
- Host-specific changes only affect that host

---

### Phase 3: Refactor Modules for Better Sharing

**Goal**: Clean up modules/ directory structure for clarity

**Prerequisites**: Phase 2 completed, both hosts working

#### Step 3.1: Analyze Current modules/

**Current structure**:
```
modules/
├── brew.nix                    # Homebrew packages
├── native-pkg-installer.nix    # Native PKG installer service
└── system.nix                  # Monolithic system config (300+ lines)
```

**Issues**:
- `system.nix` is monolithic - mixes darwin-specific with cross-platform
- No clear organization of darwin vs shared concerns

#### Step 3.2: Split modules/system.nix

**New structure**:
```
modules/
├── darwin/
│   ├── defaults.nix      # macOS system preferences (from system.nix)
│   ├── system.nix        # Darwin-specific system config
│   └── brew.nix          # MOVE: from modules/brew.nix
├── shared/
│   └── nix.nix           # Nix settings (cross-platform)
└── native-pkg-installer.nix  # KEEP: Darwin-specific but separate concern
```

**File**: `modules/darwin/defaults.nix`

Extract macOS system preferences from `modules/system.nix`:
```nix
{ lib, ... }:
{
  # All system.defaults.* settings
  # Extracted from current system.nix (see REFERENCES.md for full list)
  
  system.defaults = {
    # NSGlobalDomain settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      # ... (extract from system.nix)
    };
    
    # Dock settings
    dock = {
      autohide = true;
      # ... (extract from system.nix)
    };
    
    # Finder settings
    finder = {
      AppleShowAllFiles = true;
      # ... (extract from system.nix)
    };
    
    # etc.
  };
}
```

**File**: `modules/darwin/system.nix`

Darwin-specific system config (non-preferences):
```nix
{ pkgs, lib, ... }:
{
  # Darwin system configuration
  # Excludes: defaults (in defaults.nix), nix settings (in shared/nix.nix)
  
  # System settings
  system.keyboard.enableKeyMapping = true;
  
  # Security and privacy
  security.pam.enableSudoTouchIdAuth = true;
  
  # Services
  services.nix-daemon.enable = true;
  
  # Fonts
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      # ... font packages
    ];
  };
}
```

**File**: `modules/shared/nix.nix`

Cross-platform Nix settings (extracted from system.nix):
```nix
{ pkgs, lib, inputs, username, ... }:
{
  nix = {
    enable = false;  # Using Determinate Nix installer
    package = pkgs.nixVersions.latest;
    
    settings = {
      trusted-users = [ "@admin" "root" "${username}" ];
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        # ...
      ];
      trusted-public-keys = [ /* ... */ ];
      keep-derivations = true;
      keep-outputs = true;
    };
    
    nixPath = {
      inherit (inputs) nixpkgs nixpkgs-stable nixpkgs-unstable;
      # ...
    };
  };
}
```

#### Step 3.3: Update Imports

**Update** `lib/mkSystem.nix` to import new module structure:
```nix
modules = [
  # ...
  
  # Shared modules
  ../modules/shared/nix.nix
  
  # Darwin-specific modules
  ../modules/darwin/defaults.nix
  ../modules/darwin/system.nix
  ../modules/darwin/brew.nix
  ../modules/native-pkg-installer.nix
  
  # ...
];
```

**Update** `hosts/common.nix` to not duplicate these imports:
```nix
{
  # Remove duplicated config now in modules/
  # Keep only host-level config:
  # - User creation
  # - Networking
  # - Environment variables specific to host context
}
```

#### Step 3.4: Validation

**Test both hosts**:
```bash
# On each host
just rebuild

# Verify no differences in behavior
# Check key system preferences are still set
defaults read NSGlobalDomain AppleShowAllExtensions  # Should be 1
```

---

### Phase 4: Cleanup and Documentation

**Goal**: Remove deprecated files, update documentation

**Prerequisites**: Phase 3 completed, both hosts stable

#### Step 4.1: Archive Deprecated Files

**Move old files to archive**:
```bash
mkdir -p _archive/pre-multi-host-migration

# Archive old structure (keep for reference)
mv hosts/megabookpro.nix _archive/pre-multi-host-migration/
mv modules/system.nix _archive/pre-multi-host-migration/

# Add to .gitignore
echo "_archive/" >> .gitignore
```

**Update .gitignore**:
```
# ...existing ignores...

# Archive of deprecated files
_archive/
```

#### Step 4.2: Update Documentation

**File**: `README.md` - COMPLETE REWRITE for multi-host

```markdown
# 🗿 megadotfiles (nix'd)

<p align="center">
![ghostty + tmux + nvim](https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadots_ghostty_tmux_nvim.png)
</p>

## 🚀 Installation

### Fresh Installation (Any Mac)

```bash
# 1. Install Determinate Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Source nix to make it available
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# 3. Run the installer (auto-detects hostname)
nix run github:megalithic/dotfiles
```

The installer will:
- Auto-detect your hostname
- Validate it exists in available configurations
- Prompt you if your hostname isn't configured yet
- Clone the repo to `~/.dotfiles`
- Run the initial nix-darwin build

**Available hosts**: `megabookpro`, `${newlaptop}` (add more as needed)

### Rebuilding After Changes

```bash
# Standard rebuild (uses workaround for launch agent hang)
just rebuild

# Or use the justfile directly
cd ~/.dotfiles
just rebuild
```

## 📁 Repository Structure

This is a **multi-host, multi-user** nix-darwin + home-manager configuration.

```
.dotfiles/
├── flake.nix              # Multi-host orchestration
├── hosts/                 # Per-host configuration
│   ├── common.nix         # Shared across all hosts
│   ├── megabookpro/       # Seth's MacBook Pro
│   └── ${newlaptop}/      # Second laptop
├── users/                 # Per-user configuration
│   ├── common/            # Shared user config (~95% here)
│   │   ├── darwin.nix     # Shared darwin system config
│   │   └── home.nix       # Shared home-manager config
│   ├── seth/              # Seth's overrides
│   └── ${newuser}/        # Other user's overrides
├── modules/               # Reusable system modules
│   ├── darwin/            # macOS-specific (system.nix, brew.nix, defaults.nix)
│   └── shared/            # Cross-platform (nix.nix)
└── lib/                   # Custom library functions
    ├── mkSystem.nix       # Multi-host builder
    └── mkApp.nix          # macOS app packager
```

## 🔧 Development & Testing

### Test a Configuration Without Activating

```bash
# Test build (validates config, doesn't change system)
just test-build megabookpro

# Test build with diff against current system
just test-diff megabookpro

# Quick syntax check (fast)
just test-eval megabookpro

# Full test suite
just test-host megabookpro

# Clean up test artifacts
just test-clean
```

### Available Just Commands

```bash
just --list              # Show all commands
just rebuild             # Rebuild current host (uses darwin-switch workaround)
just test-build HOST     # Test build HOST without activating
just test-diff HOST      # Build HOST and diff vs current system
just test-eval HOST      # Fast syntax validation
just test-host HOST      # Full test suite for HOST
just test-flake          # Validate entire flake
just update-flake        # Update flake.lock
```

## ➕ Adding a New Host

### Option 1: Use the Helper Script

```bash
cd ~/.dotfiles
./bin/new-host worklaptop alice aarch64-darwin
```

This scaffolds:
- `hosts/worklaptop/default.nix`
- `users/alice/{darwin.nix,home.nix,packages.nix}`

Then:
1. Edit `flake.nix` to add the new `darwinConfigurations.worklaptop`
2. Customize the generated files
3. Test: `just test-build worklaptop`
4. On the new machine: `nix run github:megalithic/dotfiles`

### Option 2: Manual Setup

1. **Gather info**: hostname, username, system arch
2. **Create host config**: `hosts/${hostname}/default.nix`
3. **Create user config**: `users/${username}/{darwin.nix,home.nix,packages.nix}`
4. **Add to flake.nix**:
   ```nix
   darwinConfigurations.${hostname} = mkSystem {
     hostname = "${hostname}";
     system = "aarch64-darwin";  # or x86_64-darwin
     user = "${username}";
     version = "25.11";
     extraModules = [
       (brew_config { username = "${username}"; })
       (import ./modules/brew.nix)
     ];
   };
   ```
5. **Test locally**: `just test-build ${hostname}`
6. **Install on new machine**: `nix run github:megalithic/dotfiles`

## 🛠️ Common Tasks

### Update Dependencies

```bash
just update-flake        # Update flake.lock
just rebuild             # Apply updates
```

### Work with Secrets (agenix)

```bash
just age env-vars.age    # Edit encrypted secrets
```

### Fix Shell Files (If Needed)

```bash
just fix-shell-files     # Fix /etc/{zshenv,zshrc,bashrc} if darwin-rebuild corrupts them
```

## ✨ Key Features

- **Multi-host**: Support multiple Macs with different configs
- **Multi-user**: Each host can have different primary users
- **Shared config**: ~95% shared, 5% per-host/per-user customization
- **Bootstrap**: One-command installation via `nix run github:megalithic/dotfiles`
- **Testing**: Test builds without activating (`just test-build`)
- **Type-safe**: Nix validates all configuration
- **Rollback**: jj + nix generations for instant rollback
- **Out-of-store symlinks**: Live config reload for Hammerspoon, Ghostty, tmux

## 🐉 Warnings

- This is my personal config, constantly evolving
- **No stability guarantees** - review before installing
- Read the scripts before running them on your system
- Some configurations are specific to my hardware/workflow

## 📦 Included Tools

- **Terminal**: ghostty + tmux + fish
- **Editor**: neovim (nightly) with custom config
- **Shell**: fish with starship prompt
- **Window management**: Hammerspoon + kanata
- **Version control**: jj (Jujutsu) with git coexistence
- **Package management**: nix-darwin + home-manager + homebrew
- **Secrets**: agenix (age encryption)
- **AI tools**: claude-code, opencode with MCP servers

---

<p align="center" style="margin-top: 20px;">
  <a href="https://megalithic.io" target="_blank">
    <img src="https://raw.githubusercontent.com/megalithic/dotfiles/main/assets/megadotfiles.png" alt="megadotfiles logo" height="150px" />
  </a>
</p>
```

**File**: `CLAUDE.md` - Update configuration section

```markdown
## System Configuration Context

This Mac is configured through Nix (nix-darwin + home-manager) managed in `~/.dotfiles`.

**Multi-host setup**: This repo supports multiple Darwin hosts with different users.

- **Host config**: `hosts/${hostname}/default.nix`
- **User config**: `users/${username}/{darwin.nix,home.nix}`
- **Shared config**: `hosts/common.nix`, `users/common/`
- **Modules**: `modules/darwin/` (macOS), `modules/shared/` (cross-platform)

When investigating system behavior:
1. Check `users/${username}/` for user-specific config
2. Check `hosts/${hostname}/` for host-specific config
3. Check `users/common/` and `hosts/common.nix` for shared config
4. Check `modules/` for system-wide modules
```

**File**: `docs/MULTI-HOST-MIGRATION-PLAN.md` (this file)

Update status to "Completed" and add "Lessons Learned" section.

#### Step 4.3: Create Helper Scripts

**File**: `bin/new-host` (helper to add new host)

```bash
#!/usr/bin/env bash
# Helper script to scaffold a new host configuration

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <hostname> <username> <system>"
  echo "Example: $0 worklaptop alice aarch64-darwin"
  exit 1
fi

HOSTNAME=$1
USERNAME=$2
SYSTEM=$3

DOTFILES="${DOTFILES:-$HOME/.dotfiles}"
cd "$DOTFILES"

echo "Creating new host: $HOSTNAME (user: $USERNAME, system: $SYSTEM)"

# Create host directory
mkdir -p "hosts/$HOSTNAME"
cat > "hosts/$HOSTNAME/default.nix" <<EOF
{ inputs, pkgs, config, lib, username, arch, hostname, version, ... }:
{
  imports = [ ../common.nix ];
  
  # $HOSTNAME-specific config
}
EOF

# Create user directory
mkdir -p "users/$USERNAME"
cat > "users/$USERNAME/darwin.nix" <<EOF
{ ... }:
{
  imports = [ ../common/darwin.nix ];
  
  # $USERNAME's darwin config
}
EOF

cat > "users/$USERNAME/home.nix" <<EOF
{ config, pkgs, lib, inputs, username, ... }:
{
  imports = [ ../common/home.nix ];
  
  # $USERNAME's home-manager config
  
  programs.git = {
    userName = "$USERNAME";
    userEmail = "$USERNAME@example.com";  # TODO: Update email
  };
}
EOF

cat > "users/$USERNAME/packages.nix" <<EOF
{ pkgs, ... }:
{
  # $USERNAME's specific packages
  home.packages = with pkgs; [
    # Add user-specific packages here
  ];
}
EOF

echo ""
echo "✅ Created files:"
echo "  - hosts/$HOSTNAME/default.nix"
echo "  - users/$USERNAME/darwin.nix"
echo "  - users/$USERNAME/home.nix"
echo "  - users/$USERNAME/packages.nix"
echo ""
echo "Next steps:"
echo "  1. Edit flake.nix and add:"
echo "     $HOSTNAME = mkSystem {"
echo "       hostname = \"$HOSTNAME\";"
echo "       system = \"$SYSTEM\";"
echo "       user = \"$USERNAME\";"
echo "       version = \"25.11\";"
echo "       extraModules = ["
echo "         (brew_config { username = \"$USERNAME\"; })"
echo "         (import ./modules/brew.nix)"
echo "       ];"
echo "     };"
echo ""
echo "  2. Customize the generated files"
echo "  3. Build: nix build .#darwinConfigurations.$HOSTNAME.system"
echo "  4. On the new machine, run: darwin-rebuild switch --flake .#$HOSTNAME"
```

Make it executable:
```bash
chmod +x bin/new-host
```

#### Step 4.4: Update AGENTS.md and CLAUDE.md

**File**: `AGENTS.md` - Add note about multi-host

```markdown
# Agent Instructions

## Multi-Host Configuration

This repo supports multiple Darwin hosts. When making system changes:

1. **User-specific changes** → `users/${username}/`
2. **Host-specific changes** → `hosts/${hostname}/`
3. **Changes for all users** → `users/common/`
4. **Changes for all hosts** → `hosts/common.nix` or `modules/`

Always test changes on all configured hosts when modifying shared config.
```

#### Step 4.5: Final Validation

**Comprehensive test**:
```bash
# 1. Clean build
nix flake check

# 2. Build both hosts
nix build .#darwinConfigurations.megabookpro.system -o /tmp/megabookpro-result
nix build .#darwinConfigurations.${newlaptop}.system -o /tmp/${newlaptop}-result

# 3. Rebuild both (if possible)
# On megabookpro:
just rebuild

# On ${newlaptop}:
just rebuild

# 4. Verify no regressions
# Test key functionality:
# - Neovim launches
# - Hammerspoon loads
# - Ghostty opens
# - Tmux works
# - AI tools (claude-code, etc.) work
# - Git signing works
```

---

## Migration Checklist

### Phase 1: Restore mkSystem (Non-Breaking)
- [ ] Update `lib/mkSystem.nix` with modern enhancements
- [ ] Create `hosts/common.nix` with shared host config
- [ ] Create `users/common/{darwin.nix,home.nix}`
- [ ] Create `users/seth/{darwin.nix,home.nix,packages.nix}`
- [ ] Copy `home/` content to `users/common/home.nix`
- [ ] Update `flake.nix` to use mkSystem for megabookpro
- [ ] Rename `hosts/megabookpro.nix` → `hosts/megabookpro/default.nix`
- [ ] Build and validate (should be identical to current system)
- [ ] Rebuild megabookpro - verify everything works
- [ ] Commit changes: `jj describe -m "refactor: restore mkSystem for multi-host support"`

### Phase 2: Add New Laptop
- [ ] Gather new laptop info (hostname, username, system/arch)
- [ ] Create `hosts/${newlaptop}/default.nix`
- [ ] Create `users/${newuser}/{darwin.nix,home.nix,packages.nix}`
- [ ] Add new host to `flake.nix`
- [ ] Build configuration: `nix build .#darwinConfigurations.${newlaptop}.system`
- [ ] On new laptop: Install Nix (Determinate installer)
- [ ] On new laptop: Clone dotfiles
- [ ] On new laptop: Run initial `darwin-rebuild switch --flake .#${newlaptop}`
- [ ] Verify both laptops work independently
- [ ] Commit changes: `jj describe -m "feat: add ${newlaptop} host with ${newuser}"`

### Phase 3: Refactor Modules
- [ ] Create `modules/darwin/` directory
- [ ] Extract `modules/darwin/defaults.nix` from system.nix
- [ ] Extract `modules/darwin/system.nix` from system.nix
- [ ] Move `modules/brew.nix` → `modules/darwin/brew.nix`
- [ ] Create `modules/shared/` directory
- [ ] Extract `modules/shared/nix.nix` from system.nix
- [ ] Update `lib/mkSystem.nix` imports
- [ ] Update `hosts/common.nix` to remove duplicates
- [ ] Rebuild both hosts - verify no changes
- [ ] Commit changes: `jj describe -m "refactor: reorganize modules for clarity"`

### Phase 4: Cleanup and Documentation
- [ ] Archive old files to `_archive/pre-multi-host-migration/`
- [ ] Update `.gitignore` to exclude `_archive/`
- [ ] **Update `README.md` with bootstrap instructions and multi-host docs**
- [ ] **Add justfile test recipes (`test-build`, `test-diff`, `test-eval`, `test-host`, `test-clean`, `test-flake`)**
- [ ] **Update `flake.nix` apps section with modernized mkInit for multi-host bootstrap**
- [ ] Update `CLAUDE.md` with new structure
- [ ] Update `AGENTS.md` with multi-host guidance
- [ ] Create `bin/new-host` helper script
- [ ] Run final validation on both hosts
- [ ] **Test bootstrap process: `nix run .` from clean state**
- [ ] **Test idempotent builds: `just test-build testlaptop`**
- [ ] Update this document with "Completed" status
- [ ] Commit changes: `jj describe -m "docs: complete multi-host migration"`

---

## Risk Assessment and Mitigation

### Risks

1. **Breaking existing megabookpro setup during Phase 1**
   - **Likelihood**: Medium
   - **Impact**: High (can't rebuild existing system)
   - **Mitigation**: 
     - Test with `nix build` before `darwin-rebuild`
     - Use `nix store diff-closures` to verify identical output
     - Keep jujutsu operation log for instant rollback
     - Phase 1 designed to be non-breaking (migration, not refactor)

2. **Path resolution issues with users/common/ imports**
   - **Likelihood**: Medium
   - **Impact**: Medium (build failures)
   - **Mitigation**:
     - Use explicit relative imports in user configs
     - Test import resolution with `nix-instantiate --eval`
     - Validate with `nix flake check` before rebuilding

3. **Username/hostname parameter passing failures**
   - **Likelihood**: Low
   - **Impact**: Medium (config not parameterized correctly)
   - **Mitigation**:
     - Use `specialArgs` consistently (cleaner than `_module.args`)
     - Add assertions to validate parameter presence
     - Test with different username/hostname combinations

4. **Home-manager activation failures on new laptop**
   - **Likelihood**: Medium
   - **Impact**: Medium (new system doesn't activate properly)
   - **Mitigation**:
     - Build system closure before activating
     - Use `--show-trace` for detailed error messages
     - Have bootstrap script ready for re-initialization

5. **Secrets/agenix issues with new user**
   - **Likelihood**: Medium
   - **Impact**: High (can't access encrypted secrets)
   - **Mitigation**:
     - Plan agenix key generation for new user before migration
     - Document secret re-encryption process
     - Keep age keys backed up securely

### Rollback Procedures

**Phase 1 rollback** (if megabookpro breaks):
```bash
# 1. Use jujutsu to restore previous state
jj op log  # Find operation before Phase 1 changes
jj op restore <operation-id>

# 2. Rebuild from restored state
just rebuild

# 3. Verify system works again
```

**Phase 2 rollback** (if new laptop setup fails):
```bash
# On megabookpro (should be unaffected)
# No action needed - megabookpro continues working

# On new laptop (start fresh if needed)
# 1. Remove nix installation
/nix/nix-installer uninstall

# 2. Fix dotfiles config (remove newlaptop from flake.nix)
# 3. Reinstall nix and try again
```

**Phase 3/4 rollback** (if refactor causes issues):
```bash
# Use git/jj to restore specific files
jj restore <file>  # Restore individual file
# Or
jj op restore <operation-id>  # Restore entire operation

# Rebuild
just rebuild
```

---

## Success Criteria

Phase 1 is successful when:
- [ ] `nix flake check` passes
- [ ] `nix build .#darwinConfigurations.megabookpro.system` produces identical closure to current system
- [ ] `just rebuild` completes without errors
- [ ] All applications work as before (nvim, hammerspoon, ghostty, etc.)
- [ ] No regressions in any functionality

Phase 2 is successful when:
- [ ] New laptop builds successfully
- [ ] New laptop activates without errors
- [ ] New user can log in and use system
- [ ] Both laptops work independently
- [ ] Changes to shared config affect both hosts
- [ ] Changes to user-specific config only affect that user

Phase 3 is successful when:
- [ ] Modules are cleanly organized
- [ ] Both hosts rebuild without changes (diff-closures shows identical)
- [ ] No functionality regressions
- [ ] Code is more maintainable

Phase 4 is successful when:
- [ ] Documentation is complete and accurate
- [ ] Helper scripts work correctly
- [ ] No deprecated files in active codebase
- [ ] New hosts can be added easily using documented process

---

## Open Questions

1. **New laptop details** - Need to gather:
   - Hostname: `?`
   - Username: `?`
   - Architecture: `aarch64-darwin` or `x86_64-darwin`?
   - macOS version: `?`

2. **Shared vs. user-specific apps** - Which apps should be:
   - Installed for all users? (In `users/common/home.nix`)
   - User-specific? (In `users/${user}/packages.nix`)
   - Decision: Start with most in common, move to user-specific as needed

3. **Secrets management** - How to handle agenix for new user?
   - Generate new age key for new user
   - Re-encrypt shared secrets with both keys
   - Document process in Phase 2

4. **Homebrew casks** - Should brew packages be:
   - Shared across users? (System-wide)
   - Per-user? (User-specific via nix-homebrew)
   - Decision: Defer to Phase 2 based on new user's needs

---

## Post-Migration Benefits

Once complete, you'll have:

✅ **Easy host addition** - Add new Mac with `bin/new-host` + flake.nix edit  
✅ **Clean separation** - User config vs host config vs system config  
✅ **Shared configuration** - 95% shared, 5% customized  
✅ **Type safety** - Nix validates all configuration  
✅ **Version control** - All configs in git with full history  
✅ **Rollback capability** - Jujutsu + nix generations for safety  
✅ **Testability** - Build configs without activating  
✅ **Documentation** - Clear structure for future changes  

---

## Timeline Estimate

**Phase 1**: 2-4 hours
- 1-2 hours: Update mkSystem, create file structure
- 1 hour: Migrate home/ content to users/common/
- 30 min: Update flake.nix
- 30 min: Testing and validation

**Phase 2**: 1-2 hours (once new laptop info gathered)
- 30 min: Create new host/user configs
- 15 min: Update flake.nix
- 30 min: Initial setup on new laptop
- 30 min: Testing both laptops

**Phase 3**: 1-2 hours
- 1 hour: Split modules/system.nix
- 30 min: Update imports
- 30 min: Testing and validation

**Phase 4**: 1 hour
- 30 min: Documentation updates
- 15 min: Helper scripts
- 15 min: Final validation

**Total**: 5-9 hours over 1-2 days (with breaks for testing)

---

## References

- [Mitchell Hashimoto's nixos-config](https://github.com/mitchellh/nixos-config) - Original mkSystem pattern
- [Mitchell Hanberg's dotfiles](https://github.com/mhanberg/.dotfiles) - mkInit bootstrap pattern inspiration
- [Malo Bourgon's nixpkgs](https://github.com/malob/nixpkgs) - Advanced multi-host patterns
- [nix-darwin documentation](https://github.com/LnL7/nix-darwin)
- [home-manager documentation](https://nix-community.github.io/home-manager/)
- [Nix flakes documentation](https://nixos.wiki/wiki/Flakes)

---

**Confidence: 90%** - This plan is based on proven patterns from active nix-darwin configurations and your existing solid foundation. The main unknowns are the specific requirements for the new laptop/user, which will be clarified in Phase 2.

Good sir, this is your battle plan. The architecture is sound, the phases are sequenced for safety, and rollback procedures are in place. Shall we proceed with Phase 1?
