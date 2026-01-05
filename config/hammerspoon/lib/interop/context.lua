-- Context Detection Module
-- Detects frontmost app type and gathers context (URL, title, selection)
--
local M = {}
local fmt = string.format

--------------------------------------------------------------------------------
-- APP TYPE DETECTION
--------------------------------------------------------------------------------

--- Detect the type of the frontmost application
---@param app hs.application
---@return "browser"|"terminal"|"neovim"|"other"
local function detectAppType(app)
  if not app then return "other" end

  local bundleID = (app:bundleID() or ""):lower()

  -- Terminal detection
  local terminals = { "ghostty", "iterm", "terminal", "alacritty", "kitty", "warp", "hyper" }
  for _, t in ipairs(terminals) do
    if bundleID:find(t) then return "terminal" end
  end

  -- Browser detection via AXDocument with http(s) URL
  local axApp = hs.axuielement.applicationElement(app)
  if axApp then
    local win = axApp:attributeValue("AXFocusedWindow")
    if win then
      local doc = win:attributeValue("AXDocument")
      if doc and doc:match("^https?://") then return "browser" end
    end
  end

  return "other"
end

--------------------------------------------------------------------------------
-- BROWSER CONTEXT
--------------------------------------------------------------------------------

-- Map of known browsers to their JXA app names
local browserMap = {
  ["com.brave.Browser.nightly"] = { name = "Brave Browser Nightly" },
  ["com.brave.Browser"] = { name = "Brave Browser" },
  ["com.brave.Browser.dev"] = { name = "Brave Browser Dev" },
  ["com.brave.Browser.beta"] = { name = "Brave Browser Beta" },
  ["com.google.Chrome"] = { name = "Google Chrome" },
  ["com.google.Chrome.canary"] = { name = "Google Chrome Canary" },
  ["org.chromium.Chromium"] = { name = "Chromium" },
  ["company.thebrowser.Browser"] = { name = "Arc" },
  ["com.apple.Safari"] = { name = "Safari", isSafari = true },
}

--- Get browser context via JXA (URL, title, selection)
---@param app hs.application
---@return table|nil { url, title, selection }
local function getBrowserContext(app)
  if not app then return nil end

  local bundleID = app:bundleID()
  local browser = browserMap[bundleID]

  if browser then
    -- Use JXA for known browsers
    local script
    if browser.isSafari then
      script = [[
        (function() {
          var safari = Application("Safari");
          if (!safari.running()) return null;
          var win = safari.windows[0];
          if (!win) return null;
          var tab = win.currentTab;
          if (!tab) return null;
          var selection = "";
          try {
            selection = safari.doJavaScript("window.getSelection().toString()", {in: tab}) || "";
          } catch(e) {}
          return {
            url: tab.url(),
            title: tab.name(),
            selection: selection
          };
        })();
      ]]
    else
      script = fmt(
        [[
        (function() {
          var browser = Application("%s");
          if (!browser.running()) return null;
          var win = browser.windows[0];
          if (!win) return null;
          var tab = win.activeTab;
          if (!tab) return null;
          var selection = "";
          try {
            selection = browser.execute(tab, {javascript: "window.getSelection().toString()"}) || "";
          } catch(e) {}
          return {
            url: tab.url(),
            title: tab.title(),
            selection: selection
          };
        })();
      ]],
        browser.name
      )
    end

    local ok, result = hs.osascript.javascript(script)
    if ok and result then return result end
  end

  -- Fallback: use AXDocument for URL and AXTitle for window title
  local axApp = hs.axuielement.applicationElement(app)
  if axApp then
    local win = axApp:attributeValue("AXFocusedWindow")
    if win then
      return {
        url = win:attributeValue("AXDocument"),
        title = win:attributeValue("AXTitle"),
        selection = nil, -- Can't get selection without JXA
      }
    end
  end

  return nil
end

--------------------------------------------------------------------------------
-- NEOVIM CONTEXT
--------------------------------------------------------------------------------

--- Get neovim context via socket RPC
---@return table|nil { path, filetype, selection, line, col }
local function getNeovimContext()
  local nvim = require("lib.interop.nvim")

  local socket = nvim.getActiveSocket()
  if not socket then return nil end

  local bufInfo = nvim.getBufferInfo(socket)
  if not bufInfo then return nil end

  local selection = nvim.getVisualSelection(socket)

  return {
    path = bufInfo.path,
    filetype = bufInfo.filetype,
    line = bufInfo.line,
    col = bufInfo.col,
    selection = selection,
  }
