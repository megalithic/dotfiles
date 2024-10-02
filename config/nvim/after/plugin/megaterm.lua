-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.
--
-- TODO
-- - similar behaviour to here.nvim; aka, quick flip between terminal and current buffer
--    REF: https://github.com/jaimecgomezz/nvim/blob/9a29163c39efc7d28f21ae2ef715e8ba3f41a4e2/lua/plugins/term.lua

if not mega then return end

local fmt = string.format
local api = vim.api
local fn = vim.fn
local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command

vim.g.term_winnr = nil
vim.g.term_bufnr = nil
vim.g.term_tabnr = nil
vim.g.megaterm = nil

local __buftype = "terminal"
local __filetype = "megaterm"

local function is_valid_buffer(bufnr) return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 end
local function is_valid_window(winnr) return winnr ~= nil and (vim.fn.win_gotoid(winnr) == 1 or vim.api.nvim_win_is_valid(winnr)) end

--- @class TermOpts
--- @field direction? "horizontal"|"vertical"|"float"|"tab"
--- @field size? number
--- @field cmd? string
--- @field pre_cmd? string
--- @field on_open? function
--- @field on_exit? function
--- @field notifier? function
--- @field focus_on_open? boolean,
--- @field move_on_direction_change? boolean,
--- @field toggle? boolean,
--- @field caller_winnr? number
--- @field start_insert? boolean
--- @field temp? boolean
--- @field job_id? number

--- @param winnr number
--- @param bufnr number
--- @param tabnr? number
--- @param opts TermOpts
-- --- @return TermOpts
local function set_term(winnr, bufnr, tabnr, opts)
  vim.g.term_winnr = winnr
  vim.g.term_bufnr = bufnr
  vim.g.term_tabnr = tabnr

  -- FIXME: only care about the term global; get rid of the term_*_id globals
  vim.g.megaterm = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr, tabnr = tabnr })
  return vim.g.megaterm
end

local function unset_term(should_delete)
  if should_delete and vim.g.term_bufnr ~= nil and vim.api.nvim_buf_is_loaded(vim.g.term_bufnr) then
    vim.api.nvim_buf_delete(vim.g.term_bufnr, { force = true })
  end
  vim.g.term_bufnr = nil
  vim.g.term_winnr = nil
  vim.g.term_tabnr = nil
  vim.g.megaterm = {}
end

---@class ParsedArgs
---@field direction string?
---@field cmd string?
---@field dir string?
---@field size number?
---@field move_on_direction_change boolean?
---@field toggle boolean?

---Take a users command arguments in the format "cmd='git commit' dir=~/.dotfiles"
---and parse this into a table of arguments
---{cmd = "git commit", dir = "~/.dotfiles"}
---@see https://stackoverflow.com/a/27007701
---@param args string
---@return ParsedArgs|TermOpts
local function command_parser(args)
  local p = {
    single = "'(.-)'",
    double = "\"(.-)\"",
  }

  local result = {}
  if args then
    local quotes = args:match(p.single) and p.single or args:match(p.double) and p.double or nil
    if quotes then
      -- 1. extract the quoted command
      local pattern = "(%S+)=" .. quotes
      for key, value in args:gmatch(pattern) do
        -- Check if the current OS is Windows so we can determine if +shellslash
        -- exists and if it exists, then determine if it is enabled. In that way,
        -- we can determine if we should match the value with single or double quotes.
        quotes = p.single
        value = vim.fn.shellescape(value)
        result[vim.trim(key)] = vim.fn.expandcmd(value:match(quotes))
      end
      -- 2. then remove it from the rest of the argument string
      args = args:gsub(pattern, "")
    end

    for _, part in ipairs(vim.split(args, " ")) do
      if #part > 1 then
        local arg = vim.split(part, "=")
        local key, value = arg[1], arg[2]
        if key == "size" then
          value = tonumber(value)
        elseif vim.tbl_contains({ "move_on_direction_change", "toggle" }, key) then
          value = value ~= "0"
        end
        result[key] = value
      end
    end
  end

  return result
end

