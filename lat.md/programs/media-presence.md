# media-presence

`tools/media-presenced/` is a standalone Swift daemon that detects meeting/AV presence and serves JSON events to Hammerspoon over a Unix socket.

It is a tracked first-party SwiftPM package, portable across nix and mise, not yet nix-packaged or wired into Hammerspoon.

## Why a daemon, not Hammerspoon Lua

The daemon replaces heuristic Lua meeting logic with authoritative AV + CDP signals, and needs its own process for TCC correctness.

The existing logic — `bindings.lua` `loadMeeting` (hyper+z) and `watchers/camera.lua` (DND/music-pause) — relies on camera+URL heuristics and window-size guessing. When AV/screen APIs are called from a terminal child, macOS attributes the request to the responsible app (the shell's host, e.g. Ghostty) and re-prompts even when already granted; a standalone process (eventually a LaunchAgent) gets its own TCC identity. Reading window titles via `CGWindowList`/System Events is avoided because it triggers Screen Recording prompts.

## Detection layers

Two layers: an OS-level capture layer (mic/camera) and a CDP-based Google Meet layer.

The capture layer always works: microphone in-use plus owner via CoreAudio process objects (`kAudioHardwarePropertyProcessObjectList`, `kAudioProcessPropertyIsRunningInput`, `kAudioProcessPropertyPID`/`BundleID`), and camera in-use via CoreMediaIO `kAudioDevicePropertyDeviceIsRunningSomewhere`. Both install property listeners plus a 5s safety-net refresh.

The meeting layer detects Google Meet through Chrome DevTools Protocol against Helium on port 9223. `Target.setDiscoverTargets` discovers `meet.google.com` page targets event-driven, then a debounced (1.2s) `Runtime.evaluate` classifies lobby vs joined (Leave-call vs Join-now button), in-app mic/camera state, screen-share (`You are presenting`), and participant names (from `Mute X's microphone` aria-labels). CDP is the authority because TCC/replayd logs are unreliable for already-granted apps. Meet fires `Target.targetInfoChanged` in a tight loop, so classify is debounced and deduped by url+title signature.

## Concurrency

`CDPClient` confines `known`-target state to a serial queue `q` and guards `pending`/`nextID` with an `NSLock`.

This split lets `send()` run from any thread including `q` (a `q.sync` inside `send` would deadlock when `send` is called from a `q` timer handler). The original scaffold crashed from a `known` data race across the receive thread and `q`, plus the `q.sync` deadlock; both are fixed by this split.

## Socket protocol

The Unix socket (`~/.local/state/media-presence/sock`) is line-delimited JSON: broadcast event lines plus request/reply commands.

Events: `mic.on`/`mic.off`, `camera.on`/`camera.off`, `meeting.lobby`/`meeting.joined`/`meeting.left`, `screenshare.start`/`screenshare.stop`. Each line carries the full presence object (`micActive`, `micOwners`, `cameraActive`, `inMeeting`, `meetingState`, `sharing`, `meetingApp`, `meetingURL`, `meetingTitle`, `meetingTargetId`, `participants`, `inAppMic`, `inAppCamera`). Commands send one JSON line and read one reply: `{"cmd":"get"}` returns current presence; `{"cmd":"focus"}` focuses the meeting via CDP `Target.activateTarget` plus `NSRunningApplication.activate`, which hyper+z will call instead of the heuristic window finder.

## Build

The nix store SDK shadows Xcode's via `SDKROOT`, so SwiftPM must be invoked with the Xcode SDK forced.

Use `env -u SDKROOT DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer SDKROOT=<Xcode MacOSX.sdk> swift build -c release` with the Xcode toolchain swift. Binary lands at `.build/release/media-presenced`.

## Status and remaining work

Working vertical slice: Google Meet plus capture layer.

Not yet done: Slack huddle resolver, native-app (Zoom/Teams) resolver, camera owner attribution (currently on/off only), nix packaging plus LaunchAgent with its own TCC grant, and the Hammerspoon consumer that replaces `loadMeeting` and `watchers/camera.lua`.