end

--------------------------------------------------------------------------------
-- ACCESSIBILITY-BASED SELECTION (via Swift script)
--------------------------------------------------------------------------------

--- Get selected text via Accessibility APIs (clipboard-free)
--- Uses bin/get-selection Swift script that queries kAXSelectedTextAttribute
---@return string|nil selectedText
---@return string|nil url (bonus: also returns URL if available)
local function getSelectionViaAccessibility()
  local selection = require("lib.interop.selection")

  -- Use sync wrapper with 1.5s timeout (reasonable for AX queries)
  local result, err = selection.getSync(1.5)

  if err then
    U.log.d(fmt("selection.getSync() error: %s", err))
    return nil, nil
  end

  if result and result.hasSelection then return result.selectedText, result.url end

  return nil, nil
end

--------------------------------------------------------------------------------
-- LANGUAGE DETECTION
--------------------------------------------------------------------------------

-- File extension to language mapping
-- This is reliable because URLs from code hosting sites include the file extension
local extToLang = {
  -- Common
  lua = "lua",
  py = "python",
  rb = "ruby",
  js = "javascript",
  ts = "typescript",
  tsx = "tsx",
  jsx = "jsx",
  ex = "elixir",
  exs = "elixir",
  rs = "rust",
  go = "go",
  sh = "bash",
  zsh = "zsh",
  fish = "fish",
  nix = "nix",
  md = "markdown",
  json = "json",
  yaml = "yaml",
  yml = "yaml",
  toml = "toml",
  html = "html",
  css = "css",
  scss = "scss",
  sql = "sql",
  swift = "swift",
  kt = "kotlin",
  java = "java",
  c = "c",
  cpp = "cpp",
  h = "c",
  hpp = "cpp",
  cs = "csharp",
  hs = "haskell",
  erl = "erlang",
  clj = "clojure",
  vim = "vim",
  zig = "zig",
  dart = "dart",
  svelte = "svelte",
  vue = "vue",
  heex = "heex",
}

-- Documentation domain to language mapping
-- Most doc sites are language-specific, so domain → language is reliable
local domainToLang = {
  ["hexdocs.pm"] = "elixir",
  ["elixir-lang.org"] = "elixir",
  ["docs.python.org"] = "python",
  ["doc.rust-lang.org"] = "rust",
  ["docs.rs"] = "rust",
  ["pkg.go.dev"] = "go",
  ["go.dev"] = "go",
  ["developer.apple.com"] = "swift",
  ["kotlinlang.org"] = "kotlin",
  ["ruby-doc.org"] = "ruby",
  ["npmjs.com"] = "javascript",
  ["nodejs.org"] = "javascript",
  ["deno.land"] = "typescript",
  ["typescriptlang.org"] = "typescript",
  ["lua.org"] = "lua",
  ["luarocks.org"] = "lua",
  ["haskell.org"] = "haskell",
  ["clojure.org"] = "clojure",
  ["ziglang.org"] = "zig",
  ["svelte.dev"] = "svelte",
  ["vuejs.org"] = "vue",
  ["react.dev"] = "javascript",
}

