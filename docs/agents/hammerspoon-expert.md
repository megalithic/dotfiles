# Hammerspoon Expert Agent

> **Agent Type:** `hammerspoon-expert`
> **Purpose:** Deep expertise in Hammerspoon configuration, macOS automation, and debugging
> **Knowledge Base:** `docs/knowledge/hammerspoon-*.md`

## Agent Description

Use this agent when working with:
- Hammerspoon configuration files (`config/hammerspoon/`)
- macOS Accessibility (AX) APIs
- Notification system debugging
- Window management and layouts
- System automation via Hammerspoon

## Capabilities

### Primary Expertise
1. **Hammerspoon APIs** - Complete understanding of hs.* modules
2. **AX (Accessibility) Framework** - hs.axuielement, observers, element traversal
3. **macOS Integration** - Notification Center, Window Server, System Events
4. **Lua/LuaJIT** - Hammerspoon's runtime environment
5. **Configuration Architecture** - This repo's specific Hammerspoon setup

### Configuration Knowledge

This agent understands the specific architecture of `@megalithic/dotfiles-nix`:

```
config/hammerspoon/
├── init.lua           # Entry point, loads modules in order
├── preflight.lua      # Early setup (IPC, globals, logging)
├── config.lua         # C.* configuration table (displays, apps, notifier rules)
├── lib/               # Reusable modules
│   ├── notifications/ # Notification system (init, processor, notifier, db, menubar)
│   ├── db.lua         # SQLite database wrapper
│   └── ...
├── watchers/          # Event observers
│   ├── notification.lua  # AX observer for Notification Center
│   ├── network.lua
│   ├── wifi.lua
│   └── ...
└── Spoons/            # Third-party Hammerspoon plugins
```

### Key Configuration Patterns

1. **Global References:**
   - `C` = Config table (from `config.lua`)
   - `U` = Utilities (logging: `U.log.i()`, `U.log.e()`)
   - `N` = Notification system (`lib/notifications/init.lua`)
   - `TERMINAL` = Terminal bundle ID (Ghostty)

2. **Watcher Pattern:**
   ```lua
   local M = {}
   M.observer = nil
   function M:start() ... end
   function M:stop() ... end
   return M
   ```

3. **Database Path:** `~/.local/share/hammerspoon/hammerspoon.db`

## When to Use This Agent

### Good Use Cases
- "Why isn't the notification watcher capturing events?"
- "How do I add a new window layout?"
- "Debug this AX observer callback"
- "Explain how focus mode detection works"
- "Add a new notification rule"

### Not Ideal For
- General Lua questions (use standard references)
- Non-Hammerspoon macOS automation (use osascript/Shortcuts)
- Performance profiling (limited Hammerspoon tools)

## Debugging Workflows

### Notification System Debug

```lua
-- 1. Check watcher state
local w = require('watchers.notification')
print('Observer:', w.observer ~= nil)
print('PID:', w.currentPID)

-- 2. Check NC process
local nc = hs.application.find('com.apple.notificationcenterui')
print('NC PID:', nc:pid())

-- 3. Test notification delivery
local n = hs.notify.new({title='Test', informativeText='Test'})
n:send()
print('Delivered:', n:delivered())

-- 4. Check permissions
-- System Settings → Notifications → Hammerspoon
```

### AX Tree Inspection

```lua
local function inspectAX(element, depth)
  depth = depth or 0
  if depth > 3 then return end

  print(string.rep('  ', depth) ..
        'Role:', element.AXRole,
        'Subrole:', element.AXSubrole)

  for _, child in ipairs(element:attributeValue('AXChildren') or {}) do
    inspectAX(child, depth + 1)
  end
end

local nc = hs.application.find('com.apple.notificationcenterui')
inspectAX(hs.axuielement.applicationElement(nc))
```

## Known Issues & Solutions

### Issue: Notifications Not Captured

**Symptoms:** Database shows no new entries, `hs.notify:delivered()` = false

**Diagnosis:**
1. Check `defaults read com.apple.ncprefs | grep -A 5 "org.hammerspoon"`
2. Look for `flags` value - Bit 0 must be TRUE (odd number)

**Solution:**
```python
# Modify notification permissions (may require logout/login)
import plistlib
with open('~/Library/Preferences/com.apple.ncprefs.plist', 'rb') as f:
    data = plistlib.load(f)
for app in data['apps']:
    if app['bundle-id'] == 'org.hammerspoon.Hammerspoon':
        app['flags'] |= 0b1001  # Enable Allow + Banners
```

### Issue: AX Observer Not Receiving Events

**Symptoms:** Observer running but callback never fires

**Diagnosis:**
1. Check if NC PID changed: `pgrep NotificationCenter`
2. Verify observer PID matches

**Solution:**
```lua
local w = require('watchers.notification')
w:stop()
w:start()
```

### Issue: macOS Sequoia AX Changes

**Symptoms:** AX events fire but `AXSubrole` is not `AXNotificationCenterBanner`

**Root Cause:** Sequoia changed NC implementation to SwiftUI

**Workaround:** Consider Swift CLI approach or SQLite polling

## References

- **Knowledge Base:** `docs/knowledge/hammerspoon-notification-system.md`
- **Hammerspoon Docs:** https://www.hammerspoon.org/docs/
- **AX API Reference:** Apple Accessibility Programming Guide
- **Related Commit:** `zpwrnqry` - AXLayoutChanged Sequoia analysis
