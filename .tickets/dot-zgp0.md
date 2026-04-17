---
id: dot-zgp0
status: open
deps: []
links: []
created: 2026-04-17T19:07:11Z
type: task
priority: 2
assignee: Seth Messer
---
# Investigate Swift-based camera/microphone activity detection for Hammerspoon

Re-open investigation into a Swift binary/script that detects camera and microphone usage
at a deeper level than hs.camera APIs provide. The goal is a persistent helper that notifies
Hammerspoon when A/V devices activate/deactivate, enabling:

- Auto-set DND/Focus modes when on a call
- Send status messages to Slack automatically
- Auto-mute microphones in certain conditions
- Pause music when joining a call
- Identify which app/window/browser tab owns the active call so hyper+z can focus it

The Swift binary should use CoreMediaIO/AVFoundation to detect which process is using
the camera/mic, and expose this to Hammerspoon (via hs.task, unix socket, or stdout streaming).

Previous investigation found hs.camera insufficient — it can detect camera on/off but not
which process owns it or handle microphone-only calls.

Relevant code in config/hammerspoon/. See also lib/builders/ for Swift build patterns.

## Acceptance Criteria

1. Document CoreMediaIO and AVFoundation APIs for detecting camera/mic ownership by process
2. Prototype Swift script that outputs JSON events when camera/mic state changes (include owning PID)
3. Identify how to map PID to window/tab for browser-based calls (Chrome, Arc, etc.)
4. Document integration approach with Hammerspoon (hs.task, socket, etc.)
5. Write up findings and recommended architecture

