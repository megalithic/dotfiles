local api = vim.api
local fn = vim.fn
local vcmd = vim.cmd
local fmt = string.format

_G.__mega_global_callbacks = __mega_global_callbacks or {}
_G.mega = {
  _store = __mega_global_callbacks,
  functions = {},
  dirs = {},
}
local L = vim.log.levels
local get_log_level = require("vim.lsp.log").get_level

-- Global namespace
--- Inspired by @tjdevries' astraunauta.nvim/ @TimUntersberger's config
--- store all callbacks in one global table so they are able to survive re-requiring this file

function mega:load_variables()
  local home = os.getenv("HOME")
  local path_sep = mega.is_windows and "\\" or "/"
  local os_name = vim.loop.os_uname().sysname

  self.is_macos = os_name == "Darwin"
  self.is_linux = os_name == "Linux"
  self.is_windows = os_name == "Windows"
  self.vim_path = home .. path_sep .. ".config" .. path_sep .. "nvim"
  self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep
  self.local_share_dir = home .. path_sep .. ".local" .. path_sep .. "share" .. path_sep .. "nvim" .. path_sep
  self.modules_dir = self.vim_path .. path_sep .. "modules"
  self.path_sep = path_sep
  self.home = home

  return self
end
mega:load_variables()

mega.dirs.dots = fn.expand("$HOME/.dotfiles")
mega.dirs.icloud = fn.expand("$ICLOUD_DIR")
mega.dirs.docs = fn.expand("$DOCUMENTS_DIR")
mega.dirs.org = fn.expand(mega.dirs.docs .. "/_org")
mega.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

