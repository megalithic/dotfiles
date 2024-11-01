-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.
--
-- TODO
-- - similar behaviour to here.nvim; aka, quick flip between terminal and current buffer
--    REF: https://github.com/jaimecgomezz/nvim/blob/9a29163c39efc7d28f21ae2ef715e8ba3f41a4e2/lua/plugins/term.lua

if true then return end
if not mega then return end

local fmt = string.format
local api = vim.api
local U = require("mega.utils")
local augroup = require("mega.autocmds").augroup
local command = vim.api.nvim_create_user_command
local map = vim.keymap.set

vim.g.term_winnr = nil
vim.g.term_bufnr = nil
vim.g.term_tabnr = nil
vim.g.megaterms = {}

local __buftype = "terminal"
local __filetype = "megaterm"

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
--- @field focus_on_open? boolean,
--- @field move_on_dir_change? boolean,
--- @field toggle? boolean,
--- @field caller_winnr? number
--- @field start_insert? boolean
--- @field temp? boolean
--- @field job_id? number

--- @param bufnr number
--- @param opts TermOpts|nil
local function save_megaterm(bufnr, opts)
  if bufnr == nil then
    mega.notify("[megaterm] bufnr invalid or nil", L.ERROR)
    dbg(opts)

    return
  end

  if opts ~= nil then
    vim.api.nvim_buf_set_var(bufnr, "term_cmd", opts and opts.cmd or vim.o.shell)
    vim.api.nvim_buf_set_var(bufnr, "term_buf", bufnr)
    vim.api.nvim_buf_set_var(bufnr, "term_win", opts.winnr)
    vim.api.nvim_buf_set_var(bufnr, "term_dir", opts.dir or "horizontal")
    vim.api.nvim_buf_set_var(bufnr, "term_id", opts.id)
  end

  local terms_list = vim.g.megaterms
  terms_list[tostring(bufnr)] = opts
  vim.g.megaterms = terms_list

  if opts == nil and vim.api.nvim_buf_is_loaded(bufnr) then vim.api.nvim_buf_delete(bufnr, { force = true }) end

  print("saving term info")
  dbg(vim.g.megaterms)
end

--- @param megaterm_id string
local function get_opts_by_id(megaterm_id)
  -- print("debugging iter:find")
  -- dbg(vim.iter(vim.g.megaterms):find(function(opts) return opts.id == megaterm_id end))
  -- print("debugging iter:filter")
  -- dbg(vim.iter(vim.g.megaterms):filter(function(opts) return opts.id == megaterm_id end))

  -- local found_opts = vim.iter(vim.g.megaterms):find(function(opts) return opts.id == megaterm_id end)
  for _, opts in pairs(vim.g.megaterms) do
    if opts.id == megaterm_id then
      dbg({ "found opts by id", megaterm_id, opts })
      return opts
    end
  end
  -- if found_opts ~= nil then dbg({ megaterm_id, found_opts }) end

  -- return found_opts
  return nil
end

local function is_valid_buffer(bufnr) return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 end
-- local function is_valid_buffer(bufnr) return bufnr ~= nil and vim.api.nvim_buf_is_valid(bufnr) and vim.fn.buflisted(bufnr) == 1 and vim.fn.bufwinid(bufnr) == 1 end
local function is_valid_window(winnr) return winnr ~= nil and (vim.fn.win_gotoid(winnr) == 1 or vim.api.nvim_win_is_valid(winnr)) end

-- local function unset_term(should_delete)
--   if should_delete and opts.bufnr ~= nil and vim.api.nvim_buf_is_loaded(opts.bufnr) then
--     vim.api.nvim_buf_delete(opts.bufnr, { force = true })
--   end
--   opts.bufnr = nil
--   vim.g.term_winnr = nil
--   vim.g.term_tabnr = nil
-- end

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
        elseif vim.tbl_contains({ "move_on_dir_change", "toggle" }, key) then
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

