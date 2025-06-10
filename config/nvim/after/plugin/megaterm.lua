if not Plugin_enabled() then return end

local api = vim.api
local M = {}

local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local map = vim.keymap.set
local fmt = string.format
local set_buf = api.nvim_set_current_buf
local command = vim.api.nvim_create_user_command

vim.g.megaterms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
  ["bo sp"] = { resize = "height", area = "lines" },
  ["bo vsp"] = { resize = "width", area = "columns" },
}

local config = {
  term_opts = {},
  win_opts = {
    number = false,
    relativenumber = false,
    winhighlight = table.concat({
      "Normal:PanelBackground",
      "CursorLine:PanelBackground",
      "CursorLineNr:PanelBackground",
      "CursorLineSign:PanelBackground",
      "SignColumn:PanelBackground",
      "FloatBorder:PanelBorder",
    }, ","),
  },
  sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
  float = {
    relative = "editor",
    row = 0.3,
    col = 0.25,
    width = 0.5,
    height = 0.4,
    border = "single",
  },
}

-- used for initially resizing terms
vim.g.megatermh = false
vim.g.megatermv = false

-------------------------- util funcs -----------------------------
local function set_term_opts(buf, opts, should_bufdelete)
  dbg(should_bufdelete)
  should_bufdelete = should_bufdelete ~= nil and should_bufdelete or false
  dbg(should_bufdelete)

  local terms_list = vim.g.megaterms
  terms_list[tostring(buf)] = opts
  vim.g.megaterms = terms_list

  if opts ~= nil then
    vim.api.nvim_buf_set_var(buf, "term_cmd", opts and opts.cmd or vim.o.shell)
    vim.api.nvim_buf_set_var(buf, "term_buf", buf)
    vim.api.nvim_buf_set_var(buf, "term_win", opts.winnr)
    vim.api.nvim_buf_set_var(buf, "term_dir", opts.dir or "horizontal")
    vim.api.nvim_buf_set_var(buf, "term_id", opts.id)
  end

  if opts == nil and should_bufdelete and vim.api.nvim_buf_is_loaded(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
end

local function get_term_opts_by_id(id)
  local term_opts = nil

  for _, opts in pairs(vim.g.megaterms) do
    if opts.id == id then term_opts = opts end
  end

  dbg({ "found term_opts?", id, term_opts })

  return term_opts
end

local function create_float(buffer, float_opts)
  local opts = vim.tbl_deep_extend("force", config.float, float_opts or {})

  opts.width = math.ceil(opts.width * vim.o.columns)
  opts.height = math.ceil(opts.height * vim.o.lines)
  opts.row = math.ceil(opts.row * vim.o.lines)
  opts.col = math.ceil(opts.col * vim.o.columns)

  vim.api.nvim_open_win(buffer, true, opts)
end

local function set_keymaps(buf, dir)
  local opts = { buffer = buf, silent = false }
  local function quit()
    set_term_opts(buf, nil, true)
    vim.cmd("wincmd p")
  end

  local nmap = function(lhs, rhs) map("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) map("t", lhs, rhs, opts) end

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  tmap("<C-q>", quit)

  nmap("q", quit)
end

local function format_cmd(cmd) return type(cmd) == "string" and cmd or cmd() end

M.display = function(opts)
  opts.pos = opts and opts.pos or "sp"

  if opts.pos == "float" then
    create_float(opts.buf, opts.float_opts)
  else
    vim.cmd(opts.pos)
  end

  local win = api.nvim_get_current_win()
  opts.win = win

  vim.bo[opts.buf].filetype = "megaterm"
  vim.bo[opts.buf].buflisted = false

  -- resize non floating wins initially + or only when they're toggleable
  if (opts.pos == "sp" and not vim.g.megatermh) or (opts.pos == "vsp" and not vim.g.megatermv) or (opts.pos ~= "float") then
    local pos_type = pos_data[opts.pos]
    local size = opts.size and opts.size or config.sizes[opts.pos]
    local new_size = vim.o[pos_type.area] * size
    api["nvim_win_set_" .. pos_type.resize](0, math.floor(new_size))
  end

  api.nvim_win_set_buf(win, opts.buf)

  local win_opts = vim.tbl_deep_extend("force", config.win_opts, opts.win_opts or {})

  for k, v in pairs(win_opts) do
    vim.wo[win][k] = v
  end

  set_keymaps(opts.buf)

  set_term_opts(opts.buf, opts)

  -- custom on_open
  if opts ~= nil and opts.on_open ~= nil and opts.on_open == "function" then
    opts.on_open(opts.buf)
  else
    -- default_on_open
    -- vim.api.nvim_command([[normal! G]])
    vim.cmd.startinsert()
  end
end

local function create(opts)
  local buf_exists = opts.buf
  opts.buf = opts.buf or vim.api.nvim_create_buf(false, true)

  -- handle cmd opt
  local shell = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX) or vim.o.shell
  local cmd = shell

  if opts.cmd and opts.buf then cmd = fmt("%s -c %s; %s", shell, format_cmd(opts.cmd), shell) end

  M.display(opts)

  set_term_opts(opts.buf, opts)

  if not buf_exists then
    local term_cmd = (opts and opts.pre_cmd) and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd
    vim.fn.termopen(cmd, opts.termopen_opts or {
      ---@diagnostic disable-next-line: unused-local
      on_exit = function(job_id, exit_code, event)
        if opts and opts.on_exit ~= nil and type(opts.on_exit) == "function" then
          opts.on_exit(job_id, exit_code, event, term_cmd, opts and opts.caller_winnr, opts.buf)
        else
          vim.defer_fn(function()
            if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
              set_term_opts(opts.buf, nil, true)
            else
              vim.notify(fmt("exit status: %s/%s/%s", job_id, exit_code, event), L.debug)
            end
          end, 100)
        end

        if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(term_cmd, exit_code) end
        vim.cmd([[wincmd p]])
      end,
      detach = false,
    })
  end

  vim.g.megatermh = opts.pos == "sp"
  vim.g.megatermv = opts.pos == "vsp"
end

--------------------------- user api -------------------------------
--- @class MegatermOpts
--- @field id? string
--- @field dir? "horizontal"|"vertical"|"float"|"tab"
--- @field buf? number
--- @field win? number
--- @field size? number
--- @field cmd? string
--- @field pre_cmd? string
--- @field on_open? function
--- @field on_exit? function
--- @field notifier? function
--- @field focus_on_open? boolean,
--- @field move_on_dir_change? boolean,
--- @field toggle? boolean,
--- @field caller_winnr? number
--- @field start_insert? boolean
--- @field temp? boolean
--- @field job_id? number

M.new = function(opts) create(opts) end

M.toggle = function(opts)
  local x = get_term_opts_by_id(opts.id)
  opts.buf = x and x.buf or nil

  if (x == nil or not api.nvim_buf_is_valid(x.buf)) or vim.fn.bufwinid(x.buf) == -1 then
    create(opts)
  else
    api.nvim_win_close(x.win, true)
  end
end

-- spawns term with *cmd & runs the *cmd if the keybind is run again
M.runner = function(opts)
  local x = get_term_opts_by_id(opts.id)
  local clear_cmd = opts.clear_cmd or "clear; "
  opts.buf = x and x.buf or nil

  -- if buf doesnt exist
  if x == nil then
    create(opts)
  else
    -- window isnt visible
    if vim.fn.bufwinid(x.buf) == -1 then M.display(opts) end

    local cmd = format_cmd(opts.cmd)

    if x.buf == api.nvim_get_current_buf() then
      set_buf(vim.g.buf_history[#vim.g.buf_history - 1])
      cmd = format_cmd(opts.cmd)
      set_buf(x.buf)
    end

    local job_id = vim.b[x.buf].terminal_job_id
    vim.api.nvim_chan_send(job_id, clear_cmd .. cmd .. " \n")

    if opts ~= nil and opts.on_open ~= nil and opts.on_open == "function" then opts.on_open(opts.buf) end
  end
end

command("CT", function(opts) M.toggle({ pos = "sp", id = "megaterm_toggle" }) end, { nargs = "*" })
map({ "n", "t" }, "<C-;>", function() M.toggle({ pos = "sp", id = "megaterm_toggle" }) end, { desc = "term: toggle" })

mega.tt = M

return M