local set_win_hls = function(hls)
  hls = hls
    or {
      "Normal:PanelBackground",
      "CursorLine:PanelBackground",
      "CursorLineNr:PanelBackground",
      "CursorLineSign:PanelBackground",
      "SignColumn:PanelBackground",
      "FloatBorder:PanelBorder",
    }

  vim.opt_local.winhighlight = table.concat(hls, ",")
end

local function set_term_opts(term, bufnr)
  bufnr = bufnr or vim.g.term_bufnr
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  pcall(vim.api.nvim_set_option_value, "filetype", __filetype, { buf = bufnr, win = vim.g.term_winnr })
  pcall(vim.api.nvim_set_option_value, "buftype", __buftype, { buf = bufnr, win = vim.g.term_winnr })

  if term ~= nil and vim.tbl_contains({ "float", "tab" }, term.direction) then
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size()
  if vim.g.megaterm and vim.g.megaterm.direction == "vertical" then
    vim.cmd(fmt("let &winwidth=%d", vim.g.megaterm.size))
    vim.opt_local.winfixwidth = true
    vim.opt_local.winminwidth = vim.g.megaterm.size / 2
    vim.api.nvim_win_set_width(vim.g.term_winnr, vim.g.megaterm.size)
  elseif vim.g.megaterm and vim.g.megaterm.direction == "horizontal" then
    vim.cmd(fmt("let &winheight=%d", vim.g.megaterm.size))
    vim.opt_local.winfixheight = true
    vim.opt_local.winminheight = vim.g.megaterm.size / 2
    vim.api.nvim_win_set_height(vim.g.term_winnr, vim.g.megaterm.size)
  end
end

-- TODO: https://github.com/brendalf/mix.nvim/blob/main/lua/mix/window.lua#L1-L26
local create_float = function(bufnr, size, caller_winnr)
  local parsed_size = (size / 100)
  local width = math.ceil(parsed_size * vim.o.columns)
  local height = math.ceil(parsed_size * vim.o.lines)
  -- local row = math.ceil(0.1 * vim.o.lines)
  -- local col = math.ceil(0.1 * vim.o.columns)
  local row = (math.ceil(vim.o.lines - height) / 2) - 1
  local col = (math.ceil(vim.o.columns - width) / 2) - 1

  if false then
    width = math.ceil(math.min(vim.o.columns, math.max(size, vim.o.columns - 20)))
    height = math.ceil(math.min(vim.o.lines, math.max(size, vim.o.lines - 10)))
    row = (math.ceil(vim.o.lines - height) / 2) - 1
    col = (math.ceil(vim.o.columns - width) / 2) - 1
  end

  local winnr = api.nvim_open_win(bufnr, true, {
    -- win = caller_winnr,
    relative = "editor",
    style = "minimal",
    border = "single", --mega.get_border(),
    width = width,
    height = height,
    row = row,
    col = col,
    zindex = 99,
  })

  return winnr
end

local default_opts = {
  cmd = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX),
  direction = "horizontal",
  start_insert = true,
}

local split_opts = {
  ["horizontal"] = {
    new = "botright new",
    split = "rightbelow sbuffer",
    dimension = "height",
    size = vim.fn.winheight(0) > 50 and 22 or 18,
    res = "resize",
    winc = "J",
  },
  ["vertical"] = {
    new = "botright vnew",
    split = "rightbelow sbuffer",
    dimension = "width",
    size = vim.o.columns > 210 and 90 or 70,
    res = "vertical-resize",
    winc = "L",
  },
  ["tab"] = {
    new = "tabedit new",
    split = "tabnext",
  },
  ["float"] = {
    new = function(size, caller_winnr)
      vim.g.term_bufnr = api.nvim_create_buf(true, true)
      vim.g.term_winnr = create_float(vim.g.term_bufnr, size, caller_winnr)
      return vim.g.term_winnr, vim.g.term_bufnr
    end,
    split = function(size, bufnr)
      vim.g.term_winnr = create_float(bufnr, size)
      return vim.g.term_winnr, bufnr
    end,
    size = 90,
  },
}

