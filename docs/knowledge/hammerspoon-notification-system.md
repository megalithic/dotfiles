# Hammerspoon Notification System - Deep Analysis

> **Last Updated:** 2025-12-11
> **Status:** ✅ WORKING - Fixed macOS Sequoia AX structure changes
> **macOS Version:** Sequoia (Darwin 24.6.0)

## Executive Summary

The notification watcher system is **fully functional** after fixing the macOS Sequoia compatibility issue.

### Recent Fix (2025-12-11)

**Problem:** macOS Sequoia changed the Notification Center AX structure. Notifications now arrive wrapped in an `AXSystemDialog` container instead of directly as `AXNotificationCenterBanner/Alert`.

**Solution:** Added `findNotificationElement()` function that recursively traverses the AX tree to find the actual notification element inside Sequoia's wrapper structure.

**Old Structure (Pre-Sequoia):**
```
AXWindow (AXNotificationCenterBanner)
  └─ AXStaticText (title)
  └─ AXStaticText (message)
```

**New Structure (Sequoia 15+):**
```
AXWindow (AXSystemDialog)  ← AX event fires here
  └─ AXGroup (AXHostingView)
      └─ AXGroup
          └─ AXScrollArea
              └─ AXGroup (AXNotificationCenterAlert)  ← actual data here
                  StackingID: bundleIdentifier=com.example.app
                  └─ AXStaticText (title)
                  └─ AXStaticText (message)
```

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    macOS Notification Center                      │
│  (com.apple.notificationcenterui - PID varies after restart)     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ AX Events (AXLayoutChanged, AXCreated)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              watchers/notification.lua                           │
│  - hs.axuielement.observer watching NC process                   │
│  - Filters for AXSubrole: AXNotificationCenterBanner/Alert       │
│  - Extracts: title, subtitle, message, stackingID, bundleID      │
│  - Matches against C.notifier.rules                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ N.process(rule, title, subtitle, message, stackingID, bundleID)
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              lib/notifications/processor.lua                     │
│  - Pattern matching for priority (high/normal/low)               │
│  - Focus mode checking (blocks if focus active + not allowed)    │
│  - Priority-based display logic                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  lib/notifier   │  │   lib/db        │  │  lib/menubar    │
│  Canvas display │  │  SQLite logging │  │  Status icon    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

---

## File Locations

| File | Purpose |
|------|---------|
| `config/hammerspoon/watchers/notification.lua` | Main AX observer and event handler |
| `config/hammerspoon/lib/notifications/init.lua` | System controller, public API |
| `config/hammerspoon/lib/notifications/processor.lua` | Rule matching and priority logic |
| `config/hammerspoon/lib/notifications/notifier.lua` | Canvas rendering, focus detection |
| `config/hammerspoon/lib/notifications/db.lua` | SQLite database operations |
| `config/hammerspoon/lib/notifications/menubar.lua` | Menubar indicator |
| `config/hammerspoon/config.lua` | Rules defined in `C.notifier.rules` |
| `~/.local/share/hammerspoon/hammerspoon.db` | SQLite database for logged notifications |

---

## How the AX Observer Works

### 1. Observer Setup (notification.lua:125-131)

```lua
M.observer = hs.axuielement.observer
  .new(ncPID)
  :callback(function(_, element) handleNotification(element) end)
  :addWatcher(notificationCenter, "AXLayoutChanged")
  :addWatcher(notificationCenter, "AXCreated")
  :start()
```

The observer watches two event types:
- **AXLayoutChanged**: Fires when NC's UI layout changes (notification appears/disappears)
- **AXCreated**: Fires when new AX elements are created (alternative trigger)

### 2. Event Filtering (notification.lua:33)

```lua
if not notificationSubroles[element.AXSubrole] or M.processedNotificationIDs[element.AXIdentifier] then return end
```

Only processes elements with:
- `AXSubrole` = `AXNotificationCenterBanner` OR `AXNotificationCenterAlert`
- `AXIdentifier` not already in processed cache

### 3. Data Extraction (notification.lua:38-56)

