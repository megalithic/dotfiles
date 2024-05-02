local vcmd, fn, api = vim.cmd, vim.fn, vim.api
local fmt = string.format

local M = {
  hl = {},
}

function M.check_back_space()
  local col = fn.col(".") - 1
  return col == 0 or fn.getline("."):sub(col, col):match("%s") ~= nil
end

function M.root_has_file(name)
  local cwd = vim.loop.cwd()
  local lsputil = require("lspconfig.util")
  return lsputil.path.exists(lsputil.path.join(cwd, name)), lsputil.path.join(cwd, name)
end

function M.get_open_filelist(cwd)
  local Path = require("plenary.path")
  -- local flatten = vim.tbl_flatten
  local filter = vim.tbl_filter

  cwd = cwd or vim.loop.cwd()

  local bufnrs = filter(function(b)
    if 1 ~= vim.fn.buflisted(b) then return false end
    return true
  end, vim.api.nvim_list_bufs())
  if not next(bufnrs) then return end

  local filelist = {}
  for _, bufnr in ipairs(bufnrs) do
    local file = vim.api.nvim_buf_get_name(bufnr)
    table.insert(filelist, Path:new(file):make_relative(cwd))
  end
  return filelist
end

function M.hl.get(name)
  local ok, data = pcall(vim.api.nvim_get_hl_by_name, name, true)

  if not ok then
    vim.notify(fmt("Failed to find highlight by name \"%s\"", name), vim.log.levels.ERROR, { title = "nvim" })
    return {}
  end

  return data
end

function M.hl.set(group, color)
  local ok, msg = pcall(vim.api.nvim_set_hl, 0, group, color)

  if not ok then
    vim.notify(
      fmt("Failed to set highlight (%s): group %s | color: %s", msg, group, I(color)),
      vim.log.levels.ERROR,
      { title = "nvim" }
    )
  end
end

function M.hl.extend(target, source, opts) M.hl.set(target, vim.tbl_extend("force", M.hl.get(source), opts or {})) end

local function tbl_length(T)
  local count = 0
  for _ in pairs(T) do
    count = count + 1
  end
  return count
end

-- https://github.com/ibhagwan/fzf-lua/blob/455744b9b2d2cce50350647253a69c7bed86b25f/lua/fzf-lua/utils.lua#L401
function M.get_visual_selection()
  -- this will exit visual mode
  -- use 'gv' to reselect the text
  local _, csrow, cscol, cerow, cecol
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "" then
    -- if we are in visual mode use the live position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("."))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("v"))
    if mode == "V" then
      -- visual line doesn't provide columns
      cscol, cecol = 0, 999
    end
    -- exit visual mode
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", true)
  else
    -- otherwise, use the last known visual position
    _, csrow, cscol, _ = unpack(vim.fn.getpos("'<"))
    _, cerow, cecol, _ = unpack(vim.fn.getpos("'>"))
  end
  -- swap vars if needed
  if cerow < csrow then
    csrow, cerow = cerow, csrow
  end
  if cecol < cscol then
    cscol, cecol = cecol, cscol
  end
  local lines = vim.fn.getline(csrow, cerow)
  -- local n = cerow-csrow+1
  local n = tbl_length(lines)
  if n <= 0 then return "" end
  lines[n] = string.sub(lines[n], 1, cecol)
  lines[1] = string.sub(lines[1], cscol)
  return table.concat(lines, "\n")
