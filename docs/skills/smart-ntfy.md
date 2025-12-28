---
name: smart-ntfy
description: Send intelligent notifications via ~/bin/ntfy with context-aware channel selection. Use when completing tasks, asking questions, encountering errors, or reaching milestones.
tools: Bash
---

# Smart Notification System (ntfy)

## Overview

You have access to a sophisticated multi-channel notification system via `~/bin/ntfy`. This skill helps you make smart decisions about when and how to notify the user.

## Quick Reference

```bash
# Basic notification
ntfy send -t "Title" -m "Message"

# With urgency levels: normal|high|critical
ntfy send -t "Title" -m "Message" -u high

# Send to phone via Pushover (for remote notifications)
ntfy send -t "Title" -m "Message" -P

# Question that may need retry (tracks until answered)
ntfy send -t "Question" -m "Should I continue?" -q

# Mark a question as answered
ntfy answer -t "Question" -m "Should I continue?"

# List pending unanswered questions
ntfy pending
```

## Command Structure

```bash
ntfy <command> [options]

Commands:
  send      Send a notification
  answer    Mark a question as answered
  pending   List pending questions
  help      Show help message
```

## Options

| Short | Long         | Description                                 |
|-------|--------------|---------------------------------------------|
| `-t`  | `--title`    | Notification title (required)               |
| `-m`  | `--message`  | Notification message (required)             |
| `-u`  | `--urgency`  | normal\|high\|critical (default: normal)    |
| `-s`  | `--source`   | Source app name (auto-detected if omitted)  |
| `-S`  | `--no-source`| Disable source prefix in title              |
| `-p`  | `--phone`    | Send to phone via iMessage                  |
| `-P`  | `--pushover` | Send via Pushover                           |
| `-q`  | `--question` | Track for retry if unanswered               |

## Source Detection

By default, ntfy auto-detects the calling program by walking up the process tree
and prefixes the title (e.g., `[claude] Task Done`). This helps identify which
tool sent the notification.

```bash
# Auto-detection (default) - title becomes "[claude] Done" if called from Claude
ntfy send -t "Done" -m "Tests passed"

# Disable source prefix entirely
ntfy send -t "Done" -m "Tests passed" -S

# Override with custom source name
ntfy send -t "Done" -m "Tests passed" -s "myapp"  # → "[myapp] Done"
```

## Notification Channels

The ntfy script automatically routes based on user attention:

1. **Canvas Notification** - On-screen overlay (HAL 9000 icon)
   - Normal: Bottom-left, 5 seconds
   - High/Critical: Center screen with dimmed background

2. **macOS Notification Center** - Always sent for logging
   - Captured by Hammerspoon watcher
   - Logged to SQLite: `~/.local/share/hammerspoon/hammerspoon.db`

3. **Pushover** - Remote phone notification
   - Auto-sent on `critical` urgency
   - Or explicitly with `-P`

4. **iMessage** - Direct to user's phone
   - Auto-sent on `critical` urgency
   - Or explicitly with `-p`

## Urgency Guidelines

| Situation | Urgency | Why |
|-----------|---------|-----|
| Task completed successfully | `normal` | User will see canvas |
| Task completed with warnings | `high` | Draw more attention |
| Task failed/error | `critical` | Sends to phone too |
| Question needing answer | `high` | Centered, prominent |
| Security vulnerability found | `critical` | Always notify phone |
| Long task progress update | `normal` | Non-intrusive |

## When to Send Notifications

**DO send for:**
- Task completion (especially long-running)
- Errors requiring user attention
- Questions needing user input
- Significant milestones
- Security findings

**DON'T send for:**
- Minor steps completed
- Info user is actively watching
- Debugging output
- Redundant status updates

## Message Best Practices

1. **Titles:** Keep under 50 characters, be specific
2. **Messages:** Keep under 200 characters, include key details
3. **Include metrics:** "42 tests passed in 3.2s" not just "Tests passed"
4. **Be actionable:** "Check logs at /tmp/build.log" not just "Error occurred"

