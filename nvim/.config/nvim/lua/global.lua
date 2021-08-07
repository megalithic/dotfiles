local api, fn, cmd = vim.api, vim.fn, vim.cmd
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

function M.log(msg, hl, name)
  name = name or "megavim"
  hl = hl or "Todo"
  api.nvim_echo({{name .. " -> ", hl}, {msg}}, true, {})
end

function M.warn(msg)
  M.log(msg, "WarningMsg") -- LspDiagnosticsDefaultWarning
end

function M.error(msg)
  M.log(msg, "ErrorMsg") -- LspDiagnosticsDefaultError
end

function M.inspect(k, v, l, f)
  local force = f or false
  local should_log = require("vim.lsp.log").should_log(1)
  if not should_log and not force then
    return
  end

  local level = "[DEBUG]"
  local hl = "WarningMsg"
  if level ~= nil and l == 4 then
    level = "[ERROR]"
    hl = "ErrorMsg"
  end

  if v then
    -- print(level .. " " .. k .. " -> " .. vim.inspect(v))
    M.log(string.format("%s %s: %s", level, k, vim.inspect(v)), hl)
  else
    -- print(level .. " " .. k .. "..")
    M.log(string.format("%s %s", level, k), hl)
  end

  return v
end

-- function M.map(lhs, rhs, mode, expr) -- wait for lua keymaps: neovim/neovim#13823
--   mode = mode or "n"
--   if mode == "n" then
--     rhs = "<cmd>" .. rhs .. "<cr>"
--   end
--   api.nvim_set_keymap(mode, lhs, rhs, {noremap = true, silent = true, expr = expr})
-- end

function M.map(mode, lhs, rhs, opts)
  local map_opts = {noremap = true, silent = true, expr = false}
  opts = vim.tbl_extend("force", map_opts, opts or {})
  api.nvim_set_keymap(mode, lhs, rhs, opts)
end

function M.bufmap(lhs, rhs, mode, expr)
  mode = mode or "n"
  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end
  api.nvim_buf_set_keymap(0, mode, lhs, rhs, {noremap = true, silent = true, expr = expr})
end

function M.au(s)
  cmd("au!" .. s)
end

function M.augroup(group, fun)
  api.nvim_command("augroup " .. group)
  api.nvim_command("autocmd!")
  fun()
  api.nvim_command("augroup END")
end

function M.augroup_cmds(name, commands)
  cmd("augroup " .. name)
  cmd("autocmd!")
  for _, c in ipairs(commands) do
    cmd(
      string.format(
        "autocmd %s %s %s %s",
        table.concat(c.events, ","),
        table.concat(c.targets or {}, ","),
        table.concat(c.modifiers or {}, " "),
        c.command
      )
    )
  end
  cmd("augroup END")
end

--- TODO eventually move to using `nvim_set_hl`
--- however for the time being that expects colors
--- to be specified as rgb not hex
---@param name string
---@param opts table
function M.highlight(name, opts)
  local force = opts.force or false
  if name and vim.tbl_count(opts) > 0 then
    if opts.link and opts.link ~= "" then
      cmd("highlight" .. (force and "!" or "") .. " link " .. name .. " " .. opts.link)
    else
      local hi_opt = {"highlight", name}
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

function M.exec(c)
  api.nvim_exec(c, true)
end

-- a safe module loader
function M.load(req, key)
  if key == nil then
    key = "loader"
  end

  local loaded, loader = pcall(require, req)

  if loaded then
    return loader
  else
    mega.inspect("loading failed", {key, loader}, 4, true)
  end
end

function M.table_merge(dest, src)
  for k, v in pairs(src) do
    dest[k] = v
  end
  return dest
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

function M.dump(...)
  print(unpack(vim.tbl_map(inspect, {...})))
end

function M.zetty(args)
  local default_opts = {
    cmd = "meeting",
    action = "edit",
    title = "",
    notebook = "",
    tags = "",
    attendees = ""
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
    require("zk.command").new({title = title, action = "edit", notebook = "meetings", content = content})
  elseif opts.cmd == "new" then
    require("zk.command").new({title = title, action = "edit"})
  end
end

function M.plugins()
  print("-> syncing plugins..")

  package.loaded["plugins"] = nil
  require("paq"):setup({verbose = false})(require("plugins")):sync()
end

return M
