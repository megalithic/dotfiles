{
  inputs,
  lib,
}: [
  inputs.nur.overlays.default
  inputs.mcp-servers-nix.overlays.default

  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    # direnv 2.37.1 fish test gets OOM-killed in nix sandbox
    direnv = prev.direnv.overrideAttrs (old: {
      doCheck = false;
    });

    # NOTE: keeping these around for posterity and quicker reference
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

    # llm-agents = let
    #   upstream = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
    # in
    #   upstream
    #   // {
    #     # FIXME: Override claude-code to fix undefined maintainer 'ryoppippi'
    #     # Upstream bug: https://github.com/numtide/llm-agents.nix/blob/765ba8f/packages/claude-code/package.nix#L75
    #     # Remove this override when upstream adds ryoppippi to lib/default.nix maintainers
    #     claude-code = upstream.claude-code.overrideAttrs (old: {
    #       meta =
    #         old.meta
    #         // {
    #           maintainers = with prev.lib.maintainers; [
    #             malo
    #             omarjatoi
    #           ];
    #         };
    #     });
    #   };

    llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};
    nvim-nightly = inputs.neovim-nightly-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
    devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
    expert = inputs.expert.packages.${prev.stdenv.hostPlatform.system}.default;
    notmuch = prev.notmuch.override {withEmacs = false;};
    
    # shade - Floating terminal panel for macOS (prebuilt from GitHub release)
    shade = prev.stdenv.mkDerivation {
      pname = "shade";
      version = "0.2.0";

      src = prev.fetchurl {
        url = "https://github.com/megalithic/shade/releases/download/v0.2.0/shade-darwin-arm64.tar.gz";
        sha256 = "0ea3ae15aec865b6ba93aa838ebd856615c64e77bb3dc4ce53c04d9143c89e94";
      };

      # tarball contains: shade (binary) + mlx.metallib
      sourceRoot = ".";

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/share/shade
        cp shade $out/bin/shade
        cp mlx.metallib $out/share/shade/mlx.metallib
        runHook postInstall
      '';

      meta = with prev.lib; {
        description = "Floating terminal panel for macOS powered by libghostty";
        homepage = "https://github.com/megalithic/shade";
        license = licenses.mit;
        platforms = platforms.darwin;
        mainProgram = "shade";
      };
    };
  })

  # my custom packages (pkgsf)
  (import ../pkgs {inherit lib;})
]
