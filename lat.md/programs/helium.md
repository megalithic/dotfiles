# Helium browser

Helium is the primary browser, with unusually intricate packaging: the Nix build injects Widevine DRM and re-signs helper bundles so DRM playback and 1Password desktop pairing both keep working.

The package is `pkgs/helium-browser.nix`; the Home Manager module is `home/common/programs/helium-browser/`. A parallel signed-release package, `pkgs/helium-browser-signed.nix`, consumes pre-signed DMGs from a private releases repo and needs none of the injection/re-signing machinery.

## Declarative Darwin build

`pkgs/helium-browser.nix` injects Google's Widevine CDM, leaves the main app `Contents/Info.plist` untouched, then strips and ad-hoc re-signs only the helper `.app` bundles in `postFixup`.

The Widevine CDM goes into `Helium Framework.framework/Versions/<v>/Libraries/WidevineCdm/`. The build does not add TCC purpose strings because `Contents/Info.plist` is sealed by the main app's Developer ID signature; mutating it makes codesign report `invalid Info.plist` and can destabilize TCC identity.

`Helium Helper.app` is signed with `--options=runtime,kill,restrict` (hardened runtime minus library validation) plus `com.apple.security.cs.disable-library-validation` so the Google-team-signed Widevine `.dylib` loads in that helper.

The main exec, `Helium Framework.framework`, and `Sparkle.framework` keep imput LLC's original signatures (`S4Q33XPHB4`) untouched, because 1Password's `verifyClient` allowlists imput's team ID for desktop pairing and hardened-runtime library validation between the main exec and framework requires same-team signatures.

Replacing the helper `_CodeSignature` dirs breaks the outer bundle seal, so the first launch per build needs one Gatekeeper "Open Anyway" click in System Settings → Privacy & Security; later launches reuse the cached `ExecPolicy` override keyed by bundle directory inode. The extension update URL reads Chromium prodversion from the framework's `Versions/` directory at eval time via `builtins.readDir`, staying in sync with the package automatically.

## Signed release package

`pkgs/helium-browser-signed.nix` unpacks DMGs from the private `megalithic/helium-macos-releases` repo, whose CI builds Helium with Widevine already injected, then Developer ID signs (team `3ZJ3F5RFBZ`) and notarizes the bundle.

Because the bundle arrives fully signed, the package does no Widevine injection and no re-signing: `dontFixup` and `dontPatchShebangs` keep bytes identical, the deep codesign seal survives 7zz extraction, and Gatekeeper accepts with no per-build "Open Anyway" click. The nix-daemon cannot fetch the private asset (fixed-output `impureEnvVars`/`netrcPhase` read the daemon's env, not the user's shell, and Determinate Nix ignores `impure-env`), so `src` is a `requireFile` and `bin/helium-prefetch` pre-seeds the exact fixed-output store path via authenticated `gh` plus `nix-prefetch-url --name`, verifying the release's `.sha256` asset first. Version bumps update `version`/`sha256` in the package and re-run the prefetch.

The signing team differs from imput's (`S4Q33XPHB4`), which 1Password's pairing allowlist keyed on, so the signed build needs a trusted-browser entry in 1Password. That entry (`browsers.other-trusted-apps` in 1Password's `settings.json`: base64url bundle id → codesign requirement pinned to the team OU) is integrity-protected — 1Password detects external edits at startup and resets them ("had an untrusted value, it will be reset!"), so it cannot be managed declaratively. The only path is the GUI, once per machine per signing team: 1Password → Settings → Browser → Add Browser → `/Applications/Helium.app`. `bin/helium-1password-trust` is a checker: it validates the entry exists and pins the installed app's team, and prints the GUI steps when action is needed. Both scripts serve the nix config (`~/bin` via Home Manager) and the mise config (`[dotfiles]` symlink-each of `bin/`); the mise world additionally exposes the checker as `mise run helium:1password-trust` in `_mise.toml`, next to the `brew-cask:megalithic/helium/helium` install it pairs with.

`programs.helium-browser.package` still defaults to the legacy `pkgs.helium-browser`; adopting the signed build means pointing it at `pkgs.helium-browser-signed`. Until then, `just home` rsyncs the legacy build back over `/Applications/Helium.app`, which is a Chromium profile-downgrade hazard after the newer signed version has run.

## Home Manager install

Home Manager installs Helium to `/Applications/Helium.app` from the Nix package via `rsync -a --inplace --checksum --delete --chmod=u+w` and does no signing of its own.

`--checksum` is mandatory: Nix store files all have mtime `Dec 31 1969` and Chromium's main exec stub keeps the same byte size across minor versions, so rsync's default size+mtime check would skip the main exec on a version bump and leave a half-updated bundle that crashes with SIGABRT. `--inplace` preserves existing app and executable inodes for Gatekeeper/TCC caches; `--chmod=u+w` keeps replaced files writable for later rebuilds. Activation skips the copy while `/Applications/Helium.app` is running and avoids direct writes to Helium's Chromium profile files. Sparkle auto-update defaults are set through nix-darwin `system.defaults.CustomUserPreferences."net.imput.helium"`.

## Hammerspoon launch path

Helium is the primary Hammerspoon browser (`BROWSER = "net.imput.helium"`), bound to hyper+j through the generic `summon` launcher path with one Helium-relevant twist: `opts.launchCommand`.

`bin/helium-launch` is the single source of truth for launch flags: it execs `/Applications/Helium.app/Contents/MacOS/Helium` with declarative Chromium flags including `--remote-debugging-port=9223`, then detaches (nohup + background) and exits. Three consumers share it: the fish `helium` function (thin delegate), Hammerspoon's hyper+j cold start (`launchCommand` opt in `C.launchers`, spawned via `hs.task`), and both worlds get it from repo `bin/` (`~/bin` via Home Manager; `[dotfiles]` symlink-each in mise). LaunchServices forwards no command-line flags, which is why the cold start must bypass `launchOrFocusByBundleID`; once Helium runs, hyper+j only focuses/cycles windows and flags are moot — they only matter at process start. The `--remote-debugging-port` flag is runtime-only and does not touch the bundle, so Gatekeeper, codesign, TCC identity, Widevine, and 1Password pairing are unaffected. Port 9223 avoids clashing with Brave Nightly's 9222.

The launcher targets `/Applications/Helium.app` (not the Home Manager copyApps bundle): with the signed release build, Widevine is baked in and Sparkle is disabled declaratively, so the old reason to prefer the copyApps copy — Sparkle stripping injected Widevine from `/Applications` — no longer applies.

Hammerspoon browser tab automation treats Helium as the preferred Chromium browser: interop checks `BROWSER` first, keeps Helium in supported names and bundle IDs, and walks the app's accessibility menu tree for an enabled "move tab to new window" item instead of falling back to Chromium's incognito shortcut.

## Browser automation

Pi's `web-browser` skill drives Helium through the `chrome-devtools` MCP server (`chrome-devtools-mcp` on npm).

Three MCP variants are configured in `mcp.json`: `chrome-devtools` (isolated temp profile, default), `chrome-devtools-profile` (copied from daily Helium or Brave, disabled by default), and `chrome-devtools-attach` (attach to running Helium on port 9223, disabled by default). A `copy-profile.sh` helper copies the daily profile to `~/.cache/agent-web/profile-copy/`. `chrome-devtools-attach` works when Helium was launched via the fish `helium` function, which adds `--remote-debugging-port=9223`; LaunchServices/Hammerspoon launches by bundle id omit the flag, so a CDP attach requires the fish-function launch.
