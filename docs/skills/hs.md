---
name: hs
description: Comprehensive guide for Hammerspoon development in this dotfiles repo. Covers config patterns, debugging decision trees, API reference, performance monitoring, and troubleshooting.
tools: Bash, Read, Edit
---

# Hammerspoon Development Guide

## Overview

Hammerspoon is the macOS automation backbone. It handles hotkeys, window management, notifications, app integrations (Shade, browser, nvim), and system event watchers.

**CRITICAL**: Before making changes:
1. Verify NO LSP/diagnostic errors in the file
2. Research APIs at https://www.hammerspoon.org/docs/
3. Test in console before committing
4. Performance matters - CPU/memory efficiency is critical

## Configuration Structure

```
config/hammerspoon/
├── init.lua              # Entry point - loads modules in order
├── preflight.lua         # Early setup (IPC, globals, logging)
├── overrides.lua         # Monkey-patches for hs.* modules
├── config.lua            # C.* configuration table (SOURCE OF TRUTH)
├── utils.lua             # U.* utilities (logging, helpers)
├── bindings.lua          # Hotkey definitions
├── hyper.lua             # Hyper key (F19) modal system
├── hypemode.lua          # Hype mode (double-tap) triggers
├── chain.lua             # Window chaining operations
├── clipper.lua           # Clipboard manager
├── contexts/             # Per-app behavior customizations
│   ├── init.lua          # Context loader
│   └── com.*.lua         # App-specific context files
├── watchers/             # Event observers
│   ├── notification.lua  # NC notification capture
│   ├── screen.lua        # Display change watcher
│   └── ...
└── lib/                  # Reusable modules
    ├── state.lua         # S.* centralized state (S.notification.*, etc.)
    ├── canvas.lua        # Canvas drawing utilities
    ├── db.lua            # SQLite database wrapper
    ├── notifications/    # Notification system (N.*)
    │   ├── init.lua      # Main entry (N.send, N.init)
    │   ├── send.lua      # N.send() implementation
    │   ├── notifier.lua  # Canvas notification rendering
    │   └── processor.lua # Rule-based routing
    ├── interop/          # External app integrations
    │   ├── shade.lua     # Shade.app IPC
    │   ├── browser.lua   # Browser JXA bridge
    │   ├── nvim.lua      # Neovim RPC
    │   └── selection.lua # Text selection helpers
    └── meeting/          # Meeting detection
```

## Global References

| Global | Purpose | Source |
|--------|---------|--------|
| `C` | Config table | `config.lua` |
| `U` | Utilities (`U.log.i()`, `U.log.e()`, `U.log.d()`) | `utils.lua` |
| `N` | Notification system | `lib/notifications/init.lua` |
| `S` | State management (`S.notification.*`, `S.watcher.*`) | `lib/state.lua` |
| `I` | Inspect alias (`I(obj)` = `hs.inspect(obj)`) | `init.lua` |
| `P` | Debug print with location | `init.lua` |
| `TERMINAL` | Terminal bundle ID | `config.lua` (Ghostty) |
| `BROWSER` | Browser bundle ID | `config.lua` (Brave Nightly) |
| `HYPER` | Hyper key | `config.lua` (F19) |

## Decision Tree: What to Check When Things Break

### "Hotkey doesn't work"

```
1. Is Hammerspoon running?
   └─ pgrep Hammerspoon || open -a Hammerspoon

2. Is hotkey defined?
   └─ rg "the-key" config/hammerspoon/bindings.lua config/hammerspoon/hyper.lua

3. Is it in a modal that's not active?
   └─ Check if it's in hyper.lua (needs F19 held) or hypemode.lua (needs double-tap)

4. Is the handler erroring?
   └─ hs -c "hs.openConsole()" → check for red errors
   └─ Or: log stream --predicate 'subsystem == "org.hammerspoon.Hammerspoon"'

5. Is accessibility permission granted?
   └─ System Settings → Privacy & Security → Accessibility → Hammerspoon ✓
```

### "Window management doesn't work"

