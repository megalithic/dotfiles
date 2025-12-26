-- Notes Capture Library
-- Utilities for capturing screenshots and text to Obsidian vault
--
local M = {}
local fmt = string.format

-- Paths (using environment variables with iCloud fallback)
-- Hammerspoon doesn't inherit shell env vars, so we check common locations
M.notesHome = os.getenv("NOTES_HOME")
  or (os.getenv("HOME") .. "/iclouddrive/Documents/_notes")  -- iCloud path
  or (os.getenv("HOME") .. "/notes")  -- fallback
M.assetsDir = M.notesHome .. "/assets"
M.capturesDir = M.notesHome .. "/captures"
M.dailyBaseDir = M.notesHome .. "/daily"

--------------------------------------------------------------------------------
-- PATH HELPERS
--------------------------------------------------------------------------------

--- Sanitize string for use in filename
---@param str string
---@param maxLen? number Maximum length (default 30)
---@return string sanitized
local function sanitize_for_filename(str, maxLen)
  if not str or str == "" then return "" end
  maxLen = maxLen or 30

  local result = str:lower()
    :gsub("[%.:/]", "-")        -- dots/colons/slashes to dashes (preserve structure)
    :gsub("%s+", "-")           -- spaces to dashes
    :gsub("[^a-z0-9%-]", "")    -- remove non-alphanumeric
    :gsub("%-+", "-")           -- collapse multiple dashes
    :gsub("^%-", "")            -- trim leading dash
    :gsub("%-$", "")            -- trim trailing dash

  -- Truncate at word boundary if too long
  if #result > maxLen then
    result = result:sub(1, maxLen):gsub("%-[^%-]*$", "")
  end

  return result
end