local function set_term_opts(opts)
  if opts == nil then return end

  local bufnr = opts.bufnr

  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  pcall(vim.api.nvim_set_option_value, "filetype", __filetype, { buf = bufnr, win = opts.winnr })
  pcall(vim.api.nvim_set_option_value, "buftype", __buftype, { buf = bufnr, win = opts.winnr })

  if vim.tbl_contains({ "float", "tab" }, opts.dir) then
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size(opts)
  if opts == nil then return end

  if opts.dir == "vertical" then
    vim.cmd(fmt("let &winwidth=%d", opts.size))
    vim.opt_local.winfixwidth = true
    vim.opt_local.winminwidth = opts.size / 2
    vim.api.nvim_win_set_width(opts.winnr, opts.size)
  elseif opts.dir == "horizontal" then
    vim.cmd(fmt("let &winheight=%d", opts.size))
    vim.opt_local.winfixheight = true
    vim.opt_local.winminheight = opts.size / 2
    vim.api.nvim_win_set_height(opts.winnr, opts.size)
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
  cmd = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX) or vim.o.shell,
  -- cmd = vim.o.shell or fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX),
  dir = "horizontal",
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
      opts.bufnr = api.nvim_create_buf(true, true)
      vim.g.term_winnr = create_float(opts.bufnr, size, caller_winnr)
      return vim.g.term_winnr, opts.bufnr
    end,
    split = function(size, bufnr)
      vim.g.term_winnr = create_float(bufnr, size)
      return vim.g.term_winnr, bufnr
    end,
    size = 90,
  },
}

local function set_keymaps(bufnr, dir)
  local opts = { buffer = bufnr, silent = false }
  local function quit()
    save_megaterm(bufnr, nil)
    vim.cmd("wincmd p")
  end

  local nmap = function(lhs, rhs) map("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) map("t", lhs, rhs, opts) end

  nmap("q", quit)

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
        opts.on_exit(job_id, exit_code, event, term_cmd, opts and opts.caller_winnr, opts.bufnr)
      else
        vim.defer_fn(function()
          if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
            save_megaterm(opts.bufnr, nil)
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
  if opts.dir == "float" then
    local winnr, bufnr = opts.new(opts.size, opts.caller_winnr)
    -- set_term(winnr, bufnr, nil, opts)
  elseif opts.dir == "tab" then
    api.nvim_command(fmt("%s", opts.new))
    -- set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), opts)
  else
    api.nvim_command(fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size))
    -- set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, opts)
  end

  -- api.nvim_set_current_buf(opts.bufnr)
  -- api.nvim_win_set_buf(vim.g.term_winnr, opts.bufnr)
end

local function set_autocmds(opts)
  augroup("megaterm", {
    {
      event = { "BufEnter" },
      command = function(params)
        if vim.bo[params.buf].filetype == "megaterm" then
          if (opts.dir and vim.tbl_contains({ "vertical", "horizontal" }, opts.dir)) and is_valid_window(opts.winnr) then set_win_size(opts) end
        end
      end,
    },
  })
end

local term_mode_var = "__terminal_mode"
local function set_mode(bufnr, mode) vim.b[bufnr][term_mode_var] = mode end

local function get_mode(bufnr) return vim.b[bufnr][term_mode_var] end

local function __enter(opts)
  set_term_opts(opts)

  if opts ~= nil and vim.tbl_contains({ "vertical", "horizontal", "tab" }, opts.dir) then
    set_win_hls()
  else
    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })
    vim.wo[opts.winnr].winblend = 0
  end
  if opts ~= nil and vim.tbl_contains({ "vertical", "horizontal" }, opts.dir) and is_valid_window(opts.winnr) then set_win_size(opts) end

  set_keymaps(opts.bufnr, opts ~= nil and opts.dir or "horizontal")
  set_mode(opts.bufnr, "t")

  -- custom on_open
  if opts ~= nil and opts.on_open ~= nil and opts(opts.on_open) == "function" then
    opts.on_open(opts.bufnr)
  else
    -- default_on_open
    vim.api.nvim_command([[normal! G]])
    -- if opts.start_insert then vim.cmd.startinsert() end
    vim.cmd.startinsert()
  end

  vim.cmd([[do User MegaTermOpened]])

  set_autocmds(opts)