```
1. Is the app excluded from window management?
   └─ rg "bundleID" config/hammerspoon/config.lua (check C.layouts)

2. Does the window have a valid frame?
   └─ hs -c "print(I(hs.window.focusedWindow():frame()))"

3. Is it a special window (floating, panel, etc.)?
   └─ hs -c "print(hs.window.focusedWindow():subrole())"
   └─ Check if subrole is AXFloatingWindow, AXSystemDialog, etc.

4. Is the screen/display configured?
   └─ Check C.displays in config.lua matches actual display names
   └─ hs -c "print(I(hs.screen.allScreens()))"
```

### "Notification not showing"

```
1. Is notification system initialized?
   └─ hs -c "print(N ~= nil)"

2. Is canvas rendering working?
   └─ hs -c "N.send({title='Test', message='Test', urgency='normal'})"

3. Is the rule suppressing it?
   └─ Check C.notificationRules in config.lua
   └─ Maybe a rule is matching and dismissing

4. Is it a focus mode issue?
   └─ Check C.overrideFocusModes settings

5. Check the notification database:
   └─ sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
        "SELECT * FROM notifications ORDER BY timestamp DESC LIMIT 5"
```

### "Performance is bad / Hammerspoon laggy"

```
1. Check CPU usage:
   └─ top -pid $(pgrep Hammerspoon) -l 1

2. Check memory:
   └─ ps -o rss,vsz -p $(pgrep Hammerspoon)

3. Is a watcher running too often?
   └─ Add logging to watcher callbacks
   └─ U.log.d("watcher fired", ...)

4. Is there an infinite loop?
   └─ Check for circular requires or recursive callbacks

5. Canvas leak?
   └─ hs -c "print(#hs.canvas.list())"
   └─ Should be small (<10 typically)

6. Timer leak?
   └─ Check S.notification.timers or other state for accumulated timers
```

## Reloading Hammerspoon

**CRITICAL**: Use this exact pattern to avoid hangs:

```bash
RELOAD_TIME=$(date +%s)
timeout 2 hs -c "hs.reload()" 2>&1 || true
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT timestamp FROM notifications WHERE sender = 'hammerspork' AND message = 'config is loaded.' AND timestamp >= $RELOAD_TIME LIMIT 1" \
  && echo "✓ Reloaded successfully"
```

**Why timeout?** `hs.reload()` destroys the Lua interpreter, causing the CLI to hang. The timeout is expected and normal.

**Verification**: The reload success notification is logged to SQLite. Query it to confirm.

### Quick reload verification alternatives

```bash
# Method 1: Check notification database (most reliable)
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT datetime(timestamp, 'unixepoch', 'localtime'), message FROM notifications WHERE sender = 'hammerspork' ORDER BY timestamp DESC LIMIT 1"

# Method 2: Test a simple command works
hs -c "print('alive')"

# Method 3: Check IPC is responding
hs -c "return hs.processInfo.processID"
```

## Common API Patterns

### Window Management

```lua
-- Get focused window
local win = hs.window.focusedWindow()
if not win then return end  -- Always check!

-- Get/set frame
local frame = win:frame()
win:setFrame(frame)

-- Get screen
local screen = win:screen()
local screenFrame = screen:frame()

-- Move to position
win:setTopLeft(hs.geometry.point(100, 100))

-- Resize
win:setSize(hs.geometry.size(800, 600))

-- Move to another screen
win:moveToScreen(hs.screen.find("LG UltraFine"))

-- Center on screen
win:centerOnScreen()

-- Full screen toggle
win:setFullscreen(not win:isFullscreen())
```

### Application Management

```lua
-- Find by name or bundle ID
local app = hs.application.find("com.brave.Browser.nightly")
local app = hs.application.get("Brave Browser Nightly")

-- Frontmost app
local frontApp = hs.application.frontmostApplication()

-- Launch or focus
hs.application.launchOrFocusByBundleID("com.brave.Browser.nightly")

-- All windows
local windows = app:allWindows()

-- Main window
local mainWin = app:mainWindow()

-- Activate (bring to front)
app:activate()

-- Hide
app:hide()
```

### Accessibility (AX)

