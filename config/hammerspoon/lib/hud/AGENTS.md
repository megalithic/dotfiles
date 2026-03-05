# lib/hud/ — Unified HUD system

## Overview

Replaces `hs.alert`, `lib/notifications/notifier`, and bespoke canvas code.
Provides animated notifications/indicators with proper DPI scaling.

## Quick patterns

```lua
-- Alert (replaces hs.alert)
HUD.alert("Copied!")
HUD.alert("Error!", { iconType = "error", duration = 5 })

-- Toast (replaces sendCanvasNotification)
HUD.toast({
  title = "Slack",
  message = "New message",
  appBundleID = "com.tinyspeck.slackmacgap",
})

-- Panel (complex display like clipper)
local panel = HUD.panel({ id = "clipper", timeout = 10 })
panel:setMedia(image, { onClick = function() hs.open(path) end })
panel:setStatus("Uploading...", { color = "FFA500" })
panel:setContent({ { key = "v", desc = "Paste" } })
panel:show()

-- Update in place (no flicker)
panel:setStatus("✓ Done", { color = "4CD964" })

-- Persistent indicator
local mic = HUD.persistent({ id = "mic", content = { icon = img, color = "red" } })
mic:show()
mic:dismiss()
```

## HUD types

| Type | Use case | Auto-dismiss |
|------|----------|--------------|
| `alert` | Simple messages | Yes (3s default) |
| `toast` | Notifications with title/icon | Yes (5s default) |
| `panel` | Complex multi-element (media, status, keybindings) | Configurable |
| `persistent` | Indicators (mic active, recording) | No |

## Alert iconTypes

Built-in icons (no need to provide hs.image):
- `"checkmark"` — Green check
- `"warning"` — Yellow triangle
- `"error"` — Red X
- `"info"` — Blue circle
- `"gear"` — Gray gear

```lua
HUD.alert("Success", { iconType = "checkmark" })
```

## Panel API

```lua
local p = HUD.panel({
  id = "unique-id",           -- For position persistence
  position = "bottom-center", -- 9-point anchor
  ephemeral = true,           -- Auto-dismiss (default: true)
  timeout = 10,               -- Seconds (nil = manual dismiss)
})

p:setMedia(image, { onClick = fn })  -- Image (future: video via webview)
p:setStatus(text, { color = hex })   -- Status line
p:setContent(bindings)               -- Array of { key, desc }
p:show()
p:dismiss()
```

**Status colors:** Hex string (`"4CD964"`) or table (`{ red=0.3, green=0.9, blue=0.5 }`)

## Positioning

```
top-left      top-center      top-right
left-center   center          right-center
bottom-left   bottom-center   bottom-right
cursor
```

## Scaling

- **Laptop:** 1.0x
- **External:** 1.25x (auto-detected)

## Time units

- **Seconds** for `duration`, `timeout` (human-scale)
- **Milliseconds** for `animation` (precision)

## Management

```lua
HUD.dismissAll()              -- All HUDs
HUD.dismissAll({ type = "ephemeral" })
HUD.get(id)                   -- Get by ID
HUD.dismiss(id)               -- Dismiss by ID
HUD.cleanup()                 -- Call on reload
```

## Architecture

```
lib/hud/
├── init.lua          -- Public API (HUD.alert, etc.)
├── types.lua         -- Alert, Toast, Panel, Persistent classes
├── renderer.lua      -- Canvas element creation
├── animator.lua      -- Slide/fade/scale animations
├── position.lua      -- 9-point positioning, DPI scaling
├── theme.lua         -- Dark/light mode colors
├── persistence.lua   -- hs.settings wrapper
├── stack.lua         -- Multi-HUD z-ordering
└── sfsymbol.lua      -- SF Symbol loading (via ~/bin/sfsymbol.swift)
```

## Common mistakes

```lua
-- WRONG: icon expects hs.image, not string
HUD.alert("Hi", { icon = "checkmark" })

-- CORRECT: use iconType for built-in icons
HUD.alert("Hi", { iconType = "checkmark" })

-- WRONG: persistent option doesn't exist
HUD.panel({ persistent = true })

-- CORRECT: use ephemeral = false
HUD.panel({ ephemeral = false })

-- WRONG: recreating panel on status update
panel:dismiss()
panel = HUD.panel(...)
panel:show()

-- CORRECT: update in place
panel:setStatus("New status")
```

## Media support

Currently: `hs.image` only (static images, GIFs show first frame)

Future: `hs.webview` fallback for video/animated GIF (research only, not implemented)
