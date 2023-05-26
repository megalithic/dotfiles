if not mega then return end
if not vim.g.enabled_plugin["megaterm"] then return end

local api = vim.api
local fn = vim.fn
local cmd = vim.cmd

-- [ DEFAULTS/LOCALS ] ---------------------------------------------------------

local __buftype = "terminal"
local __filetype = "megaterm"
local __cmd = fmt("%s/bin/zsh", vim.env.HOMEBREW_PREFIX) or vim.o.shell
local __pre_cmd = ""

local function __spawn(self)
  local term_cmd = self.pre_cmd and fmt("%s; %s", self.pre_cmd, self.cmd) or self.cmd
  vim.fn.termopen(term_cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(job_id, exit_code, event)
      if self.notifier ~= nil and type(self.notifier) == "function" then self.notifier(term_cmd, exit_code) end

      -- if we get a custom on_exit, run it instead...
      if self.on_exit ~= nil and type(self.on_exit) == "function" then
        self.on_exit(job_id, exit_code, event, term_cmd, self.window.winid, self.window:get_bufno())
      else
        vim.defer_fn(function()
          if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then
            self:close()
          else
            dd(fmt("exit status: %s/%s/%s", job_id, exit_code, event))
          end
        end, 100)
      end

      vim.cmd(self.window.winid .. [[wincmd w]])
    end,
  })
end

-- [ WINDOW ] ------------------------------------------------------------------

local Window = {}

function Window:new(params)
  params = params and params or {}

  self.pos = params.pos or params.position or "botright"
  self.split = params.split or "sp"
  self.wincmd = params.wincmd or "J"
  self.width = params.width or vim.o.columns > 210 and 90 or 70
  self.height = params.height or fn.winheight(0) > 50 and 22 or 18

  return self
end

-- Opens new window bottom of tab
-- @return { number } window id
function Window:create(bufnr)
  api.nvim_command(
    fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", self.pos, self.wincmd, self.dimension, 0, self.height)
  )

  -- local cmd_format = "%s %s"
  -- cmd(cmd_format:format(self.pos, self.split))
  -- local cmd_format = "%s %s +buffer\\ %d"
  -- cmd(cmd_format:format(self.pos, self.split, bufnr))

  self.winid = fn.win_getid()

  self:update_size()

  return self.winid
end

-- Opens new terminal window bottom of tab
-- @return { number } window number
function Window:create_term()
  -- local cmd_format = "%s new"
  -- local cmd_format = "%s new +term"
  -- cmd(cmd_format:format(self.pos))
  self.cmd = __cmd
  self.pre_cmd = __pre_cmd
  __spawn(self)
  -- self:spawn()

  self.winid = fn.win_getid()

  self:update_size()

  return self.winid
end

-- Set window width to self.width
function Window:update_size()
  if self.width ~= nil then api.nvim_win_set_width(self.winid, self.width) end

  if self.height ~= nil then api.nvim_win_set_height(self.winid, self.height) end
end

function Window:get_size()
  local width = api.nvim_win_get_width(self.winid)
  local height = api.nvim_win_get_height(self.winid)

  return width, height
end

-- close the window
function Window:close(winid)
  winid = winid or self.winid
  if self:is_valid() then api.nvim_win_close(self.winid, false) end
end

-- Returns the validity of the window
-- @return { boolean } window is valid or not
function Window:is_valid()
  if self.winid == nil then return false end

  return api.nvim_win_is_valid(self.winid)
end

function Window:set_buf(bufno) return api.nvim_win_set_buf(self.winid, bufno) end

function Window:focus() api.nvim_set_current_win(self.winid) end

-- Returns the buffer number
-- @return { number } buffer number
function Window:get_bufno()
  if self:is_valid() then return api.nvim_win_get_buf(self.winid) end
end

-- [ TERMINAL ] ----------------------------------------------------------------

local Terminal = { bufs = {}, last_winid = nil, last_term = nil }

function Terminal:new(window, params)
  params = params or {}
  self.window = window or Window:new(params)
  self.cmd = params.cmd or __cmd
  self.pre_cmd = params.pre_cmd or __pre_cmd
  return self
end

function Terminal:spawn(_params) __spawn(self) end

function Terminal:open(term_number)
  term_number = term_number or 1

  local create_win = not self.window:is_valid()
  -- create buffer if it does not exist by the given term_number or the stored
  -- buffer number is no longer valid
  local create_buf = self.bufs[term_number] == nil or not api.nvim_buf_is_valid(self.bufs[term_number])

  -- window and buffer do not exist
  if create_win and create_buf then
    self.last_winid = api.nvim_get_current_win()
    self.window:create_term()
    self.bufs[term_number] = self.window:get_bufno()

    -- window does not exist but buffer does
  elseif create_win then
    self.last_winid = api.nvim_get_current_win()
    self.window:create(self.bufs[term_number])

    -- buffer does not exist but window does
  elseif create_buf then
    self.window:focus()
    -- cmd.terminal()
    self:spawn()

    local bufnr = self.window:get_bufno()
    -- pcall(api.nvim_buf_set_option, bufnr, "filetype", __filetype)
    -- pcall(api.nvim_buf_set_option, bufnr, "buftype", __buftype)

    self.bufs[term_number] = bufnr

    -- buffer and window exist
  else
    local curr_term_buf = self.bufs[term_number]
    local last_term_buf = self.bufs[self.last_term]

    if curr_term_buf ~= last_term_buf then self.window:set_buf(curr_term_buf) end
  end

  self.last_term = term_number