```lua
local ax = hs.axuielement

-- Get element for app
local appElement = ax.applicationElement(app)

-- Get attribute
local children = appElement:attributeValue("AXChildren")
local role = appElement:attributeValue("AXRole")
local title = appElement:attributeValue("AXTitle")

-- Common attributes
-- AXRole, AXSubrole, AXTitle, AXDescription, AXValue
-- AXFocused, AXEnabled, AXPosition, AXSize
-- AXChildren, AXParent, AXWindows, AXFocusedWindow

-- Perform action
appElement:performAction("AXPress")
appElement:performAction("AXRaise")

-- Build a tree
local function printAXTree(el, depth)
  depth = depth or 0
  if depth > 3 then return end
  local role = el:attributeValue("AXRole") or "?"
  local title = el:attributeValue("AXTitle") or ""
  print(string.rep("  ", depth) .. role .. ": " .. title)
  for _, child in ipairs(el:attributeValue("AXChildren") or {}) do
    printAXTree(child, depth + 1)
  end
end
```

### Notifications

```lua
-- Using the notification system (N.send)
N.send({
  title = "Title",
  message = "Message body",
  urgency = "normal",  -- "low"|"normal"|"high"|"critical"
})

-- With phone notification
N.send({
  title = "Alert",
  message = "Something important",
  urgency = "critical",  -- Auto-sends to phone
  phone = true,          -- Or explicit
})

-- Native hs.notify (goes to NC only)
hs.notify.new({
  title = "Title",
  informativeText = "Body",
}):send()
```

### Distributed Notifications (IPC)

```lua
-- Post to external apps (e.g., Shade)
hs.distributednotifications.post("io.shade.toggle", nil, nil)

-- Listen from external apps
local watcher = hs.distributednotifications.new(function(name, object, info)
  U.log.i("Received:", name, object, info)
end, "notification.name")
watcher:start()
```

### Timers

```lua
-- One-shot timer (after delay)
hs.timer.doAfter(2, function()
  -- Runs once after 2 seconds
end)

-- Repeating timer
local timer = hs.timer.new(5, function()
  -- Runs every 5 seconds
end)
timer:start()
timer:stop()  -- Don't forget to stop!

-- Delayed timer (common pattern)
hs.timer.delayed.new(0.5, function()
  -- Runs 0.5s after last trigger
end):start()
```

### Canvas (Drawing)

```lua
local canvas = hs.canvas.new({ x = 100, y = 100, w = 200, h = 100 })
canvas:appendElements({
  {
    type = "rectangle",
    fillColor = { red = 0, green = 0, blue = 0, alpha = 0.8 },
    roundedRectRadii = { xRadius = 10, yRadius = 10 },
  },
  {
    type = "text",
    text = "Hello",
    textColor = { white = 1 },
    textAlignment = "center",
    frame = { x = 0, y = 35, w = 200, h = 30 },
  },
})
canvas:show()

-- IMPORTANT: Always clean up canvases
canvas:delete()  -- or canvas:hide() then delete later
```

## Debugging Commands

```bash
# Open Hammerspoon console
hs -c "hs.openConsole()"

# Check if running
pgrep Hammerspoon

# View logs
log stream --predicate 'subsystem == "org.hammerspoon.Hammerspoon"' --level debug

# Test a module
hs -c "print(I(require('lib.interop.shade')))"

# Check state
hs -c "print(I(S.notification))"

# Check config
hs -c "print(I(C.displays))"

# List loaded modules
hs -c "for k,v in pairs(package.loaded) do print(k) end"

# Memory usage (canvas count is a good indicator)
hs -c "print('Canvases:', #hs.canvas.list())"

# Check notification rules
hs -c "print(I(C.notificationRules))"

# Query notification database
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT datetime(timestamp,'unixepoch','localtime') as time, sender, title, message FROM notifications ORDER BY timestamp DESC LIMIT 10"
```

## Performance Monitoring

```lua
-- Memory tracking
local function logMemory(label)
  collectgarbage("collect")
  local mem = collectgarbage("count")
  U.log.i(label .. " memory:", string.format("%.2f KB", mem))
end

-- Timer audit
local function auditTimers()
  -- Check S.* for timer accumulation
  local count = 0
  for k, v in pairs(S.notification.timers or {}) do
    count = count + 1
  end
  U.log.i("Active notification timers:", count)
end

-- Canvas audit
local function auditCanvases()
  local canvases = hs.canvas.list()
  U.log.i("Active canvases:", #canvases)
  for i, c in ipairs(canvases) do
    U.log.d("  Canvas", i, c:frame())
  end
end
```

