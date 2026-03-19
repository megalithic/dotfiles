-- after/plugin/notes.lua
-- Task management, Shade integration, capture linking, and markdown utilities
--
-- Commands:
--   :NotesToggleTask [status]  - Toggle task checkbox
--   :NotesSortTasks            - Sort tasks by priority
--   :NotesSyncTags             - Sync body tags to frontmatter
--   :NotesIndexCaptures [date] - Reindex captures into daily note (YYYYMMDD)
--   :NotesLinkCapture          - Manually link current capture to its daily note
--
-- Keymaps (markdown buffers):
--   <C-x>d      - Mark task done [x]
--   <C-x>t      - Mark task todo [-]
--   <C-x>s      - Mark task started [.]
--   <C-x>u      - Mark task skipped [/]
--   <C-x><C-x>  - Clear task [ ]
--
-- Auto-linking:
--   - On save, captures are auto-linked to same-day daily notes
--   - Links appear in ## Captures section (created if missing)
--   - Format: - HH:MM [[filename|description]]
--
-- Shade integration:
--   - Detects <!-- shade:pending:* --> placeholders
--   - Shows virtual text "⏳ Processing..." while Shade MLX runs
--   - Auto-syncs body **Tags:** to frontmatter on save

if not Plugin_enabled() then return end

local M = {}
mega.p.notes = M

-- Lazy-load capture module
local capture = nil
local function get_capture()
  if not capture then
    local ok, mod = pcall(require, "notes.capture")
    if ok then capture = mod end
  end
  return capture
end

-- Expose for external use
M.is_capture_note_empty = function(bufnr) return get_capture() and get_capture().is_empty(bufnr) end
M.cleanup_empty_capture = function(filepath, cb) return get_capture() and get_capture().cleanup(filepath, cb) end

-- Expose shade context for statusline
vim.g.shade_context = vim.env.SHADE == "1"

--------------------------------------------------------------------------------
-- Task Management
--------------------------------------------------------------------------------

-- Priority: in-progress (.) > todo (-) > not-started ( ) > other > done (x)
local TASK_PRIORITY = {
  ["."] = 1, -- started/wip
  ["-"] = 2, -- todo
  [" "] = 3, -- not started
  ["/"] = 4, -- skipped
  ["x"] = 5, -- done
}

