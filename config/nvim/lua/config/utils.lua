if not mega then return end

local fn = vim.fn
local api = vim.api
local fmt = string.format
local levels = vim.log.levels
local L = levels
local SETTINGS = require("config.options")
local get_node = vim.treesitter.get_node
local cur_pos = vim.api.nvim_win_get_cursor

local M = {
  hl = {},
  lsp = {},
  notes = {},
  strings = {},
  commands = {},
  ts = {},
}

function M.ts.get_language_tree_for_cursor_location(bufnr)
  bufnr = bufnr or 0
  local cursor = vim.api.nvim_win_get_cursor(bufnr)
  local language_tree = vim.treesitter.get_parser(bufnr):language_for_range({ cursor[1], cursor[2], cursor[1], cursor[2] })

  return language_tree
end

---@param types string[] Will return the first node that matches one of these types
---@param node TSNode|nil
---@return TSNode|nil
function M.ts.find_node_ancestor(types, node)
  if not node then return nil end

  if vim.tbl_contains(types, node:type()) then return node end

  local parent = node:parent()

  return M.ts.find_node_ancestor(types, parent)
end

function M.lsp.is_enabled_elixir_ls(client, enabled_clients)
  local client_name = type(client) == "table" and client.name or client
  enabled_clients = enabled_clients or SETTINGS.enabled_elixir_ls

  return vim.tbl_contains(enabled_clients, client_name)
end

---@param data { old_name: string, new_name: string }
local function prepare_file_rename(data)
  local bufnr = vim.fn.bufnr(data.old_name)
  for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    local rename_path = { "server_capabilities", "workspace", "fileOperations", "willRename" }
    if not vim.tbl_get(client, rename_path) then return vim.notify(fmt("%s does not LSP file rename", client.name), L.INFO, { title = "LSP" }) end
    local params = {
      files = { { newUri = "file://" .. data.new_name, oldUri = "file://" .. data.old_name } },
    }
    ---@diagnostic disable-next-line: invisible
    local resp = client:request_sync("workspace/willRenameFiles", params, 1000, bufnr)
    if resp then vim.lsp.util.apply_workspace_edit(resp.result, client.offset_encoding) end
  end
end

function M.lsp.rename_file()
  local old_name = vim.api.nvim_buf_get_name(0)
  local cursor_pos = vim.api.nvim_win_get_cursor(0) -- Save the cursor position
  -- vim.fs.basename(old_name)
  -- nvim_buf_get_name(0)
  -- -- -> fnamemodify(':t')
  -- vim.fs.basename(vim.api.nvim_buf_get_name(0))
  vim.ui.input({ prompt = fmt("rename %s to -> ", vim.fs.basename(old_name)) }, function(name)
    if not name then return end
    local new_name = fmt("%s/%s", vim.fs.dirname(old_name), name)
    prepare_file_rename({ old_name = old_name, new_name = new_name })
    vim.lsp.util.rename(old_name, new_name)

    -- Restore the cursor position
    vim.api.nvim_win_set_cursor(0, cursor_pos)
    -- Redraw the screen
    vim.cmd("redraw!")
  end)
end

---Gets the text in the last visual selection
--
---@return string text in range
function M.get_selected_text()
  local region = vim.region(0, "'<", "'>", vim.fn.visualmode(), true)

  local chunks = {}
  local maxcol = vim.v.maxcol
  for line, cols in vim.spairs(region) do
    local endcol = cols[2] == maxcol and -1 or cols[2]
    local chunk = vim.api.nvim_buf_get_text(0, line, cols[1], line, endcol, {})[1]
    table.insert(chunks, chunk)
  end
  return table.concat(chunks, "\n")
end

--- Call the given function and use `vim.notify` to notify of any errors
--- this function is a wrapper around `xpcall` which allows having a single
--- error handler for all errors
---@param msg string
---@param func function
---@param ... any
---@return boolean, any
---@overload fun(func: function, ...): boolean, any
function M.pcall(msg, func, ...)
  local args = { ... }
  if type(msg) == "function" then
    local arg = func --[[@as any]]
    args, func, msg = { arg, unpack(args) }, msg, nil
  end
  return xpcall(func, function(err)
    msg = debug.traceback(msg and fmt("%s:\n%s\n%s", msg, vim.inspect(args), err) or err)
    vim.schedule(function() vim.notify(msg, L.ERROR, { title = "ERROR", render = "default" }) end)
  end, unpack(args))
end

