# Hammerspoon Notification System - Deep Analysis

> **Last Updated:** 2025-12-19 16:20 EST
> **Status:** ✅ ACTIVE - Level 2 rules engine with unified action system
> **macOS Version:** Sequoia (Darwin 24.6.0)

## Executive Summary

The notification system has been completely refactored with a **unified action architecture**:

- **ONE watcher** (`watchers/notification.lua`) handles ALL notifications (transient + persistent)
- **THREE actions** (`redirect`, `dismiss`, `ignore`) provide flexible routing
- **Level 2 matching** with AND/OR logic for powerful rule expressions
- **Enhanced tracking** with match criteria, notification types, and subroles logged to database

### Recent Major Changes (2025-12-19)

1. **Removed persistent-notification scanner** - No more separate polling watcher
2. **Implemented dismiss action** - Finds and clicks close button via AX API (doesn't open System Settings)
3. **New match syntax** - Field-based matching with array support for OR logic
4. **Database schema enhanced** - `action` + `action_detail` instead of `action_taken`
5. **Match criteria tracking** - Logs what matched for analytics

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
| `config/hammerspoon/watchers/notification.lua` | **Main AX observer, rule matching, and action dispatch** |
| `config/hammerspoon/lib/notifications/init.lua` | System controller, public API |
| `config/hammerspoon/lib/notifications/processor.lua` | Priority logic and canvas notification rendering (redirect action) |
| `config/hammerspoon/lib/notifications/notifier.lua` | Canvas rendering, focus detection |
| `config/hammerspoon/lib/notifications/db.lua` | SQLite database operations |
| `config/hammerspoon/lib/db.lua` | **Unified database with notification queries** |
| `config/hammerspoon/lib/notifications/menubar.lua` | Menubar indicator for blocked notifications |
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

### Schema Migration (2025-12-19)

The notification table schema was migrated to support enhanced features:
- Old table renamed to `legacy_notifications` (preserved for reference)
- New clean schema with additional tracking fields
- Backward compatible log function during transition

**Table: notifications (CURRENT SCHEMA as of 2025-12-19)**
```sql
CREATE TABLE notifications (
  -- Core identification
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER NOT NULL,
  notification_id TEXT,              -- AX element UUID or generated UUID
  
  -- Content
  title TEXT,
  subtitle TEXT,
  message TEXT NOT NULL,
  sender TEXT NOT NULL,
  
  -- Source
  app_id TEXT NOT NULL,              -- AX stackingID (bundleIdentifier=...) or bundleID
  app_name TEXT,                     -- Human-readable app name (future use)
  notification_type TEXT,            -- "app" | "system" | "unknown"
  subrole TEXT,                      -- "AXNotificationCenterBanner" | "AXNotificationCenterAlert"
  
  -- Rule matching
  rule_name TEXT NOT NULL,
  match_criteria TEXT,               -- JSON of matched criteria (e.g. {"bundleID":"com.app","title":"Test"})
  
  -- Action/routing
  action TEXT NOT NULL,              -- "redirect" | "dismiss" | "ignore" | "blocked"
  action_detail TEXT,                -- "shown_center_dimmed" | "shown_bottom_left" | "dismissed_via_close_button" | "dismiss_failed" | "blocked_by_focus" | etc.
  priority TEXT,                     -- "low" | "normal" | "high" (from pattern matching)
  
  -- State tracking
  shown INTEGER NOT NULL DEFAULT 1,  -- 0 = not shown (blocked/dismissed/ignored), 1 = shown (redirected to canvas)
  first_seen INTEGER,                -- When first detected (future use for time-based rules)
  dismissed_at INTEGER,              -- When dismissed/cleared from menubar
  dismiss_method TEXT,               -- "auto" | "manual" | NULL (future use)
  focus_mode TEXT                    -- Current focus mode when notification arrived
);
```

**Action Values:**
- `redirect` - Shown via canvas notification (default)
- `dismiss` - Dismissed via AX close button
- `ignore` - Silent drop (rule matched but not logged in current implementation)
- `blocked` - Blocked by focus mode or priority checks

**Action Detail Values:**
- `shown_center_dimmed` - High priority, center screen with dimmed background
- `shown_bottom_left` - Normal/low priority, bottom-left corner
- `dismissed_via_close_button` - Successfully found and clicked close button
- `dismiss_failed` - No close button found (notification disappeared too quickly or structure unexpected)
- `blocked_by_focus` - Blocked by active focus mode (not in overrideFocusModes list)
- `blocked_app_already_focused` - High priority but source app already focused
- `blocked_in_terminal` - High priority but terminal focused and not allowed

**Table: legacy_notifications (OLD DATA)**
Contains historical notifications from before 2025-12-19 schema migration. Uses old column names (`action_taken` instead of `action` + `action_detail`).

---

## Configuration (config.lua)

### Rule Structure

The system supports **two rule syntaxes** for backward compatibility:

#### New Syntax (Level 2 - Recommended)

Uses the `match` field for flexible field matching with AND/OR logic:

```lua
C.notifier.rules = {
  {
    name = "GitHub Notifications",
    match = {
      bundleID = { "com.brave.Browser.nightly", "org.mozilla.firefox" },  -- OR within array
      message = "GitHub.*",  -- Lua pattern matching
    },
    action = "dismiss",  -- or "redirect" (default), "ignore"
    duration = 5,
    overrideFocusModes = true,
  },
}
```

**Match Fields:**
- `bundleID` - App bundle identifier
- `title` - Notification title
- `subtitle` - Notification subtitle  
- `message` - Notification body
- `sender` - Sender name (alias for title)
- `notificationType` - "system" or "app"
- `subrole` - AX subrole ("AXNotificationCenterBanner" or "AXNotificationCenterAlert")

**Match Logic:**
- Multiple fields = **AND** (all must match)
- Array values = **OR** (any must match)
- String values = Lua pattern matching

**Actions:**
- `redirect` - Show via canvas notification (default, old behavior)
- `dismiss` - Log to database but don't show
- `ignore` - Silent drop (no logging, no display)

#### Old Syntax (Level 1 - Backward Compatible)

Uses `appBundleID` and `senders` fields:

```lua
C.notifier.rules = {
  {
    name = "Important Messages",
    appBundleID = "com.apple.MobileSMS",
    senders = { "Abby Messer", "Mom" },  -- Optional: exact title match
    patterns = {
      high = { "urgent", "emergency" },
      normal = { ".*" },
      low = { "liked", "loved" },
    },
    alwaysShowInTerminal = true,
    showWhenAppFocused = false,
    overrideFocusModes = { "Personal", "Work" },  -- or true for all
    duration = 10,
    appImageID = "com.apple.MobileSMS",
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

### Rule Matching and Action Dispatch

The complete rule matching and action dispatch is implemented in `watchers/notification.lua`:

#### Rule Matching

**Level 1 (Old-Style):** `matchesOldRule(notifData, rule)`
- Checks `appBundleID` field (substring match)
- Optional `senders` array (exact title match)
- Backward compatible with existing rules

**Level 2 (New-Style):** `matchesNewRule(notifData, matchCriteria)`  
- Supports `match` table with arbitrary fields
- Each field can be: string (Lua pattern), array (OR logic)
- `matchField(value, pattern)` handles both cases
- Multiple fields combined with AND logic

**Match Criteria Logging:**
- Matched criteria serialized to JSON via `hs.json.encode()`
- Stored in `notifications.match_criteria` column
- Enables analytics: "What patterns are actually matching?"
- Example: `{"bundleID":"org.hammerspoon.Hammerspoon","title":"hammerspork"}`

#### Action Dispatch (Option 2 Architecture)

Once a rule matches in `handleNotification()`, action is dispatched inline:

```lua
if matched then
  local action = rule.action or "redirect"
  
  if action == "dismiss" then
    -- Find close button and click it
    local success = dismissNotification(notificationElement, title)
    -- Log to database
    
  elseif action == "ignore" then
    -- Silent drop (no logging, no display)
    
  else -- "redirect"
    -- Delegate to processor.lua for canvas display
    N.process(rule, title, subtitle, message, ...)
  end
end
```

**Key Architectural Decision:** Dismiss action handled in watcher (not processor) because:
- Element reference naturally in scope
- No function signature changes needed across multiple files
- Clean separation: watcher for dismiss, processor for redirect
- Lower risk of breaking existing redirect flow

#### Dismiss Implementation

`dismissNotification(notificationElement, title)` in `watchers/notification.lua`:

1. **Recursively searches for close button** (max depth 8)
2. **Identifies AXButton** with "close" in AXDescription or AXTitle
3. **Clicks the button** via `closeButton:performAction("AXPress")`
4. **NOT the notification element** - that would trigger default action (open System Settings)

```lua
local function dismissNotification(notificationElement, title)
  local function findCloseButton(element, depth)
    if depth > 8 then return nil end
    
    if element.AXRole == "AXButton" then
      local desc = (element.AXDescription or ""):lower()
      local btnTitle = (element.AXTitle or ""):lower()
      if desc:match("close") or btnTitle:match("close") then
        return element
      end
    end
    
    -- Recurse into children...
  end
  
  local closeButton = findCloseButton(notificationElement)
  if closeButton then
    closeButton:performAction("AXPress")  -- Click BUTTON, not notification
    return true
  end
  return false
end
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

-- Check rule counts
local rules = C.notifier.rules
local newStyleCount, oldStyleCount = 0, 0
for _, rule in ipairs(rules) do
  if rule.match then newStyleCount = newStyleCount + 1
  elseif rule.appBundleID then oldStyleCount = oldStyleCount + 1 end
end
print(string.format('Rules: %d new-style, %d old-style, %d total', newStyleCount, oldStyleCount, #rules))
```

### Check NC Process
```lua
local nc = hs.application.find('com.apple.notificationcenterui')
print('NC PID:', nc and nc:pid())
```

### Test Actions
```lua
-- Test redirect (canvas notification)
hs.notify.new({title='Test Redirect', informativeText='Should show via canvas', withdrawAfter=5}):send()

-- Test dismiss (auto-click close button) - needs matching rule with action="dismiss"
hs.notify.new({title='Test Dismiss', informativeText='Should auto-dismiss', withdrawAfter=0}):send()
```

### Check Database
```bash
# Check recent notifications with actions
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT id, timestamp, title, action, action_detail, notification_type FROM notifications ORDER BY timestamp DESC LIMIT 10"

# Check match criteria (JSON serialized)
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT rule_name, match_criteria FROM notifications WHERE match_criteria IS NOT NULL ORDER BY timestamp DESC LIMIT 5"

# Count by action type
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT action, COUNT(*) as count FROM notifications GROUP BY action ORDER BY count DESC"

# Check dismiss success/failure rate
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT action_detail, COUNT(*) FROM notifications WHERE action = 'dismiss' GROUP BY action_detail"

# Verify Hammerspoon reload succeeded
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT timestamp FROM notifications WHERE sender = 'hammerspork' AND message = 'config is loaded.' ORDER BY timestamp DESC LIMIT 1"

# Check legacy data still accessible
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db "SELECT COUNT(*) FROM legacy_notifications"
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

---

## Verification & Testing

### Verify Hammerspoon Loaded Successfully

After `hs.reload()`, check the database for the load notification:

```bash
# Should return a recent timestamp (within last few seconds)
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT timestamp, sender, message FROM notifications 
   WHERE sender = 'hammerspoon' AND message = 'config is loaded.' 
   ORDER BY timestamp DESC LIMIT 1"
```

If empty, Hammerspoon may have failed to reload or the notification system didn't initialize.

### Send Test Notification

```bash
# Via ntfy (recommended - goes through full notification pipeline)
~/bin/ntfy send -t "Test" -m "Schema validation test" -u normal

# Check it was captured (should appear within 2 seconds)
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT id, title, message, action FROM notifications 
   ORDER BY timestamp DESC LIMIT 1"
```

### Verify Schema Migration

```bash
# Both tables should exist
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db ".tables"
# Should show: notifications, legacy_notifications, connection_events, user_cache, ft_notifications*

# Legacy data preserved
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  "SELECT COUNT(*) as legacy_count FROM legacy_notifications"

# New schema has enhanced fields
sqlite3 ~/.local/share/hammerspoon/hammerspoon.db \
  ".schema notifications" | grep notification_id
# Should show: notification_id TEXT, notification_type TEXT, etc.
```

---


---

## Implementation Status (2025-12-19)

### ✅ Completed

- [x] Level 2 rules engine with match syntax
- [x] Three action types (redirect, dismiss, ignore)
- [x] Dismiss action via AX close button (doesn't open System Settings)
- [x] Match criteria tracking to database
- [x] Database schema migration (action_taken → action + action_detail)
- [x] Backward compatibility with old appBundleID rules
- [x] Unified architecture (removed persistent-notification watcher)
- [x] Enhanced fields logging (notification_id, notification_type, subrole)
- [x] Documentation updated

### 🧪 Testing Needed

- [ ] Dismiss action with real persistent system notifications (Login Items, Background Items, etc.)
- [ ] Verify close button found on various notification types
- [ ] Test with notifications that have action buttons (Reply, Snooze, etc.)
- [ ] Edge cases: notifications with custom layouts, grouped notifications

### 🚀 Future Enhancements

- [ ] Add `snooze` action (dismiss for N minutes, then re-show)
- [ ] Add `reply` action (for iMessage, Mail, etc.)
- [ ] Time-based rules (dismiss after X seconds via `first_seen` field)
- [ ] Whitelist for persistent notifications that should never auto-dismiss
- [ ] Custom dismiss timeouts per rule
- [ ] Analytics dashboard (most dismissed apps, busiest times, etc.)
- [ ] Export blocked notifications to external system
- [ ] Machine learning for automatic rule suggestions

### Known Limitations

1. **Dismiss may fail for quick-disappearing notifications** - If notification auto-withdraws before we find close button, logs `dismiss_failed`
2. **No swipe gesture support** - Only clicks close button, doesn't simulate swipe to dismiss
3. **System notifications structure varies** - Some may have different AX hierarchy requiring close button search adjustment
4. **No undo for dismissed notifications** - Once dismissed via AX API, gone from NC (though logged in database)

---

## Migration Notes

### From Old Schema to New Schema

The 2025-12-19 refactor changed:

**Column Renames:**
- `action_taken` → `action` (primary action type)
- Added `action_detail` (specific implementation detail)

**New Columns:**
- `notification_id` - UUID for tracking
- `notification_type` - "app" | "system" | "unknown"
- `subrole` - AX subrole for analytics
- `match_criteria` - JSON of matched rule criteria

**Code Changes Required:**
- All queries using `action_taken` must update to `action` and `action_detail`
- Menubar queries updated in `lib/db.lua`
- Display functions updated to show both action and detail

**Data Migration:**
- Old notifications table renamed to `legacy_notifications`
- New notifications table created with enhanced schema
- Both tables coexist for historical reference

### From Persistent-Notification Watcher to Unified System

**Old Architecture:**
```
watchers/notification.lua    → intercepts transient banners
watchers/persistent-notification.lua → polls NC drawer every 10s
```

**New Architecture:**
```
watchers/notification.lua → intercepts ALL notifications + dispatches actions
```

**Benefits:**
- Reduced complexity (one watcher vs two)
- Consistent rule syntax for both transient and persistent
- No polling overhead
- Dismiss happens immediately on notification arrival

---