local function set_keymaps(bufnr, direction)
  local opts = { buffer = bufnr, silent = false }
  local function quit()
    unset_term(true)
    vim.cmd("wincmd p")
  end

  local map = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs, opts) end
  local nmap = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) vim.keymap.set("t", lhs, rhs, opts) end

  if direction ~= "tab" then nmap("q", quit) end

  map({ "n", "t" }, "<C-;>", [[<cmd>TT<cr>]])

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  tmap("<C-x>", quit)
end

local function create_term(opts)
  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  local term_cmd = (opts and opts.pre_cmd) and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd
  local opened_term = vim.fn.termopen(term_cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(job_id, exit_code, event)
      -- if we get a custom on_exit, run it instead...
      if opts and opts.on_exit ~= nil and type(opts.on_exit) == "function" then
        opts.on_exit(job_id, exit_code, event, term_cmd, opts and opts.caller_winnr, vim.g.term_bufnr)
      else
        vim.defer_fn(function()
          if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
            unset_term(true)
          else
            vim.notify(fmt("exit status: %s/%s/%s", job_id, exit_code, event), L.debug)
          end
        end, 100)
      end

      if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(term_cmd, exit_code) end
      -- vim.cmd(opts.caller_winnr .. [[wincmd w]])
      vim.cmd([[wincmd p]])
    end,
  })

  -- dbg({ "opened_term", opened_term })
  -- vim.g.term_bufnr = vim.api.nvim_get_current_buf()
end

local function create_win(opts)
  if opts.direction == "float" then
    local winnr, bufnr = opts.new(opts.size, opts.caller_winnr)
    -- set_term(winnr, bufnr, nil, opts)
  elseif opts.direction == "tab" then
    api.nvim_command(fmt("%s", opts.new))
    -- set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), opts)
  else
    api.nvim_command(fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size))
    -- set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, opts)
  end

  -- api.nvim_set_current_buf(vim.g.term_bufnr)
  -- api.nvim_win_set_buf(vim.g.term_winnr, vim.g.term_bufnr)
end

local function set_autocmds(opts)
  augroup("megaterm", {
    {
      event = { "BufEnter" },
      command = function(params)
        if vim.bo[params.buf].filetype == "megaterm" then
          if (vim.g.megaterm.direction and vim.tbl_contains({ "vertical", "horizontal" }, vim.g.megaterm.direction)) and is_valid_window(vim.g.term_winnr) then
            set_win_size()
          end
        end
      end,
    },
  })
end

local term_mode_var = "__terminal_mode"
local function set_mode(buf, mode) vim.b[buf][term_mode_var] = mode end

local function get_mode(buf) return vim.b[buf][term_mode_var] end

local function __enter(opts)
  -- if vim.g.megaterm == nil then
  --   vim.notify("term not found")
  --   return
  -- end

  set_term_opts(vim.g.megaterm)

  if vim.g.megaterm ~= nil and vim.tbl_contains({ "vertical", "horizontal", "tab" }, vim.g.megaterm.direction) then
    set_win_hls()
  else
    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })
    vim.wo[vim.g.term_winnr].winblend = 0
  end
  if vim.g.megaterm ~= nil and vim.tbl_contains({ "vertical", "horizontal" }, vim.g.megaterm.direction) and is_valid_window(vim.g.term_winnr) then
    set_win_size()
  end

  set_keymaps(vim.g.term_bufnr, vim.g.megaterm ~= nil and vim.g.megaterm.direction or "horizontal")
  set_mode(vim.g.term_bufnr, "t")

  -- custom on_open
  if vim.g.megaterm ~= nil and vim.g.megaterm.on_open ~= nil and vim.g.megaterm(vim.g.megaterm.on_open) == "function" then
    vim.g.megaterm.on_open(vim.g.term_bufnr)
  else
    -- default_on_open
    vim.api.nvim_command([[normal! G]])
    -- if vim.g.megaterm.start_insert then vim.cmd.startinsert() end
    vim.cmd.startinsert()
  end

  -- set some useful term-derived vars
  api.nvim_buf_set_var(vim.g.term_bufnr, "term_cmd", vim.g.megaterm and vim.g.megaterm.cmd or "zsh")
  api.nvim_buf_set_var(vim.g.term_bufnr, "term_buf", vim.g.term_bufnr)
  api.nvim_buf_set_var(vim.g.term_bufnr, "term_win", vim.g.term_winnr)
  api.nvim_buf_set_var(vim.g.term_bufnr, "term_direction", vim.g.megaterm and vim.g.megaterm.direction or "horizontal")

  vim.cmd([[do User MegaTermOpened]])

  set_autocmds(opts)
