------@class FiletypeSettings
------@field g table<string, any>
------@field bo vim.bo
------@field wo vim.wo
------@field opt vim.Option
------@field plugins {[string]: fun(module: table)}
---
------@param args {[1]: string, [2]: string, [3]: string, [string]: boolean | integer}[]
------@param buf integer
---local function apply_ft_key_mappings(args, buf)
---  vim.iter(args):each(function(m)
---    assert(#m == 3, "map args must be a table with at least 3 items")
---    local opts = vim.iter(m):fold({ buffer = buf }, function(acc, key, item)
---      if type(key) == "string" then acc[key] = item end
---      return acc
---    end)
---    map(m[1], m[2], m[3], opts)
---  end)
---end
---
------ A convenience wrapper that calls the ftplugin config for a plugin if it exists
------ and warns me if the plugin is not installed
------@param configs table<string, fun(module: table)>
---local function ftplugin_conf(configs)
---  if type(configs) ~= "table" then return end
---  for name, callback in pairs(configs) do
---    local ok, plugin = mega.pcall(require, name)
---    if ok then callback(plugin) end
---  end
---end
---
------ This function is an alternative API to using ftplugin files. It allows defining
------ filetype settings in a single place, then creating FileType autocommands from this definition
------
------ e.g.
------ ```lua
------   as.filetype_settings({
------     lua = {
------      opt = {foldmethod = 'expr' },
------      bo = { shiftwidth = 2 }
------     },
------    [{'c', 'cpp'}] = {
------      bo = { shiftwidth = 2 }
------    }
------   })
------ ```
------
----- ---@param map {[string|string[]]: FiletypeSettings | {[integer]: fun(args: AutocmdArgs)}}
---local function ft_settings(map)
---  local commands = vim.iter(map):map(function(ft, settings)
---    local name = type(ft) == "table" and table.concat(ft, ",") or ft
---    return {
---      pattern = ft,
---      event = "FileType",
---      desc = ("ft settings for %s"):format(name),
---      command = function(args)
---        local bufnr = args.buf
---        vim.iter(settings):each(function(key, value)
---          if key == "opt" then key = "opt_local" end
---          if key == "bufvar" then
---            for k, v in pairs(value) do
---              vim.api.nvim_buf_set_var(bufnr, k, v)
---            end
---          end
---          if key == "mappings" or key == "keys" then return apply_ft_key_mappings(value, bufnr) end
---          if key == "compiler" then vim.api.nvim_buf_call(bufnr, function() vim.cmd.compiler({ args = { value } }) end) end
---          if key == "plugins" then return ftplugin_conf(value) end
---          if key == "callback" and type(value) == "function" then return mega.pcall(value, args) end
---          if key == "abbr" then
---            vim.api.nvim_buf_call(bufnr, function()
---              for k, v in pairs(value) do
---                -- vim.cmd(string.format("iabbrev <buffer> %s %s", k, v))
---                dbg(value)
---
---                vim.cmd.iabbrev(string.format("<buffer> %s %s", k, v))
---              end
---            end)
---          end
---          if type(key) == "function" then return mega.pcall(key, args) end
---
---          vim.iter(value):each(function(option, setting) vim[key][option] = setting end)
---        end)
---      end,
---    }
---  end)
---  require("mega.autocmds").augroup("mega-filetype-settings", unpack(commands:totable()))
---end

local ftplugin = require("mega.ftplugin")
ftplugin.extend_all({
  -- ft_settings({
  [{ "elixir", "eelixir" }] = {
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

      local has_clue, clue = pcall(require, "mini.clue")
      if has_clue then vim.b.miniclue_config = {
        clues = {
          { mode = "n", keys = "<localleader>e", desc = "+elixir" },
        },
      } end
    end,
  },
  heex = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[<%!-- %s --%>]],
    },
    callback = function(bufnr, args) vim.bo[bufnr].commentstring = [[<%!-- %s --%>]] end,
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
      cbt = "- [ ]",
      cb = "[ ]",
      cabag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cabdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cabjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cabam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
      cbag = [[Co-authored-by: Aaron Gunderson <aaron@ternit.com>]],
      cbdt = [[Co-authored-by: Dan Thiffault <dan@ternit.com>]],
      cbjm = [[Co-authored-by: Jia Mu <jia@ternit.com>]],
      cbam = [[Co-authored-by: Ali Marsh<ali@ternit.com>]],
      ["mtg:"] = [[## Meeting 󱛡 ->]],
      ["trn:"] = [[### Linear Ticket  ->]],
    },
    opt = {
      relativenumber = false,
      number = false,
      conceallevel = 2,
      shiftwidth = 2,
      tabstop = 2,
      softtabstop = 2,
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
    callback = function(bufnr)
      vim.keymap.set("n", "<leader>w", function()
        vim.schedule(function()
          pcall(vim.cmd.FormatNotes)
          vim.cmd.write({ bang = true })
        end)
      end, { buffer = bufnr })
      vim.keymap.set("n", "<C-x>", function()
        vim.schedule(function() pcall(vim.cmd.ToggleTask) end)
      end, { buffer = bufnr })
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
  sql = {
    opt = {
      tabstop = 2,
      shiftwidth = 2,
      commentstring = [[-- %s]],
    },
  },
})

ftplugin.setup()
