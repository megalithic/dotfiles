if not mega then return end

local U = require("mega.utils")
local M = {}

function M.format_notes(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local function get_priority_from_status(status)
    if status == "." then
      return 1 -- In-progress
    elseif status == "-" then
      return 2 -- Todo/Up next
    elseif status == " " then
      return 3 -- Not-yet-started
    elseif status == "x" then
      return 5 -- Completed (always last)
    else
      return 4 -- Unknown type of task
    end
  end

  local function extract(lines)
    local tasks = {}

    for i, line in ipairs(lines) do
      local prefix, box, status, task_text = line:match("^(%s*[-*] )(%[(.)%])%s(.*)")
      if prefix ~= nil and box ~= nil and status ~= nil then table.insert(tasks, { index = i, line = line, status = status, text = task_text }) end
    end

    return tasks, tasks[1].index
  end

  local function sort(tasks)
    table.sort(tasks, function(a, b)
      if a.status == b.status then
        return a.text < b.text -- Sort alphabetically if status are the same
      else
        return get_priority_from_status(a.status) < get_priority_from_status(b.status) -- Sort by status
      end
    end)
  end

  local function replace(bufnr, sorted_tasks, starting_task_line, _lines)
    local sorted_tasks_texts = {}

    for _, task in ipairs(sorted_tasks) do
      table.insert(sorted_tasks_texts, task.line)
    end

    vim.api.nvim_buf_set_lines(bufnr, starting_task_line - 1, starting_task_line + U.tlen(sorted_tasks_texts), false, sorted_tasks_texts)
  end

  -- extract tasks and the first line the tasks start on
  local tasks, starting_task_line = extract(lines)

  -- used for comparison later
  local originally_extracted_tasks = U.tcopy(tasks)

  sort(tasks)

  -- verifies our mutated-tasks table (sorted) is different from the tasks before we sorted to know if we ought to replace them. This prevents needless buffer re-writes.
  if not U.deep_equals(originally_extracted_tasks, tasks) then replace(bufnr, tasks, starting_task_line, lines) end
end

vim.api.nvim_create_user_command("FormatNotes", M.format_notes, {})

return M
