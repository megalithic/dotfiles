---
name: web-browser
description: "Interact with web pages using agent-browser CLI. Connects to existing browser on port 9222 for authenticated sessions."
---

# Web Browser Skill

Browser automation using `agent-browser` CLI connected to your running browser.

## IMPORTANT: Always connect first

Your Brave Browser Nightly runs with `--remote-debugging-port=9222`. This gives agent-browser access to your logged-in sessions (Asana, GitHub, etc.).

**Always run this first in each session:**

```bash
agent-browser connect 9222
```

Or use the `browser` tool:
```
browser connect 9222
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
browser open https://example.com    # Open URL (new tab)
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

## Workflow example

```bash
# 1. Connect to your logged-in browser
browser connect 9222

# 2. Find and switch to Asana tab
browser tab list | grep -i asana
browser tab 14

# 3. Interact with authenticated page
browser snapshot -i
browser click @e5
```

## Tab targeting by URL

Instead of remembering tab numbers, find tabs by URL:

```bash
browser tab list | grep -i github
browser tab list | grep -i localhost:4000
```

## Notes

- Tabs are numbered by CDP, not visual order in browser
- `snapshot -i` gives @refs like @e1, @e2 for clicking
- After page changes (navigation, clicks), re-run `snapshot -i`
- Your browser must be running with `--remote-debugging-port=9222`
