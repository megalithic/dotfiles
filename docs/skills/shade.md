---
name: shade
description: Expert help with Shade - the native Swift note capture app. Use for debugging Shade issues, understanding IPC protocols, implementing Hammerspoon integration, nvim RPC, context gathering, and MegaNote workflows.
tools: Bash, Read, Grep, Glob, Edit, Write
---

# Shade Expert

## Overview

Shade is a **native Swift floating panel app** that hosts a Ghostty terminal running nvim for quick note capture and obsidian.nvim integration. It replaces the previous pure-Hammerspoon approach with a performant, persistent terminal panel.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Hammerspoon                              │
│  (hotkeys, notifications, sends io.shade.* notifications)       │
└──────────────────────────┬──────────────────────────────────────┘
                           │ DistributedNotificationCenter
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                           Shade.app                              │
│  ┌─────────────┐  ┌─────────────┐  ┌────────────────────────┐   │
│  │ ShadePanel  │  │ContextGath-│  │     ShadeNvim          │   │
│  │ (floating)  │  │    erer     │  │  (msgpack-rpc actor)   │   │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬────────────┘   │
│         │                │                     │                 │
│         ▼                ▼                     ▼                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    GhosttyKit                                ││
│  │           (embedded terminal view, nvim shell)               ││
│  └─────────────────────────────────────────────────────────────┘│
│         │                                      ▲                 │
│         ▼                                      │ unix socket     │
│  ┌─────────────┐                    ┌──────────┴────────────┐   │
│  │ Terminal    │                    │ ~/.local/state/shade/ │   │
│  │  Surface    │                    │   nvim.sock           │   │
│  └─────────────┘                    │   context.json        │   │
│                                     │   shade.pid           │   │
│                                     └───────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Key Directories

| Path | Purpose |
|------|---------|
| `~/code/shade/` | Main Shade Swift source |
| `~/.local/state/shade/` | Runtime state (nvim.sock, context.json, shade.pid) |
| `~/.dotfiles/config/hammerspoon/lib/interop/shade.lua` | Hammerspoon integration |
| `~/code/shade/.handoff/` | Integration docs for dotfiles |

## Notification Protocol (IPC)

Hammerspoon communicates with Shade via `DistributedNotificationCenter`:

| Notification | Purpose | Shade Action |
|--------------|---------|--------------|
| `io.shade.toggle` | Toggle panel visibility | Shows/hides panel |
| `io.shade.show` | Force show panel | Shows panel, activates |
| `io.shade.hide` | Force hide panel | Hides panel |
| `io.shade.quit` | Quit Shade | Terminates app |
| `io.shade.note.capture` | Text capture hotkey | Gathers context, creates capture note |
| `io.shade.note.daily` | Daily note hotkey | Opens :ObsidianToday via RPC |
| `io.shade.note.capture.image` | Image capture (clipper) | Reads context.json (imageFilename), creates image note |

### Notification Flow Example

```swift
// In Hammerspoon (Lua → ObjC bridge):
postNotification("io.shade.note.capture")

// In Shade (ShadeAppDelegate.swift):
@objc func handleCaptureNotification(_ notification: Notification) {
    Task {
        // 1. Gather context from frontmost app (AX, JXA, nvim RPC)
        let context = await ContextGatherer.shared.gather()
        
        // 2. Write context.json for obsidian.nvim template
        StateDirectory.writeContext(context)
        
        // 3. Send command to nvim via RPC
        try await ShadeNvim.shared.openNewCapture()
        
        // 4. Show panel
        showPanel()
    }
}
```

## State Directory (`~/.local/state/shade/`)

| File | Purpose | Format |
|------|---------|--------|
| `nvim.sock` | Nvim RPC socket | Unix domain socket |
| `context.json` | Capture context for obsidian.nvim | JSON |
| `shade.pid` | Process ID for Hammerspoon detection | Plain text |

### Context JSON Schema

```json
{
  "appType": "browser|terminal|neovim|editor|communication|other",
  "appName": "Brave Browser Nightly",
  "bundleID": "com.brave.Browser.nightly",
  "windowTitle": "GitHub - shade",
  "url": "https://github.com/example/shade",
  "filePath": "/path/to/file.swift",
  "filetype": "swift",
  "selection": "selected text here",
  "detectedLanguage": "swift",
  "line": 42,
  "col": 5,
  "imageFilename": "20260108-123456.png",
  "timestamp": "2026-01-08T12:34:56Z"
}
```

## Key Source Files

### ShadeAppDelegate.swift
- Main app lifecycle
- Notification listeners (toggle, capture, daily, image)
- Ghostty initialization
- Panel management

### ContextGatherer/ContextGatherer.swift
- Orchestrates context gathering from frontmost app
- Uses: AccessibilityHelper, AppTypeDetector, JXABridge, nvim RPC
- Entry point: `await ContextGatherer.shared.gather()`

### ShadeNvim.swift
- Actor for nvim msgpack-rpc communication
- Methods: `connect()`, `openDailyNote()`, `openNewCapture()`, `openImageCapture()`
- Uses `~/.local/state/shade/nvim.sock`

### StateDirectory.swift
- XDG-compliant state management
- `writeContext()`, `readContext()`, `readGatheredContext()`
- PID file management

## Context Gathering Flow

```
1. User hits Hyper+Shift+N (Hammerspoon)
2. Hammerspoon posts io.shade.note.capture
3. Shade receives notification
4. ContextGatherer.gather() called:
   a. Get frontmost app (NSWorkspace)
   b. Detect app type from bundle ID
   c. Based on type:
      - Browser: JXA for URL/title/selection, fallback to AX
      - Terminal: Check for nvim RPC, else AX
      - Other: Accessibility API
   d. Detect programming language
5. Write context.json
6. Send :Obsidian new_from_template via nvim RPC
7. Show panel
```