-- XPCALL example:
-- function _M.load_module_if_exists(module_name)
--   local status, res = xpcall(function()
--     return require(module_name)
--   end, debug.traceback)
--   if status then
--     return true, res
--   -- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
--   elseif type(res) == "string" and find(res, "module '" .. module_name .. "' not found", nil, true) then
--     return false, res
--   else
--     error("error loading module '" .. module_name .. "':\n" .. res)
--   end
-- end
--

--- Call the given function and use `vim.notify` to notify of any errors
--- this function is a wrapper around `xpcall` which allows having a single
--- error handler for all errors
---@param msg string
---@param func function
---@vararg any
---@return boolean, any
---@overload fun(fun: function, ...): boolean, any
function M.wrap_err(msg, func, ...) return M.pcall(msg, func, ...) end

function M.capitalize(str) return (str:gsub("^%l", string.upper)) end

---@param haystack string
---@param needle string
---@return boolean found true if needle in haystack
function M.starts_with(haystack, needle) return type(haystack) == "string" and haystack:sub(1, needle:len()) == needle end

local smallcaps_mappings = {
  -- alt F ғ (ghayn)
  -- alt Q ꞯ (currently using ogonek)
  alpha = {
    "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ",
    -- "ᴀ ʙ ᴄ ᴅ ᴇ ꜰ ɢ ʜ ɪ ᴊ ᴋ ʟ ᴍ ɴ ᴏ ᴘ ꞯ ʀ ꜱ ᴛ ᴜ ᴠ ᴡ x ʏ ᴢ"
  },
  symbols = {
    "‹›",
    "<>",
  },
  numbers = {
    "⁰¹²³⁴⁵⁶⁷⁸⁹",
    "0123456789",
  },
}

---@class SmallcapsOptions
---@field numbers? boolean whether to smallcaps numbers
---@field symbols? boolean whether to smallcaps symbols

---@param text string
---@param options? SmallcapsOptions
M.smallcaps = function(text, options)
  if not text then return text end

  local result = text:upper()

  result = vim.fn.tr(result, smallcaps_mappings.alpha[1], smallcaps_mappings.alpha[2])

  if not options or options.numbers then result = vim.fn.tr(result, smallcaps_mappings.numbers[1], smallcaps_mappings.numbers[2]) end

  if not options or options.symbols then result = vim.fn.tr(result, smallcaps_mappings.symbols[1], smallcaps_mappings.symbols[2]) end

  return result
end

--- Convert a list or map of items into a value by iterating all it's fields and transforming
--- them with a callback
---@generic T : table
---@param callback fun(T, T, key: string | number): T
---@param list T[]
---@param accum T
---@return T
function M.fold(callback, list, accum)
  accum = accum or {}
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

function M.tcopy(t)
  local u = {}
  for k, v in pairs(t) do
    u[k] = v
  end

  return setmetatable(u, getmetatable(t))
end

function M.tshift(tbl)
  if #tbl == 0 then return nil, {} end

  local first = tbl[1]
  local rest = {}

  for i = 2, #tbl do
    rest[i - 1] = tbl[i]
  end

  return first, rest
end

--- deeply compare two objects and return the diff
--- REF: https://gist.github.com/sapphyrus/fd9aeb871e3ce966cc4b0b969f62f539
function M.compare(o1, o2)
  -- same object
  if o1 == o2 then return nil end

  local o1Type = type(o1)
  local o2Type = type(o2)
  --- different type
  if o1Type ~= o2Type then -- don't expand tables to make it more readable
    return { _1 = o1Type == "table" and o1Type or o1, _2 = o2Type == "table" and o2Type or o2 }
  end
  --- same type but not table, already compared above
  if o1Type ~= "table" then return nil end

  local diff = {}

  -- iterate over o1
  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    diff[key1] = M.compare(value1, value2)
  end

  --- check keys in o2 but missing from o1
  for key2, value2 in pairs(o2) do
    diff[key2] = M.compare(nil, value2)
  end
  local gen, param, state = pairs(diff)
  if gen(param, state) ~= nil then
    return diff
  else
    return nil
  end
end

