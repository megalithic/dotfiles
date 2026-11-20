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
While F19 is held, the layer consumes its trigger (Return), its chords
(Escape) and, only once armed, its keys (n/t/c/e for Shade); everything else
goes through to v1. A key moves from v1 to this layer by deleting its v1
binding in the same change (hyper+Escape left v1's `dismissBindings`).

`lib/hyper.js` wires it to sup and Shade:

- hyper down runs `sup show actions --hold`: sup rings its target toast (the
  newest visible critical, else urgent, else newest) and hints esc Dismiss
  and ⏎ Open. It exits 3 at once when nothing is actionable. Hyper up, Return
  or Escape end it.
- hyper+Return runs `sup open`, which opens the target toast's source (a
  Messages thread, a Rex block, a tab) and dismisses it. Exit 3 (nothing to
  open) falls back to Shade, below.
- hyper+Escape runs `sup dismiss --action`: it removes what sup's config
  `actions.dismiss` names (`config/sup/config.json`: every toast; hints and
  alerts stay). Exit 3 (nothing dismissed) is normal. There is no
  `open --action`, so hyper+Return keeps `sup open`.

Shade's layer works by modality: it is active only while Shade is.

- With nothing to open, hyper+Return runs `shade toggle <SHADE_DEFAULT_VERB>`
  (`init.js`, "write"). When Shade's reply says the panel is now visible, the
  layer arms for the rest of that hyper hold; when it hid the panel, or Shade
  isn't running (exit 69; a command never launches it), nothing arms.
- Armed, sup's hint (`sup show hint --key n=Note ... --hold`) shows at once,
  and n, t, c, e run `shade show write|tell|capture|edit` (`show`, so the
  current verb never hides the panel) and close the hint. Tell and edit need
  Shade's Accessibility grant (io.swifties.shade).
- Releasing hyper disarms the layer and ends the hint; focus stays in Shade.
  A plain hyper hold never arms and never shows a hint.
- `--hold` also ends on stdin EOF, so `seams.js` never closes the task's
  stdin. When sup has no daemon, `lib/hud.js` draws its own canvas instead.

## Shade and sup

Both run from their mise installs under LaunchAgents (`io.swifties.shade`,
`io.swifties.sup` in `config/mise/config.toml`). Shade reads
`~/.config/shade/config.json` (`config/shade/`); sup reads
`~/.config/sup/config.json` (`config/sup/`; a change needs a sup restart,
and an invalid file makes it exit 78) and logs to
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
   (shade_next.lua binds hyper+return itself).
3. `mise run update:dotfiles`, then `open -a shade-next` (it lives in
   `~/Applications/shade-next.app`), then `bin/hs-reload`.
4. Check hyper+return toggles shade-next and hyper+n opens its route modal.

## Tests

- `mise run test:ts` runs `tests/*.test.js` with a mock `hs` (`tests/mock_hs.js`).
- `tests/e2e/atlas.sh` runs the real app in Atlas's helper desktop: Atlas's
  key presses check the tap and pass-through, `hammerspoon2://` links run
  the trigger path (`trigger`: toggle, arm, HUD screenshot) and the verb path
  (`action`). Stubs `shade` and `sup` log their args; the shade stub answers
  visible, and the sup stub reports no daemon, so the canvas HUD shows.
  One-time setup: copy `tests/e2e/init.js` (as `init.js`), `lib/*.js` and
  `tests/e2e/{shade,sup}` (to `.local/bin`, executable) with `atlas environment`,
  then `atlas install-app` the app. Accessibility is one Mac-wide list, so
  Seth's grant on his desktop covers the helper too.
- Never post synthetic key events from the helper (`hs.eventtap` `post()`,
  osascript, cliclick): HID-level posts reach the console session, Seth's
  desktop, not the helper. Atlas can't hold F19, so held hyper is checked on
  the real keyboard:
  1. Hold hyper alone: no hint. hyper+n, hyper+t and hyper+c do what v1
     does with them, or nothing.
  2. Hold hyper, press Return: Shade's write panel opens and, while hyper is
     still held, sup's n/t/c/e hint shows. Release: the hint goes, focus stays
     in Shade.
  3. Hyper+Return again: Shade hides, and no hint shows.
  4. Hyper+Return to open it, keep holding, press n: the hint closes and the
     panel stays on write. Press t, c or e instead: Shade switches to that
     verb and nothing is typed into Shade.
  5. hyper+j and other v1 chords still work.
  6. With a toast up (`notiwatchd post --title T --body B --urgency high`),
     hold hyper: the toast gets a ring and the esc/⏎ hint. Return opens its
     source; Escape dismisses it. No toast: hyper+Return opens Shade as above.
