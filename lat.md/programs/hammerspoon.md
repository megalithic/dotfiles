# Hammerspoon

Hammerspoon owns macOS automation: window management, launcher panels, menubar state, and clipboard tooling. Lua config lives in `config/hammerspoon/` (out-of-store symlink); nix-generated data fragments land in `~/.local/share/hammerspoon/`.

## Parallel mise configuration

`mise/config/hammerspoon/` is an independent mise twin of Nix source `config/hammerspoon/`; `mise/config/mise/global_config.toml` links it to `~/.config/hammerspoon`.

It is a copy, not shared source: mirror changes manually from `config/hammerspoon/` into the twin.

One field is an intentional, permanent divergence and must never be blindly overwritten during a sync: `config.lua`'s `dock.kanata.daemonLabel` is `"org.kanata.daemon"` on the nix side (matches `modules/darwin/kanata.nix`) but `"dev.mise.org.kanata.daemon"` on the mise side, because mise prefixes bootstrap-managed launchd labels with `dev.mise.` (see `mise/tasks/kanata-setup`). `watchers/dock.lua`'s kanata-profile-switch code reads this field to target the right launchd service with `launchctl kickstart -k`/`launchctl print`, so a wrong label silently breaks kanata profile switching in whichever world got the wrong value.

## Reload safety

**Hammerspoon must only be reloaded via `bin/hs-reload`.** Unsafe CLI reload paths can crash Hammerspoon.

`bin/hs-reload` prefers `open -g hammerspoon://hs-reload`, which Hammerspoon handles inside its own process by calling the wrapped `hs.reload()` cleanup path. It does not use `hs` CLI reload or `hs` CLI menu selection, because those IPC paths can crash/kill Hammerspoon while reloading.

If the running config is too old to have the URL handler, `bin/hs-reload` falls back to a System Events menu click and fails with an Accessibility-permission error instead of trying unsafe IPC fallbacks. Hammerspoon's preflight adds `~/.local/share/hammerspoon` to Lua `package.path` so generated data-only fragments such as `fragments/shade-next.lua` can be required without editing the generated file.

## Global app bindings

Global app bindings stay data-driven so app launchers, local pass-through keys, and URL-scheme actions share one configuration surface instead of per-app binding code.

`C.launchers` rows use `{ bundleID, bind, opts? }`: simple launchers omit `opts`, while `opts.passThrough`, `opts.focusOnly`, `opts.cycleWindows`, `opts.urlSchemes`, and `opts.launchCommand` handle exceptions. `opts.launchCommand` (string or argv table) replaces the LaunchServices cold start with a detaching launcher script — LaunchServices forwards no command-line flags, so launchers that need them (Helium's CDP port via `bin/helium-launch`) spawn the script through `hs.task`; focus/cycle of an already-running app never respawns. When `opts.cycleWindows = true`, hitting the app binding while that app is focused cycles visible app windows rather than browser tabs. Fantastical keeps `hyper+y` as the app toggle; `hyper+'` opens `x-fantastical3://parse?sentence=`; `hyper+shift+'` opens `x-fantastical3://parse?reminder=1&sentence=`.

## URL routing

Hammerspoon can act as the HTTP/S handler for app deep links while preserving browser auth flows.

`config/hammerspoon/watchers/url.lua` redirects Figma web URLs to `figma://...`, but paths containing `auth` such as `/app_auth` pass through to the browser.

## shade-next panel

shade-next bindings are split between generated data and handwritten lifecycle code.

`home/common/programs/shade-next/default.nix` writes `~/.local/share/hammerspoon/fragments/shade-next.lua` and `~/.config/shade-next/config.toml`; `config/hammerspoon/shade_next.lua` reads the fragment. The panel design spec lives in `~/.local/share/pi/docs/shade-next/panel-design.md`.

Key behavior: one panel-height rule across all states; block types are result cards, section lists, message rows, composer, and preview; Esc always hides the panel; route keys reserve Ctrl+n for note, Ctrl+p for Pi, Ctrl+c for calc. Compact launch geometry starts at `900×104` points and grows result panels to visible rows before clamping to the configured max height.

`hyper+return` talks directly to shade-next's control socket or `shade-next://toggle` URL so current app focus does not decide toggle behavior. When shade-next shows, it records the frontmost app before activating itself and restores it on hide without Accessibility APIs. `hyper+n` enters the route modal (`p` prefills `pi`, `n` prefills `note`). Legacy Shade keeps `hyper+return` for `shade.smartToggle()` and moves its advanced modal to `hyper+shift+n`.

The `[ui]` table in the generated `config.toml` owns panel visual defaults including `border_width`, `border_color`, and `dim_unfocused`; the panel is non-opaque so the rounded material surface shows real transparency.

## Window management

Window management uses the custom `wm.lua` grid/geometry path on `hyper+l`; native Tahoe menu tiling is optional on `hyper+w`.

`wm.lua` converts the configured `C.grid` `60×20` positions into proportional screen-local frames and applies `C.windowGap` as a pixel inset so chained movement, center sizing, split tiling, browser tab splitting, and app layout automation keep spacing across displays. WM hypemode auto-exits after 2s idle; chained keys use a 1.25s `chainExitDelay`. `hyper+l,s` moves the active Helium/Chromium tab into a right-half window via `lib.interop.browser:splitTab(false)`; `hyper+l,shift+s` moves it full-size to the next screen.

App and window watchers run layout rules on launch and window creation (not `mainWindowChanged`, which fired too often). Rule precedence is per-window: a non-empty title pattern matches first and only the first specific match places the window; a catch-all rule applies only when no specific rule matched. Manual placements bypass one later auto-layout pass through a short-lived per-window suppression entry that `placeApp` consumes.

## Miccheck menubar

The old `miccheck.lua` module is gone; push-to-talk/push-to-mute now lives in the standalone [[miccheck]] menubar app, and Hammerspoon only sends it mode commands.

`config/hammerspoon/lib/micctl.lua` is the socket client (`setPTTMode`, `toggleMode`); `watchers/camera.lua`, `watchers/media-presence.lua`, and `contexts/co.detail.mac.lua` call it where they previously required the Lua module. The eventtap, menubar icon, hotkeys, and mute logic all moved into the compiled Swift app.

## Audio device watcher

`config/hammerspoon/watchers/audio.lua` selects preferred audio devices after debounced `hs.audiodevice.watcher` events.

It uses a trailing timer for `dev#` bursts, calls Hammerspoon's `hs.audiodevice` API, and logs deterministic device-change messages only when the default device actually changes. It intentionally does not shell out to `SwitchAudioSource` for status text because shell output can include terminal control sequences when Hammerspoon runs inside a console/tmux-shaped environment.

## Clipper and utilities

Hammerspoon utility helpers include `U.case`, an ordered value/predicate matcher used for small pattern-matching branches.

Hammerspoon clipper uses `U.case` for gatekeeper reason display: oversized captures keep the 5MB upload gatekeeper, show a resizing warning, then ImageMagick compresses the PNG to a conservative JPEG target before replacing the upload path, never clearing a newer active resize task. System jankyborders is not managed by nix-darwin; visible focus indication comes from tmux/Hammerspoon/Ghostty UI settings.