## Common Issues and Fixes

### "Error: attempt to index nil value"
**Cause**: Trying to access property on nil object (window closed, app quit, etc.)
**Fix**: Always check for nil before accessing:
```lua
local win = hs.window.focusedWindow()
if not win then return end
```

### "Hammerspoon uses too much CPU"
**Cause**: Watcher firing too often, infinite loop, or timer leak
**Fix**:
1. Add debouncing to watchers
2. Check for recursive callbacks
3. Ensure timers are stopped when not needed

### "Canvas not appearing"
**Cause**: Canvas behind other windows, wrong coordinates, or not shown
**Fix**:
```lua
canvas:level(hs.canvas.windowLevels.overlay)  -- Above everything
canvas:behavior(hs.canvas.windowBehaviors.canJoinAllSpaces)
canvas:show()
```

### "Accessibility not working"
**Cause**: Permission not granted or app not accessibility-enabled
**Fix**:
1. System Settings → Privacy & Security → Accessibility → Hammerspoon ✓
2. Some apps (like browsers) need extra permissions
3. Try `hs.accessibilityState()` to check

### "Module not found after reload"
**Cause**: Cached require not cleared
**Fix**:
```lua
package.loaded["module.name"] = nil
require("module.name")
```

## Files to Check First

| Symptom | Check This File |
|---------|-----------------|
| Hotkey not working | `bindings.lua`, `hyper.lua` |
| Window behavior | `config.lua` (C.layouts), `chain.lua` |
| Notification issue | `lib/notifications/*.lua`, `config.lua` (C.notificationRules) |
| App-specific behavior | `contexts/com.bundleid.lua` |
| IPC with Shade | `lib/interop/shade.lua` |
| Browser automation | `lib/interop/browser.lua` |
| State/globals | `lib/state.lua`, `init.lua` |

## Discovering Hammerspoon Capabilities

### List All Available Modules

```lua
-- In Hammerspoon console: list all hs.* modules
for k, v in pairs(hs) do
  if type(v) == "table" then
    print("hs." .. k)
  end
end

-- Check what a module provides
print(I(hs.window))  -- See all methods/properties

-- Get help for a function
help("hs.window.focusedWindow")
```

### Key hs.* Modules Reference

| Module | Purpose |
|--------|---------|
| `hs.window` | Window manipulation |
| `hs.application` | Application control |
| `hs.screen` | Display/screen info |
| `hs.hotkey` | Keyboard shortcuts |
| `hs.eventtap` | Low-level input events |
| `hs.canvas` | Custom drawing |
| `hs.notify` | Native notifications |
| `hs.distributednotifications` | IPC with other apps |
| `hs.axuielement` | Accessibility API |
| `hs.osascript` | AppleScript/JXA |
| `hs.timer` | Timers and delays |
| `hs.task` | Run shell commands |
| `hs.socket` | Network sockets |
| `hs.http` | HTTP requests |
| `hs.json` | JSON encode/decode |
| `hs.fs` | File system operations |
| `hs.audiodevice` | Audio input/output |
| `hs.battery` | Battery status |
| `hs.caffeinate` | Prevent sleep |
| `hs.pasteboard` | Clipboard |
| `hs.chooser` | Selection UI |
| `hs.alert` | Simple alerts |
| `hs.menubar` | Menu bar icons |
| `hs.pathwatcher` | File change watcher |
| `hs.usb` | USB device events |
| `hs.wifi` | WiFi info |
| `hs.location` | GPS location |
| `hs.speech` | Text-to-speech |

### Reading Hammerspoon Source

The Hammerspoon codebase reveals capabilities not always in docs:

```bash
# Clone Hammerspoon source for deep reference
git clone https://github.com/Hammerspoon/hammerspoon.git /tmp/hs-source

# Search for specific functionality
rg "AX" /tmp/hs-source/extensions --type objc

# Check how a module is implemented
cat /tmp/hs-source/extensions/window/window.lua

# Find undocumented features
rg "@objc func" /tmp/hs-source/Hammerspoon --type swift
```

### Checking Documentation Gaps