function M.deep_equals(o1, o2, ignore_mt)
  -- same object
  if o1 == o2 then return true end

  local o1Type = type(o1)
  local o2Type = type(o2)
  --- different type
  if o1Type ~= o2Type then return false end
  --- same type but not table, already compared above
  if o1Type ~= "table" then return false end

  -- use metatable method
  if not ignore_mt then
    local mt1 = getmetatable(o1)
    if mt1 and mt1.__eq then
      --compare using built in method
      return o1 == o2
    end
  end

  -- iterate over o1
  for key1, value1 in pairs(o1) do
    local value2 = o2[key1]
    if value2 == nil or M.deep_equals(value1, value2, ignore_mt) == false then return false end
  end

  --- check keys in o2 but missing from o1
  for key2, _ in pairs(o2) do
    if o1[key2] == nil then return false end
  end

  return true
end

function M.strim(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

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
  local n = M.tlen(lines)
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

--- automatically clear commandline messages after a few seconds delay
--- source: http://unix.stackexchange.com/a/613645
---@return function
function M.clear_commandline(delay)
  --- Track the timer object and stop any previous timers before setting
  --- a new one so that each change waits for 10secs and that 10secs is
  --- deferred each time
  local timer
  return function()
    if timer then timer:stop() end
    if delay == nil then
      if timer then timer:stop() end
      return
    end
    timer = vim.defer_fn(function()
      if fn.mode() == "n" then
        vim.api.nvim_echo({}, false, {})
        vim.cmd.echon("''")
      end
    end, delay)
  end
end

-- local function clear_commandline()
--   --- Track the timer object and stop any previous timers before setting
--   --- a new one so that each change waits for 10secs and that 10secs is
--   --- deferred each time
--   local timer

--   return function()
--     if timer then timer:stop() end

--     timer = vim.defer_fn(function()
--       if vim.fn.mode() == "n" then
--         vim.api.nvim_echo({}, false, {})
--         vim.cmd.echon("''")
--       end
--     end, 10000)
--   end
-- end

-- https://www.reddit.com/r/neovim/comments/nrz9hp/can_i_close_all_floating_windows_without_closing/h0lg5m1/
function M.close_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" and config.relative ~= "win" and config ~= "laststatus" then vim.api.nvim_win_close(win, false) end
    end
  end
end

function M.deluxe_clear_ui(_opts)
  vim.cmd.doautoall("User EscDeluxeStart")
  M.clear_ui({ deluxe = true })
  vim.cmd.doautoall("User EscDeluxeEnd")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", true)
end

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

  M.close_floats()

  pcall(mega.blink_cursorline)

  vim.cmd.redraw({ bang = true })

  -- do
  --   local ok, tsc = pcall(require, "treesitter-context")
  --   if ok then tsc.enable() end
  -- end

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

---Close quickfix and loclist, then delete buffer from buffer list
M.buf_close = function()
  vim.cmd.cclose()
  vim.cmd.lclose()
  local ok, bufremove = pcall(require, "mini.bufremove")
  if ok then
    bufremove.delete(nil, true)
  else
    vim.cmd.bdelete({ bang = true })
  end
  -- user will be on the previous buffer now
  -- BUT the alt buffer (<C-^>) is the one we just deleted!
  -- Set the alt buffer to the previous listed buffer in buflist, or to current
  -- buffer (as if switching back to undeleted buffer)
  local curr = vim.fn.bufnr()
  local prev = nil
  for _, nr in ipairs(vim.api.nvim_list_bufs()) do
    if nr == curr then
      -- set alt buffer to previous listed, or current (no alt)
      vim.cmd(("let @# = %d"):format(prev or curr))
      return
    end
    if vim.bo[nr].buflisted then prev = nr end
  end
end

function M.is_chonky(bufnr, filepath)
  local max_filesize = 50 * 1024 -- 50 KB
  local max_length = 5000

  bufnr = bufnr or vim.api.nvim_get_current_buf()
  filepath = filepath or vim.api.nvim_buf_get_name(bufnr)
  local is_too_long = vim.api.nvim_buf_line_count(bufnr) >= max_length
  local is_too_large = false

  local ok, stats = pcall(vim.uv.fs_stat, filepath)
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
  local timer = vim.uv.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

function M.throttle(ms, fn)
  local timer = vim.uv.new_timer()
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
  local timer = vim.uv.new_timer()
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
    vim.notify("Wrap: Node not found", L.WARN)
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
  fmt = string.format
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

function M.get_visible_qflists()
  -- get winnrs for qflists visible in current tab
  return vim.iter(vim.api.nvim_tabpage_list_wins(0)):filter(function(winnr) return vim.fn.getwininfo(winnr)[1].quickfix == 1 end)
end

function M.qflist_populate(lines, opts)
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

  if opts.open_in_trouble ~= nil and opts.open_in_trouble then
    vim.cmd("Trouble qflist open")
  else
    local commands = table.concat({
      "horizontal copen",
      (opts.scroll_to_end and "normal! G") or "",
      -- (opts.title and require("statusline").set_statusline_cmd(opts.title)) or "",
      "wincmd p",
    }, "\n")

    vim.cmd(commands)
  end
end

local branch_cache = {}
local remote_cache = {}

--- get the path to the root of the current file. The
-- root can be anything we define, such as ".git",
-- "Makefile", etc.
-- see https://www.reddit.com/r/neovim/comments/zy5s0l/you_dont_need_vimrooter_usually_or_how_to_set_up/
-- @tparam  path: file to get root of
-- @treturn path to the root of the filepath parameter
function M.get_path_root(path)
  if path == "" then return end

  local root = vim.b.path_root
  if root ~= nil then return root end

  local root_items = {
    ".git",
  }

  root = vim.fs.root(0, root_items)
  if root == nil then return nil end
  vim.b.path_root = root

  return root
end

-- get the name of the remote repository
function M.get_git_remote_name(root)
  if root == nil then return end

  local remote = remote_cache[root]
  if remote ~= nil then return remote end

  -- see https://stackoverflow.com/a/42543006
  -- "basename" "-s" ".git" "`git config --get remote.origin.url`"
  local cmd = table.concat({ "git", "config", "--get remote.origin.url" }, " ")
  remote = vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then return nil end

  remote = vim.fs.basename(remote)
  if remote == nil then return end

  remote = vim.fn.fnamemodify(remote, ":r")
  remote_cache[root] = remote

  return remote
end

function M.root_has_file(name)
  local cwd = vim.uv.cwd()
  local lsputil = require("lspconfig.util")
  return lsputil.path.exists(lsputil.path.join(cwd, name)), lsputil.path.join(cwd, name)
end

function M.get_bufnrs()
  local bufnrs = vim.tbl_filter(function(bufnr)
    local bufname = vim.api.nvim_buf_get_name(bufnr)

    if not vim.api.nvim_buf_is_loaded(bufnr) then return false end
    if not vim.api.nvim_buf_is_valid(bufnr) then return false end

    if bufname == "" then return false end
    if string.match(bufname, "term:") then return false end
    if vim.bo[bufnr].buftype == "terminal" then return false end
    if vim.bo[bufnr].filetype == "megaterm" then return false end
    if vim.bo[bufnr].filetype == "terminal" then return false end

    if 1 ~= vim.fn.buflisted(bufnr) then return false end

    return true
  end, vim.api.nvim_list_bufs())

  return M.tlen(bufnrs)
end

function M.get_buf_lines(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  return vim.api.nvim_buf_get_lines(bufnr or 0, 0, -1, false)
end

function M.get_buf_current_line(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor[1] - 1
  return vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 1, false)[1] or ""
end

--[[
-- HIGHLIGHTS -----------------------------------------------------------------
--]]

---Convert a hex color to RGB
---@param color string
---@return number
---@return number
---@return number
local function hex_to_rgb(color)
  local hex = color:gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5), 16)
