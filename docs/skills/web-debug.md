---
name: web-debug
description: Systematic web application debugging using Chrome DevTools MCP with intelligent validation and app-specific context discovery. Use for debugging web apps, APIs, authentication flows, and UI issues.
tools: mcp__chrome-devtools__*, mcp__fetch__fetch, Read, Grep, mcp__memory__*
---

# Web Application Debugging with Chrome DevTools MCP

## Overview

This skill guides systematic, efficient web debugging using Chrome DevTools MCP. It emphasizes **validation before action** to minimize slow operations and **automatic context discovery** from project documentation.

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

---

**Remember**: Speed comes from intelligence, not just raw execution. Validate, batch, and use the lightest tool for the job.