end

local function build_defaults(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  opts = vim.tbl_extend("force", split_opts[opts.dir], opts)
  opts = vim.tbl_extend("keep", opts, { caller_winnr = vim.api.nvim_get_current_win() })
  opts = vim.tbl_extend("keep", opts, { focus_on_open = true })
  opts = vim.tbl_extend("keep", opts, { move_on_dir_change = true })

  return opts
end

--- Toggles open, or hides a custom terminal
--- @param args TermOpts|ParsedArgs|string
function mega.toggleterm(args)
  -- REF: https://gist.github.com/shivamashtikar/16a4d7b83b743c9619e29b47a66138e0?permalink_comment_id=4924914#gistcomment-4924914
  U.clear_ui()

  local parsed_opts = args or {}

  if type(args) == "string" then
    parsed_opts = command_parser(args)

    vim.validate({
      -- toggle = { parsed_opts.toggle, "boolean", true },
      id = { parsed_opts.id, "string", true },
      size = { parsed_opts.size, "number", true },
      dir = { parsed_opts.dir, "string", true },
      move_on_dir_change = { parsed_opts.move_on_dir_change, "boolean", true },
    })

    if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
    if not parsed_opts.dir then parsed_opts.dir = "horizontal" end
    if not parsed_opts.caller_winnr then parsed_opts.caller_winnr = vim.api.nvim_get_current_win() end
  end

  local opts = get_opts_by_id(parsed_opts.id) or build_defaults(parsed_opts)

  -- TODO: get togglign workign to where we're not spawning a new window each time.. perhaps with:
  -- REF: https://github.com/NvChad/ui/blob/v3.0/lua/nvchad/term/init.lua

  -- dbg({ opts.id, opts.winnr, opts.bufnr, is_valid_window(opts.winnr), is_valid_buffer(opts.bufnr) })
  local is_open = is_valid_window(opts.winnr or vim.g.term_winnr) and is_valid_buffer(opts.bufnr or vim.g.term_bufnr)
  -- local is_open = is_valid_window(opts.winnr or vim.g.term_winnr)

  if is_open then
    vim.api.nvim_win_close(opts.winnr or vim.g.term_winnr, true)
    vim.cmd([[wincmd p]])
  else
    -- Open new window 25 lines tall at the bottom of the screen
    create_win(opts)
    opts.winnr = vim.api.nvim_get_current_win()
    -- vim.g.term_winnr = opts.winnr

    local bufnr = opts.bufnr or vim.g.term_bufnr
    if is_valid_buffer(bufnr) then
      opts["bufnr"] = vim.api.nvim_win_get_buf(opts.winnr)
      vim.api.nvim_win_set_buf(opts.winnr, bufnr)

      vim.api.nvim_command([[normal! G]])
      vim.cmd.startinsert()

      save_megaterm(opts.bufnr, opts)
    else
      create_term(opts)

      opts["bufnr"] = vim.api.nvim_win_get_buf(opts.winnr)
      vim.g.term_bufnr = opts.bufnr

      __enter(opts)

      vim.bo[opts.bufnr].filetype = __filetype
      vim.bo[opts.bufnr].buftype = __buftype

      save_megaterm(opts.bufnr, opts)
    end
  end
end

-- [COMMANDS] ------------------------------------------------------------------

command("TT", function(opts) mega.toggleterm(opts.args) end, { nargs = "*" })
command("Runner", function(opts) mega.togglerunner(opts.args) end, { nargs = "*" })

-- augroup("megaterm_term", { {
--   event = { "TermClose" },
--   command = function(args)
--     dbg(args)
--     save_term_info(args.buf, nil)
--   end,
-- } })

map({ "n", "t" }, "<C-;>", function()
  mega.toggleterm({
    id = "megaterm_toggleterm",
  })
end, { desc = "term: toggle" })
