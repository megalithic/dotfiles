---
id: dot-e0ca
status: open
deps: []
links: []
parent: dot-2pv9
created: 2026-04-17T19:06:59Z
type: task
priority: 2
assignee: Seth Messer
---
# Investigate Hammerspoon bluetooth audio device management

Research and prototype Hammerspoon-based menu/keybindings for controlling bluetooth connections.
Should cover headphones, hearing aids, and AirPods — both connection management and microphone selection.
This is an investigation ticket — needs further refinement once we understand what's possible.

Relevant code in config/hammerspoon/.
Look at hs.audiodevice, hs.bluetooth, and any third-party Spoons for bluetooth control.
Consider a menubar widget and/or hyper-key bindings for quick switching.

## Acceptance Criteria

1. Document available Hammerspoon APIs for bluetooth audio control
2. Document available macOS CLI tools (blueutil, SwitchAudioSource, etc.)
3. Identify gaps — what can't be done natively and needs workarounds
4. Write up findings in a research doc or ticket comment

