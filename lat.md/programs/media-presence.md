# media-presence

`bin/media-presenced` is a single-file Swift daemon that detects meeting/AV presence and serves JSON events to Hammerspoon over a Unix socket.

It is an editable `#!/usr/bin/swift` script run as a user LaunchAgent (`home/common/programs/media-presence/`). The Hammerspoon consumer (`watchers/media-presence.lua`) connects to the Unix socket and replaces `watchers/camera.lua` heuristics; hyper+z (`bindings.lua` `loadMeeting`) sends `{cmd:focus}` to the daemon.

## Why a daemon, not Hammerspoon Lua

The daemon replaces heuristic Lua meeting logic with authoritative AV + CDP signals, and needs its own process for TCC correctness.

The existing logic — `bindings.lua` `loadMeeting` (hyper+z) and `watchers/camera.lua` (DND/music-pause) — relied on camera+URL heuristics and window-size guessing. `watchers/media-presence.lua` replaces `camera.lua` with authoritative socket events, and hyper+z delegates to the daemon's `{cmd:focus}`. When AV/screen APIs are called from a terminal child, macOS attributes the request to the responsible app (the shell's host, e.g. Ghostty) and re-prompts even when already granted; a standalone LaunchAgent avoids the terminal-host lifecycle. Reading window titles via `CGWindowList`/System Events is avoided because it triggers Screen Recording prompts.

## Detection layers

Three layers: an OS-level capture layer (mic/camera), a CDP-based browser meeting layer, and a Slack huddle resolver plus a replayd-based screenshare resolver.

The capture layer always works: microphone in-use plus owner via CoreAudio process objects (`kAudioHardwarePropertyProcessObjectList`, `kAudioProcessPropertyIsRunningInput`, `kAudioProcessPropertyPID`/`BundleID`), and camera in-use via CoreMediaIO `kAudioDevicePropertyDeviceIsRunningSomewhere`. Both install property listeners plus a 5s safety-net refresh.

The meeting layer detects supported browser meeting URLs through Chrome DevTools Protocol against Helium on port 9223. `Target.setDiscoverTargets` discovers `meet.google.com` and `telehealth.px.athena.io` page targets event-driven, then a debounced (1.2s) `Runtime.evaluate` classifies lobby vs joined (Leave-call/End-call vs Join-now/Join-visit button), in-app mic/camera state, screen-share (`You are presenting`/stop sharing), and Google Meet participant names (from `Mute X's microphone` aria-labels). CDP is the authority because TCC/replayd logs are unreliable for already-granted apps. Meet fires `Target.targetInfoChanged` in a tight loop, so classify is debounced and deduped by url+title signature. Some meeting URLs (currently Athena telehealth) can fall back to `meetingState: camera-active`: if the URL prefix matches the fallback list and macOS reports the camera active, the daemon treats the page as an active meeting even when DOM classification is unknown.

### Slack huddle resolver

When the capture layer detects a mic owner whose bundle ID starts with `com.tinyspeck.slackmacgap` (the Slack app or its helper), the engine treats it as a meeting.

This sets `inMeeting=true`, `meetingApp="com.tinyspeck.slackmacgap"`, `meetingState="joined"`. This triggers miccheckd's push-to-talk enforcement for Slack huddles without any CDP involvement. No video required — the mic-owner signal alone is sufficient (validated live 2026-07-07).

The engine fuses Slack and CDP meeting sources: CDP takes priority when both are active (hyper+z focus works for browser meetings but not for Slack), so meetingApp stays on Helium while a Meet tab is also in a meeting. When Slack is the sole meeting source, `meetingApp` and `inMeeting` reflect the huddle, and `meeting.left` fires when the Slack mic owner disappears.

### Screenshare resolver (sender-side)

A `ScreenshareMonitor` spawns an OSLog stream (`/usr/bin/log stream --predicate` filtering on `process == "replayd"` and `subsystem CONTAINS[c] "screencapturekit"`). No TCC grants are required for log-stream access.

**Start**: `SCScreenCaptureSession startWithError:` or `updateScreenCaptureDidStart:` sets `sharing=true`.

**Heartbeat**: `updateExistingDisplayStreamCapturesWithAuditTokenValues:` fires every ~10s while capturing. The monitor resets a watchdog timer on each heartbeat.

