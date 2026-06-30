---
id: dot-717t
status: in_progress
deps: []
links: []
created: 2026-06-26T21:03:08Z
type: feature
priority: 1
assignee: Seth Messer
tags: [media-presence, swift, hammerspoon, meetings]
---

# Finish media-presence meeting/AV watcher (Swift daemon)

Continue `bin/media-presenced` (single-file Swift daemon). Working vertical slice: capture layer (mic owner via CoreAudio process objects, camera via CoreMediaIO) + CDP Google Meet/Athena telehealth detection (lobby/joined/sharing/participants, event-driven, debounced) + Unix-socket JSON events with get/focus commands. See `lat.md/programs/media-presence.md`. Resume by asking to 'start back on the media watcher swift binary'.

## Design

Daemon must run as its own LaunchAgent so lifecycle is independent from the terminal host. CDP is authority for Meet/Athena telehealth (TCC/replayd logs unreliable for already-granted apps). Avoid CGWindowList/System Events window-title reads (trigger Screen Recording prompts). Helium launched with --remote-debugging-port=9223. The daemon is now an editable `#!/usr/bin/swift` script, not a nix-built binary.

## Acceptance Criteria

1. Single-file Swift script at `bin/media-presenced`, wired into home-manager LaunchAgent. 2. LaunchAgent runs it at login without terminal-host re-prompts. 3. Hammerspoon consumer: connect to the Unix socket, dispatch events to ptt mute, music pause, DND/focus on screenshare.start/stop, and Slack status; replace watchers/camera.lua heuristics. 4. Repoint hyper+z (bindings.lua loadMeeting) to send {cmd:focus} to the daemon instead of window-size guessing. 5. Slack huddle resolver (capture signals + window/AX), validated live. 6. Native Zoom/Teams resolver. 7. Camera owner attribution (not just on/off). 8. Live-validate meeting.left, screenshare stop, and lobby->joined transitions end to end. 9. lat.md/programs/media-presence updated; lat check passes.

## Notes

**2026-06-30T17:50Z**

Migrated daemon source to one editable Swift script at `bin/media-presenced`; removed SwiftPM/nix package path. Home-manager LaunchAgent now points directly at the script.

**2026-06-28T01:49Z**

Criteria 3+4 implemented:

- `config/hammerspoon/watchers/media-presence.lua`: persistent `nc -U` consumer, dispatches meeting.lobby/joined→PTT mute+music pause, meeting.left→reset, screenshare.start/stop→DND on/off, auto-reconnect on daemon restart
- `config/hammerspoon/bindings.lua` `loadMeeting` (hyper+z): sends `{"cmd":"focus"}` to daemon socket, removed heuristic `findMeetingWindow` + window-size guessing
- `config/hammerspoon/init.lua`: added "media-presence" to watchers list (replaces "camera")
- `lat.md/programs/media-presence.md`: added Hammerspoon consumer section, updated status

**2026-06-26T21:04:58Z**

mise-bootstrap-migration notes (superseded by `bin/media-presenced`): the daemon source is now a portable single-file Swift script. Remaining portability work is only launch setup and ensuring Helium starts with `--remote-debugging-port=9223` outside nix.
