-- @attribution: this initially was a blend of several basic and complicated term
-- plugin ideas; ultimately, I've taken many brilliant ideas from @akinsho and @kassio
-- and created my own version for my specific needs. they are the real ones here.
--
-- TODO
-- - similar behaviour to here.nvim; aka, quick flip between terminal and current buffer
--    REF: https://github.com/jaimecgomezz/nvim/blob/9a29163c39efc7d28f21ae2ef715e8ba3f41a4e2/lua/plugins/term.lua

if not Plugin_enabled() then return end

-- REF: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/terminal.lua
-- REF: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/init.lua
-- REF: https://github.com/folke/snacks.nvim/blob/main/lua/snacks/win.lua

local fmt = string.format
local api = vim.api
local fn = vim.fn
local U = require("config.utils")
local augroup = require("config.autocmds").augroup
local command = vim.api.nvim_create_user_command

local terminals = {}

local nil_id = -1
local term_win_id = nil_id
local term_buf_id = nil_id
local term_tab_id = nil
local term_job_id = nil
local Term = nil

local __buftype = "terminal"
local __filetype = "megaterm"

local function is_valid_buffer(bufnr) return vim.api.nvim_buf_is_valid(bufnr) end
local function is_valid_window(winnr) return vim.api.nvim_win_is_valid(winnr) end
local function find_windows_by_bufnr(bufnr) return fn.win_findbuf(bufnr) end

--- @class TermOpts
--- @field direction? "horizontal"|"vertical"|"float"|"tab"
--- @field position? "bottom"|"right"|"float"|"full"|"tab"
--- @field size? number
--- @field cmd? string
--- @field pre_cmd? string
--- @field on_open? function
--- @field on_exit? function
--- @field notifier? function
--- @field focus_on_open? boolean,
--- @field move_on_position_change? boolean,
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
  term_win_id = nil_id
  term_job_id = nil_id
  term_tab_id = nil

  Term = {}
end

---@class ParsedArgs
---@field position string?
---@field cmd string?
---@field dir string?
---@field size number?
---@field move_on_position_change boolean?

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
        elseif vim.tbl_contains({ "move_on_position_change" }, key) then
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

  if vim.tbl_contains({ "float", "tab" }, term.position) then
    vim.opt_local.signcolumn = "no"
    vim.bo.bufhidden = "wipe"
    vim.cmd("setlocal bufhidden=wipe")
  end
end

local function set_win_size()
  if Term and Term.position == "right" then
    vim.cmd(fmt("let &winwidth=%d", Term.size))
    vim.opt_local.winfixwidth = true
    vim.opt_local.winminwidth = Term.size / 2
    vim.api.nvim_win_set_width(Term.winnr, Term.size)
  elseif Term and Term.position == "bottom" then
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
  position = "bottom",
  start_insert = true,
}