end

local function alter(attr, percent) return math.floor(attr * (100 + percent) / 100) end

---@source https://stackoverflow.com/q/5560248
---@see: https://stackoverflow.com/a/37797380
---Darken a specified hex color
---@param color string
---@param percent number
---@return string
function M.hl.alter_color(color, percent)
  local r, g, b = hex_to_rgb(color)
  if not r or not g or not b then return "NONE" end
  r, g, b = alter(r, percent), alter(g, percent), alter(b, percent)
  r, g, b = math.min(r, 255), math.min(g, 255), math.min(b, 255)
  return fmt("#%02x%02x%02x", r, g, b)
end

function M.hl.extend(target, source, opts) M.hl.set(target, vim.tbl_extend("force", M.hl.get(source), opts or {})) end

--- Check if the current window has a winhighlight
--- which includes the specific target highlight
--- @param win_id integer
--- @vararg string
--- @return boolean, string
function M.hl.winhighlight_exists(win_id, ...)
  local win_hl = vim.wo[win_id].winhighlight
  for _, target in ipairs({ ... }) do
    if win_hl:match(target) ~= nil then return true, win_hl end
  end
  return false, win_hl
end

---@param group_name string A highlight group name
local function get_hl(group_name)
  local ok, hl = pcall(api.nvim_get_hl_by_name, group_name, true)
  if ok then
    hl.foreground = hl.foreground and "#" .. bit.tohex(hl.foreground, 6)
    hl.background = hl.background and "#" .. bit.tohex(hl.background, 6)
    hl[true] = nil -- BUG: API returns a true key which errors during the merge
    return hl
  end
  return {}
