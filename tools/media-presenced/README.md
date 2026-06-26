# media-presenced

A single Swift daemon that detects meeting/AV presence on macOS and serves a
line-delimited JSON event stream over a Unix-domain socket for Hammerspoon.

## What it detects

- **Capture layer** (OS-level, always works, no browser cooperation):
  - microphone in-use + owner (CoreAudio process objects: pid + bundle id)
  - camera in-use (CoreMediaIO `kAudioDevicePropertyDeviceIsRunningSomewhere`)
- **Meeting layer** (Google Meet via Chrome DevTools Protocol):
  - lobby vs joined, in-app mic/camera state, screen-share (presenting), participants
  - event-driven via CDP target discovery; debounced DOM classify

Requires the browser launched with `--remote-debugging-port=9223` (Helium is, via
the nix wrapper / fish `helium` function). If CDP is unavailable the daemon still
emits the capture layer and degrades gracefully.

## Build

```sh
# nix store SDK can shadow Xcode's; force the Xcode SDK/toolchain:
XSDK=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk
env -u SDKROOT DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer SDKROOT="$XSDK" \
  /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift build -c release
```

Binary: `.build/release/media-presenced`.

## Run

```sh
media-presenced [--socket PATH] [--cdp-port N]
# default socket: ~/.local/state/media-presence/sock, cdp port 9223
media-presenced --snapshot   # one-shot capture snapshot, then exit
```

## Socket protocol (line-delimited JSON)

- Every connected client receives broadcast **event** lines.
- Commands (send one JSON line, read one JSON line reply):
  - `{"cmd":"get"}` → current presence
  - `{"cmd":"focus"}` → focus the current meeting (CDP `activateTarget` + app activate)

### Events

`mic.on` `mic.off` `camera.on` `camera.off` `meeting.lobby` `meeting.joined`
`meeting.left` `screenshare.start` `screenshare.stop`

Each line carries the full presence object (`micActive`, `micOwners`,
`cameraActive`, `inMeeting`, `meetingState`, `sharing`, `meetingApp`,
`meetingURL`, `meetingTitle`, `meetingTargetId`, `participants`, `inAppMic`,
`inAppCamera`).

## Status

Working vertical slice: Google Meet + capture layer. Not yet done:

- Slack huddle resolver
- native-app (Zoom/Teams) resolver
- camera owner attribution (currently capture on/off only)
- nix packaging + LaunchAgent (own TCC identity, so it never re-prompts the
  terminal's host app)
- Hammerspoon consumer (replace `bindings.lua loadMeeting` heuristics +
  `watchers/camera.lua` with socket events)

## Design notes

- Standalone daemon (not run from a terminal) so TCC attributes screen/automation
  permission to itself, never the shell's host app (e.g. Ghostty). Reading window
  titles via `CGWindowList`/System Events is avoided — it triggers Screen Recording
  prompts.
- CDP is the authority for Meet state; system logs (TCC/replayd) are unreliable
  for already-granted apps (no fresh access-request per share).
