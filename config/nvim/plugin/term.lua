-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.

if not mega then return end

local fmt = string.format
local api = vim.api
local fn = vim.fn
local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command
local nnoremap = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = "term: " .. desc }) end

local nil_id = 999999
local term_win_id = nil_id
local term_buf_id = nil_id
local term_tab_id = nil
local Term = nil

local __buftype = "terminal"
local __filetype = "megaterm"

local function is_valid_buffer(bufnr) return vim.api.nvim_buf_is_valid(bufnr) end
local function is_valid_window(winnr) return vim.api.nvim_win_is_valid(winnr) end
local function find_windows_by_bufnr(bufnr) return fn.win_findbuf(bufnr) end

--
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
--- @field caller_winnr? number
--- @field start_insert? boolean
--- @field temp? boolean
--- @field job_id? number
--

--- @param winnr number
--- @param bufnr number
--- @param tabnr? number
--- @param opts TermOpts
-- --- @return TermOpts
local function set_term(winnr, bufnr, tabnr, opts)
  term_win_id = winnr
  term_buf_id = bufnr
  term_tab_id = tabnr

  -- FIXME: only care about the term global; get rid of the term_*_id globals
  Term = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr, tabnr = tabnr })
  return Term
end

local function unset_term(should_delete)
  if should_delete and api.nvim_buf_is_loaded(term_buf_id) then api.nvim_buf_delete(term_buf_id, { force = true }) end
  term_buf_id = nil_id
  term_win_id = nil
  term_tab_id = nil
  Term = {}
end

---@class ParsedArgs
---@field direction string?
---@field cmd string?
---@field dir string?
---@field size number?
---@field move_on_direction_change boolean?

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
        elseif vim.tbl_contains({ "move_on_direction_change" }, key) then
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

local function set_term_opts(term)
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  pcall(vim.api.nvim_buf_set_option, term_buf_id, "filetype", __filetype)
  pcall(vim.api.nvim_buf_set_option, term_buf_id, "buftype", __buftype)

  if vim.tbl_contains({ "float", "tab" }, term.direction) then
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size()
  if Term and Term.direction == "vertical" then
    vim.cmd(fmt("let &winwidth=%d", Term.size))
    vim.opt_local.winfixwidth = true
    vim.opt_local.winminwidth = Term.size / 2
    vim.api.nvim_win_set_width(Term.winnr, Term.size)
  elseif Term and Term.direction == "horizontal" then
    vim.cmd(fmt("let &winheight=%d", Term.size))
    vim.opt_local.winfixheight = true
    vim.opt_local.winminheight = Term.size / 2
    vim.api.nvim_win_set_height(Term.winnr, Term.size)
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

  -- P(I({
  --   mine = {
  --     size = size,
  --     parsed_size = parsed_size,
  --     width = math.ceil(parsed_size * vim.o.columns),
  --     height = math.ceil(parsed_size * vim.o.lines),
  --     row = math.ceil(0.1 * vim.o.lines),
  --     col = math.ceil(0.1 * vim.o.columns),
  --   },
  --   theirs = {
  --     size = size,
  --     width = width,
  --     height = height,
  --     row = row,
  --     col = col,
  --   },
  -- }))

  local winnr = api.nvim_open_win(bufnr, true, {
    -- win = caller_winnr,
    relative = "editor",
    style = "minimal",
    border = "single", --mega.get_border(),
    width = width,
    height = height,
    row = row,
    col = col,
    -- width = math.floor(parsed_size * vim.o.columns),
    -- height = math.floor(parsed_size * vim.o.lines),
    -- row = math.floor(0.1 * vim.o.lines),
    -- col = math.floor(0.1 * vim.o.columns),
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
      term_buf_id = api.nvim_create_buf(true, true)
      term_win_id = create_float(term_buf_id, size, caller_winnr)
      return term_win_id, term_buf_id
    end,
    split = function(size, bufnr)
      term_win_id = create_float(bufnr, size)
      return term_win_id, bufnr
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

  local nmap = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) vim.keymap.set("t", lhs, rhs, opts) end

  if direction ~= "tab" then nmap("q", quit) end

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  tmap("<C-x>", quit)
end

local function create_term(opts)
  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  local term_cmd = opts.pre_cmd and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd
  vim.fn.termopen(term_cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(job_id, exit_code, event)
      -- if we get a custom on_exit, run it instead...
      if opts.on_exit ~= nil and type(opts.on_exit) == "function" then
        opts.on_exit(job_id, exit_code, event, term_cmd, opts.caller_winnr, term_buf_id)
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
end

local function create_win(opts)
  if opts.direction == "float" then
    local winnr, bufnr = opts.new(opts.size, opts.caller_winnr)
    set_term(winnr, bufnr, nil, opts)
  elseif opts.direction == "tab" then
    api.nvim_command(fmt("%s", opts.new))
    set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), opts)
  else
    api.nvim_command(fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size))
    set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, opts)
  end

  api.nvim_set_current_buf(term_buf_id)
  api.nvim_win_set_buf(term_win_id, term_buf_id)
