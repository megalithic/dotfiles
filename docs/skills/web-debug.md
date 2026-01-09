---
name: web-debug
description: Systematic web application debugging using Chrome DevTools MCP and Playwright MCP with intelligent validation and app-specific context discovery. Use for debugging web apps, APIs, authentication flows, and UI issues.
tools: mcp__chrome-devtools__*, mcp__playwright__*, mcp__fetch__fetch, Read, Grep, mcp__memory__*
---

# Web Application Debugging with Chrome DevTools MCP and Playwright MCP

## Overview

This skill guides systematic, efficient web debugging using Chrome DevTools MCP and
Playwright MCP. It emphasizes **validation before action** to minimize slow operations
and **automatic context discovery** from project documentation.

## Decision Trees

### "Which MCP should I use?"

```
Browser debugging needed?
│
├─▶ Chrome is already open with target page?
│   └─▶ Use Chrome DevTools MCP
│       ├─▶ Requires: --remote-debugging-port=9222 flag
│       └─▶ Check: curl http://localhost:9222/json/version
│
├─▶ Need to launch fresh browser instance?
│   └─▶ Use Playwright MCP
│       ├─▶ Creates headless or headed browser
│       └─▶ Cleaner state, no extension interference
│
├─▶ Need to test multiple browsers (Brave, Firefox, Safari)?
│   └─▶ Playwright MCP supports multiple engines
│
├─▶ Need to connect to existing DevTools session?
│   └─▶ Chrome DevTools MCP only
│
└─▶ Automated testing / repeatable scenarios?
    └─▶ Playwright MCP (better API for automation)
```

### "How should I debug this issue?"

```
Web debugging task?
│
├─▶ Page not loading / blank screen?
│   ├─▶ 1. Validate URL: mcp__fetch__fetch (check status)
│   ├─▶ 2. Check console: list_console_messages({ types: ["error"] })
│   ├─▶ 3. Check network: list_network_requests (look for 4xx/5xx)
│   └─▶ 4. Only then: browser_snapshot (see what rendered)
│
├─▶ Authentication not working?
│   ├─▶ 1. Check docs for auth method (Context Discovery)
│   ├─▶ 2. Inspect storage: browser_evaluate localStorage/cookies
│   ├─▶ 3. Check network: filter for auth endpoints
│   └─▶ 4. Inspect response headers (Set-Cookie, WWW-Authenticate)
│
├─▶ API call failing?
│   ├─▶ 1. list_network_requests({ resourceTypes: ["xhr", "fetch"] })
│   ├─▶ 2. get_network_request({ reqid: N }) for details
│   ├─▶ 3. Check: status, headers, body, CORS errors
│   └─▶ 4. Compare with docs/expected API contract
│
├─▶ Element not found / can't click?
│   ├─▶ 1. Quick check: browser_evaluate("!!document.querySelector(...)")
│   ├─▶ 2. If false: check network for pending loads
│   ├─▶ 3. If still false: browser_snapshot to see actual page
│   └─▶ 4. Check: wrong selector, dynamic loading, iframe
│
├─▶ Page is slow?
│   ├─▶ 1. performance_start_trace({ reload: true, autoStop: true })
│   ├─▶ 2. Review insights from trace
│   └─▶ 3. Check: large network payloads, long JS execution
│
└─▶ Visual/layout issue?
    ├─▶ 1. browser_snapshot (accessibility tree)
    ├─▶ 2. browser_take_screenshot (actual visual)
    └─▶ 3. For full-page: save to file, then resize-image --check
```

### "Should I take a screenshot or snapshot?"

```
Need page content?
│
├─▶ Need to interact (click, fill, etc.)?
│   └─▶ browser_snapshot (returns element refs like "e123")
│
├─▶ Need exact visual appearance?
│   └─▶ browser_take_screenshot
│       ├─▶ Viewport only: Usually safe
│       ├─▶ fullPage: true: ⚠️ May exceed API limits
│       │   └─▶ Save to file, then: resize-image --check
│       └─▶ Element screenshot: Specify uid
│
├─▶ Just checking page structure?
│   └─▶ browser_snapshot (faster, includes a11y tree)
│
├─▶ Verifying simple condition?
│   └─▶ browser_evaluate is FASTEST
│       └─▶ "() => document.title"
│       └─▶ "() => !!document.querySelector('.logged-in')"
│
└─▶ Performance investigation?
    └─▶ performance_start_trace / performance_stop_trace
```

