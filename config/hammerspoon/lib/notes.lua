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

--- Generate capture note filename
---@param title? string Optional title (defaults to "capture")
---@return string filename Without extension
---@return string timestamp HH:MM format for daily note link
function M.generateCaptureName(title)
  local now = os.date("*t")
  local dateStr = fmt("%04d%02d%02d", now.year, now.month, now.day)
  local timeStr = fmt("%02d%02d", now.hour, now.min)
  local timestamp = fmt("%02d:%02d", now.hour, now.min)

  title = title or "capture"
  -- Sanitize title for filename
  title = title:lower():gsub("%s+", "-"):gsub("[^a-z0-9%-]", "")
  if title == "" then title = "capture" end

  local filename = fmt("%s-%s-%s", dateStr, timeStr, title)
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
---@param imageFilename string Image filename for thumbnail
---@param timestamp string HH:MM timestamp
---@return boolean success
function M.appendToDailyNote(captureFilename, imageFilename, timestamp)
  if not M.ensureDailyNote() then
    return false
  end

  local dailyPath = M.getDailyNotePath()

  -- Read existing content
  local f = io.open(dailyPath, "r")
  if not f then return false end
  local content = f:read("*a")
  f:close()

  -- Build the capture entry
  local entry = fmt("\n- %s [[%s]]\n  ![[%s|200]]\n", timestamp, captureFilename, imageFilename)

  -- Check if ## Captures section exists
  local capturesSection = "## Captures"
  local capturesPos = content:find(capturesSection, 1, true)

  if capturesPos then
    -- Find the end of the Captures section (next ## or end of file)
    local nextSectionPos = content:find("\n## ", capturesPos + #capturesSection)
    if nextSectionPos then
      -- Insert before next section
      content = content:sub(1, nextSectionPos - 1) .. entry .. content:sub(nextSectionPos)
    else
      -- Append to end of file
      content = content .. entry
    end
  else
    -- Add Captures section at end
    content = content .. "\n" .. capturesSection .. "\n" .. entry
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
  if not M.appendToDailyNote(captureFilename, imageFilename, timestamp) then
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
  if not M.appendToDailyNote(captureFilename, imageFilename, timestamp) then
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
  -- Generate filename
  local captureFilename, timestamp = M.generateCaptureName("text")
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

  -- Only add source info if there's actual selected content
  if hasSelection then
    local source = context.appType or "other"
    -- Don't add source: other, it's meaningless
    if source ~= "other" then
      frontmatter = frontmatter .. fmt("source: %s\n", source)
    end
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
