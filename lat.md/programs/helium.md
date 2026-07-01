# Helium browser

Helium is the primary browser. The key packaging detail: the source fork owns Widevine DRM injection and Developer ID signing, and the Nix package here is a thin consumer of the signed DMG.

The package is `pkgs/helium-browser.nix`; the Home Manager module is `home/common/programs/helium-browser/`; the shared Chromium-browser option builder is `lib/builders/mkChromiumBrowser.nix`.

## Declarative Darwin build

`pkgs/helium-browser.nix` is a thin consumer: fetch a signed DMG with `_7zz`, `cp -R Helium.app`, `makeWrapper` `bin/helium`. No Widevine download, no helper re-signing, no `codesign` — the build log has zero of any of those.

Widevine CDM injection and Developer ID signing happen in the source fork (`megalithic/helium-macos`), via `inject_widevine.sh` wired into the build pipeline before signing. The signed DMG is published as a GitHub release and consumed by `fetchurl` here. Until the first megalithic signed release ships (release ticket), `src` points at the upstream `imputnet` 0.12.5.1 DMG, which has no Widevine — DRM regresses temporarily, by design. The release ticket bumps `version` + `src` to the megalithic release.

Local iteration uses the `localSrc ? null` override seam: `pkgs.helium-browser.override { localSrc = /path/to/helium_X_signed.dmg; }` consumes a locally built DMG without touching the release fetch. `passthru.appLocation = "wrapper"` keeps `mkChromiumBrowser` from double-installing the base `.app` into `home.packages`.

The extension update URL reads Chromium `prodversion` from the framework's `Versions/` directory at eval time via `builtins.readDir`, staying in sync with the package automatically.

## Runtime flags via mkChromiumBrowser

`mkChromiumBrowser.nix` generates Chromium command-line flags from structured options so browser modules don't hard-code switches in `commandLineArgs`:

- `remoteDebuggingPort` (`nullOr port`, default `null`) appends `--remote-debugging-port=<port>` when set. Helium sets `9223` (Brave Nightly uses 9222). The flag is runtime-only and does not touch the bundle, so Gatekeeper, codesign, TCC identity, Widevine, and 1Password pairing are unaffected.
- `experimentalFeatures.enable` / `.disable` (`listOf str`) append `--enable-features=A,B` and `--disable-features=C,D`. Helium disables `OutdatedBuildDetector`, which nags on non-upstream builds.
- `customAccelerators` (`attrsOf submodule { added, removed }`) is a deferred seam for native macOS accelerator overrides — defined but not wired yet (native shortcut customization is deferred).

These compose into `effectiveArgs = commandLineArgs ++ generatedArgs`, which feeds the wrapper `.app` args, the CLI wrapper `--add-flags`, and the `wrapperAppPackage` / `home.packages` gating conditions.

## Managed preferences (Chromium policy)

The HM module installs `~/Library/Managed Preferences/net.imput.helium.plist` from a nix-built XML plist via `home.activation.heliumManagedPrefs`, so `chrome://policy` reflects the settings on next launch.

- `ExtensionSettings` — dict keyed by extension id; each entry `installation_mode = "force_installed"` plus `update_url` with `prodversion` baked in. Force-installs Surfingkeys, Firenvim, LiveDebugger, Clear Downloads, Enhancer for YouTube.
- `DeveloperToolsAvailability` — int-enum `1` (`DeveloperToolsAllowed`): allow devtools everywhere, including on force-installed extensions (needed for LiveDebugger). `0` disallows on forced extensions (the default), `2` disallows everywhere.
- `CommandLineFlagSecurityWarningsEnabled` — `false`: suppress the "unsupported flag" banner for `--remote-debugging-port` and friends.
- `DefaultSearchProviderEnabled` / `DefaultSearchProviderName` / `DefaultSearchProviderSearchURL` / `DefaultSearchProviderKeyword` — pin Kagi as the default search engine.