## Question Tracking

The `-q` flag marks a notification as a question that needs acknowledgment:

```bash
# Send a question
ntfy send -t "Confirm" -m "Deploy to production?" -u high -q

# Later, mark it as answered
ntfy answer -t "Confirm" -m "Deploy to production?"

# Or answer by ID (returned from send)
ntfy answer -i <question_id>

# Check pending questions
ntfy pending
```

## Attention Detection

The ntfy script automatically detects if you're paying attention:
- Checks if terminal app is frontmost
- Checks current tmux session/window
- Checks display state (asleep/locked)

If user IS paying attention → subtle NC notification only
If user NOT paying attention → canvas overlay + NC + optional remote

## Examples

```bash
# Task completed
ntfy send -t "Build Complete" -m "42 tests passed, 0 failures in 3.2s"

# Error with high urgency
ntfy send -t "Build Failed" -m "3 type errors in src/auth.ts:45,78,123" -u high

# Critical security finding (auto-sends to phone)
ntfy send -t "Security Alert" -m "Found hardcoded API key in config.js" -u critical

# Question for user
ntfy send -t "Clarification Needed" -m "Should I refactor the auth module or just fix the bug?" -u high -q

# Send to phone when away
ntfy send -t "Task Done" -m "Deployment completed successfully" -p
```

## Internal Architecture

The ntfy script delegates all logic to Hammerspoon's notification system:

```
ntfy send → N.send(opts) → routeNotification() → sendCanvas/sendMacOS/sendPhone
                                                      ↓
                                              sendCanvasNotification()
```

### Key Function Signatures

**N.send()** - Main entry point (lib/notifications/send.lua)
```lua
N.send({
  title = "string",      -- Required
  message = "string",    -- Required
  urgency = "normal",    -- "normal"|"high"|"critical"
  phone = false,         -- Send via iMessage
  pushover = false,      -- Send via Pushover
  question = false,      -- Track for retry
  context = "session:window:pane",  -- tmux context for attention detection
})
-- Returns: { sent = bool, channels = {"macos","phone"}, reason = string, questionId = string|nil }
```

**sendCanvasNotification()** - Visual overlay (lib/notifications/notifier.lua)
```lua
sendCanvasNotification(title, message, opts)
-- opts: { subtitle?, duration?, anchor?, position?, dimBackground?, appImageID?, appBundleID?, includeProgram?, ... }
-- Uses U.defaults() for merging - subtitle defaults to "", duration to config.defaultDuration or 5
```

**M.process()** - Rule-based routing (lib/notifications/processor.lua)
```lua
M.process(rule, opts)
-- opts: { title, subtitle?, message, axStackingID, bundleID, notificationID?, notificationType?, subrole?, matchedCriteria?, urgency? }
-- Uses U.defaults() for merging - title/subtitle/message default to "", urgency to "normal"
```

### Attention Detection Flow

1. Check display state (awake/asleep/locked)
2. Check if terminal is frontmost app
3. Query tmux for active session:window:pane
4. Compare against calling context
5. Route: `paying_attention` → subtle | `not_paying_attention` → full | `display_asleep` → remote_only

## Related Files

- `~/bin/ntfy` - CLI wrapper (bash)
- `~/.dotfiles/config/hammerspoon/lib/notifications/send.lua` - N.send() API
- `~/.dotfiles/config/hammerspoon/lib/notifications/notifier.lua` - Canvas rendering
- `~/.dotfiles/config/hammerspoon/lib/notifications/processor.lua` - Rule processing
- `~/.dotfiles/config/hammerspoon/watchers/notification.lua` - NC capture
- `~/.local/share/hammerspoon/hammerspoon.db` - Notification history

## Troubleshooting

If notifications aren't appearing:
1. Check Hammerspoon is running: `pgrep Hammerspoon`
2. Check hs CLI works: `hs -c "print('hello')"`
3. Verify permissions: System Settings → Notifications → Hammerspoon