## Hammerspoon Integration

### shade.lua Functions

```lua
local M = require("lib.interop.shade")

M.isRunning()          -- Check if Shade process exists
M.launch(callback)     -- Launch Shade.app
M.show()               -- Post io.shade.show
M.hide()               -- Post io.shade.hide
M.toggle()             -- Post io.shade.toggle
M.quit()               -- Post io.shade.quit
M.captureWithContext() -- Post io.shade.note.capture (Shade gathers context)
M.openDailyNote()      -- Post io.shade.note.daily (Shade handles :ObsidianToday)
M.smartCaptureToggle() -- Toggle or capture based on state
M.smartToggle()        -- Smart toggle with auto-launch
```

### CRITICAL: Hammerspoon Should NOT Send nvim Commands

**Old pattern (deprecated):**
```lua
-- DON'T DO THIS
sendNvimCommand(":ObsidianToday")
```

**New pattern:**
```lua
-- DO THIS - Shade handles nvim RPC internally
postNotification(NOTIFICATION_DAILY)
```

## Decision Trees

### "Shade isn't working - what's wrong?"

```
Shade not working?
│
├─▶ Panel doesn't appear?
│   ├─▶ Check if running: pgrep -x Shade
│   │   ├─▶ NOT running → Launch Shade.app or require("lib.interop.shade").launch()
│   │   └─▶ Running → Check notification delivery (see below)
│   │
│   └─▶ Check notification:
│       └─▶ hs -c "require('lib.interop.shade').toggle()"
│           ├─▶ Works → Hammerspoon hotkey issue
│           └─▶ Doesn't work → Check IPC (notifications)
│
├─▶ nvim commands not executing?
│   ├─▶ Check socket: ls ~/.local/state/shade/nvim.sock
│   │   ├─▶ Missing → nvim not started or wrong path
│   │   └─▶ Exists → Test connection (see below)
│   │
│   └─▶ Test nvim connection:
│       └─▶ nvim --server ~/.local/state/shade/nvim.sock --remote-expr 'v:version'
│           ├─▶ Returns version → ShadeNvim actor issue
│           └─▶ Error → Socket stale or nvim crashed
│
├─▶ Context not captured?
│   ├─▶ Check context.json: cat ~/.local/state/shade/context.json | jq .
│   │   ├─▶ Empty/missing → ContextGatherer not running
│   │   └─▶ Has data → obsidian.nvim template issue
│   │
│   └─▶ Check Accessibility permissions:
│       └─▶ System Preferences → Privacy → Accessibility → Shade
│
└─▶ Image capture not working?
    └─▶ Check context.json has imageFilename
        ├─▶ Missing → Hammerspoon image path not written
        └─▶ Present → obsidian.nvim template issue
```

### "How do I debug IPC issues?"

```
IPC debugging?
│
├─▶ Hammerspoon → Shade direction:
│   └─▶ 1. Check HS can post: hs -c "require('lib.interop.shade').toggle()"
│       2. Check Shade logs: log stream --predicate 'subsystem == "io.shade"'
│       3. Verify notification received in logs
│
├─▶ Shade → nvim direction:
│   └─▶ 1. Check socket: ls ~/.local/state/shade/nvim.sock
│       2. Test manually: nvim --server ... --remote-expr 'v:version'
│       3. Check ShadeNvim connection state in logs
│
└─▶ Context flow:
    └─▶ 1. Trigger capture
        2. Immediately check: cat ~/.local/state/shade/context.json
        3. Check if obsidian.nvim reads it
```

## Debugging

### Check if Shade is running
```bash
pgrep -x Shade && cat ~/.local/state/shade/shade.pid
```

### Check nvim socket
```bash
ls -la ~/.local/state/shade/nvim.sock
# Test connection:
nvim --server ~/.local/state/shade/nvim.sock --remote-expr 'v:version'
```

### Check context.json
```bash
cat ~/.local/state/shade/context.json | jq .
```

### View Shade logs
```bash
log stream --predicate 'subsystem == "io.shade"' --level debug
```

### Test notifications manually
```bash
# From Hammerspoon console:
require("lib.interop.shade").toggle()
```

## Building Shade

```bash
cd ~/code/shade
swift build          # Debug build
swift build -c release  # Release build
swift run shade      # Run debug build
```

## Common Issues

### Panel doesn't show
1. Check if Shade is running: `pgrep -x Shade`
2. Check notifications: Are they being posted? Check Hammerspoon console.
3. Check logs: `log stream --predicate 'subsystem == "io.shade"'`

### nvim commands don't work
1. Check socket exists: `ls ~/.local/state/shade/nvim.sock`
2. Test nvim connection: `nvim --server ~/.local/state/shade/nvim.sock --remote-expr 'v:version'`
3. Check ShadeNvim connection state in logs

### Context not captured
1. Check Accessibility permissions in System Preferences
2. For browsers: JXA may need "Allow JavaScript from Apple Events" enabled
3. Check `~/.local/state/shade/context.json` after capture

## Related Components

- **GhosttyKit**: Embedded terminal library from Ghostty
- **obsidian.nvim**: Nvim plugin for Obsidian vault management
- **MsgpackRpc**: Swift msgpack-rpc library for nvim communication
- **Hammerspoon**: macOS automation (hotkeys, IPC bridge)

## Beads Epic Reference

- `shade-qji`: Context Gathering in Shade (completed Jan 2026)
  - shade-qji.1: AccessibilityHelper
  - shade-qji.2: AppTypeDetector
  - shade-qji.3: JXABridge
  - shade-qji.4: NvimContext
  - shade-qji.5: LanguageDetector
  - shade-qji.6: Wire up context gathering
