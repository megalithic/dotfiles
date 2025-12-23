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
      if doc and doc:match("^https?://") then
        return "browser"
      end
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
      script = fmt([[
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
      ]], browser.name)
    end

    local ok, result = hs.osascript.javascript(script)
    if ok and result then
      return result
    end
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
-- CLIPBOARD SELECTION FALLBACK
--------------------------------------------------------------------------------

--- Get selected text via clipboard (⌘C, read, restore)
---@return string|nil
local function getSelectionViaClipboard()
  -- Save current clipboard
  local savedClipboard = hs.pasteboard.getContents()

  -- Send Cmd+C to copy selection
  hs.eventtap.keyStroke({ "cmd" }, "c", 50000) -- 50ms

  -- Small delay for clipboard to update
  hs.timer.usleep(100000) -- 100ms

  -- Get new clipboard content
  local selectedText = hs.pasteboard.getContents()

  -- Restore original clipboard
  if savedClipboard then
    hs.pasteboard.setContents(savedClipboard)
  else
    hs.pasteboard.clearContents()
  end

  -- Check if we got something new
  if selectedText and selectedText ~= savedClipboard then
    return selectedText
  end

  return nil
end

--------------------------------------------------------------------------------
-- LANGUAGE DETECTION
--------------------------------------------------------------------------------

--- Detect programming language from text content and context
---@param text string|nil Selected text
---@param url string|nil Source URL (for hints)
---@param filetype string|nil Known filetype (from nvim)
---@return string|nil Language identifier
function M.detectLanguage(text, url, filetype)
  -- If we have filetype from nvim, use it directly
  if filetype and filetype ~= "" then
    return filetype
  end

  -- URL-based hints (highest confidence for web sources)
  if url then
    -- GitHub file extensions
    local ext = url:match("github%.com/.-/.-/blob/.-%.(%w+)")
    if ext then
      local extMap = {
        lua = "lua", py = "python", rb = "ruby", js = "javascript",
        ts = "typescript", tsx = "tsx", jsx = "jsx", ex = "elixir",
        exs = "elixir", rs = "rust", go = "go", sh = "bash",
        zsh = "zsh", fish = "fish", nix = "nix", md = "markdown",
        json = "json", yaml = "yaml", yml = "yaml", toml = "toml",
        html = "html", css = "css", scss = "scss", sql = "sql",
        swift = "swift", kt = "kotlin", java = "java", c = "c",
        cpp = "cpp", h = "c", hpp = "cpp", cs = "csharp",
      }
      if extMap[ext] then return extMap[ext] end
    end

    -- Domain hints
    if url:match("hexdocs%.pm") then return "elixir" end
    if url:match("docs%.python%.org") then return "python" end
    if url:match("doc%.rust%-lang%.org") then return "rust" end
    if url:match("pkg%.go%.dev") then return "go" end
    if url:match("developer%.apple%.com") then return "swift" end
    if url:match("kotlinlang%.org") then return "kotlin" end
  end

  -- Content-based heuristics (fallback)
  if text and text ~= "" then
    local firstLines = text:sub(1, 500) -- Check first 500 chars

    local patterns = {
      { "^%s*defmodule%s+", "elixir" },
      { "^%s*defp?%s+%w+", "elixir" },
      { "|>", "elixir" }, -- pipe operator common in elixir
      { "^%s*def%s+%w+.-:", "python" },
      { "^%s*import%s+%w+", "python" },
      { "^%s*from%s+%w+%s+import", "python" },
      { "^%s*fn%s+%w+", "rust" },
      { "^%s*let%s+mut%s+", "rust" },
      { "^%s*func%s+%w+", "go" },
      { "^%s*package%s+%w+", "go" },
      { "^%s*local%s+function", "lua" },
      { "^%s*function%s+%w+", "lua" },
      { "^%s*const%s+%w+%s*=", "javascript" },
      { "^%s*let%s+%w+%s*=", "javascript" },
      { "^%s*import%s+{", "javascript" },
      { "^%s*export%s+", "javascript" },
      { "^%s*interface%s+%w+", "typescript" },
      { "^%s*type%s+%w+%s*=", "typescript" },
      { "<%w+[^>]*>", "html" },
      { "^%s*{%s*\n", "json" },
      { "^#!.-/bin/bash", "bash" },
      { "^#!.-/bin/zsh", "zsh" },
      { "^#!.-/bin/fish", "fish" },
      { "^%s*{.-=%s*{", "nix" }, -- nix attribute set pattern
    }

    for _, p in ipairs(patterns) do
      if firstLines:match(p[1]) then return p[2] end
    end
  end

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
      if win then
        context.windowTitle = win:attributeValue("AXTitle")
      end
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

  -- Fallback: try clipboard selection if we don't have one
  if not context.selection or context.selection == "" then
    context.selection = getSelectionViaClipboard()
  end

  -- Detect language
  context.detectedLanguage = M.detectLanguage(
    context.selection,
    context.url,
    context.filetype
  )

  return context
end

return M
