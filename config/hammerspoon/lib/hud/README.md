# HUD Module

Unified HUD system for Hammerspoon. Provides consistent, animated notifications
and indicators with proper scaling across displays.

## Quick Start

```lua
local hud = require("lib.hud")

-- Simple alert (replaces hs.alert)
hud.alert("Copied!")

-- Alert with icon and duration
hud.alert("Error!", { icon = errorIcon, duration = 5 })

-- Toast notification (replaces sendCanvasNotification)
hud.toast({
  title = "Slack",
  message = "New message from Alice",
  appBundleID = "com.tinyspeck.slackmacgap",
  duration = 5,
})

-- Panel for complex displays (e.g., clipper)
local panel = hud.panel({ id = "clipper", timeout = 10 })
panel:setThumbnail(image, { onClick = function() hs.open(path) end })
panel:setStatus("Uploading...", { color = "warning" })
panel:setContent({
  { key = "v", desc = "Paste URL" },
  { key = "m", desc = "Markdown" },
})
panel:show()

-- Update status in place (no hide/reshow)
panel:setStatus("✓ Uploaded", { color = "success" })

-- Persistent indicator (stays until dismissed)
local mic = hud.persistent({
  id = "mic-active",
  content = { icon = micIcon, color = "error" },
})
mic:show()
mic:dismiss()
```

## API Reference

### Alert

Simple ephemeral message. Fancy replacement for `hs.alert`.

```lua
hud.alert(message, opts?)
```

**Options:**
- `icon` — `hs.image` to display
- `duration` — Seconds before auto-dismiss (default: 3)
- `position` — Anchor position (default: "bottom-center")
- `animation` — Animation duration in milliseconds (default: 250)
- `style.fontSize` — Font size
- `style.color` — Text color

**Convenience methods:**
- `hud.success(message, opts?)` — Green checkmark
- `hud.warning(message, opts?)` — Yellow triangle
- `hud.error(message, opts?)` — Red X
- `hud.info(message, opts?)` — Blue info circle

### Toast

Notification-style with title, subtitle, message, and icon.

```lua
hud.toast(opts)
```

**Options:**
- `title` — Bold title text
- `subtitle` — Secondary text (optional)
- `message` — Body text
- `icon` — `hs.image` to display
- `appBundleID` — App bundle ID for auto-icon and click-to-focus
- `duration` — Seconds before auto-dismiss (default: 5)
- `position` — Anchor position (default: "bottom-left")
- `onClick` — Callback when toast is clicked
- `onIconClick` — Callback when icon is clicked

### Panel

Rich multi-element HUD. Use for complex displays like clipper.

```lua
local panel = hud.panel(opts)
```

**Options:**
- `id` — Unique identifier (for position persistence)
- `position` — Anchor position (default: "bottom-center")
- `timeout` — Seconds before auto-dismiss (nil = manual)
- `onHover.scale` — Scale factor when hovering thumbnail (e.g., 2.0)

**Methods:**
- `panel:setThumbnail(image, { onClick? })` — Set thumbnail image
- `panel:setStatus(text, { color? })` — Set status text
- `panel:setContent(content)` — Set additional content (e.g., keybinding hints)
- `panel:show()` — Display the panel
- `panel:dismiss()` — Hide the panel

### Persistent

Indicator that stays visible until explicitly dismissed.

```lua
local indicator = hud.persistent(opts)
```

**Options:**
- `id` — Unique identifier (required)
- `content.icon` — `hs.image` icon
- `content.text` — Text label
- `content.color` — Icon/text color (name or table)
- `position` — Anchor position (default: "top-right")
- `onClick` — Callback when clicked

**Methods:**
- `indicator:show()` — Display
- `indicator:dismiss()` — Hide
- `indicator:update(content)` — Update content

### Management

```lua
hud.dismissAll()        -- Dismiss all HUDs
hud.dismissAll({ type = "ephemeral" })  -- Only ephemeral
hud.get(id)             -- Get HUD by ID
hud.dismiss(id)         -- Dismiss specific HUD
hud.getActive()         -- Get all active HUDs
hud.cleanup()           -- Clean up (call on reload)
```

## Positioning

9 anchor points plus cursor-relative:

```
top-left      top-center      top-right
left-center   center          right-center
bottom-left   bottom-center   bottom-right
cursor
```

Position is persisted per HUD ID via `hs.settings`.

## Scaling

Two-tier scaling:
- **Laptop display:** 1.0x
- **External display:** 1.5x

Detection is automatic based on screen name.

## Theming

Colors automatically follow system dark/light mode.

```lua
local theme = require("lib.hud.theme")
theme.getColors()       -- Current color scheme
theme.isDarkMode()      -- Check appearance
```

## Time Units

- **Seconds** for durations (human-scale): `duration = 5`
- **Milliseconds** for animations (precision): `animation = 300`

## Architecture

```
lib/hud/
├── init.lua          -- Main API
├── types.lua         -- HUD type classes
├── renderer.lua      -- Canvas rendering
├── animator.lua      -- Animation primitives
├── position.lua      -- Positioning logic
├── theme.lua         -- Color schemes
├── persistence.lua   -- Settings storage
└── stack.lua         -- Multi-HUD management
```
