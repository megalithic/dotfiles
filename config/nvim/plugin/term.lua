local fmt = string.format
local api = vim.api
local fn = vim.fn

local nil_buf_id = 999999
local term_buf_id = nil_buf_id
local term_win_id = nil
local term_tab_id = nil

local create_float = function(buf_id, size)
  local parsed_size = (size / 100)
  local win_id = api.nvim_open_win(buf_id, true, {
    relative = "editor",
    style = "minimal",
    border = mega.get_border(),
    width = math.floor(parsed_size * vim.o.columns),
    height = math.floor(parsed_size * vim.o.lines),
    row = math.floor(0.1 * vim.o.lines),
    col = math.floor(0.1 * vim.o.columns),
    zindex = 99,
  })
  vim.opt_local.relativenumber = false
  vim.opt_local.number = false
  vim.opt_local.signcolumn = "no"
  api.nvim_buf_set_option(buf_id, "filetype", "megaterm")
  api.nvim_win_set_option(
    win_id,
    "winhl",
    table.concat({
      "Normal:NormalFloat",
      "FloatBorder:FloatBorder",
      "CursorLine:Visual",
      "Search:None",
    }, ",")
  )

  vim.cmd("setlocal bufhidden=wipe")
  return win_id
end

local default_opts = {
  ["horizontal"] = {
    new = "botright new",
    split = "rightbelow sbuffer",
    dimension = "height",
    dim = "vim.api.nvim_win_set_height",
    size = 25,
    res = "resize",
    winc = "J",
  },
  ["vertical"] = {
    new = "botright vnew",
    split = "rightbelow sbuffer",
    dimension = "width",
    dim = "vim.api.nvim_win_set_width",
    size = 70,
    res = "vertical-resize",
    winc = "L",
  },
  ["tab"] = {
    new = "tabedit new",
    split = "tabnext",
  },
  ["float"] = {
    new = function(size)
      term_buf_id = api.nvim_create_buf(true, true)
      term_win_id = create_float(term_buf_id, size)
    end,
    split = function(size, bufnr) term_win_id = create_float(bufnr, size) end,
    size = 80,
  },
}

---@class ParsedArgs
---@field direction string?
---@field cmd string?
---@field dir string?
---@field size number?
---@field go_back boolean?
---@field open boolean?

---Take a users command arguments in the format "cmd='git commit' dir=~/.dotfiles"
---and parse this into a table of arguments
---{cmd = "git commit", dir = "~/.dotfiles"}
---@see https://stackoverflow.com/a/27007701
---@param args string
---@return ParsedArgs
function mega.term.parse(args)
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
        elseif key == "go_back" or key == "open" then
          value = value ~= "0"
        end
        result[key] = value
      end
    end
  end
  return result
end

-- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
local function create_keymaps(bufnr, winnr)
  local opts = { buffer = bufnr, silent = false }
  -- quit terminal and go back to last window
  nmap("q", function()
    api.nvim_buf_delete(bufnr, { force = true })
    bufnr = nil_buf_id
    -- jump back to our last window
    vim.cmd(winnr .. [[wincmd p]])
  end, opts)

  tmap("<esc>", [[<C-\><C-n>]], opts)
  -- tmap("<C-c>", [[<C-\><C-n>]], opts)
  tmap("<C-h>", [[<Cmd>wincmd h<CR>]], opts)
  tmap("<C-j>", [[<Cmd>wincmd j<CR>]], opts)
  tmap("<C-k>", [[<Cmd>wincmd k<CR>]], opts)
  tmap("<C-l>", [[<Cmd>wincmd l<CR>]], opts)
end

local function create_term(cmd, opts)
  opts = opts or {}
  local custom_on_exit = opts.on_exit or nil
  local winnr = opts.winnr
  local notifier = opts.notifier

  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  vim.fn.termopen(cmd, {
    ---@diagnostic disable-next-line: unused-local
    on_exit = function(jobid, exit_code, event)
      -- if we get a custom on_exit, run it instead...
      if custom_on_exit ~= nil and type(custom_on_exit) == "function" then
        custom_on_exit(jobid, exit_code, event, cmd, winnr, term_buf_id)
      else
        if notifier ~= nil and type(notifier) == "function" then notifier(cmd, exit_code) end
        -- test passed/process ended with an "ok" exit code, so let's close it.
        if exit_code == 0 then
          -- TODO: send results to quickfixlist
          api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end
      end
    end,
  })
end

local function handle_existing(cmd, opts)
  local size = opts["size"] or cmd.size
  local on_after_open = opts.on_after_open or nil
  local winnr = opts.winnr

  if opts.direction == "float" then
    cmd.split(size, term_buf_id)
  elseif opts.direction == "tab" then
    local c = fmt("%s%s", term_tab_id, cmd.split)
    api.nvim_command(c)
    term_win_id = nil -- api.nvim_get_current_win()
  else
    local c = fmt(
      "%s %s | wincmd %s | lua vim.api.nvim_win_set_%s(0, %s)",
      cmd.split,
      term_buf_id,
      cmd.winc,
      cmd.dimension,
      size
    )
    api.nvim_command(c)
    term_win_id = api.nvim_get_current_win()
  end

  if on_after_open ~= nil and type(on_after_open) == "function" then
    on_after_open(term_buf_id, winnr)
  else
    api.nvim_command([[normal! G]])
    if opts.direction ~= "float" then vim.cmd(winnr .. [[wincmd p]]) end
  end
end

