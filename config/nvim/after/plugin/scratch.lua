if not mega then return end

mega["tterm"] = {}

do
  vim.g.debug_enabled = true

  --- @class TermOpts
  --- @field direction? "horizontal"|"vertical"|"float"|"tab"
  --- @field size? number
  --- @field cmd? string
  --- @field pre_cmd? string
  --- @field on_open? function
  --- @field on_exit? function
  --- @field notifier? function
  --- @field caller_win? number
  --- @field start_insert? boolean
  local term = {}

  local function is_valid_buffer(bufnr) return vim.api.nvim_buf_is_valid(bufnr) end
  local function is_valid_window(winnr) return vim.api.nvim_win_is_valid(winnr) end
  local function is_valid_term()
    local is_valid = term ~= nil and mega.tlen(term) > 0 and is_valid_buffer(term.bufnr) and is_valid_window(term.winnr)
    P(fmt("check term validity(%s) for %s", is_valid, I(term)))
    return is_valid
  end

  local function set_size(winnr, dimension, size)
    vim.api.nvim_command(fmt([[lua vim.api.nvim_win_set_%s(%s, %s)]], dimension, winnr, size))
  end

  local function set_term(winnr, bufnr, opts)
    term = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr })
    P(fmt("setting term for winnr/bufnr %d/%d to %s", winnr, bufnr, I(term)))
  end
  local function unset_term()
    term = {}
    vim.api.nvim_buf_delete(term.bufnr, { force = true })
    P("unsetting term")
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
  ---@return ParsedArgs
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

  local create_float = function(bufnr, size)
    local parsed_size = (size / 100)
    local winnr = vim.api.nvim_open_win(bufnr, true, {
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
    vim.api.nvim_buf_set_option(bufnr, "filetype", "megaterm")

    set_win_hls({
      "Normal:PanelBackground",
      "FloatBorder:PanelBorder",
      "CursorLine:Visual",
      "Search:None",
    })

    vim.cmd("setlocal bufhidden=wipe")

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
      win = "J",
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
        local bufnr = vim.api.nvim_create_buf(true, true)
        local winnr = create_float(bufnr, size)

        return winnr, bufnr
      end,
      split = function(bufnr)
        local winnr = term.winnr
        return winnr, bufnr
      end,
      size = 80,
    },
  }

  -- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
  local function set_keymaps(bufnr, _, direction)
    local opts = { buffer = bufnr, silent = false }
    -- quit terminal and go back to last window
    -- TODO: do we want this ONLY for non tab terminals?
    if direction ~= "tab" then
      nmap("q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
        unset_term()
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

  local function set_term_opts(bufnr)
    local opts = term

    vim.opt_local.relativenumber = false
    vim.opt_local.number = false
    vim.opt_local.signcolumn = "yes:1"
    -- vim.bo[bufnr].filetype = "megaterm"
    -- vim.bo[bufnr].buftype = "terminal"
    pcall(vim.api.nvim_buf_set_option, bufnr, "filetype", "megaterm")
    pcall(vim.api.nvim_buf_set_option, bufnr, "buftype", "terminal")

    set_win_hls()
  end

  local function set_window_size(bufnr)
    local opts = term

    if opts.direction == "vertical" then
      vim.cmd(fmt("let &winwidth=%d", opts.size))
    elseif opts.direction == "horizontal" then
      vim.cmd(fmt("let &winheight=%d", opts.size))
    end
  end

  local set_autocommands = function(bufnr)
    local opts = term
    -- P(fmt("buffer name: %s", vim.api.nvim_buf_get_name(bufnr)))

    mega.augroup("MegatermResizer", {
      {
        event = { "WinLeave" },
        buffer = bufnr,
        command = function()
          -- P(fmt("winleave win/buf: %s/%s", opts.winnr, bufnr))
          set_window_size(bufnr)
        end,
      },
      {
        event = { "WinEnter" },
        buffer = bufnr,
        command = function(evt)
          set_window_size(bufnr)
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

  local function on_open(bufnr)
    local opts = term

    vim.cmd([[do User MegaTermOpened]])

    set_term_opts(bufnr)
    set_window_size(bufnr)
    set_keymaps(bufnr, opts.winnr, opts.direction)

    -- custom on_open
    if opts.on_open ~= nil and type(opts.on_open) == "function" then
      opts.on_open(bufnr)
    else
      -- default_on_open
      vim.api.nvim_command([[normal! G]])
      if opts.start_insert then vim.cmd("startinsert") end
      -- if opts.direction ~= "float" then vim.cmd([[wincmd p]]) end
    end

    -- set some useful term-derived vars
    vim.api.nvim_buf_set_var(bufnr, "term_cmd", opts.cmd)
    vim.api.nvim_buf_set_var(bufnr, "term_buf", opts.bufnr)
    vim.api.nvim_buf_set_var(bufnr, "term_win", opts.winnr)
    vim.api.nvim_buf_set_var(bufnr, "term_direction", opts.direction)

    set_autocommands(bufnr)
  end

  local function create_term(winnr, bufnr, opts)
    local cmd = opts.cmd
    local on_exit = opts.on_exit or nil
    local notifier = opts.notifier or nil

    -- REF: https://github.com/seblj/dotfiles/commit/fcdfc17e2987631cbfd4727c9ba94e6294948c40#diff-bbe1851dbfaaa99c8fdbb7229631eafc4f8048e09aa116ef3ad59cde339ef268L56-R90
    vim.fn.termopen(cmd, {
      on_exit = function(job_id, exit_code, event)
        if notifier ~= nil and type(notifier) == "function" then notifier(cmd, exit_code) end

        -- if we get a custom on_exit, run it instead...
        if on_exit ~= nil and type(on_exit) == "function" then
          on_exit(job_id, exit_code, event, cmd, winnr, bufnr)
        else
          if exit_code == 0 then
            vim.api.nvim_buf_delete(bufnr, { force = true })
            vim.cmd([[wincmd p]])
          end
        end
      end,
    })

    set_term(winnr, bufnr, opts)
  end

  local function create_win(opts)
    local size = opts.size
    local new_cmd = opts.new
    local win_cmd = opts.winc
    local dimension = opts.dimension

    -- vim.api.nvim_command(fmt([[%s | wincmd %s]], new_cmd, win_cmd))
    vim.api.nvim_command(fmt([[%s]], new_cmd))

    local winnr = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_command(fmt([[lua vim.api.nvim_win_set_%s(%s, %s)]], dimension, winnr, size))

    return winnr, bufnr
  end

  local function use_win()
    -- vim.api.nvim_command(fmt([[%s | wincmd %s]], new_cmd, win_cmd))
    P(fmt("use_win term: %s", I(term)))
    vim.api.nvim_command(fmt([[%s %s]], term.split, term.bufnr))
    vim.api.nvim_command(fmt([[lua vim.api.nvim_win_set_%s(%s, %s)]], term.dimension, term.winnr, term.size))
  end

  --- Handles opening an existing terminal
  local function existing_term()
    use_win()
    on_open(term.bufnr)

    vim.api.nvim_set_current_win(term.winnr)
    vim.api.nvim_set_current_buf(term.bufnr)
  end

  --- Creates a new terminal window as a split (horizontal or vertical), tab, or float,
  --- with custom hooks for various points of creation, command execution, and exiting.
  --- @param opts? TermOpts
  local function new_term(opts)
    opts = vim.tbl_extend("force", default_opts, opts or {})
    opts = vim.tbl_extend("keep", split_opts[opts.direction], opts)

    local winnr, bufnr = create_win(opts)
    create_term(winnr, bufnr, opts)
    on_open(bufnr)

    vim.api.nvim_set_current_win(winnr)
    vim.api.nvim_set_current_buf(bufnr)
  end

  local function open_term()
    if not is_valid_term() or vim.fn.bufexists(term.bufnr) ~= 1 or term.direction == "tab" then
      P("new")
      new_term()
    elseif vim.fn.win_gotoid(term.winnr) ~= 1 then
      P("existing")
      existing_term()
    end

    set_autocommands()
  end

  local function hide_term()
    if vim.fn.win_gotoid(term.winnr) == 1 then vim.api.nvim_command("hide") end
  end

  function mega.tterm.toggle(args)
    local parsed_opts = args or {}

    if type(args) == "string" then
      parsed_opts = command_parser(args)

      vim.validate({
        size = { parsed_opts.size, "number", true },
        direction = { parsed_opts.direction, "string", true },
      })
      if parsed_opts.size then parsed_opts.size = tonumber(parsed_opts.size) end
    end

    if is_valid_term() and term.winnr and vim.fn.win_gotoid(term.winnr) == 1 and parsed_opts.direction ~= "tab" then
      P("hiding")
      hide_term()
      vim.cmd([[wincmd p]])
    else
      P("opening")
      open_term()
    end

    -- vim.g.debug_enabled = false
  end

  -- [COMMANDS] ------------------------------------------------------------------

  mega.command("MT", function(opts) mega.tterm.toggle(opts.args) end, { nargs = "*" })

  -- [KEYMAPS] ------------------------------------------------------------------

  -- nnoremap("<leader>tt", "<cmd>MT<cr>", "term")
  -- nnoremap("<leader>tf", "<cmd>MT direction=float<cr>", "term (float)")
  -- nnoremap("<leader>tv", "<cmd>MT direction=vertical<cr>", "term (vertical)")
  -- nnoremap("<leader>tp", "<cmd>MT direction=tab<cr>", "term (tab-persistent)")
end