local split_opts = {
  ["bottom"] = {
    new = "botright new",
    split = "rightbelow sbuffer",
    dimension = "height",
    size = vim.fn.winheight(0) > 50 and 22 or 18,
    res = "resize",
    winc = "J",
  },
  ["right"] = {
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

local function set_keymaps(bufnr, position)
  local opts = { buffer = bufnr, silent = false }
  local function quit()
    unset_term(true)
    vim.cmd("wincmd p")
  end

  local nmap = function(lhs, rhs) vim.keymap.set("n", lhs, rhs, opts) end
  local tmap = function(lhs, rhs) vim.keymap.set("t", lhs, rhs, opts) end

  if position ~= "tab" then nmap("q", quit) end

  tmap("<esc>", [[<C-\><C-n>]])
  tmap("<C-h>", [[<cmd>wincmd p<cr>]])
  tmap("<C-j>", [[<cmd>wincmd p<cr>]])
  tmap("<C-k>", [[<cmd>wincmd p<cr>]])
  tmap("<C-l>", [[<cmd>wincmd p<cr>]])
  tmap("<C-;>", mega.toggle)
  tmap("<C-x>", quit)
end

local function create_term(opts)
  -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
  local term_cmd = opts.pre_cmd and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd

  term_job_id = vim.fn.jobstart(term_cmd, {
    term = true,
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

  return term_job_id
end

local function create_win(opts)
  if opts.position == "float" then
    local winnr, bufnr = opts.new(opts.size, opts.caller_winnr)
    set_term(winnr, bufnr, nil, opts)
  elseif opts.position == "tab" then
    api.nvim_command(fmt("%s", opts.new))
    set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), api.nvim_get_current_tabpage(), opts)
  else
    -- D(fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size))
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
          if vim.tbl_contains({ "right", "bottom" }, Term.position) then set_win_size() end
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
  if vim.tbl_contains({ "right", "bottom", "tab" }, Term.position) then
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
  if vim.tbl_contains({ "right", "bottom" }, Term.position) then set_win_size() end

  set_keymaps(term_buf_id, Term.position)
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
  api.nvim_buf_set_var(term_buf_id, "term_position", Term.position)
  api.nvim_buf_set_var(term_buf_id, "term_name", __filetype)
  -- api.nvim_buf_set_name(term_buf_id, __filetype) -- 0 refers to the current buffer

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
  if opts.position == "tab" then unset_term(false) end

  return term_buf_id ~= nil_id and term_win_id ~= nil_id and term_job_id ~= nil_id
end

local function build_defaults(opts)
  opts = vim.tbl_extend("force", default_opts, opts or {})
  opts = vim.tbl_extend("force", split_opts[opts.position], opts)
  opts = vim.tbl_extend("keep", opts, { caller_winnr = vim.fn.winnr() })
  opts = vim.tbl_extend("keep", opts, { focus_on_open = true })
  opts = vim.tbl_extend("keep", opts, { move_on_position_change = true })

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
      position = { parsed_opts.position, "string", true },
      move_on_position_change = { parsed_opts.move_on_position_change, "boolean", true },
    })

    if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
  end

  new_or_open_term(parsed_opts)
end