local function handle_new(cmd, opts)
  local size = opts["size"] or cmd.size
  local init_cmd = opts.cmd or "zsh -i"
  local precmd = opts.precmd or nil
  local on_after_open = opts.on_after_open or nil
  local winnr = opts.winnr

  if opts.direction == "float" then
    cmd.new(size)
  elseif opts.direction == "tab" then
    local c = fmt("%s", cmd.new)
    api.nvim_command(c)

    term_win_id = api.nvim_get_current_win()
    term_buf_id = api.nvim_get_current_buf()
    term_tab_id = api.nvim_get_current_tabpage()

    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
    api.nvim_buf_set_option(term_buf_id, "filetype", "megaterm")
    vim.bo.bufhidden = "wipe"
  else
    local c = fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(0, %s)", cmd.new, cmd.winc, cmd.dimension, size)
    api.nvim_command(c)

    term_win_id = api.nvim_get_current_win()
    term_buf_id = api.nvim_get_current_buf()

    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
    api.nvim_buf_set_option(term_buf_id, "filetype", "megaterm")
  end

  api.nvim_buf_set_var(term_buf_id, "cmd", opts.cmd)
  create_keymaps(term_buf_id, term_win_id)

  if precmd ~= nil then init_cmd = fmt("%s; %s", precmd, init_cmd) end

  create_term(init_cmd, opts)

  if on_after_open ~= nil and type(on_after_open) == "function" then
    on_after_open(term_buf_id, winnr)
  else
    api.nvim_command([[normal! G]])
    if opts.direction ~= "float" then vim.cmd(winnr .. [[wincmd p]]) end
  end

  if opts.direction == "tab" then
    term_win_id = nil
    term_buf_id = nil_buf_id
    term_tab_id = nil
  end
end

function mega.term.open(args)
  args = args or {}
  local direction = args["direction"] or "horizontal"
  local cmd_opts = default_opts[direction]

  if fn.bufexists(term_buf_id) ~= 1 or direction == "tab" then
    handle_new(cmd_opts, args)
  elseif fn.win_gotoid(term_win_id) ~= 1 then
    handle_existing(cmd_opts, args)
  end
end

function mega.term.hide()
  if fn.win_gotoid(term_win_id) == 1 then api.nvim_command("hide") end
end

-- --- @class TermOpts
-- --- @field cmd string,
-- --- @field precmd string,
-- --- @field direction "horizontal"|"vertical"|"float"|"tab",
-- --- @field on_after_open function,
-- --- @field on_exit function,
-- --- @field winnr number,
-- --- @field notifier function,
-- --- @field height integer,
-- --- @field width integer,
-- --- @field persist boolean,
--
-- ---Opens a custom terminal
-- ---@param opts TermOpts
function mega.term.toggle(opts)
  local parsed = opts

  if type(opts) == "string" then
    parsed = mega.term.parse(opts)

    vim.validate({
      size = { parsed.size, "number", true },
      direction = { parsed.direction, "string", true },
    })
    if parsed.size then parsed.size = tonumber(parsed.size) end
  end

  if not parsed.winnr then parsed["winnr"] = vim.fn.winnr() end -- api.nvim_get_current_win()
  if not parsed.cmd then parsed["cmd"] = "zsh -i" end
  if not parsed.on_after_open then parsed["on_after_open"] = function() vim.cmd("startinsert") end end

  if fn.win_gotoid(term_win_id) == 1 and parsed.direction ~= "tab" then
    mega.term.hide()
  else
    mega.term.open(parsed)
  end
end

mega.command("T", function(opts) mega.term.toggle(opts.args) end, { nargs = "*" })

mega.command("Term", function()
  mega.term.toggle({
    winnr = vim.fn.winnr(),
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr) vim.cmd("startinsert") end,
  })
end)

mega.command("TermElixir", function()
  local precmd = ""
  local cmd = ""
  -- load up our Deskfile if we have one..
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end
  if require("mega.utils").root_has_file("mix.exs") then
    cmd = "iex -S mix"
  else
    cmd = "iex"
  end

  mega.term.open({
    cmd = cmd,
    precmd = precmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermRuby", function()
  local precmd = ""
  local cmd = ""
  if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end
  if require("mega.utils").root_has_file("Gemfile") then
    cmd = "rails c"
  else
    cmd = "irb"
  end

  mega.term.open({
    cmd = cmd,
    precmd = precmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermLua", function()
  local cmd = "lua"

  mega.term.open({
    cmd = cmd,
    direction = "horizontal",
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermPython", function()
  local cmd = "python"

  mega.term.open({
    cmd = cmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

mega.command("TermNode", function()
  local cmd = "node"

  mega.term.open({
    cmd = cmd,
    on_exit = function() end,
    ---@diagnostic disable-next-line: unused-local
    on_after_open = function(bufnr, _winnr)
      api.nvim_buf_set_var(bufnr, "cmd", cmd)
      vim.cmd("startinsert")
    end,
  })
end)

if vim.g.term_plugin then
  nnoremap("<leader>tt", "<cmd>T<cr>", "term")
  nnoremap("<leader>tf", "<cmd>T direction=float<cr>", "term (float)")
  nnoremap("<leader>tv", "<cmd>T direction=vertical<cr>", "term (vertical)")
  nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "term (tab-persistent)")
  nnoremap("<leader>tre", "<cmd>TermElixir<cr>", "repl > elixir")
  nnoremap("<leader>trr", "<cmd>TermRuby<cr>", "repl > ruby")
  nnoremap("<leader>trl", "<cmd>TermLua<cr>", "repl > lua")
  nnoremap("<leader>trn", "<cmd>TermNode<cr>", "repl > node")
  nnoremap("<leader>trp", "<cmd>TermPython<cr>", "repl > python")
end
