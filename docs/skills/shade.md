---
name: shade
description: Expert help with Shade - the native Swift note capture app. Use for debugging Shade issues, understanding IPC protocols, implementing Hammerspoon integration, nvim RPC, context gathering, and meganote workflows.
tools: Bash, Read, Grep, Glob, Edit, Write
---

# Shade Expert

## Related Skills

**Load the `notes` skill** for nvim-side meganote details:
- obsidian.nvim configuration and template substitutions
- Daily note linking (autocmds.lua)
- Capture filename format and same-day validation
- Task management and sorting

This skill focuses on **Shade app internals**: Swift code, IPC, context gathering, nvim RPC, and MLX inference.

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
| `io.shade.mode.sidebar-left` | Enter left sidebar mode | Resizes companion window, docks Shade left |
| `io.shade.mode.sidebar-right` | Enter right sidebar mode | Resizes companion window, docks Shade right |
| `io.shade.mode.floating` | Return to floating mode | Restores companion window, centers Shade |

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
-- Sidebar mode functions:
M.sidebarLeft()              -- Post io.shade.mode.sidebar-left
M.sidebarRight()             -- Post io.shade.mode.sidebar-right
M.floatingMode()             -- Post io.shade.mode.floating
M.sidebarToggle()            -- Toggle between sidebar-left and floating
M.captureWithContextSidebar() -- Capture note in sidebar mode
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

## Sidebar Mode

Shade can dock to the left or right of the screen, resizing the "companion" window (the frontmost app when sidebar mode is entered) to share screen space.

### Architecture

- Shade uses AXUIElement APIs to resize the companion window
- Window positions are tracked for restore on floating mode
- All window management happens in Shade (not Hammerspoon)

### Workflow

1. User hits hotkey (e.g., Hyper+Shift+L for sidebar-left)
2. Hammerspoon posts `io.shade.mode.sidebar-left`
3. Shade:
   - Captures companion window reference
   - Resizes companion to right 60% of screen
   - Docks Shade panel to left 40%
4. On `io.shade.mode.floating`:
   - Restores companion window to original size
   - Returns Shade to centered floating panel

### Companion Window

The "companion" window is the frontmost app's active window when sidebar mode is entered. Shade:
- Stores reference via AXUIElement
- Tracks original frame for restore
- Applies 60/40 split (companion on right for left sidebar)

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

## LLM Integration (MLX Swift)

Shade uses **MLX Swift** for native on-device LLM inference. This enables summarization, categorization, and content enrichment without external API calls.

### Design Philosophy

- **Quality over speed** - Notes are permanent artifacts; precision matters more than latency
- **Backend-agnostic config** - Config key is `llm` (not `mlx`) for future flexibility
- **Async enrichment** - VisionKit provides instant OCR; LLM enriches asynchronously

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Shade.app                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │ ShadeConfig     │  │ MLXInference-   │  │ AsyncEnrich-    │  │
│  │ (config.json)   │  │ Engine (actor)  │  │ mentManager     │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                     │           │
│           ▼                    ▼                     ▼           │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    Capture Pipeline                          ││
│  │  1. VisionKit OCR (instant)                                  ││
│  │  2. Insert OCR text + placeholder                            ││
│  │  3. Async: MLX summarize/categorize                          ││
│  │  4. nvim RPC: Replace placeholder with enriched content      ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Configuration

Config is **generated by Nix** from `~/.dotfiles/home/programs/shade.nix`:

```nix
# In home-manager config
shadeConfig = {
  llm = {
    enabled = true;
    backend = "mlx";
    model = "mlx-community/Qwen3-8B-Instruct-4bit";
    preset = "quality";  # quality | balanced | fast
    max_tokens = 512;
    temperature = 0.7;
  };
  capture = {
    working_directory = config.home.sessionVariables.notes_home + "/captures";
    async_enrichment = true;
  };
};

xdg.configFile."shade/config.json".text = builtins.toJSON shadeConfig;
```

**Config location**: `~/.config/shade/config.json`

### Recommended Models (M2 Max 64GB)

| Model | Size | Speed | Quality | Use Case |
|-------|------|-------|---------|----------|
| **Qwen3-8B-Instruct-4bit** | ~4.3 GB | ~50 tok/s | ★★★★½ | Default (quality) |
| Llama-3.2-3B-Instruct-4bit | ~1.8 GB | ~90 tok/s | ★★★½ | Balanced |
| Qwen3-4B-Instruct-4bit | ~2.3 GB | ~75 tok/s | ★★★★ | Good balance |

### Key Source Files (LLM)

| File | Purpose |
|------|---------|
| `Sources/MLXInferenceEngine.swift` | Actor for lazy model loading and inference |
| `Sources/ShadeConfig.swift` | Parse and validate config.json |
| `Sources/AsyncEnrichmentManager.swift` | Manage background enrichment tasks |

### Async Enrichment Flow

```
1. User captures image (Hyper+Shift+I)
2. SYNCHRONOUS (instant):
   ├─ VisionKit extracts OCR text
   ├─ Create note with OCR text + placeholder:
   │    ## Summary
   │    <!-- shade:pending:summary -->
   └─ Show panel immediately

3. ASYNCHRONOUS (background):
   ├─ MLXInferenceEngine.summarize(ocrText, context)
   ├─ When complete, send nvim RPC:
   │    nvim_buf_set_lines() to replace placeholder
   └─ Optional: nvim notification "✓ Summary ready"
```

### Placeholder Pattern

Placeholders mark where async content will be injected:

```markdown
## Summary
<!-- shade:pending:summary -->

## Tags
<!-- shade:pending:tags -->
```

After enrichment:
```markdown
## Summary
This image shows a code snippet implementing...

## Tags
#code #swift #mlx
```

### LLM Debugging

```bash
# Check if config is valid
cat ~/.config/shade/config.json | jq .

# Check model cache location
ls ~/Library/Caches/mlx-swift/

# View LLM-specific logs
log stream --predicate 'subsystem == "io.shade" AND category == "llm"' --level debug

# Test MLX inference directly (if CLI available)
swift run shade --test-llm "Summarize: Hello world"
```

### Decision Tree: LLM Not Working

```
LLM not working?
│
├─▶ Model not loading?
│   ├─▶ Check config: cat ~/.config/shade/config.json | jq .llm
│   ├─▶ Check model exists: ls ~/Library/Caches/mlx-swift/
│   └─▶ Check memory: Model needs ~8GB for Qwen3-8B
│
├─▶ Enrichment not appearing?
│   ├─▶ Check async_enrichment enabled in config
│   ├─▶ Check placeholder exists in note
│   └─▶ Check nvim RPC connection (see nvim debugging above)
│
└─▶ Quality issues?
    ├─▶ Try larger model (more quality, more memory)
    ├─▶ Adjust temperature (lower = more deterministic)
    └─▶ Check prompt templates in obsidian.nvim config
```

## Beads Epic Reference

- `shade-qji`: Context Gathering in Shade (completed Jan 2026)
  - shade-qji.1: AccessibilityHelper
  - shade-qji.2: AppTypeDetector
  - shade-qji.3: JXABridge
  - shade-qji.4: NvimContext
  - shade-qji.5: LanguageDetector
  - shade-qji.6: Wire up context gathering

- `shade-ahf`: MLX Swift Integration (in progress Jan 2026)
  - Native on-device LLM inference via mlx-swift-lm
  - Async enrichment pipeline with nvim RPC
  - Nix-generated configuration