end

local function set_autocmds(opts)
  augroup("megaterm", {
    {
      event = { "BufEnter" },
      command = function(params)
        if vim.bo[params.buf].filetype == "megaterm" then
          if vim.tbl_contains({ "vertical", "horizontal" }, Term.direction) then set_win_size() end
        end
      end,
    },
  })
end

local term_mode_var = "__terminal_mode"
local function set_mode(buf, mode) vim.b[buf][term_mode_var] = mode end

local function get_mode(buf) return vim.b[buf][term_mode_var] end

local function __enter(opts)
  if Term == nil then
    vim.notify("term not found")
    return
  end

  set_term_opts(Term)
  if vim.tbl_contains({ "vertical", "horizontal", "tab" }, Term.direction) then
    set_win_hls()
  else
    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })
    vim.wo[term_win_id].winblend = 0
  end
  if vim.tbl_contains({ "vertical", "horizontal" }, Term.direction) then set_win_size() end

  set_keymaps(term_buf_id, Term.direction)
  set_mode(term_buf_id, "t")

  -- custom on_open
  if Term.on_open ~= nil and Term(Term.on_open) == "function" then
    Term.on_open(term_buf_id)
  else
    -- default_on_open
    vim.api.nvim_command([[normal! G]])
    if Term.start_insert then vim.cmd.startinsert() end
  end

  -- set some useful term-derived vars
  api.nvim_buf_set_var(term_buf_id, "term_cmd", Term.cmd)
  api.nvim_buf_set_var(term_buf_id, "term_buf", term_buf_id)
  api.nvim_buf_set_var(term_buf_id, "term_win", term_win_id)
  api.nvim_buf_set_var(term_buf_id, "term_direction", Term.direction)

  vim.cmd([[do User MegaTermOpened]])

  set_autocmds(opts)
end

local function new_term(opts)
  if is_valid_buffer(term_buf_id) and opts.temp then unset_term(true) end

  create_win(opts)
  create_term(opts)
  __enter(opts)

  if not opts.focus_on_open then vim.cmd("wincmd p | stopinsert") end

  -- we only want new tab terms each time
  if opts.direction == "tab" then unset_term(false) end
end

local function build_defaults(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  opts = vim.tbl_extend("force", split_opts[opts.direction], opts)
  opts = vim.tbl_extend("keep", opts, { caller_winnr = vim.fn.winnr() })
  opts = vim.tbl_extend("keep", opts, { focus_on_open = true })
  opts = vim.tbl_extend("keep", opts, { move_on_direction_change = true })

  return opts
end

local function new_or_open_term(opts)
  opts = build_defaults(opts)
  new_term(opts)
  if not opts.focus_on_open then vim.cmd("wincmd p") end
end

local function hide_term(is_moving)
  if fn.win_gotoid(term_win_id) == 1 then
    api.nvim_command("hide")
    if not is_moving then vim.cmd([[wincmd p]]) end
  end
end

--- Toggles open, or hides a custom terminal
--- @param args TermOpts|ParsedArgs|string
function mega.term(args)
  -- be sure to clear our search highlights and other UI adornments
  U.clear_ui()

  local parsed_opts = args or {}

  if type(args) == "string" then
    parsed_opts = command_parser(args)

    vim.validate({
      size = { parsed_opts.size, "number", true },
      direction = { parsed_opts.direction, "string", true },
      move_on_direction_change = { parsed_opts.move_on_direction_change, "boolean", true },
    })

    if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
  end

  new_or_open_term(parsed_opts)
end

-- [COMMANDS] ------------------------------------------------------------------

command("T", function(opts) mega.term(opts.args) end, { nargs = "*" })

-- [KEYMAPS] ------------------------------------------------------------------

nnoremap("<leader>tt", "<cmd>T direction=horizontal move_on_direction_change=true<cr>", "horizontal")
nnoremap("<leader>tf", "<cmd>T direction=float move_on_direction_change=true<cr>", "float")
nnoremap("<leader>tv", "<cmd>T direction=vertical move_on_direction_change=true<cr>", "vertical")
nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "tab-persistent")
