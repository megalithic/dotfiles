if not Plugin_enabled() then return end

local U = require("config.utils")
local command = vim.api.nvim_create_user_command
local map = vim.keymap.set

-- Expose meganote context for statusline/UI customization
vim.g.meganote_context = vim.env.MEGANOTE == "1"

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
  local current_node = get_node({ lang = "markdown_inline" })

  while current_node do
    local type = current_node:type()
    if type == "link_text" then return vim.treesitter.get_node_text(current_node, 0) end
    current_node = current_node:parent()
  end

  return nil
end

--- Get image reference from current line (wiki-link or markdown image syntax)
--- Supports: ![[image.png]], ![[image.png|200]], ![alt](path/to/image.png)
---@return string|nil image_ref The image filename/path or nil
function M.get_image_ref_on_line()
  local line = vim.api.nvim_get_current_line()

  -- Wiki-link image: ![[filename.png]] or ![[filename.png|size]]
  local wiki_ref = line:match("!%[%[([^%]|]+)")
  if wiki_ref then return wiki_ref end

  -- Markdown image: ![alt](path)
  local md_ref = line:match("!%[[^%]]*%]%(([^%)]+)%)")
  if md_ref then return md_ref end

  return nil
end

--- Resolve image reference to full filesystem path
---@param image_ref string Image reference (filename or relative path)
---@return string|nil full_path Full path to image or nil if not found
function M.resolve_image_path(image_ref)
  if not image_ref then return nil end

  local notes_home = vim.g.notes_path
  if not notes_home then return nil end

  -- Check common locations
  local search_paths = {
    notes_home .. "/assets/" .. image_ref,
    notes_home .. "/" .. image_ref,
    vim.fn.expand("%:p:h") .. "/" .. image_ref, -- relative to current file
  }

  for _, path in ipairs(search_paths) do
    if vim.fn.filereadable(path) == 1 then return path end
  end

  return nil
end

--- Run vision-ocr on an image and return the text
---@param image_path string Full path to image
---@return string|nil text OCR text or nil on failure
function M.run_vision_ocr(image_path)
  local cmd = string.format("%s/bin/vision-ocr '%s'", vim.env.HOME, image_path)
  local result = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    vim.notify("OCR failed: " .. (result or "unknown error"), vim.log.levels.ERROR)
    return nil
  end

  -- Trim trailing newline
  result = result:gsub("\n$", "")
  return result
end

--- Insert OCR text into current buffer after image reference
--- Creates or updates ## OCR Text section
---@param ocr_text string The OCR text to insert
function M.insert_ocr_text(ocr_text)
  if not ocr_text or ocr_text == "" then
    vim.notify("No text extracted from image", vim.log.levels.WARN)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Look for existing ## OCR Text section
  local ocr_section_line = nil
  local next_section_line = nil

  for i, line in ipairs(lines) do
    if line:match("^## OCR Text") then
      ocr_section_line = i
    elseif ocr_section_line and line:match("^## ") then
      next_section_line = i
      break
    end
  end

  local ocr_lines = vim.split(ocr_text, "\n")

  if ocr_section_line then
    -- Replace existing OCR section content
    local end_line = next_section_line and (next_section_line - 1) or #lines
    -- Keep the header, replace content
    local new_content = { "", unpack(ocr_lines), "" }
    vim.api.nvim_buf_set_lines(bufnr, ocr_section_line, end_line, false, new_content)
    vim.notify("OCR text updated", vim.log.levels.INFO)
  else
    -- Append new OCR section at end
    local new_content = { "", "## OCR Text", "", unpack(ocr_lines), "" }
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, new_content)
    vim.notify("OCR text added", vim.log.levels.INFO)
  end
end

