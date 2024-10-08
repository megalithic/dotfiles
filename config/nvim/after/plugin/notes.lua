if not mega then return end

local M = {}

vim.api.nvim_create_user_command("FormatNotes", function()
  local U = require("mega.utils")

  local function extract_tasks(lines)
    local tasks = {}

    for i, line in ipairs(lines) do
      local prefix, box, status = line:match("^(%s*[-*] )(%[(.)%])")
      if prefix ~= nil and box ~= nil and status ~= nil then table.insert(tasks, { index = i, text = line, status = status }) end
    end

    return tasks, tasks[1].index
  end

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

  local function sort_tasks_by_task_status(tasks)
    table.sort(tasks, function(a, b) return get_priority_from_status(a.status) < get_priority_from_status(b.status) end)
  end

  local function replace_tasks(bufnr, sorted_tasks, starting_task_line, _lines)
    local sorted_tasks_texts = {}

    for _, task in ipairs(sorted_tasks) do
      table.insert(sorted_tasks_texts, task.text)
    end

    vim.api.nvim_buf_set_lines(bufnr, starting_task_line - 1, starting_task_line + U.tlen(sorted_tasks_texts), false, sorted_tasks_texts)
  end

  local function sort_and_replace_tasks_in_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local tasks, starting_task_line = extract_tasks(lines)
    local originally_extracted_tasks = U.tcopy(tasks)

    sort_tasks_by_task_status(tasks)

    -- verifies our mutated-tasks table (sorted) is different from the tasks before we sorted to know if we ought to replace them. This prevents needless buffer re-writes.
    if not U.deep_equals(originally_extracted_tasks, tasks) then replace_tasks(bufnr, tasks, starting_task_line, lines) end
  end

  sort_and_replace_tasks_in_buffer()
end, {})

return M