---Toggle task checkbox status
---@param status string? New status (nil = toggle between ' ' and 'x')
function M.toggle_task(status)
  local line = vim.api.nvim_get_current_line()
  local prefix, box, current_status = line:match("^(%s*[-*] )(%[(.)%])")

  if not prefix or not box then return end

  local new_status
  if not status or status == "" then
    new_status = current_status == "x" and " " or "x"
  else
    new_status = status
  end

  local new_box = string.format("[%s]", new_status)
  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(0, cursor[1] - 1, #prefix, cursor[1] - 1, #prefix + #box, { new_box })
end

---Sort tasks in buffer by status priority
---Handles non-contiguous tasks (tasks scattered through file) by tracking line indices
---NOTE: Does not handle tasks with nested subtasks - subtasks would be orphaned
---@param bufnr number?
---@param lines string[]? Optional pre-read lines (avoids double buffer read)
function M.sort_tasks(bufnr, lines)
  bufnr = bufnr or 0
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Extract tasks with their original line numbers
  local tasks = {}
  for i, line in ipairs(lines) do
    local _, _, status, text = line:match("^(%s*[-*] )(%[(.)%])%s*(.*)")
    if status then
      table.insert(tasks, { line_num = i, line = line, status = status, text = text })
    end
  end

  if #tasks == 0 then return end

  -- Sort tasks by priority, then alphabetically
  local sorted = vim.deepcopy(tasks)
  table.sort(sorted, function(a, b)
    local pa = TASK_PRIORITY[a.status] or 4
    local pb = TASK_PRIORITY[b.status] or 4
    if pa ~= pb then return pa < pb end
    return a.text < b.text
  end)

  -- Check if order actually changed
  local changed = false
  for i, task in ipairs(tasks) do
    if task.line ~= sorted[i].line then
      changed = true
      break
    end
  end

  if not changed then return end

  -- Apply sorted lines back to their original positions
  for i, task in ipairs(tasks) do
    lines[task.line_num] = sorted[i].line
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

--------------------------------------------------------------------------------
-- Shade Processing Indicators
--------------------------------------------------------------------------------

local shade_ns = vim.api.nvim_create_namespace("shade_processing")

---Find Shade placeholder lines in buffer
---@param bufnr number
---@return table[] placeholders { line: number, type: string }
function M.find_shade_placeholders(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local placeholders = {}

  for i, line in ipairs(lines) do
    local ptype = line:match("<!%-%- shade:pending:(%w+) %-%->")
    if ptype then
      table.insert(placeholders, { line = i, type = ptype })
    end
  end

  return placeholders
end

---Update processing indicators (virtual text) for Shade placeholders
---@param bufnr number
---@return boolean has_placeholders
function M.update_shade_indicators(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, shade_ns, 0, -1)

  local placeholders = M.find_shade_placeholders(bufnr)

  for _, p in ipairs(placeholders) do
    vim.api.nvim_buf_set_extmark(bufnr, shade_ns, p.line - 1, 0, {
      virt_text = { { "⏳ Processing " .. p.type .. "...", "Comment" } },
      virt_text_pos = "eol",
    })
  end

  return #placeholders > 0
end

---Check if buffer has pending Shade enrichments
---@param bufnr number?
---@return boolean
function M.has_shade_pending(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return #M.find_shade_placeholders(bufnr) > 0
end

--------------------------------------------------------------------------------
-- Frontmatter Tag Sync
--------------------------------------------------------------------------------

---Parse tags from body **Tags:** line
---@param bufnr number
---@param lines string[]? Optional pre-read lines (avoids buffer read)
---@return string[]? tags
function M.parse_body_tags(bufnr, lines)
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for _, line in ipairs(lines) do
    -- Match **Tags:** #tag1 #tag2 or **Tags:** tag1, tag2
    local tags_str = line:match("^%*%*Tags:%*%*%s*(.+)$")
    if tags_str then
      local tags = {}
      -- Extract #tags or plain words
      for tag in tags_str:gmatch("#?([%w_-]+)") do
        if tag ~= "" then
          table.insert(tags, tag)
        end
      end
      return #tags > 0 and tags or nil
    end
  end

  return nil
end

---Find frontmatter boundaries
---@param lines string[]
---@return number? start_line, number? end_line (1-indexed)
local function find_frontmatter(lines)
  if #lines == 0 or lines[1] ~= "---" then return nil, nil end

  for i = 2, #lines do
    if lines[i] == "---" then
      return 1, i
    end
  end

  return nil, nil
end

---Parse existing frontmatter tags
---@param lines string[]
---@param fm_start number
---@param fm_end number
---@return string[]? tags, number? tags_start_line, number? tags_end_line (1-indexed, inclusive)
local function parse_frontmatter_tags(lines, fm_start, fm_end)
  for i = fm_start + 1, fm_end - 1 do
    local line = lines[i]
    -- Match tags: [tag1, tag2] or tags:\n  - tag1
    local inline_tags = line:match("^tags:%s*%[(.*)%]")
    if inline_tags then
      local tags = {}
      for tag in inline_tags:gmatch("[%w_-]+") do
        table.insert(tags, tag)
      end
      return tags, i, i
    elseif line:match("^tags:%s*$") then
      -- Multi-line format, collect following lines starting with -
      local tags = {}
      local j = i + 1
      while j <= fm_end - 1 and lines[j]:match("^%s*%- ") do
        local tag = lines[j]:match("^%s*%- ([%w_-]+)")
        if tag then table.insert(tags, tag) end
        j = j + 1
      end
      -- Return range: from "tags:" line to last list item (j-1)
      return tags, i, j - 1
    elseif line:match("^tags:%s+[%w_-]") then
      -- Single tag inline: tags: mytag
      local tag = line:match("^tags:%s+([%w_-]+)")
      return { tag }, i, i
    end
  end

  return nil, nil, nil
end

---Sync body **Tags:** to frontmatter tags
---@param bufnr number?
---@param lines string[]? Optional pre-read lines (avoids buffer read)
---@return boolean changed
function M.sync_tags_to_frontmatter(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find body tags (pass lines to avoid double read)
  local body_tags = M.parse_body_tags(bufnr, lines)
  if not body_tags or #body_tags == 0 then return false end

  -- Find frontmatter
  local fm_start, fm_end = find_frontmatter(lines)
  if not fm_start then return false end

  -- Get existing frontmatter tags (with line range for multi-line format)
  local fm_tags, tags_start, tags_end = parse_frontmatter_tags(lines, fm_start, fm_end)
  fm_tags = fm_tags or {}

  -- Merge: add new tags, preserve existing
  local tag_set = {}
  for _, t in ipairs(fm_tags) do tag_set[t] = true end

  local new_tags_added = false
  for _, t in ipairs(body_tags) do
    if not tag_set[t] then
      table.insert(fm_tags, t)
      tag_set[t] = true
      new_tags_added = true
    end
  end

  if not new_tags_added then return false end

  -- Build new tags line (inline format)
  local new_tags_line = "tags: [" .. table.concat(fm_tags, ", ") .. "]"

  if tags_start then
    -- Remove old tags lines (handles multi-line format)
    for _ = tags_start, tags_end do
      table.remove(lines, tags_start)
    end
    -- Insert new single-line format at same position
    table.insert(lines, tags_start, new_tags_line)
  else
    -- Insert before frontmatter end
    table.insert(lines, fm_end, new_tags_line)
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return true
end

--------------------------------------------------------------------------------
-- Capture → Daily Note Linking
--------------------------------------------------------------------------------

--- Get the notes home directory
---@return string
local function get_notes_home()
  return vim.g.notes_path or vim.env.NOTES_HOME or (vim.env.HOME .. "/notes")
end

--- Get path to daily note for a given date
---@param date_str string Date in YYYYMMDD format
---@return string path Full path to daily note
local function get_daily_note_path(date_str)
  local year = date_str:sub(1, 4)
  return string.format("%s/daily/%s/%s.md", get_notes_home(), year, date_str)
end

--- Extract date (YYYYMMDD) from capture filename
---@param filename string Capture filename (e.g., "202601141430-github-pr")
---@return string|nil date Date string or nil if not parseable
local function extract_capture_date(filename)
  return filename:match("^(%d%d%d%d%d%d%d%d)")
end

--- Extract time (HHMM) from capture filename
---@param filename string Capture filename (e.g., "202601141430-github-pr")
---@return string|nil hour, string|nil min
local function extract_capture_time(filename)
  return filename:match("^%d%d%d%d%d%d%d%d(%d%d)(%d%d)")
end

--- Read file content safely
---@param path string File path
---@return string|nil content
local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

--- Write file content safely
---@param path string File path
---@param content string Content to write
---@return boolean success
local function write_file(path, content)
  local f = io.open(path, "w")
  if not f then return false end
  f:write(content)
  f:close()
  return true
end

--- Check if a line is template/skip content for description extraction
---@param trimmed string Trimmed line
---@param state table Mutable state { in_frontmatter, in_code_block, in_callout }
---@return boolean should_skip
local function should_skip_for_description(trimmed, state)
  -- Track frontmatter
  if trimmed == "---" then
    state.in_frontmatter = not state.in_frontmatter
    return true
  end
  if state.in_frontmatter then return true end

  -- Track code blocks
  if trimmed:match("^```") then
    state.in_code_block = not state.in_code_block
    return true
  end
  if state.in_code_block then return true end

  -- Track callouts
  if trimmed:match("^> %[!") or (state.in_callout and trimmed:match("^>")) then
    state.in_callout = trimmed:match("^>") ~= nil
    return true
  else
    state.in_callout = false
  end

  -- Skip empty, headers, images, placeholders
  if trimmed == "" then return true end
  if trimmed:match("^#") then return true end
  if trimmed:match("^!%[") then return true end
  if trimmed:match("^<!%-%-") then return true end

  return false
end

--- Build description for capture link from file content
---@param content string File content
---@return string description
local function build_capture_description(content)
  -- Try to extract title from frontmatter
  local title = content:match("title:%s*[\"']?([^\n\"']+)")
  if title and title ~= "" then return title end

  -- Try first non-template content line
  local state = { in_frontmatter = false, in_code_block = false, in_callout = false }

  for line in content:gmatch("[^\n]+") do
    local trimmed = line:match("^%s*(.-)%s*$") or ""

    if not should_skip_for_description(trimmed, state) then
      -- Found content line
      if #trimmed > 50 then trimmed = trimmed:sub(1, 47) .. "..." end
      return trimmed
    end
  end

  return "Capture"
end

--- Ensure the ## Captures section exists in daily note content
---@param content string Daily note content
---@return string content Updated content with Captures section
---@return number insert_pos Position to insert new entries (line number in original)
local function ensure_captures_section(content)
  local captures_header = "## Captures"
  local captures_pos = content:find(captures_header, 1, true)

  if captures_pos then
    -- Find end of Captures section (next ## or end)
    local section_start = captures_pos + #captures_header
    local next_section = content:find("\n## ", section_start)
    return content, next_section or #content + 1
  end

  -- Add Captures section before ## Links or at end
  local links_pos = content:find("## Links", 1, true)
  if links_pos then
    local before = content:sub(1, links_pos - 1):gsub("%s+$", "")
    local after = content:sub(links_pos)
    return before .. "\n\n" .. captures_header .. "\n\n" .. after, #before + #captures_header + 4
  end

  -- Add at end
  return content:gsub("%s+$", "") .. "\n\n" .. captures_header .. "\n", #content + #captures_header + 3
end

--- Check if capture is already linked in daily note
---@param daily_content string Daily note content
---@param capture_filename string Capture filename (without .md)
---@return boolean
local function is_capture_linked(daily_content, capture_filename)
  local pattern = "%[%[" .. capture_filename:gsub("%-", "%%-") .. "[%]|]"
  return daily_content:match(pattern) ~= nil
end

--- Append a capture link to the daily note
---@param capture_path string Full path to capture file
---@param daily_path string Full path to daily note
---@return boolean success
---@return string|nil error
function M.append_capture_to_daily(capture_path, daily_path)
  -- Extract info from capture
  local capture_filename = vim.fn.fnamemodify(capture_path, ":t:r")
  local hour, min = extract_capture_time(capture_filename)
  local timestamp = (hour and min) and string.format("%s:%s", hour, min) or "??:??"

  -- Read capture content for description
  local capture_content = read_file(capture_path)
  if not capture_content then return false, "Could not read capture" end

  local description = build_capture_description(capture_content)

  -- Read or create daily note
  local daily_content = read_file(daily_path)
  if not daily_content then
    -- Try to create daily note via obsidian.nvim
    -- Note: daily.today() creates the file and returns the Note object
    local ok = pcall(function()
      local daily = require("obsidian.daily")
      daily.today() -- Creates file if missing, returns Note (we don't need to open it)
    end)

    if ok then
      -- Wait briefly for file creation
      vim.wait(200, function() return vim.fn.filereadable(daily_path) == 1 end, 50)
      daily_content = read_file(daily_path)
    end

    if not daily_content then
      return false, "Could not read or create daily note"
    end
  end

  -- Check if already linked
  if is_capture_linked(daily_content, capture_filename) then
    return true, nil -- Already linked, not an error
  end

  -- Ensure Captures section exists
  daily_content = ensure_captures_section(daily_content)

  -- Find where to insert (end of Captures section, before next ##)
  local captures_pos = daily_content:find("## Captures", 1, true)
  if not captures_pos then return false, "Could not find Captures section" end

  local section_start = captures_pos + #"## Captures"
  local next_section = daily_content:find("\n## ", section_start)

  -- Build the link entry
  local entry = string.format("- %s [[%s|%s]]", timestamp, capture_filename, description)

  -- Insert entry
  if next_section then
    local before = daily_content:sub(1, next_section - 1):gsub("%s+$", "")
    local after = daily_content:sub(next_section)
    daily_content = before .. "\n" .. entry .. "\n" .. after
  else
    daily_content = daily_content:gsub("%s+$", "") .. "\n" .. entry .. "\n"
  end

  -- Write back
  if not write_file(daily_path, daily_content) then
    return false, "Could not write daily note"
  end

  return true, nil
end

--- Link current capture to its daily note (same-day only by default)
---@param bufnr number? Buffer number
---@param force boolean? Force link even if not same day
---@return boolean success
---@return string|nil message
function M.link_capture_to_daily(bufnr, force)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)

  -- Must be a capture file
  if not filepath:match("/captures/") then
    return false, "Not a capture file"
  end

  local filename = vim.fn.fnamemodify(filepath, ":t:r")
  local capture_date = extract_capture_date(filename)

  if not capture_date then
    return false, "Could not parse date from filename"
  end

  -- Same-day check (unless forced)
  local today = os.date("%Y%m%d")
  if not force and capture_date ~= today then
    return false, "Capture is from " .. capture_date .. ", not today"
  end

  local daily_path = get_daily_note_path(capture_date)
  local ok, err = M.append_capture_to_daily(filepath, daily_path)

  if ok then
    -- Mark as linked to prevent re-linking on subsequent saves
    vim.b[bufnr].capture_linked = true
    return true, "Linked to daily note"
  end

  return false, err
end

--- Reindex all captures for a given date into the daily note
---@param date_str? string Date in YYYYMMDD format (defaults to today)
---@return number added Count of captures added
---@return number skipped Count of captures already linked
function M.reindex_captures(date_str)
  date_str = date_str or os.date("%Y%m%d")
  local notes_home = get_notes_home()
  local captures_dir = notes_home .. "/captures"
  local daily_path = get_daily_note_path(date_str)

  -- Find all captures for this date
  local pattern = date_str .. "*.md"
  local handle = io.popen(string.format(
    "find '%s' -maxdepth 1 -name '%s' -type f 2>/dev/null | sort",
    captures_dir, pattern
  ))

  if not handle then
    vim.notify("Failed to scan captures directory", vim.log.levels.ERROR)
    return 0, 0
  end

  local captures = {}
  for path in handle:lines() do
    table.insert(captures, path)
  end
  handle:close()

  if #captures == 0 then
    return 0, 0
  end

  local added, skipped = 0, 0

  for _, capture_path in ipairs(captures) do
    local ok, err = M.append_capture_to_daily(capture_path, daily_path)
    if ok and not err then
      added = added + 1
    else
      skipped = skipped + 1
    end
  end

  return added, skipped
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("NotesToggleTask", function(opts)
  M.toggle_task(opts.args)
end, { nargs = "?", desc = "Toggle task checkbox status" })

vim.api.nvim_create_user_command("NotesSortTasks", function()
  M.sort_tasks()
end, { desc = "Sort tasks by priority" })

vim.api.nvim_create_user_command("NotesSyncTags", function()
  if M.sync_tags_to_frontmatter() then
    vim.notify("Tags synced to frontmatter", vim.log.levels.INFO)
  else
    vim.notify("No new tags to sync", vim.log.levels.INFO)
  end
end, { desc = "Sync body tags to frontmatter" })

vim.api.nvim_create_user_command("NotesIndexCaptures", function(opts)
  local date_str = opts.args ~= "" and opts.args or nil
  local added, skipped = M.reindex_captures(date_str)
  local date_display = date_str or os.date("%Y%m%d")
  if added > 0 or skipped > 0 then
    vim.notify(
      string.format("Indexed %s: %d added, %d already linked", date_display, added, skipped),
      vim.log.levels.INFO
    )
  else
    vim.notify(string.format("No captures found for %s", date_display), vim.log.levels.INFO)
  end
end, { nargs = "?", desc = "Index captures into daily note (optional: YYYYMMDD date)" })

vim.api.nvim_create_user_command("NotesLinkCapture", function(opts)
  local force = opts.bang
  local ok, msg = M.link_capture_to_daily(nil, force)
  if ok then
    vim.notify(msg or "Linked to daily note", vim.log.levels.INFO)
  else
    vim.notify(msg or "Failed to link", vim.log.levels.WARN)
  end
end, { bang = true, desc = "Link current capture to daily note (! to force cross-day)" })

--------------------------------------------------------------------------------
-- Autocmds
--------------------------------------------------------------------------------

local augroup = vim.api.nvim_create_augroup("mega.notes", { clear = true })

-- Pre-save processing for obsidian notes
vim.api.nvim_create_autocmd("User", {
  group = augroup,
  pattern = "ObsidianNoteWritePre",
  callback = function(args)
    local bufnr = args.buf
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    -- Read lines once for all operations
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Sort tasks in daily notes
    if filepath:match("/daily/") then
      M.sort_tasks(bufnr, lines)
    end

    -- Sync body tags to frontmatter in capture notes
    if filepath:match("/captures/") then
      M.sync_tags_to_frontmatter(bufnr, lines)
    end
  end,
  desc = "Pre-save processing for obsidian notes",
})

-- Shade placeholder detection: update indicators on buffer changes
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
  group = augroup,
  pattern = "*.md",
  callback = function(args)
    -- Only check notes path buffers (avoid unnecessary work)
    local filepath = vim.api.nvim_buf_get_name(args.buf)
    local notes_path = vim.g.notes_path or "notes"
    -- Use string.find with plain=true to avoid pattern injection
    if not filepath:find(notes_path, 1, true) then return end

    M.update_shade_indicators(args.buf)
  end,
  desc = "Update Shade processing indicators",
})

-- Task keymaps for ALL markdown buffers (including firenvim)
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = "markdown",
  callback = function(args)
    local buf = args.buf
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
    end

    map("<C-x>d", function() M.toggle_task("x") end, "notes: mark done")
    map("<C-x>t", function() M.toggle_task("-") end, "notes: mark todo")
    map("<C-x>s", function() M.toggle_task(".") end, "notes: mark started")
    map("<C-x>u", function() M.toggle_task("/") end, "notes: mark skipped")
    map("<C-x><C-x>", function() M.toggle_task(" ") end, "notes: clear checkbox")
  end,
  desc = "Set up task keymaps for markdown",
})

-- Auto-link captures to daily notes on save (same-day only)
vim.api.nvim_create_autocmd("BufWritePost", {
  group = augroup,
  pattern = "*/captures/*.md",
  callback = function(args)
    local bufnr = args.buf

    -- Skip if already linked this session
    if vim.b[bufnr].capture_linked then return end

    -- Extract date from filename
    local filepath = vim.api.nvim_buf_get_name(bufnr)
    local filename = vim.fn.fnamemodify(filepath, ":t:r")
    local capture_date = extract_capture_date(filename)

    if not capture_date then return end

    -- Only auto-link same-day captures
    local today = os.date("%Y%m%d")
    if capture_date ~= today then return end

    -- Attempt to link (silently on success, warn on failure)
    local ok, err = M.link_capture_to_daily(bufnr, false)
    if ok then
      vim.notify("Linked to daily note", vim.log.levels.DEBUG)
    elseif err and err ~= "Capture is from " .. capture_date .. ", not today" then
      vim.notify("Auto-link failed: " .. (err or "unknown"), vim.log.levels.WARN)
    end
  end,
  desc = "Auto-link captures to daily notes on save",
})

-- Empty capture cleanup on buffer close (when NOT in Shade context)
-- Shade handles this via QuitPre in its own integration
if not vim.g.shade_context then
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    pattern = "*/captures/*.md",
    callback = function(args)
      local cap = get_capture()
      if not cap then return end

      local bufnr = args.buf
      local is_empty, filepath = cap.is_empty(bufnr)

      if is_empty and filepath then
        -- Defer to allow buffer to close first
        vim.defer_fn(function()
          cap.cleanup(filepath)
        end, 100)
      end
    end,
    desc = "Prompt to delete empty capture notes on buffer close",
  })
end

return M
