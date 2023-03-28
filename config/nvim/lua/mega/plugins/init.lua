return {
  -- ( CORE ) ------------------------------------------------------------------
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },
  {
    "ethanholz/nvim-lastplace",
    lazy = false,
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit", "terminal", "megaterm" },
        lastplace_open_folds = true,
      })
    end,
  },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "mcchrish/zenbones.nvim",
    lazy = false,
    priority = 999,
    dependencies = "rktjmp/lush.nvim",
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!dirbuf" },
        buftype = { "*", "!prompt", "!nofile", "!dirbuf" },
        user_default_options = {
          RGB = false, -- #RGB hex codes
          RRGGBB = true, -- #RRGGBB hex codes
          names = false, -- "Name" codes like Blue or blue
          RRGGBBAA = true, -- #RRGGBBAA hex codes
          AARRGGBB = true, -- 0xAARRGGBB hex codes
          rgb_fn = true, -- CSS rgb() and rgba() functions
          hsl_fn = true, -- CSS hsl() and hsla() functions
          -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
          css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
          sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
          -- Available modes for `mode`: foreground, background,  virtualtext
          mode = "background", -- Set the display mode.
          virtualtext = "■",
        },
        -- all the sub-options of filetypes apply to buftypes
        buftypes = {},
      })

      _G.mega.augroup("Colorizer", {
        {
          event = { "BufReadPost" },
          command = function()
            if _G.mega.is_chonky(vim.api.nvim_get_current_buf()) then vim.cmd("ColorizerDetachFromBuffer") end
          end,
        },
      })
    end,
  },
  { "lukas-reineke/virt-column.nvim", config = { char = "│" }, event = "VimEnter" },
  -- {
  --   "stevearc/dressing.nvim",
  --   event = "VeryLazy",
  --   config = {
  --     input = {
  --       enabled = true,
  --       override = function(conf)
  --         conf.col = -1
  --         conf.row = 0
  --         return conf
  --       end,
  --     },
  --   },
  --   -- init = function()
  --   --   ---@diagnostic disable-next-line: duplicate-set-field
  --   --   vim.ui.input = function(...)
  --   --     require("lazy").load({ plugins = { "dressing.nvim" } })
  --   --     return vim.ui.input(...)
  --   --   end
  --   -- end,
  -- },
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    enabled = false,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("todo-comments").setup()
      -- mega.command("TodoDots", ("TodoQuickFix cwd=%s keywords=TODO,FIXME"):format(vim.g.vim_dir))
    end,
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      plugins = {
        gitsigns = true,
        tmux = true,
        kitty = { enabled = false, font = "+2" },
      },
    },
    keys = { { "<localleader>zz", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  },

  -- indent guides for Neovim
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    enabled = false,
    opts = {
      char = "┊", -- alts: ┆ ┊  ▎│
      show_foldtext = false,
      context_char = "▎",
      char_priority = 12,
      show_current_context = true,
      show_current_context_start = true,
      show_current_context_start_on_current_line = true,
      show_trailing_blankline_indent = true,
      show_first_indent_level = false,
      filetype_exclude = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "lazy",
        "fzf",
        "fzf-lua",
        "fzflua",
        "megaterm",
        "dbout",
        "neo-tree-popup",
        "dap-repl",
        "startify",
        "dashboard",
        "log",
        "fugitive",
        "gitcommit",
        "packer",
        "vimwiki",
        "markdown",
        "txt",
        "vista",
        "help",
        "NvimTree",
        "git",
        "TelescopePrompt",
        "undotree",
        "flutterToolsOutline",
        "norg",
        "org",
        "orgagenda",
        "", -- for all buffers without a file type
      },
      buftype_exclude = { "terminal", "nofile" },
    },
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
    config = function()
      vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
      vim.g.undotree_SetFocusWhenToggle = 1
    end,
  },
  {
    "chrisgrieser/replacer.nvim",
    ft = "qf",
    keys = {
      { "<leader>R", function() require("replacer").run() end, desc = "qf: replace in qflist" },
    },
    init = function()
      -- save & quit via "q"
      mega.augroup("ReplacerFileType", {
        pattern = "replacer",
        callback = function()
          mega.nmap("q", vim.cmd.write, { desc = " Finish replacing", buffer = true, nowait = true })
        end,
      })
    end,
  },

  -- ( LSP ) -------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "nvim-lua/lsp_extensions.nvim" },
      {
        "jose-elias-alvarez/typescript.nvim",
        ft = { "typescript", "typescriptreact" },
        dependencies = { "jose-elias-alvarez/null-ls.nvim" },
        config = function()
          -- require("typescript").setup({ server = require("mega.servers")("tsserver") })
          require("null-ls").register({
            sources = { require("typescript.extensions.null-ls.code-actions") },
          })
        end,
      },
      { "MunifTanjim/nui.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "b0o/schemastore.nvim" },
      { "mrshmllow/document-color.nvim", event = "BufReadPre" },
      {
        "mhanberg/elixir.nvim",
        ft = { "elixir", "eex", "heex", "surface" },
        config = function()
          local elixir = require("elixir")

          elixir.setup({
            cmd = fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh"),
            settings = elixir.settings({
              dialyzerEnabled = true,
              dialyzerFormat = "dialyxir_short",
              fetchDeps = false,
              enableTestLenses = false,
              suggestSpecs = true,
            }),
            log_level = vim.lsp.protocol.MessageType.Log,
            message_level = vim.lsp.protocol.MessageType.Log,
            on_attach = function(client, bufnr)
              -- whatever keybinds you want, see below for more suggestions
              -- vim.keymap.set("n", "<space>fp", ":ElixirFromPipe<cr>", { buffer = true, noremap = true })
              -- vim.keymap.set("n", "<space>tp", ":ElixirToPipe<cr>", { buffer = true, noremap = true })
              -- vim.keymap.set("v", "<space>em", ":ElixirExpandMacro<cr>", { buffer = true, noremap = true })
            end,
          })
        end,
        dependencies = {
          "nvim-lua/plenary.nvim",
        },
      },
      {
        "lewis6991/hover.nvim",
        keys = { "K", "gK" },
        config = function()
          require("hover").setup({
            init = function()
              require("hover.providers.lsp")
              require("hover.providers.gh")
              require("hover.providers.gh_user")
              require("hover.providers.jira")
              require("hover.providers.man")
              require("hover.providers.dictionary")
            end,
            preview_opts = {
              border = require("mega.globals").get_border(),
            },
            -- Whether the contents of a currently open hover window should be moved
            -- to a :h preview-window when pressing the hover keymap.
            preview_window = true,
            title = false,
          })
        end,
      },
    },
  },
  -- {
  --   {
  --     "williamboman/mason.nvim",
  --     cmd = "Mason",
  --     build = ":MasonUpdate",
  --     opts = { ui = { border = mega.get_border(), height = 0.8 } },
  --   },
  --   {
  --     "williamboman/mason-lspconfig.nvim",
  --     event = { "BufReadPre", "BufNewFile" },
  --     dependencies = {
  --       "mason.nvim",
  --       {
  --         "neovim/nvim-lspconfig",
  --         dependencies = {
  --           {
  --             "folke/neodev.nvim",
  --             ft = "lua",
  --             opts = { library = { plugins = { "nvim-dap-ui" } } },
  --           },
  --           {
  --             "folke/neoconf.nvim",
  --             cmd = { "Neoconf" },
  --             opts = { local_settings = ".nvim.json", global_settings = "nvim.json" },
  --           },
  --         },
  --         config = function()
  --           -- highlight.plugin("lspconfig", { { LspInfoBorder = { link = "FloatBorder" } } })
  --           require("lspconfig.ui.windows").default_options.border = mega.get_border()
  --           require("lspconfig").ccls.setup(require("mega.lsp.servers")("ccls"))
  --         end,
  --       },
  --     },
  --     config = function()
  --       require("mason-lspconfig").setup({ automatic_installation = true })
  --       require("mason-lspconfig").setup_handlers({
  --         function(name)
  --           local config = require("mega.lsp.servers")(name)
  --           if config then require("lspconfig")[name].setup(config) end
  --         end,
  --       })
  --     end,
  --   },
  -- },

  -- ( Movements ) -------------------------------------------------------------
  -- @trial multi-cursor: https://github.com/brendalf/dotfiles/blob/master/.config/nvim/lua/core/multi-cursor.lua

  -- ( Navigation ) ------------------------------------------------------------
  {
    "knubie/vim-kitty-navigator",
    event = "VeryLazy",
    -- build = "cp ./*.py ~/.config/kitty/",
    cond = not vim.env.TMUX and not vim.env.ZELLIJ,
  },
  -- {
  --   "sidebar-nvim/sidebar.nvim",
  --   keys = {
  --     -- { "<leader>et", [[<Cmd>lua require("sidebar-nvim").toggle({focus = true})<CR>]], desc = "Toggle sidebar" },
  --   },
  --   cmd = {
  --     "SidebarNvimToggle",
  --     "SidebarNvimOpen",
  --     "SidebarNvimClose",
  --     "SidebarNvimUpdate",
  --     "SidebarNvimFocus",
  --     "SidebarNvimResize",
  --   },
  --   cond = vim.g.tree == "sidebar",
  --   opts = {
  --     open = false,
  --     initial_width = 30,
  --     section_separator = { " ", " " },
  --     files = {
  --       show_hidden = true,
  --     },
  --     todos = {
  --       icon = " ",
  --       ignored_paths = { "~" }, -- ignore certain paths, this will prevent huge folders like $HOME to hog Neovim with TODO searching
  --       initially_closed = false, -- whether the groups should be initially closed on start. You can manually open/close groups later.
  --     },
  --     sections = {
  --       "git",
  --       "files",
  --       "diagnostics",
  --       -- "todos",
  --       -- "buffers",
  --       -- "symbols",
  --       -- "containers",
  --     },
  --   },
  -- },
  {
    "megalithic/dirbuf.nvim",
    dev = true,
    keys = {
      {
        "<leader>ed",
        function()
          local buf = vim.api.nvim_buf_get_name(0)
          -- vim.cmd([[vertical topleft split|vertical resize 60]])
          vim.cmd([[vertical rightbelow split]])
          require("dirbuf").open(buf)
        end,
        desc = "dirbuf: toggle",
      },
      {
        "<leader>ee",
        function()
          local buf = vim.api.nvim_buf_get_name(0)
          -- vim.cmd([[vertical topleft split|vertical resize 60]])
          require("dirbuf").open(buf)
        end,
        desc = "dirbuf: toggle",
      },
    },
    cmd = { "Dirbuf", "DirbufQuit", "DirbufSync" },
    opts = {
      sort_order = "directories_first",
      devicons = true,
    },
  },
  -- {
  --   "prichrd/netrw.nvim",
  --   ft = "netrw",
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --   },
  -- },
  { "kevinhwang91/nvim-bqf", ft = "qf" },
  {
    url = "https://gitlab.com/yorickpeterse/nvim-pqf",
    event = "BufReadPre",
    config = function()
      local icons = require("mega.icons")
      require("pqf").setup({
        signs = {
          error = icons.lsp.error,
          warning = icons.lsp.warn,
          info = icons.lsp.info,
          hint = icons.lsp.hint,
        },
      })
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    config = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },

  -- ( Testing/Debugging ) -----------------------------------------------------
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = "nvim-dap",
    -- event = "VeryLazy",
    config = function()
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })
    end,
  },
  {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = "nvim-dap",
    -- event = "VeryLazy"
  },
  {
    "suketa/nvim-dap-ruby",
    -- event = "VeryLazy",
    dependencies = "nvim-dap",
    config = function() require("dap-ruby").setup() end,
  },
  -- {
  --   "microsoft/vscode-js-debug",
  --   build = "npm install --legacy-peer-deps && npm run compile",
  -- },
  {
    "mxsdev/nvim-dap-vscode-js",
    -- event = "VeryLazy",
    dependencies = "nvim-dap",
    config = function()
      require("dap-vscode-js").setup({
        log_file_level = vim.log.levels.TRACE,
        adapters = {
          "pwa-node",
          "pwa-chrome",
          "pwa-msedge",
          "node-terminal",
          "pwa-extensionHost",
        },
      })
    end,
  },
  {
    "sultanahamer/nvim-dap-reactnative",
    dependencies = "nvim-dap",
    -- event = "VeryLazy"
  },
  -- {
  --   "jayp0521/mason-nvim-dap.nvim",
  --   dependencies = "nvim-dap",
  --   config = function()
  --     require("mason-nvim-dap").setup({
  --       ensure_installed = { "python", "node2", "chrome", "firefox" },
  --       automatic_installation = true,
  --     })
  --   end,
  -- },

  -- ( Development ) -----------------------------------------------------------
  {
    "kevinhwang91/nvim-hclipboard",
    event = "InsertCharPre",
    config = function() require("hclipboard").start() end,
  },
  {
    "mg979/vim-visual-multi",
    keys = { { "<C-e>", mode = { "n", "x" } }, "\\j", "\\k" },
    enabled = false,
    event = { "BufReadPost", "BufNewFile" },
    init = function()
      vim.g.VM_highlight_matches = "underline"
      vim.g.VM_theme = "codedark"
      vim.g.VM_maps = {
        ["Find Word"] = "<C-E>",
        ["Find Under"] = "<C-E>",
        ["Find Subword Under"] = "<C-E>",
        ["Select Cursor Down"] = "\\j",
        ["Select Cursor Up"] = "\\k",
      }
    end,
  },
  -- {
  --   "danymat/neogen",
  --   event = "VeryLazy",
  --   keys = {
  --     {
  --       "<leader>cc",
  --       function() require("neogen").generate({}) end,
  --       desc = "Neogen Comment",
  --     },
  --   },
  --   config = { snippet_engine = "luasnip" },
  -- },
  {
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  },
  { "alvan/vim-closetag", ft = { "elixir", "heex", "html", "liquid", "javascriptreact", "typescriptreact" } },
  {
    "andymass/vim-matchup",
    event = "BufReadPre",
    config = function()
      vim.g.matchup_surround_enabled = true
      vim.g.matchup_matchparen_deferred = true
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
        -- fullwidth = true,
        highlight = "Normal",
        border = "none",
      }
    end,
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  },
  { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
  -- {
  --   "chrisgrieser/nvim-genghis",
  --   -- dependencies = {
  --   --   { "tpope/vim-eunuch", event = "VeryLazy" },
  --   -- },
  --   event = "VeryLazy",
  --   config = function()
  --     local genghis = require("genghis")
  --     mega.nnoremap("<localleader>yp", genghis.copyFilepath, { desc = "Copy filepath" })
  --     mega.nnoremap("<localleader>yn", genghis.copyFilename, { desc = "Copy filename" })
  --     mega.nnoremap("<localleader>yf", genghis.duplicateFile, { desc = "Duplicate file" })
  --     mega.nnoremap("<localleader>rf", genghis.renameFile, { desc = "Rename file" })
  --     mega.nnoremap("<localleader>cx", genghis.chmodx, { desc = "Chmod +x file" })
  --     mega.nnoremap(
  --       "<localleader>df",
  --       function() genghis.trashFile({ trashLocation = "$HOME/.Trash" }) end,
  --       { desc = "Delete to trash" }
  --     ) -- default: "$HOME/.Trash".
  --     -- mega.nmap("<localleader>mf", genghis.moveAndRenameFile)
  --     -- mega.nmap("<localleader>nf", genghis.createNewFile)
  --     -- mega.nmap("<localleader>x", genghis.moveSelectionToNewFile)
  --   end,
  -- },
  {
    "tpope/vim-abolish",
    event = "CmdlineEnter",
    keys = {
      {
        "<C-s>",
        ":S/<C-R><C-W>//<LEFT>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (line)",
      },
      {
        "<C-s>",
        ":%S/<C-r><C-w>//c<left><left>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (file)",
      },
      {
        "<C-r>",
        [["zy:'<'>S/<C-r><C-o>"//c<left><left>]],
        mode = "x",
        silent = false,
        desc = "abolish: replace word under the cursor (visual)",
      },
    },
  },
  { "tpope/vim-rhubarb", event = { "VeryLazy" } },
  { "tpope/vim-repeat", lazy = false },
  { "tpope/vim-unimpaired", event = { "VeryLazy" } },
  { "tpope/vim-apathy", event = { "VeryLazy" } },
  { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
  { "wsdjeg/vim-fetch", event = { "BufReadPre" } }, -- vim path/to/file.ext:12:3
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  {
    "linty-org/readline.nvim",
    keys = {
      { "<C-f>", function() require("readline").forward_word() end, mode = "!" },
      { "<C-b>", function() require("readline").backward_word() end, mode = "!" },
      { "<C-a>", function() require("readline").beginning_of_line() end, mode = "!" },
      { "<C-e>", function() require("readline").end_of_line() end, mode = "!" },
      { "<M-d>", function() require("readline").kill_word() end, mode = "!" },
      { "<M-BS>", function() require("readline").backward_kill_word() end, mode = "!" },
      { "<C-w>", function() require("readline").unix_word_rubout() end, mode = "!" },
      { "<C-k>", function() require("readline").kill_line() end, mode = "!" },
      { "<C-u>", function() require("readline").backward_kill_line() end, mode = "!" },
    },
  },
  { "axelvc/template-string.nvim", ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" } },

  -- ( Motions/Textobjects ) ---------------------------------------------------
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter", "AndrewRadev/splitjoin.vim" },
    cmd = { "TSJSplit", "TSJJoin", "TSJToggle", "SplitjoinJoin", "SplitjoinSplit" },
    keys = { "gs", "gj", "gS", "gJ" },
    config = function()
      require("treesj").setup({ use_default_keymaps = false, max_join_length = 150 })

      local langs = require("treesj.langs")["presets"]

      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = "*",
        callback = function()
          if langs[vim.bo.filetype] then
            mega.nnoremap("gS", ":TSJSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gJ", ":TSJJoin<cr>", { desc = "Join lines", buffer = true })
            mega.nnoremap("gs", ":TSJSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gj", ":TSJJoin<cr>", { desc = "Join lines", buffer = true })
          else
            mega.nnoremap("gS", ":SplitjoinSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gJ", ":SplitjoinJoin<cr>", { desc = "Join lines", buffer = true })
            mega.nnoremap("gs", ":SplitjoinSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gj", ":SplitjoinJoin<cr>", { desc = "Join lines", buffer = true })
          end
        end,
      })
    end,
  },
  {
    "abecodes/tabout.nvim",
    event = { "InsertEnter" },
    keys = { "<Tab>", "<S-Tab>", "<C-t>", "<C-d>" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/nvim-cmp" },
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = "<C-d>", -- reverse shift default action,
        enable_backwards = true, -- well ...
        completion = true, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = "\"", close = "\"" },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "<", close = ">" },
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {}, -- tabout will ignore these filetypes
      })
    end,
  },

  -- ( Notes/Docs ) ------------------------------------------------------------
  { "iamcco/markdown-preview.nvim", ft = "markdown", build = "cd app && yarn install" },
  {
    "ekickx/clipboard-image.nvim",
    ft = "markdown",
    config = true,
  },
  {
    "evanpurkhiser/image-paste.nvim",
    ft = "markdown",
    keys = {
      { "<C-v>", function() require("image-paste").paste_image() end, mode = "i" },
    },
    config = {
      imgur_client_id = "2974b259fd073e2",
    },
  },
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = { "markdown" },
    config = function()
      local peek = require("peek")
      peek.setup({})

      _G.mega.command("Peek", function()
        if not peek.is_open() and vim.bo[vim.api.nvim_get_current_buf()].filetype == "markdown" then
          peek.open()
          -- vim.fn.system([[hs -c 'require("wm.snap").send_window_right(hs.window.find("Peek preview"))']])
          -- vim.fn.system([[hs -c 'require("wm.snap").send_window_left(hs.application.find("kitty"):mainWindow())']])
        else
          peek.close()
        end
      end)
    end,
  },
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    keys = { "<CR>", "<Tab>", "<S-Tab>", "o", "O", ">>", "<<", "<C-r>", "<leader>x", "C-c" },
    config = function()
      local autolist = require("autolist")
      autolist.setup()
      autolist.create_mapping_hook("i", "<CR>", autolist.new)
      autolist.create_mapping_hook("i", "<Tab>", autolist.indent)
      autolist.create_mapping_hook("i", "<S-Tab>", autolist.indent, "<C-D>")
      autolist.create_mapping_hook("n", "o", autolist.new)
      autolist.create_mapping_hook("n", "O", autolist.new_before)
      autolist.create_mapping_hook("n", ">>", autolist.indent)
      autolist.create_mapping_hook("n", "<<", autolist.indent)
      autolist.create_mapping_hook("n", "<C-r>", autolist.force_recalculate)
      autolist.create_mapping_hook("n", "<leader>x", autolist.invert_entry, "")
      autolist.create_mapping_hook("n", "<C-c>", autolist.invert_entry, "")
      vim.api.nvim_create_autocmd("TextChanged", {
        pattern = "*",
        callback = function() vim.cmd.normal({ autolist.force_recalculate(nil, nil), bang = false }) end,
      })
      -- require("autolist").setup({ normal_mappings = { invert = { "<c-c>" } } })
    end,
  },
  { "ellisonleao/glow.nvim", ft = { "markdown" } },
  {
    "lukas-reineke/headlines.nvim",
    -- has TS query errors/warnings/etc
    enabled = false,
    ft = { "markdown" },
    dependencies = "nvim-treesitter",
    config = function()
      require("headlines").setup({
        markdown = {
          source_pattern_start = "^```",
          source_pattern_end = "^```$",
          dash_pattern = "-",
          dash_highlight = "Dash",
          dash_string = "", -- alts:  靖並   ﮆ 
          headline_pattern = "^#+",
          headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
          codeblock_highlight = "CodeBlock",
        },
        yaml = {
          dash_pattern = "^---+$",
          dash_highlight = "Dash",
        },
      })
    end,
  },
  -- @trial phaazon/mind.nvim
  -- @trial "renerocksai/telekasten.nvim"
  -- @trial preservim/vim-wordy
  -- @trial jghauser/follow-md-links.nvim
  -- @trial jakewvincent/mkdnflow.nvim
  -- @trial jubnzv/mdeval.nvim
  -- "dkarter/bullets.vim".
  -- "dhruvasagar/vim-table-mode".
  -- "rhysd/vim-gfm-syntax".

  -- ( Syntax/Languages ) ------------------------------------------------------
  { "ii14/emmylua-nvim", ft = "lua" },
  { "elixir-editors/vim-elixir", ft = { "markdown" } }, -- nvim exceptions thrown when not installed
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
}
