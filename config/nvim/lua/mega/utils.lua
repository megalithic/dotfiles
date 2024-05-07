if not mega then return end

local fn = vim.fn
local api = vim.api
local fmt = vim.format
local levels = vim.log.levels
local L = levels
local SETTINGS = require("mega.settings")

local M = {
  hl = {},
  lsp = {},
}

function M.lsp.is_enabled_elixir_ls(client, enabled_clients)
  local client_name = type(client) == "table" and client.name or client
  enabled_clients = enabled_clients or SETTINGS.enabled_elixir_ls

  return vim.tbl_contains(enabled_clients, client_name)
end

function M.lsp.formatting_filter(client, exclusions)
  local client_name = type(client) == "table" and client.name or client
  exclusions = exclusions or SETTINGS.formatter_exclusions

  return not vim.tbl_contains(exclusions, client_name)
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

-- alt F ғ (ghayn)
-- alt Q ꞯ (currently using ogonek)
local smallcaps = "ᴀʙᴄᴅᴇꜰɢʜɪᴊᴋʟᴍɴᴏᴘǫʀsᴛᴜᴠᴡxʏᴢ‹›⁰¹²³⁴⁵⁶⁷⁸⁹"
local normal = "ABCDEFGHIJKLMNOPQRSTUVWXYZ<>0123456789"

---@param text string
function M.smallcaps(text) return vim.fn.tr(text:upper(), normal, smallcaps) end

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

-- https://www.reddit.com/r/neovim/comments/nrz9hp/can_i_close_all_floating_windows_without_closing/h0lg5m1/
function M.close_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" then vim.api.nvim_win_close(win, false) end
    end
  end
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
  local bg = M.get_hl(hl_group, "bg")
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

return M