--- Detect programming language from text content and context
--- Priority: nvim filetype > URL extension > domain hint > code fence > shebang
---@param text string|nil Selected text
---@param url string|nil Source URL (for hints)
---@param filetype string|nil Known filetype (from nvim)
---@return string|nil Language identifier
function M.detectLanguage(text, url, filetype)
  -- 1. nvim filetype (highest confidence - treesitter knows best)
  if filetype and filetype ~= "" then return filetype end

  -- 2. URL-based detection (reliable for code hosting sites)
  if url then
    -- Git forges: extract file extension from blob/src URLs
    local ext = url:match("github%.com/.+/blob/.+%.(%w+)$")
      or url:match("gitlab%.com/.+/%-/blob/.+%.(%w+)$")
      or url:match("bitbucket%.org/.+/src/.+%.(%w+)$")
      or url:match("codeberg%.org/.+/src/.+%.(%w+)$")
      or url:match("sr%.ht/.+/tree/.+%.(%w+)$")
      or url:match("raw%.githubusercontent%.com/.+%.(%w+)$")
    if ext and extToLang[ext:lower()] then return extToLang[ext:lower()] end

    -- Domain-based hints (doc sites are language-specific)
    local domain = url:match("https?://([^/]+)")
    if domain then
      domain = domain:gsub("^www%.", "")
      if domainToLang[domain] then return domainToLang[domain] end
      -- MDN: inspect path for web technology
      if domain:match("developer%.mozilla%.org") then
        if url:match("/JavaScript/") or url:match("/js/") then return "javascript" end
        if url:match("/CSS/") then return "css" end
        if url:match("/HTML/") then return "html" end
      end
    end
  end

  -- 3. Content-based detection (minimal, high-confidence patterns only)
  if text and text ~= "" then
    -- Code fence language hint (explicit, highest confidence for content)
    local fenceLang = text:match("^%s*```(%w+)")
    if fenceLang and fenceLang ~= "" then
      local aliases =
        { js = "javascript", ts = "typescript", py = "python", rb = "ruby", ex = "elixir", rs = "rust", sh = "bash" }
      return aliases[fenceLang:lower()] or fenceLang:lower()
    end

    -- Shebang (explicit, unambiguous)
    local shebang = text:match("^#!.-/([%w]+)")
    if shebang then
      local shebangMap = {
        python = "python",
        python3 = "python",
        ruby = "ruby",
        bash = "bash",
        zsh = "zsh",
        sh = "bash",
        fish = "fish",
        node = "javascript",
        perl = "perl",
      }
      if shebangMap[shebang] then return shebangMap[shebang] end
      -- env-style: #!/usr/bin/env python
      local envLang = text:match("^#!.-env%s+(%w+)")
      if envLang and shebangMap[envLang] then return shebangMap[envLang] end
    end
  end

  -- Unknown - and that's okay. Better to return nil than guess wrong.
  return nil
end

--------------------------------------------------------------------------------
-- MAIN CONTEXT GATHERING
--------------------------------------------------------------------------------

---@class CaptureContext
---@field appType "browser"|"terminal"|"neovim"|"other"
---@field appName string
---@field bundleID string
---@field windowTitle string|nil
---@field url string|nil
---@field filePath string|nil
---@field filetype string|nil
---@field selection string|nil
---@field detectedLanguage string|nil
---@field line number|nil
---@field col number|nil

--- Gather context from the frontmost application
---@return CaptureContext
function M.getContext()
  local app = hs.application.frontmostApplication()
  local appType = detectAppType(app)

  local context = {
    appType = appType,
    appName = app and app:name() or "Unknown",
    bundleID = app and app:bundleID() or "",
    windowTitle = nil,
    url = nil,
    filePath = nil,
    filetype = nil,
    selection = nil,
    detectedLanguage = nil,
    line = nil,
    col = nil,
  }

  -- Get window title via AX
  if app then
    local axApp = hs.axuielement.applicationElement(app)
    if axApp then
      local win = axApp:attributeValue("AXFocusedWindow")
      if win then context.windowTitle = win:attributeValue("AXTitle") end
    end
  end

  -- Gather type-specific context
  if appType == "browser" then
    local browserCtx = getBrowserContext(app)
    if browserCtx then
      context.url = browserCtx.url
      context.windowTitle = browserCtx.title or context.windowTitle
      context.selection = browserCtx.selection
    end
  elseif appType == "terminal" then
    -- Check if there's an nvim instance in the current tmux pane
    local nvimCtx = getNeovimContext()
    if nvimCtx then
      context.appType = "neovim" -- Upgrade type
      context.filePath = nvimCtx.path
      context.filetype = nvimCtx.filetype
      context.selection = nvimCtx.selection
      context.line = nvimCtx.line
      context.col = nvimCtx.col
    end
  end

  -- Fallback: try Accessibility-based selection if we don't have one
  -- This is clipboard-free and works well for native macOS apps
  if not context.selection or context.selection == "" then
    local axSelection, axUrl = getSelectionViaAccessibility()
    context.selection = axSelection
    -- Also use URL from AX if we don't have one (useful for non-JXA browsers)
    if axUrl and (not context.url or context.url == "") then context.url = axUrl end
  end

  -- Detect language
  context.detectedLanguage = M.detectLanguage(context.selection, context.url, context.filetype)

  return context
end

return M
