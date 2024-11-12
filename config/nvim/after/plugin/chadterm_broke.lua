if true then return end
if not mega then return end

local M = {}

local api = vim.api
local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local map = vim.keymap.set
local fmt = string.format
local set_buf = api.nvim_set_current_buf
local command = vim.api.nvim_create_user_command

vim.g.megaterms = {}

--- @class TermOpts
--- @field id? string
--- @field dir? "horizontal"|"vertical"|"float"|"tab"
--- @field bufnr? number
--- @field winnr? number
--- @field size? number
--- @field cmd? string
--- @field pre_cmd? string
--- @field on_open? function
--- @field on_exit? function
--- @field notifier? function
--- @field job_id? number

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
vim.g.megahterm = false
vim.g.megavterm = false

-------------------------- util funcs -----------------------------

local function save_term_info(bufnr, opts)
  if bufnr == nil then
    vim.notify("[megaterm] bufnr invalid or nil", L.ERROR)
    dbg(opts)

    -- return
  end

  local terms_list = vim.g.megaterms
  terms_list[tostring(bufnr)] = opts
  vim.g.megaterms = terms_list

  if opts ~= nil then
    vim.api.nvim_buf_set_var(bufnr, "term_cmd", opts and opts.cmd or vim.o.shell)
    vim.api.nvim_buf_set_var(bufnr, "term_buf", bufnr)
    vim.api.nvim_buf_set_var(bufnr, "term_win", opts.winnr)
    vim.api.nvim_buf_set_var(bufnr, "term_dir", opts.dir or "horizontal")
    vim.api.nvim_buf_set_var(bufnr, "term_id", opts.id)
  end

  if opts == nil and vim.api.nvim_buf_is_loaded(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end
end

local function get_opts_by_id(id)
  for _, opts in pairs(vim.g.megaterms) do
    if opts.id == id then return opts end
  end
end

local function create_float(buffer, float_opts)
  local opts = vim.tbl_deep_extend("force", config.float, float_opts or {})

  opts.width = math.ceil(opts.width * vim.o.columns)
  opts.height = math.ceil(opts.height * vim.o.lines)
  opts.row = math.ceil(opts.row * vim.o.lines)
  opts.col = math.ceil(opts.col * vim.o.columns)

  vim.api.nvim_open_win(buffer, true, opts)
end

local function set_keymaps(bufnr, direction)
  local opts = { buffer = bufnr, silent = false }
  local function quit()
    save_term_info(bufnr, nil)
    vim.cmd("wincmd p")
  end

  local nmap = function(lhs, rhs) map("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) map("t", lhs, rhs, opts) end

  if direction ~= "tab" then nmap("q", quit) end

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  nmap("q", quit)
end

local function format_cmd(cmd) return type(cmd) == "string" and cmd or cmd() end

M.display = function(opts)
  local pos = opts.pos and opts.pos or "sp"
  if pos == "float" then
    create_float(opts.bufnr, opts.float_opts)
  else
    vim.cmd(pos)
  end

  local win = api.nvim_get_current_win()
  opts.winnr = win

  vim.bo[opts.bufnr].filetype = "megaterm"
  vim.bo[opts.bufnr].buflisted = false
  vim.cmd("startinsert")

  -- resize non floating wins initially + or only when they're toggleable
  if (pos == "sp" and not vim.g.megahterm) or (pos == "vsp" and not vim.g.megavterm) or (pos ~= "float") then
    local pos_type = pos_data[pos]
    local size = opts.size and opts.size or config.sizes[pos]
    local new_size = vim.o[pos_type.area] * size
    api["nvim_win_set_" .. pos_type.resize](0, math.floor(new_size))
  end

  api.nvim_win_set_buf(win, opts.bufnr)

  local win_opts = vim.tbl_deep_extend("force", config.win_opts, opts.win_opts or {})

  for k, v in pairs(win_opts) do
    vim.wo[win][k] = v
  end

  set_keymaps(opts.bufnr, pos)

  save_term_info(opts.bufnr, opts)

  if opts.on_after_open ~= nil and type(opts.on_after_open) == "function" then opts.on_after_open(opts.bufnr, vim.fn.bufwinid(opts.bufnr)) end
end

local function create(opts)
  local buf_exists = opts.bufnr
  opts.bufnr = opts.bufnr or vim.api.nvim_create_buf(false, true)

  local shell = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX) or vim.o.shell
  local cmd = shell

  if opts.cmd and opts.bufnr then cmd = fmt("%s -c %s; %s", shell, format_cmd(opts.cmd), shell) end

  vim.g.term_bufnr = opts.bufnr
  vim.api.nvim_buf_set_var(opts.bufnr, "term_cmd", cmd)

  M.display(opts)

  save_term_info(opts.bufnr, opts)

  if not buf_exists then
    vim.fn.termopen(cmd, opts.termopen_opts or {
      detach = false,

      ---@diagnostic disable-next-line: unused-local
      on_exit = function(job_id, exit_code, event)
        -- if we get a custom on_exit, run it instead...
        if opts and opts.on_exit ~= nil and type(opts.on_exit) == "function" then
          opts.on_exit(job_id, exit_code, event, cmd, opts and opts.caller_winnr, opts.bufnr)
        else
          vim.defer_fn(function()
            if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
              -- unset_term(true)
            else
              vim.notify(fmt("exit status: %s/%s/%s", job_id, exit_code, event), L.debug)
            end
          end, 100)
        end

        if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(opts.bufnr, exit_code) end
        -- vim.cmd(opts.caller_winnr .. [[wincmd w]])
        vim.cmd([[wincmd p]])
      end,
    })
  end

  vim.g.megahterm = opts.pos == "sp"
  vim.g.megavterm = opts.pos == "vsp"
end

--------------------------- user api -------------------------------

M.new = function(opts) create(opts) end

M.toggle = function(opts)
  dbg(opts)

  local x = get_opts_by_id(opts.id)
  opts.bufnr = x and x.bufnr or nil

  if (x == nil or not api.nvim_buf_is_valid(x.bufnr)) or vim.fn.bufwinid(x.bufnr) == -1 then
    create(opts)
  else
    api.nvim_win_close(x.win, true)
  end
end

-- spawns term with *cmd & runs the *cmd if the keybind is run again
M.runner = function(opts)
  opts = get_opts_by_id(opts.id)

  local clear_cmd = opts.clear_cmd or "clear; "
  opts.bufnr = opts and opts.bufnr or nil

  -- if buf doesnt exist
  if opts == nil then
    create(opts)
  else
    -- window isnt visible
    if vim.fn.bufwinid(opts.bufnr) == -1 then M.display(opts) end

    local cmd = format_cmd(opts.cmd)

    if opts.bufnr == api.nvim_get_current_buf() then
      set_buf(vim.g.buf_history[#vim.g.buf_history - 1])
      cmd = format_cmd(opts.cmd)
      set_buf(opts.bufnr)
    end

    local job_id = vim.b[opts.bufnr].terminal_job_id
    vim.api.nvim_chan_send(job_id, clear_cmd .. cmd .. " \n")
  end
end

--------------------------- autocmds -------------------------------

augroup("megaterm_term", { {
  event = { "TermClose" },
  command = function(args) save_term_info(args.buf, nil) end,
} })

command("TT", function(opts) M.toggle(opts.args) end, { nargs = "*" })

map({ "n", "t" }, "<C-;>", function() mega.tt.toggle({ pos = "sp", id = "megaterm_h" }) end, { desc = "term: toggle" })

mega.tt = M

return M
