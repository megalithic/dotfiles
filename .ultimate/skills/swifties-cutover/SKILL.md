---
name: swifties-cutover
description: Move this Mac's swifties tools (aeroplay, miccheckd, notiwatchd, pidewaved, avwatchd, shade, sup from megalithic/swifties) to a new release, from the pin bump through the restarts to verified and reported. Use when someone asks to bump, cut over to, install or roll out a swifties version, or to check that the installed swifties release is healthy.
---

# Swifties cutover

The steps three cutovers repeated by hand (#49643, #54613/#62667, #66003). `check` does every read-only check and prints
one line each; run it before you report anything installed or running:

```bash
~/.dotfiles/.ultimate/skills/swifties-cutover/check [version]   # default: mise's current sup
```

Lines: `pins` (installed at the version; `warn` while the deployed pins still name the old one), `sums` (release `SHA256SUMS`), `copies` (`~/.local/bin` daemons equal the release), `appledbl` (no
`._*` files), `codesign`, one `launchd` per agent (running, on this version's path, started after its binary was
installed, `TERMINAL => rex` on notiwatch and pidewave), `sup` (`sup config --json`), `notiwatch` (the newest config
line is `config loaded: N rule(s)` with the config's rule count, not `config parse failed, keeping previous`), `idle`. Exit status 1 when any line fails.

## 1. Branch: pins and paths

In a hub branch, in `config/mise/config.toml`:

- every `[tools.<swifty>] version`;
- the in-place app paths in `[bootstrap.macos.launchd.agents."io.swifties.*"]`: miccheck, aeroplay, shade, sup
  (`installs/<tool>/<version>/…`). avwatch, notiwatch and pidewave run `~/.local/bin` copies and need no path change;
- any caller that uses a new flag or config key (`bin/notify`, `config/notiwatchd/config.json`, sup's config,
  `config/hammerspoon2/lib/seams.js`), with its tests (`bin/tests/notify.test.sh`).

## 2. Install

From the branch worktree: `mise install -f <tool>@<version> …` for all seven (`-f` replaces a cached asset from a
re-cut release). The postinstalls copy notiwatchd, pidewaved and avwatchd into `~/.local/bin`. Then run `check
<version>`: `sums`, `copies`, `appledbl` and `codesign` must be `ok` before anything restarts. Until landing, `pins`
is `warn` (the deployed config still pins the old version) and the app agents' `launchd` lines fail on their old
paths; both must be `ok` after step 3.

## 3. Restart, in this order

Ask Seth before any restart unless the relay says he approved restarts for this cutover: a restart blinks his panels
and drops a hint or toast on screen.

1. **Before landing, only when callers use a new flag:** restart the `~/.local/bin` daemons that callers reach, so the
   flag works the moment the caller lands: `launchctl kickstart -k gui/$(id -u)/dev.mise.io.swifties.<name>` for
   notiwatch, pidewave, avwatch.
2. **After landing and `activate-dotfiles`:** `mise bootstrap macos launchd-agents apply` rewrites the app agents'
   plists to the new paths and reloads them (miccheck, aeroplay, shade, sup). Kickstart any `~/.local/bin` daemon
   not restarted in step 1.
3. **Config reloads last:** a changed `config/notiwatchd/config.json` loads on notiwatchd's restart; a bad config
   keeps the old one, so the `notiwatch` line must show the new rule count.

Then `check` again: every `launchd` line `ok` (a `started before` line means that agent still runs the old binary).

## 4. Visible checks

- **Test toast** only when the `idle` line is `ok` (Seth idle five minutes or more), with harmless text, at normal
  urgency: `~/bin/notify -s hub-test -u normal -g swifties -t "Swifties <version>" -m "test toast"`. Confirm it in
  notiwatchd's log. Never test with `-s ultimate`: notiwatchd's `ultimate-time-sensitive` rule
  (`config/notiwatchd/config.json`) matches that source and forces `critical` with `ttl: 0`, whatever `-u` says, so
  it sticks on screen until dismissed; that source is reserved for real deadlines (`~/.ultimate/AGENTS.md`). Only
  when the cutover changed critical toasts, add one urgent test the same way with `-u critical` (still `hub-test`).
- When Seth is active, or a check needs his hands (hyper+Esc dismisses toasts, a Shade panel, MicCheck
  push-to-talk, AeroPlay routing, avwatch during a screen share): put each one in his Inbox as a step with what
  he should see. Never post synthetic key events.

## 5. Other Macs and report

- **megabookpro is deferred:** list it as pending in the report. Roll it out only when Seth asks, through its own
  @ultimate, with this skill and its own approval for restarts.
- Report per machine: landed (sha), pushed (or held), installed (`check` lines `pins` to `codesign`), running
  (`launchd`, `sup`, `notiwatch`), visible checks done or in the Inbox, and who acts next.