From the AX element:
- `AXStackingIdentifier` → bundleID (format: `bundleIdentifier=com.example.app,threadIdentifier=...`)
- Child `AXStaticText` elements → title, subtitle, message (2-3 text elements)

### 4. Rule Matching (notification.lua:59-91)

Iterates through `C.notifier.rules`, matching:
1. `stackingID:find(rule.appBundleID, 1, true)` - App bundle match
2. Optional `rule.senders` - Exact title match for specific senders

---

## Known Issues

### Issue 1: macOS Notification Permissions (CURRENT BLOCKER)

**Symptoms:**
- `hs.notify:delivered()` returns `false`
- `hs.notify:presented()` returns `false`
- No notification banners appear

**Root Cause:**
The `com.apple.ncprefs.plist` has `flags` with Bit 0 (Allow Notifications) = FALSE for Hammerspoon.

**Location:** `~/Library/Preferences/com.apple.ncprefs.plist`

**Flags Decoding:**
```
flags = 41951254 (binary: 10100000000010000000010110)
Bit 0 (Allow):  FALSE  ← Problem!
Bit 1 (Show NC): TRUE
Bit 2 (Lock):    TRUE
Bit 3 (Banner):  FALSE
Bit 4 (Alert):   TRUE
```

**Fix Attempt (Partially Successful):**
```python
import plistlib
plist_path = "~/Library/Preferences/com.apple.ncprefs.plist"
with open(plist_path, 'rb') as f:
    data = plistlib.load(f)
for app in data['apps']:
    if app['bundle-id'] == 'org.hammerspoon.Hammerspoon':
        app['flags'] = app['flags'] | 0b1001  # Enable Bit 0 and 3
with open(plist_path, 'wb') as f:
    plistlib.dump(data, f)
```

**Note:** Even after modifying flags and restarting NC daemon, `delivered: false` persists. May require:
- Full logout/login
- Manual toggle in System Settings → Notifications
- Possible SIP/TCC protection preventing programmatic changes

### Issue 2: macOS Sequoia AX Changes (✅ RESOLVED 2025-12-11)

**Symptoms:**
- AX observer receives events but notifications appear as `AXSystemDialog` instead of `AXNotificationCenterBanner`
- This was documented in commit `zpwrnqry` (4 weeks ago)

**Root Cause:**
macOS Sequoia changed Notification Center implementation:
1. Now uses SwiftUI instead of AppKit
2. Notifications wrapped in `AXSystemDialog` container
3. Actual `AXNotificationCenterAlert/Banner` is nested 4-5 levels deep

**Solution Implemented:**
Added `findNotificationElement()` function in `watchers/notification.lua` that:
1. Detects when incoming element is `AXSystemDialog`
2. Recursively traverses the AX tree (max depth 6)
3. Finds the nested `AXNotificationCenterAlert/Banner` element
4. Extracts `stackingID` and text content from the correct element

```lua
-- Key fix in notification.lua
local function findNotificationElement(element, depth)
  depth = depth or 0
  if depth > 6 then return nil end

  if notificationSubroles[element.AXSubrole] then
    return element
  end

  local children = element:attributeValue("AXChildren") or {}
  for _, child in ipairs(children) do
    local found = findNotificationElement(child, depth + 1)
    if found then return found end
  end
  return nil
end
```

---

## Database Schema

**Location:** `~/.local/share/hammerspoon/hammerspoon.db`

**Table: notifications**
```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER,
  rule_name TEXT,
  app_id TEXT,      -- Full stackingID
  sender TEXT,      -- Notification title
  subtitle TEXT,
  message TEXT,
  action_taken TEXT, -- shown_center_dimmed, shown_bottom_left, blocked_by_focus, etc.
  focus_mode TEXT,
  shown INTEGER     -- 0 or 1
);
```

---

## Configuration (config.lua)

### Rule Structure