--- OCR the image on current line and insert text into buffer
function M.ocr_image_on_line()
  local image_ref = M.get_image_ref_on_line()
  if not image_ref then
    vim.notify("No image reference found on current line", vim.log.levels.WARN)
    return
  end

  local image_path = M.resolve_image_path(image_ref)
  if not image_path then
    vim.notify("Could not find image: " .. image_ref, vim.log.levels.ERROR)
    return
  end

  vim.notify("Running OCR on " .. vim.fn.fnamemodify(image_path, ":t") .. "...", vim.log.levels.INFO)

  -- Run async to not block UI
  vim.schedule(function()
    local ocr_text = M.run_vision_ocr(image_path)
    if ocr_text then M.insert_ocr_text(ocr_text) end
  end)
end

--- Stub for AI image summarization (Phase 6)
function M.summarize_image_on_line()
  local image_ref = M.get_image_ref_on_line()
  if not image_ref then
    vim.notify("No image reference found on current line", vim.log.levels.WARN)
    return
  end

  vim.notify("AI summarization not yet implemented (Phase 6)", vim.log.levels.INFO)
end

function M.get_previous_daily_note()
  local notes = vim.split(
    vim.fn.glob(
      "`find "
        .. vim.g.notes_path
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
command("ExecuteLine", function() M.execute_line() end, {})

-- [[ mappings ]] --------------------------------------------------------------
local notesMappings = {
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
          if client.name == "obsidian-ls" then
            map("n", "<leader>w", function()
              vim.schedule(function()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

                if string.match(vim.fn.expand("%:p:h"), "daily") then
                  M.sort_tasks(bufnr, lines)
                  M.parse_due_dates(bufnr, lines)
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

            -- Unified gr: find references for tags, links, or fall back to LSP
            map("n", "gr", function()
              local api = require("obsidian.api")

              -- Check if cursor is on a #tag in body text
              local tag = api.cursor_tag()
              if tag then
                -- cursor_tag() returns "#tagname", strip the # for the command
                vim.cmd("Obsidian tags " .. tag:sub(1))
                return
              end

              -- Check if cursor is on a tag in YAML frontmatter
              local row = vim.api.nvim_win_get_cursor(0)[1]
              local col = vim.api.nvim_win_get_cursor(0)[2] + 1
              local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

              -- Find frontmatter bounds (between --- markers)
              local fm_start, fm_end = nil, nil
              if lines[1] == "---" then
                fm_start = 1
                for i = 2, #lines do
                  if lines[i] == "---" then
                    fm_end = i
                    break
                  end
                end
              end

              -- If we're in frontmatter, check for tags
              if fm_start and fm_end and row > fm_start and row < fm_end then
                local line = lines[row]
                -- Match list-style tag: "  - tagname" or "- tagname"
                local list_tag = line:match("^%s*-%s+([%w_/-]+)%s*$")
                if list_tag then
                  vim.cmd("Obsidian tags " .. list_tag)
                  return
                end
                -- Match inline array: "tags: [tag1, tag2]" - find tag under cursor
                local tags_line = line:match("^tags:%s*%[(.+)%]")
                if tags_line then
                  -- Find which tag the cursor is on
                  local pos = col - (line:find("%[") or 0)
                  local current_pos = 0
                  for t in tags_line:gmatch("([%w_/-]+)") do
                    local t_start = tags_line:find(t, current_pos + 1, true)
                    local t_end = t_start + #t - 1
                    if pos >= t_start and pos <= t_end then
                      vim.cmd("Obsidian tags " .. t)
                      return
                    end
                    current_pos = t_end
                  end
                end
              end

              -- Check if cursor is on a wiki/markdown link
              local link, _ = api.cursor_link()
              if link then
                vim.cmd("Obsidian backlinks")
                return
              end

              -- Fall back to LSP references
              vim.lsp.buf.references()
            end, { buffer = bufnr, desc = "[notes] find references (tag/link/lsp)" })

            -- Image OCR: extract text from image on current line
            map(
              "n",
              "<localleader>io",
              function() M.ocr_image_on_line() end,
              { buffer = bufnr, desc = "[notes] OCR image on line" }
            )

            -- Image AI summarize: generate description (stub for Phase 6)
            map(
              "n",
              "<localleader>is",
              function() M.summarize_image_on_line() end,
              { buffer = bufnr, desc = "[notes] AI summarize image (stub)" }
            )
          end
        end
      end
    end,
  },
})

return M