end

local function build_defaults(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  opts = vim.tbl_extend("force", split_opts[opts.direction], opts)
  opts = vim.tbl_extend("keep", opts, { caller_winnr = vim.api.nvim_get_current_win() })
  opts = vim.tbl_extend("keep", opts, { focus_on_open = true })
  opts = vim.tbl_extend("keep", opts, { move_on_direction_change = true })

  return opts
end

local function open_term(opts)
  if opts.direction == "float" then
    opts.split(opts.size, vim.g.term_bufnr)
  elseif opts.direction == "tab" then
    api.nvim_command(fmt("%s%s", vim.g.term_tabnr, opts.split))
    vim.g.term_winnr = nil
  else
    api.nvim_command(
      fmt(
        "%s %s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)",
        opts.split,
        vim.g.term_bufnr,
        opts.winc,
        opts.dimension,
        is_valid_window(vim.g.term_winnr) and vim.g.term_winnr or 0,
        opts.size
      )
    )
  end

  -- Term.on_open()
  -- term_win_id = api.nvim_get_current_win()
end

--- Toggles open, or hides a custom terminal
--- @param args TermOpts|ParsedArgs|string
function mega.toggleterm(args)
  -- REF: https://gist.github.com/shivamashtikar/16a4d7b83b743c9619e29b47a66138e0
  U.clear_ui()

  local parsed_opts = args or {}

  if type(args) == "string" then
    parsed_opts = command_parser(args)

    vim.validate({
      -- toggle = { parsed_opts.toggle, "boolean", true },
      size = { parsed_opts.size, "number", true },
      direction = { parsed_opts.direction, "string", true },
      move_on_direction_change = { parsed_opts.move_on_direction_change, "boolean", true },
    })

    if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
    if not parsed_opts.direction then parsed_opts.direction = "horizontal" end
    if not parsed_opts.caller_winnr then parsed_opts.caller_winnr = vim.api.nvim_get_current_win() end
  end

  local opts = build_defaults(parsed_opts)
  vim.g.megaterm = opts

  local is_open = is_valid_window(vim.g.term_winnr)

  if is_open then
    vim.api.nvim_win_hide(vim.g.term_winnr)
    vim.g.term_winnr = nil
    vim.cmd([[wincmd p]])

    return
  end

  -- Open new window 25 lines tall at the bottom of the screen
  create_win(opts)
  vim.g.term_winnr = vim.api.nvim_get_current_win()

  if is_valid_buffer(vim.g.term_bufnr) then
    -- vim.api.nvim_set_current_buf(vim.g.term_bufnr)
    vim.api.nvim_win_set_buf(vim.g.term_winnr, vim.g.term_bufnr)
    vim.g.term_bufnr = vim.api.nvim_win_get_buf(vim.g.term_winnr)
  else
    create_term(opts)
    vim.g.term_bufnr = vim.api.nvim_win_get_buf(vim.g.term_winnr)
    __enter(opts)

    -- vim.g.term_bufnr = vim.api.nvim_get_current_buf()
    vim.bo[vim.g.term_bufnr].filetype = __filetype
    vim.bo[vim.g.term_bufnr].buftype = __buftype
  end

  vim.cmd.startinsert()
end

-- [COMMANDS] ------------------------------------------------------------------

command("TT", function(opts) mega.toggleterm(opts.args) end, { nargs = "*" })

vim.keymap.set({ "n", "t" }, "<C-;>", "<cmd>TT<cr>", { desc = "term: toggle" })
