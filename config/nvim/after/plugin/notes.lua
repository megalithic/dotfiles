if not Plugin_enabled() then return end

local U = require("config.utils")
local command = vim.api.nvim_create_user_command
local map = vim.keymap.set

local M = {}

---@param status string?
function M.toggle_task(status)
  -- TODO: https://github.com/epilande/checkbox-cycle.nvim/blob/main/lua/checkbox-cycle/init.lua
  local line = vim.api.nvim_get_current_line()
  local default_empty_status = " "

  local prefix, box, _box_status, _task_text = line:match("^(%s*[-*] )(%[(.)%])%s(.*)")

  if not prefix or not box then return end
  local function wrap_status(s) return string.format("[%s]", s) end

  if status == nil or status == "" then
    if box == "[x]" then
      status = wrap_status(default_empty_status)
    else
      status = wrap_status("x")
    end
  else
    status = wrap_status(status)
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  vim.api.nvim_buf_set_text(0, cursor[1] - 1, prefix:len(), cursor[1] - 1, prefix:len() + box:len(), { status })
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
      "`find "
        .. vim.env.NOTES_HOME
        .. "/daily -type f -name '*.md' -print0 | xargs -0 ls -Ur | sort -nr | head -2 | cut -f2- -d' ' | tail -n1`"
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

function M.sort_tasks(bufnr, lines)
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
      if prefix ~= nil and box ~= nil and status ~= nil then
        table.insert(tasks, { index = i, line = line, status = status, text = task_text })
      end
    end
    if tasks and U.tlen(tasks) > 0 then return tasks, tasks[1].index end

    return nil, nil
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
      local text = task.text
      if task.status == "/" then text = string.format("~~%s~~", task.text) end
      local task_line = string.format("- [%s] %s", task.status, text)
      table.insert(sorted_tasks_texts, task_line)
    end

    vim.api.nvim_buf_set_lines(
      bufnr,
      starting_task_line - 1,
      starting_task_line + U.tlen(sorted_tasks_texts),
      false,
      sorted_tasks_texts
    )
  end

  -- extract tasks and the first line the tasks start on
  local tasks, starting_task_line = extract(lines)

  if tasks == nil then return end

  -- used for comparison later
  local originally_extracted_tasks = U.tcopy(tasks)

  -- sorts by status priority, then alphanumerically
  local sorted_tasks = sort(tasks)

  -- prevents unncessary re-writes of the buffer..
  if not U.deep_equals(originally_extracted_tasks, sorted_tasks) then
    replace(bufnr, sorted_tasks, starting_task_line, lines)
  end
end