function mega.toggle(opts)
  D({ "mega.toggle", term_win_id, term_buf_id, term_job_id, term_tab_id })

  opts = build_defaults(opts or {})
  local function cleanup()
    term_buf_id = nil_id
    term_win_id = nil_id
    term_tab_id = nil_id
    term_job_id = nil_id
  end

  local function is_visible()
    -- Check if our terminal buffer exists and is displayed in any window
    if not term_buf_id or not vim.api.nvim_buf_is_valid(term_buf_id) then return false end

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if vim.api.nvim_win_get_buf(win) == term_buf_id then
          term_win_id = win
          term_tab_id = tab

          break
        end
      end

      if term_win_id ~= nil_id then return true end
    end

    -- Buffer exists but no window displays it
    term_win_id = nil_id
    return false
  end

  local function is_valid()
    -- First check if we have a valid buffer
    if not term_buf_id or not vim.api.nvim_buf_is_valid(term_buf_id) then
      cleanup()
      return false
    end

    -- If buffer is valid but window is invalid, try to find a window displaying this buffer
    if not term_win_id or not vim.api.nvim_win_is_valid(term_win_id) then
      -- Search all windows for our terminal buffer
      -- local windows = vim.api.nvim_list_wins()
      -- for _, win in ipairs(windows) do
      --   if vim.api.nvim_win_get_buf(win) == term_buf_id then
      --     -- Found a window displaying our terminal buffer, update the tracked window ID
      --     term_win_id = win
      --     logger.debug("terminal", "Recovered terminal window ID:", win)
      --     return true
      --   end
      -- end
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          if vim.api.nvim_win_get_buf(win) == term_buf_id then
            term_win_id = win
            term_tab_id = tab

            break
          end
        end

        if term_win_id ~= nil_id then return true end
      end

      -- Buffer exists but no window displays it - this is normal for hidden terminals
      return true -- Buffer is valid even though not visible
    end

    -- Both buffer and window are valid
    return true
  end

  local function focus()
    if is_valid() then
      vim.api.nvim_set_current_win(term_win_id)
      vim.cmd("startinsert")
    end
  end

  local function find()
    -- Iterate through all existing buffers and find the opencode buffer
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if pcall(vim.api.nvim_buf_get_var, buf, "term_name") and vim.api.nvim_buf_get_var(buf, "term_name") == __filetype then
        -- if string.find(vim.api.nvim_buf_get_name(buf), __filetype, 1, true) then
        term_buf_id = buf

        break
      end
    end

    if term_buf_id then
      -- Iterate through all tabpages and their windows to find where the buffer is
      for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
          if vim.api.nvim_win_get_buf(win) == term_buf_id then
            term_win_id = win
            term_tab_id = tab

            break
          end
        end

        if term_win_id ~= nil_id then
          break -- Found the tab, exit outer loop
        end
      end
    end

    return term_win_id, term_buf_id, term_tab_id
  end

  local function hide()
    -- Hide the terminal window but keep the buffer and job alive
    if term_buf_id and vim.api.nvim_buf_is_valid(term_buf_id) and term_win_id and vim.api.nvim_win_is_valid(term_win_id) then
      -- Set buffer to hide instead of being wiped when window closes
      vim.api.nvim_buf_set_var(term_buf_id, "bufhidden", "hide")

      -- Close the window - this preserves the buffer and job
      vim.api.nvim_win_close(term_win_id, false)
      term_win_id = nil_id -- Clear window reference

      vim.notify("terminal: Terminal window hidden, process preserved", L.INFO)
    end
  end

  local function show(opts, focus)
    -- Show an existing hidden terminal buffer in a new window
    if not term_buf_id or not vim.api.nvim_buf_is_valid(term_buf_id) then return false end

    -- Check if it's already visible
    if is_visible() then
      if focus then focus() end
      return true
    end

    local original_win = vim.api.nvim_get_current_win()

    -- Create a new window for the existing buffer
    local width = math.floor(vim.o.columns * 0.30)
    local full_height = vim.o.lines
    local placement_modifier

    if opts.split_side == "left" then
      placement_modifier = "topleft "
    else
      placement_modifier = "botright "
    end

    vim.cmd(placement_modifier .. width .. "vsplit")
    local new_winid = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_height(new_winid, full_height)

    -- Set the existing buffer in the new window
    vim.api.nvim_win_set_buf(new_winid, term_buf_id)
    term_win_id = new_winid

    if focus then
      -- Focus the terminal: switch to terminal window and enter insert mode
      vim.api.nvim_set_current_win(term_win_id)
      vim.cmd("startinsert")
    else
      -- Preserve user context: return to the window they were in before showing terminal
      vim.api.nvim_set_current_win(original_win)
    end

    return true
  end

  -- Check if we have a valid terminal buffer (process running)
  local has_buffer = term_buf_id and vim.api.nvim_buf_is_valid(term_buf_id)
  local buf_visible = has_buffer and is_visible()

  if buf_visible then
    D({ "buf_visible? yes", term_win_id, term_buf_id, term_job_id, term_tab_id })
    -- Terminal is visible, hide it (but keep process running)
    hide()
  else
    -- Terminal is not visible
    if has_buffer then
      D({ "has_buffer? yes", term_win_id, term_buf_id, term_job_id, term_tab_id })

      -- -- Terminal process exists but is hidden, show it
      if show(opts, true) then
        vim.notify("terminal: showing hidden term", L.INFO)
      else
        vim.notify("terminal: failed to show hidden term", L.ERROR)
      end
    else
      -- No terminal process exists, check if there's an existing one we lost track of
      local existing_win, existing_buf, _existing_tab = find()

      if existing_buf ~= nil_id and existing_win ~= nil_id then
        -- Recover the existing terminal
        term_buf_id = existing_buf
        term_win_id = existing_win
        vim.notify("terminal: Recovered existing megaterm", L.INFO)

        focus()
      else
        -- No existing terminal found, create a new one
        if not new_term(opts) then vim.notify("failed to find or create a megaterm", L.ERROR) end
      end
    end
  end
end

-- [COMMANDS] ------------------------------------------------------------------

-- _G.Megat = mega.toggle
Command("T", function(opts) mega.term(opts.args) end, { nargs = "*" })
nnoremap("<C-;>", function(args) mega.term(args) end, { desc = "toggle megaterm (split)" })
-- Nnoremap("<C-;>", function() mega.toggle() end, { desc = "toggle megaterm (split)" })
-- nnoremap("<C-/>", function() mega.term({ position = "right" }) end, { desc = "toggle megaterm (vsplit)" })

return M
