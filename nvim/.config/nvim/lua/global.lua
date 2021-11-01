local api, fn, cmd = vim.api, vim.fn, vim.cmd
_G.__mega_global_callbacks = __mega_global_callbacks or {}
local M = {
  _store = __mega_global_callbacks,
  functions = {},
  dirs = {},
}
local L = vim.log.levels
local get_log_level = require("vim.lsp.log").get_level

-- Global namespace
--- Inspired by @tjdevries' astraunauta.nvim/ @TimUntersberger's config
--- store all callbacks in one global table so they are able to survive re-requiring this file

function M:load_variables()
  local home = os.getenv("HOME")
  local path_sep = M.is_windows and "\\" or "/"
  local os_name = vim.loop.os_uname().sysname

  self.is_mac = os_name == "Darwin"
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
M:load_variables()

M.dirs.dots = fn.expand("$HOME/.dotfiles")
M.dirs.icloud = fn.expand("$ICLOUD_DIR")
M.dirs.docs = fn.expand("$DOCUMENTS_DIR")
M.dirs.org = fn.expand(M.dirs.docs .. "/_org")
M.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")

--- Check if a directory exists in this path
function M.isdir(path)
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
function M.auto_mkdir()
  local dir = fn.expand("%:p:h")

  if fn.isdirectory(dir) == 0 then
    local create_dir = fn.input(string.format("[?] Parent dir [%s] doesn't exist; create it? (y|n)", dir))
    if create_dir == "y" or create_dir == "yes" then
      fn.mkdir(dir, "p")
      vim.cmd("redraw")
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
function M.P(...)
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
M.dump = dump

function M.dump_text(...)
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

function M.log(msg, hl, reason)
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

function M.warn(msg, reason)
  M.log(msg, "DiagnosticDefaultWarning", reason)
end

function M.error(msg, reason)
  M.log(msg, "DiagnosticDefaultError", reason)
end

function M.get_log_string(label, level)
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