## Core Principle: Validate Before Acting

**CRITICAL**: MCP browser operations are expensive. Always validate before taking action:

```bash
# ❌ SLOW - Navigate blindly, then snapshot to check
browser_navigate → browser_snapshot → "oops, 404"

# ✅ FAST - Validate URL exists first
fetch(url) → if 200 then browser_navigate → quick check current URL matches
```

## Smart Debugging Workflow

### 1. Context Discovery (First Step)

Before debugging, discover app-specific context from the repository:

```bash
# Check for web debugging documentation (in priority order)
1. docs/web-debug.md           # Dedicated debugging guide
2. docs/debugging.md            # General debugging guide
3. docs/authentication.md       # Auth-specific docs
4. README.md                    # Project README (search for "debug", "auth", "dev")
5. .env.example / .env.local    # Environment variable hints
6. package.json / Gemfile / etc # Check for dev scripts, test users
```

**What to extract from docs:**
- Base URL(s) for local dev / staging / production
- Authentication mechanism (JWT, sessions, OAuth, API keys)
- Test credentials or how to obtain them
- Common routes and expected behavior
- Known issues / quirks
- API endpoint patterns

**Store discovered context:**
```bash
# Use MCP memory to remember app context for future sessions
mcp__memory__create_entities({
  entities: [{
    name: "launchdeck-web-debug",
    entityType: "AppDebugContext",
    observations: [
      "Base URL: http://localhost:3000",
      "Auth: JWT token in localStorage key 'auth_token'",
      "Test credentials: user@example.com / password123",
      "API pattern: /api/v1/{resource}",
      "Known issue: CORS errors on Safari, works on Brave"
    ]
  }]
})
```

### 2. Pre-Flight Validation (Before Navigation)

**Always validate URLs before navigating:**

```typescript
// ✅ Validate URL is reachable
const response = await mcp__fetch__fetch({
  url: targetUrl,
  prompt: "Return status code only"
});

if (response.includes("404") || response.includes("error")) {
  // Don't navigate, report the issue
  return "URL not reachable: " + targetUrl;
}

// ✅ Quick check - are we already on the right page?
const pages = await browser_list_pages();
if (currentPage.url === targetUrl) {
  // Skip navigation, already there
}
```

### 3. Efficient State Inspection

**Use the lightest operation that answers your question:**

| Need | ❌ Slow | ✅ Fast |
|------|---------|---------|
| Check current URL | `browser_snapshot` | `browser_list_pages` |
| Verify element exists | `browser_snapshot` | `browser_evaluate({ function: "() => !!document.querySelector('.login-btn')" })` |
| Get simple value | `browser_snapshot` | `browser_evaluate({ function: "() => localStorage.getItem('token')" })` |
| Check if logged in | `browser_snapshot` | `browser_evaluate({ function: "() => document.body.dataset.authenticated" })` |
| Inspect network | `browser_snapshot` | `list_network_requests` |
| Check console errors | `browser_snapshot` | `list_console_messages({ types: ["error"] })` |

**Batch parallel operations:**
```typescript
// ✅ Get all diagnostic info at once (parallel)
Promise.all([
  list_console_messages({ types: ["error", "warn"] }),
  list_network_requests({ resourceTypes: ["xhr", "fetch"] }),
  browser_evaluate({ function: "() => ({ url: window.location.href, token: localStorage.getItem('auth_token') })" })
])

// ❌ Sequential snapshots (3x slower)
browser_snapshot → list_console_messages → list_network_requests
```

### 4. Authentication Handling

**Discovery process:**