end

function Terminal:close(force_exit)
  local current_winid = api.nvim_get_current_win()

  if self.window:is_valid() then
    self.window:close(current_winid)

    if current_winid == self.window.winid then api.nvim_set_current_win(self.last_winid) end
    if force_exit then self.last_term = nil end
  end
end

function Terminal:toggle()
  -- NOTE: to ensure toggling works, be sure to set:
  --  vim.o.hidden = true

  self.last_term = self.last_term and self.last_term or 1

  local opened = self.window:is_valid()

  if opened then
    self:close()
  else
    self:open(self.last_term)
  end
end

function Terminal:set_keymaps()
  local opts = { silent = false, buffer = 0 }

  mega.nmap("q", function() self:close() end, opts)

  tnoremap("<esc>", [[<C-\><C-n>]], opts)
  tnoremap("<C-h>", [[<cmd>wincmd h<cr>]], opts)
  tnoremap("<C-j>", [[<cmd>wincmd j<cr>]], opts)
  tnoremap("<C-k>", [[<cmd>wincmd k<cr>]], opts)
  tnoremap("<C-l>", [[<cmd>wincmd l<cr>]], opts)
  -- tnoremap("<C-h>", [[<C-\><C-N><C-w>h]], opts)
  -- tnoremap("<C-j>", [[<C-\><C-N><C-w>j]], opts)
  -- tnoremap("<C-k>", [[<C-\><C-N><C-w>k]], opts)
  -- tnoremap("<C-l>", [[<C-\><C-N><C-w>l]], opts)
  tnoremap("<C-x>", function() self:close() end, opts)
end

function Terminal:set_defaults(params)
  local bufnr = params.buf
  vim.cmd.startinsert()

  local hls = {
    "Normal:PanelBackground",
    "CursorLine:PanelBackground",
    "CursorLineNr:PanelBackground",
    "CursorLineSign:PanelBackground",
    "SignColumn:PanelBackground",
    "FloatBorder:PanelBorder",
  }

  vim.opt_local.winhighlight = table.concat(hls, ",")

  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "yes:1"
  -- vim.opt_local.statuscolumn = ""
  pcall(vim.api.nvim_buf_set_option, bufnr, "filetype", __filetype)
  pcall(vim.api.nvim_buf_set_option, bufnr, "buftype", __buftype)

  api.nvim_buf_set_var(bufnr, "term_cmd", __cmd)
  api.nvim_buf_set_var(bufnr, "term_buf", bufnr)
  api.nvim_buf_set_var(bufnr, "term_win", self.winid)
  api.nvim_buf_set_var(bufnr, "term_direction", "horizontal")

  vim.cmd([[do User MegatermOpen]])

  -- TODO: use these when we enable tab/float windows:
  -- vim.opt_local.signcolumn = "no"
  -- vim.bo.bufhidden = "wipe"
  -- vim.cmd("setlocal bufhidden=wipe")
end

local Megaterm = Terminal:new(Window:new())
-- function mega.term(params)
--   mega.clear_ui()
--   Terminal:new(Window:new())
-- end

mega.augroup("megaterm", {
  {
    event = {
      "TermOpen",
      -- "TermClose",
      -- "TermEnter",
      -- "TermLeave",
      -- "BufEnter",
      -- "BufLeave",
      -- "BufDelete",
    },
    pattern = "term://*",
    command = function(params)
      if vim.tbl_contains({ "", "megaterm" }, vim.bo.filetype) then Megaterm:set_defaults(params) end
    end,
  },
  {
    event = { "User" },
    pattern = "MegatermOpen",
    command = function(_params)
      if vim.tbl_contains({ "", "megaterm" }, vim.bo.filetype) then Megaterm:set_keymaps() end
    end,
  },
  {
    event = { "BufEnter" },
    command = function(_params)
      if "megaterm" == vim.bo.filetype then vim.cmd.startinsert() end
    end,
  },
  {
    event = {
      -- "TermOpen",
      "TermClose",
      -- "TermEnter",
      -- "TermLeave",
      -- "BufEnter",
      -- "BufLeave",
      -- "BufDelete",
    },
    pattern = "term://*",
    command = function(params) Megaterm:close() end,
  },
})

mega.command("Mt", function(_params)
  vim.o.hidden = false
  Megaterm:open()
end, { nargs = "*" })
mega.command("Mtt", function(_params)
  vim.o.hidden = true
  Megaterm:toggle()
end, { nargs = "*" })

-- mega.nnoremap("<leader>to", "<cmd>T<cr>", "term: open")
-- mega.nnoremap("<leader>tt", "<cmd>Tt<cr>", "term: toggle")

-- vim.cmd([[
--     tnoremap <esc> <C-\><C-N>
--     tnoremap <C-k> :wincmd k<cr>
--     " tnoremap <C-h> <C-\><C-N><C-w>h
--     " tnoremap <C-j> <C-\><C-N><C-w>j
--     " tnoremap <C-k> <C-\><C-N><C-w>k
--     " tnoremap <C-l> <C-\><C-N><C-w>l
--   ]])
