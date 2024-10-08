if not mega then return end

local M = {}

vim.api.nvim_create_user_command("FormatNotes", function()
  local U = require("mega.utils")

  local function extract_tasks(lines)
    local tasks = {}

    for i, line in ipairs(lines) do
      if line:match("^%- %[[ %-x%.]%]") then
        local _prefix, status = line:match("^(%s*[-*] )%[(.)%]")
        table.insert(tasks, { index = i, text = line, status = status })
      end
    end

    return tasks, tasks[1].index
  end

  local function get_priority_from_status(status)
    local priority = 5
    if status == "." then
      priority = 1 -- In-progress
    elseif status == "-" then
      priority = 2 -- Todo tasks
    elseif status == " " then
      priority = 3 -- Not started tasks
    elseif status == "x" then
      priority = 4 -- Completed tasks
    else
      priority = 5 -- Fallback for unrecognized tasks
    end

    return priority
  end

  -- Function to sort tasks by priority
  local function sort_tasks_by_task_status(tasks)
    table.sort(tasks, function(a, b) return get_priority_from_status(a.status) < get_priority_from_status(b.status) end)
    -- table.sort(tasks, function(a, b) return get_priority(a.text) < get_priority(b.text) end)
  end

  -- Function to replace tasks in the buffer
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

    sort_tasks_by_task_status(tasks)

    replace_tasks(bufnr, tasks, starting_task_line, lines)
  end

  sort_and_replace_tasks_in_buffer()
end, {})

return M
