# Hammerspoon

Hammerspoon owns macOS automation: window management, launcher panels, menubar state, and clipboard tooling. mise owns it on both hosts — brew cask app, config in `mise/config/hammerspoon/`, fragments in `~/.local/share/hammerspoon/`.

The app installs via `brew install --cask hammerspoon`, declared in `[bootstrap.hooks.post-packages]` because the `brew-cask:` backend can't handle its `binary` artifacts. `[dotfiles]` links `~/.config/hammerspoon` to `mise/config/hammerspoon/`.

## Ownership flip from nix

The former HM module (`home/common/programs/hammerspoon/`) is removed; its launchd launcher + nix-store app copies caused duplicate instances at login.

The old setup installed `pkgs.brewCasks.hammerspoon`, generated `nix_path.lua`, and ran a launchd launcher agent that opened the Home Manager Apps copy. Duplicates happened because macOS window-resume relaunched the previous session's raw `/nix/store/...` path while the launchd agent opened the HM Apps path, and every rebuild minted a new store path that LaunchServices registered as a distinct app.

Now launch-at-login is Hammerspoon's own `hs.autoLaunch` login item pointing at the stable `/Applications/Hammerspoon.app`, and `~/.local/share/hammerspoon/nix_path.lua` is the committed static `mise/fragments/hammerspoon/nix_path.lua` (mise shims PATH; the `NIX_PATH`/`NIX_ENV` global names are kept for compatibility).

The old nix twin `config/hammerspoon/` is retired and no longer linked anywhere; `mise/config/hammerspoon/` is the sole source. Historical divergences that lived across the twins (kanata `daemonLabel` `dev.mise.` prefix, kanata stderr log path) are now just the mise values — the `dev.mise.` label comment in `config.lua` remains until kanata's own ownership is unified.

The mise `up` task ends by calling `bin/hs-reload` (non-fatal if Hammerspoon is not running) so a freshly synced config is picked up safely.

## Dock watcher

The dock watcher checks the current `kanata.kbd` symlink and launchd state before switching profiles.

If the requested profile already runs, Hammerspoon logs success and skips `launchctl kickstart`, so config reloads do not bounce Kanata. When a restart fails, the watcher reports stderr only if the stderr file changed during that restart attempt; stale Input Monitoring errors do not appear as fresh failures.

## Reload safety

**Hammerspoon must only be reloaded via `bin/hs-reload`.** Unsafe CLI reload paths can crash Hammerspoon.

`bin/hs-reload` prefers `open -g hammerspoon://hs-reload`, which Hammerspoon handles inside its own process by calling the wrapped `hs.reload()` cleanup path. It does not use `hs` CLI reload or `hs` CLI menu selection, because those IPC paths can crash/kill Hammerspoon while reloading.

If the running config is too old to have the URL handler, `bin/hs-reload` falls back to a System Events menu click and fails with an Accessibility-permission error instead of trying unsafe IPC fallbacks. Hammerspoon's preflight adds `~/.local/share/hammerspoon` to Lua `package.path` so generated data-only fragments such as `fragments/shade-next.lua` can be required without editing the generated file.

## Global app bindings

Global app bindings stay data-driven so app launchers, local pass-through keys, and URL-scheme actions share one configuration surface instead of per-app binding code.