```lua
C.notifier.rules = {
  {
    name = "Important Messages",
    appBundleID = "com.apple.MobileSMS",
    senders = { "Abby Messer", "Mom", ... },  -- Optional: filter by sender
    patterns = {
      high = { "urgent", "emergency" },
      normal = { ".*" },
      low = { "liked", "loved" },
    },
    allowedFocusModes = { nil, "Personal" },  -- nil = no focus mode
    alwaysShowInTerminal = true,
    showWhenAppFocused = false,
    duration = 10,
    appImageID = "com.apple.MobileSMS",  -- Icon for canvas notification
  },
}
```

### Notifier Config

```lua
-- All config keys are direct children of C.notifier (not nested under .config)
C.notifier = {
  rules = { ... },  -- App notification rules (see above)

  -- Positioning
  defaultDuration = 5,
  positionMode = "auto",  -- auto, fixed, above-prompt
  minOffset = 100,
  offsets = {
    default = 350,
    nvim = 400,
    claude = 450,
  },

  -- Animation
  animation = { enabled = true, duration = 0.3 },

  -- Colors
  colors = {
    dark = { background = {...}, title = {...}, ... },
    light = { background = {...}, title = {...}, ... },
  },

  -- Database
  retentionDays = 30,

  -- Agent notification settings (for N.send() API via ntfy CLI)
  agent = {
    durations = { normal = 5, high = 10, critical = 15 },
    questionRetry = { enabled = true, intervalSeconds = 300, maxRetries = 3, escalateOnRetry = true },
    pushover = { enabled = true },  -- Tokens from env: PUSHOVER_USER_TOKEN, PUSHOVER_APP_TOKEN
    phone = { enabled = true, cacheTTL = 604800 },  -- iMessage notifications
  },
}
```

---

## Health Check System

The notification system has a built-in health check (`lib/notifications/init.lua:90-146`):

1. Runs every 5 minutes
2. Checks:
   - System initialized flag
   - Database connection
   - Notification watcher observer exists
   - Menubar indicator present
3. Auto-reinitializes on failure

---

## Debugging Commands

### Check Watcher State
```lua
local w = require('watchers.notification')
print('Observer:', w.observer ~= nil)
print('PID:', w.currentPID)
print('Processed IDs:', (function() local c=0; for _ in pairs(w.processedNotificationIDs) do c=c+1 end; return c end)())
```

### Check NC Process
```lua
local nc = hs.application.find('com.apple.notificationcenterui')
print('NC PID:', nc and nc:pid())
```

### Test Notification Delivery
```lua
local n = hs.notify.new({title='Test', informativeText='Test', withdrawAfter=10})
n:send()
print('Delivered:', n:delivered())
print('Presented:', n:presented())
```

### Check Database
```bash
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT * FROM notifications ORDER BY timestamp DESC LIMIT 10"
```

### Check Notification Permissions
```bash
defaults read com.apple.ncprefs | grep -A 10 "org.hammerspoon"
```

---

## Recovery Procedures

### Notification Watcher Not Capturing

1. **Check NC PID match:**
   ```lua
   local nc = hs.application.find('com.apple.notificationcenterui')
   local w = require('watchers.notification')
   if nc:pid() ~= w.currentPID then
     w:stop(); w:start()
   end
   ```

2. **Restart NC daemon:**
   ```bash
   killall NotificationCenter usernoted
   ```

3. **Check notification permissions:**
   - System Settings → Notifications → Hammerspoon
   - Enable "Allow Notifications"
   - Set style to "Banners" or "Alerts"

### Database Issues

```bash
# Check database integrity
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "PRAGMA integrity_check"

# Vacuum database
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "VACUUM"
```

---

## Future Improvements

1. **Swift-based notification observer** - Bypass AX API limitations
2. **Hybrid approach** - Poll usernoted SQLite + AX events
3. **Notification permission automation** - Script to enable permissions via osascript/TCC manipulation
4. **macOS version detection** - Different strategies for Sequoia vs earlier

---

## Related Commits

| Change ID | Description |
|-----------|-------------|
| `zpwrnqry` | Root cause analysis - AXLayoutChanged broken on Sequoia |
| `mxukvtzp` | Smart truncation with remaining char count |
| `yzkuorqq` | Fix watchers, add pushover, optimize reload |
| `okyrptkt` | Original notification routing system with sqlite tracking |