--- Extract meaningful snippet from window title
--- Removes common suffixes like "- Google Chrome", app names, etc.
---@param windowTitle string|nil
---@return string|nil snippet 2-3 word snippet or nil
local function extract_title_snippet(windowTitle)
  if not windowTitle or windowTitle == "" then return nil end

  -- Remove common browser/app suffixes
  local cleaned = windowTitle
    :gsub("%s*[%-–—|·]%s*[A-Z][%w%s]*$", "")  -- " - App Name" or " | App"
    :gsub("%s*[%-–—]%s*[A-Z][%w]*%s*[A-Z][%w]*$", "")  -- " - Two Words"
    :gsub("^https?://[^/]+/", "")  -- leading URLs
    :gsub("^www%.", "")

  -- Take first 2-3 meaningful words only
  local words = {}
  for word in cleaned:gmatch("%S+") do
    if #words < 3 and #word > 1 then
      table.insert(words, word)
    end
  end

  if #words == 0 then return nil end

  local snippet = table.concat(words, " ")
  local sanitized = sanitize_for_filename(snippet, 25)

  -- Only return if we got something meaningful (at least 3 chars)
  return (#sanitized >= 3) and sanitized or nil
end

--- Extract domain from URL
---@param url string|nil
---@return string|nil domain without www prefix
local function extract_domain(url)
  if not url then return nil end
  local domain = url:match("https?://([^/]+)")
  if domain then
    domain = domain:gsub("^www%.", "")
    -- Just first part of domain (github.com -> github)
    local short = domain:match("^([^%.]+)")
    return short
  end
  return nil
end

--- Generate capture note filename
---@param titleOrContext? string|table Optional title string or context table
---@return string filename Without extension
---@return string timestamp HH:MM format for daily note link
function M.generateCaptureName(titleOrContext)
  local now = os.date("*t")
  local dateStr = fmt("%04d%02d%02d", now.year, now.month, now.day)
  local timeStr = fmt("%02d%02d", now.hour, now.min)
  local timestamp = fmt("%02d:%02d", now.hour, now.min)

  local descriptor = "capture"

  if type(titleOrContext) == "string" then
    -- Simple string title (backward compatible)
    descriptor = sanitize_for_filename(titleOrContext)
  elseif type(titleOrContext) == "table" then
    -- Full context object - build smart descriptor
    local ctx = titleOrContext

    -- Priority 1: Window title snippet
    local snippet = extract_title_snippet(ctx.windowTitle)
    if snippet then
      descriptor = snippet
    else
      -- Priority 2: Domain + language
      local domain = extract_domain(ctx.url)
      local lang = ctx.detectedLanguage or ctx.filetype

      if domain and lang then
        descriptor = fmt("%s-%s", domain, sanitize_for_filename(lang))
      elseif domain then
        descriptor = domain
      elseif lang then
        descriptor = sanitize_for_filename(lang)
      -- Priority 3: App type (if not "other")
      elseif ctx.appType and ctx.appType ~= "other" then
        descriptor = ctx.appType
      else
        descriptor = "text"
      end
    end
  end

  if descriptor == "" then descriptor = "capture" end

  local filename = fmt("%s-%s-%s", dateStr, timeStr, descriptor)
  return filename, timestamp
end

--- Get today's daily note path
--- Structure: daily/YYYY/YYYYMMDD.md (year folder, no dashes in filename)
---@return string path Full path to daily note
function M.getDailyNotePath()
  local year = os.date("%Y")
  local dateStr = os.date("%Y%m%d")
  return fmt("%s/%s/%s.md", M.dailyBaseDir, year, dateStr)
end

--- Get daily note directory for today
---@return string path Directory containing today's daily note
function M.getDailyNoteDir()
  local year = os.date("%Y")
  return fmt("%s/%s", M.dailyBaseDir, year)
end

--- Get capture note path
---@param filename string Filename without extension
---@return string path Full path to capture note
function M.getCaptureNotePath(filename)
  return fmt("%s/%s.md", M.capturesDir, filename)
end

--- Get asset path for an image
---@param filename string Image filename (with extension)
---@return string path Full path in assets directory
function M.getAssetPath(filename)
  return fmt("%s/%s", M.assetsDir, filename)
end

--------------------------------------------------------------------------------
-- FILE OPERATIONS
--------------------------------------------------------------------------------

--- Ensure a directory exists
---@param path string Directory path
---@return boolean success
function M.ensureDir(path)
  local result = os.execute(fmt("mkdir -p '%s'", path))
  return result == 0 or result == true
end

--- Copy image to assets folder with new name
---@param sourcePath string Source image path
---@param destFilename string Destination filename (just name, not full path)
---@return string|nil destPath Full path if successful, nil on failure
function M.copyImageToAssets(sourcePath, destFilename)
  if not M.ensureDir(M.assetsDir) then
    return nil
  end

  local destPath = M.getAssetPath(destFilename)
  local result = os.execute(fmt("cp '%s' '%s'", sourcePath, destPath))

  if result == 0 or result == true then
    return destPath
  end
  return nil
end

--- Delete file from DO Spaces (async with callback)
---@param imageUrl string Full CDN URL of the image
---@param callback? fun(success: boolean, err?: string) Optional completion callback
function M.deleteFromSpaces(imageUrl, callback)
  if not imageUrl or imageUrl == "" then
    if callback then callback(true) end
    return
  end

  -- Extract the path from the URL (e.g., screenshots/20241223_1405_0001.png)
  local path = imageUrl:match("/screenshots/(.+)$")
  if not path then
    if callback then callback(false, "Could not parse image path from URL") end
    return
  end

  -- Build delete command using capper's env var pattern
  local envPath = fmt("%s/agenix/env-vars", os.getenv("DARWIN_USER_TEMP_DIR") or "/tmp")
  local cmd = fmt(
    [[source '%s' 2>/dev/null; s3cmd --access_key="$DO_SPACES_CAPS_KEY" \
      --secret_key="$DO_SPACES_CAPS_SECRET" \
      --host="${DO_SPACES_CAPS_REGION}.digitaloceanspaces.com" \
      --host-bucket='%%(bucket)s.'"${DO_SPACES_CAPS_REGION}"'.digitaloceanspaces.com' \
      del "s3://${DO_SPACES_CAPS_SPACE}/screenshots/%s"]],
    envPath, path
  )

  -- Run async with hs.task
  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
    local success = exitCode == 0
    if success then
      hs.printf("[notes] Deleted from DO Spaces: %s", path)
    else
      hs.printf("[notes] Failed to delete from DO Spaces: %s (exit %d)", stdErr or "unknown", exitCode)
    end
    if callback then callback(success, stdErr) end
  end, { "-c", cmd })

  if task then
    task:start()
  elseif callback then
    callback(false, "Failed to create task")
  end
end

--- Delete local screenshot file
---@param imagePath string Full path to local image
---@return boolean success
function M.deleteLocalScreenshot(imagePath)
  if not imagePath or imagePath == "" then return true end

  -- Safety check: only delete from screenshots directory
  local screenshotsDir = os.getenv("HOME") .. "/_screenshots"
  if not imagePath:find(screenshotsDir, 1, true) then
    return false -- Don't delete files outside screenshots dir
  end

  local result = os.execute(fmt("rm -f '%s'", imagePath))
  return result == 0 or result == true
end

--------------------------------------------------------------------------------
-- NOTE CREATION
--------------------------------------------------------------------------------

