if not mega then return end

local U = require("mega.utils")
local command = vim.api.nvim_create_user_command
local map = vim.keymap.set

local M = {}

---@return nil|TSNode
function M.get_task_list_marker()
  local markers = {}
  local node = vim.treesitter.get_node()
  while node and node:type() ~= "list_item" do
    node = node:parent()
  end

  if not node then return end

  for child in node:iter_children() do
    dbg(child:type())
    if child:type():match("^task_list_marker") then return child end
  end
end

---@param replacement string?
local function replace_marker(replacement)
  local line = vim.api.nvim_get_current_line()

  local prefix, box = line:match("^(%s*[-*] )(%[.%])")

  if replacement == nil then
    if box == "[x]" then
      replacement = "[ ]"
    else
      replacement = "[x]"
    end
  end

  if not prefix or not box then return end
  local cur = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(0, cur[1] - 1, prefix:len(), cur[1] - 1, prefix:len() + box:len(), { replacement })
end

function M.toggle_task()
  replace_marker()
  -- return function() replace_marker() end
  -- return function() replace_marker("[" .. new_status .. "]") end
end

function M.get_md_link_title()
  if vim.bo.filetype ~= "markdown" then return end
  local get_node = vim.treesitter.get_node
  local _cur_pos = vim.api.nvim_win_get_cursor

  local current_node = get_node({ lang = "markdown_inline" })

  while current_node do
    local type = current_node:type()
    -- if type == "inline_link" or type == "image" then return vim.treesitter.get_node_text(current_node:named_child(1), 0) end
    if type == "link_text" then return vim.treesitter.get_node_text(current_node, 0) end
    current_node = current_node:parent()
  end

  return nil
end

function M.get_previous_daily_note()
  local notes = vim.split(
    vim.fn.glob(
      "`find " .. vim.env.HOME .. "/Documents/_notes/daily/**/*.md -type f -print0 | xargs -0 stat -f '%m %N' | sort -nr | head -2 | cut -f2- -d' ' | tail -n1`"
    ),
    "\n",
    { trimempty = true }
  )

  if #notes == 1 then return notes[1] end

  return nil
end

function M.note_info(fpath, ...)
  local args = { ... }
  local path = vim.g.notes_path .. "/"
  local starts_with_a_path = vim.fn.fnamemodify(fpath, ":h")
  local starts_with_name = vim.fn.fnamemodify(fpath, ":t")
  local where = string.gsub(starts_with_a_path .. "/", "^\\.", "")
  local has_a_path = starts_with_a_path ~= "."
  local fname = table.concat({
    has_a_path and starts_with_name or fpath,
    #args > 1 and table.concat(args, " ") or args[1],
  }, " ") or ""

  if has_a_path then path = path .. where end

  path = path .. vim.fn.strftime("%Y%m%d%H%M") .. (fname and " " .. fname or "") .. ".md"

  return {
    path,
    fname,
    vim.fn.strftime("%Y-%m-%dT%H:%M"),
  }
end

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

-- [[ commands ]] --------------------------------------------------------------

command("ToggleTask", function() M.toggle_task() end, {})
command("FormatNotes", function() M.format_notes() end, {})

