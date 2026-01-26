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
}:
[
  # ===========================================================================
  # External Overlays (from flake inputs)
  # ===========================================================================
  inputs.nur.overlays.default
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
    # llm-agents = let
    #   upstream = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
    #   # Import llm-agents' custom npm fetcher for hash overrides
    #   npmPackumentSupport = prev.callPackage "${inputs.llm-agents}/lib/fetch-npm-deps.nix" {};
    # in
    #   upstream
    #   // {
    #     # FIXME: Override claude-code-acp npmDeps hash due to npm registry instability
    #     # Remove this override when upstream hash stabilizes
    #     claude-code-acp = upstream.claude-code-acp.overrideAttrs (old: {
    #       npmDeps = npmPackumentSupport.fetchNpmDepsWithPackuments {
    #         inherit (old) src;
    #         name = "${old.pname}-${old.version}-npm-deps";
    #         hash = "sha256-Pxgc5Xbh8IkHbk90WScVvvs98Nk4Svkb0r6lWMFyfwk=";
    #         fetcherVersion = 2;
    #       };
    #     });
    #   };
    llm-agents = let
      upstream = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
    in
      upstream
      // {
        # FIXME: Override claude-code to fix undefined maintainer 'ryoppippi'
        # Upstream bug: https://github.com/numtide/llm-agents.nix/blob/765ba8f/packages/claude-code/package.nix#L75
        # Remove this override when upstream adds ryoppippi to lib/default.nix maintainers
        claude-code = upstream.claude-code.overrideAttrs (old: {
          meta = old.meta // {
            maintainers = with prev.lib.maintainers; [
              malo
              omarjatoi
            ];
          };
        });
      };
    mcphub = inputs.mcp-hub.packages.${prev.stdenv.hostPlatform.system}.default;
    nvim-nightly = inputs.neovim-nightly-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
    expert = inputs.expert.packages.${prev.stdenv.hostPlatform.system}.default;
    # FIXME: Shade flake tries to extract GhosttyKit from Ghostty's Nix output,
    # but Ghostty's Nix build doesn't produce a macOS app bundle with the framework.
    # Upstream fix needed in shade repo's flake.nix
    # shade = inputs.shade.packages.${prev.stdenv.hostPlatform.system}.default;

    # Package overrides
    notmuch = prev.notmuch.override { withEmacs = false; };
  })

  # ===========================================================================
  # Custom Packages (from pkgs/)
  # ===========================================================================
  (import ../pkgs { inherit lib; })
]
