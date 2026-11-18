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
  `hs.socket`, so swifties apps are called through their CLIs (`lib/seams.js`),
  by their mise shims' absolute paths, never through PATH.

## Hyper

v1 owns F19 (kanata's hyper) as a bare Carbon hotkey and its hyper modal.
`lib/hyper_layer.js` only watches F19 with a session event tap and never
blocks it: never bind F19 with `hs.hotkey` here, or both apps fight over it.
While F19 is held, the layer consumes its own keys (n/t/c for Shade) and
lets every other key through to v1. A key moves from v1 to this layer by
deleting its v1 binding in the same change.

- n, t, c run `shade toggle write|tell|capture`. Shade 0.9.0 answers
  "unknown verb" to tell and capture until its Phases 2 and 3 ship; they are
  bound now so nothing here changes then. Exit 69 means Shade isn't running;
  a command never launches it.
- Held hyper shows sup's hint (`sup show hint --key n=Note ... --hold`),
  terminated on release. `--hold` also ends on stdin EOF, so `seams.js` never
  closes the task's stdin. When sup has no daemon, `lib/hud.js` draws its own
  canvas instead.
- v1 keeps hyper+return, which sends `toggle write` to Shade's control socket.

## Shade and sup

Both run from their mise installs under LaunchAgents (`io.swifties.shade`,
`io.swifties.sup` in `config/mise/config.toml`). Shade reads
`~/.config/shade/config.json` (`config/shade/`) and logs to
`~/.local/state/shade/shade.log`, including `shade: vimrc <path>` at start.

### Rollback to shade-next (by hand only)

shade-next 0.1.0 is the known-good target. Its mise install stays on disk
until `mise prune`; if it's gone, `mise install github:megalithic/shade-next@0.1.0`.
The retiring commit is `git log -1 --diff-filter=D --format=%h -- config/hammerspoon/shade_next.lua`;
call it `C`.

1. Stop the new pieces: `launchctl bootout gui/$(id -u)/dev.mise.io.swifties.shade`,
   the same for `dev.mise.io.swifties.sup` and `dev.mise.com.megadots.hammerspoon2`
   (HS2 would otherwise consume hyper+n).
2. Restore shade-next's v1 glue and config:
   `git checkout C^ -- config/hammerspoon/shade_next.lua config/shade-next/config.toml`,
   add `req("shade_next")` after `req("clipper")` in `config/hammerspoon/init.lua`,
   and delete v1's `M.loadShade()` hyper+return binding in `bindings.lua`
   (shade_next.lua binds hyper+return itself).
3. `mise run update:dotfiles`, then `open -a shade-next` (it lives in
   `~/Applications/shade-next.app`), then `bin/hs-reload`.
4. Check hyper+return toggles shade-next and hyper+n opens its route modal.

## Tests

- `mise run test:ts` runs `tests/*.test.js` with a mock `hs` (`tests/mock_hs.js`).
- `tests/e2e/atlas.sh` runs the real app in Atlas's helper desktop: Atlas's
  key presses check the tap and pass-through, `hammerspoon2://` links drive
  the HUD (screenshot) and the Shade seam (stub `shade` and `sup` log their
  args; the sup stub reports no daemon, so the canvas HUD shows).
  One-time setup: copy `tests/e2e/init.js` (as `init.js`), `lib/*.js` and
  `tests/e2e/{shade,sup}` (to `.local/bin`, executable) with `atlas environment`,
  then `atlas install-app` the app. Accessibility is one Mac-wide list, so
  Seth's grant on his desktop covers the helper too.
- Never post synthetic key events from the helper (`hs.eventtap` `post()`,
  osascript, cliclick): HID-level posts reach the console session, Seth's
  desktop, not the helper. Atlas can't hold F19, so held hyper is checked on
  the real keyboard:
  1. Hold hyper: after a moment sup's n/t/c hint shows; release hides it.
  2. Hold hyper, press n: Shade's write panel toggles, and nothing else opens
     (no v1 modal). Press it again: it hides.
  3. Hold hyper, press t, then c: nothing is typed into the front app (Shade
     0.9.0 answers "unknown verb"; HS2's console logs `exited 1`).
  4. hyper+return toggles Shade's write panel (v1).
  5. hyper+j and other v1 chords still work.
