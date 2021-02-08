local M = {}

local home = os.getenv("HOME")
local path_sep = M.is_windows and "\\" or "/"
local os_name = vim.loop.os_uname().sysname

function M:load_variables()
  self.is_mac = os_name == "Darwin"
  self.is_linux = os_name == "Linux"
  self.is_windows = os_name == "Windows"
  self.vim_path = home .. path_sep .. ".config" .. path_sep .. "nvim"
  self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep
  self.modules_dir = self.vim_path .. path_sep .. "modules"
  self.path_sep = path_sep
  self.home = home

  return self
end
M:load_variables()

-- check file exists
function M.exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

--- Check if a directory exists in this path
function M.isdir(path)
  -- "/" works on both Unix and Windows
  return M.exists(path .. "/")
end

function M.set_highlight(group, _fg, _bg, _style, _bang)
  local fg, bg, style, bang = "", "", "", ""

  if _fg ~= nil then
    fg = "guifg=" .. _fg
  end

  if _bg ~= nil then
    bg = "guibg=" .. _bg
  end

  if _style ~= nil then
    style = "gui=" .. _style
  end

  if _bang ~= nil and _bang then
    bang = "!"
  end

  vim.api.nvim_exec("highlight" .. bang .. " " .. group .. " " .. fg .. " " .. bg .. " " .. style, true)
end

M.map_opts = {noremap = true, silent = false, expr = false}
function M.map(mode, lhs, rhs, opts)
  opts = vim.tbl_extend("force", M.map_opts, opts or {})
  vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

-- a safe module loader
function M.load(key, req)
  local loaded, loader = pcall(require, req)

  if loaded then
    return loader
  else
    mega.inspect("loading failed", {key, loader}, 4)
  end
end

function M.table_merge(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
end

function M.cmd_map(cmd)
  return string.format("<cmd>%s<cr>", cmd)
end

function M.vcmd_map(cmd)
  return string.format([[<cmd>'<,'>%s<cr>]], cmd)
end

function M.create_mappings(mappings, bufnr)
  local fn = vim.api.nvim_set_keymap
  if bufnr then
    fn = function(...)
      vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
  end

  for mode, rules in pairs(mappings) do
    for _, m in ipairs(rules) do
      fn(mode, m.lhs, m.rhs, m.opts or {})
    end
  end
end

function M.exec_cmds(cmd_list)
  vim.cmd(table.concat(cmd_list, "\n"))
end

function M.au(cmd)
  vim.api.nvim_exec(cmd, true)
end

function M.augroup(group, fn)
  vim.api.nvim_command("augroup " .. group)
  vim.api.nvim_command("autocmd!")
  fn()
  vim.api.nvim_command("augroup END")
end

function M.augroup_cmds(name, commands)
  vim.cmd("augroup " .. name)
  vim.cmd("autocmd!")
  for _, c in ipairs(commands) do
    vim.cmd(
      string.format(
        "autocmd %s %s %s %s",
        table.concat(c.events, ","),
        table.concat(c.targets, ","),
        table.concat(c.modifiers or {}, " "),
        c.command
      )
    )
  end
  vim.cmd("augroup END")
end

-- Split given string with given separator
-- and returns the result as a table.
function M.split(inputstr, separator)
  if separator == nil then
    separator = "%s"
  end
  local t = {}
  for str in string.gmatch(inputstr, "([^" .. separator .. "]+)") do
    table.insert(t, str)
  end
  return t
end

-- Key mapping
function M.map(mode, key, result, opts)
  opts =
    M.table_merge(
    {
      noremap = true,
      silent = true,
      expr = false
    },
    opts or {}
  )

  vim.fn.nvim_set_keymap(mode, key, result, opts)
end

-- Stolen from https://github.com/kyazdani42/nvim-palenight.lua/blob/master/lua/palenight.lua#L10
-- Usage:
-- highlight(Cursor, { fg = bg_dark, bg = yellow })
function M.highlight(group, styles)
  local gui = styles.gui and "gui=" .. styles.gui or "gui=NONE"
  local sp = styles.sp and "guisp=" .. styles.sp or "guisp=NONE"
  local fg = styles.fg and "guifg=" .. styles.fg or "guifg=NONE"
  local bg = styles.bg and "guibg=" .. styles.bg or "guibg=NONE"
  vim.cmd("highlight " .. group .. " " .. gui .. " " .. sp .. " " .. fg .. " " .. bg)
end

-- Usage:
-- highlight({
--      CursorLine   = { bg = bg },
--      Cursor       = { fg = bg_dark, bg = yellow }
-- })
function M.highlights(hi_table)
  for group, styles in pairs(hi_table) do
    M.highlight(group, styles)
  end
end

function M.hiLink(src, dest)
  vim.cmd("highlight link " .. src .. " " .. dest)
end

function M.hiLinks(hi_table)
  for src, dest in pairs(hi_table) do
    M.hiLink(src, dest)
  end
end

function M.debounce(interval_ms, fn)
  local timer = vim.loop.new_timer()
  local last_call = {}

  local make_call = function()
    if #last_call > 0 then
      fn(unpack(last_call))
      last_call = {}
    end
  end
  timer:start(interval_ms, interval_ms, make_call)
  return {
    call = function(...)
      last_call = {...}
    end,
    stop = function()
      make_call()
      timer:close()
    end
  }
end

-- helps with nerdfonts usages
local bytemarkers = {{0x7FF, 192}, {0xFFFF, 224}, {0x1FFFFF, 240}}
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

function M.bmap(mode, key, result, opts)
  local map_opts = opts

  if opts == nil then
    map_opts = {noremap = true, silent = true}
  end

  vim.api.nvim_buf_set_keymap(0, mode, key, result, map_opts)
end

function M.get_icon(icon_name)
  local ICONS = {
    paste = "⍴",
    spell = "✎",
    -- branch = os.getenv('PURE_GIT_BRANCH') ~= '' and fn.trim(os.getenv('PURE_GIT_BRANCH')) or ' ',
    branch = " ",
    error = "×",
    info = "●",
    warn = "!",
    hint = "›",
    lock = "",
    success = " "
    -- success = ' '
  }

  return ICONS[icon_name] or ""
end

function M.get_color(synID, what, mode)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(synID)), what, mode)
end

