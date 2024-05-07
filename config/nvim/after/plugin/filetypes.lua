local ftplugin = require("mega.ftplugin")

ftplugin.extend_all({
  elixir = {
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
    callback = function()
      -- REF:
      -- running tests in iex:
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

      nmap("<localleader>ok", [[:lua require("mega.utils").wrap_cursor_node("{:ok, ", "}")<CR>]], "copy module alias")
      xmap("<localleader>ok", [[:lua require("mega.utils").wrap_selected_nodes("{:ok, ", "}")<CR>]], "copy module alias")
      nmap("<localleader>err", [[:lua require("mega.utils").wrap_cursor_node("{:error, ", "}")<CR>]], "copy module alias")
      xmap("<localleader>err", [[:lua require("mega.utils").wrap_selected_nodes("{:error, ", "}")<CR>]], "copy module alias")

      local has_wk, wk = pcall(require, "which-key")
      if has_wk then wk.register({
        ["<localleader>e"] = { name = "+elixir" },
      }) end
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
      map("n", "q", vim.cmd.cquit, { buffer = true, nowait = true, desc = "Abort" })
      vim.fn.matchaddpos("DiagnosticVirtualTextError", { { 1, 50, 10000 } })
      if vim.fn.prevnonblank(".") ~= vim.fn.line(".") then vim.cmd.startinsert() end
    end,
  },
  fugitiveblame = {
    keys = {
      { "gp", "<CMD>echo system('git findpr ' . expand('<cword>'))<CR>" },
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
    callback = function() pcall(vim.treesitter.start) end,
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
      ["!="] = [[~=]],
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
    abbr = {
      -- ["-cc"] = "- [ ]",
      cb = "[ ]",
      cabag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cabdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cabjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cabam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
      cbag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cbdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cbjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cbam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
    },
    opt = {
      conceallevel = 2,
      shiftwidth = 2,
      tabstop = 2,
      softtabstop = 2,
      -- formatoptions = "jqlnr",
      -- comments = "sb:- [x],mb:- [ ],b:-,b:*,b:>",
      linebreak = true,
      wrap = true,
      suffixesadd = ".md",
      spell = true,
    },
    -- keys = {
    --   -- { "<leader>td", require("markdown").task_mark_done },
    --   -- { "<leader>tu", require("markdown").task_mark_undone },
    -- },
    -- callback = function(bufnr)
    --   -- Allow bullets.vim and nvim-autopairs to coexist.
    --   -- REF: https://github.com/ribru17/.dotfiles/blob/0f09207e5587b5217d631cb09885957906eaaa7a/.config/nvim/after/ftplugin/markdown.lua#L7-L19
    --   -- vim.schedule(function()
    --   -- vim.keymap.set("i", "<CR>", function()
    --   --   -- local pair = require("nvim-autopairs").completion_confirm()
    --   --   -- if pair == vim.api.nvim_replace_termcodes("<CR>", true, false, true) then
    --   --   vim.cmd.InsertNewBullet()
    --   --   -- else
    --   --   --   vim.api.nvim_feedkeys(pair, "n", false)
    --   --   -- end
    --   -- end, {
    --   --   buffer = bufnr,
    --   -- })
    --   -- end)
    --   -- require("markdown").update_code_highlights(bufnr)
    --   -- local aug = vim.api.nvim_create_augroup("MarkdownStyling", {})
    --   -- vim.api.nvim_clear_autocmds({ buffer = bufnr, group = aug })
    --   -- vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    --   --   buffer = bufnr,
    --   --   callback = vim.schedule_wrap(function(args) require("markdown").update_code_highlights(bufnr) end),
    --   -- })
    -- end,
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
    end,
  },
})

ftplugin.setup()
