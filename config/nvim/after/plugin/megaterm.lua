if not Plugin_enabled() then return end

---@class Megaterm
---@field id string
---@field name string
---@field idx number
---@field buf number
---@field job number
---@field win number
---@field opts Config

---@class Config
---@field pre_cmd? string | string[]
---@field cmd? string | string[]
---@field cwd? string
---@field env? table<string, string>
---@field position? "float"|"bottom"|"top"|"left"|"right" location and type of terminal
---@field wo? vim.wo|{} window options
---@field bo? vim.bo|{} buffer options
---@field b? table<string, any> buffer local variables
---@field w? table<string, any> window local variables
---@field ft? string filetype to use for treesitter/syntax highlighting. Won't override existing filetype
---@field on_buf? fun(Megaterm) Callback after opening the buffer
---@field on_win? fun(Megaterm) Callback after opening the window
---@field on_close? fun(Megaterm) Callback after closing the window
---@field on_exit? fun(job_id, exit_code, event, Megaterm) Callback after terminal exits (job-id, exit_code, event, State)
---@field on_exit_notifier? fun(term_cmd, exit_code) Callback after terminal exits (term_cmd, exit_code)
---@field start_insert? boolean boolean to immedi
---@field auto_insert? boolean Boolean to start insert mode when entering buffer
---@field auto_close? boolean Boolean to automatically close the terminal on exit
---@field focus? boolean Boolean to determine if we should focus the terminal buffer
---@field temp? boolean Boolean to determine if this is a toggleable terminal buffer
---@field win_config vim.api.keyset.win_config Config options passed directly into neovim windows

---@overload fun(opts? :Config|{}): Megaterm
local M = setmetatable({}, {
  __call = function(t, opts)
    opts = (opts == nil or opts == "") and {} or opts
    opts.temp = opts.temp ~= nil and opts.temp == true or false

    -- -- handle temp buffers as one-shots; typically used with vim-test strategies
    -- local temp = t:get(temp_buffer_id)
    -- if temp ~= nil then
    --   temp:close() -- return vim.schedule_wrap(function() return temp:toggle(opts) end)
    --
    --   return temp:toggle(opts)
    -- end

    if t.buf == nil or t.win == nil or t.job == nil then
      t.buf = nil
      t.win = nil
      t.job = nil
      t.id = nil
    end

    return t:toggle(opts)
  end,
})

M.__index = M

local __filetype = "megaterm"
local __buftype = "terminal"
local __augroup = nil
local idx = 0
local event_stack = {}
local terminals = {}
local caller_win = nil
local default_position = "bottom"
local default_shell = string.format("%s/bin/zsh", vim.env.HOMEBREW_PREFIX)
local temp_buffer_id = "megaterm_temp"

local split_commands = {
  editor = {
    top = { "topleft", "k" },
    right = { "vertical botright", "l" },
    bottom = { "botright", "j" },
    left = { "vertical topleft", "h" },
  },
  win = {
    top = { "aboveleft", "k" },
    right = { "vertical rightbelow", "l" },
    bottom = { "belowright", "j" },
    left = { "vertical leftabove", "h" },
  },
}

local function to_split(position)
  local lookup = {
    bottom = "below",
    left = "left",
    right = "right",
    top = "above",
  }

  return lookup[position]
end

---@alias defaults Config
local defaults = {
  cmd = vim.o.shell or vim.env.SHELL or default_shell,
  env = {},
  focus = true,
  start_insert = true,
  auto_insert = true,
  auto_close = true,
  position = default_position,
  win_config = {
    split = to_split(default_position),
    style = "minimal",
    width = 90,
    height = 25,
    width_percentage = 0.3,
    height_percentage = 0.3,
  },
  wo = {
    winhighlight = table.concat({
      "Normal:PanelBackground",
      "CursorLine:PanelBackground",
      "CursorLineNr:PanelBackground",
      "CursorLineSign:PanelBackground",
      "SignColumn:PanelBackground",
      "FloatBorder:PanelBorder",
      -- "WinBar:PanelBorder",
      -- "WinBarNC:PanelBorder",
    }, ","),
    cursorcolumn = false,
    cursorline = false,
    cursorlineopt = "both",
    colorcolumn = "",
    fillchars = "eob: ,lastline:…",
    list = false,
    listchars = "extends:…,tab:  ",
    number = false,
    relativenumber = false,
    signcolumn = "no",
    spell = false,
    statuscolumn = "",
    winblend = 0,
    -- winbar = "",
    wrap = false,
    sidescrolloff = 0,
  },
  w = {},
  bo = {
    filetype = __filetype,
  },
  b = {
    buftype = __buftype,
  },
}

