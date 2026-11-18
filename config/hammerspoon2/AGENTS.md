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
- `tests/e2e/atlas.sh` runs the real app in Atlas's helper desktop beside a
  minimal v1 (`tests/e2e/v1-init.lua`), posting the hyper sequence from
  `tests/e2e/init.js` and reading back both logs, TextEdit's text and a HUD
  screenshot. One-time setup: copy `tests/e2e/init.js`, `lib/*.js`,
  `tests/e2e/shade` (to `.local/bin`) and `tests/e2e/v1-init.lua` with
  `atlas environment`, `atlas install-app` both apps, and Seth grants
  Hammerspoon 2 Accessibility inside the helper.