**Stop**: when the heartbeat gap exceeds 25s, `sharing` flips to `false`. Method-name stop events (`stopAndInvalidateWithStreamData:userStopped:`) are captured as hints but are not authoritative — Slack renegotiates streams during startup, producing spurious stop-then-restart sequences that would false-fire. The heartbeat-gap discriminator avoids this.

Attribution via replayd client PID → bundle ID (`processNewConnection ... PID: <pid>`) is noted for future enhancement.

Sharing transitions emit `screenshare.start`/`screenshare.stop`, which Hammerspoon's watcher translates to DND enforcement — closing the huddle-screenshare → DND gap.

## Concurrency

`CDPClient` confines `known`-target state to a serial queue `q` and guards `pending`/`nextID` with an `NSLock`.

This split lets `send()` run from any thread including `q` (a `q.sync` inside `send` would deadlock when `send` is called from a `q` timer handler). The original scaffold crashed from a `known` data race across the receive thread and `q`, plus the `q.sync` deadlock; both are fixed by this split.

## Socket protocol

The Unix socket (`~/.local/state/media-presence/sock`) is line-delimited JSON: broadcast event lines plus request/reply commands.

Events: `mic.on`/`mic.off`, `camera.on`/`camera.off`, `meeting.lobby`/`meeting.joined`/`meeting.left`, `screenshare.start`/`screenshare.stop`. Each line carries the full presence object (`micActive`, `micOwners`, `cameraActive`, `inMeeting`, `meetingState`, `sharing`, `meetingApp`, `meetingURL`, `meetingTitle`, `meetingTargetId`, `participants`, `inAppMic`, `inAppCamera`). `meetingState` is `idle`, `lobby`, `joined`, `unknown`, or `camera-active` (fallback URL + active camera). Commands send one JSON line and read one reply: `{"cmd":"get"}` returns current presence; `{"cmd":"focus"}` focuses the meeting via CDP `Target.activateTarget` plus `NSRunningApplication.activate`, which hyper+z calls instead of the heuristic window finder.

## Hammerspoon consumer

`config/hammerspoon/watchers/media-presence.lua` polls the daemon every 3s via `nc -w 1 -U` with `{"cmd":"get"}`, detects state transitions by diffing successive snapshots, and dispatches:

- `inMeeting` false→true → pause Apple Music
- `sharing` false→true → enforce DND focus mode (`U.dnd(true, "meeting")`)
- `sharing` true→false → restore previous DND state

PTT mode enforcement moved out of this watcher: [[miccheck#Presence integration|miccheckd subscribes to the daemon's socket directly]] and forces push-to-talk on `inMeeting` transitions. Hammerspoon can still set modes manually via `lib/micctl.lua`.

`nc -w 1` (1s idle timeout) is required because plain `nc -U` hangs waiting for more data, preventing the `hs.task` exit callback from firing.

`bindings.lua` `loadMeeting` (hyper+z) sends `{"cmd":"focus"}` to the daemon via the same `nc -w 1 -U` pattern; the daemon handles CDP target activation and app focusing.

## Build and packaging

There is no SwiftPM or nix package; `bin/media-presenced` is the source and executable.

`home/common/programs/media-presence/` points launchd directly at `~/.dotfiles/bin/media-presenced` (RunAtLoad + KeepAlive); the mise config mirrors it as `_mise.toml` agent `com.megadots.media-presenced` (no args — the script's defaults match the nix agent's args). The script uses an absolute `#!/usr/bin/swift` shebang so launchd can run it with its minimal environment. If the nix store SDK shadows Xcode's in an interactive shell, verify with `env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin bin/media-presenced --snapshot`.

The daemon needs no TCC grants: it reads device state (CoreAudio/CoreMediaIO IsRunningSomewhere), localhost CDP, and `NSRunningApplication.activate` — no `CGWindowList`, AX, or screencapture — so the agent runs with zero permission prompts. Because this is a script, its process identity is the Swift interpreter; keep it free of TCC-sensitive APIs unless it becomes a compiled binary again.

## Status and remaining work

Working: Google Meet, Athena telehealth, Slack huddle resolver (capture-layer mic owner), screenshare resolver (replayd heartbeat), capture layer, running as a LaunchAgent from `bin/media-presenced`.

Also working: Hammerspoon consumer wired (ptt mute, music pause, DND on screenshare, hyper+z repointed to `{cmd:focus}`).

Not yet done: native-app (Zoom/Teams) resolver, camera owner attribution (currently on/off only), and end-to-end live validation of `meeting.left`/screenshare-stop/lobby-to-joined transitions. Tracked in ticket dot-717t.