--- Create capture note with frontmatter and image embed
---@param filename string Note filename (without .md)
---@param imageFilename string Image filename in assets
---@param opts? {title?: string, tags?: string[], ocr?: string} Options
---@return boolean success
function M.createCaptureNote(filename, imageFilename, opts)
  opts = opts or {}
  local notePath = M.getCaptureNotePath(filename)

  if not M.ensureDir(M.capturesDir) then
    return false
  end

  local title = opts.title or "Capture"
  local tags = opts.tags or { "capture/quick" }
  local tagsStr = table.concat(tags, ", ")

  local now = os.date("%Y-%m-%dT%H:%M:%S")

  local content = fmt(
    "---\ntitle: \"%s\"\ncreated: %s\ntags: [%s]\n---\n\n![[%s]]\n",
    title, now, tagsStr, imageFilename
  )

  -- Add OCR section if provided
  if opts.ocr and opts.ocr ~= "" then
    content = content .. fmt("\n## OCR Text\n\n%s\n", opts.ocr)
  end

  local f = io.open(notePath, "w")
  if not f then return false end
  f:write(content)
  f:close()

  return true
end

--------------------------------------------------------------------------------
-- DAILY NOTE INTEGRATION
--------------------------------------------------------------------------------

--- Ensure daily note exists (creates via daily_note -s if missing)
--- Uses the daily_note script's -s flag for silent creation with full template
--- (includes task migration from previous day, links section, etc.)
---@return boolean exists
function M.ensureDailyNote()
  local dailyPath = M.getDailyNotePath()

  -- Check if it exists
  local f = io.open(dailyPath, "r")
  if f then
    f:close()
    return true
  end

  -- Create using daily_note script with -s flag (silent mode, no editor)
  local dailyNoteScript = os.getenv("HOME") .. "/.dotfiles/bin/daily_note"
  os.execute(fmt("'%s' -s 2>/dev/null", dailyNoteScript))

  -- Verify it was created
  f = io.open(dailyPath, "r")
  if f then
    f:close()
    return true
  end

  return false
end

