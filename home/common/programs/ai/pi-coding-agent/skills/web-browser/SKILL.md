---
name: web-browser
description: "Interact with web pages using agent-browser CLI. Connects to existing browser on port 9222 for authenticated sessions."
---

# Web Browser Skill

Browser automation using `agent-browser` CLI connected to your running browser.

## ⚠️ CRITICAL REQUIREMENTS

### 1. ALWAYS connect to port 9222 FIRST

Before ANY browser operation, you MUST connect to the remote debugging port:

```bash
browser connect 9222
```

This is REQUIRED for accessing authenticated sessions (Asana, Figma, GitHub, etc.). Without this step, commands will fail or create isolated sessions without your logins.

### 2. NEVER take over existing tabs

When navigating to a URL:
- First check if tab already exists: `browser tab list`
- If found, switch to it: `browser tab <index>`
- If NOT found, open a NEW tab: `browser open <url>`

**NEVER navigate an existing tab to a different URL** - this destroys the user's work/context.

## Correct workflow

```bash
# 1. ALWAYS connect first (required every session)
browser connect 9222

# 2. Check for existing tab
browser tab list

# 3a. If tab exists for your URL, switch to it
browser tab 14

# 3b. If tab doesn't exist, open NEW tab
browser open https://app.asana.com/...

# 4. Interact
browser snapshot -i
browser click @e5
```

## Check if browser is listening

```bash
lsof -i :9222 -sTCP:LISTEN
```

## Common commands

After connecting, use standard agent-browser commands:

### Navigation & tabs
```bash
browser tab list                    # List all tabs
browser tab 14                      # Switch to tab by index
browser open https://example.com    # Open URL (NEW tab)
browser back                        # Go back
browser reload                      # Reload page
```

### Inspection
```bash
browser snapshot -i                 # Get interactive elements with @refs
browser screenshot                  # Take screenshot
browser get title                   # Get page title
browser get url                     # Get current URL
browser get text @e1                # Get text of element
```

### Interaction
```bash
browser click @e1                   # Click element
browser fill @e2 "search text"      # Clear and type
browser type @e3 "append text"      # Type without clearing
browser select @e4 "option"         # Select dropdown
browser press Enter                 # Press key
browser scroll down 500             # Scroll
```

### Waiting
```bash
browser wait @e1                    # Wait for element
browser wait 2000                   # Wait milliseconds
```

## Tab targeting by URL

Instead of remembering tab numbers, find tabs by URL:

```bash
browser tab list | rg -i asana
browser tab list | rg -i localhost:4000
```

## Notes

- Tabs are numbered by CDP, not visual order in browser
- `snapshot -i` gives @refs like @e1, @e2 for clicking
- After page changes (navigation, clicks), re-run `snapshot -i`
- Your browser must be running with `--remote-debugging-port=9222`