function M.inspect(label, v, opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("keep", opts, { data_before = true, level = L.INFO })

  local log_str, hl = M.get_log_string(label, opts.level)

  -- presently no better API to get the current lsp log level
  -- L.DEBUG == 3
  if opts.level == L.DEBUG and (get_log_level() == L.DEBUG or get_log_level() == 3) then
    if opts.data_before then
      M.P(v)
      M.log(log_str, hl)
    else
      M.log(log_str, hl)
      M.P(v)
    end
  end

  return v
end

-- a safe module loader
function M.load(module, opts)
  opts = opts or { silent = false, safe = false }

  if opts.key == nil then
    opts.key = "loader"
  end

  local ok, result = pcall(require, module)

  if not ok and not opts.silent then
    -- REF: https://github.com/neovim/neovim/blob/master/src/nvim/lua/vim.lua#L421
    local level = L.ERROR
    local reason = M.get_log_string("loading failed", level)

    M.error(result, reason)
  end

  if opts.safe == true then
    return ok, result
  else
    return result
  end
end

function M._create(f)
  table.insert(M._store, f)
  return #M._store
end

function M._execute(id, args)
  local func = M._store[id]
  if not func then
    M.error("function for id doesn't exist: " .. id)
  end
  M._store[id](args)
  -- return M._store[id](args)
end

function M.command(args)
  local nargs = args.nargs or 0
  local name = args[1]
  local rhs = args[2]
  local types = (args.types and type(args.types) == "table") and table.concat(args.types, " ") or ""

  if type(rhs) == "function" then
    local fn_id = M._create(rhs)
    rhs = string.format("lua mega._execute(%d%s)", fn_id, nargs > 0 and ", <f-args>" or "")
  end

  vim.cmd(string.format("command! -nargs=%s %s %s %s", nargs, types, name, rhs))
end

-- function M.execute(id)
-- 	local func = M.functions[id]
-- 	if not func then
-- 		M.error("Function doest not exist: " .. id)
-- 	end
-- 	return func()
-- end

local function map(modes, lhs, rhs, opts)
  -- TODO: extract these to a function or a module var
  local map_opts = { noremap = true, silent = true, expr = false, nowait = false }

  opts = vim.tbl_extend("force", map_opts, opts or {})
  local buffer = opts.buffer
  opts.buffer = nil

  -- this let's us pass in local lua functions without having to shove them on
  -- the global first!
  if type(rhs) == "function" then
    local fn_id = mega._create(rhs)
    if opts.expr then
      rhs = ([[luaeval('mega._execute(%d)')]]):format(fn_id)
    else
      rhs = ("<cmd>lua mega._execute(%d)<cr>"):format(fn_id)
    end
  end

  -- handle single mode being given
  if type(modes) ~= "table" then
    modes = { modes }
  end

  for i = 1, #modes do
    -- auto switch between buffer mode or not; TODO: deprecate M.bufmap
    if buffer and type(buffer) == "number" then
      vim.api.nvim_buf_set_keymap(buffer, modes[i], lhs, rhs, opts)
    else
      vim.api.nvim_set_keymap(modes[i], lhs, rhs, opts)
    end

    -- auto-register which-key item
    if opts.label then
      local ok, wk = M.load("which-key", { silent = true, safe = true })
      M.P(wk)
      if ok then
        wk.register({ [lhs] = opts.label }, { mode = modes[i] })
      end
      opts.label = nil
    end
  end
end

function M.map(mode, key, rhs, opts)
  return map(mode, key, rhs, opts)
end

-- function M.map(mode, key, rhs, opts, defaults)
-- 	return map(mode, key, rhs, opts, defaults)
-- end

-- function M.nmap(key, rhs, opts)
-- 	return map("n", key, rhs, opts)
-- end
-- function M.vmap(key, rhs, opts)
-- 	return map("v", key, rhs, opts)
-- end
-- function M.xmap(key, rhs, opts)
-- 	return map("x", key, rhs, opts)
-- end
-- function M.imap(key, rhs, opts)
-- 	return map("i", key, rhs, opts)
-- end
-- function M.omap(key, rhs, opts)
-- 	return map("o", key, rhs, opts)
-- end
-- function M.smap(key, rhs, opts)
-- 	return map("s", key, rhs, opts)
-- end

-- function M.nnoremap(key, rhs, opts)
-- 	return map("n", key, rhs, opts, { noremap = true })
-- end
-- function M.vnoremap(key, rhs, opts)
-- 	return map("v", key, rhs, opts, { noremap = true })
-- end
-- function M.xnoremap(key, rhs, opts)
-- 	return map("x", key, rhs, opts, { noremap = true })
-- end
-- function M.inoremap(key, rhs, opts)
-- 	return map("i", key, rhs, opts, { noremap = true })
-- end
-- function M.onoremap(key, rhs, opts)
-- 	return map("o", key, rhs, opts, { noremap = true })
-- end
-- function M.snoremap(key, rhs, opts)
-- 	return map("s", key, rhs, opts, { noremap = true })
-- end

function M.bmap(mode, lhs, rhs, opts)
  opts = opts or { noremap = true, silent = true, expr = false, buffer = 0 }
  mode = mode or "n"

  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end

  M.map(mode, lhs, rhs, opts)
end

-- this assumes the first buffer (0); refactor to accept a buffer
-- TODO: _deprecate_ this immediately
function M.bufmap(lhs, rhs, mode, expr)
  local bufnr = 0

  mode = mode or "n"

  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end

  if bufnr == vim.api.nvim_get_current_buf() then
    mega.log("`bufmap` is deprecated, please use `bmap` instead")
  end
  M.map(mode, lhs, rhs, { noremap = true, silent = true, expr = expr, buffer = bufnr })
end

function M.au(s)
  cmd("au!" .. s)
end

local function is_valid_target(command)
  local valid_type = command.targets and vim.tbl_islist(command.targets)
  return valid_type or vim.startswith(command.events[1], "User ")
end
function M.augroup(name, commands)
  cmd("augroup " .. name)
  cmd("autocmd!")
  for _, c in ipairs(commands) do
    if c.command and c.events and is_valid_target(c) then
      local command = c.command
      if type(command) == "function" then
        local fn_id = mega._create(command)
        command = string.format("lua mega._execute(%s)", fn_id)
      end
      c.events = type(c.events) == "string" and { c.events } or c.events
      vim.cmd(
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
  cmd("augroup END")
end

--- TODO eventually move to using `nvim_set_hl`
--- however for the time being that expects colors
--- to be specified as rgb not hex
---@param name string
---@param opts table
function M.highlight(name, opts)
  local force = opts.force or true
  if name and vim.tbl_count(opts) > 0 then
    if opts.link and opts.link ~= "" then
      cmd("highlight" .. (force and "!" or "") .. " link " .. name .. " " .. opts.link)
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
      cmd(table.concat(hi_opt, " "))
    end
  end
end
M.hi = M.highlight

function M.hi_link(src, dest)
  cmd("hi! link " .. src .. " " .. dest)
end

function M.exec(c, bool)
  bool = bool or true
  api.nvim_exec(c, bool)
end

function M.noop()
  return
end

-- essentially allows for a ternary operator of sorts
function M._if(bool, a, b)
  if bool then
    return a
  else
    return b
  end
end

function M.table_merge(t1, t2, opts)
  opts = opts or { strategy = "deep" }

  if opts.strategy == "deep" then
    -- # deep_merge:
    for k, v in pairs(t2) do
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
        M.table_merge(t1[k], t2[k])
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

M.deep_merge = function(...)
  M.table_merge(..., { strategy = "deep" })
end

M.shallow_merge = function(...)
  M.table_merge(..., { strategy = "shallow" })
end

function M.iter(list_or_iter)
  if type(list_or_iter) == "function" then
    return list_or_iter
  end

  return coroutine.wrap(function()
    for i = 1, #list_or_iter do
      coroutine.yield(list_or_iter[i])
    end
  end)
end

function M.reduce(list, memo, func)
  for i in M.iter(list) do
    memo = func(memo, i)
  end
  return memo
end

-- helps with nerdfonts usages
local bytemarkers = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
function M.utf8(decimal)
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

function M.has(feature)
  return fn.has(feature) > 0
end

-- open URI under cursor
function M.open_uri()
  local Job = require("plenary.job")
  local uri = vim.fn.expand("<cWORD>")
  Job
    :new({
      "open",
      uri,
    })
    :sync()
end

function M.save_and_exec()
  if vim.bo.filetype == "vim" then
    vim.cmd("silent! write")
    vim.cmd("source %")
  elseif vim.bo.filetype == "lua" then
    vim.cmd("silent! write")
    vim.cmd("luafile %")
  end
end

function M.zetty(args)
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

function M.floating_window_big(bufnr)
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

function M.floating_window_small(bufnr, opts)
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

function M.get_num_entries(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

function M.plugins()
  M.log("paq-nvim: syncing plugins..")

  package.loaded["plugins"] = nil
  require("paq"):setup({ verbose = false })(require("plugins")):sync()
end

return M
