if not mega then return end
if not vim.g.enabled_plugin["term"] then return end

if false then
  local fmt = string.format
  local api = vim.api
  local fn = vim.fn

  local nil_buf_id = 999999
  local term_buf_id = nil_buf_id
  local term_win_id = nil
  local term_tab_id = nil

  local set_win_hls = function(winnr, hls)
    hls = hls
      or {
        "Normal:PanelBackground",
        "CursorLine:PanelBackground",
        "CursorLineNr:PanelBackground",
        "CursorLineSign:PanelBackground",
        "SignColumn:PanelBackground",
        "FloatBorder:PanelBorder",
      }
    api.nvim_win_set_option(winnr, "winhl", table.concat(hls, ","))
  end

  local set_autocommands = function()
    -- FIXME: i just want the dang term wins to stay consistent sized
    mega.augroup("MegatermResizer", {
      {
        event = { "BufEnter" },
        pattern = { "term://*#megaterm#*" },
        nested = true,
        command = function(evt)
          -- vim.opt_local.relativenumber = false
          -- vim.opt_local.number = false
          -- vim.opt_local.signcolumn = "yes:1"

          -- api.nvim_buf_set_option(term_buf_id, "filetype", "megaterm")

          -- set_win_hls(term_win_id)
          -- P(evt)
          -- local info = vim.api.nvim_get_mode()
          -- if info and (info.mode == "n" or info.mode == "nt") then vim.cmd("normal! G") end
          -- -- P(I(evt))
          P("we're in bufenter")
          if vim.api.nvim_win_is_valid(term_win_id) and vim.bo[args.buf] == vim.api.nvim_win_get_buf(term_win_id) then
            local buf = vim.bo[vim.api.nvim_win_get_buf(term_win_id)]
            if buf.filetype == "megaterm" then
              P("we're in a valid megaterm buffer on enter")
              -- local window = vim.wo[win]
              -- local size = args.size or cmd_opts.size
              -- local dimension = cmd_opts.dimension
              -- vim.cmd(fmt("lua vim.api.nvim_win_set_%s(%s, %s)", dimension, term_win_id, size))
              -- if evt.event == "WinEnter" then vim.cmd([[:e | execute 'normal! g`"']]) end
            end
          end
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
    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "no"
    api.nvim_buf_set_option(bufnr, "filetype", "megaterm")

    set_win_hls(winnr, {
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })

    vim.cmd("setlocal bufhidden=wipe")
    return winnr
  end
  local default_opts = {
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
  local function set_keymaps(bufnr, winnr, direction)
    local opts = { buffer = bufnr, silent = false }
    -- quit terminal and go back to last window
    -- TODO: do we want this ONLY for non tab terminals?
    if direction ~= "tab" then
      nmap("q", function()
        api.nvim_buf_delete(bufnr, { force = true })
        bufnr = nil_buf_id
        -- jump back to our last window
        vim.cmd([[wincmd p]])
      end, opts)
    end

    tmap("<esc>", [[<C-\><C-n>]], opts)
    -- TODO: find a way to be more intelligent about these (e.g., how can we use `wincmd p` and know that we're goign to the right thing from the term)
    tmap("<C-h>", [[<Cmd>wincmd h<CR>]], opts)
    tmap("<C-j>", [[<Cmd>wincmd j<CR>]], opts)
    tmap("<C-k>", [[<Cmd>wincmd k<CR>]], opts)
    tmap("<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    -- TODO: want a `<C-r>` or `;,` to pull up last executed command in the term
    -- TODO: want a `<C-b>` to auto scroll back and `<C-f>` to auto scroll forward in insert mode
    -- NOTE: keep this disbled so we can C-c in a shell to halt a running process:
    -- tmap("<C-c>", [[<C-\><C-n>]], opts)
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
            vim.cmd([[wincmd p]])
          end
        end
      end,
    })
  end

  local function handle_new(cmd, opts)
    local size = opts["size"] or cmd.size
    local init_cmd = opts.cmd or "zsh -i"
    local precmd = opts.precmd or nil
    local on_after_open = opts.on_after_open or nil
    local winnr = opts.winnr

    if vim.api.nvim_buf_is_valid(term_buf_id) and opts.temp then
      vim.api.nvim_buf_delete(term_buf_id, { force = true })
      term_buf_id = nil_buf_id
    end

    if opts.direction == "float" then
      cmd.new(size)
    elseif opts.direction == "tab" then
      api.nvim_command(fmt("%s", cmd.new))

      term_win_id = api.nvim_get_current_win()
      term_buf_id = api.nvim_get_current_buf()
      term_tab_id = api.nvim_get_current_tabpage()

      -- Focus first file:line:col pattern in the terminal output
      -- vim.keymap.set('n', 'F', [[:call search('\f\+:\d\+:\d\+')<CR>]], { buffer = true, silent = true })
      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
      vim.opt_local.signcolumn = "no"
      api.nvim_buf_set_option(term_buf_id, "filetype", "megaterm")
      vim.bo.bufhidden = "wipe"
    else
      api.nvim_command(
        fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", cmd.new, cmd.winc, cmd.dimension, 0, size)
      )

      term_win_id = api.nvim_get_current_win()
      term_buf_id = api.nvim_get_current_buf()

      vim.opt_local.relativenumber = false
      vim.opt_local.number = false
      vim.opt_local.signcolumn = "yes:1"
      api.nvim_buf_set_option(term_buf_id, "filetype", "megaterm")

      set_win_hls(term_win_id)
    end

    api.nvim_buf_set_var(term_buf_id, "term_cmd", opts.cmd)
    api.nvim_buf_set_var(term_buf_id, "term_buf", term_buf_id)
    api.nvim_buf_set_var(term_buf_id, "term_win", term_win_id)
    api.nvim_buf_set_var(term_buf_id, "term_direction", opts.direction)

    set_keymaps(term_buf_id, term_win_id, opts.direction)

    if precmd ~= nil then init_cmd = fmt("%s; %s", precmd, init_cmd) end

    create_term(init_cmd, opts)

    if on_after_open ~= nil and type(on_after_open) == "function" then
      on_after_open(term_buf_id, winnr)
    else
      api.nvim_command([[normal! G]])
      if opts.direction ~= "float" then vim.cmd([[wincmd p]]) end
    end

    if opts.direction == "tab" then
      term_win_id = nil
      term_buf_id = nil_buf_id
      term_tab_id = nil
    end
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
      api.nvim_command(
        fmt(
          "%s %s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)",
          cmd.split,
          term_buf_id,
          cmd.winc,
          cmd.dimension,
          vim.api.nvim_win_is_valid(term_win_id) and term_win_id or 0,
          size
        )
      )
      term_win_id = api.nvim_get_current_win()
    end

    if on_after_open ~= nil and type(on_after_open) == "function" then
      on_after_open(term_buf_id, winnr)
    else
      api.nvim_command([[normal! G]])
      if opts.direction ~= "float" then vim.cmd([[wincmd p]]) end
    end
  end

  function mega.term.open(args)
    args = args or {}
    local direction = args["direction"] or "horizontal"
    local cmd_opts = default_opts[direction]

    if fn.bufexists(term_buf_id) ~= 1 or direction == "tab" or args.temp then
      handle_new(cmd_opts, args)
    elseif fn.win_gotoid(term_win_id) ~= 1 then
      handle_existing(cmd_opts, args)
    end

    set_autocommands()
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
    if not parsed.cmd then parsed["cmd"] = "zsh" end
    if not parsed.on_after_open then parsed["on_after_open"] = function() vim.cmd("startinsert") end end

    if fn.win_gotoid(term_win_id) == 1 and parsed.direction ~= "tab" then
      mega.term.hide()
      vim.cmd([[wincmd p]])
    else
      mega.term.open(parsed)
    end
  end

  mega.command("T", function(opts) mega.term.toggle(opts.args) end, { nargs = "*" })
  mega.command("Tv", function() vim.cmd([[T direction=vertical]]) end)
  mega.command("Tf", function() vim.cmd([[T direction=float]]) end)

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
      ---@diagnostic disable-next-line: unused-local
      on_after_open = function(bufnr, _winnr)
        api.nvim_buf_set_var(bufnr, "cmd", cmd)
        vim.cmd("startinsert")
      end,
    })
  end)

  mega.command("TermRuby", function(args)
    local precmd = ""
    local cmd = ""
    if require("mega.utils").root_has_file("Deskfile") then precmd = "eval $(desk load)" end

    if args.bang then
      cmd = fmt("ruby %s", vim.fn.expand("%"))
    elseif require("mega.utils").root_has_file("Gemfile") then
      cmd = "rails c"
    else
      cmd = "irb"
    end

    mega.term.open({
      cmd = cmd,
      precmd = precmd,
      ---@diagnostic disable-next-line: unused-local
      on_after_open = function(bufnr, _winnr)
        api.nvim_buf_set_var(bufnr, "cmd", cmd)
        vim.cmd("startinsert")
      end,
    })
  end, { bang = true })

  mega.command("TermLua", function()
    local cmd = "lua"

    mega.term.open({
      cmd = cmd,
      direction = "horizontal",
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
      ---@diagnostic disable-next-line: unused-local
      on_after_open = function(bufnr, _winnr)
        api.nvim_buf_set_var(bufnr, "cmd", cmd)
        vim.cmd("startinsert")
      end,
    })
  end)

  -- FIXME: we don't rerun the test command anymore (we need to)

  nnoremap("<leader>tt", "<cmd>T<cr>", "term")
  nnoremap("<leader>tf", "<cmd>T direction=float<cr>", "term (float)")
  nnoremap("<leader>tv", "<cmd>T direction=vertical<cr>", "term (vertical)")
  nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "term (tab-persistent)")
  nnoremap("<leader>tre", "<cmd>TermElixir<cr>", "repl > elixir")
  nnoremap("<leader>trr", "<cmd>TermRuby<cr>", "repl > ruby")
  nnoremap("<leader>trR", "<cmd>TermRuby!<cr>", "repl > ruby (current file)")
  nnoremap("<leader>trl", "<cmd>TermLua<cr>", "repl > lua")
  nnoremap("<leader>trn", "<cmd>TermNode<cr>", "repl > node")
  nnoremap("<leader>trp", "<cmd>TermPython<cr>", "repl > python")
