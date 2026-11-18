# Hammerspoon 2

Hammerspoon 2 (cmsj/Hammerspoon2, JavaScript, experimental) runs beside v1
(`config/hammerspoon/`). It is migrating in one piece at a time; new swifties
glue goes here, not into v1.

- App: `http:hammerspoon2` in `config/mise/config.toml`, pinned to 0.0.15, the
  last build for macOS 26. The `com.megadots.hammerspoon2` LaunchAgent runs it
  in place; a version bump also updates the agent's program path. Bundle id
  `net.tenshu.Hammerspoon-2`; Sparkle checks are off.
- Config: this folder deploys per file to `~/.config/hammerspoon2/`, which the
  app reads as its default `~/.config/Hammerspoon2/init.js` (case-insensitive
  disk). `tests/` does not deploy.
- Reload: `open -g hammerspoon2://reload`.
- API docs: https://cmsj.github.io/Hammerspoon2/ (pick 0.0.15). 0.0.15 has no
  `hs.socket`, so swifties apps are called through their CLIs (`lib/seams.js`).

## Hyper

v1 owns F19 (kanata's hyper) as a bare Carbon hotkey and its hyper modal.
`lib/hyper_layer.js` only watches F19 with a session event tap and never
blocks it: never bind F19 with `hs.hotkey` here, or both apps fight over it.
While F19 is held, the layer consumes its own keys (n/t/c for Shade) and
lets every other key through to v1. A key moves from v1 to this layer by
deleting its v1 binding in the same change.

## Tests

- `mise run test:ts` runs `tests/*.test.js` with a mock `hs` (`tests/mock_hs.js`).
- `tests/e2e/atlas.sh` runs the real app in Atlas's helper desktop: Atlas's
  key presses check the tap and pass-through, `hammerspoon2://` links drive
  the HUD (screenshot) and the Shade seam (a stub `shade` logs its args).
  One-time setup: copy `tests/e2e/init.js` (as `init.js`), `lib/*.js` and
  `tests/e2e/shade` (to `.local/bin`, executable) with `atlas environment`,
  then `atlas install-app` the app. Accessibility is one Mac-wide list, so
  Seth's grant on his desktop covers the helper too.
- Never post synthetic key events from the helper (`hs.eventtap` `post()`,
  osascript, cliclick): HID-level posts reach the console session, Seth's
  desktop, not the helper. Atlas can't hold F19, so held hyper is checked on
  the real keyboard:
  1. Hold hyper: after a moment the n/t/c HUD shows; release hides it.
  2. Hold hyper, press t, then c: Shade toggles tell and capture; nothing is
     typed into the front app.
  3. Hold hyper, press n: Shade toggles write. Until v1's hyper+n binding
     (shade_next.lua) is removed, note whether v1's shade-next modal also
     opens: that is the double-fire this layer must not cause.
  4. hyper+j and other v1 chords still work.