function _G.dump_text(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

local installed
---Check if a plugin is on the system not whether or not it is loaded
---@param plugin_name string
---@return boolean
function mega.plugin_installed(plugin_name)
  if not installed then
    local dirs = fn.expand(fn.stdpath("data") .. "/site/pack/paqs/start/*", true, true)
    local opt = fn.expand(fn.stdpath("data") .. "/site/pack/paqs/opt/*", true, true)
    vim.list_extend(dirs, opt)
    installed = vim.tbl_map(function(path)
      return fn.fnamemodify(path, ":t")
    end, dirs)
  end
  return vim.tbl_contains(installed, plugin_name)
end

--- Check if a directory exists in this path
function mega.isdir(path)
  -- check if file exists
  local function file_exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
      if code == 13 then
        -- Permission denied, but it exists
        return true
      end
    end
    return ok, err
  end

  -- "/" works on both Unix and Windows
  return file_exists(path .. "/")
end

-- TODO: would like to add ability to gather input for continuing; ala `jordwalke/VimAutoMakeDirectory`
function mega.auto_mkdir()
  local dir = fn.expand("%:p:h")

  if fn.isdirectory(dir) == 0 then
    local create_dir = fn.input(string.format("[?] Parent dir [%s] doesn't exist; create it? (y/n)", dir))
    if create_dir == "y" or create_dir == "yes" then
      fn.mkdir(dir, "p")
      vcmd("redraw")
    end
  end
end

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function mega.P(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end
mega.dump = dump

function mega.dump_text(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

function mega.log(msg, hl, reason)
  if hl == nil and reason == nil then
    api.nvim_echo({ { msg } }, true, {})
  else
    local name = "megavim"
    local prefix = name .. " -> "
    if reason ~= nil then
      prefix = name .. " -> " .. reason .. "\n"
    end
    hl = hl or "DiagnosticDefaultInformation"
    api.nvim_echo({ { prefix, hl }, { msg } }, true, {})
  end
end

function mega.warn(msg, reason)
  mega.log(msg, "DiagnosticDefaultWarning", reason)
end

function mega.error(msg, reason)
  mega.log(msg, "DiagnosticDefaultError", reason)
end

function mega.get_log_string(label, level)
  local display_level = "[DEBUG]"
  local hl = "Todo"

  if level ~= nil then
    if level == L.ERROR then
      display_level = "[ERROR]"
      hl = "ErrorMsg"
    elseif level == L.WARN then
      display_level = "[WARNING]"
      hl = "WarningMsg"
    end
  end

  local str = string.format("%s %s", display_level, label)

  return str, hl
end

function mega.inspect(label, v, opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("keep", opts, { data_before = true, level = L.INFO })

  local log_str, hl = mega.get_log_string(label, opts.level)

  -- presently no better API to get the current lsp log level
  -- L.DEBUG == 3
  if opts.level == L.DEBUG and (get_log_level() == L.DEBUG or get_log_level() == 3) then
    if opts.data_before then
      mega.P(v)
      mega.log(log_str, hl)
    else
      mega.log(log_str, hl)
      mega.P(v)
    end
  end

  return v
end

function mega.opt(o, v, scopes)
  scopes = scopes or { vim.o }
  for _, s in ipairs(scopes) do
    s[o] = v
  end
end

-- a safe module loader
function mega.load(module, opts)
  opts = opts or { silent = false, safe = false }

  if opts.key == nil then
    opts.key = "loader"
  end

  local ok, result = pcall(require, module)

  if not ok and (opts.silent ~= nil and not opts.silent) then
    -- REF: https://github.com/neovim/neovim/blob/master/src/nvim/lua/vim.lua#L421
    local level = L.ERROR
    local reason = mega.get_log_string("loading failed", level)

    mega.error(result, reason)
  end

  if opts.safe ~= nil and opts.safe == true then
    return ok, result
  else
    return result
  end
end

function mega.safe_require(module, opts)
  opts = vim.tbl_extend("keep", { safe = true }, opts or {})
  return mega.load(module, opts)
end

function mega._create(f)
  table.insert(mega._store, f)
  return #mega._store
end

function mega._execute(id, args)
  local func = mega._store[id]
  if not func then
    mega.error("function for id doesn't exist: " .. id)
  end
  mega._store[id](args)
  -- return M._store[id](args)
end

function mega.command(args)
  local nargs = args.nargs or 0
  local name = args[1]
  local rhs = args[2]
  local types = (args.types and type(args.types) == "table") and table.concat(args.types, " ") or ""

  if type(rhs) == "function" then
    local fn_id = mega._create(rhs)
    rhs = string.format("lua mega._execute(%d%s)", fn_id, nargs > 0 and ", <f-args>" or "")
  end

  vcmd(string.format("command! -nargs=%s %s %s %s", nargs, types, name, rhs))
end

mega.comm = function(name, fun)
  vim.cmd(string.format("command! %s %s", name, fun))
end

mega.lua_comm = function(name, fun)
  mega.comm(name, "lua " .. fun)
end

---check if a mapping already exists
---@param lhs string
---@param mode string
---@return boolean
function mega.has_map(lhs, mode)
  mode = mode or "n"
  return vim.fn.maparg(lhs, mode) ~= ""
end

---create a mapping function factory
---@param mode string
---@param o table
---@return fun(lhs: string, rhs: string, opts: table|nil) 'create a mapping'
local function make_mapper(mode, o)
  -- copy the opts table as extends will mutate the opts table passed in otherwise
  local parent_opts = vim.deepcopy(o)
  ---Create a mapping
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts table
  return function(lhs, rhs, opts)
    assert(type(rhs) == "string" or type(rhs) == "function", "\"rhs\" should be a function or string")
    -- If the label is all that was passed in, set the opts automagically
    opts = type(opts) == "string" and { label = opts } or opts and vim.deepcopy(opts) or {}

    local force = opts.force or false
    opts.force = nil

    if not force then
      assert(not force and lhs ~= mode, fmt("The lhs should not be the same as mode for %s", lhs))
    end

    local buffer = opts.buffer
    opts.buffer = nil
    if type(rhs) == "function" then
      local fn_id = mega._create(rhs)
      rhs = string.format("<cmd>lua mega._execute(%s)<CR>", fn_id)
    end

    if opts.label then
      local ok, wk = mega.safe_require("which-key", { silent = true })
      if ok then
        wk.register({ [lhs] = opts.label }, { mode = mode })
      end
      opts.label = nil
    end

    opts = vim.tbl_extend("keep", opts, parent_opts)
    if buffer and type(buffer) == "number" then
      return api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
    end

    api.nvim_set_keymap(mode, lhs, rhs, opts)
  end
end

local map_opts = { noremap = false, silent = true }
local noremap_opts = { noremap = true, silent = true }

for _, mode in ipairs({ "n", "x", "i", "v", "o", "t", "s" }) do
  -- {
  -- n = "normal",
  -- v = "visual",
  -- s = "select",
  -- x = "visual & select",
  -- i = "insert",
  -- o = "operator",
  -- t = "terminal",
  -- }

  -- A recursive mapping
  mega[mode .. "map"] = make_mapper(mode, map_opts)
  _G[mode .. "map"] = mega[mode .. "map"]
  -- A non-recursive mapping
  mega[mode .. "noremap"] = make_mapper(mode, noremap_opts)
  _G[mode .. "noremap"] = mega[mode .. "noremap"]
end

-- A recursive commandline mapping
mega.cmap = make_mapper("c", { noremap = false, silent = false })
_G["cmap"] = mega.cmap
-- A non-recursive commandline mapping
mega.cnoremap = make_mapper("c", { noremap = true, silent = false })
_G["cnoremap"] = mega.cnoremap

---Factory function to create multi mode map functions
---e.g. `mega.map({"n", "s"}, lhs, rhs, opts)`
---@param target string
---@return fun(modes: string[], lhs: string, rhs: string, opts: table)
local function multimap(target)
  return function(modes, lhs, rhs, opts)
    for _, m in ipairs(modes) do
      mega[m .. target](lhs, rhs, opts)
    end
  end
end
-- FIXME: these here and above might not work with dynamically gen'd *map and
-- *noremap functions:
mega.mmap = multimap("map")
mega.mnoremap = multimap("noremap")

-- my original mapper
mega.map = function(modes, lhs, rhs, opts)
  -- TODO: extract these to a function or a module var
  local default_opts = { noremap = false, silent = true, expr = false, nowait = false }

  -- assert(lhs ~= mode, fmt("The lhs should not be the same as mode for %s", lhs))
  assert(type(rhs) == "string" or type(rhs) == "function", "\"rhs\" should be a function or string")
  -- If the label is all that was passed in, set the opts automagically
  opts = type(opts) == "string" and { label = opts } or opts and vim.deepcopy(opts) or {}

  -- local buffer = opts.buffer
  -- opts.buffer = nil
  -- local label = opts.label
  -- opts.label = nil

  -- -- this let's us pass in local lua functions without having to shove them on
  -- -- the global first!
  -- if type(rhs) == "function" then
  --   local fn_id = mega._create(rhs)
  --   if opts.expr then
  --     rhs = ([[luaeval('mega._execute(%d)')]]):format(fn_id)
  --   else
  --     rhs = ("<cmd>lua mega._execute(%d)<cr>"):format(fn_id)
  --   end
  -- end

  local buffer = opts.buffer
  opts.buffer = nil
  if type(rhs) == "function" then
    local fn_id = mega._create(rhs)
    rhs = string.format("<cmd>lua mega._execute(%s)<CR>", fn_id)
  end

  -- handle single mode being given
  if type(modes) ~= "table" then
    modes = { modes }
  end

  for i = 1, #modes do
    -- auto-register which-key entry
    if opts.label then
      local ok, wk = mega.safe_require("which-key", { silent = true })
      if ok then
        wk.register({ [lhs] = opts.label }, { mode = modes[i] })
      end
      opts.label = nil
    end

    opts = vim.tbl_extend("keep", opts, default_opts)
    -- auto switch between buffer mode or not
    if buffer and type(buffer) == "number" then
      api.nvim_buf_set_keymap(buffer, modes[i], lhs, rhs, opts)
      -- return api.nvim_buf_set_keymap(buffer, modes[i], lhs, rhs, opts)
    else
      vim.api.nvim_set_keymap(modes[i], lhs, rhs, opts)
    end
    -- vim.api.nvim_set_keymap(modes[i], lhs, rhs, opts)
  end
end

function mega.bmap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true, expr = false, buffer = 0 }
  mode = mode or "n"

  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end

  mega.map(mode, lhs, rhs, opts)
end

-- this assumes the first buffer (0); refactor to accept a buffer
-- TODO: _deprecate_ this immediately
function mega.bufmap(lhs, rhs, mode, expr)
  if 0 == vim.api.nvim_get_current_buf() then
    mega.log("`bufmap` is deprecated; please use `bmap` instead.")
  end

  local opts = { noremap = true, silent = true, expr = expr, buffer = 0 }
  mega.bmap(mode, lhs, rhs, opts)
end

function mega.au(s)
  vcmd("au!" .. s)
end

local function is_valid_target(command)
  local valid_type = command.targets and vim.tbl_islist(command.targets)
  return valid_type or vim.startswith(command.events[1], "User ")
end
function mega.augroup(name, commands)
  vcmd("augroup " .. name)
  vcmd("autocmd!")
  for _, c in ipairs(commands) do
    if c.command and c.events and is_valid_target(c) then
      local command = c.command
      if type(command) == "function" then
        local fn_id = mega._create(command)
        command = string.format("lua mega._execute(%s)", fn_id)
      end
      c.events = type(c.events) == "string" and { c.events } or c.events
      vcmd(
        string.format(
          "autocmd %s %s %s %s",
          table.concat(c.events, ","),
          table.concat(c.targets or {}, ","),
          table.concat(c.modifiers or {}, " "),
          command
        )
      )
    else
      vim.notify(string.format("An autocommand in %s is specified incorrectly: %s", name, vim.inspect(name)), L.ERROR)
    end
  end
  vcmd("augroup END")
end

--- TODO eventually move to using `nvim_set_hl`
--- however for the time being that expects colors
--- to be specified as rgb not hex
---@param name string
---@param opts table
function mega.highlight(name, opts)
  local force = opts.force or true
  if name and vim.tbl_count(opts) > 0 then
    if opts.link and opts.link ~= "" then
      vcmd("highlight" .. (force and "!" or "") .. " link " .. name .. " " .. opts.link)
    else
      local hi_opt = { "highlight", name }
      if opts.guifg and opts.guifg ~= "" then
        table.insert(hi_opt, "guifg=" .. opts.guifg)
      end
      if opts.guibg and opts.guibg ~= "" then
        table.insert(hi_opt, "guibg=" .. opts.guibg)
      end
      if opts.gui and opts.gui ~= "" then
        table.insert(hi_opt, "gui=" .. opts.gui)
      end
      if opts.guisp and opts.guisp ~= "" then
        table.insert(hi_opt, "guisp=" .. opts.guisp)
      end
      if opts.cterm and opts.cterm ~= "" then
        table.insert(hi_opt, "cterm=" .. opts.cterm)
      end
      vcmd(table.concat(hi_opt, " "))
    end
  end
end
mega.hi = mega.highlight

function mega.hi_link(src, dest)
  vcmd("hi! link " .. src .. " " .. dest)
end

function mega.exec(c, bool)
  bool = bool or true
  api.nvim_exec(c, bool)
end

function mega.noop()
  return
end

---A terser proxy for `nvim_replace_termcodes`
---@param str string
---@return any
function mega.replace_termcodes(str)
  return api.nvim_replace_termcodes(str, true, true, true)
end

-- essentially allows for a ternary operator of sorts
function mega._if(bool, a, b)
  if bool then
    return a
  else
    return b
  end
end

function mega.table_merge(t1, t2, opts)
  opts = opts or { strategy = "deep" }

  if opts.strategy == "deep" then
    -- # deep_merge:
    for k, v in pairs(t2) do
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
        mega.table_merge(t1[k], t2[k])
      else
        t1[k] = v
      end
    end
  else
    -- # shallow_merge:
    for k, v in pairs(t2) do
      t1[k] = v
    end
  end

  return t1
end

mega.deep_merge = function(...)
  mega.table_merge(..., { strategy = "deep" })
end

mega.shallow_merge = function(...)
  mega.table_merge(..., { strategy = "shallow" })
end

function mega.iter(list_or_iter)
  if type(list_or_iter) == "function" then
    return list_or_iter
  end

  return coroutine.wrap(function()
    for i = 1, #list_or_iter do
      coroutine.yield(list_or_iter[i])
    end
  end)
end

function mega.reduce(list, memo, func)
  for i in mega.iter(list) do
    memo = func(memo, i)
  end
  return memo
end

-- helps with nerdfonts usages
local bytemarkers = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
function mega.utf8(decimal)
  if decimal < 128 then
    return string.char(decimal)
  end
  local charbytes = {}
  for bytes, vals in ipairs(bytemarkers) do
    if decimal <= vals[1] then
      for b = bytes + 1, 2, -1 do
        local mod = decimal % 64
        decimal = (decimal - mod) / 64
        charbytes[b] = string.char(128 + mod)
      end
      charbytes[1] = string.char(vals[2] + decimal)
      break
    end
  end
  return table.concat(charbytes)
end

function mega.has(feature)
  return fn.has(feature) > 0
end

function mega.executable(e)
  return fn.executable(e) > 0
end

-- open URI under cursor
function mega.open_uri()
  local Job = require("plenary.job")
  local uri = vim.fn.expand("<cWORD>")
  Job
    :new({
      "open",
      uri,
    })
    :sync()
end

function mega.save_and_exec()
  if vim.bo.filetype == "vim" then
    vcmd("silent! write")
    vcmd("source %")
  elseif vim.bo.filetype == "lua" then
    vcmd("silent! write")
    vcmd("luafile %")
  end
end

---Find an item in a list
---@generic T
---@param haystack T[]
---@param matcher fun(arg: T):boolean
---@return T
function mega.find(haystack, matcher)
  local found
  for _, needle in ipairs(haystack) do
    if matcher(needle) then
      found = needle
      break
    end
  end
  return found
end

---Determine if a value of any type is empty
---@param item any
---@return boolean
function mega.empty(item)
  if not item then
    return true
  end
  local item_type = type(item)
  if item_type == "string" then
    return item == ""
  elseif item_type == "table" then
    return vim.tbl_isempty(item)
  end
end

function mega.zetty(args)
  local default_opts = {
    cmd = "meeting",
    action = "edit",
    title = "",
    notebook = "",
    tags = "",
    attendees = "",
  }

  local opts = vim.tbl_extend("force", default_opts, args or {})

  local title = string.format([[%s]], string.gsub(opts.title, "|", "&"))

  local content = ""

  if opts.attendees ~= nil and opts.attendees ~= "" then
    content = string.format("Attendees:\n%s\n\n---\n", opts.attendees)
  end

  local changed_title = fn.input(string.format("[?] Change title from [%s] to: ", title))
  if changed_title ~= "" then
    title = changed_title
  end

  if opts.cmd == "meeting" then
    require("zk.command").new({ title = title, action = "edit", notebook = "meetings", content = content })
  elseif opts.cmd == "new" then
    require("zk.command").new({ title = title, action = "edit" })
  end
end

local border_symbols = {
  vertical = "┃",
  horizontal = "━",
  fill = " ",
  corner = {
    topleft = "┏",
    topright = "┓",
    bottomleft = "┗",
    bottomright = "┛",
  },
}

function border_symbols:draw(width, height)
  local border_lines = {
    table.concat({
      border_symbols.corner.topleft,
      string.rep(border_symbols.horizontal, width),
      border_symbols.corner.topright,
    }),
  }
  local middle_line = table.concat({
    border_symbols.vertical,
    string.rep(border_symbols.fill, width),
    border_symbols.vertical,
  })
  for _ = 1, height do
    table.insert(border_lines, middle_line)
  end
  table.insert(
    border_lines,
    table.concat({
      border_symbols.corner.bottomleft,
      string.rep(border_symbols.horizontal, width),
      border_symbols.corner.bottomright,
    })
  )

  return border_lines
end

function mega.floating_window_big(bufnr)
  local winnr_bak = vim.fn.winnr()
  local altwinnr_bak = vim.fn.winnr("#")

  local width, height = vim.o.columns, vim.o.lines

  local win_width = math.ceil(width * 0.8) - 4
  local win_height = math.ceil(height * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- border
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }

  local border_bufnr = api.nvim_create_buf(false, true)
  local border_lines = border_symbols:draw(win_width, win_height)
  vim.api.nvim_buf_set_lines(border_bufnr, 0, -1, false, border_lines)
  local border_winnr = api.nvim_open_win(border_bufnr, true, border_opts)
  api.nvim_win_set_option(border_winnr, "winblend", 0)
  api.nvim_win_set_option(border_winnr, "winhl", "NormalFloat:")

  -- content
  local win_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }
  local winnr = api.nvim_open_win(bufnr, true, win_opts)

  api.nvim_command(string.format([[autocmd BufWipeout <buffer> execute "silent bwipeout! %d"]], border_bufnr))
  api.nvim_command(
    string.format([[autocmd WinClosed  <buffer> execute "%dwincmd w" | execute "%dwincmd w"]], altwinnr_bak, winnr_bak)
  )

  api.nvim_buf_set_keymap(bufnr, "n", "q", ":q<CR>", { nowait = true, noremap = false, silent = false })
  api.nvim_buf_set_keymap(bufnr, "n", "<ESC><ESC>", ":q<CR>", { nowait = true, noremap = false, silent = false })

  return winnr
end

function mega.floating_window_small(bufnr, opts)
  opts = opts or {}
  local winnr_bak = vim.fn.winnr()
  local altwinnr_bak = vim.fn.winnr("#")

  local width, height = vim.o.columns, vim.o.lines

  local win_width = math.ceil(width * 0.8) - 4
  local win_height = math.ceil(height * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- border
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }

  local border_bufnr = api.nvim_create_buf(false, true)
  local border_lines = border_symbols:draw(win_width, win_height)
  vim.api.nvim_buf_set_lines(border_bufnr, 0, -1, false, border_lines)
  local border_winnr = api.nvim_open_win(border_bufnr, true, border_opts)
  api.nvim_win_set_option(border_winnr, "winblend", 0)
  api.nvim_win_set_option(border_winnr, "winhl", "NormalFloat:")

  -- content
  local win_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }
  local winnr = api.nvim_open_win(bufnr, true, win_opts)

  api.nvim_command(string.format([[autocmd BufWipeout <buffer> execute "silent bwipeout! %d"]], border_bufnr))
  api.nvim_command(
    string.format([[autocmd WinClosed  <buffer> execute "%dwincmd w" | execute "%dwincmd w"]], altwinnr_bak, winnr_bak)
  )

  api.nvim_buf_set_keymap(bufnr, "n", "q", ":q<CR>", { nowait = true, noremap = false, silent = false })
  api.nvim_buf_set_keymap(bufnr, "n", "<ESC><ESC>", ":q<CR>", { nowait = true, noremap = false, silent = false })

  return winnr
end

function mega.get_num_entries(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

function mega.sync_plugins()
  mega.log("paq-nvim: syncing plugins..")

  package.loaded["plugins"] = nil
  require("paq"):setup({ verbose = false })(require("plugins")):sync()
end

--- Usage:
--- 1. Call `local stop = utils.profile('my-log')` at the top of the file
--- 2. At the bottom of the file call `stop()`
--- 3. Restart neovim, the newly created log file should open
function mega.profile(filename)
  local base = "/tmp/config/profile/"
  fn.mkdir(base, "p")
  local success, profile = pcall(require, "plenary.profile.lua_profiler")
  if not success then
    vim.api.nvim_echo({ "Plenary is not installed.", "Title" }, true, {})
  end
  profile.start()
  return function()
    profile.stop()
    local logfile = base .. filename .. ".log"
    profile.report(logfile)
    vim.defer_fn(function()
      vcmd("tabedit " .. logfile)
    end, 1000)
  end
end

local function fileicon()
  local name = fn.bufname()
  local icon, hl
  local loaded, devicons = mega.load("nvim-web-devicons", { safe = true })
  if loaded then
    icon, hl = devicons.get_icon(name, fn.fnamemodify(name, ":e"), { default = true })
  end
  return icon, hl
end

function mega.title_string()
  -- if not hl_ok then
  --   return
  -- end
  local dir = fn.fnamemodify(fn.getcwd(), ":t")
  local icon, _ = fileicon()
  -- if not hl then
  --   return (icon or "") .. " "
  -- end
  return string.format("%s %s ", dir, icon)
  -- return string.format("%s #[fg=%s]%s ", dir, H.get_hl(hl, "fg"), icon)
end

function mega.showCursorHighlights()
  local ft = vim.bo.filetype
  local ts_ft = ft
  -- if ts_ft == "cs" then
  --   ts_ft = "c_sharp"
  -- end
  local is_ts_enabled = require("nvim-treesitter.configs").is_enabled("highlight", ts_ft)
    and require("nvim-treesitter.configs").is_enabled("playground", ts_ft)
  if is_ts_enabled then
    require("nvim-treesitter-playground.hl-info").show_hl_captures()
  else
    local synstack = vim.fn.synstack(vim.fn.line("."), vim.fn.col("."))
    local lmap = vim.fn.map(synstack, "synIDattr(v:val, \"name\")")
    print(vim.fn.join(vim.fn.reverse(lmap), " "))
  end
end

mega.nightly = mega.has("nvim-0.6")

return mega