function M.inspect(k, v, l)
  local should_log = require("vim.lsp.log").should_log(1)
  if not should_log then
    return
  end

  local level = "[DEBUG]"
  if level ~= nil and l == 4 then
    level = "[ERROR]"
  end

  if v then
    print(level .. " " .. k .. " -> " .. vim.inspect(v))
  else
    print(level .. " " .. k .. "..")
  end

  return v
end

function M.pclients()
  M.inspect("active_clients", vim.inspect(vim.lsp.get_active_clients()))
end

function M.pbclients()
  M.inspect("buf_clients", vim.inspect(vim.lsp.buf_get_clients()))
end

function M.phandlers()
  M.inspect("handlers", vim.inspect(vim.lsp.handlers))
end

function M.plogpath()
  M.inspect("log_path", vim.inspect(vim.lsp.get_log_path()))
end

function M.copy(obj, seen)
  if type(obj) ~= "table" then
    return obj
  end
  if seen and seen[obj] then
    return seen[obj]
  end
  local s = seen or {}
  local res = {}
  s[obj] = res
  for k, v in next, obj do
    res[M.copy(k, s)] = M.copy(v, s)
  end
  return setmetatable(res, getmetatable(obj))
end

function M.dump(...)
  local objects = vim.tbl_map(vim.inspect, {...})
  print(unpack(objects))
end

function M.activeLSP()
  local servers = {}
  for _, lsp in pairs(vim.lsp.get_active_clients()) do
    table.insert(servers, {name = lsp.name, id = lsp.id})
  end
  M.dump(servers)
end

function M.bufferActiveLSP()
  local servers = {}
  for _, lsp in pairs(vim.lsp.buf_get_clients()) do
    table.insert(servers, {name = lsp.name, id = lsp.id})
  end
  M.dump(servers)
end

return M
