if not mega then return end
if not vim.g.enabled_plugin["term"] then return end

local fmt = string.format
local api = vim.api
local fn = vim.fn

local term = nil

local function is_valid_buffer() return term ~= nil and vim.api.nvim_buf_is_valid(term.bufnr) end
local function is_valid_window() return term ~= nil and vim.api.nvim_win_is_valid(term.winnr) end
local function find_windows_by_bufnr() return term ~= nil and fn.win_findbuf(term.bufnr) end

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
--

--- @param winnr number
--- @param bufnr number
--- @param tabnr? number
--- @param opts TermOpts
-- --- @return TermOpts
local function set_term(winnr, bufnr, tabnr, opts)
  -- mutate and set our current term
  term = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr, tabnr = tabnr })
end

local function unset_term(should_delete)
  if should_delete or api.nvim_buf_is_loaded(term.bufnr) then api.nvim_buf_delete(term.bufnr, { force = true }) end
  term = nil
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

local function set_term_opts()
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  pcall(vim.api.nvim_buf_set_option, term.bufnr, "filetype", "megaterm")
  pcall(vim.api.nvim_buf_set_option, term.bufnr, "buftype", "terminal")

  if vim.tbl_contains({ "float", "tab" }, term.direction) then
    -- Focus first file:line:col pattern in the terminal output
    -- vim.keymap.set('n', 'F', [[:call search('\f\+:\d\+:\d\+')<CR>]], { buffer = true, silent = true })
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    -- vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size()
  if term.direction == "vertical" then
    vim.cmd(fmt("let &winwidth=%d", term.size))
  elseif term.direction == "horizontal" then
    vim.cmd(fmt("let &winheight=%d", term.size))
  end
end

local set_autocommands = function()
  mega.augroup("MegatermResizer", {
    {
      event = { "WinLeave" },
      buffer = term.bufnr,
      command = function(evt)
        -- P(fmt("winleave win/buf: %s/%s", opts.winnr, bufnr))
        set_win_size(evt.buf)
      end,
    },
    {
      event = { "WinEnter" },
      buffer = term.bufnr,
      command = function(evt)
        set_win_size(evt.buf)
        -- P(fmt("winenter win/buf: %s/%s", opts.winnr, bufnr))
      end,
    },
    {
      event = { "TermOpen" },
      pattern = { "term://*" },
      command = function(evt)
        -- P(fmt("termopen win/buf: %s/%s", opts.winnr, bufnr))
        -- if vim.bo[evt.buf].filetype == "" or vim.bo[evt.buf].filetype == "megaterm" then
        --   P(fmt("termopen megaterm win/buf: %s/%s", opts.winnr, bufnr))
        -- end
      end,
    },
    {
      event = { "BufEnter" },
      buffer = term.bufnr,
      command = function(evt)
        -- if vim.bo[evt.buf].filetype == "" or vim.bo[evt.buf].filetype == "megaterm" then
        --   P(fmt("bufenter megaterm win/buf: %s/%s", opts.winnr, bufnr))
        -- end
      end,
    },
  })
end

local create_float = function(bufnr, size)
  local parsed_size = (size / 100)
  local winnr = api.nvim_open_win(bufnr, true, {
    relative = "editor",
    style = "minimal",
    border = mega.get_border(),
    width = math.floor(parsed_size * vim.o.columns),
    height = math.floor(parsed_size * vim.o.lines),
    row = math.floor(0.1 * vim.o.lines),
    col = math.floor(0.1 * vim.o.columns),
    zindex = 99,
  })

  return winnr
end

local default_opts = {
  cmd = "zsh",
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
    new = function(size)
      local bufnr = api.nvim_create_buf(true, true)
      local winnr = create_float(bufnr, size)

      return winnr, bufnr
    end,
    split = function(size, bufnr)
      local winnr = create_float(bufnr, size)

      return winnr, bufnr
    end,
    size = 80,
  },
}

-- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
local function set_keymaps()
  local keymap_opts = { buffer = term.bufnr, silent = false }
  -- quit terminal and go back to last window
  -- TODO: do we want this ONLY for non tab terminals?
  if term.direction ~= "tab" then
    nmap("q", function()
      unset_term(true)
      -- jump back to our last window
      vim.cmd([[wincmd p]])
    end, keymap_opts)
  end

  tmap("<esc>", [[<C-\><C-n>]], keymap_opts)
  -- TODO: find a way to be more intelligent about these (e.g., how can we use `wincmd p` and know that we're goign to the right thing from the term)
  tmap("<C-h>", [[<Cmd>wincmd h<CR>]], keymap_opts)
  tmap("<C-j>", [[<Cmd>wincmd j<CR>]], keymap_opts)
  tmap("<C-k>", [[<Cmd>wincmd k<CR>]], keymap_opts)
  tmap("<C-l>", [[<Cmd>wincmd l<CR>]], keymap_opts)
  -- TODO: want a `<C-r>` or `;,` to pull up last executed command in the term
  -- TODO: want a `<C-b>` to auto scroll back and `<C-f>` to auto scroll forward in insert mode
  -- NOTE: keep this disbled so we can C-c in a shell to halt a running process:
  -- tmap("<C-c>", [[<C-\><C-n>]], opts)
end

local function create_term(opts)
  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  local term_cmd = opts.pre_cmd and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd
  vim.fn.termopen(term_cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(job_id, exit_code, event)
      if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(term_cmd, exit_code) end

      -- if we get a custom on_exit, run it instead...
      if opts.on_exit ~= nil and type(opts.on_exit) == "function" then
        opts.on_exit(job_id, exit_code, event, term_cmd, opts.caller_winnr, term.bufnr)
      else
        -- test passed/process ended with an "ok" exit code, so let's close it.
        if exit_code == 0 or exit_code == 127 or exit_code == 130 then
          unset_term()
          vim.cmd([[wincmd p]])
        end
      end
    end,
  })
