-- URL Watcher Module
-- Intercepts URLs via hs.urlevent.httpCallback (Hammerspoon as default browser)
-- Routes URLs to handlers based on pattern matching, falls through to real browser
--
-- Usage:
--   Add handlers to M.handlers table with pattern and action
--   Actions can be:
--     - string: bundle ID to open URL with
--     - function(url, sourceBundle, focusContext): custom handler function
--
-- REF: https://www.hammerspoon.org/docs/hs.urlevent.html
-- REF: Legacy implementation patterns from megalithic/dotfiles (legacy_dotbot branch)

local fmt = string.format
local fnutils = require("hs.fnutils")

local M = {}

M.__index = M
M.name = "watcher.url"
M.currentHandler = nil

--------------------------------------------------------------------------------
-- Configuration (embedded for now, refactor to config.lua later)
--------------------------------------------------------------------------------

-- Handlers are evaluated in order; first match wins
-- Each handler:
--   name: string - Human-readable name for logging
--   pattern: string - Lua pattern to match against URL
--   sourceApp: string|nil - Optional bundle ID to restrict matches (nil = any source)
--   action: string|function - Bundle ID to open with, or function(url, sourceBundle, focusContext)
M.handlers = {
  --[[
    Google OAuth Consent Auto-Clicker (MailMate)

    When MailMate needs to re-authenticate with Google, it opens a consent page.
    This handler:
    1. Opens the URL in the browser (background)
    2. Waits for page load
    3. Verifies the correct Google account is shown
    4. Clicks the "Continue" button
    5. Closes the tab

    Element references (as of 2025-01):
    - Account email: <div data-email="...">
    - Continue button: #submit_approve_access or button with "Continue" text
  ]]
  {
    name = "Google OAuth Consent (MailMate)",
    pattern = "accounts%.google%.com/o/oauth2",
    sourceApp = "com.freron.MailMate",
    action = function(url, sourceBundle, focusContext)
      -- NOTE: Email validation disabled - just automate whatever account is shown
      -- The OAuth URL already contains login_hint from MailMate, so the correct
      -- account should be pre-selected. Re-enable WORK_EMAIL validation later
      -- if we need to verify the account matches before clicking Continue.
      M.handleGoogleOAuthConsent(url, {
        targetEmail = nil, -- Not used when skipEmailValidation = true
        closeAfterSuccess = true,
        timeoutSeconds = 10,
        focusContext = focusContext,
      })
    end,
  },

  ------------------------------------------------------------------------------
  -- App-specific URL handlers
  -- Route web URLs to their native apps when installed
  ------------------------------------------------------------------------------

  -- 1Password: open in app instead of browser
  {
    name = "1Password",
    pattern = "start%.1password%.com/open/",
    action = function(url, sourceBundle, focusContext)
      -- Extract the 1Password URI from the redirect URL
      -- Format: https://start.1password.com/open/i?a=...&v=...&i=...&h=...
      -- Convert to: onepassword://open/i?a=...&v=...&i=...&h=...
      local uri = url:gsub("https?://start%.1password%.com/", "onepassword://")
      U.log.f("[%s] 1Password: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- Figma: open in desktop app (handles /file/, /design/, /proto/, /board/, etc.)
  {
    name = "Figma",
    pattern = "figma%.com/",
    action = function(url, sourceBundle, focusContext)
      -- Convert web URL to figma:// protocol
      -- Format: https://www.figma.com/file/... -> figma://file/...
      local uri = url:gsub("https?://[^/]*figma%.com/", "figma://")
      U.log.f("[%s] Figma: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- Zoom: open meetings in app
  {
    name = "Zoom",
    pattern = "zoom%.us/j/",
    action = function(url, sourceBundle, focusContext)
      -- Convert https://zoom.us/j/123456 to zoommtg://zoom.us/join?confno=123456
      local confno = url:match("zoom%.us/j/(%d+)")
      if confno then
        local uri = fmt("zoommtg://zoom.us/join?confno=%s", confno)
        -- Also extract password if present
        local pwd = url:match("[?&]pwd=([^&]+)")
        if pwd then uri = uri .. "&pwd=" .. pwd end
        U.log.f("[%s] Zoom: redirecting to %s", M.name, uri)
        hs.urlevent.openURL(uri)
      else
        -- Fallback to browser
        openUrlWithApp(url, BROWSER)
      end
    end,
  },

  -- Spotify: open in app (disabled - using Apple Music)
  -- {
  --   name = "Spotify",
  --   pattern = "open%.spotify%.com/",
  --   action = function(url, sourceBundle, focusContext)
  --     -- Convert https://open.spotify.com/track/... to spotify:track:...
  --     local uri = url:gsub("https?://open%.spotify%.com/", "spotify:")
  --     uri = uri:gsub("/", ":")
  --     uri = uri:gsub("%?.*", "") -- Remove query params
  --     U.log.f("[%s] Spotify: redirecting to %s", M.name, uri)
  --     hs.urlevent.openURL(uri)
  --   end,
  -- },

  -- Spotify short links (disabled - using Apple Music)
  -- {
  --   name = "Spotify Link",
  --   pattern = "spotify%.link/",
  --   action = "com.spotify.client",
  -- },

  -- Slack: open in app
  {
    name = "Slack",
    pattern = "slack%.com/archives/",
    action = function(url, sourceBundle, focusContext)
      -- Slack deep links: https://xxx.slack.com/archives/C123/p456
      -- Convert to: slack://channel?team=T123&id=C123&message=456
      -- For simplicity, just use the app's URL handler
      local uri = url:gsub("https?://", "slack://open?url=https://")
      U.log.f("[%s] Slack: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- Linear: open in app
  {
    name = "Linear",
    pattern = "linear%.app/",
    action = function(url, sourceBundle, focusContext)
      local uri = url:gsub("https?://", "linear://")
      U.log.f("[%s] Linear: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- Notion: open in app
  {
    name = "Notion",
    pattern = "notion%.so/",
    action = function(url, sourceBundle, focusContext)
      local uri = url:gsub("https?://", "notion://")
      U.log.f("[%s] Notion: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- Discord: open in app
  {
    name = "Discord",
    pattern = "discord%.com/channels/",
    action = function(url, sourceBundle, focusContext)
      local uri = url:gsub("https?://", "discord://")
      U.log.f("[%s] Discord: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },

  -- VS Code: open in app (vscode.dev links)
  {
    name = "VS Code",
    pattern = "vscode%.dev/",
    action = function(url, sourceBundle, focusContext)
      local uri = url:gsub("https?://vscode%.dev/", "vscode://vscode.dev/")
      U.log.f("[%s] VS Code: redirecting to %s", M.name, uri)
      hs.urlevent.openURL(uri)
    end,
  },
}

--------------------------------------------------------------------------------
-- Helper Functions
--------------------------------------------------------------------------------

--- Open URL in browser without stealing focus (uses AppleScript)
--- For Chromium-based browsers, opens URL in a new background tab
---@param url string URL to open
---@param bundleID string Application bundle ID
---@param opts table|nil Options: { background = true (default) }
---@return boolean success
local function openUrlWithApp(url, bundleID, opts)
  opts = opts or {}
  local background = opts.background ~= false

  -- Get app name for AppleScript
  local app = hs.application.get(bundleID)
  local appName = app and app:name()

  -- If app not running or background mode not requested, use standard method
  if not appName or not background then
    return hs.urlevent.openURLWithBundle(url, bundleID)
  end

  -- Use AppleScript to open URL in background tab (Chromium browsers)
  -- This avoids stealing focus from the current app
  local script = string.format(
    [[
    tell application "%s"
      -- Create new tab in front window without activating
      tell front window
        set newTab to make new tab with properties {URL:"%s"}
      end tell
    end tell
    return true
    ]],
    appName,
    url:gsub('"', '\\"')
  )

  local ok, result = hs.osascript.applescript(script)
  if not ok then
    U.log.wf("[%s] Background tab open failed, falling back to standard open", M.name)
    return hs.urlevent.openURLWithBundle(url, bundleID)
  end

  return true
end

--- Execute AppleScript and return result
---@param script string AppleScript code
---@return boolean ok, any result
local function runAppleScript(script)
  local ok, result, rawOutput = hs.osascript.applescript(script)
  if not ok then U.log.wf("[%s] AppleScript error: %s", M.name, rawOutput and tostring(rawOutput) or "unknown") end
  return ok, result
end

--- Get the browser app name from bundle ID for AppleScript
---@param bundleID string
---@return string|nil appName
local function getBrowserAppName(bundleID)
  local app = hs.application.get(bundleID)
  if app then return app:name() end
  -- Fallback mappings for common browsers
  local names = {
    ["com.brave.Browser.nightly"] = "Brave Browser Nightly",
    ["com.brave.Browser.dev"] = "Brave Browser Dev",
    ["com.brave.Browser"] = "Brave Browser",
    ["com.google.Chrome"] = "Google Chrome",
    ["com.apple.Safari"] = "Safari",
    ["org.mozilla.firefox"] = "Firefox",
  }
  return names[bundleID]
end

--------------------------------------------------------------------------------
-- Google OAuth Consent Handler
--------------------------------------------------------------------------------

--- Restore focus to the previously focused app/window
---@param focusContext table|nil { app = hs.application, window = hs.window }
local function restoreFocus(focusContext)
  if not focusContext then return end
  local app, win = focusContext.app, focusContext.window

  -- Try window first, then app
  if win then
    -- Window object may be stale, try to refetch by ID
    local winId = win:id()
    if winId then
      local freshWin = hs.window.get(winId)
      if freshWin and freshWin:isVisible() then
        freshWin:focus()
        U.log.df("[%s] Restored focus to window: %s", M.name, freshWin:title() or "untitled")
        return
      end
    end
  end

  -- Fallback to app activation
  if app and app:isRunning() then
    app:activate()
    U.log.df("[%s] Restored focus to app: %s", M.name, app:name() or "unknown")
  end
end

--- Handle Google OAuth consent page automation
---@param url string The OAuth URL
---@param opts table Options: targetEmail, closeAfterSuccess, timeoutSeconds, focusContext
function M.handleGoogleOAuthConsent(url, opts)
  opts = opts or {}
  local targetEmail = opts.targetEmail
  local closeAfterSuccess = opts.closeAfterSuccess ~= false
  local timeoutSeconds = opts.timeoutSeconds or 10
  local focusContext = opts.focusContext

  local browserBundle = BROWSER
  local browserName = getBrowserAppName(browserBundle)

  if not browserName then
    U.log.ef("[%s] Cannot determine browser name for %s", M.name, browserBundle)
    openUrlWithApp(url, browserBundle) -- Will restore focus via built-in mechanism
    return
  end

  U.log.f("[%s] Opening OAuth URL in %s (will automate consent for %s)", M.name, browserName, targetEmail)

  -- Open the URL in the browser
  if not openUrlWithApp(url, browserBundle) then
    U.log.ef("[%s] Failed to open URL in %s", M.name, browserName)
    restoreFocus(focusContext)
    return
  end

  -- JavaScript to verify account and click Continue
  -- This handles the Google OAuth consent page structure
  --
  -- NOTE: Email validation is currently DISABLED (skipEmailValidation = true)
  -- When re-enabled, set skipEmailValidation = false to verify the correct
  -- Google account is shown before clicking Continue.
  local skipEmailValidation = true

  local automationJS = fmt(
    [[
    (function() {
      var skipEmailValidation = %s;

      // Find the account email element
      var emailEl = document.querySelector('[data-email]');
      var email = emailEl ? emailEl.getAttribute('data-email') : null;

      // Email validation (disabled when skipEmailValidation is true)
      if (!skipEmailValidation) {
        if (!emailEl) {
          return JSON.stringify({status: 'error', reason: 'no-email-element'});
        }
        if (email !== '%s') {
          return JSON.stringify({status: 'error', reason: 'wrong-account', found: email});
        }
      }

      // Find and click the Continue button
      // Try multiple selectors for robustness
      // var btn = document.querySelector('#submit_approve_access button') ||
      //           document.querySelector('#submit_approve_access') ||
      //           document.querySelector('button[jsname="LgbsSe"]');

      var btn = document.querySelector('#submit_approve_access button');

      if (!btn) {
        // Fallback: find button by text content
        var buttons = document.querySelectorAll('button');
        for (var i = 0; i < buttons.length; i++) {
          if (buttons[i].textContent.trim() === 'Continue') {
            btn = buttons[i];
            break;
          }
        }
      }

      if (!btn) {
        return JSON.stringify({status: 'error', reason: 'no-continue-button'});
      }

      btn.click();
      return JSON.stringify({status: 'clicked', email: email || 'unknown (validation skipped)'});
    })()
  ]],
    skipEmailValidation and "true" or "false",
    targetEmail
  )

  -- Escape the JS for AppleScript string embedding
  local escapedJS = automationJS:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")

  -- AppleScript to find the OAuth tab and execute JS
  -- This runs without focusing the browser
  local findAndAutomateScript = fmt(
    [[
    tell application "%s"
      set foundTab to missing value
      set foundWindow to missing value

      repeat with w in windows
        repeat with t in tabs of w
          try
            if URL of t contains "accounts.google.com/signin/oauth" then
              set foundTab to t
              set foundWindow to w
              exit repeat
            end if
          end try
        end repeat
        if foundTab is not missing value then exit repeat
      end repeat

      if foundTab is missing value then
        return "{\"status\": \"error\", \"reason\": \"tab-not-found\"}"
      end if

      -- Execute the automation JS
      set jsResult to execute foundTab javascript "%s"
      return jsResult
    end tell
  ]],
    browserName,
    escapedJS
  )

  -- JavaScript to check for errors on the page after clicking Continue
  local errorCheckJS = [[
    (function() {
      var errors = [];
      var pageText = document.body ? document.body.innerText.toLowerCase() : '';

      // Common error patterns in text content
      var errorPatterns = [
        'something went wrong',
        'access denied',
        'authorization error',
        'error occurred',
        'request failed',
        'invalid request',
        'unauthorized',
        'permission denied',
        'authentication failed',
        'session expired',
        'try again',
        'couldn\'t sign you in',
        'can\'t connect',
        'this app is blocked',
        'access blocked'
      ];

      for (var i = 0; i < errorPatterns.length; i++) {
        if (pageText.indexOf(errorPatterns[i]) !== -1) {
          errors.push(errorPatterns[i]);
        }
      }

      // Check for error-indicating elements
      var errorSelectors = [
        '[role="alert"]',
        '.error-message',
        '.error',
        '[class*="error"]',
        '[class*="Error"]',
        '.alert-danger',
        '.alert-error',
        '#error',
        '[data-error]'
      ];

      for (var j = 0; j < errorSelectors.length; j++) {
        var el = document.querySelector(errorSelectors[j]);
        if (el && el.innerText && el.innerText.trim().length > 0) {
          var text = el.innerText.trim().substring(0, 100);
          if (errors.indexOf(text) === -1) {
            errors.push('element[' + errorSelectors[j] + ']: ' + text);
          }
        }
      }

      // Check URL for error indicators
      var url = window.location.href.toLowerCase();
      if (url.indexOf('error') !== -1 || url.indexOf('denied') !== -1 ||
          url.indexOf('failed') !== -1 || url.indexOf('invalid') !== -1) {
        errors.push('url-contains-error-indicator');
      }

      if (errors.length > 0) {
        return JSON.stringify({status: 'error', errors: errors});
      }
      return JSON.stringify({status: 'ok'});
    })()
  ]]
  local escapedErrorCheckJS = errorCheckJS:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")

  -- AppleScript to check for errors in the current tab
  local errorCheckScript = fmt(
    [[
    tell application "%s"
      repeat with w in windows
        repeat with t in tabs of w
          try
            if URL of t contains "accounts.google.com" then
              set jsResult to execute t javascript "%s"
              return jsResult
            end if
          end try
        end repeat
      end repeat
      return "{\"status\": \"ok\", \"note\": \"tab-not-found\"}"
    end tell
  ]],
    browserName,
    escapedErrorCheckJS
  )

  -- AppleScript to close a tab by URL pattern
  -- After clicking Continue, Google redirects to the OAuth callback URL
  -- For MailMate: https://mailmate-app.com/authorization_completed/
  local closeTabScript = fmt(
    [[
    tell application "%s"
      repeat with w in windows
        set tabsToClose to {}
        repeat with t in tabs of w
          try
            set u to URL of t
            -- Close OAuth pages or callback tabs
            if u contains "accounts.google.com/o/oauth2" or u contains "accounts.google.com/signin/oauth" or u contains "mailmate-app.com/authorization" or u starts with "http://127.0.0.1:" or u starts with "http://localhost:" then
              set end of tabsToClose to t
            end if
          end try
        end repeat
        -- Close tabs (in reverse to avoid index issues)
        repeat with i from (count of tabsToClose) to 1 by -1
          try
            close item i of tabsToClose
          end try
        end repeat
        if (count of tabsToClose) > 0 then
          return "closed:" & (count of tabsToClose)
        end if
      end repeat
      return "not-found"
    end tell
  ]],
    browserName
  )

  -- Wait for page to load, then automate
  -- Use a timer with retries since page load time varies
  local attempts = 0
  local maxAttempts = math.ceil(timeoutSeconds / 0.5)

  local function tryAutomation()
    attempts = attempts + 1

    local ok, result = runAppleScript(findAndAutomateScript)
    if not ok then
      if attempts < maxAttempts then
        hs.timer.doAfter(0.5, tryAutomation)
      else
        U.log.ef("[%s] OAuth automation timed out after %d attempts", M.name, attempts)
        restoreFocus(focusContext)
      end
      return
    end

    -- Parse the JSON result
    local parsed = hs.json.decode(result)
    if not parsed then
      U.log.wf("[%s] Could not parse automation result: %s", M.name, tostring(result))
      restoreFocus(focusContext)
      return
    end

    if parsed.status == "clicked" then
      U.log.of("[%s] OAuth consent clicked for %s, checking for errors...", M.name, parsed.email)

      -- Wait for page to respond, then check for errors before closing
      hs.timer.doAfter(1.5, function()
        local errorOk, errorResult = runAppleScript(errorCheckScript)
        local hasErrors = false

        if errorOk and errorResult then
          local errorParsed = hs.json.decode(errorResult)
          if errorParsed and errorParsed.status == "error" and errorParsed.errors then
            hasErrors = true
            U.log.ef("[%s] OAuth page shows errors after clicking Continue:", M.name)
            for _, err in ipairs(errorParsed.errors) do
              U.log.ef("[%s]   - %s", M.name, err)
            end
            U.log.wf("[%s] NOT closing tab due to errors - manual intervention required", M.name)
            restoreFocus(focusContext)
          end
        end

        if not hasErrors then
          U.log.of("[%s] OAuth consent completed successfully for %s", M.name, parsed.email)

          -- Close the tab after confirming no errors
          if closeAfterSuccess then
            hs.timer.doAfter(0.5, function()
              local closeOk, closeResult = runAppleScript(closeTabScript)
              if closeOk then U.log.df("[%s] Tab close result: %s", M.name, tostring(closeResult)) end
              restoreFocus(focusContext)
            end)
          else
            restoreFocus(focusContext)
          end
        end
      end)
    elseif parsed.status == "error" then
      if parsed.reason == "tab-not-found" or parsed.reason == "no-email-element" then
        -- Page might not be loaded yet, retry
        if attempts < maxAttempts then
          hs.timer.doAfter(0.5, tryAutomation)
        else
          U.log.wf("[%s] OAuth automation failed: %s (after %d attempts)", M.name, parsed.reason, attempts)
          restoreFocus(focusContext)
        end
      elseif parsed.reason == "wrong-account" then
        U.log.wf("[%s] OAuth page shows different account: %s (expected %s)", M.name, parsed.found, targetEmail)
        -- Don't auto-click for wrong account, leave tab open for user but restore focus
        restoreFocus(focusContext)
      else
        U.log.wf("[%s] OAuth automation error: %s", M.name, parsed.reason)
        restoreFocus(focusContext)
      end
    end
  end

  -- Start automation after initial delay for page load
  hs.timer.doAfter(1.0, tryAutomation)
end

--------------------------------------------------------------------------------
-- URL Callback Handler (Core)
--------------------------------------------------------------------------------

--- Find a handler matching the given URL and optional source app
---@param url string URL to match
---@param sourceBundle string|nil Source application bundle ID
---@return table|nil handler The matching handler, or nil
local function findHandler(url, sourceBundle)
  return fnutils.find(M.handlers, function(handler)
    -- Check URL pattern
    if not string.match(url, handler.pattern) then return false end
    -- Check source app restriction (if specified)
    if handler.sourceApp and handler.sourceApp ~= sourceBundle then return false end
    return true
  end)
end

--- Handle incoming HTTP/HTTPS URL
--- This is the main callback registered with hs.urlevent.httpCallback
---@param scheme string "http" or "https"
---@param host string URL host
---@param params table URL query parameters
---@param fullURL string Complete URL
---@param senderPID number Process ID of the app that triggered the URL open
local function handleHttpCallback(scheme, host, params, fullURL, senderPID)
  -- Capture current focus IMMEDIATELY before any URL handling
  -- This must happen first, before any async operations or URL opens
  local previousApp = hs.application.frontmostApplication()
  local previousWindow = previousApp and previousApp:focusedWindow()

  -- Determine the source application bundle ID
  local sourceBundle = nil
  if senderPID and senderPID > 0 then
    local sourceApp = hs.application.applicationForPID(senderPID)
    if sourceApp then sourceBundle = sourceApp:bundleID() end
  end

  U.log.df("[%s] URL received: %s (from: %s, PID: %s)", M.name, fullURL, sourceBundle or "unknown", senderPID or "?")

  -- Safety check
  if not fullURL or fullURL == "" then
    U.log.ef("[%s] Received empty URL", M.name)
    return
  end

  -- Store focus context for handlers that need it
  local focusContext = {
    app = previousApp,
    window = previousWindow,
  }

  -- Find matching handler
  local handler = findHandler(fullURL, sourceBundle)

  if handler then
    U.log.f("[%s] Matched handler: %s", M.name, handler.name)

    if type(handler.action) == "function" then
      -- Custom handler function - pass focus context as 3rd arg
      local ok, err = pcall(handler.action, fullURL, sourceBundle, focusContext)
      if not ok then
        U.log.ef("[%s] Handler '%s' error: %s", M.name, handler.name, tostring(err))
        -- Fallback: open in default browser
        openUrlWithApp(fullURL, BROWSER)
      end
    elseif type(handler.action) == "string" then
      -- Bundle ID to open with
      U.log.df("[%s] Opening URL with %s", M.name, handler.action)
      openUrlWithApp(fullURL, handler.action)
    end
  else
    -- No handler matched, pass through to default browser
    U.log.df("[%s] No handler matched, opening in %s", M.name, BROWSER)
    openUrlWithApp(fullURL, BROWSER)
  end
end

--------------------------------------------------------------------------------
-- Nvim Open URL Handler (for PLUG_EDITOR / Phoenix clickable stacktraces)
--------------------------------------------------------------------------------

--- Register the hammerspoon://nvim-open URL handler.
--- All resolution + open logic lives in lib/interop/nvim-open.
function M.registerNvimOpenHandler()
  hs.urlevent.bind("nvim-open", require("lib.interop.nvim-open").handleURL)
  U.log.f("[%s] nvim-open URL handler registered", M.name)
end

--------------------------------------------------------------------------------
-- Module Lifecycle
--------------------------------------------------------------------------------

function M:start()
  -- Check if Hammerspoon is the default HTTP handler
  -- If not, the httpCallback won't receive URL events
  local defaultHandler = hs.urlevent.getDefaultHandler("http")
  if defaultHandler ~= "org.hammerspoon.Hammerspoon" then
    U.log.wf("[%s] Hammerspoon is not the default HTTP handler (current: %s)", M.name, defaultHandler or "none")
    U.log.wf("[%s] To enable URL interception, run: hs.urlevent.setDefaultHandler('http')", M.name)
    -- Still register the callback in case user sets it later
  end

  -- Register as HTTP/HTTPS handler
  hs.urlevent.httpCallback = handleHttpCallback
  M.currentHandler = BROWSER

  -- Register hammerspoon://nvim-open handler for PLUG_EDITOR
  -- Opens files in neovim running in a tmux session (for Phoenix clickable stacktraces)
  M.registerNvimOpenHandler()

  U.log.f("[%s] started (HTTP callback registered)", M.name)
  return self
end

function M:stop()
  -- Unregister HTTP callback
  hs.urlevent.httpCallback = nil
  M.currentHandler = nil

  U.log.f("[%s] stopped (HTTP callback unregistered)", M.name)
  return self
end

return M
