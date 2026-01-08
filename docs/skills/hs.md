---
name: hs
description: Quick reference for Hammerspoon development in this dotfiles repo. Use for config patterns, reload commands, debugging tips, and macOS API guidance.
tools: Bash, Read, Edit
---

# Hammerspoon Quick Reference

## Configuration Location

```
config/hammerspoon/
├── init.lua        # Entry point - loads modules in order
├── preflight.lua   # Early setup (IPC, globals, logging)
├── overrides.lua   # Monkey-patches for hs.* modules
├── config.lua      # C.* configuration table (THE SOURCE OF TRUTH)
├── lib/            # Reusable modules
│   ├── notifications/  # Notification system
│   └── interop/        # External app integration (shade, nvim, browser)
└── watchers/       # Event observers
```

**ALWAYS check `config.lua` first** for:
- Display names: `C.displays.internal`, `C.displays.external`
- App bundle IDs: `C.launchers`, `C.layouts`
- Paths: `C.paths`
- Notification settings
- Any hardcoded values - prefer config over hardcoding

## Global References

| Global | Purpose | Source |
|--------|---------|--------|
| `C` | Config table | `config.lua` |
| `U` | Utilities (`U.log.i()`, `U.log.e()`) | `lib/utils.lua` |
| `N` | Notification system | `lib/notifications/init.lua` |
| `TERMINAL` | Terminal bundle ID | Ghostty |

## Reloading Hammerspoon

**CRITICAL**: Use this exact pattern to avoid hangs:

```bash
RELOAD_TIME=$(date +%s)
timeout 2 hs -c "hs.reload()" 2>&1 || true
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT timestamp FROM notifications WHERE sender = 'hammerspork' AND message = 'config is loaded.' AND timestamp >= $RELOAD_TIME LIMIT 1" \
  && echo "Reloaded"
```

**Why timeout?** `hs.reload()` destroys the Lua interpreter, causing the CLI to hang. The timeout is expected - reload succeeds even though command times out.

**Database path**: `~/.local/share/hammerspoon/hammerspoon.db`

## Before Making Changes

1. **Check for diagnostics** - Verify NO workspace or document errors before reloading
2. **Research APIs** - Never assume hs.* syntax; check https://www.hammerspoon.org/docs/
3. **Performance matters** - CPU/memory efficiency is critical; laggy = crash risk

## Module Pattern

```lua
local M = {}

M.observer = nil

function M:start()
  -- Initialize
end

function M:stop()
  -- Cleanup
end

return M
```

## Common APIs

### Window Management
```lua
local win = hs.window.focusedWindow()
win:frame()           -- Get frame
win:setFrame(frame)   -- Set frame
win:application()     -- Get owning app
```

### Application
```lua
hs.application.find("com.bundle.id")
hs.application.frontmostApplication()
app:mainWindow()
app:allWindows()
```

### Accessibility (AX)
```lua
local ax = hs.axuielement
local element = ax.applicationElement(app)
element:attributeValue("AXChildren")
element:attributeValue("AXRole")
```

### Notifications
```lua
hs.notify.new({
  title = "Title",
  informativeText = "Body"
}):send()
```

### Distributed Notifications (IPC)
```lua
-- Post to external apps
hs.distributednotifications.post("io.shade.toggle", nil, nil)

-- Listen from external apps
hs.distributednotifications.new(callback, "notification.name"):start()
```

## Debugging

### Console
```lua
-- In Hammerspoon console or via hs CLI:
hs -c "print(hs.inspect(C.displays))"
hs -c "U.log.i('test')"
```

### Check Running State
```lua
local w = require('watchers.notification')
print('Observer:', w.observer ~= nil)
print('Running:', w.running)
```

### AX Tree Inspection
```lua
local function inspectAX(el, depth)
  depth = depth or 0
  if depth > 3 then return end
  print(string.rep('  ', depth) .. 'Role:', el.AXRole)
  for _, child in ipairs(el:attributeValue('AXChildren') or {}) do
    inspectAX(child, depth + 1)
  end
end
```

## Related Resources

- **Hammerspoon Expert Agent**: Spawn for deep debugging/exploration tasks
- **Shade Skill**: For Shade.app integration (uses `lib/interop/shade.lua`)
- **Hammerspoon Docs**: https://www.hammerspoon.org/docs/
