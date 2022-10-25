if not mega then return end

do
  local terms = {}

  local function is_valid_buffer(bufnr) return vim.api.nvim_buf_is_valid(bufnr) end
  local function is_valid_window(winnr) return vim.api.nvim_win_is_valid(winnr) end

  local function set_size(winnr, dimension, size)
    vim.api.nvim_command(fmt([[lua vim.api.nvim_win_set_%s(%s, %s)]], dimension, winnr, size))
  end

  local function add_term(winnr, bufnr, opts)
    terms[bufnr] = vim.tbl_extend("force", opts, { winnr = winnr, bufnr = bufnr })
    P(I(terms))
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
    -- ["float"] = {
    --   new = function(size)
    --     term_buf_id = api.nvim_create_buf(true, true)
    --     term_win_id = create_float(term_buf_id, size)
    --   end,
    --   split = function(size, bufnr) term_win_id = create_float(bufnr, size) end,
    --   size = 80,
    -- },
  }

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

  -- REF: https://github.com/outstand/titan.nvim/blob/main/lua/titan/plugins/toggleterm.lua
  local function set_keymaps(bufnr, _winnr, direction)
    local opts = { buffer = bufnr, silent = false }
    -- quit terminal and go back to last window
    -- TODO: do we want this ONLY for non tab terminals?
    if direction ~= "tab" then
      nmap("q", function()
        vim.api.nvim_buf_delete(bufnr, { force = true })
        bufnr = nil
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
    local opts = terms[bufnr]

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
    local opts = terms[bufnr]

    if opts.direction == "vertical" then
      vim.cmd(fmt("let &winwidth=%d", opts.size))
    elseif opts.direction == "horizontal" then
      vim.cmd(fmt("let &winheight=%d", opts.size))
    end
  end

  local set_autocommands = function(bufnr)
    local opts = terms[bufnr]
    P(fmt("buffer name: %s", vim.api.nvim_buf_get_name(bufnr)))

    mega.augroup("MegatermResizer", {
      {
        event = { "WinLeave" },
        buffer = bufnr,
        command = function()
          P(fmt("winleave win/buf: %s/%s", opts.winnr, bufnr))
          set_window_size(bufnr)
        end,
      },
      {
        event = { "WinEnter" },
        buffer = bufnr,
        command = function(evt) P(fmt("winenter win/buf: %s/%s", opts.winnr, bufnr)) end,
      },
      {
        event = { "TermOpen" },
        pattern = { "term://*" },
        command = function(evt)
          P(fmt("termopen win/buf: %s/%s", opts.winnr, bufnr))
          if vim.bo[evt.buf].filetype == "" or vim.bo[evt.buf].filetype == "megaterm" then
            P(fmt("termopen megaterm win/buf: %s/%s", opts.winnr, bufnr))
          end
        end,
      },
      {
        event = { "BufEnter" },
        pattern = { "term://*" },
        command = function(evt)
          if vim.bo[evt.buf].filetype == "" or vim.bo[evt.buf].filetype == "megaterm" then
            P(fmt("bufenter megaterm win/buf: %s/%s", opts.winnr, bufnr))
          end
        end,
      },
    })
  end

  local function on_open(bufnr)
    local opts = terms[bufnr]

    vim.cmd([[do User MegaTermOpened]])

    set_term_opts(bufnr)
    set_window_size(bufnr)

    -- custom on_open
    if opts.on_open ~= nil and type(opts.on_open) == "function" then
      opts.on_open(bufnr)
    else
      -- default_on_open
      vim.api.nvim_command([[normal! G]])
      vim.api.nvim_buf_set_var(bufnr, "cmd", opts.cmd)
      vim.api.nvim_buf_set_var(bufnr, "direction", opts.direction)
      if opts.start_insert then vim.cmd("startinsert") end
      -- if opts.direction ~= "float" then vim.cmd([[wincmd p]]) end
    end

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

    add_term(winnr, bufnr, opts)
  end

  local function create_win(opts)
    local size = opts.size
    local new_cmd = opts.new
    local win_cmd = opts.wimc
    local dimension = opts.dimension

    -- vim.api.nvim_command(fmt([[%s | wincmd %s]], new_cmd, win_cmd))
    vim.api.nvim_command(fmt([[%s]], new_cmd))

    local winnr = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_get_current_buf()

    vim.api.nvim_command(fmt([[lua vim.api.nvim_win_set_%s(%s, %s)]], dimension, winnr, size))

    return winnr, bufnr
  end

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

  --- Creates a new terminal window as a split (horizontal or vertical), tab, or float,
  --- with custom hooks for various points of creation, command execution, and exiting.
  --- @param opts TermOpts
  function mega.term.new(opts)
    opts = vim.tbl_extend("force", default_opts, opts or {})
    opts = vim.tbl_extend("keep", split_opts[opts.direction], opts)

    local winnr, bufnr = create_win(opts)
    create_term(winnr, bufnr, opts)
    on_open(bufnr)

    vim.api.nvim_set_current_win(winnr)
    vim.api.nvim_set_current_buf(bufnr)
  end
end
