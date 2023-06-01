-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.

if not mega then return end
if not vim.g.enabled_plugin["term"] then return end

local fmt = string.format
local api = vim.api
local fn = vim.fn

local __term_mode_var = "__terminal_mode"
local __buftype = "terminal"
local __filetype = "megaterm"
local __focus_startinsert = true

local function is_valid_buffer(bufnr) return api.nvim_buf_is_valid(bufnr) end
-- local function is_valid_window(winnr) return api.nvim_win_is_valid(winnr) end
-- local function find_windows_by_bufnr(bufnr) return fn.win_findbuf(bufnr) end
local function set_mode(buf, mode) vim.b[buf][__term_mode_var] = mode end
-- local function get_mode(buf) return vim.b[buf][__term_mode_var] end

local Window = {}

---@class Terminal
---@field direction? "horizontal"|"vertical"|"float"|"tab"
---@field size? number
---@field cmd? string
---@field pre_cmd? string
---@field on_open? function
---@field on_stdout? fun(job: number, data: string[]?, name: string?)
---@field on_stderr? fun(job: number, data: string[], name: string)
---@field on_exit? fun(job: number, exit_code: number?, name: string?, cmd: string?, caller_winnr: number?, bufnr: number?)
---@field notifier? function
---@field focus_on_open? boolean,
---@field move_on_direction_change? boolean,
---@field caller_winnr? number
---@field open_startinsert? boolean
---@field focus_startinsert? boolean
---@field temp? boolean
---@field job_id? number
local Terminal = {}

--- @param winnr number
--- @param bufnr number
--- @param tabnr? number
--- @param params Terminal
-- --- @return Terminal
function Terminal:set(winnr, bufnr, tabnr, params)
  self.winnr = winnr
  self.bufnr = bufnr
  self.tabnr = tabnr

  api.nvim_set_current_buf(bufnr)
  api.nvim_win_set_buf(winnr, bufnr)

  return vim.tbl_extend("force", params, { winnr = winnr, bufnr = bufnr, tabnr = tabnr })
end

function Terminal:unset(should_delete)
  if should_delete and api.nvim_buf_is_loaded(self.bufnr) then api.nvim_buf_delete(self.bufnr, { force = true }) end

  self.winnr = nil
  self.bufnr = nil
  self.tabnr = nil
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
---@return ParsedArgs|Terminal
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
        value = fn.shellescape(value)
        result[vim.trim(key)] = fn.expandcmd(value:match(quotes))
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

local function parse_params(params)
  local parsed_opts = params or {}

  if type(params) == "string" then
    parsed_opts = command_parser(params)

    vim.validate({
      size = { parsed_opts.size, "number", true },
      direction = { parsed_opts.direction, "string", true },
      move_on_direction_change = { parsed_opts.move_on_direction_change, "boolean", true },
    })

    if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
  end

  return parsed_opts
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

local function set_term_opts(bufnr, direction)
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  pcall(api.nvim_buf_set_option, bufnr, "filetype", __filetype)
  pcall(api.nvim_buf_set_option, bufnr, "buftype", __buftype)

  if vim.tbl_contains({ "float", "tab" }, direction) then
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size(direction, size)
  if direction == "vertical" then
    vim.cmd(fmt("let &winwidth=%s", size))
    vim.opt_local.winfixwidth = true
  elseif direction == "horizontal" then
    vim.cmd(fmt("let &winheight=%s", size))
    vim.opt_local.winfixheight = true
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
    relative = "editor",
    style = "minimal",
    border = mega.get_border(),
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
  direction = "horizontal",
  open_startinsert = true,
  focus_startinsert = __focus_startinsert,
  caller_winnr = fn.winnr(),
  focus_on_open = true,
  move_on_direction_change = true,
}

local window_opts = {
  ["horizontal"] = {
    new = "botright new",
    split = "rightbelow sbuffer",
    dimension = "height",
    size = fn.winheight(0) > 50 and 22 or 18,
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
    new = function(size, caller_winnr) return api.nvim_create_buf(true, true), create_float(bufnr, size, caller_winnr) end,
    split = function(size, bufnr) return create_float(bufnr, size), bufnr end,
    size = 90,
  },
}

local function build_defaults(params)
  params = vim.tbl_extend("force", default_opts, params or {})
  params = vim.tbl_extend("keep", window_opts[params.direction], params)

  return params
end

local function set_keymaps(bufnr, direction)
  local opts = { buffer = bufnr, silent = false }
  local function quit()
    Terminal:unset()
    vim.cmd("wincmd p")
  end
  if direction ~= "tab" then mega.nmap("q", quit, opts) end

  tnoremap("<esc>", [[<C-\><C-n>]], opts)
  tnoremap("<C-h>", [[<cmd>wincmd h<cr>]], opts)
  tnoremap("<C-j>", [[<cmd>wincmd j<cr>]], opts)
  tnoremap("<C-k>", [[<cmd>wincmd k<cr>]], opts)
  tnoremap("<C-l>", [[<cmd>wincmd l<cr>]], opts)
  tnoremap("<C-x>", quit, opts)
end