`C.launchers` rows use `{ bundleID, bind, opts? }`: simple launchers omit `opts`, while `opts.passThrough`, `opts.focusOnly`, `opts.cycleWindows`, `opts.urlSchemes`, and `opts.launchCommand` handle exceptions. `opts.launchCommand` (string or argv table) replaces the LaunchServices cold start with a detaching launcher script — LaunchServices forwards no command-line flags, so launchers that need them (Helium's CDP port via `bin/helium-launch`) spawn the script through `hs.task`; focus/cycle of an already-running app never respawns. When `opts.cycleWindows = true`, hitting the app binding while that app is focused cycles visible app windows rather than browser tabs. Fantastical keeps `hyper+y` as the app toggle; `hyper+'` opens `x-fantastical3://parse?sentence=`; `hyper+shift+'` opens `x-fantastical3://parse?reminder=1&sentence=`.

## URL routing

Hammerspoon can act as the HTTP/S handler for app deep links while preserving browser auth flows.

`mise/config/hammerspoon/watchers/url.lua` redirects Figma web URLs to `figma://...`, but paths containing `auth` such as `/app_auth` pass through to the browser.

## shade-next panel

shade-next bindings are split between generated data and handwritten lifecycle code.

mise `[dotfiles]` links `~/.local/share/hammerspoon/fragments/shade-next.lua` from the static `mise/fragments/hammerspoon/shade-next.lua` and `~/.config/shade-next/config.toml` from `mise/config/shade-next/config.toml` (the former nix shade-next module that generated both is removed); `mise/config/hammerspoon/shade_next.lua` reads the fragment. The panel design spec lives in `~/.local/share/pi/docs/shade-next/panel-design.md`.

Key behavior: one panel-height rule across all states; block types are result cards, section lists, message rows, composer, and preview; Esc always hides the panel; route keys reserve Ctrl+n for note, Ctrl+p for Pi, Ctrl+c for calc. Compact launch geometry starts at `900×104` points and grows result panels to visible rows before clamping to the configured max height.

`hyper+return` talks directly to shade-next's control socket when the app is running. On a cold start, it invokes the mise-installed `shade-next` wrapper with the `shade-next://toggle` URL; the wrapper repairs the `~/Applications` symlink and LaunchServices registration before opening the URL. Direct URL dispatch remains only as a fallback for installs without the wrapper. The installed wrapper also makes bindings active without a local source build. When shade-next shows, it records the frontmost app before activating itself and restores it on hide without Accessibility APIs. `hyper+n` enters the route modal (`p` prefills `pi`, `n` prefills `note`). Legacy Shade keeps `hyper+return` for `shade.smartToggle()` and moves its advanced modal to `hyper+shift+n`.

The `[ui]` table in `mise/config/shade-next/config.toml` owns panel visual defaults including `border_width`, `border_color`, and `dim_unfocused`; the panel is non-opaque so the rounded material surface shows real transparency.

## Window management

Window management uses the custom `wm.lua` grid/geometry path on `hyper+l`; native Tahoe menu tiling is optional on `hyper+w`.

`wm.lua` converts the configured `C.grid` `60×20` positions into proportional screen-local frames and applies `C.windowGap` as a pixel inset so chained movement, center sizing, split tiling, browser tab splitting, and app layout automation keep spacing across displays. WM hypemode auto-exits after 2s idle; chained keys use a 1.25s `chainExitDelay`. `hyper+l,s` moves the active Helium/Chromium tab into a right-half window via `lib.interop.browser:splitTab(false)`; `hyper+l,shift+s` moves it full-size to the next screen.

App and window watchers run layout rules on launch and window creation (not `mainWindowChanged`, which fired too often). Rule precedence is per-window: a non-empty title pattern matches first and only the first specific match places the window; a catch-all rule applies only when no specific rule matched. Manual placements bypass one later auto-layout pass through a short-lived per-window suppression entry that `placeApp` consumes.

## Miccheck menubar

The old `miccheck.lua` module is gone; push-to-talk/push-to-mute now lives in the standalone [[miccheck]] menubar app, and Hammerspoon only sends it mode commands.

`mise/config/hammerspoon/lib/micctl.lua` is the socket client (`setPTTMode`, `toggleMode`); `watchers/camera.lua`, `watchers/media-presence.lua`, and `contexts/co.detail.mac.lua` call it where they previously required the Lua module. The eventtap, menubar icon, hotkeys, and mute logic all moved into the compiled Swift app.

## Audio device watcher

`mise/config/hammerspoon/watchers/audio.lua` selects preferred audio devices after debounced `hs.audiodevice.watcher` events.

It uses a trailing timer for `dev#` bursts, calls Hammerspoon's `hs.audiodevice` API, and logs deterministic device-change messages only when the default device actually changes. It intentionally does not shell out to `SwitchAudioSource` for status text because shell output can include terminal control sequences when Hammerspoon runs inside a console/tmux-shaped environment.

## Clipper and utilities

Hammerspoon utility helpers include `U.case`, an ordered value/predicate matcher used for small pattern-matching branches.

Hammerspoon clipper uses `U.case` for gatekeeper reason display: oversized captures keep the 5MB upload gatekeeper, show a resizing warning, then ImageMagick compresses the PNG to a conservative JPEG target before replacing the upload path, never clearing a newer active resize task. The Lua twins still call `capper` with `{ "capper", imagePath }`; `bin/capper` owns fnox wrapping when DO Spaces variables are missing. Capper passes secrets to `s3cmd` through AWS environment variables, always uses `--config=/dev/null`, and never reads `~/.s3cfg` or puts secret values in argv. System jankyborders is not managed by nix-darwin; visible focus indication comes from tmux/Hammerspoon/Ghostty UI settings.
