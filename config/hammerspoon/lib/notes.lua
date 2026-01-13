-- Notes Library
-- Path utilities for Obsidian vault integration
--
-- Note creation and templates are handled by obsidian.nvim.
-- Image capture and processing are handled by Shade.
-- This library provides path constants and file existence helpers.
--
local M = {}
local fmt = string.format

-- Paths (using environment variables with iCloud fallback)
-- Hammerspoon doesn't inherit shell env vars, so we check common locations
M.notesHome = os.getenv("NOTES_HOME")
  or (os.getenv("HOME") .. "/iclouddrive/Documents/_notes")  -- iCloud path
  or (os.getenv("HOME") .. "/notes")  -- fallback
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

--- Ensure daily note file exists (creates empty file if needed)
--- Content is populated by obsidian.nvim templates when opened
---@return boolean success
function M.ensureDailyNote()
  local dir = M.getDailyNoteDir()
  if not M.ensureDir(dir) then
    return false
  end

  local path = M.getDailyNotePath()
  -- Check if file exists
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end

  -- Create empty file (obsidian.nvim will apply template)
  f = io.open(path, "w")
  if f then
    f:close()
    return true
  end
  return false
end

return M
