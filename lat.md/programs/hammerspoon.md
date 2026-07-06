# Hammerspoon

Hammerspoon owns macOS automation: window management, launcher panels, menubar state, and clipboard tooling. Lua config lives in `config/hammerspoon/` (out-of-store symlink); nix-generated data fragments land in `~/.local/share/hammerspoon/`.

## Reload safety

**Hammerspoon must only be reloaded via `bin/hs-reload`.** Unsafe CLI reload paths can crash Hammerspoon.

`bin/hs-reload` uses System Events to click Hammerspoon's File → Reload Config menu item and fails with an Accessibility-permission error instead of trying unsafe fallbacks. CLI `hs -c` menu selection and direct `hs.reload()` are both unsafe.

Hammerspoon's preflight adds `~/.local/share/hammerspoon` to Lua `package.path` so generated data-only fragments such as `fragments/shade-next.lua` can be required without editing the generated file.

## Global app bindings

Global app bindings stay data-driven so app launchers, local pass-through keys, and URL-scheme actions share one configuration surface instead of per-app binding code.

`C.launchers` rows use `{ bundleID, bind, opts? }`: simple launchers omit `opts`, while `opts.passThrough`, `opts.focusOnly`, `opts.cycleWindows`, `opts.urlSchemes`, and `opts.launchCommand` handle exceptions. `opts.launchCommand` (string or argv table) replaces the LaunchServices cold start with a detaching launcher script — LaunchServices forwards no command-line flags, so launchers that need them (Helium's CDP port via `bin/helium-launch`) spawn the script through `hs.task`; focus/cycle of an already-running app never respawns. When `opts.cycleWindows = true`, hitting the app binding while that app is focused cycles visible app windows rather than browser tabs. Fantastical keeps `hyper+y` as the app toggle; `hyper+'` opens `x-fantastical3://parse?sentence=`; `hyper+shift+'` opens `x-fantastical3://parse?reminder=1&sentence=`.

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

Miccheck menubar state lives in `config/hammerspoon/miccheck.lua` and now handles push-to-talk and mute only.

Push-to-dictate and push-to-record are fully disabled: their functions are stubbed to no-ops, the `cmd+opt+shift` eventtap branch and `ptdToggle` hotkey are removed, whisper is `nil` at init, and the menubar omits dictation entries. Muted state shows a white slashed-mic glyph on the transparent menubar; unmuted passthrough uses a white mic glyph on a rounded red pill so the hot-mic state stays visible. Legacy recording/processing HUD renderers remain but are unreachable.

## Clipper and utilities

Hammerspoon utility helpers include `U.case`, an ordered value/predicate matcher used for small pattern-matching branches.

Hammerspoon clipper uses `U.case` for gatekeeper reason display: oversized captures keep the 5MB upload gatekeeper, show a resizing warning, then ImageMagick compresses the PNG to a conservative JPEG target before replacing the upload path, never clearing a newer active resize task. System jankyborders is not managed by nix-darwin; visible focus indication comes from tmux/Hammerspoon/Ghostty UI settings.
