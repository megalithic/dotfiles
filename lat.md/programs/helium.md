# Helium browser

Helium is the primary browser, consumed as pre-signed, notarized DMG releases from the `megalithic/helium-macos-releases` repo (public since 2026-07) — CI bakes Widevine in and Developer ID signs the bundle, so nothing signs or injects locally.

Both hosts install Helium through mise (`[tools."github:megalithic/helium-macos-releases"]`); the Home Manager module (`home/common/programs/helium-browser/`) was removed in the megabookpro wave-1 mise flip. `pkgs/helium-browser.nix` remains in the tree but is unreferenced by Home Manager; retire it with `bin/helium-prefetch` in the teardown wave. (That package replaced a legacy one that injected Widevine into imput's public DMG and ad-hoc re-signed helpers locally; see git history for that machinery.)

## Signed release package

`pkgs/helium-browser.nix` unpacks DMGs from the `megalithic/helium-macos-releases` repo, whose CI builds Helium with Widevine already injected, then Developer ID signs (team `3ZJ3F5RFBZ`) and notarizes the bundle.

Nothing consumes the package since the module removal (it was `programs.helium-browser.package` via the `mkChromiumBrowser` default). Its extension update URL reads Chromium prodversion from the framework's `Versions/` directory at eval time via `builtins.readDir`, staying in sync with the package automatically.

Because the bundle arrives fully signed, the package does no Widevine injection and no re-signing: `dontFixup` and `dontPatchShebangs` keep bytes identical, the deep codesign seal survives 7zz extraction, and Gatekeeper accepts with no per-build "Open Anyway" click. The nix-daemon cannot fetch the private asset (fixed-output `impureEnvVars`/`netrcPhase` read the daemon's env, not the user's shell, and Determinate Nix ignores `impure-env`), so `src` is a `requireFile` and `bin/helium-prefetch` pre-seeds the exact fixed-output store path via authenticated `gh` plus `nix-prefetch-url --name`, verifying the release's `.sha256` asset first. Version bumps update `version`/`sha256` in the package and re-run the prefetch.

The signing team differs from imput's (`S4Q33XPHB4`), which 1Password's pairing allowlist keyed on, so the signed build needs a trusted-browser entry in 1Password. That entry (`browsers.other-trusted-apps` in 1Password's `settings.json`: base64url bundle id → codesign requirement pinned to the team OU) is integrity-protected — 1Password detects external edits at startup and resets them ("had an untrusted value, it will be reset!"), so it cannot be managed declaratively. The only path is the GUI, once per machine per signing team: 1Password → Settings → Browser → Add Browser → `/Applications/Helium.app`. `bin/helium-1password-trust` is a checker: it validates the entry exists and pins the installed app's team, and prints the GUI steps when action is needed. Both scripts live in repo `bin/` (`~/bin` via Home Manager during migration; `[dotfiles]` symlink-each in mise); mise additionally exposes the checker as `mise run helium:1password-trust` in `mise/config/mise/global_config.toml`.

Since the releases repo went public, the mise world installs Helium declaratively via `[tools."github:megalithic/helium-macos-releases"]` (version `latest`, `asset_pattern` for the arm64 DMG, sha256 verified by mise against the release's `.sha256` asset). mise does not extract `.dmg` assets — and renames a single-file asset to the tool's short name, dropping the suffix — so the `postinstall` hook `mise/hooks/install-app.sh` finds the payload (by `.dmg` glob, else largest file), mounts it with hdiutil, and swaps the bundle into `/Applications`; it reruns on version changes, which is the upgrade path. `mise run setup:helium:install` (`mise/tasks/install-helium`: GitHub releases API download + `.sha256` verify + hdiutil copy, token now optional) remains as a manual fallback and no longer runs in the `bootstrap` task; the secrets chain there (`setup:op:signin` → `setup:fnox:render`) persists for other secrets, not for Helium.

## Mise declarative profile setup

The mise world replicates the module's declarative profile/prefs pieces via `mise/tasks/setup-helium` (`mise run setup:helium`, alias `helium:setup`).

It writes the five `External Extensions/<id>.json` files, sets `NSUserKeyEquivalents` plus the Sparkle kill-switch defaults on `net.imput.helium`, and installs the `en-US-10-1.bdic` spellcheck dictionary (fetched from chromium's `hunspell_dictionaries` gitiles, the same upstream nixpkgs uses; non-fatal on failure). It deliberately never touches profile JSON such as "Secure Preferences".

The prodversion baked into the extension update URLs is read at runtime from the installed app's framework `Versions/` dir — the mise equivalent of the nix module's eval-time `readDir`. Because it goes stale on Chromium bumps, the helium tool's `postinstall` in `global_config.toml` chains `install-app.sh && setup-helium`, so every install/upgrade re-bakes it. Sparkle defaults are additionally declared in `[bootstrap.macos.defaults."net.imput.helium"]` for fresh-machine bootstrap; the task repeats them because `mise run up` skips the macos-defaults step. Chromium picks up External Extensions on next launch; deleting a JSON uninstalls and blocklists the extension, so ids dropped from the list are left on disk. `mise run helium:1password-trust` runs the trust checker.

## Home Manager install (removed)

The Home Manager install path is removed with the module; mise's `install-app.sh` postinstall now owns `/Applications/Helium.app` on both hosts.

That path was an rsync of the Nix package into `/Applications/Helium.app` with `requireFile` + `bin/helium-prefetch` store seeding. Sparkle auto-update defaults still come from nix-darwin `system.defaults.CustomUserPreferences."net.imput.helium"` on megabookpro until system teardown; mise declares the same in `[bootstrap.macos.defaults."net.imput.helium"]` and `setup-helium`.

## Hammerspoon launch path

Helium is the primary Hammerspoon browser (`BROWSER = "net.imput.helium"`), bound to hyper+j through the generic `summon` launcher path with one Helium-relevant twist: `opts.launchCommand`.

`bin/helium-launch` is the single source of truth for launch flags: it execs `/Applications/Helium.app/Contents/MacOS/Helium` with declarative Chromium flags including `--remote-debugging-port=9223`, then detaches (nohup + background) and exits. Three consumers share it: the fish `helium` function (thin delegate), Hammerspoon's hyper+j cold start (`launchCommand` opt in `C.launchers`, spawned via `hs.task`), and both worlds get it from repo `bin/` (`~/bin` via Home Manager; `[dotfiles]` symlink-each in mise). LaunchServices forwards no command-line flags, which is why the cold start must bypass `launchOrFocusByBundleID`; once Helium runs, hyper+j only focuses/cycles windows and flags are moot — they only matter at process start. The `--remote-debugging-port` flag is runtime-only and does not touch the bundle, so Gatekeeper, codesign, TCC identity, Widevine, and 1Password pairing are unaffected. Port 9223 avoids clashing with Brave Nightly's 9222.

The launcher targets `/Applications/Helium.app` (not the Home Manager copyApps bundle): with the signed release build, Widevine is baked in and Sparkle is disabled declaratively, so the old reason to prefer the copyApps copy — Sparkle stripping injected Widevine from `/Applications` — no longer applies.

Hammerspoon browser tab automation treats Helium as the preferred Chromium browser: interop checks `BROWSER` first, keeps Helium in supported names and bundle IDs, and walks the app's accessibility menu tree for an enabled "move tab to new window" item instead of falling back to Chromium's incognito shortcut.

## Browser automation

Pi's `web-browser` skill drives Helium through the `chrome-devtools` MCP server (`chrome-devtools-mcp` on npm).

Three MCP variants are configured in `mcp.json`: `chrome-devtools` (isolated temp profile, default), `chrome-devtools-profile` (copied from daily Helium or Brave, disabled by default), and `chrome-devtools-attach` (attach to running Helium on port 9223, disabled by default). A `copy-profile.sh` helper copies the daily profile to `~/.cache/agent-web/profile-copy/`. `chrome-devtools-attach` works when Helium was cold-started through `bin/helium-launch` (fish `helium` function or Hammerspoon hyper+j `launchCommand`), which adds `--remote-debugging-port=9223`; a bare LaunchServices launch (`open -a`, Finder) omits the flag and breaks CDP attach until relaunch.
