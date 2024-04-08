local ftplugin = mega.req("mega.utils.ftplugin")

ftplugin.extend_all({
  arduino = {
    keys = {
      { "<leader>ac", ":wa<CR>:ArduinoVerify<CR>" },
      { "<leader>au", ":wa<CR>:ArduinoUpload<CR>" },
      { "<leader>ad", ":wa<CR>:ArduinoUploadAndSerial<CR>" },
      { "<leader>ab", "<CMD>ArduinoChooseBoard<CR>" },
      { "<leader>ap", "<CMD>ArduinoChooseProgrammer<CR>" },
    },
  },
  -- cs = {
  --   opt = {
  --     foldlevel = 0,
  --     foldmethod = "syntax",
  --   },
  --   bufvar = {
  --     match_words = "\\s*#\\s*region.*$:\\s*#\\s*endregion",
  --     all_folded = 1,
  --   },
  -- },
  DressingInput = {
    keys = {
      { "<C-k>", "<CMD>lua require(\"dressing.input\").history_prev()<CR>", mode = "i" },
      { "<C-j>", "<CMD>lua require(\"dressing.input\").history_next()<CR>", mode = "i" },
    },
  },
  elixir = {
    callback = function()
      -- REF:
      -- running tests in iex:
      -- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar

      vim.cmd([[setlocal iskeyword+=!,?,-]])
      vim.cmd([[setlocal indentkeys-=0{]])
      vim.cmd([[setlocal indentkeys+=0=end]])

      mega.command("CopyModuleAlias", function()
        vim.api.nvim_feedkeys(
          -- Copy Module Alias to next window? [[mT?defmodule <cr>w"zyiW`T<c-w>poalias <c-r>z]]
          vim.api.nvim_replace_termcodes([[mT?defmodule <cr>w"zyiW`Tpoalias <c-r>z]], true, false, true),
          "n",
          true
        )
      end)

      -- nnoremap("<leader>ed", [[orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>]])
      nnoremap("<localleader>ep", [[o|><ESC>a]], { desc = "ex: pipe (new line)" })
      nnoremap("<localleader>ed", [[o|> dbg()<ESC>a]], { desc = "ex: dbg (new line)" })
      nnoremap("<localleader>ei", [[o|> IO.inspect()<ESC>i]], { desc = "ex: inspect (new line)" })
      nnoremap("<localleader>eil", [[o|> IO.inspect(label: "")<ESC>hi]], { desc = "ex: inspect label (new line)" })
      nnoremap("<localleader>em", "<cmd>CopyModuleAlias<cr>", { desc = "ex: copy module alias" })

      local has_wk, wk = pcall(require, "which-key")
      if has_wk then wk.register({
        ["<localleader>e"] = { name = "+elixir" },
      }) end

      vim.cmd.iabbrev([[ep      |>]])
      vim.cmd.iabbrev([[epry    require IEx; IEx.pry]])
      vim.cmd.iabbrev([[ei      IO.inspect()<ESC>i]])
      vim.cmd.iabbrev([[eputs   IO.puts()<ESC>i]])
      vim.cmd.iabbrev([[edb      dbg()<ESC>i]])
      vim.cmd.iabbrev([[~H      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
      vim.cmd.iabbrev([[~h      ~H""""""<ESC>2hi<CR><ESC>O<BS> ]])
      vim.cmd.iabbrev([[:skip:  @tag :skip]])
      vim.cmd.iabbrev([[tskip   @tag :skip]])

      -- nnoremap("<localleader>eok", [[o|> IO.inspect(label: "")<ESC>hi]])
      -- nnoremap("<localleader>eer", [[o|> IO.inspect(label: "")<ESC>hi]])
      vim.cmd([[
" Wrap word in {:ok, word} tuple
nmap <silent> <localleader>ok :lua require("mega.utils").wrap_cursor_node("{:ok, ", "}")<CR>
xmap <silent> <localleader>ok :lua require("mega.utils").wrap_selected_nodes("{:ok, ", "}")<CR>


" Wrap word in {:error, word} tuple
nmap <silent> <localleader>er :lua require("mega.utils").wrap_cursor_node("{:error, ", "}")<CR>
xmap <silent> <localleader>er :lua require("mega.utils").wrap_selected_nodes("{:error, ", "}")<CR>
]])

      local function desk_cmd()
        local deskfile_cmd = ""
        local deskfile_path = require("mega.utils").root_has_file("Deskfile")
        if deskfile_path then deskfile_cmd = "eval $(desk load); " end
        return deskfile_cmd
      end

      -- REF:
      -- https://github.com/mhanberg/elixir.nvim/tree/main/lua/elixir/mix
      local function root_dir(fname)
        local lsputil = require("lspconfig.util")
        local uv = vim.uv

        if not fname or fname == "" then fname = vim.fn.getcwd() end

        local path = lsputil.path
        local child_or_root_path = lsputil.root_pattern({ "mix.exs", ".git" })(fname)
        local maybe_umbrella_path =
          lsputil.root_pattern({ "mix.exs" })(uv.fs_realpath(path.join({ child_or_root_path, ".." })))

        local has_ancestral_mix_exs_path =
          vim.startswith(child_or_root_path, path.join({ maybe_umbrella_path, "apps" }))
        if maybe_umbrella_path and not has_ancestral_mix_exs_path then maybe_umbrella_path = nil end

        path = maybe_umbrella_path or child_or_root_path or uv.os_homedir()

        return path
      end

      local mix_exs_path_cache = nil

      local function refresh_completions()
        local cmd = desk_cmd() .. "mix help | awk -F ' ' '{printf \"%s\\n\", $2}' | grep -E \"[^-#]\\w+\""

        vim.g.mix_complete_list = vim.fn.system(cmd)

        vim.notify("commands refreshed", vim.log.levels.INFO, { title = "elixir mix" })
      end

      local function load_completions(cli_input)
        local l = #(vim.split(cli_input, " "))

        -- Don't print if command already selected
        if l > 2 then return "" end

        -- Use cache if list has been already loaded
        if vim.g.mix_complete_list then return vim.g.mix_complete_list end

        refresh_completions()

        return vim.g.mix_complete_list
      end

      local function run_mix(action, args)
        local args_as_str = table.concat(args, " ")

        local cd_cmd = ""
        local mix_exs_path = root_dir(vim.fn.expand("%:p"))

        if mix_exs_path then cd_cmd = table.concat({ "cd", mix_exs_path, "&&" }, " ") end

        local cmd = { cd_cmd, desk_cmd(), "mix", action, args_as_str }

        return vim.fn.system(table.concat(cmd, " "))
      end

      function __Elixir_Mix_complete(_, line, _) return load_completions(line) end

      local function build_and_run_mix_cmd(opts)
        local action = opts.cmd
        local args = opts.args

        local result = run_mix(action, args)
        print(result)
      end

      local function load_cmd(start_line, end_line, count, cmd, ...)
        local args = { ... }

        if not cmd then return end

        local user_opts = {
          start_line = start_line,
          end_line = end_line,
          count = count,
          cmd = cmd,
          args = args,
        }

        build_and_run_mix_cmd(user_opts)
      end

      local function setup_mix()
        for _, cmd in pairs({ "M", "Mix" }) do
          mega.command(
            cmd,
            function(opts) load_cmd(opts.line1, opts.line2, opts.count, unpack(opts.fargs)) end,
            { range = true, nargs = "*", complete = "custom,v:lua.__Elixir_Mix_complete" }
          )
        end
      end

      setup_mix()

      -- local function is_elixir_test_file()
      --   local file_name = vim.fn.expand("%:t")
      --   local is_test_file = type(file_name:match("_test%.exs$")) == "string" and file_name:match("_test%.exs$") ~= nil
      --   return is_test_file
      -- end
      --
      -- local function set_iex_strategy_after_delay()
      --   vim.defer_fn(function()
      --     local ok, neotest = pcall(require, "neotest")
      --     if ok then
      --       local cwd = vim.loop.cwd()
      --       neotest.setup_project(cwd, {
      --         adapters = { require("neotest-elixir") },
      --         default_strategy = "iex",
      --       })
      --     end
      --   end, 100)
      -- end

      -- if is_elixir_test_file() then set_iex_strategy_after_delay() end
    end,
  },
  heex = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[<%!-- %s --%>]],
    },
  },
  gitconfig = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[# %s]],
    },
  },
  gitcommit = {
    keys = {
      { "q", vim.cmd.cquit, { nowait = true, buffer = true, desc = "abort", bang = true } },
    },
    opt = {
      list = false,
      number = false,
      relativenumber = false,
      cursorline = false,
      spell = true,
      spelllang = "en_gb",
      colorcolumn = "50,72",
    },
    callback = function()
      vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })
      if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd.startinsert() end
    end,
  },
  gitrebase = {
    function() vim.keymap.set("n", "q", vim.cmd.cquit, { nowait = true, desc = "abort" }) end,
  },
  neogitcommitmessage = {
    keys = {
      { "q", vim.cmd.cquit, { nowait = true, buffer = true, desc = "abort", bang = true } },
    },
    opt = {
      list = false,
      number = false,
      relativenumber = false,
      cursorline = false,
      spell = true,
      spelllang = "en_gb",
      colorcolumn = "50,72",
    },
    callback = function()
      vim.keymap.set("n", "q", vim.cmd.cquit, { buffer = true, nowait = true, desc = "Abort" })
      vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })
      if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd.startinsert() end
    end,
  },
  fugitiveblame = {
    keys = {
      { "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  go = {
    compiler = "go",
    opt = {
      list = false,
      listchars = "nbsp:⦸,extends:»,precedes:«,tab:  ",
    },
  },
  help = {
    keys = {
      { "gd", "<C-]>" },
    },
    opt = {
      signcolumn = "no",
      splitbelow = true,
      number = true,
      relativenumber = true,
      list = false,
      textwidth = 80,
    },
    callback = function() mega.pcall(vim.treesitter.start) end,
  },
  man = {
    keys = {
      { "gd", "<C-]>" },
    },
    opt = {
      signcolumn = "no",
      splitbelow = true,
      number = true,
      relativenumber = true,
      list = false,
      textwidth = 80,
    },
  },
  oil = {
    keys = {},
    opt = {
      conceallevel = 3,
      concealcursor = "n",
      list = false,
      wrap = false,
      signcolumn = "no",
    },
    callback = function()
      nnoremap("q", "<cmd>q<cr>", { desc = "oil: quit", buffer = 0 })
      nnoremap("<leader>ed", "<cmd>q<cr>", { desc = "oil: quit", buffer = 0 })
      nnoremap("<BS>", function() require("oil").open() end, { desc = "oil: goto parent dir", buffer = 0 })

      nnoremap("<localleader>ff", function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
        mega.find_files({ cwd = dir, hidden = true })
      end, "oil: find files in dir")
      nnoremap("<localleader>a", function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
        mega.grep({ cwd = dir })
      end, "oil: grep files in dir")
    end,
  },
  lua = {
    abbr = {
      ["!="] = "~=",
      locla = "local",
      vll = "vim.log.levels",
    },
    keys = {
      { "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
    },
    opt = {
      comments = ":---,:--",
    },
  },
  make = {
    opt = {
      expandtab = false,
    },
  },
  markdown = {
    opt = {
      conceallevel = 2,
      shiftwidth = 2,
      tabstop = 2,
      softtabstop = 2,
      formatoptions = "jqlnr",
      comments = "sb:- [x],mb:- [ ],b:-,b:*,b:>",
      linebreak = true,
      wrap = true,
      suffixesadd = ".md",
      spell = true,
    },
    keys = {
      -- { "<leader>td", require("markdown").task_mark_done },
      -- { "<leader>tu", require("markdown").task_mark_undone },
    },
    callback = function(bufnr)
      -- require("markdown").update_code_highlights(bufnr)
      local aug = vim.api.nvim_create_augroup("MarkdownStyling", {})
      vim.api.nvim_clear_autocmds({ buffer = bufnr, group = aug })
      -- vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
      --   buffer = bufnr,
      --   callback = vim.schedule_wrap(function(args) require("markdown").update_code_highlights(bufnr) end),
      -- })
    end,
  },
  ["neotest-summary"] = {
    opt = {
      wrap = false,
    },
  },
  norg = {
    opt = {
      comments = "n:-,n:( )",
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
      linebreak = true,
      wrap = true,
    },
  },
  python = {
    abbr = {
      inn = "is not None",
      ipmort = "import",
      improt = "import",
    },
    opt = {
      shiftwidth = 4,
      tabstop = 4,
      softtabstop = 4,
      textwidth = 88,
    },
    callback = function(bufnr)
      if vim.fn.executable("autoimport") == 1 then
        vim.keymap.set("n", "<leader>o", function()
          vim.cmd.write()
          vim.cmd("silent !autoimport " .. vim.api.nvim_buf_get_name(0))
          vim.cmd.edit()
          vim.lsp.buf.formatting({})
        end, { buffer = bufnr })
      end
      -- vim.keymap.set(
      --   "n",
      --   "<leader>e",
      --   function() run_file({ "python", vim.api.nvim_buf_get_name(0) }) end,
      --   { buffer = bufnr }
      -- )
    end,
  },
  qf = {
    opt = {
      winfixheight = true,
      relativenumber = false,
      buflisted = false,
    },
    callback = function()
      vim.cmd([[
  " Autosize quickfix to match its minimum content
  " https://vim.fandom.com/wiki/Automatically_fitting_a_quickfix_window_height
  function! s:adjust_height(minheight, maxheight)
    exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
  endfunction

  " force quickfix to open beneath all other splits
  wincmd J

  setlocal nonumber
  setlocal norelativenumber
  setlocal nowrap
  setlocal signcolumn=yes
  setlocal colorcolumn=
  setlocal nobuflisted " quickfix buffers should not pop up when doing :bn or :bp
  call s:adjust_height(3, 10)
  setlocal winfixheight

  " REF: https://github.com/romainl/vim-qf/blob/2e385e6d157314cb7d0385f8da0e1594a06873c5/autoload/qf.vim#L22
]])

      nnoremap("<C-n>", function()
        pcall(function()
          vim.cmd.lne({
            count = vim.v.count1,
          })
        end)
      end, { buffer = 0, label = "QF: next" })
      nnoremap("<C-p>", function()
        pcall(function()
          vim.cmd.lp({
            count = vim.v.count1,
          })
        end)
      end, { buffer = 0, label = "QF: previous" })
      vim.keymap.set(
        { "n", "x" },
        "<CR>",
        function()
          vim.cmd.ll({
            count = vim.api.nvim_win_get_cursor(0)[1],
          })
        end,
        {
          buffer = true,
        }
      )

      local ok_bqf, bqf = pcall(require, "bqf")
      if not ok_bqf then return end

      local fugitive_pv_timer
      local preview_fugitive = function(bufnr, qwinid, bufname)
        local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
        if fugitive_pv_timer and fugitive_pv_timer:get_due_in() > 0 then
          fugitive_pv_timer:stop()
          fugitive_pv_timer = nil
        end
        fugitive_pv_timer = vim.defer_fn(function()
          if not is_loaded then
            vim.api.nvim_buf_call(bufnr, function() vim.cmd(("do fugitive BufReadCmd %s"):format(bufname)) end)
          end
          require("bqf.preview.handler").open(qwinid, nil, true)
          vim.api.nvim_buf_set_option(require("bqf.preview.session").float_bufnr(), "filetype", "git")
        end, is_loaded and 0 or 60)
        return true
      end

      bqf.setup({
        auto_enable = true,
        auto_resize_height = true,
        preview = {
          auto_preview = true,
          win_height = 15,
          win_vheight = 15,
          delay_syntax = 80,
          border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
          ---@diagnostic disable-next-line: unused-local
          should_preview_cb = function(bufnr, qwinid)
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            local fsize = vim.fn.getfsize(bufname)
            if fsize > 100 * 1024 then
              -- skip file size greater than 100k
              return false
            elseif bufname:match("^fugitive://") then
              return preview_fugitive(bufnr, qwinid, bufname)
            end

            return true
          end,
        },
        filter = {
          fzf = {
            extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
          },
        },
      })

      -- save & quit via "q"
      mega.augroup("ReplacerFileType", {
        pattern = "replacer",
        callback = function()
          mega.nmap("q", vim.cmd.write, { desc = " done replacing", buffer = true, nowait = true })
        end,
      })

      -- mega.nnoremap("<leader>r", function() require("replacer").run() end, { desc = "qf: replace in qflist", nowait = true })
    end,
  },
  -- rust = {
  --   compiler = "cargo",
  --   callback = function(bufnr)
  --     -- vim.keymap.set("n", "<leader>e", function() run_file({ "cargo", "run" }) end, { buffer = bufnr })
  --   end,
  -- },
  sh = {
    callback = function(bufnr)
      -- vim.keymap.set(
      --   "n",
      --   "<leader>e",
      --   function() run_file({ "bash", vim.api.nvim_buf_get_name(0) }) end,
      --   { buffer = bufnr }
      -- )
    end,
  },
  -- supercollider = {
  --   keys = {
  --     { "<CR>", "<Plug>(scnvim-send-block)" },
  --     { "<c-CR>", "<Plug>(scnvim-send-block)", mode = "i" },
  --     { "<CR>", "<Plug>(scnvim-send-selection)", mode = "x" },
  --     { "<F1>", "<cmd>call scnvim#install()<CR><cmd>SCNvimStart<CR><cmd>SCNvimStatusLine<CR>" },
  --     { "<F2>", "<cmd>SCNvimStop<CR>" },
  --     { "<F12>", "<Plug>(scnvim-hard-stop)" },
  --     { "<leader><space>", "<Plug>(scnvim-postwindow-toggle)" },
  --     { "<leader>g", "<cmd>call scnvim#sclang#send('s.plotTree;')<CR>" },
  --     { "<leader>s", "<cmd>call scnvim#sclang#send('s.scope;')<CR>" },
  --     { "<leader>f", "<cmd>call scnvim#sclang#send('FreqScope.new;')<CR>" },
  --     { "<leader>r", "<cmd>SCNvimRecompile<CR>" },
  --     { "<leader>m", "<cmd>call scnvim#sclang#send('Master.gui;')<CR>" },
  --   },
  --   opt = {
  --     foldmethod = "marker",
  --     foldmarker = "{{{,}}}",
  --     statusline = "%f %h%w%m%r %{scnvim#statusline#server_status()} %= %(%l,%c%V %= %P%)",
  --   },
  --   callback = function(bufnr)
  --     vim.api.nvim_create_autocmd("WinEnter", {
  --       pattern = "*",
  --       command = "if winnr('$') == 1 && getbufvar(winbufnr(winnr()), '&filetype') == 'scnvim'|q|endif",
  --       group = "ClosePostWindowIfLast",
  --     })
  --   end,
  -- },
  typescript = {
    compiler = "tsc",
  },
  vim = {
    opt = {
      foldmethod = "marker",
      keywordprg = ":help",
    },
  },
  -- zig = {
  --   compiler = "zig_test",
  --   opt = {
  --     shiftwidth = 4,
  --     tabstop = 4,
  --     softtabstop = 4,
  --   },
  -- },
})

ftplugin.setup()
