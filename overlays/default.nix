# Overlay composition
#
# This file composes all overlays that get applied to nixpkgs:
#   - External overlays from flake inputs (nur, fenix, mcp-servers, etc.)
#   - Package set aliases (stable, unstable)
#   - Input package aliases (ai-tools, nvim-nightly, etc.)
#   - Custom packages from pkgs/ directory
#
# For YOUR custom package definitions (mkApp, callPackage derivations),
# see pkgs/default.nix instead.
#
{
  inputs,
  lib,
}: [
  # ===========================================================================
  # External Overlays (from flake inputs)
  # ===========================================================================
  inputs.nur.overlays.default
  inputs.fenix.overlays.default
  inputs.mcp-servers-nix.overlays.default

  # ===========================================================================
  # Package Sets & Input Aliases
  # ===========================================================================
  # Provides: pkgs.stable.*, pkgs.unstable.*, pkgs.ai-tools.*, etc.
  (final: prev: {
    # Pinned package sets for stability
    stable = import inputs.nixpkgs-stable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    # Input package aliases (convenient access without inputs.foo.packages.system)
    ai-tools = inputs.nix-ai-tools.packages.${prev.stdenv.hostPlatform.system};
    mcphub = inputs.mcp-hub.packages.${prev.stdenv.hostPlatform.system}.default;
    nvim-nightly = inputs.neovim-nightly-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
    expert = inputs.expert.packages.${prev.stdenv.hostPlatform.system}.default;

    # Package overrides
    notmuch = prev.notmuch.override {withEmacs = false;};
  })

  # ===========================================================================
  # Custom Packages (from pkgs/)
  # ===========================================================================
  (import ../pkgs {inherit lib;})
]
