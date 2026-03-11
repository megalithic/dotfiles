-- after/plugin/notes.lua
-- Task management, Shade integration, and markdown utilities
--
-- Commands:
--   :NotesToggleTask [status]  - Toggle task checkbox
--   :NotesSortTasks            - Sort tasks by priority
--   :NotesSyncTags             - Sync body tags to frontmatter
--
-- Keymaps (markdown buffers):
--   <C-x>d      - Mark task done [x]
--   <C-x>t      - Mark task todo [-]
--   <C-x>s      - Mark task started [.]
--   <C-x>u      - Mark task skipped [/]
--   <C-x><C-x>  - Clear task [ ]
--
-- Shade integration:
--   - Detects <!-- shade:pending:* --> placeholders
--   - Shows virtual text "⏳ Processing..." while Shade MLX runs
--   - Auto-syncs body **Tags:** to frontmatter on save
--
-- Shade processing indicator options (current: A):
--   A) nvim-side placeholder detection + virtual text (implemented)
--      - No Shade changes, works now, simple
--   B) Shade RPC notifications (User autocmd ShadeEnrichmentStarted/Finished)
--      - More reliable, requires Shade changes
--   C) Animated spinner with timer
--      - Enhancement to A, uses vim.uv.new_timer() for animation

if not Plugin_enabled() then return end

local M = {}
mega.p.notes = M

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

return M