else
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  -- ============================================================================================================================================================================
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if not mega then return end
  if not vim.g.enabled_plugin["term"] then return end

  local fmt = string.format
  local api = vim.api
  local fn = vim.fn

  local nil_buf_id = 999999
  local term_win_id = nil
  local term_buf_id = nil_buf_id
  local term_tab_id = nil
  local term = nil

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

    term = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr, tabnr = tabnr })
    return term
  end

  local function unset_term()
    if api.nvim_buf_is_loaded(term_buf_id) then api.nvim_buf_delete(term_buf_id, { force = true }) end
    term_buf_id = nil_buf_id
    term_win_id = nil
    term_tab_id = nil
    term = {}
  end

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
          elseif key == "go_back" or key == "open" then
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
    pcall(vim.api.nvim_buf_set_option, term_buf_id, "filetype", "megaterm")
    pcall(vim.api.nvim_buf_set_option, term_buf_id, "buftype", "terminal")

    if vim.tbl_contains({ "float", "tab" }, term.direction) then
      -- Focus first file:line:col pattern in the terminal output
      -- vim.keymap.set('n', 'F', [[:call search('\f\+:\d\+:\d\+')<CR>]], { buffer = true, silent = true })
      vim.opt_local.signcolumn = "no"
      vim.bo.bufhidden = "wipe"
    end
  end

  local function set_win_size(bufnr)
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
        buffer = term_buf_id,
        command = function(evt)
          -- P(fmt("winleave win/buf: %s/%s", opts.winnr, bufnr))
          set_win_size(evt.buf)
        end,
      },
      {
        event = { "WinEnter" },
        buffer = term_buf_id,
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
        pattern = { "term://*" },
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
        term_buf_id = api.nvim_create_buf(true, true)
        term_win_id = create_float(term_buf_id, size)
        return term_win_id, term_buf_id
      end,
      split = function(size, bufnr)
        term_win_id = create_float(bufnr, size)
        return term_win_id, bufnr
      end,
      size = 80,
    },
  }

  -- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
  local function set_keymaps()
    local keymap_opts = { buffer = term_buf_id, silent = false }
    -- quit terminal and go back to last window
    -- TODO: do we want this ONLY for non tab terminals?
    if term.direction ~= "tab" then
      nmap("q", function()
        api.nvim_buf_delete(term_buf_id, { force = true })
        term_buf_id = nil_buf_id
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
    local cmd = opts.pre_cmd and fmt("%s; %s", opts.pre_cmd, opts.cmd) or opts.cmd
    vim.fn.termopen(cmd, {
      ---@diagnostic disable-next-line: unused-local
      on_exit = function(jobid, exit_code, event)
        -- if we get a custom on_exit, run it instead...
        if opts.on_exit ~= nil and type(opts.on_exit) == "function" then
          opts.on_exit(jobid, exit_code, event, cmd, opts.caller_winnr, term_buf_id)
        else
          if opts.notifier ~= nil and type(opts.notifier) == "function" then opts.notifier(cmd, exit_code) end
          -- test passed/process ended with an "ok" exit code, so let's close it.
          if exit_code == 0 then
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
    else
      api.nvim_command(
        fmt("%s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)", opts.new, opts.winc, opts.dimension, 0, opts.size)
      )
      set_term(api.nvim_get_current_win(), api.nvim_get_current_buf(), nil, opts)
    end

    api.nvim_set_current_buf(term_buf_id)
    api.nvim_win_set_buf(term_win_id, term_buf_id)
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
      vim.wo[term_win_id].winblend = 0
    end
    set_win_size()
    set_keymaps()
    set_autocommands()

    -- custom on_open
    if term.on_open ~= nil and term(term.on_open) == "function" then
      term.on_open(term_buf_id)
    else
      -- default_on_open
      vim.api.nvim_command([[normal! G]])
      if term.start_insert then vim.cmd("startinsert") end
    end

    -- set some useful term-derived vars
    api.nvim_buf_set_var(term_buf_id, "term_cmd", term.cmd)
    api.nvim_buf_set_var(term_buf_id, "term_buf", term_buf_id)
    api.nvim_buf_set_var(term_buf_id, "term_win", term_win_id)
    api.nvim_buf_set_var(term_buf_id, "term_direction", term.direction)

    vim.cmd([[do User MegaTermOpened]])
  end

  local function new_term(opts)
    if is_valid_buffer(term_buf_id) and opts.temp then
      unset_term()
      -- vim.api.nvim_buf_delete(term_buf_id, { force = true })
      -- term_buf_id = nil_buf_id
    end

    create_win(opts)
    create_term(opts)
    on_open()

    -- we only want new tab terms each time
    if opts.direction == "tab" then unset_term() end
  end

  local function open_term(opts)
    if opts.direction == "float" then
      opts.split(opts.size, term_buf_id)
    elseif opts.direction == "tab" then
      api.nvim_command(fmt("%s%s", term_tab_id, opts.split))
      term_win_id = nil
    else
      api.nvim_command(
        fmt(
          "%s %s | wincmd %s | lua vim.api.nvim_win_set_%s(%s, %s)",
          opts.split,
          term_buf_id,
          opts.winc,
          opts.dimension,
          is_valid_window(term_win_id) and term_win_id or 0,
          opts.size
        )
      )
    end

    on_open()
    -- term_win_id = api.nvim_get_current_win()
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
    if fn.bufexists(term_buf_id) ~= 1 or opts.direction == "tab" then
      new_term(opts)
    elseif fn.win_gotoid(term_win_id) ~= 1 then
      open_term(opts)
    end

    if not opts.focus_on_open then vim.cmd([[wincmd p]]) end
  end

  local function hide_term()
    if fn.win_gotoid(term_win_id) == 1 then
      api.nvim_command("hide")
      vim.cmd([[wincmd p]])
    end
  end

  local function move_term(opts)
    local orig_buf_id = term_buf_id
    local orig_win_id = term_win_id

    hide_term()
    new_or_open_term(opts)
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
      })

      if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
    end

    if fn.win_gotoid(term_win_id) == 1 and parsed_opts.direction ~= "tab" then
      if term.direction and parsed_opts.direction ~= term.direction and parsed_opts.move_on_direction_change then
        P(
          fmt(
            "hiding this term (%s) but with a different direction expected (%s). %d/%d",
            term.direction,
            parsed_opts.direction,
            term_win_id,
            term_buf_id
          )
        )
        move_term(parsed_opts)
      end

      hide_term()
    else
      new_or_open_term(parsed_opts)
    end
  end
  mega.term.open = new_or_open_term

  -- [COMMANDS] ------------------------------------------------------------------
  mega.command("T", function(opts) mega.term.toggle(opts.args) end, { nargs = "*" })

  -- [KEYMAPS] ------------------------------------------------------------------
  nnoremap("<leader>tt", "<cmd>T<cr>", "term")
  nnoremap("<leader>tf", "<cmd>T direction=float<cr>", "term (float)")
  nnoremap("<leader>tv", "<cmd>T direction=vertical<cr>", "term (vertical)")
  nnoremap("<leader>tp", "<cmd>T direction=tab<cr>", "term (tab-persistent)")
end
