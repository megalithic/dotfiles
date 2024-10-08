if not mega then return end

local U = require("mega.utils")
local M = {}

function M.format_notes(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- specific task status priorities.. your mileage my vary
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

  -- allows for extracting discrete parts of a task list item for further evaluation
  ---@diagnostic disable-next-line: redefined-local
  local function extract(lines)
    local tasks = {}

    for i, line in ipairs(lines) do
      local prefix, box, status, task_text = line:match("^(%s*[-*] )(%[(.)%])%s(.*)")
      if prefix ~= nil and box ~= nil and status ~= nil then table.insert(tasks, { index = i, line = line, status = status, text = task_text }) end
    end

    return tasks, tasks[1].index
  end

  -- sorts by status priority first, then alphanumerically
  local function sort(tasks)
    local sorted_tasks = U.tcopy(tasks)

    table.sort(sorted_tasks, function(a, b)
      if a.status == b.status then
        return a.text < b.text -- sort by alphanumerics if the statuses are the same
      else
        return get_priority_from_status(a.status) < get_priority_from_status(b.status) -- otherwise, sort by our statuses
      end
    end)

    return sorted_tasks
  end

  ---@diagnostic disable-next-line: redefined-local
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

  -- sorts by status priority, then alphanumerically
  local sorted_tasks = sort(tasks)

  -- prevents unncessary re-writes of the buffer..
  if not U.deep_equals(originally_extracted_tasks, sorted_tasks) then replace(bufnr, sorted_tasks, starting_task_line, lines) end
end

vim.api.nvim_create_user_command("FormatNotes", function() M.format_notes() end, {})

return M