1. **Check documentation first** (see Context Discovery above)
2. **Inspect the app** (if docs don't exist):
   ```typescript
   // Check for common auth patterns
   browser_evaluate({
     function: `() => ({
       localStorage: Object.keys(localStorage).filter(k =>
         k.includes('token') || k.includes('auth') || k.includes('session')
       ),
       cookies: document.cookie,
       hasLoginForm: !!document.querySelector('form[action*="login"]'),
       userIndicator: document.querySelector('[data-user], .user-name')?.textContent
     })`
   })
   ```

3. **If auth mechanism unknown, ask user ONCE and remember:**
   ```bash
   # Ask user via AskUserQuestion tool
   "I need to authenticate with this app but couldn't find credentials.
    How should I log in?"

   # Store their answer in MCP memory for future sessions
   mcp__memory__add_observations({
     entityName: "app-name-web-debug",
     observations: ["Auth method: Form login with user@test.com / password123"]
   })
   ```

### 5. Systematic Debugging by Issue Type

#### Network / API Debugging

```typescript
// 1. List recent network activity (fast)
const requests = await list_network_requests({
  resourceTypes: ["xhr", "fetch"],
  includeStatic: false  // Ignore images, fonts, etc.
});

// 2. Filter for failures or slow requests
const issues = requests.filter(r =>
  r.status >= 400 || r.time > 2000
);

// 3. Inspect specific failed request
if (issues.length > 0) {
  const detail = await get_network_request({ reqid: issues[0].id });
  // Check: headers, body, timing, CORS issues
}
```

#### Console Error Debugging

```typescript
// 1. Get errors only (fast)
const errors = await list_console_messages({
  types: ["error"],
  includePreservedMessages: false
});

// 2. Get detailed error if needed
if (errors.length > 0) {
  const detail = await get_console_message({ msgid: errors[0].id });
}

// 3. Correlate with network failures
// Often console errors follow failed API calls
```

#### Authentication Flow Debugging

```typescript
// 1. Check current auth state (fast evaluate, not snapshot)
const authState = await browser_evaluate({
  function: `() => ({
    token: localStorage.getItem('auth_token'),
    cookies: document.cookie.split(';').map(c => c.trim().split('=')[0]),
    isLoggedIn: !!document.querySelector('[data-logged-in="true"]')
  })`
});

// 2. If not authenticated, check if we have credentials
const appContext = await mcp__memory__search_nodes({
  query: `${appName} auth credentials`
});

// 3. Perform login if we have credentials
if (appContext.hasCredentials) {
  await browser_fill_form({ fields: [...] });
  await browser_click({ element: "Submit", ref: "..." });

  // 4. Validate login succeeded (check for redirect or token)
  await wait_for({ text: "Dashboard" }); // or check localStorage
}
```

#### UI / Interaction Debugging

```typescript
// 1. Before clicking, validate element exists (evaluate, not snapshot)
const elementExists = await browser_evaluate({
  function: `() => !!document.querySelector('button[data-action="submit"]')`
});

if (!elementExists) {
  // Don't attempt click, investigate why element is missing
  // Check: network failures, JS errors, wrong page
}

// 2. Take snapshot only when actually needed for interaction
const snapshot = await browser_snapshot();
// Now find element ref and interact
```

## Decision Framework

### When to use full `browser_snapshot`
- **Need to interact** with elements (requires refs)
- **Visual debugging** (need to see layout/hierarchy)
- **Unknown page state** (first time visiting)

### When to use `browser_evaluate`
- **Simple data extraction** (get token, check boolean)
- **Quick validation** (element exists, page ready)
- **Performance-critical checks** (in loops, pre-flight validation)

### When to use `list_*` tools
- **Diagnostic info** (console errors, network failures)
- **Monitoring** (watching for issues during workflow)
- **Quick checks** (any errors? any failed requests?)

## Common Patterns

### Pattern: Safe Navigation
```typescript
async function navigateSafely(url: string) {
  // 1. Validate URL exists
  const check = await mcp__fetch__fetch({
    url,
    prompt: "HTTP status code only"
  });
  if (!check.includes("200")) {
    throw new Error(`URL not reachable: ${url}`);
  }

  // 2. Check if already there
  const pages = await browser_list_pages();
  if (pages.current.url === url) {
    return "Already on page";
  }

  // 3. Navigate
  await browser_navigate({ url });

  // 4. Wait for specific content (not arbitrary timeout)
  await wait_for({ text: "Expected content" });
}
```

### Pattern: Quick Health Check
```typescript
async function quickHealthCheck() {
  // Parallel checks - all fast operations
  const [console, network, state] = await Promise.all([
    list_console_messages({ types: ["error"] }),
    list_network_requests({ includeStatic: false }),
    browser_evaluate({
      function: "() => ({ url: location.href, ready: document.readyState })"
    })
  ]);

  return {
    errors: console.filter(m => m.type === "error"),
    failures: network.filter(r => r.status >= 400),
    currentUrl: state.url,
    pageReady: state.ready === "complete"
  };
}
```

### Pattern: Find and Remember Auth
```typescript
async function discoverAuth(appName: string) {
  // 1. Check if we already know
  const known = await mcp__memory__open_nodes({
    names: [`${appName}-web-debug`]
  });

  if (known.hasAuth) {
    return known.authMethod;
  }

  // 2. Search docs in repo
  const authDoc = await findInRepo([
    "docs/web-debug.md",
    "docs/authentication.md",
    "README.md"
  ], /auth|login|credential/i);

  if (authDoc) {
    // Extract and store
    await mcp__memory__create_entities({
      entities: [{
        name: `${appName}-web-debug`,
        entityType: "AppDebugContext",
        observations: [extractedAuthInfo]
      }]
    });
    return extractedAuthInfo;
  }

  // 3. Ask user (last resort)
  const userInput = await AskUserQuestion({
    questions: [{
      question: `How should I authenticate with ${appName} for debugging?`,
      header: "Auth Method",
      options: [
        { label: "Form login", description: "Username/password form" },
        { label: "API token", description: "Bearer token in headers" },
        { label: "Session cookie", description: "Cookie-based auth" },
        { label: "No auth needed", description: "Public access" }
      ],
      multiSelect: false
    }]
  });

  // Store for next time
  await mcp__memory__create_entities({ ... });
  return userInput;
}
```

## Optimization Checklist

Before any debugging session, ensure:

- [ ] Browser is running with `--remote-debugging-port=9222`
- [ ] Checked `http://localhost:9222/json/version` to verify connection
- [ ] Loaded app context from docs or memory
- [ ] Know the base URL and auth method
- [ ] Have test credentials available

During debugging:

- [ ] Validate URLs before navigating (use `fetch`)
- [ ] Check current URL before re-navigating (use `list_pages`)
- [ ] Use `evaluate` for simple checks, not `snapshot`
- [ ] Batch parallel requests when possible
- [ ] Only snapshot when you need element refs for interaction
- [ ] Check console/network logs before assuming app state

## Error Recovery

If debugging fails:

1. **Browser not responding**: Check if debug port is open
   ```bash
   curl http://localhost:9222/json/version
   ```

2. **Can't find elements**: Take snapshot to see current state
   ```bash
   browser_snapshot()  # See what's actually on the page
   ```

3. **Navigation timeout**: URL might not exist or be slow
   ```bash
   # Increase timeout or validate URL first
   browser_navigate({ url, timeout: 30000 })
   ```

4. **Auth not working**: Clear state and retry
   ```typescript
   browser_evaluate({
     function: "() => { localStorage.clear(); location.reload(); }"
   })
   ```

## App Context Template

When creating `docs/web-debug.md` in an app repo, use this template:

```markdown
# Web Debugging Context for [App Name]

## Base URLs
- Development: http://localhost:3000
- Staging: https://staging.example.com
- Production: https://example.com

## Authentication
- Method: JWT token in localStorage
- Key: `auth_token`
- Test credentials: `test@example.com` / `password123`
- Login endpoint: POST /api/auth/login
- Token expiry: 24 hours

## Common Routes
- Dashboard: /dashboard
- Login: /login
- API base: /api/v1

## API Patterns
- Auth header: `Authorization: Bearer ${token}`
- Response format: `{ data: {...}, error: null }`
- Error format: `{ data: null, error: { message: "..." } }`

## Known Issues
- CORS errors on Safari - use Brave for debugging
- Websocket connection fails on first load - refresh once
- Session expires after 30min inactivity

## Development Setup
```bash
npm run dev         # Start dev server on :3000
npm run test:e2e    # Run E2E tests (creates test data)
```

## Test Data
- Test user: `test@example.com` (auto-created on dev startup)
- Sample data seeded: Yes (see `db/seeds.rb`)
```

## Playwright MCP Reference

When using Playwright MCP instead of Chrome DevTools MCP, here are the equivalent operations:

### Tool Mapping

| Chrome DevTools MCP | Playwright MCP | Notes |
|---------------------|----------------|-------|
| `take_snapshot` | `browser_snapshot` | Same output format |
| `take_screenshot` | `browser_take_screenshot` | Playwright has more options |
| `navigate_page` | `browser_navigate` | |
| `click` | `browser_click` | |
| `fill` | `browser_type` | Playwright: type into element |
| `fill_form` | `browser_fill_form` | Multi-field form filling |
| `press_key` | `browser_press_key` | Keyboard input |
| `hover` | `browser_hover` | |
| `evaluate_script` | `browser_evaluate` | Run JS in page |
| `list_console_messages` | `browser_console_messages` | |
| `list_network_requests` | `browser_network_requests` | |
| `list_pages` | `browser_tabs` | Tab management |
| `select_page` | `browser_tabs` | With `action: "select"` |
| `new_page` | `browser_tabs` | With `action: "new"` |
| `close_page` | `browser_tabs` | With `action: "close"` |
| `wait_for` | `browser_wait_for` | Wait for text/element |
| `handle_dialog` | `browser_handle_dialog` | Alert/confirm/prompt |

### Playwright-Specific Features

```typescript
// Navigate back/forward (Playwright only)
browser_navigate_back()

// Run arbitrary Playwright code
browser_run_code({
  code: `async (page) => {
    await page.getByRole('button', { name: 'Submit' }).click();
    return await page.title();
  }`
})

// Select dropdown option
browser_select_option({
  element: "Country dropdown",
  ref: "e123",
  values: ["United States"]
})

// Drag and drop
browser_drag({
  startElement: "Item to drag",
  startRef: "e45",
  endElement: "Drop target",
  endRef: "e67"
})

// File upload
browser_file_upload({
  paths: ["/path/to/file.pdf"]
})

// Close browser completely
browser_close()
```

### When to Prefer Playwright MCP

1. **Headless testing** - No visible browser needed
2. **Clean state** - No cookies, storage, or extensions
3. **Multiple browsers** - Chromium, Firefox, WebKit
4. **Complex interactions** - Drag/drop, file upload, dialogs
5. **Code-based automation** - `browser_run_code` for complex sequences

## Screenshot Handling

**CRITICAL**: Full-page screenshots can exceed Claude API limits (5MB, 8000px max dimension).

### Safe Screenshot Workflow

```typescript
// ✅ SAFE - Viewport only
browser_take_screenshot()

// ✅ SAFE - Element screenshot
browser_take_screenshot({ uid: "e123" })

// ⚠️ DANGER - Full page may exceed limits
browser_take_screenshot({ fullPage: true })

// ✅ SAFE - Save to file, then check
browser_take_screenshot({
  fullPage: true,
  filePath: "/tmp/screenshot.png"
})
```

After saving to file:

```bash
# Check if resize needed
resize-image --check /tmp/screenshot.png

# If "needs-resize", resize before reading
resize-image /tmp/screenshot.png

# Then read the resized version
# /tmp/screenshot-resized.png
```

**See the `image-handling` skill for complete resize-image documentation.**

## Self-Discovery Patterns

### Exploring Chrome DevTools MCP

```bash
# Check if Chrome DevTools MCP is available
# Look for mcp__chrome-devtools__* tools in your available tools list

# Verify browser connection
curl http://localhost:9222/json/version

# List available pages/tabs
mcp__chrome-devtools__list_pages()

# Check what's on current page
mcp__chrome-devtools__take_snapshot()
```

### Exploring Playwright MCP

```bash
# Check if Playwright MCP is available
# Look for mcp__playwright__* tools

# Check browser status
mcp__playwright__browser_snapshot()

# If browser not running, may need to navigate first
mcp__playwright__browser_navigate({ url: "http://localhost:3000" })

# If browser engine not installed
mcp__playwright__browser_install()
```

### Checking Network/Console State

```typescript
// Quick diagnostic bundle
const [console, network, cookies] = await Promise.all([
  list_console_messages({ types: ["error", "warn"] }),
  list_network_requests({ resourceTypes: ["xhr", "fetch"] }),
  browser_evaluate({ function: "() => document.cookie" })
]);

console.log("Console errors:", console.filter(m => m.type === "error").length);
console.log("Failed requests:", network.filter(r => r.status >= 400).length);
console.log("Has cookies:", cookies.length > 0);
```

## Troubleshooting

### Chrome DevTools MCP Issues

**"Cannot connect to browser"**
```bash
# Check if debug port is open
curl http://localhost:9222/json/version

# If nothing, browser wasn't started with debug flag
# Restart Chrome/Brave with:
brave --remote-debugging-port=9222

# Or for Chrome:
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
```

**"No pages found"**
```bash
# Check what pages are available
curl http://localhost:9222/json/list

# Open a page first if empty
open http://localhost:3000  # Then MCP can see it
```

**"Element not found (ref invalid)"**
- Refs (e.g., "e123") are only valid from the MOST RECENT snapshot
- Take a new snapshot before interacting
- Page may have changed since last snapshot

**"Timeout waiting for element"**
- Check if page is fully loaded: `browser_evaluate("() => document.readyState")`
- Check for JS errors: `list_console_messages({ types: ["error"] })`
- Element may be in iframe: can't access cross-origin iframes

### Playwright MCP Issues

**"Browser not found"**
```bash
# Install browser engine
mcp__playwright__browser_install()

# Then retry navigation
mcp__playwright__browser_navigate({ url: "..." })
```

**"Page closed unexpectedly"**
- Playwright may close browser on errors
- Re-navigate to restart: `browser_navigate({ url: "..." })`
- Check for unhandled dialogs: `browser_handle_dialog({ accept: true })`

**"Cannot interact with element"**
- Take fresh snapshot to get current refs
- Element may be hidden/overlapped - check visibility
- May need to scroll element into view first

### General Issues

**"Authentication keeps failing"**
1. Check credentials in docs: `docs/web-debug.md`, `README.md`
2. Inspect what's being sent: `get_network_request` for login endpoint
3. Check for CSRF tokens in form
4. Try clearing state: `browser_evaluate("() => localStorage.clear()")`
5. Check cookies are being set: `browser_evaluate("() => document.cookie")`

**"Page is stuck loading"**
1. Check network: `list_network_requests` - any pending/failed?
2. Check console: `list_console_messages` - JS errors blocking?
3. Try reload: `navigate_page({ type: "reload" })`
4. Increase timeout: `navigate_page({ timeout: 60000 })`

**"Getting different results than expected"**
1. Verify you're on the right page: `list_pages` or `browser_evaluate("() => location.href")`
2. Check if logged in: `browser_evaluate` for auth indicators
3. Compare with fresh browser session - cache/cookies may affect behavior

## Known Limitations

1. **Cross-origin iframes** - Cannot access content in cross-origin iframes
2. **Browser extensions** - Chrome DevTools sees extension-injected content; Playwright doesn't
3. **Shadow DOM** - Some elements in shadow DOM may not appear in snapshot
4. **Canvas/WebGL** - Cannot inspect canvas content (only screenshot)
5. **Service Workers** - Limited visibility into service worker behavior
6. **Multiple windows** - Each MCP session typically manages one browser window

---

**Remember**: Speed comes from intelligence, not just raw execution. Validate, batch, and use the lightest tool for the job.