function M.compile_links(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local links = {}

  for i, line in ipairs(lines) do
    local url =
      line:match("((https?)://([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w%w%w?%w?)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))")

    if url ~= nil then table.insert(links, { index = i, line = line, url = url }) end
  end

  return links
end

function M.extract_links(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local inline_query = vim.treesitter.query.parse("markdown_inline", [[(inline_link) @link]])
  local auto_query = vim.treesitter.query.parse("markdown_inline", [[(uri_autolink) @link]])

  local get_root = function(str)
    local parser = vim.treesitter.get_string_parser(str, "markdown_inline")
    return parser:parse()[1]:root()
  end

  local get_text = vim.treesitter.get_node_text

  local function markdown_links(bufnr, str)
    local inline_links = vim
      .iter(inline_query:iter_captures(get_root(str), str))
      :map(function(_, node)
        local text = get_text(node:child(1), str)
        local link = get_text(node:child(4), str)
        return { url = link, text = text }
      end)
      :totable()

    local autolinks = vim
      .iter(auto_query:iter_captures(get_root(str), str))
      :map(function(_, node)
        local text = get_text(node, str):sub(2, -2)
        return { text = text }
      end)
      :totable()

    -- local raw_urls = vim
    --   .iter(str)
    --   :map(function(_, node)
    --     local text = get_text(node, str):sub(2, -2)
    --     return text, text
    --   end)
    --   :totable()

    return vim.list_extend(inline_links, autolinks)
  end

  local function raw_urls(bufnr, lines) return M.compile_links(bufnr, lines) end

  local links = markdown_links(bufnr, table.concat(lines, "\n"))
  local urls = raw_urls(bufnr, lines)

  return vim.list_extend(links, urls)
end

function M.parse_due_dates(bufnr, lines)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local tasks_due = {}

  for i, line in ipairs(lines) do
    -- matches: `- [ ] some sort of task that has a due date @@today at 3pm!`
    local prefix, box, status, text, date_parse_string, due_date = line:match("^(%s*[-*] )(%[(.)%])%s(.*(@@(.*)!))")
    if prefix ~= nil and box ~= nil and status ~= nil then
      text = U.strim(string.gsub(text, date_parse_string, ""))

      table.insert(tasks_due, {
        index = i,
        line = line,
        status = status,
        text = text,
        date_parse_string = date_parse_string,
        due_date = due_date,
      })

      vim.fn.jobstart(string.format([[reme "%s" "%s"]], text, due_date), {
        detach = false,
        on_exit = function(job_id, exit_code, event)
          if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
            vim.notify(string.format("set reminder '%s' for %s", text, due_date))
          end
        end,
      })
    end
  end

  if tasks_due and U.tlen(tasks_due) > 0 then return tasks_due end
end

function M.format_notes(bufnr, lines) end

function M.execute_line()
  if vim.bo.filetype ~= "markdown" then return end

  -- https://github.com/AckslD/nvim-FeMaco.lua/blob/main/lua/femaco/edit.lua
  local ts = vim.treesitter
  local get_node_range = ts.get_node_range
  local query = require("nvim-treesitter.query")

  local any = function(func, items)
    for _, item in ipairs(items) do
      if func(item) then return true end
    end
    return false
  end

  -- Maybe we could use https://github.com/nvim-treesitter/nvim-treesitter/pull/3487
  -- if they get merged
  local is_in_range = function(range, line, col)
    local start_line, start_col, end_line, end_col = unpack(range)
    if line >= start_line and line <= end_line then
      if line == start_line and line == end_line then
        return col >= start_col and col < end_col
      elseif line == start_line then
        return col >= start_col
      elseif line == end_line then
        return col < end_col
      else
        return true
      end
    else
      return false
    end
  end

  local get_match_range = function(match)
    if match.metadata ~= nil and match.metadata.range ~= nil then
      return unpack(match.metadata.range)
    else
      return get_node_range(match.node)
    end
  end

  local get_match_text = function(match, bufnr)
    local srow, scol, erow, ecol = get_match_range(match)
    return table.concat(vim.api.nvim_buf_get_text(bufnr, srow, scol, erow, ecol, {}), "\n")
  end

  local parse_match = function(match)
    local language = match.language or match._lang or (match.injection and match.injection.language)
    if language == nil then
      for lang, val in pairs(match) do
        return {
          lang = lang,
          content = val,
        }
      end
    end
    local lang
    local lang_range
    if type(language) == "string" then
      lang = language
    else
      lang = get_match_text(language, 0)
      lang_range = { get_match_range(language) }
    end
    local content = match.content or (match.injection and match.injection.content)

    return {
      lang = lang,
      lang_range = lang_range,
      content = content,
    }
  end

  local get_match_at_cursor = function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))

    local contains_cursor = function(range)
      return is_in_range(range, row - 1, col) or (range[3] == row - 1 and range[4] == col)
    end

    local is_after_cursor = function(range) return range[1] == row - 1 and range[2] > col end

    local is_before_cursor = function(range) return range[3] == row - 1 and range[4] < col end

    local matches = query.get_matches(vim.api.nvim_get_current_buf(), "injections")
    local before_cursor = {}
    local after_cursor = {}
    for _, match in ipairs(matches) do
      local match_data = parse_match(match)
      local content_range = { get_match_range(match_data.content) }
      local ranges = { content_range }
      if match_data.lang_range then table.insert(ranges, match_data.lang_range) end
      if any(contains_cursor, ranges) then
        return { lang = match_data.lang, content = match_data.content, range = content_range }
      elseif any(is_after_cursor, ranges) then
        table.insert(after_cursor, { lang = match_data.lang, content = match_data.content, range = content_range })
      elseif any(is_before_cursor, ranges) then
        table.insert(before_cursor, { lang = match_data.lang, content = match_data.content, range = content_range })
      end
    end
    if #after_cursor > 0 then
      return after_cursor[1]
    elseif #before_cursor > 0 then
      return before_cursor[#before_cursor]
    end
  end

  local match_data = get_match_at_cursor()
  if match_data == nil then return end
  -- local match_lines = vim.split(get_match_text(match_data.content, 0), "\n")
  local filetype = match_data.lang

  local current_line_to_execute = vim.api.nvim_get_current_line()

  local function exec(args, cmd, ft)
    cmd = cmd and cmd .. " " or ""
    vim.notify(string.format("%s: executing %s%s", ft, cmd, current_line_to_execute))
    mega.toggleterm({ cmd = "zsh -lc '" .. cmd .. args .. "; echo; echo Press any key to exit...; read -n 1; exit'" })
  end

  if filetype == "sh" then
    exec(current_line_to_execute)
  elseif filetype == "elixir" then
    exec(current_line_to_execute, "elixir", filetype)
  elseif filetype == "lua" then
    exec(current_line_to_execute, "lua", filetype)
  else
    vim.notify(string.format("%s: unable to execute `%s`", filetype, current_line_to_execute))
  end
end

-- [[ commands ]] --------------------------------------------------------------

command("ToggleTask", function(evt) M.toggle_task(evt.args) end, {})
command("FormatNotes", function() M.format_notes() end, {})
command("ExecuteLine", function() M.execute_line() end, {})

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

-- <leader>n<key>
vim.iter(notesMappings):each(function(key, rhs) leaderMapper("n", "n" .. key, rhs[1], rhs[2]) end)

require("config.autocmds").augroup("NotesLoaded", {
  {
    event = { "LspAttach", "BufEnter" },
    desc = "Use various notes related functions upon markdown entering or markdown-oxide lsp attaching",
    command = function(evt)
      local bufnr = evt.buf
      if vim.bo[bufnr].filetype == "markdown" then
        local notesAbbrevs = {
          ["mtg:"] = [[### Meeting 󱛡 ->]],
          ["trn:"] = [[### Linear Ticket  ->]],
          ["pr:"] = [[### Pull Request  ->]],
          ["self:"] = [[### Self  ->]],
          ["prep:"] = [[## Daily Game Plan Prep]],
          ["end:"] = [[## End of Day Wrap-up (😃😐😞)]],
          ["call:"] = [[ (call) ]],
          ["email:"] = [[ (email) ]],
          ["contact:"] = [[󰻞 (contact) ]],
          ["chat:"] = [[󰻞 (contact) ]],
          ["act:"] = [[_Action item:_ ]],
        }

        vim.api.nvim_buf_call(bufnr, function()
          for k, v in pairs(notesAbbrevs) do
            vim.cmd.iabbrev(string.format("<buffer> %s %s", k, v))
          end
        end)

        map("n", "gx", vim.cmd.ExecuteLine, { desc = "execute line", buffer = bufnr })
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        for _, client in ipairs(clients) do
          if
            vim.tbl_contains({ "markdown_oxide", "marksman", "obsidian-ls" }, client.name)
            and string.match(vim.fn.expand("%:p:h"), vim.env.NOTES_HOME)
          then
            map("n", "<leader>w", function()
              vim.schedule(function()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

                if string.match(vim.fn.expand("%:p:h"), "daily") then
                  M.sort_tasks(bufnr, lines)
                  M.parse_due_dates(bufnr, lines)

                  -- FIXME: do we need link related parsing for _only_ daily notes?
                  M.extract_links(bufnr, lines)
                  -- M.compile_links(bufnr, lines)
                end

                vim.cmd.write({ bang = true })
              end)
            end, { buffer = bufnr, desc = "[notes] format and save" })
            if pcall(require, "mini.clue") then
              vim.b.miniclue_config = {
                clues = {
                  { mode = "n", keys = "<C-x>", desc = "+tasks" },
                  { mode = "i", keys = "<C-x>", desc = "+tasks" },
                  { mode = "x", keys = "<C-x>", desc = "+tasks" },
                },
              }
            end

            map("n", "<C-x>d", function() M.toggle_task("x") end, { buffer = bufnr, desc = "[notes] toggle -> done" })
            map("n", "<C-x>t", function() M.toggle_task("-") end, { buffer = bufnr, desc = "[notes] toggle -> todo" })
            map(
              "n",
              "<C-x>s",
              function() M.toggle_task(".") end,
              { buffer = bufnr, desc = "[notes] toggle -> started" }
            )
            map(
              "n",
              "<C-x>u",
              function() M.toggle_task("/") end,
              { buffer = bufnr, desc = "[notes] toggle -> undo/skip/trash" }
            )
            map(
              "n",
              "<C-x><C-x>",
              function() M.toggle_task(" ") end,
              { buffer = bufnr, desc = "[notes] toggle -> not-started" }
            )
            map("n", "<leader>ff", "<cmd>Obsidian quick_switch<cr>", { desc = "[notes] find", buffer = bufnr })
            map("n", "<leader>a", "<cmd>Obsidian search<cr>", { desc = "[notes] grep" })
            map(
              "n",
              "<leader>A",
              string.format("<cmd>Obsidian search %s<cr>", vim.fn.expand("<cword>")),
              { desc = "[notes] grep cursor" }
            )
            map(
              { "x", "v" },
              "<leader>A",
              string.format("<cmd>Obsidian search %s<cr>", require("config.utils").get_selected_text()),
              { desc = "[notes] grep selection" }
            )

            map({ "n", "v" }, "<localleader>n", function()
              -- `/` - Start a search forwards from the current cursor position.
              -- `^` - Match the beginning of a line.
              -- `##` - Match 2 ## symbols
              -- `\\+` - Match one or more occurrences of prev element (#)
              -- `\\s` - Match exactly one whitespace character following the hashes
              -- `.*` - Match any characters (except newline) following the space
              -- `$` - Match extends to end of line
              vim.cmd("silent! /^##\\+\\sNotes.*$")
              -- Clear the search highlight
              vim.schedule(function()
                vim.cmd.nohlsearch()
                pcall(mega.searchCountIndicator, "clear")
              end)
            end, { desc = "go to main notes section" })
          end
        end
      end
    end,
  },
})

return M