--- Append capture link to daily note's ## Captures section
---@param captureFilename string Capture note filename (without .md)
---@param timestamp string HH:MM timestamp
---@return boolean success
function M.appendToDailyNote(captureFilename, timestamp)
  if not M.ensureDailyNote() then
    return false
  end

  local dailyPath = M.getDailyNotePath()

  -- Read existing content
  local f = io.open(dailyPath, "r")
  if not f then return false end
  local content = f:read("*a")
  f:close()

  -- Build the capture entry (image capture: just the note link)
  -- The image embed is handled by obsidian.nvim in the capture note itself
  local entry = fmt("- %s [[%s]]", timestamp, captureFilename)

  -- Check if ## Captures section exists
  local capturesSection = "## Captures"
  local capturesPos = content:find(capturesSection, 1, true)

  if capturesPos then
    -- Find the end of the Captures section (next ## or end of file)
    local nextSectionPos = content:find("\n## ", capturesPos + #capturesSection)
    if nextSectionPos then
      -- Insert before next section, ensure single newline separation
      local before = content:sub(1, nextSectionPos - 1):gsub("%s+$", "")
      content = before .. "\n" .. entry .. "\n" .. content:sub(nextSectionPos + 1)
    else
      -- Append to end, ensure single newline before entry
      content = content:gsub("%s+$", "") .. "\n" .. entry .. "\n"
    end
  else
    -- Add Captures section at end
    content = content:gsub("%s+$", "") .. "\n\n" .. capturesSection .. "\n\n" .. entry .. "\n"
  end

  -- Write back
  f = io.open(dailyPath, "w")
  if not f then return false end
  f:write(content)
  f:close()

  return true
end

--------------------------------------------------------------------------------
-- HIGH-LEVEL CAPTURE FUNCTIONS
--------------------------------------------------------------------------------

--- Perform quick capture: copy image to vault, create note, link in daily
--- Fire-and-forget mode - no editor interaction
---@param imagePath string Source image path
---@param imageUrl? string DO Spaces URL (for deletion)
---@return boolean success
---@return string? error Error message if failed
function M.captureQuick(imagePath, imageUrl)
  -- Generate names
  local captureFilename, timestamp = M.generateCaptureName()
  local imageExt = imagePath:match("%.(%w+)$") or "png"
  local imageFilename = captureFilename .. "." .. imageExt

  -- 1. Copy image to assets
  local assetPath = M.copyImageToAssets(imagePath, imageFilename)
  if not assetPath then
    return false, "Failed to copy image to assets"
  end

  -- 2. Create capture note
  if not M.createCaptureNote(captureFilename, imageFilename, { tags = { "capture/quick" } }) then
    return false, "Failed to create capture note"
  end

  -- 3. Append to daily note
  if not M.appendToDailyNote(captureFilename, timestamp) then
    return false, "Failed to update daily note"
  end

  -- 4. Cleanup: delete from DO Spaces
  if imageUrl then
    M.deleteFromSpaces(imageUrl)
  end

  -- 5. Cleanup: delete local screenshot
  M.deleteLocalScreenshot(imagePath)

  return true
end

--- Perform full capture: copy image to vault, create note with title
--- Interactive mode - returns filename for editor to open
---@param imagePath string Source image path
---@param imageUrl? string DO Spaces URL (for deletion)
---@param title? string Optional title for the note
---@return boolean success
---@return string? captureFilename Filename if successful
---@return string? error Error message if failed
function M.captureFull(imagePath, imageUrl, title)
  -- Generate names
  local captureFilename, timestamp = M.generateCaptureName(title)
  local imageExt = imagePath:match("%.(%w+)$") or "png"
  local imageFilename = captureFilename .. "." .. imageExt

  -- 1. Copy image to assets
  local assetPath = M.copyImageToAssets(imagePath, imageFilename)
  if not assetPath then
    return false, nil, "Failed to copy image to assets"
  end

  -- 2. Create capture note
  if not M.createCaptureNote(captureFilename, imageFilename, {
    title = title or "Capture",
    tags = { "capture/full" },
  }) then
    return false, nil, "Failed to create capture note"
  end

  -- 3. Append to daily note
  if not M.appendToDailyNote(captureFilename, timestamp) then
    return false, nil, "Failed to update daily note"
  end

  -- 4. Cleanup: delete from DO Spaces
  if imageUrl then
    M.deleteFromSpaces(imageUrl)
  end

  -- 5. Cleanup: delete local screenshot
  M.deleteLocalScreenshot(imagePath)

  return true, captureFilename
end

--------------------------------------------------------------------------------
-- TEXT CAPTURE
--------------------------------------------------------------------------------

---@class TextCaptureContext
---@field appType "browser"|"terminal"|"neovim"|"other"
---@field appName string
---@field windowTitle string|nil
---@field url string|nil
---@field filePath string|nil
---@field filetype string|nil
---@field selection string|nil
---@field detectedLanguage string|nil

--- Create a text capture note with context
---@param context TextCaptureContext Context from lib/interop/context.lua
---@return boolean success
---@return string? notePath Full path if successful
---@return string? error Error message if failed
function M.createTextCaptureNote(context)
  -- Generate filename from context (window title, url, language, etc.)
  local captureFilename, timestamp = M.generateCaptureName(context)
  local notePath = M.getCaptureNotePath(captureFilename)

  if not M.ensureDir(M.capturesDir) then
    return false, nil, "Failed to create captures directory"
  end

  -- Build frontmatter
  local now = os.date("%Y-%m-%dT%H:%M:%S")
  local tags = { "capture/text" }
  local hasSelection = context.selection and context.selection ~= ""

  -- Start frontmatter
  local frontmatter = fmt("---\ncreated: %s\ntags: [%s]\n", now, table.concat(tags, ", "))

  -- Add source info (always include app/window for context, other fields only with selection)
  local source = context.appType or "other"
  if source ~= "other" then
    frontmatter = frontmatter .. fmt("source: %s\n", source)
  end
  if context.appName and context.appName ~= "" then
    frontmatter = frontmatter .. fmt("source_app: %s\n", context.appName)
  end
  if context.windowTitle and context.windowTitle ~= "" then
    -- Escape quotes in window title for YAML
    local title = context.windowTitle:gsub('"', '\\"')
    frontmatter = frontmatter .. fmt('source_window: "%s"\n', title)
  end

  -- Additional source info only when there's selected content
  if hasSelection then
    if context.url then
      frontmatter = frontmatter .. fmt("source_url: %s\n", context.url)
    end
    if context.filePath then
      frontmatter = frontmatter .. fmt("source_file: %s\n", context.filePath)
    end
    if context.detectedLanguage then
      frontmatter = frontmatter .. fmt("source_lang: %s\n", context.detectedLanguage)
    end
  end

  frontmatter = frontmatter .. "---\n\n"

  -- Build content: frontmatter + optional selection + blank space for typing
  local content = frontmatter

  -- Add selection as code block if present
  if hasSelection then
    local lang = context.detectedLanguage or ""
    content = content .. fmt("```%s\n%s\n```\n\n", lang, context.selection)
  end

  -- That's it - no title placeholder, no ## Notes section
  -- Just blank space ready for typing

  -- Write the file
  local f = io.open(notePath, "w")
  if not f then
    return false, nil, "Failed to write capture note"
  end
  f:write(content)
  f:close()

  -- NOTE: Daily note linking now happens on SAVE via nvim autocmd
  -- This prevents empty/abandoned captures from cluttering the daily note

  return true, notePath, captureFilename
end

return M
