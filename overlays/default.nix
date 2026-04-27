{
  inputs,
  lib,
}: [
  inputs.mcp-servers-nix.overlays.default

  (final: prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (prev.stdenv.hostPlatform) system;
      config.allowUnfree = true;
      config.allowUnfreePredicate = _: true;
    };

    # direnv 2.37.1 tests hang/OOM in nix sandbox (fish OOM, zsh hangs)
    direnv = prev.direnv.overrideAttrs (old: {
      doCheck = false;
    });

    # ollama: nixos-25.11 is frozen at 0.12.11, need 0.20+ for gemma4 models
    ollama = final.unstable.ollama;

    # mise: 2026.4.20 not cached, use 2026.4.6 which has binary in cache.nixos.org
    mise = (import (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/716d1202c91ee02d6b9f3a281491becf17a9bc46.tar.gz";
      sha256 = "0c23g3flxl3ba5ldkz3ykcv7mvds37bashyn0id98am79p1vjzrb";
    }) { inherit (prev.stdenv.hostPlatform) system; config.allowUnfree = true; config.allowUnfreePredicate = _: true; }).mise;

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