end

---A mechanism to allow inheritance of the winhighlight of a specific
---group in a window
---@param win_id number
---@param target string
---@param name string
---@param fallback string
function M.hl.adopt_winhighlight(win_id, target, name, fallback)
  local win_hl_name = name .. win_id
  local _, win_hl = M.hl.winhighlight_exists(win_id, target)
  local hl_exists = fn.hlexists(win_hl_name) > 0
  if hl_exists then return win_hl_name end
  local parts = vim.split(win_hl, ",")
  local found = M.find(parts, function(part) return part:match(target) end)
  if not found then return fallback end
  local hl_group = vim.split(found, ":")[2]
  local bg = M.hl.get_hl(hl_group, "bg")
  M.hl.set_hl(win_hl_name, { background = bg, inherit = fallback })
  return win_hl_name
end

---This helper takes a table of highlights and converts any highlights
---specified as `highlight_prop = { from = 'group'}` into the underlying colour
---by querying the highlight property of the from group so it can be used when specifying highlights
---as a shorthand to derive the right color.
---For example:
---```lua
---  M.set_hl({ MatchParen = {foreground = {from = 'ErrorMsg'}}})
---```
---This will take the foreground colour from ErrorMsg and set it to the foreground of MatchParen.
---@param opts table<string, string|boolean|table<string,string>>
local function convert_hl_to_val(opts)
  for name, value in pairs(opts) do
    if type(value) == "table" and value.from then opts[name] = M.hl.get_hl(value.from, vim.F.if_nil(value.attr, name)) end
  end
end

---@param name string
---@param opts table
function M.hl.set_hl(name, opts)
  assert(name and opts, "Both 'name' and 'opts' must be specified")
  local hl = get_hl(opts.inherit or name)
  convert_hl_to_val(opts)
  opts.inherit = nil
  local ok, msg = pcall(api.nvim_set_hl, 0, name, vim.tbl_deep_extend("force", hl, opts))
  if not ok then vim.notify(fmt("Failed to set %s because: %s", name, msg)) end
end
M.hl.set = M.hl.set_hl

---Get the value a highlight group whilst handling errors, fallbacks as well as returning a gui value
---in the right format
---@param group string
---@param attribute string
---@param fallback string?
---@return string
function M.hl.get_hl(group, attribute, fallback)
  if not group then
    vim.notify("Cannot get a highlight without specifying a group", levels.ERROR)
    return "NONE"
  end
  local hl = get_hl(group)
  attribute = ({ fg = "foreground", bg = "background" })[attribute] or attribute
  local color = hl[attribute] or fallback
  if not color then
    vim.schedule(function() vim.notify(fmt("%s %s does not exist", group, attribute), levels.INFO) end)
    return "NONE"
  end
  -- convert the decimal RGBA value from the hl by name to a 6 character hex + padding if needed
  return color
end
M.hl.get = M.hl.get_hl

function M.hl.clear_hl(name)
  assert(name, "name is required to clear a highlight")
  api.nvim_set_hl(0, name, {})
end
M.hl.clear = M.hl.clear_hl

---Apply a list of highlights
---@param hls table<string, table<string, boolean|string>>
function M.hl.all(hls)
  for name, hl in pairs(hls) do
    M.hl.set_hl(name, hl)
  end
end

function M.hl.group(name, opts) vim.api.nvim_set_hl(0, name, opts) end

---------------------------------------------------------------------------------
-- Plugin highlights
---------------------------------------------------------------------------------
---Apply highlights for a plugin and refresh on colorscheme change
---@param name string plugin name
---@vararg table<string, table> map of highlights
function M.hl.plugin(name, hls)
  name = name:gsub("^%l", string.upper) -- capitalise the name for autocommand convention sake
  M.all(hls)
  mega.augroup(fmt("%sHighlightOverrides", name), {
    {
      event = { "ColorScheme" },
      command = function() M.all(hls) end,
    },
  })
end

---Truncate a string in the middle, inserting a separator.
---
---@param str string The string to be truncated
---@param opts table? Optional parameters
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---@return string string The truncated string
---TODO: be able to choose the position of the separator (left, right, center)
function M.strings.truncateString(str, opts)
  opts = opts or {}

  local length = opts.length or vim.o.columns / 2
  local separator = opts.separator or "..."

  local sep_length = #separator
  local part_length = math.floor((length - sep_length) / 2)

  return str:sub(1, part_length) .. separator .. str:sub(-part_length)