--- Set window-local options.
---@param win number
---@param wo vim.wo|{}|{winhighlight: string|table<string, string>}
local function apply_wo(win, wo)
  for k, v in pairs(wo or {}) do
    -- if v == "" or v == nil then return end

    if k == "winhighlight" and type(v) == "table" then
      local parts = {} ---@type string[]
      for kk, vv in pairs(v) do
        if vv ~= "" then parts[#parts + 1] = ("%s:%s"):format(kk, vv) end
      end
      v = table.concat(parts, ",")
    end

    vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
  end
end
--- Set window variables.
---@param win number
---@param w table<string, any> window local variables
local function apply_w(win, w)
  for k, v in pairs(w or {}) do
    vim.w[win][k] = v
  end
end

--- Set buffer-local options.
---@param buf number
---@param bo vim.bo|{}
local function apply_bo(buf, bo)
  for k, v in pairs(bo or {}) do
    vim.api.nvim_set_option_value(k, v, { buf = buf })
  end
end

--- Set buffer variables.
---@param buf number
---@param b table<string, any> buffer local variables
local function apply_b(buf, b)
  for k, v in pairs(b or {}) do
    vim.b[buf][k] = v
  end
end

---@param term Megaterm
local function apply_keymaps(term)
  -- local nmap = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, opts) end
  -- local tmap = function(lhs, rhs) vim.keymap.set("t", lhs, rhs, opts) end

  -- P({ term.win, term.buf, term.job, term.opts.position })

  tnoremap("<esc>", [[<C-\><C-n>]], { buffer = term.buf })
  tnoremap("<C-;>", function() M:toggle() end, { buffer = term.buf })
  tnoremap("<C-'>", function() M:toggle({ position = "right" }) end, { buffer = term.buf })
  tnoremap("<C-h>", [[<cmd>wincmd p<cr>]], { buffer = term.buf })
  tnoremap("<C-j>", [[<cmd>wincmd p<cr>]], { buffer = term.buf })
  tnoremap("<C-k>", [[<cmd>wincmd p<cr>]], { buffer = term.buf })
  tnoremap("<C-l>", [[<cmd>wincmd p<cr>]], { buffer = term.buf })
  tnoremap("<C-q>", function() M:close() end, { buffer = term.buf })
  tnoremap("<C-x>", function() M:close() end, { buffer = term.buf })
  nnoremap("q", function() M:close() end, { buffer = term.buf })
end

function M.opts_to_config(...)
  local opts = vim.tbl_deep_extend("force", defaults, ... or {})

  return opts
end

---@param term_cmd string|string[]
function M:apply_settings(term_cmd)
  if not self:win_valid() then return end
  local opts = self.opts
  opts.wo.winbar = opts.wo.winbar or (opts.position == "float" and "" or string.format("%s#%s: %%{get(b:, 'term_title', '')}", __filetype, idx))

  apply_wo(self.win, opts.wo)
  apply_w(self.win, opts.w)
  apply_bo(self.buf, opts.bo)
  apply_b(self.buf, opts.b)
  apply_keymaps(self)

  local term_id = self:get_term_id()
  local term_name = self:get_term_name({ temp = opts.temp })

  vim.w[self.win].megaterm_win = {
    id = term_id,
    cmd = term_cmd,
    temp = opts.temp,
    position = self.opts.position,
    name = term_name,
    buf = self.buf,
    job = self.job,
  }

  vim.api.nvim_buf_set_var(self.buf, "term_cmd", term_cmd)
  vim.api.nvim_buf_set_var(self.buf, "term_id", term_id)
  vim.api.nvim_buf_set_var(self.buf, "term_buf", self.buf)
  vim.api.nvim_buf_set_var(self.buf, "term_win", self.win)
  vim.api.nvim_buf_set_var(self.buf, "term_job", self.job)
  vim.api.nvim_buf_set_var(self.buf, "term_position", self.opts.position)
  vim.api.nvim_buf_set_var(self.buf, "term_name", term_name)

  local width = self.opts.win_config.width and self.opts.win_config.height or math.floor(vim.o.columns * 0.2)
  local height = self.opts.win_config.height and self.opts.win_config.height or vim.o.lines * 0.2

  if opts.position == "left" or opts.position == "right" then
    vim.opt_local.winfixwidth = true
    vim.opt_local.winwidth = width
    vim.opt_local.winminwidth = width / 2
    vim.api.nvim_win_set_width(self.win, width)
  elseif opts.position == "top" or opts.position == "bottom" then
    vim.opt_local.winfixheight = true
    vim.opt_local.winheight = height
    vim.opt_local.winminheight = height
    vim.api.nvim_win_set_height(self.win, height)
  end