```bash
# Hammerspoon docs source
git clone https://github.com/Hammerspoon/hammerspoon.github.io.git /tmp/hs-docs

# Compare extension implementations vs docs
ls /tmp/hs-source/extensions/
# vs
ls /tmp/hs-docs/docs/
```

## Known Limitations and Issues

### Platform Limitations (macOS)

| Limitation | Reason | Workaround |
|------------|--------|------------|
| Cannot interact with full-screen apps in other Spaces | macOS security | None - OS limitation |
| AX may not work with some apps | App doesn't implement AX | Use JXA/AppleScript |
| Cannot capture global hotkeys used by system | SIP protection | Remap in System Settings |
| Window manipulation slow for some apps | App uses non-standard windows | Use hs.timer delays |
| Cannot read passwords/secure text fields | macOS security | None - by design |

### Common GitHub Issues

Check these resources for known bugs:

```bash
# Current open issues
open "https://github.com/Hammerspoon/hammerspoon/issues"

# Search for specific problem
open "https://github.com/Hammerspoon/hammerspoon/issues?q=is%3Aissue+canvas+leak"

# Check if issue is fixed in newer version
open "https://github.com/Hammerspoon/hammerspoon/releases"
```

**Notable recurring issues:**
- Canvas memory leaks (always delete canvases)
- hs.reload() hanging (use timeout pattern)
- Accessibility permission revoked after macOS updates
- Window filters not catching all events
- Some apps not responding to AX actions

### Version Compatibility

```lua
-- Check Hammerspoon version
print(hs.processInfo.version)

-- Check if feature exists (defensive coding)
if hs.canvas then
  -- Use canvas
else
  hs.alert("Canvas not available in this version")
end

-- Check macOS version for compatibility
local osVersion = hs.host.operatingSystemVersion()
print(osVersion.major, osVersion.minor, osVersion.patch)
```

### Undocumented But Useful

```lua
-- hs.inspect (aliased as I in this config)
print(hs.inspect(someTable, { depth = 2 }))

-- hs.printf (like printf)
hs.printf("Value: %s", someValue)

-- hs.fnutils (functional programming)
local mapped = hs.fnutils.map(list, function(x) return x * 2 end)
local filtered = hs.fnutils.filter(list, function(x) return x > 5 end)

-- hs.geometry helpers
local rect = hs.geometry.rect(0, 0, 100, 100)
rect:move(10, 20)
rect:scale(1.5)

-- hs.settings (persistent storage)
hs.settings.set("myKey", "myValue")
local value = hs.settings.get("myKey")

-- hs.ipc (command line communication)
-- This is how `hs -c "..."` works
```

### Extensions Not in Default Build

Some extensions require manual compilation or are experimental:

```lua
-- Check if extension exists
if hs.razer then print("Razer support available") end
if hs.streamdeck then print("Stream Deck support available") end
if hs.tangent then print("Tangent panel support available") end
```

## Self-Discovery Pattern

When you don't know if Hammerspoon can do something:

```
1. Check if module exists:
   └─ hs -c "print(hs.modulename ~= nil)"

2. List module contents:
   └─ hs -c "for k,v in pairs(hs.modulename) do print(k, type(v)) end"

3. Check docs:
   └─ open "https://www.hammerspoon.org/docs/hs.modulename.html"

4. Search GitHub issues:
   └─ open "https://github.com/Hammerspoon/hammerspoon/issues?q=modulename"

5. Search source code:
   └─ rg "modulename" /path/to/hammerspoon/source

6. Ask in community:
   └─ https://github.com/Hammerspoon/hammerspoon/discussions
   └─ IRC: #hammerspoon on Libera.Chat
```

## Related Resources

- **Hammerspoon Expert Agent**: Spawn for deep debugging/exploration tasks
- **Shade Skill**: For Shade.app integration
- **Smart-ntfy Skill**: For notification system details
- **Hammerspoon Docs**: https://www.hammerspoon.org/docs/
- **Hammerspoon GitHub**: https://github.com/Hammerspoon/hammerspoon
- **Hammerspoon Wiki**: https://github.com/Hammerspoon/hammerspoon/wiki
- **Notification DB**: `~/.local/share/hammerspoon/hammerspoon.db`
- **Spoons (plugins)**: https://www.hammerspoon.org/Spoons/