end
-- OR --------------------------------------------------------------------------
-- REF: https://github.com/fdschmidt93/dotfiles/blob/master/nvim/.config/nvim/lua/fds/utils/init.lua
function M.get_selection()
  local rv = vim.fn.getreg("v")
  local rt = vim.fn.getregtype("v")
  vim.cmd([[noautocmd silent normal! "vy]])
  local selection = vim.fn.getreg("v")
  vim.fn.setreg("v", rv, rt)
  return vim.split(selection, "\n")
end

---@return string
function M.get_root()
  local path = vim.loop.fs_realpath(vim.api.nvim_buf_get_name(0))
  ---@type string[]
  local roots = {}
  if path ~= "" then
    for _, client in pairs(vim.lsp.get_clients({ bufnr = 0 })) do
      local workspace = client.config.workspace_folders
      local paths = workspace and vim.tbl_map(function(ws) return vim.uri_to_fname(ws.uri) end, workspace)
        or client.config.root_dir and { client.config.root_dir }
        or {}
      for _, p in ipairs(paths) do
        local r = vim.loop.fs_realpath(p)
        if path:find(r, 1, true) then roots[#roots + 1] = r end
      end
    end
  end
  ---@type string?
  local root = roots[1]
  if not root then
    path = path == "" and vim.loop.cwd() or vim.fs.dirname(path)
    ---@type string?
    root = vim.fs.find({ ".git" }, { path = path, upward = true })[1]
    root = root and vim.fs.dirname(root) or vim.loop.cwd()
  end
  ---@cast root string
  return root
end

function M.get_visible_qflists()
  -- get winnrs for qflists visible in current tab
  return vim
    .iter(vim.api.nvim_tabpage_list_wins(0))
    :filter(function(winnr) return vim.fn.getwininfo(winnr)[1].quickfix == 1 end)
end

function M.qf_populate(lines, opts)
  -- set qflist and open
  if not lines or #lines == 0 then return end

  opts = vim.tbl_deep_extend("force", {
    simple_list = false,
    mode = "r",
    title = nil,
    scroll_to_end = false,
  }, opts or {})

  -- convenience implementation, set qf directly from values
  if opts.simple_list then
    lines = vim.iter(lines):map(function(item)
      -- set default file loc to 1:1
      return { filename = item, lnum = 1, col = 1, text = item }
    end)
  end

  -- close any prior lists visible in current tab
  if not vim.tbl_isempty(M.get_visible_qflists()) then vim.cmd([[ cclose ]]) end

  vim.fn.setqflist(lines, opts.mode)

  -- ux
  local commands = table.concat({
    "horizontal copen",
    (opts.scroll_to_end and "normal! G") or "",
    -- (opts.title and require("statusline").set_statusline_cmd(opts.title)) or "",
    "wincmd p",
  }, "\n")

  vim.cmd(commands)
end

function M.get_file_extension(filepath) return filepath:match("^.+(%..+)$") end

function M.is_image(filepath)
  local ext = M.get_file_extension(filepath)
  return vim.tbl_contains({ ".bmp", ".jpg", ".jpeg", ".png", ".gif" }, ext)
end

function M.is_openable(filepath)
  local ext = M.get_file_extension(filepath)
  return vim.tbl_contains({ ".pdf", ".svg", ".html" }, ext)
end

function M.preview_file(filename)
  local cmd = fmt("silent !open %s", filename)

  if M.is_image(filename) then
    -- vim.notify(filename, L.INFO, { title = "nvim: previewing image..", render = "wrapped-compact" })
    cmd = fmt("silent !wezterm cli split-pane --right --percent 30 -- bash -c 'wezterm imgcat --hold %s;'", filename)
  elseif M.is_openable(filename) then
    -- vim.notify(filename, L.INFO, { title = "nvim: opening with default app..", render = "wrapped-compact" })
  else
    vim.notify(filename, L.WARN, { title = "nvim: not previewable file; aborting.", render = "wrapped-compact" })

    return
  end

  vim.api.nvim_command(cmd)
end

function M.conceal_class(bufnr)
  local min_chars = 2
  local namespace = vim.api.nvim_create_namespace("ConcealClassName")
  local ft = "html"
  if
    not vim.tbl_contains({ "html", "svelte", "astro", "vue", "elixir", "eelixir", "heex", "phoenix_html" }, vim.bo.ft)
  then
    ft = "tsx"
  end
  local language_tree = vim.treesitter.get_parser(bufnr, ft)
  local syntax_tree = language_tree:parse()
  local root = syntax_tree[1]:root()
  local query = [[
    ((attribute
      (attribute_name) @att_name (#eq? @att_name "class")
      (quoted_attribute_value (attribute_value) @class_value) (#set! @class_value conceal "…")))
    ((attribute
      (attribute_name) @att_name (#eq? @att_name "additional_classes")
      (quoted_attribute_value (attribute_value) @class_value) (#set! @class_value conceal "…")))
    ((attribute
      (attribute_name) @att_name (#eq? @att_name "card_classes")
      (quoted_attribute_value (attribute_value) @class_value) (#set! @class_value conceal "…")))
    ]]

  if ft == "tsx" then
    query = [[
      ((jsx_attribute
        (property_identifier) @att_name (#eq? @att_name "className")
        (string (string_fragment) @class_value) (#set! @class_value conceal "…")))
      ]]
  end

  local ok_query, ts_query = pcall(vim.treesitter.query.parse, ft, query)
  if not ok_query then dd(ts_query) end

  for _, captures, metadata in ts_query:iter_matches(root, bufnr, root:start(), root:end_(), {}) do
    local start_row, start_col, end_row, end_col = captures[2]:range()
    local row_diff = end_row - start_row
    local col_diff = end_col - start_col
    if row_diff == 0 and col_diff > min_chars then
      vim.api.nvim_buf_set_extmark(bufnr, namespace, start_row, start_col, {
        end_line = end_row,
        end_col = end_col,
        conceal = metadata[2].conceal,
        priority = 5001,
      })
    end
  end
end

function M.wrap_range(bufnr, range, before, after)
  local lines = vim.api.nvim_buf_get_lines(bufnr, range[1], range[3] + 1, true)
  local last_line = lines[#lines]
  local with_after = last_line:gsub("()", { [range[4] + 1] = after })
  lines[#lines] = with_after

  local first_line = lines[1]
  local with_before = first_line:gsub("()", { [range[2] + 1] = before })
  lines[1] = with_before

  vim.api.nvim_buf_set_lines(bufnr, range[1], range[3] + 1, true, lines)
end

function M.wrap_cursor_node(before, after)
  local ts_utils = require("nvim-treesitter.ts_utils")
  local winnr = 0
  local node = ts_utils.get_node_at_cursor(winnr)

  if node then
    local bufnr = vim.api.nvim_win_get_buf(winnr)
    local range = { node:range() }
    M.wrap_range(bufnr, range, before, after)
  else
    vim.notify("Wrap: Node not found", vim.log.levels.WARN)
  end
end

function M.wrap_selected_nodes(before, after)
  local start = vim.fn.getpos("'<")
  local end_ = vim.fn.getpos("'>")
  local bufnr = 0

  local start_node = vim.treesitter.get_node({ bufnr = 0, pos = { start[2] - 1, start[3] - 1 } })
  local end_node = vim.treesitter.get_node({ bufnr = 0, pos = { end_[2] - 1, end_[3] - 1 } })
  local start_range = { start_node:range() }
  local end_range = { end_node:range() }

  local range = { start_range[1], start_range[2], end_range[3], end_range[4] }

  M.wrap_range(bufnr, range, before, after)
end

--- Convert a list or map of items into a value by iterating all it's fields and transforming
--- them with a callback
---@generic T : table
---@param callback fun(T, T, key: string | number): T
---@param list T[]
---@param accum T
---@return T
function M.fold(callback, list, accum)
  for k, v in pairs(list) do
    accum = callback(accum, v, k)
    assert(accum ~= nil, "The accumulator must be returned on each iteration")
  end
  return accum
end

---@generic T:table
---@param callback fun(item: T, key: any)
---@param list table<any, T>
function M.foreach(callback, list)
  for k, v in pairs(list) do
    callback(v, k)
  end
end

--- Check if the target matches  any item in the list.
---@param target string
---@param list string[]
---@return boolean
function M.any(target, list)
  for _, item in ipairs(list) do
    if target:match(item) then return true end
  end
  return false
end

---Find an item in a list
---@generic T
---@param haystack T[]
---@param matcher fun(arg: T):boolean
---@return T
function M.find(haystack, matcher)
  local found
  for _, needle in ipairs(haystack) do
    if matcher(needle) then
      found = needle
      break
    end
  end
  return found
end

function M.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end

--- automatically clear commandline messages after a few seconds delay
--- source: http://unix.stackexchange.com/a/613645
---@return function
function M.clear_commandline()
  --- Track the timer object and stop any previous timers before setting
  --- a new one so that each change waits for 10secs and that 10secs is
  --- deferred each time
  local timer
  return function()
    if timer then timer:stop() end
    timer = vim.defer_fn(function()
      if fn.mode() == "n" then vim.cmd([[echon '']]) end
    end, 2500)
  end
end

function M.is_chonky(bufnr, filepath)
  local max_filesize = 50 * 1024 -- 50 KB
  local max_length = 5000

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  filepath = filepath or vim.api.nvim_buf_get_name(bufnr)
  local is_too_long = vim.api.nvim_buf_line_count(bufnr) >= max_length
  local is_too_large = false

  local ok, stats = pcall(vim.loop.fs_stat, filepath)
  if ok and stats and stats.size > max_filesize then is_too_large = true end

  return (is_too_long or is_too_large)
end

function M.exec(c, bool)
  bool = bool or true
  vim.api.nvim_exec(c, bool)
end

function M.has(feature) return fn.has(feature) > 0 end

function M.has_plugin(plugin) return require("lazy.core.config").spec.plugins[plugin] ~= nil end

function M.executable(e) return fn.executable(e) > 0 end
--

-- https://www.reddit.com/r/neovim/comments/nrz9hp/can_i_close_all_floating_windows_without_closing/h0lg5m1/
function M.close_float_wins()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then vim.api.nvim_win_close(win, false) end
    end
  end
end

function M.save_and_exec()
  if vim.bo.filetype == "vim" then
    vcmd("silent! write")
    vcmd("source %")
    vim.notify("wrote and sourced vim file..", vim.log.levels.INFO, { title = "nvim" })
  elseif vim.bo.filetype == "lua" then
    vcmd("silent! write")
    vcmd("luafile %")
    vim.notify("wrote and sourced lua file..", vim.log.levels.INFO, { title = "nvim" })
  end
end

---Check whether or not the location or quickfix list is open
---@return boolean
function M.is_vim_list_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local location_list = fn.getloclist(0, { filewinid = 0 })
    local is_loc_list = location_list.filewinid > 0
    if vim.bo[buf].filetype == "qf" or is_loc_list then return true end
  end
  return false
end

function M.showCursorHighlights() vim.cmd("TSHighlightCapturesUnderCursor") end

---Determine if a value of any type is empty
---@param item any
---@return boolean?
function M.falsy(item)
  if not item then return true end
  local item_type = type(item)
  if item_type == "boolean" then return not item end
  if item_type == "string" then return item == "" end
  if item_type == "number" then return item <= 0 end
  if item_type == "table" then return vim.tbl_isempty(item) end
  return item ~= nil
end

---Determine if a value of any type is empty
---@param item any
---@return boolean
function M.empty(item)
  if not item then return true end
  local item_type = type(item)
  if item_type == "string" then
    return item == ""
  elseif item_type == "number" then
    return item <= 0
  elseif item_type == "table" then
    return vim.tbl_isempty(item)
  else
    return true
  end
end

function M.debounce(ms, fn)
  local timer = vim.loop.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

function M.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function()
        running = false
        pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
      end)
      running = true
    end
  end
end

--- Debounces a function on the trailing edge. Automatically
--- `schedule_wrap()`s.
---
-- @param fn (function) Function to debounce
-- @param timeout (number) Timeout in ms
-- @param first (boolean, optional) Whether to use the arguments of the first
---call to `fn` within the timeframe. Default: Use arguments of the last call.
-- @returns (function, timer) Debounced function and timer. Remember to call
---`timer:close()` at the end or you will leak memory!
function M.debounce_trailing(func, ms, first)
  local timer = vim.loop.new_timer()
  local wrapped_fn

  if not first then
    function wrapped_fn(...)
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function() pcall(vim.schedule_wrap(func), unpack(argv, 1, argc)) end)
    end
  else
    local argv, argc
    function wrapped_fn(...)
      argv = argv or { ... }
      argc = argc or select("#", ...)

      timer:start(ms, 0, function() pcall(vim.schedule_wrap(func), unpack(argv, 1, argc)) end)
    end
  end
  return wrapped_fn, timer
end

function M.starts_with(haystack, needle) return type(haystack) == "string" and haystack:sub(1, needle:len()) == needle end

function M.clear_ui(opts)
  opts = opts or {}
  local deluxe = opts["deluxe"]
  -- vcmd([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]])
  -- Clear / search term
  -- vim.fn.setreg("/", "")

  -- Stop highlighting searches
  vim.cmd.nohlsearch()

  vim.cmd.diffupdate()
  vim.cmd("syntax sync fromstart")
  M.close_float_wins()

  if plugin_loaded("cursorline") then mega.blink_cursorline() end
  vim.cmd.redraw({ bang = true })

  do
    local ok, mj = pcall(require, "mini.jump")
    if ok then mj.stop_jumping() end
  end

  do
    local ok, n = pcall(require, "notify")
    if ok then n.dismiss() end
  end

  M.clear_commandline()
end

--- Utility function to toggle the location or the quickfix list
---@param list_type '"quickfix"' | '"location"'
---@return nil
function M.toggle_list(list_type)
  local is_location_target = list_type == "location"
  local prefix = is_location_target and "l" or "c"
  local L = vim.log.levels
  local is_open = M.is_vim_list_open()
  if is_open then return fn.execute(prefix .. "close") end
  local list = is_location_target and fn.getloclist(0) or fn.getqflist()
  if vim.tbl_isempty(list) then
    local msg_prefix = (is_location_target and "Location" or "QuickFix")
    return vim.notify(msg_prefix .. " List is Empty.", L.WARN)
  end

  local winnr = fn.winnr()
  fn.execute(prefix .. "open")
  if fn.winnr() ~= winnr then vim.cmd("wincmd p") end
end

M.capitalize = function(str) return (str:gsub("^%l", string.upper)) end

---@param haystack string
---@param needle string
---@return boolean found true if needle in haystack
M.starts_with = function(haystack, needle) return type(haystack) == "string" and haystack:sub(1, needle:len()) == needle end

-- alt F ғ (ghayn)
-- alt Q ꞯ (currently using ogonek)
local smallcaps = "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ‹›⁰¹²³⁴⁵⁶⁷⁸⁹"
local normal = "ABCDEFGHIJKLMNOPQRSTUVWXYZ<>0123456789"

---@param text string
M.smallcaps = function(text) return vim.fn.tr(text:upper(), normal, smallcaps) end

return M