end

local function create_win(opts)
  if opts.direction == "float" then
    local winnr, bufnr = opts.new(opts.size)
    set_term(winnr, bufnr, nil, opts)
  elseif opts.direction == "tab" then
    api.nvim_command(fmt("%s", opts.new))
    set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), opts)
    P(fmt("term for a tab: %s", I(term)))
  else
    api.nvim_command(
      fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size)
    )
    set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, opts)
  end

  api.nvim_set_current_buf(term.bufnr)
  api.nvim_win_set_buf(term.winnr, term.bufnr)
end

local function on_open()
  set_term_opts()
  if vim.tbl_contains({ "vertical", "horizontal", "tab" }, term.direction) then
    set_win_hls()
  else
    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })
    vim.wo[term.winnr].winblend = 0
  end
  if vim.tbl_contains({ "vertical", "horizontal" }, term.direction) then set_win_size() end
  set_keymaps()
  set_autocommands()

  -- custom on_open
  if term.on_open ~= nil and term(term.on_open) == "function" then
    term.on_open(term.bufnr)
  else
    -- default_on_open
    vim.api.nvim_command([[normal! G]])
    if term.start_insert then vim.cmd("startinsert") end
  end

  -- set some useful term-derived vars
  api.nvim_buf_set_var(term.bufnr, "term_cmd", term.cmd)
  api.nvim_buf_set_var(term.bufnr, "term_buf", term.bufnr)
  api.nvim_buf_set_var(term.bufnr, "term_win", term.winnr)
  api.nvim_buf_set_var(term.bufnr, "term_direction", term.direction)

  vim.cmd([[do User MegaTermOpened]])
end

local function new_term(opts)
  if is_valid_buffer() then
    P("presently new terming, and about to unset term")
    unset_term()
  end

  create_win(opts)
  create_term(opts)
  on_open()

  -- we only want new tab terms each time
  if opts.direction == "tab" then unset_term(false) end
end

local function open_term(opts)
  if opts.direction == "float" then
    opts.split(opts.size, term.bufnr)
  elseif opts.direction == "tab" then
    api.nvim_command(fmt("%s%s", term.bufnr, opts.split))
    term.winnr = nil -- FIXME: is this right?!
  else
    api.nvim_command(
      fmt(
        "%s %s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)",
        opts.split,
        term.bufnr,
        opts.winc,
        opts.dimension,
        is_valid_window() and term.winnr or 0,
        opts.size
      )
    )
  end

  on_open()
  -- term.winnr = api.nvim_get_current_win()
end

local function build_defaults(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  opts = vim.tbl_extend("keep", split_opts[opts.direction], opts)
  opts = vim.tbl_extend("keep", opts, { caller_winnr = vim.fn.winnr() })
  opts = vim.tbl_extend("keep", opts, { focus_on_open = true })
  opts = vim.tbl_extend("keep", opts, { move_on_direction_change = true })

  return opts
end

local function new_or_open_term(opts)
  opts = build_defaults(opts)
  if (term == nil or fn.bufexists(term.bufnr) ~= 1) or opts.direction == "tab" then
    new_term(opts)
  elseif term ~= nil and fn.win_gotoid(term.winnr) ~= 1 then
    open_term(opts)
  end

  if not opts.focus_on_open then vim.cmd([[wincmd p]]) end
end

local function hide_term(is_moving)
  if fn.win_gotoid(term.winnr) == 1 then
    api.nvim_command("hide")
    if not is_moving then vim.cmd([[wincmd p]]) end
  end
end

local function move_term(opts)
  hide_term(true)
  -- mega.term.open({ direction = opts.direction })
  vim.cmd(fmt("T direction=%s", opts.direction))
end

--- Toggles open, or hides a custom terminal
--- @param args TermOpts|string
function mega.term.toggle(args)
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

  if (term ~= nil and fn.win_gotoid(term.winnr) == 1) and parsed_opts.direction ~= "tab" then
    if parsed_opts.direction and parsed_opts.direction ~= term.direction and parsed_opts.move_on_direction_change then
      -- P(
      --   fmt(
      --     "hiding this term (%s) but with a different direction expected (%s). %d/%d",
      --     term.direction,
      --     parsed_opts.direction,
      --     term.winnr,
      --     term.bufnr
      --   )
      -- )
      P("moving and hiding")
      move_term(parsed_opts)
    else
      P("hiding")
      hide_term()
    end
  else
    P("newing or opening")
    new_or_open_term(parsed_opts)
  end
end
mega.term.open = new_or_open_term

-- [COMMANDS] ------------------------------------------------------------------
mega.command("T", function(opts) mega.term.toggle(opts.args) end, { nargs = "*" })

-- [KEYMAPS] ------------------------------------------------------------------
nnoremap("<leader>tt", "<cmd>T direction=horizontal move_on_direction_change=true<cr>", "term")
nnoremap("<leader>tf", "<cmd>T direction=float move_on_direction_change=true<cr>", "term (float)")
nnoremap("<leader>tv", "<cmd>T direction=vertical move_on_direction_change=true<cr>", "term (vertical)")
nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "term (tab-persistent)")