end

---Truncate chunks with a separator while preserving highlight groups.
---
---@param chunks HighlightedChunks A list of `{ text, hl_group }` arrays, each representing a text chunk with specified highlight. `hl_group` element can be omitted for no highlight.
---@param opts table? Optional parameters.
---             length - The maximum allowed length of the string
---             separator - The separator to insert in the middle of the truncated string
---             separator_hg - The highlight group to use for the separator
---@return HighlightedChunks chunks The truncated chunks
---TODO: be able to choose the position of the separator (left, right, center)
---TODO: support chunks nesting
function M.strings.truncateChunks(chunks, opts)
  opts = opts or {}

  local length = opts.length or vim.o.columns / 2
  local separator = opts.separator or "..."
  local separator_hg = opts.separator_hg or ""

  -- calculate total length of all chunks
  local total_length = 0
  for _, chunk in ipairs(chunks) do
    total_length = total_length + #chunk[1]
  end

  -- if total length is less or equal to the maxium length, return the original chunks
  if total_length <= length then return chunks end

  local sep_length = #separator
  local part_length = math.floor((length - sep_length) / 2)
  local truncated_chunks = {}
  local unrolled_chunks = {}

  -- unroll chunks to a linear list of single [character, highlight_group]s
  -- but construct these single character chunks with utf8 encoding
  for _, chunk in ipairs(chunks) do
    local chunk_text = chunk[1]
    local chunk_hg = chunk[2] or ""
    local chunk_length = #chunk_text

    local char_pointer = 1

    while char_pointer <= chunk_length do
      local utf8_char_buffer = chunk_text:sub(char_pointer, char_pointer)

      -- check if the current character is a multi-byte character
      -- assuming all bytes in a "multi-byte" character have a byte value greater than 127
      if string.byte(utf8_char_buffer) >= 128 then
        local next_char_pointer = char_pointer + 1

        while next_char_pointer <= chunk_length do
          local next_char = chunk_text:sub(next_char_pointer, next_char_pointer)

          if string.byte(next_char) >= 128 then
            utf8_char_buffer = utf8_char_buffer .. next_char
            next_char_pointer = next_char_pointer + 1
          else
            break
          end
        end
      end

      -- insert the newly constructed utf8 character into unrolled_chunks as one
      table.insert(unrolled_chunks, { utf8_char_buffer, chunk_hg })

      -- move pointer to the next character
      char_pointer = char_pointer + #utf8_char_buffer
    end
  end

  local pos_start = part_length
  local pos_end = #unrolled_chunks - part_length

  -- loop through each table inside unrolled_chunks and in case it
  -- is not empty and within the range to be truncated remove it
  for k, v in ipairs(unrolled_chunks) do
    local is_string = type(v[1]) == "string"
    local has_text = v[1]:len() > 0
    local is_in_range = k >= pos_start and k <= pos_end

    local is_valid = is_string and has_text and not is_in_range

    if is_valid then table.insert(truncated_chunks, v) end
  end

  table.insert(truncated_chunks, #truncated_chunks / 2, { separator, separator_hg })

  return truncated_chunks
end

function M.echo(chunks, async, opts)
  async = async or false
  opts = opts or {}

  vim.api.nvim_echo(chunks, async, opts)
end

function M.command(name, command, opts)
  opts = opts or {}
  vim.api.nvim_create_user_command(name, command, opts)
end

---An insert mode implementation of `vim.treesitter`'s `get_node`
---@param opts table? Opts to be passed to `get_node`
---@return TSNode node The node at the cursor
local get_node_insert_mode = function(opts)
  opts = opts or {}
  local ins_curs = cur_pos(0)
  ins_curs[1] = math.max(ins_curs[1] - 1, 0)
  ins_curs[2] = math.max(ins_curs[2] - 1, 0)
  opts.pos = ins_curs
  return get_node(opts) --[[@as TSNode]]
end

---Whether or not the cursor is in a JSX-tag region
---@param insert_mode boolean Whether or not the cursor is in insert mode
---@return boolean
function M.in_jsx_tags(insert_mode)
  local current_node = insert_mode and get_node_insert_mode() or get_node()
  return current_node and current_node:__has_ancestor({ "jsx_element" }) or false
end

return M