function Terminal:enter()
  set_term_opts(self.bufnr, self.direction)

  if vim.tbl_contains({ "vertical", "horizontal", "tab" }, self.direction) then
    set_win_hls()
  else
    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })
    vim.wo[self.winnr].winblend = 0
  end
  if vim.tbl_contains({ "vertical", "horizontal" }, self.direction) then set_win_size(self.direction, self.size) end

  set_keymaps(self.bufnr, self.direction)
  set_mode(self.bufnr, "t")

  -- custom on_open
  if self.on_open ~= nil and self.on_open == "function" then
    self.on_open(self.bufnr)
  else
    -- default_on_open
    api.nvim_command([[normal! G]])
    if (vim.bo.filetype == "" or vim.bo.filetype == "megaterm") and self.open_startinsert then vim.cmd.startinsert() end
  end

  -- set some useful term-derived vars for use with megaline
  api.nvim_buf_set_var(self.bufnr, "term_cmd", self.cmd)
  api.nvim_buf_set_var(self.bufnr, "term_buf", self.bufnr)
  api.nvim_buf_set_var(self.bufnr, "term_win", self.winnr)
  api.nvim_buf_set_var(self.bufnr, "term_direction", self.direction)

  vim.cmd([[do User MegaTermOpened]])
end

function Terminal:spawn()
  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  local term_cmd = self.pre_cmd and fmt("%s; %s", self.pre_cmd, self.cmd) or self.cmd
  self.job_id = fn.termopen(term_cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_stdout = function(job_id, data, name) end,
    ---@diagnostic disable-next-line: unused-local
    on_stderr = function(job_id, data, name)
      vim.notify(fmt("[#%s] error occurred(%s): %s", job_id, name, data), L.error, {})
    end,
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(job_id, exit_code, event)
      if self.notifier ~= nil and type(self.notifier) == "function" then self.notifier(term_cmd, exit_code) end

      -- if we get a custom on_exit, run it instead...
      if self.on_exit ~= nil and type(self.on_exit) == "function" then
        self.on_exit(job_id, exit_code, event, term_cmd, self.caller_winnr, self.bufnr)
      else
        vim.defer_fn(function()
          if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
            Terminal:unset(true)
          else
            dd(fmt("[#%s] %s(%s)", job_id, event, exit_code))
          end
        end, 100)
      end

      vim.cmd(self.caller_winnr .. [[wincmd w]])
    end,
  })

  if self.job_id then Terminal:enter() end
end

function Window:new(params)
  if params.direction == "float" then
    local winnr, bufnr = params.new(params.bufnr or 0, params.size, params.caller_winnr)

    params = Terminal:set(winnr, bufnr, nil, params)
  elseif params.direction == "tab" then
    api.nvim_command(fmt("%s", params.new))

    params =
      Terminal:set(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), params)
  else
    api.nvim_command(
      fmt(
        "%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)",
        params.new,
        params.winc,
        params.dimension,
        0,
        params.size
      )
    )

    params = Terminal:set(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, params)
  end

  return params
end

function Terminal:new(params)
  local t = build_defaults(params) or {}

  self.__index = self

  t = Window:new(t)
  __focus_startinsert = t.focus_startinsert

  self.caller_winnr = t.caller_winnr
  self.cmd = t.cmd
  self.dimension = t.dimension
  self.direction = t.direction
  self.focus_on_open = t.focus_on_open
  self.focus_startinsert = t.focus_startinsert
  self.open_startinsert = t.open_startinsert
  self.move_on_direction_change = t.move_on_direction_change
  self.new = t.new
  self.res = t.res
  self.size = t.size
  self.split = t.split
  self.winc = t.winc
  self.notifier = t.notifier
  self.bufnr = self.bufnr or 0

  setmetatable(t, self)

  if is_valid_buffer(self.bufnr) and self.temp then Terminal:unset(true) end
  Terminal:spawn()

  if not self.focus_on_open then vim.cmd("wincmd p | stopinsert") end

  -- we only want new tab terms each time
  if self.direction == "tab" then Terminal:unset(false) end
end

--- @param params Terminal|string
function mega.term(params)
  mega.clear_ui()
  Terminal:new(parse_params(params))
end

-- [COMMANDS] ------------------------------------------------------------------
mega.command("T", function(params) mega.term(params.args) end, { nargs = "*" })

-- [KEYMAPS] ------------------------------------------------------------------

nnoremap("<leader>tt", "<cmd>T direction=horizontal move_on_direction_change=true<cr>", "term (horizontal)")
nnoremap("<leader>tf", "<cmd>T direction=float move_on_direction_change=true<cr>", "term (float)")
nnoremap("<leader>tv", "<cmd>T direction=vertical move_on_direction_change=true<cr>", "term (vertical)")
nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "term (tab-persistent)")
-- end

mega.augroup("megaterm", {
  -- {
  --   event = {
  --     "TermOpen",
  --     -- "TermClose",
  --     -- "TermEnter",
  --     -- "TermLeave",
  --     -- "BufEnter",
  --     -- "BufLeave",
  --     -- "BufDelete",
  --   },
  --   pattern = "term://*",
  --   command = function(_params)
  --     if vim.bo.filetype == "megaterm" and term.open_startinsert then
  --       vim.cmd.startinsert()
  --     end
  --   end,
  -- },
  -- {
  --   event = { "User" },
  --   pattern = "MegatermOpen",
  --   command = function(_params)
  --     if vim.bo.filetype == "megaterm" and term.open_startinsert then
  --       dd("megatermopen")
  --       vim.cmd.startinsert()
  --     end
  --   end,
  -- },
  {
    event = { "BufEnter" },
    command = function(_params)
      if vim.bo.filetype == "megaterm" and __focus_startinsert then vim.cmd.startinsert() end
    end,
  },
  -- {
  --   event = {
  --     -- "TermOpen",
  --     "TermClose",
  --     -- "TermEnter",
  --     -- "TermLeave",
  --     -- "BufEnter",
  --     -- "BufLeave",
  --     -- "BufDelete",
  --   },
  --   pattern = "term://*",
  --   command = function(params) Megaterm:close() end,
  -- },
})
