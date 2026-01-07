-- Notes Capture Library
-- Utilities for managing assets and cleanup in Obsidian vault
--
-- Note: Note creation is now handled by obsidian.nvim via templates.
-- This library provides:
--   - Path constants for vault directories
--   - Image asset management (copy to vault)
--   - Cleanup utilities (delete from DO Spaces, local screenshots)
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

return M