end

function M:get_win_cmd(is_existing)
  is_existing = is_existing ~= nil and is_existing == true or false
  local width = self.opts.win_config.width and self.opts.win_config.height or math.floor(vim.o.columns * 0.2)
  local height = self.opts.win_config.height and self.opts.win_config.height or vim.o.lines * 0.2
  local relative = self.opts.win_config.relative or "editor"
  local position = self.opts.position or "bottom"
  local vertical = position == "left" or position == "right"

  local split, direction = unpack(split_commands[relative][position])
  local dim_unit, dim_size = unpack(vertical and { "width", width } or { "height", height })
  direction = (self.opts.focus == nil or self.opts.focus or true) and string.format("wincmd %s | ", direction) or ""

  local win_cmd = string.format("%s new | %s lua vim.api.nvim_win_set_%s(%s, %s)", split, direction, dim_unit, 0, dim_size)

  if is_existing then win_cmd = string.format("%s %ssbuffer | %s lua vim.api.nvim_win_set_%s(%s, %s)", split, self.buf, direction, dim_unit, 0, dim_size) end

  D({ self.win, self.buf, self.job, win_cmd })

  return win_cmd
end

function M:apply_autocmds()
  self:on("WinEnter", function(args)
    local on_win = self.win and self.opts.on_win
    if self.opts.start_insert and vim.api.nvim_get_current_buf() == self.buf then vim.cmd.startinsert() end
    if on_win then on_win(self) end
  end, { win = true })

  self:on("BufEnter", function(args)
    if vim.bo[args.buf].filetype == __filetype then self:apply_settings() end
    if self.opts.auto_insert then vim.cmd.startinsert() end

    vim.schedule(function() self:resize() end)
  end, { buf = true })

  self:on("BufWinEnter", function(args)
    if vim.bo[args.buf].filetype == __filetype then self:apply_settings() end

    vim.schedule(function() self:resize() end)
  end, { buf = true })

  self:on("TermClose", function(_args)
    -- D({ args, vim.v.event })
    if type(vim.v.event) == "table" and vim.v.event.status ~= 0 then
      vim.notify("megaterm: exited with code " .. vim.v.event.status .. ".\nCheck for any errors.", L.ERROR)
      return
    end
    self:close()
    vim.cmd.checktime()
  end, { buf = true })

  local on_close = self.win and self.opts.on_close
  self:on("WinClosed", function(_args)
    if on_close then on_close(self) end
  end, { win = true })

  self:on("ExitPre", function(_args) self:close() end)

  self:on("BufWipeout", function()
    if not self.opts.temp then vim.schedule(function() self:close() end) end
  end, { buf = true })
end

---@return string|nil
function M:get_term_id()
  if self.id ~= nil and self.id:match(string.format("_buf%s_job%s", self.buf, self.job)) then return self.id end

  return string.format("win%s_buf%s_job%s", self.win, self.buf, self.job)
end

---@param opts { temp?: boolean|false }
---@return string
function M:get_term_name(opts)
  local temp = opts.temp ~= nil and opts.temp or false
  if temp then return string.format("%s_temp_%s_%s", __filetype, self.win, self.buf) end

  return string.format("%s_%s_%s", __filetype, self.win, self.buf)
end

---@return { height: number, width: number }
function M:parent_size()
  return {
    height = self.opts.win_config.relative == "win" and vim.api.nvim_win_get_height(self.win) or vim.o.lines,
    width = self.opts.win_config.relative == "win" and vim.api.nvim_win_get_width(self.win) or vim.o.columns,
  }
end

---@return boolean
function M:buf_valid() return self.buf ~= nil and self.buf ~= -1 and vim.api.nvim_buf_is_valid(self.buf) end

---@return boolean
function M:win_valid()
  vim.notify(string.format("buf filetype: %s", vim.bo[self.buf].filetype))
  return self.win ~= nil and self.win ~= -1 and vim.api.nvim_win_is_valid(self.win)
end

function M:is_floating() return self:is_valid() and vim.api.nvim_win_get_config(self.win).zindex ~= nil end

---@return boolean
function M:is_valid()
  if not self:buf_valid() then return false end

  if not self:win_valid() then
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.api.nvim_win_get_buf(win) == self.buf then
          self.win = win
          self.tab = tab

          break
        end
      end

      if self:win_valid() and self:get() ~= nil then return true end
    end

    return true
  end

  return true
end

---@param term_id string?
---@return Megaterm[] | nil
function M:get(term_id)
  term_id = term_id ~= nil and term_id or self:get_term_id()
  return terminals[term_id]
