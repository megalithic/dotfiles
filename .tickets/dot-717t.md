---
id: dot-717t
status: open
deps: []
links: []
created: 2026-06-26T21:03:08Z
type: feature
priority: 1
assignee: Seth Messer
tags: [media-presence, swift, hammerspoon, meetings]
---

# Finish media-presence meeting/AV watcher (Swift daemon)

Continue tools/media-presenced (Swift daemon). Working vertical slice already committed (093a6662a): capture layer (mic owner via CoreAudio process objects, camera via CoreMediaIO) + CDP Google Meet detection (lobby/joined/sharing/participants, event-driven, debounced) + Unix-socket JSON events with get/focus commands. See lat.md/programs/media-presence and tools/media-presenced/README.md. Resume by asking to 'start back on the media watcher swift binary'.

## Design

Daemon must run as its own LaunchAgent with its own TCC identity so screen/automation prompts attribute to it, not the terminal host (Ghostty re-prompt problem). CDP is authority for Meet (TCC/replayd logs unreliable for already-granted apps). Avoid CGWindowList/System Events window-title reads (trigger Screen Recording prompts). Helium launched with --remote-debugging-port=9223. Build needs Xcode SDK forced over nix SDKROOT.

## Acceptance Criteria

1. nix package (pkgs/media-presenced.nix) building the Swift binary, wired into home-manager. 2. LaunchAgent runs it at login with its own Screen Recording/Automation TCC grant (no terminal re-prompts). 3. Hammerspoon consumer: connect to the Unix socket, dispatch events to ptt mute, music pause, DND/focus on screenshare.start/stop, and Slack status; replace watchers/camera.lua heuristics. 4. Repoint hyper+z (bindings.lua loadMeeting) to send {cmd:focus} to the daemon instead of window-size guessing. 5. Slack huddle resolver (capture signals + window/AX), validated live. 6. Native Zoom/Teams resolver. 7. Camera owner attribution (not just on/off). 8. Live-validate meeting.left, screenshare stop, and lobby->joined transitions end to end. 9. lat.md/programs/media-presence updated; lat check passes.