command("ExecuteLine", function()
  -- if vim.bo.filetype ~= "markdown" then return end
  local ts = vim.treesitter

  -- Function to check if the current line is in a markdown code block and get its language
  local function is_in_markdown_code_block()
    -- Get the parser for the current buffer
    local parser = ts.get_parser(0, "markdown") -- Ensure we use the markdown parser
    local tree = parser:parse()[1] -- Get the first parsed tree
    local root = tree:root() -- Get the root of the syntax tree

    -- Get the current cursor position (0-indexed)
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_row = cursor_row - 1 -- Convert from 1-indexed to 0-indexed

    -- Function to check if a node contains the cursor
    local function node_contains_cursor(node)
      local start_row, start_col, end_row, end_col = node:range()
      return start_row <= cursor_row and end_row >= cursor_row
    end

    -- Tree-sitter query to find fenced code blocks and their language identifier
    local query = [[
        (fenced_code_block
            (info_string) @lang)
    ]]

    local lang_tree = ts.query.parse("markdown", query)
    for _, captures, _ in lang_tree:iter_matches(root, 0, cursor_row, cursor_row + 1) do
      local lang_node = captures[1] -- The 'info_string' node that contains the language
      local code_block_node = lang_node:parent() -- The parent node of the language identifier

      if node_contains_cursor(code_block_node) then
        -- Get the text of the language identifier (e.g., `lua`, `python`, etc.)
        local lang = ts.get_node_text(lang_node, 0)
        return true, lang
      end
    end

    return false, nil
  end

  -- Usage example
  local in_code_block, lang = is_in_markdown_code_block()

  if in_code_block then
    print("Cursor is inside a code block for language:", lang)
  else
    print("Cursor is not inside a code block.")
  end

  -- local bufnr = vim.api.nvim_get_current_buf()
  -- local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  -- local ts = vim.treesitter
  -- local get_node_text = require("vim.treesitter").get_node_text

  -- if vim.bo.filetype ~= "markdown" then return end
  -- local get_node = ts.get_node
  -- local _cur_pos = vim.api.nvim_win_get_cursor

  -- local current_node = get_node({ lang = "markdown" })
  -- local node = current_node

  -- while node ~= nil and node:type() ~= "code_fence_content" and node:type() ~= "fenced_code_block" do
  --   node = node:parent()
  --   P(node:type())
  -- end

  -- local language = ""
  -- for child_node in node:iter_children() do
  --   print(child_node:type())
  --   if child_node:type() == "code_fence_content" or node:type() == "fenced_code_block" then node = child_node end
  --   if child_node:type() == "info_string" then
  --     for c in child_node:iter_children() do
  --       if c:type() == "language" then language = get_node_text(c, 0) end
  --     end
  --   end
  -- end

  -- while node ~= nil and node:type() ~= "code_fence_content" and node:type() ~= "fenced_code_block" do
  --   node = node:parent()
  --   P(node:type())
  -- end

  -- local codeblock_content = vim.split(get_node_text(node, 0):gsub("\n>?%s-$", ""), "\n")
  -- dbg(codeblock_content)

  -- while node ~= nil and node:type() ~= "code_fence_content" and node:type() ~= "fenced_code_block" do
  --   node = node:parent()
  -- end

  -- -- return node ~= nil and (node:type() == "code_fence_content" or node:type() == "fenced_code_block")
  -- if node ~= nil and (node:type() == "code_fence_content" or node:type() == "fenced_code_block") then
  --   local language = ""
  --   for child_node in node:iter_children() do
  --     dbg(child_node:type())
  --     if child_node:type() == "code_fence_content" then node = child_node end
  --     if child_node:type() == "info_string" then
  --       for c in child_node:iter_children() do
  --         if c:type() == "language" then language = get_node_text(c, 0) end
  --       end
  --     end
  --   end

  --   print(language)

  --   -- local current_line = vim.api.nvim_get_current_line()
  --   -- print(current_line)
  -- end

  -- while current_node do
  --   local type = current_node:type()
  --   dbg(type)
  --   -- if type == "inline_link" or type == "image" then return vim.treesitter.get_node_text(current_node:named_child(1), 0) end
  --   if type == "link_text" then print(ts.get_node_text(current_node, 0)) end
  --   -- if type == "link_text" then return ts.get_node_text(current_node, 0) end
  --   current_node = current_node:parent()
  -- end

  -- local tsparser = vim.treesitter.get_string_parser(self.content, "markdown")
  -- local tstree = tsparser:parse()[1]
  -- local parent_node = tstree:root()

  -- local ts = vim.treesitter

  -- -- Function to check if the current line is in a code fence block
  -- local function is_in_code_fence_block()
  --   local parser = ts.get_parser(0) -- Get parser for the current buffer
  --   local tree = parser:parse()[1] -- Get the first parsed tree
  --   local root = tree:root() -- Root of the syntax tree

  --   local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0)) -- Get cursor position
  --   cursor_row = cursor_row - 1 -- Make it 0-indexed

  --   -- Function to find the code block node at cursor position
  --   local function node_contains_cursor(node)
  --     local start_row, start_col, end_row, end_col = node:range()
  --     return start_row <= cursor_row and end_row >= cursor_row
  --   end

  --   local function find_code_fence_node()
  --     local query = [[
  --         ;; Query to find code fences in markdown-like languages
  --         (fenced_code_block
  --           (info_string) @lang)
  --       ]]
  --     local lang_tree = ts.query.parse("markdown", query)
  --     for _, captures, metadata in lang_tree:iter_matches(root, 0, cursor_row, cursor_row + 1) do
  --       local lang_node = captures[1] -- The 'info_string' node that specifies the language
  --       if lang_node ~= nil and node_contains_cursor(lang_node:parent()) then
  --         return lang_node -- The node that specifies the language
  --       end
  --     end
  --     return nil
  --   end

  --   -- Check if we are inside a fenced code block and get the language
  --   local lang_node = find_code_fence_node()
  --   if lang_node then
  --     -- Extract the language (i.e., the programming language after ```)
  --     local lang = ts.get_node_text(lang_node, 0)
  --     return true, lang
  --   else
  --     return false, nil
  --   end
  -- end

  -- -- Usage
  -- local in_fence, lang = is_in_code_fence_block()
  -- if in_fence then
  --   print("Cursor is inside a code fence block for language:", lang)
  -- else
  --   print("Cursor is not in a code fence block.")
  -- end
end, {})

-- [[ mappings ]] --------------------------------------------------------------
local notesMappings = {
  d = {
    function()
      local notePathObj = vim.system({ "daily_note", "-c", "| tr -d '\n'" }, { text = true }):wait()
      local notePath = string.gsub(notePathObj.stdout, "^%s*(.-)%s*$", "%1")

      -- open only if we're not presently editing that buffer/file
      if notePath ~= vim.api.nvim_buf_get_name(0) then vim.cmd("edit " .. notePath) end
    end,
    "open [d]aily note",
  },
  D = {
    function()
      local notePathObj = vim.system({ "daily_note", "-c", "| tr -d '\n'" }, { text = true }):wait()
      local notePath = string.gsub(notePathObj.stdout, "^%s*(.-)%s*$", "%1")

      vim.cmd("vnew " .. notePath)
    end,
    "open [d]aily note (vsplit)",
  },
  g = {
    function() mega.picker.grep({ cwd = vim.g.notes_path, default_text = "" }) end,
    "[g]rep notes",
  },
  p = {
    function()
      local note = M.get_previous_daily_note()
      if note ~= nil then vim.cmd("edit " .. note) end
    end,
    "open [l]ast daily note",
  },
  P = {
    function()
      local note = M.get_previous_daily_note()
      if note ~= nil then vim.cmd("vnew " .. note) end
    end,
    "open [l]ast daily note (vsplit)",
  },
}

local function leaderMapper(mode, key, rhs, opts)
  if type(opts) == "string" then opts = { desc = opts } end
  map(mode, "<leader>" .. key, rhs, opts)
end

local function localLeaderMapper(mode, key, rhs, opts)
  if type(opts) == "string" then opts = { desc = opts } end
  map(mode, "<localleader>" .. key, rhs, opts)
end

-- <leader>n<key>
vim.iter(notesMappings):each(function(key, rhs) leaderMapper("n", "n" .. key, rhs[1], rhs[2]) end)

return M
