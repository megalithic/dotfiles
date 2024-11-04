local ftplugin = require("mega.ftplugin")
ftplugin.extend_all({
  [{ "elixir", "eelixir" }] = {
    opt = {
      syntax = "OFF",
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[# %s]],
    },
    abbr = {
      ep = "|>",
      epry = [[require IEx; IEx.pry]],
      ei = [[IO.inspect()<ESC>hi]],
      eputs = [[IO.puts()<ESC>hi]],
      edb = [[dbg()<ESC>hi]],
      ["~H"] = [[~H""""""<ESC>2hi<CR><ESC>O<BS> ]],
      ["~h"] = [[~H""""""<ESC>2hi<CR><ESC>O<BS> ]],
      [":skip:"] = "@tag :skip",
      tskip = "@tag :skip",
    },
    -- opt = {
    --   iskeyword = vim.opt.iskeyword + { "!", "?", "-" },
    --   indentkeys = vim.opt.indentkeys + { "end" },
    -- },
    callback = function(bufnr, args)
      -- REF:
      -- running tests in iex:
      -- https://www.elixirstreams.com/tips/test-breakpoints
      -- https://curiosum.com/til/run-tests-in-elixir-iex-shell?utm_medium=email&utm_source=elixir-radar
      vim.cmd([[setlocal iskeyword+=!,?,-]])
      vim.cmd([[setlocal indentkeys-=0{]])
      vim.cmd([[setlocal indentkeys+=0=end]])

      -- mega.command("CopyModuleAlias", function()
      --   vim.api.nvim_feedkeys(
      --     -- Copy Module Alias to next window? [[mT?defmodule <cr>w"zyiW`T<c-w>poalias <c-r>z]]
      --     vim.api.nvim_replace_termcodes([[mT?defmodule <cr>w"zyiW`Tpoalias <c-r>z]], true, false, true),
      --     "n",
      --     true
      --   )
      -- end)

      local nmap = function(lhs, rhs, desc) vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = "ex: " .. desc }) end
      local xmap = function(lhs, rhs, desc) vim.keymap.set("x", lhs, rhs, { buffer = 0, desc = "ex: " .. desc }) end
      -- nnoremap("<leader>ed", [[orequire IEx; IEx.pry; #respawn() to leave pry<ESC>:w<CR>]])
      nmap("<localleader>ep", [[o|><ESC>a]], "pipe (new line)")
      nmap("<localleader>ed", [[o|> dbg()<ESC>a]], "dbg (new line)")
      nmap("<localleader>ei", [[o|> IO.inspect()<ESC>i]], "inspect (new line)")
      nmap("<localleader>eil", [[o|> IO.inspect(label: "")<ESC>hi]], "inspect label (new line)")
      nmap("<localleader>em", "<cmd>CopyModuleAlias<cr>", "copy module alias")
      nmap("<localleader>eF", function()
        vim.cmd("silent !mix format")
        vim.cmd("edit")
      end, "format")

      nmap("<localleader>ok", [[:lua require("mega.utils").wrap_cursor_node("{:ok, ", "}")<CR>]], "copy module alias")
      xmap("<localleader>ok", [[:lua require("mega.utils").wrap_selected_nodes("{:ok, ", "}")<CR>]], "copy module alias")
      nmap("<localleader>err", [[:lua require("mega.utils").wrap_cursor_node("{:error, ", "}")<CR>]], "copy module alias")
      xmap("<localleader>err", [[:lua require("mega.utils").wrap_selected_nodes("{:error, ", "}")<CR>]], "copy module alias")

      if vim.g.tester == "vim-test" then
        nmap("<localleader>td", function()
          local function elixir_dbg_transform(cmd)
            -- local modified_cmd = cmd:gsub("^mix%s*", "")
            -- local returned_cmd = "MIX_ENV=test iex --dbg pry -S mix do " .. modified_cmd .. " --trace + run -e 'System.halt'"
            local returned_cmd = string.format("iex -S %s -b", cmd)

            return returned_cmd
          end
          vim.g["test#custom_transformations"] = { elixir = elixir_dbg_transform }
          vim.g["test#transformation"] = "elixir"
          vim.cmd("TestNearest")
        end, "[d]ebug [n]earest test")
      end

      local has_wk, wk = pcall(require, "which-key")
      if has_wk then wk.add({
        ["<localleader>e"] = { group = "[e]lixir" },
      }) end

      if pcall(require, "mini.clue") then
        vim.b.miniclue_config = {
          clues = {
            { mode = "n", keys = "<localleader>e", desc = "+elixir" },
          },
        }
      end
    end,
  },
  heex = {
    opt = {
      syntax = "OFF",
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[<%!-- %s --%>]],
    },
    callback = function(bufnr, args) vim.bo[bufnr].commentstring = [[<%!-- %s --%>]] end,
  },
  ghostty = {
    opt = {
      commentstring = [[# %s]],
    },
  },
  nix = {
    opt = {
      commentstring = "# %s",
      -- nil_ls = {},
    },
  },
  terminal = {
    opt = {
      relativenumber = false,
      number = false,
      signcolumn = "yes:1",
    },
  },
  gitconfig = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[# %s]],
    },
  },
  gitrebase = {
    callback = function(bufnr, args)
      vim.keymap.set("n", "q", function() vim.cmd("cq!", { bang = true }) end, { buffer = bufnr, nowait = true, desc = "abort" })
    end,
  },
  [{ "gitcommit", "NeogitCommitMessage" }] = {
    -- keys = {
    --   { "n", "q", function() vim.cmd("cq!") end, { nowait = true, buffer = true, desc = "abort", bang = true } },
    -- },
    bo = { bufhidden = "delete" },
    opt = {
      list = false,
      number = false,
      relativenumber = false,
      cursorline = false,
      spell = true,
      spelllang = "en_gb",
      colorcolumn = "50,72",
      conceallevel = 2,
      concealcursor = "nc",
    },
    callback = function()
      vim.keymap.set("n", "q", function() vim.cmd("cq!", { bang = true }) end, { buffer = true, nowait = true, desc = "Abort" })
      vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })
      if vim.fn.prevnonblank(0) ~= vim.fn.line(".") then vim.cmd.startinsert() end
    end,
  },
  fugitiveblame = {
    keys = {
      { "n", "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
    },
  },
  help = {
    keys = {
      { "n", "gd", "<C-]>" },
    },
    opt = {
      signcolumn = "no",
      splitbelow = true,
      number = true,
      relativenumber = true,
      list = false,
      textwidth = 80,
    },
    cmp = {
      sources = {
        { name = "git" },
        { name = "buffer" },
      },
    },
  },
  prompt = {
    opt = {
      signcolumn = "no",
      number = false,
      relativenumber = false,
      list = false,
    },
    callback = function(ctx)
      vim.pprint(ctx)
      print(vim.bo.buftype)
      print(vim.bo.filetype)
    end,
  },
  man = {
    keys = {
      { "n", "gd", "<C-]>" },
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
      local map = function(keys, func, desc) vim.keymap.set("n", keys, func, { buffer = 0, desc = "oil: " .. desc }) end

      map("q", "<cmd>q<cr>", "quit")
      map("<leader>ed", "<cmd>q<cr>", "quit")
      map("<BS>", function() require("oil").open() end, "goto parent dir")

      map("<localleader>ff", function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
        mega.picker.find_files({ cwd = dir, hidden = true })
      end, "find files in dir")
      map("<localleader>a", function()
        local oil = require("oil")
        local dir = oil.get_current_dir()
        if vim.api.nvim_win_get_config(0).relative ~= "" then vim.api.nvim_win_close(0, true) end
        mega.picker.grep({ cwd = dir })
      end, "grep files in dir")
    end,
  },
  lua = {
    abbr = {
      locla = "local",
      vll = "vim.log.levels",
    },
    keys = {
      { "n", "gh", "<CMD>exec 'help ' . expand('<cword>')<CR>" },
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
    abbr = {
      cabag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cabdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cabjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cabam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
      cbag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cbdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cbjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cbam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
      cbt = "- [ ]",
      cb = "[ ]",
    },
    opt = {
      relativenumber = false,
      number = false,
      conceallevel = 2,
      shiftwidth = 2,
      tabstop = 2,
      softtabstop = 2,
      syntax = "OFF",
      -- formatoptions = "jqlnr",
      -- comments = "sb:- [x],mb:- [ ],b:-,b:*,b:>",
      linebreak = true,
      wrap = true,
      textwidth = 0,
      wrapmargin = 0,
      suffixesadd = ".md",
      spell = true,
      -- vim.o.textwidth = 0
      -- vim.o.wrapmargin = 0
      -- -- visual wrap (no real line cutting is made)
      -- vim.o.wrap = true
      -- vim.o.linebreak = true
    },
    cmp = {
      sources = {
        {
          name = "nvim_lsp",
          markdown_oxide = {
            keyword_pattern = [[\(\k\| \|\/\|#\|\^\)\+]],
          },
        },
        { name = "snippets" },
        { name = "git" },
        { name = "path" },
        { name = "spell" },
      },
    },
    callback = function(bufnr)
      local map = vim.keymap.set

      -- vim.schedule(function()
      --   map("i", "<CR>", function()
      --     local pair = require("nvim-autopairs").completion_confirm()
      --     if vim.bo.ft == "markdown" and pair == vim.api.nvim_replace_termcodes("<CR>", true, false, true) then
      --       vim.cmd.InsertNewBullet()
      --     else
      --       vim.api.nvim_feedkeys(pair, "n", false)
      --     end
      --   end, {
      --     buffer = bufnr,
      --   })
      -- end)

      ---sets `buffer`, `silent` and `nowait` to true
      ---@param mode string|string[]
      ---@param lhs string
      ---@param rhs string|function
      ---@param opts? { desc: string, remap: boolean }
      local function bmap(mode, lhs, rhs, opts)
        opts = vim.tbl_extend("force", { buffer = bufnr, silent = true, nowait = true }, opts or {})
        map(mode, lhs, rhs, opts)
      end

      if pcall(require, "mini.clue") then
        vim.b.miniclue_config = {
          clues = {
            { mode = "n", keys = "<localleader>m", desc = "+markdown" },
            { mode = "n", keys = "<C-g>", desc = "+markdown" },
            { mode = "i", keys = "<C-g>", desc = "+markdown" },
            { mode = "x", keys = "<C-g>", desc = "+markdown" },
          },
        }
      end

      bmap("v", "<localleader>mll", function()
        -- Copy what's currently in my clipboard to the register "a lamw25wmal
        vim.cmd("let @a = getreg('+')")
        -- delete selected text
        vim.cmd("normal d")
        -- Insert the following in insert mode
        vim.cmd("startinsert")
        vim.api.nvim_put({ "[]() " }, "c", true, true)
        -- Move to the left, paste, and then move to the right
        vim.cmd("normal F[pf(")
        -- Copy what's on the "a register back to the clipboard
        vim.cmd("call setreg('+', @a)")
        -- Paste what's on the clipboard
        vim.cmd("normal p")
        -- Leave me in normal mode or command mode
        vim.cmd("stopinsert")
        -- Leave me in insert mode to start typing
        -- vim.cmd("startinsert")
      end, { desc = "[P]Convert to link" })

      -- ctrl+g/ctrl+l: markdown link
      bmap("n", "<C-g><C-l>", "bi[<Esc>ea]()<Esc>hp", { desc = "[markdown]  link" })
      bmap("x", "<C-g><C-l>", "<Esc>`<i[<Esc>`>la]()<Esc>hp", { desc = "[markdown]  link" })
      bmap("i", "<C-g><C-l>", "[]()<Left><Left><Left>", { desc = "[markdown]  link" })

      -- ctrl+g/ctrl+b: bold
      bmap("n", "<C-g><C-b>", "bi**<Esc>ea**<Esc>", { desc = "[markdown]  bold" })
      bmap("i", "<C-g><C-b>", "****<Left><Left>", { desc = "[markdown]  bold" })
      bmap("x", "<C-g><C-b>", "<Esc>`<i**<Esc>`>lla**<Esc>", { desc = "[markdown]  bold" })

      -- ctrl+g/ctrl+i: italics
      bmap("n", "<C-g><C-i>", "bi*<Esc>ea*<Esc>", { desc = "[markdown]  italics" })
      bmap("i", "<C-g><C-i>", "**<Left>", { desc = "[markdown]  italics" })
      bmap("x", "<C-g><C-i>", "<Esc>`<i*<Esc>`>la*<Esc>", { desc = "[markdown]  italics" })

      -- ctrl+g ctrl+s: strike-through
      bmap("n", "<C-g><C-s>", "bi~~<Esc>ea~~<Esc>", { desc = "[markdown] 󰊁 strikethrough" })
      bmap("i", "<C-g><C-s>", "~~~~<Left><Left>", { desc = "[markdown] 󰊁 strikethrough" })
      bmap("x", "<C-g><C-s>", "<Esc>`<i~~<Esc>`>la~~<Esc>", { desc = "[markdown] 󰊁 strikethrough" })
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
  org = {
    opt = {
      comments = "n:-,n:( )",
      conceallevel = 2,
      indentkeys = "o,O,*<M-o>,*<M-O>,*<CR>",
      linebreak = true,
      wrap = true,
    },
  },
  qf = {
    opt = {
      winfixheight = true,
      winfixwidth = true,
      relativenumber = false,
      number = false,
      buflisted = false,
      wrap = false,
    },
    callback = function()
      vim.cmd("wincmd J")
      vim.cmd([[
        " Autosize quickfix to match its minimum content
        " https://vim.fandom.com/wiki/Automatically_fitting_a_quickfix_window_height
        function! s:adjust_height(minheight, maxheight)
          exe max([min([line("$"), a:maxheight]), a:minheight]) . "wincmd _"
        endfunction

        " force quickfix to open beneath all other splits
        call s:adjust_height(3, 10)

        " REF: https://github.com/romainl/vim-qf/blob/2e385e6d157314cb7d0385f8da0e1594a06873c5/autoload/qf.vim#L22
      ]])

      -- nnoremap("<C-n>", function()
      --   pcall(function()
      --     vim.cmd.lne({
      --       count = vim.v.count1,
      --     })
      --   end)
      -- end, { buffer = 0, label = "QF: next" })
      -- nnoremap("<C-p>", function()
      --   pcall(function()
      --     vim.cmd.lp({
      --       count = vim.v.count1,
      --     })
      --   end)
      -- end, { buffer = 0, label = "QF: previous" })
      -- vim.keymap.set(
      --   { "n", "x" },
      --   "<CR>",
      --   function()
      --     vim.cmd.ll({
      --       count = vim.api.nvim_win_get_cursor(0)[1],
      --     })
      --   end,
      --   {
      --     buffer = true,
      --   }
      -- )

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
          if not is_loaded then vim.api.nvim_buf_call(bufnr, function() vim.cmd(("do fugitive BufReadCmd %s"):format(bufname)) end) end
          require("bqf.preview.handler").open(qwinid, nil, true)
          vim.api.nvim_set_option_value("filetype", "git", { buf = require("bqf.preview.session").float_bufnr(), win = qwinid })
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
    end,
  },
  query = {
    callback = function(bufnr)
      if vim.bo[bufnr].buftype == "nofile" then return end
      vim.lsp.start({
        name = "ts_query_ls",
        cmd = {
          vim.fs.joinpath(vim.env.HOME, "Documents/CodeProjects/ts_query_ls/target/release/ts_query_ls"),
        },
        root_dir = vim.fs.root(0, { "queries" }),
        settings = {
          parser_install_directories = {
            -- If using nvim-treesitter with lazy.nvim
            vim.fs.joinpath(vim.fn.stdpath("data"), "/lazy/nvim-treesitter/parser/"),
          },
          parser_aliases = {
            ecma = "javascript",
          },
          language_retrieval_patterns = {
            "languages/src/([^/]+)/[^/]+\\.scm$",
          },
        },
      })
    end,
  },
  sql = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[-- %s]],
    },
    cmp = {
      sources = {
        { name = "vim-dadbod-completion" },
        { name = "buffer" },
      },
    },
  },
})

ftplugin.setup()