`SUAutomaticallyUpdate` and `SUEnableAutomaticChecks` are Sparkle/NSUserDefaults keys, not Chromium policies, so they stay in `targets.darwin.defaults` (via `mkChromiumBrowser`) and are intentionally not in the managed plist.

The `ExtensionSettings` force-install is authoritative; the External Extensions JSON that `mkChromiumBrowser.extensions` also writes (in `Application Support/net.imput.helium/External Extensions/`) is a redundant fallback kept until a follow-up prunes it.

## Home Manager install

Home Manager installs Helium to `/Applications/Helium.app` from the Nix package via `rsync -a --inplace --checksum --delete --chmod=u+w` and does no signing of its own — the artifact is already signed in the source build.

`--checksum` is mandatory: Nix store files all have mtime `Dec 31 1969` and Chromium's main exec stub keeps the same byte size across minor versions, so rsync's default size+mtime check would skip the main exec on a version bump and leave a half-updated bundle that crashes with SIGABRT. `--inplace` preserves existing app and executable inodes for Gatekeeper/TCC caches; `--chmod=u+w` keeps replaced files writable for later rebuilds. Activation skips the copy while `/Applications/Helium.app` is running and avoids direct writes to Helium's Chromium profile files. Sparkle auto-update defaults are set through `targets.darwin.defaults` (`net.imput.helium`).

## Hammerspoon launch path

Helium is the primary Hammerspoon browser (`BROWSER = "net.imput.helium"`), launched through the same generic `summon.toggle` / `summon.focus` path as every other launcher, not a Helium-specific `hs.task` branch.

Hammerspoon opens Helium by bundle id via LaunchServices, which resolves to `/Applications/Helium.app` and forwards no flags (no remote-debugging port). The fish `helium` function instead launches the Nix-built bundle directly and adds declarative Chromium flags including `--remote-debugging-port=9223`. Because the source build always injects Widevine, the bundle has DRM regardless of which copy launches — there is no longer a "Widevine stripped by Sparkle" caveat for the `/Applications` copy. The `--remote-debugging-port` flag is runtime-only and does not touch the bundle, so Gatekeeper, codesign, TCC identity, Widevine, and 1Password pairing are unaffected. Port 9223 avoids clashing with Brave Nightly's 9222.

Hammerspoon browser tab automation treats Helium as the preferred Chromium browser: interop checks `BROWSER` first, keeps Helium in supported names and bundle IDs, and walks the app's accessibility menu tree for an enabled "move tab to new window" item instead of falling back to Chromium's incognito shortcut.

## 1Password desktop pairing (manual)

1Password pairs with browser extensions by allowlisting the app's code-signing team ID. The source build signs Helium with a Developer ID cert (not imput's team ID), so add it to 1Password manually once per signed-build team ID.

1. Open/unlock 1Password for Mac.
2. Settings → Browser → Add Browser.
3. Select `/Applications/Helium.app`.
4. Confirm the prompt (1Password warns that additional browsers get full access).

There is no CLI/programmatic method on Mac — this is GUI-only. After the step, the 1Password extension in Helium connects to the desktop app and autofill works. If the signing team ID changes (new cert), repeat the step.

## Browser automation

Pi's `web-browser` skill drives Helium through the `chrome-devtools` MCP server (`chrome-devtools-mcp` on npm).

Three MCP variants are configured in `mcp.json`: `chrome-devtools` (isolated temp profile, default), `chrome-devtools-profile` (copied from daily Helium or Brave, disabled by default), and `chrome-devtools-attach` (attach to running Helium on port 9223, disabled by default). A `copy-profile.sh` helper copies the daily profile to `~/.cache/agent-web/profile-copy/`. `chrome-devtools-attach` works when Helium was launched via the fish `helium` function, which adds `--remote-debugging-port=9223`; LaunchServices/Hammerspoon launches by bundle id omit the flag, so a CDP attach requires the fish-function launch.