end

---@return Megaterm[]
function M.list()
  return vim.tbl_filter(function(mt) return mt:buf_valid() end, terminals)
end

---@param event string|string[]
---@param cb fun(self: Megaterm, ev:vim.api.keyset.create_autocmd.callback_args):boolean?
---@param opts? vim.api.keyset.create_autocmd|{}
function M:on(event, cb, opts)
  if vim.bo[self.buf].filetype ~= __filetype then return end
  opts = opts ~= nil and opts or {}
  opts.callback = cb

  if self:is_valid() then
    local event_opts = {} ---@type vim.api.keyset.create_autocmd
    local skip = { "buf", "win", "event" }
    for k, v in pairs(opts) do
      if not vim.tbl_contains(skip, k) then event_opts[k] = v end
    end

    local default_augroup = vim.api.nvim_create_augroup(string.format("%s_%s_%s-%s-%s", __filetype, __augroup, self.win, self.buf, self.job), {
      clear = true,
    })

    event_opts.group = event_opts.group or self.opts.augroup or default_augroup

    event_opts.callback = function(ev)
      table.insert(event_stack, ev.event)
      local ok, err = pcall(opts.callback, self, ev)
      vim.notify(string.format("megaterm: event %s callback called (win: %s/buf: %s)", ev.event, self.win, self.buf), L.WARN)
      table.remove(event_stack)
      return not ok and error(err) or err
    end

    if event_opts.pattern or event_opts.buffer then
    -- don't alter the pattern or buffer
    elseif opts.win then
      event_opts.pattern = self.win .. ""
    elseif opts.buf then
      event_opts.buffer = self.buf
    end

    vim.api.nvim_create_autocmd(event, event_opts)
  end
end

---@return boolean
function M:is_visible()
  if not self:buf_valid() then return false end

  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == self.buf then return true end
    end
  end

  return false
end

function M:start_term(term_cmd)
  self.job = vim.api.nvim_buf_call(self.buf, function()
    return vim.fn.jobstart(term_cmd, {
      cwd = self.opts.cwd,
      term = true,
      on_exit = function(job_id, exit_code, event)
        vim.schedule(function()
          if job_id == self.job then
            self.win = vim.api.nvim_get_current_win()
            self.buf = vim.api.nvim_get_current_buf()

            if vim.tbl_contains({ 0, 127, 129, 130 }, exit_code) then vim.notify(string.format("megaterm: process exited with %s", exit_code), L.INFO) end

            if self.opts.on_exit then pcall(self.opts.on_exit, job_id, exit_code, event, self) end

            if self.opts.on_exit_notifier then
              pcall(self.opts.on_exit_notifier, term_cmd, exit_code)
            else
              vim.notify(string.format("megaterm: process exited with %s", exit_code), L.INFO)
            end

            if self.opts.auto_close then self:close() end
          end
        end)
      end,
    })
  end)

  return self
end

---@param opts? Config|{}
---@return Megaterm
function M:new(opts, is_existing)
  is_existing = is_existing ~= nil and is_existing == true or false

  if opts.temp then
    opts = (opts == nil or opts == "") and {} or opts
    opts = M.opts_to_config(opts)
  else
    idx = idx + 1
    self.idx = idx
  end

  self.opts = opts

  caller_win = self.win ~= vim.api.nvim_get_current_win() and vim.api.nvim_get_current_win() or caller_win

  local win_cmd = self:get_win_cmd(is_existing)
  vim.api.nvim_command(win_cmd)

  self.win = vim.api.nvim_get_current_win()
  self.buf = vim.api.nvim_get_current_buf()

  -- vim.bo[self.buf].filetype = __filetype
  -- vim.bo[self.buf].buftype = __buftype
  -- vim.b[self.buf].filetype = __filetype
  -- vim.b[self.buf].buftype = __buftype

  local term_cmd = self.opts.pre_cmd and string.format("%s; %s", self.opts.pre_cmd, self.opts.cmd) or self.opts.cmd or default_shell

  vim.api.nvim_win_set_buf(self.win, self.buf)

  vim.api.nvim_buf_call(self.buf, function()
    self:apply_settings(term_cmd)
    self:apply_autocmds()

    vim.b[self.buf].megaterm = { cmd = term_cmd, id = self.id, name = self.name }
    vim.b[self.buf].megaterm_buf = { cmd = term_cmd, id = self.id, name = self.name }

    local on_buf = (self.win and self.buf) and self.opts.on_buf
    if on_buf then on_buf(self) end
  end)

  if not is_existing then M:start_term(term_cmd) end

  if opts.temp then
    self.id = temp_buffer_id
  else
    self.id = self:get_term_id()
  end

  terminals[self.id] = self

  vim.schedule(function() self:focus() end)
  vim.schedule(function() self:resize() end)

  return self
