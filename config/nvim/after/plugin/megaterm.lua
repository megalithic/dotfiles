if not mega then return end

local M = {}

local api = vim.api
local g = vim.g
local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local fmt = string.format
local set_buf = api.nvim_set_current_buf
local command = vim.api.nvim_create_user_command

g.mega_terms = {}

local pos_data = {
  sp = { resize = "height", area = "lines" },
  vsp = { resize = "width", area = "columns" },
  ["bo sp"] = { resize = "height", area = "lines" },
  ["bo vsp"] = { resize = "width", area = "columns" },
}

local config = {
  winopts = {
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

local function save_term_info(index, val)
  local terms_list = g.mega_terms
  terms_list[tostring(index)] = val
  g.mega_terms = terms_list
end

local function opts_to_id(id)
  for _, opts in pairs(g.mega_terms) do
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

  local map = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, opts) end
  local nmap = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) vim.keymap.set("t", lhs, rhs, opts) end

  if direction ~= "tab" then nmap("q", quit) end

  -- map({ "n", "t" }, "<C-;>", [[<cmd>TT<cr>]])

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  tmap("<C-x>", quit)
end

local function format_cmd(cmd) return type(cmd) == "string" and cmd or cmd() end

M.display = function(opts)
  if opts.pos == "float" then
    create_float(opts.buf, opts.float_opts)
  else
    vim.cmd(opts.pos)
  end

  local win = api.nvim_get_current_win()
  opts.win = win

  vim.bo[opts.buf].filetype = "megaterm"
  vim.bo[opts.buf].buflisted = false
  vim.cmd("startinsert")

  -- resize non floating wins initially + or only when they're toggleable
  if (opts.pos == "sp" and not vim.g.megahterm) or (opts.pos == "vsp" and not vim.g.megavterm) or (opts.pos ~= "float") then
    local pos_type = pos_data[opts.pos]
    local size = opts.size and opts.size or config.sizes[opts.pos]
    local new_size = vim.o[pos_type.area] * size
    api["nvim_win_set_" .. pos_type.resize](0, math.floor(new_size))
  end

  api.nvim_win_set_buf(win, opts.buf)

  local winopts = vim.tbl_deep_extend("force", config.winopts, opts.winopts or {})

  for k, v in pairs(winopts) do
    vim.wo[win][k] = v
  end

  set_keymaps(opts.buf, opts.pos)

  save_term_info(opts.buf, opts)
end

local function create(opts)
  local buf_exists = opts.buf
  opts.buf = opts.buf or vim.api.nvim_create_buf(false, true)

  -- handle cmd opt
  local shell = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX) or vim.o.shell
  local cmd = { shell }

  if opts.cmd and opts.buf then
    cmd = { shell, "-c", format_cmd(opts.cmd) .. "; " .. shell }
  else
    cmd = { shell }
  end

  M.display(opts)

  save_term_info(opts.buf, opts)

  if not buf_exists then
    vim.fn.termopen(cmd, opts.termopen_opts or {
      detach = false,

      ---@diagnostic disable-next-line: unused-local
      on_exit = function(job_id, exit_code, event)
        -- if we get a custom on_exit, run it instead...
        if opts and opts.on_exit ~= nil and type(opts.on_exit) == "function" then
          opts.on_exit(job_id, exit_code, event, cmd, opts and opts.caller_winnr, opts.buf)
        else
          vim.defer_fn(function()
            if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
              -- unset_term(true)
            else
              vim.notify(fmt("exit status: %s/%s/%s", job_id, exit_code, event), L.debug)
            end
          end, 100)
        end

        if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(opts.buf, exit_code) end
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
  local x = opts_to_id(opts.id)
  opts.buf = x and x.buf or nil

  if (x == nil or not api.nvim_buf_is_valid(x.buf)) or vim.fn.bufwinid(x.buf) == -1 then
    create(opts)
  else
    api.nvim_win_close(x.win, true)
  end
end

-- spawns term with *cmd & runs the *cmd if the keybind is run again
M.runner = function(opts)
  local x = opts_to_id(opts.id)
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
      set_buf(g.buf_history[#g.buf_history - 1])
      cmd = format_cmd(opts.cmd)
      set_buf(x.buf)
    end

    local job_id = vim.b[x.buf].terminal_job_id
    vim.api.nvim_chan_send(job_id, clear_cmd .. cmd .. " \n")
  end
end

--------------------------- autocmds -------------------------------
api.nvim_create_autocmd("TermClose", {
  callback = function(args) save_term_info(args.buf, nil) end,
})

command("TT", function(opts) M.toggle(opts.args) end, { nargs = "*" })

vim.keymap.set({ "n", "t" }, "<C-;>", function() M.toggle({ pos = "sp", id = "spterm" }) end, { desc = "term: toggle" })

vim.keymap.set({ "n", "v", "i", "t" }, "<C-x>", function()
  M.runner({
    id = "run_and_build_term",
    pos = "vsp",
    cmd = function()
      local file = vim.fn.expand("%")
      local sfile = vim.fn.expand("%:r")
      local ft = vim.bo.ft
      local ft_cmds = {
        sh = "bash " .. file,
        elixir = "elixir " .. file,
        lua = "lua " .. file,
        rust = "cargo " .. file,
        python = "python3 " .. file,
        javascript = "node " .. file,
        java = "javac " .. file .. " && java " .. sfile,
        go = "go build && go run " .. file,
        c = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
        cpp = "g++ " .. file .. " -o " .. sfile .. " && ./" .. sfile,
        typescript = "deno compile " .. file .. " && deno run " .. file,
      }

      -- don't execute this for certain filetypes
      if vim.tbl_contains({ "markdown" }, ft) then return end

      return ft_cmds[ft]
    end,
  })
end, { desc = "term: build and run file" })

return M
