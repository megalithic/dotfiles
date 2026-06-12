{ inputs }:
[
  inputs.brew-nix.overlays.default

  (_: prev: {
    # pi-coding-agent = prev.pi-coding-agent.overrideAttrs (old: {
    #   postInstall =
    #     (old.postInstall or "")
    #     + ''
    #       # Find agent-session.js regardless of namespace (@earendil-works, @mariozechner, pi-monorepo)
    #       TARGET=$(find $out/lib/node_modules -path '*/dist/core/agent-session.js' -print -quit)
    #       if [ -z "$TARGET" ]; then
    #         echo "WARNING: agent-session.js not found, skipping pi patches"
    #       else
    #         # 1. Skip maxRetries cap for 429/rate-limit errors
    #         substituteInPlace "$TARGET" \
    #           --replace-fail 'if (this._retryAttempt > settings.maxRetries) {' \
    #           'const _is429 = /429|rate.?limit|too many requests/i.test(message.errorMessage || ""); if (!_is429 && this._retryAttempt > settings.maxRetries) {'
    #
    #         # 2. Cap delay at maxDelayMs (set to 900000/15min in settings.json)
    #         substituteInPlace "$TARGET" \
    #           --replace-fail 'const delayMs = settings.baseDelayMs * 2 ** (this._retryAttempt - 1);' \
    #           'const delayMs = Math.min(settings.baseDelayMs * 2 ** (this._retryAttempt - 1), settings.maxDelayMs);'
    #
    #         # 3. Expose setScopedModels to extensions via providerActions
    #         substituteInPlace "$TARGET" \
    #           --replace-fail \
    #             'unregisterProvider: (name) => {' \
    #             'setScopedModels: (models) => { this.setScopedModels(models); }, unregisterProvider: (name) => {'
    #
    #         # 4. Wire setScopedModels through to extension runtime
    #         RUNNER=$(find $out/lib/node_modules -path '*/dist/core/extensions/runner.js' -print -quit)
    #         if [ -n "$RUNNER" ]; then
    #           substituteInPlace "$RUNNER" \
    #             --replace-fail \
    #               'this.runtime.registerProvider = (name, config) => {' \
    #               'this.runtime.setScopedModels = providerActions?.setScopedModels ?? (() => {}); this.runtime.registerProvider = (name, config) => {'
    #         fi
    #       fi
    #     '';
    # });

    # llama-cpp: nodejs 24 hits a libuv kqueue assertion (Abort trap: 6) on darwin
    # during the webui `npm run build` teardown. Artifacts are already produced
    # when it aborts, but nix sees the non-zero exit. Pin nodejs_22 for the webui
    # build to dodge the libuv bug. Upstream report: nodejs/node#56831.
    llama-cpp = prev.llama-cpp.override { nodejs_latest = prev.nodejs_22; };

    # # https://github.com/NixOS/nixpkgs/pull/485980
    # dbus = prev.dbus.overrideAttrs (old: {
    #   mesonFlags =
    #     old.mesonFlags or []
    #     ++ [
    #       (prev.lib.mesonOption "dbus_session_bus_listen_address" "unix:tmpdir=/tmp")
    #     ];
    # });
  })
]