end

---@return Megaterm
function M:show()
  -- local win_cmd = self:get_win_cmd()

  -- vim.api.nvim_command(win_cmd)
  -- vim.api.nvim_win_set_buf(self.win, self.buf)

  return self:new(self.opts, true)
end

---@return Megaterm
function M:hide()
  vim.bo[self.buf].bufhidden = "hide"
  vim.api.nvim_win_hide(self.win)

  return self
end

---@return Megaterm
function M:close()
  local wipe = true --opts.buf ~= false
  local win = self.win
  local job = wipe and self.job
  local buf = wipe and self.buf

  if self.opts.on_close then self.opts.on_close(self) end
  if vim.api.nvim_get_current_win() == self.win then pcall(vim.cmd.wincmd, "p") end

  if buf then self.buf = nil end
  if job then self.job = nil end

  local close = function()
    if win and vim.api.nvim_win_is_valid(win) then
      local ok, err = pcall(vim.api.nvim_win_close, win, true)
      if not ok and (err and err:find("E444")) then
        -- last window, so creat a split and close it again
        vim.cmd("silent! vsplit")
        pcall(vim.api.nvim_win_close, win, true)
      elseif not ok then
        error(err)
      end

      vim.w[self.win].megaterm_win = nil
    end

    if buf and vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end

    if __augroup then
      pcall(vim.api.nvim_del_augroup_by_id, __augroup)
      __augroup = nil
    end
  end

  local retries = 0
  local try_close ---@type fun()
  try_close = function()
    local ok, err = pcall(close)
    if ok or not err then return self end

    -- command window is open
    if err:find("E11") then
      vim.defer_fn(try_close, 200)
      return self
    end

    -- text lock
    if err:find("E565") and retries < 20 then
      retries = retries + 1
      vim.defer_fn(try_close, 50)
      return self
    end

    if not ok then vim.notify("megaterm: failed to close window: " .. err, L.ERROR) end
  end

  -- HACK: WinClosed is not recursive, so we need to schedule it
  -- if we're in a WinClosed event
  if vim.tbl_contains(event_stack, "WinClosed") or not pcall(close) then vim.schedule(try_close) end

  return self:reset()
end

---@return Megaterm
function M:focus()
  local focus = self.opts.focus ~= nil and self.opts.focus == true or false

  if focus then
    vim.api.nvim_set_current_win(self.win)
    if self.opts.start_insert then vim.cmd.startinsert() end
    if self.opts.temp then
      vim.cmd.stopinsert()
      vim.cmd.normal("G")
    end
  else
    vim.api.nvim_set_current_win(caller_win)
  end

  vim.cmd.nohlsearch()

  return self
end

---@return Megaterm
function M:reset()
  if terminals[self.id] ~= nil then terminals[self.id] = nil end

  idx = idx - 1
  self.buf = -1
  self.win = -1
  self.job = -1
  self.id = nil
  self.idx = nil

  return self
end

function M:resize()
  if self:is_floating() then return end

  local all = vim.tbl_filter(
    function(win)
      return vim.w[win].megaterm_win
        and vim.w[win].megaterm_win.relative == self.opts.win_config.relative
        and vim.w[win].megaterm_win.position == self.opts.position
    end,
    vim.api.nvim_tabpage_list_wins(0)
  )
  if #all <= 1 then return end
  local vertical = self.opts.position == "left" or self.opts.position == "right"
  local parent_size = self:parent_size()[vertical and "height" or "width"]
  local size = math.floor(parent_size / #all)
  for _, win in ipairs(all) do
    D({ win, self.win, self.buf, self.id })
    vim.api.nvim_win_call(win, function() vim.cmd(("%s resize %s"):format(vertical and "horizontal" or "vertical", size)) end)
  end
end

---@param opts? Config|{}
---@return Megaterm
function M:toggle(opts)
  opts = (opts == nil and opts == "") and {} or opts
  opts = M.opts_to_config(opts)

  -- if opts.temp then return self:new(opts) end

  if self:is_valid() then
    if self:is_visible() then
      self:hide()
    else
      self:show()
    end
  else
    self:new(opts)
  end

  return self
end

Command("Megaterm", function(opts) M(opts.args) end, { nargs = "*" })
nnoremap("<C-;>", function() M() end, { desc = "toggle megaterm (split)" })
nnoremap("<C-'>", function() M({ position = "right" }) end, { desc = "toggle megaterm (vsplit)" })

-- _G.Megaterm = M

return M
