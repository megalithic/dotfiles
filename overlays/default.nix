{
  inputs,
  lib,
}:
[
  inputs.brew-nix.overlays.default

  (_: prev: {
    # direnv 2.37.1 tests hang/OOM in nix sandbox (fish OOM, zsh hangs)
    direnv = prev.direnv.overrideAttrs (_: {
      doCheck = false;
    });

    # mise: 2026.4.20 not cached, use 2026.4.6 which has binary in cache.nixos.org
    inherit
      (
        (import
          (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/716d1202c91ee02d6b9f3a281491becf17a9bc46.tar.gz";
            sha256 = "0c23g3flxl3" + "b" + "a5ldkz3ykcv7mvds37bashyn0id98am79p1vjzrb";
          })
          {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
            config.allowUnfreePredicate = _: true;
          }
        )
      )
      mise
      ;

    nvim-nightly = inputs.neovim-nightly-overlay.packages.${prev.stdenv.hostPlatform.system}.default;
    devenv = inputs.devenv.packages.${prev.stdenv.hostPlatform.system}.devenv;
    notmuch = prev.notmuch.override { withEmacs = false; };

    # pi-coding-agent: patch retry behavior + expose setScopedModels to extensions
    pi-coding-agent = prev.pi-coding-agent.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        # Find agent-session.js regardless of namespace (@earendil-works, @mariozechner, pi-monorepo)
        TARGET=$(find $out/lib/node_modules -path '*/dist/core/agent-session.js' -print -quit)
        if [ -z "$TARGET" ]; then
          echo "WARNING: agent-session.js not found, skipping pi patches"
        else
          # 1. Skip maxRetries cap for 429/rate-limit errors
          substituteInPlace "$TARGET" \
            --replace-fail 'if (this._retryAttempt > settings.maxRetries) {' \
            'const _is429 = /429|rate.?limit|too many requests/i.test(message.errorMessage || ""); if (!_is429 && this._retryAttempt > settings.maxRetries) {'

          # 2. Cap delay at maxDelayMs (set to 900000/15min in settings.json)
          substituteInPlace "$TARGET" \
            --replace-fail 'const delayMs = settings.baseDelayMs * 2 ** (this._retryAttempt - 1);' \
            'const delayMs = Math.min(settings.baseDelayMs * 2 ** (this._retryAttempt - 1), settings.maxDelayMs);'

          # 3. Expose setScopedModels to extensions via providerActions
          substituteInPlace "$TARGET" \
            --replace-fail \
              'unregisterProvider: (name) => {' \
              'setScopedModels: (models) => { this.setScopedModels(models); }, unregisterProvider: (name) => {'

          # 4. Wire setScopedModels through to extension runtime
          RUNNER=$(find $out/lib/node_modules -path '*/dist/core/extensions/runner.js' -print -quit)
          if [ -n "$RUNNER" ]; then
            substituteInPlace "$RUNNER" \
              --replace-fail \
                'this.runtime.registerProvider = (name, config) => {' \
                'this.runtime.setScopedModels = providerActions?.setScopedModels ?? (() => {}); this.runtime.registerProvider = (name, config) => {'
          fi
        fi
      '';
    });

    # llama-cpp: nodejs 24 hits a libuv kqueue assertion (Abort trap: 6) on darwin
    # during the webui `npm run build` teardown. Artifacts are already produced
    # when it aborts, but nix sees the non-zero exit. Pin nodejs_22 for the webui
    # build to dodge the libuv bug. Upstream report: nodejs/node#56831.
    llama-cpp = prev.llama-cpp.override { nodejs = prev.nodejs_22; };

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
  (import ../pkgs { inherit lib; })
]
