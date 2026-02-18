# Hammerspoon DPI/Scale Factor Detection

Research notes for HUD module display scaling.

## Current Implementation (v1)

Simple 2-tier scaling based on display name detection:

```lua
local position = require("lib.hud.position")

-- Check if external display
local isExternal = position.isExternalDisplay(screen)  -- true/false

-- Get scale factor
local scale = position.getScaleFactor(screen)  -- 1.0 or 1.5
```

**Logic:**
- Built-in display (contains "built-in", "color lcd", "internal"): 1.0x
- External display: 1.5x

This is sufficient for most use cases but doesn't account for:
- Different external monitor sizes/resolutions
- Per-display DPI differences
- User preferences

## Available Hammerspoon APIs

### `screen:currentMode()`

Returns the current display mode:

```lua
local mode = screen:currentMode()
-- mode.w        -- Width in points
-- mode.h        -- Height in points
-- mode.scale    -- Scaling factor (1 or 2 for retina)
-- mode.freq     -- Refresh rate
-- mode.depth    -- Color depth
```

**Note:** `mode.scale` is the macOS backing scale (1 = standard, 2 = retina), not
a physical DPI metric.

### `screen:fullFrame()` vs `screen:frame()`

```lua
local fullFrame = screen:fullFrame()  -- Includes menu bar/dock
local frame = screen:frame()          -- Usable area only
```

### `screen:name()`

Returns display name as reported by macOS:
- "Built-in Retina Display"
- "LG UltraFine"
- "Dell U2720Q"
- etc.

### `hs.screen.setDefaultCallback()`

Monitor for display configuration changes:

```lua
hs.screen.setDefaultCallback(function()
  -- Displays changed, recalculate scaling
end)
```

## Calculating Physical DPI

macOS doesn't expose physical DPI directly. You can approximate:

```lua
local function estimateDPI(screen)
  local mode = screen:currentMode()
  local frame = screen:fullFrame()

  -- Native resolution (before scaling)
  local nativeW = mode.w * (mode.scale or 1)
  local nativeH = mode.h * (mode.scale or 1)

  -- Approximate physical size based on known displays
  -- This requires a database of known display dimensions
  local knownDisplays = {
    ["Built-in Retina Display"] = { diagonal = 14.2 },  -- 14" MacBook Pro
    ["LG UltraFine 5K"] = { diagonal = 27 },
    ["LG UltraFine 4K"] = { diagonal = 23.7 },
  }

  local info = knownDisplays[screen:name()]
  if info then
    -- Calculate DPI from diagonal and resolution
    local diagonalPixels = math.sqrt(nativeW^2 + nativeH^2)
    local dpi = diagonalPixels / info.diagonal
    return dpi
  end

  return nil  -- Unknown display
end
```

**Problems with this approach:**
- Requires maintaining a display database
- Display names can vary by macOS version
- Doesn't handle generic USB-C displays

## Future Enhancement Ideas

### 1. User Preference Setting

```lua
-- In hs.settings
hud.scaleFactor.external = 1.5   -- User-configurable
hud.scaleFactor.builtin = 1.0
```

### 2. Resolution-Based Heuristics

```lua
local function getScaleHeuristic(screen)
  local mode = screen:currentMode()
  local nativeW = mode.w * (mode.scale or 1)

  -- Heuristics based on common resolutions
  if nativeW >= 5120 then return 2.0 end    -- 5K display
  if nativeW >= 3840 then return 1.5 end    -- 4K display
  if nativeW >= 2560 then return 1.25 end   -- QHD display
  return 1.0
end
```

### 3. Per-Display Configuration

```lua
-- Allow users to configure specific displays
local displayScales = {
  ["LG UltraFine 5K"] = 2.0,
  ["Dell U2720Q"] = 1.5,
}
```

## Recommendation

For v1, the simple 2-tier approach (laptop vs external) works well:
- Covers the 90% case
- No configuration needed
- Easy to understand

For v2+, consider adding user preference overrides in Hammerspoon config for
users who want finer control.

## References

- [Hammerspoon hs.screen docs](https://www.hammerspoon.org/docs/hs.screen.html)
- [macOS Retina Display](https://support.apple.com/en-us/HT202471)
- [Apple Human Interface Guidelines - Display](https://developer.apple.com/design/human-interface-guidelines/displays)
