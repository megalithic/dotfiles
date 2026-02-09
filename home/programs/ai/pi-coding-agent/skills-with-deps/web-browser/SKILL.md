---
name: web-browser
description: "Allows to interact with web pages by performing actions such as clicking buttons, filling out forms, and navigating links. It works by remote controlling Chromium-based browsers using the Chrome DevTools Protocol (CDP). When Claude needs to browse the web, it can use this skill to do so."
license: Stolen from Mario
---

# Web Browser Skill

Minimal CDP tools for collaborative site exploration.

## Browser detection

The skill auto-detects which browser to use:

1. **Port 9222 already listening** → Use existing browser (no restart needed)
2. **Hammerspoon BROWSER** → Use configured browser from HS config
3. **Fallback** → Google Chrome

Check if a browser is listening:
```bash
lsof -i :9222 -sTCP:LISTEN
```

## Start browser (if needed)

```bash
./scripts/start.js              # Auto-detect or start browser
./scripts/start.js --profile    # Copy your browser profile (cookies, logins)
```

**Note:** If your main browser is already running with `--remote-debugging-port=9222`, the script detects and uses it automatically.

## Tab targeting

All scripts support targeting specific tabs:

```bash
# Use cached target from last nav.js call (default)
./scripts/screenshot.js

# Explicit target by ID
./scripts/screenshot.js --target ABC123

# Find tab by URL substring
./scripts/screenshot.js --url-match github
```

**How it works:**
1. `nav.js` saves the targetId to `~/.cache/agent-web/current-target`
2. Other scripts read this cache by default
3. Use `--target` or `--url-match` to override

## Navigate

```bash
./scripts/nav.js https://example.com
./scripts/nav.js https://example.com --new
./scripts/nav.js https://example.com --url-match github  # Navigate existing tab
```

Opens new tab by default (safe). Only reuses existing tabs with explicit targeting.

## Evaluate JavaScript

```bash
./scripts/eval.js 'document.title'
./scripts/eval.js 'document.querySelectorAll("a").length'
./scripts/eval.js 'JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => ({ text: a.textContent.trim(), href: a.href })).filter(link => !link.href.startsWith("https://")))'
```

Execute JavaScript in active tab (async context). Be careful with string escaping, best to use single quotes.

## Screenshot

```bash
./scripts/screenshot.js
```

Screenshot current viewport, returns temp file path

## Pick Elements

```bash
./scripts/pick.js "Click the submit button"
```

Interactive element picker. Click to select, Cmd/Ctrl+Click for multi-select, Enter to finish.

## Dismiss Cookie Dialogs

```bash
./scripts/dismiss-cookies.js          # Accept cookies
./scripts/dismiss-cookies.js --reject # Reject cookies (where possible)
```

Automatically dismisses EU cookie consent dialogs.

Run after navigating to a page:
```bash
./scripts/nav.js https://example.com && ./scripts/dismiss-cookies.js
```

## Background Logging (Console + Errors + Network)

Automatically started by `start.js` and writes JSONL logs to:

```
~/.cache/agent-web/logs/YYYY-MM-DD/<targetId>.jsonl
```

Manually start:
```bash
./scripts/watch.js
```

Tail latest log:
```bash
./scripts/logs-tail.js           # dump current log and exit
./scripts/logs-tail.js --follow  # keep following
```

Summarize network responses:
```bash
./scripts/net-summary.js
```
