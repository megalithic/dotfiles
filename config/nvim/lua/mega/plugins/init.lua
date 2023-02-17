return {
  -- ( CORE ) ------------------------------------------------------------------
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },
  "mattn/webapi-vim",
  {
    "ethanholz/nvim-lastplace",
    lazy = false,
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
        lastplace_open_folds = true,
      })
    end,
  },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("lush")(require("mega.lush_theme.megaforest"))
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  -- {
  --   "JoosepAlviste/palenightfall.nvim",
  --   lazy = false,
  --   config = vim.g.colorscheme == "palenightfall",
  -- },
  {
    "mcchrish/zenbones.nvim",
    lazy = false,
    dependencies = "rktjmp/lush.nvim",
  },
  {
    "neanias/everforest-nvim",
    lazy = false,
    config = function()
      require("everforest").setup({
        -- Controls the "hardness" of the background. Options are "soft", "medium" or "hard".
        -- Default is "medium".
        background = "soft",
        -- How much of the background should be transparent. Options are 0, 1 or 2.
        -- Default is 0.
        --
        -- 2 will have more UI components be transparent (e.g. status line
        -- background).
        transparent_background_level = 0,
      })
    end,
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    -- event = { "CursorHold", "CursorMoved", "InsertEnter" },
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage" },
        buftype = { "*", "!prompt", "!nofile" },
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
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
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
  {
    "stevearc/dressing.nvim",
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },

  -- indent guides for Neovim
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- char = "▏",
      char = "│", -- alts: ┆ ┊  ▎
      filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy" },
      show_trailing_blankline_indent = false,
      show_current_context = false,
      show_current_context_start = true,
    },
  },

  -- active indent guide and indent text objects
  {
    "echasnovski/mini.indentscope",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = true },
    },
    config = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
        callback = function() vim.b.miniindentscope_disable = true end,
      })
      require("mini.indentscope").setup(opts)
    end,
  },
  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   event = { "BufReadPost", "BufNewFile" },
  --   config = function()
  --     local ibl = require("indent_blankline")
  --
  --     -- local refresh = ibl.refresh
  --     -- ibl.refresh = _G.mega.debounce(100, refresh)
  --
  --     ibl.setup({
  --       char = "│", -- alts: ┆ ┊  ▎
  --       show_foldtext = false,
  --       context_char = "▎",
  --       char_priority = 12,
  --       show_current_context = true,
  --       show_current_context_start = true,
  --       show_current_context_start_on_current_line = true,
  --       show_first_indent_level = true,
  --       filetype_exclude = {
  --         "dbout",
  --         "neo-tree-popup",
  --         "dap-repl",
  --         "startify",
  --         "dashboard",
  --         "log",
  --         "fugitive",
  --         "gitcommit",
  --         "packer",
  --         "vimwiki",
  --         "markdown",
  --         "txt",
  --         "vista",
  --         "help",
  --         "NvimTree",
  --         "git",
  --         "TelescopePrompt",
  --         "undotree",
  --         "flutterToolsOutline",
  --         "norg",
  --         "org",
  --         "orgagenda",
  --         "", -- for all buffers without a file type
  --       },
  --       buftype_exclude = { "terminal", "nofile" },
  --     })
  --   end,
  -- },

  -- ( Movements ) -------------------------------------------------------------
  -- @trial multi-cursor: https://github.com/brendalf/dotfiles/blob/master/.config/nvim/lua/core/multi-cursor.lua

  -- ( Navigation ) ------------------------------------------------------------
  {
    "knubie/vim-kitty-navigator",
    -- build = "cp ./*.py ~/.config/kitty/",
    cond = not vim.env.TMUX and not vim.env.ZELLIJ,
  },
  {
    "Lilja/zellij.nvim",
    cond = vim.env.ZELLIJ,
    config = function()
      require("zellij").setup({})
      local function edgeDetect(direction)
        local currWin = vim.api.nvim_get_current_win()
        vim.api.nvim_command("wincmd " .. direction)
        local newWin = vim.api.nvim_get_current_win()

        -- You're at the edge when you just moved direction and the window number is the same
        print("ol winN ")
        print(currWin)
        print(" new ")
        print(newWin)
        print(" same? ")
        print(currWin == newWin)
        return currWin == newWin
      end

      local function zjCall(direction)
        local directionTranslation = {
          h = "left",
          j = "down",
          k = "up",
          l = "right",
        }
        -- local cmd  = "zellij action move-focus-or-tab " .. directionTranslation[direction]
        local cmd = "zellij action move-focus-or-tab " .. directionTranslation[direction]
        local cmd2 = "zellij --help"
        print("cmd")
        print(cmd)
        local c = vim.fn.system(cmd)
        print(c)
        local c2 = vim.fn.system("ls -l")
        print(c2)
      end

      local function zjNavigate(direction)
        if edgeDetect(direction) then zjCall(direction) end
      end

      vim.keymap.set("n", "<C-h>", function() zjNavigate("h") end)
      vim.keymap.set("n", "<C-j", function() zjNavigate("j") end)
      vim.keymap.set("n", "<C-k", function() zjNavigate("k") end)
      vim.keymap.set("n", "<C-l", function() zjNavigate("l") end)
    end,
  },
  -- { "sunaku/tmux-navigate", cond = vim.env.TMUX },
  -- { "elihunter173/dirbuf.nvim", config = function() require("dirbuf").setup({}) end },
  -- {
  --   "folke/trouble.nvim",
  --   cmd = "TroubleToggle",
  --   keys = { "<leader>E", "<leader>le" },
  --   config = function()
  --     _G.mega.plugin_setup("trouble", {
  --       auto_preview = false,
  --       use_diagnostic_signs = true,
  --       auto_close = true,
  --       action_keys = {
  --         close = { "q", "<Esc>", "<C-q>", "<C-c>" },
  --         refresh = "R",
  --         jump = { "<Space>" },
  --         open_split = { "<c-s>" },
  --         open_vsplit = { "<c-v>" },
  --         open_tab = { "<c-t>" },
  --         jump_close = { "<CR>" },
  --         toggle_mode = "m",
  --         toggle_preview = "P",
  --         hover = { "gh" },
  --         preview = "p",
  --         close_folds = { "h", "zM", "zm" },
  --         open_folds = { "l", "zR", "zr" },
  --         toggle_fold = { "zA", "za" },
  --         previous = "k",
  --         next = "j",
  --         cancel = nil,
  --       },
  --     })
  --     _G.mega.nmap("<leader>E", "<cmd>TroubleToggle<CR>")
  --     _G.mega.nmap("<leader>le", "<cmd>TroubleToggle<CR>", "Toggle Trouble")
  --   end,
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

  -- ( LSP ) -------------------------------------------------------------------
  -- TODO: https://github.com/folke/dot/tree/master/config/nvim/lua/config/plugins/lsp
  -- {
  --   "williamboman/mason.nvim",
  --   event = "BufRead",
  --   dependencies = {
  --     "nvim-lspconfig",
  --     "williamboman/mason-lspconfig.nvim",
  --   },
  --   config = function()
  --     -- require("mason").setup({
  --     --   ui = {
  --     --     border = _G.mega.get_border(),
  --     --     log_level = vim.log.levels.DEBUG,
  --     --   },
  --     -- })
  --
  --     -- require("mega.lsp.servers")()
  --     local get_config = require("mega.lsp.servers")
  --     require("mason").setup({
  --       ui = {
  --         border = _G.mega.get_border(),
  --         log_level = vim.log.levels.DEBUG,
  --       },
  --     })
  --     require("mason-lspconfig").setup({
  --       automatic_installation = true,
  --       ensure_installed = {
  --         "bashls",
  --         "clangd",
  --         -- "cmake",
  --         "cssls",
  --         "dockerls",
  --         "elixirls",
  --         "elmls",
  --         "ember",
  --         "emmet_ls",
  --         -- "erlangls",
  --         "gopls",
  --         "html",
  --         "jsonls",
  --         -- "marksman",
  --         "pyright",
  --         "rust_analyzer",
  --         "solargraph",
  --         -- "sqlls",
  --         "sumneko_lua",
  --         "tailwindcss",
  --         "terraformls",
  --         "tsserver",
  --         "vimls",
  --         "yamlls",
  --         "zk",
  --         "zls",
  --       },
  --     })
  --     require("mason-lspconfig").setup_handlers({
  --       function(name)
  --         local cfg = get_config(name)
  --         if cfg then
  --           -- vim.notify(fmt("Found lsp config for %s", name), vim.log.levels.INFO, { title = "mason-lspconfig" })
  --           require("lspconfig")[name].setup(cfg)
  --         end
  --       end,
  --     })
  --   end,
  -- },
  -- {
  --   "jayp0521/mason-null-ls.nvim",
  --   dependencies = {
  --     "williamboman/mason.nvim",
  --     "jose-elias-alvarez/null-ls.nvim",
  --   },
  --   dependencies = "mason.nvim",
  --   config = function()
  --     require("mason-null-ls").setup({
  --       automatic_installation = true,
  --       ensure_installed = {
  --         "beautysh",
  --       },
  --     })
  --   end,
  -- },
  -- {
  --   "neovim/nvim-lspconfig",
  --   dependencies = {
  --     -- having this one installed just makes neovim api docs available
  --     -- via LSP, don't need to actually do anything with it
  --     "folke/neodev.nvim",
  --   },
  --   config = function() require("lspconfig.ui.windows").default_options.border = _G.mega.get_border() end,
  -- },

  {
    "SmiteshP/nvim-navic",
    lazy = true,
    config = function()
      vim.g.navic_silence = true
      require("nvim-navic").setup({ separator = " ", highlight = true, depth_limit = 5 })
    end,
  },

  -- {
  --   "issafalcon/lsp-overloads.nvim",
  --   dependencies = "nvim-lspconfig",
  --   config = function()
  --     require("lsp-overloads").setup({
  --       ui = {
  --         -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
  --         border = mega.get_border(),
  --       },
  --     })
  --   end,
  -- },

  -- {
  --   "ray-x/lsp_signature.nvim",
  --   dependencies = "nvim-lspconfig",
  --   config = function()
  --     require("lsp_signature").setup({
  --       bind = true,
  --       fix_pos = true,
  --       auto_close_after = 5, -- close after 15 seconds
  --       hint_enable = false,
  --       floating_window_above_cur_line = true,
  --       doc_lines = 0,
  --       handler_opts = {
  --         anchor = "SW",
  --         relative = "cursor",
  --         row = -1,
  --         focus = false,
  --         border = _G.mega.get_border(),
  --       },
  --       zindex = 99, -- Keep signature popup below the completion PUM
  --       toggle_key = "<C-K>",
  --       select_signature_key = "<M-N>",
  --     })
  --   end,
  -- },

  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/typescript.nvim",
  "MunifTanjim/nui.nvim",
  "williamboman/mason-lspconfig.nvim",
  "b0o/schemastore.nvim",
  "mrshmllow/document-color.nvim",
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    config = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },
  {
    "lewis6991/hover.nvim",
    keys = { "K", "gK" },
    config = function()
      require("hover").setup({
        init = function()
          -- Require providers
          require("hover.providers.lsp")
          -- require('hover.providers.gh')
          -- require('hover.providers.gh_user')
          -- require('hover.providers.jira')
          -- require('hover.providers.man')
          -- require('hover.providers.dictionary')
        end,
        preview_opts = {
          border = require("mega.globals").get_border(),
        },
        -- Whether the contents of a currently open hover window should be moved
        -- to a :h preview-window when pressing the hover keymap.
        preview_window = false,
        title = true,
      })
    end,
  },
  -- { "folke/lua-dev.nvim", module = "lua-dev" },
  -- { "microsoft/python-type-stubs", lazy = true },
  -- { "lvimuser/lsp-inlayhints.nvim" },

  -- ( Git ) -------------------------------------------------------------------
  {
    "TimUntersberger/neogit",
    cmd = "Neogit",
    config = function()
      local neogit = require("neogit")
      neogit.setup({
        disable_signs = false,
        disable_hint = true,
        disable_commit_confirmation = true,
        disable_builtin_notifications = true,
        disable_insert_on_commit = false,
        signs = {
          section = { "", "" }, -- "", ""
          item = { "▸", "▾" },
          hunk = { "樂", "" },
        },
        integrations = {
          diffview = true,
        },
      })
      mega.nnoremap("<localleader>gs", function() neogit.open() end)
      mega.nnoremap("<localleader>gc", function() neogit.open({ "commit" }) end)
      mega.nnoremap("<localleader>gl", neogit.popups.pull.create)
      mega.nnoremap("<localleader>gp", neogit.popups.push.create)
    end,
    dependencies = "nvim-lua/plenary.nvim",
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = true,
    keys = { { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
  },
  {
    "akinsho/git-conflict.nvim",
    lazy = false,
    dependencies = "rktjmp/lush.nvim",
    config = function()
      require("git-conflict").setup({
        disable_diagnostics = true,
        highlights = {
          incoming = "DiffText",
          current = "DiffAdd",
          ancestor = "DiffBase",
        },
      })
    end,
  },
  {
    "ruifm/gitlinker.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    keys = {
      { "<localleader>gu", mode = "n" },
      { "<localleader>gu", mode = "v" },
      "<localleader>go",
      "<leader>gH",
      { "<localleader>go", mode = "n" },
      { "<localleader>go", mode = "v" },
    },
    config = function()
      require("gitlinker").setup({ mappings = nil })

      local function linker() return require("gitlinker") end
      local function browser_open() return { action_callback = require("gitlinker.actions").open_in_browser } end
      mega.nnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("n") end,
        "gitlinker: copy line to clipboard"
      )
      mega.vnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("v") end,
        "gitlinker: copy range to clipboard"
      )
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_repo_url(browser_open()) end,
        "gitlinker: open in browser"
      )
      mega.nnoremap("<leader>gH", function() linker().get_repo_url(browser_open()) end, "gitlinker: open in browser")
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("n", browser_open()) end,
        "gitlinker: open current line in browser"
      )
      mega.vnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("v", browser_open()) end,
        "gitlinker: open current selection in browser"
      )
    end,
  },

  -- ( Testing/Debugging ) -----------------------------------------------------
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = "nvim-dap",
    config = function()
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })
    end,
  },
  { "jbyuki/one-small-step-for-vimkind", dependencies = "nvim-dap" },
  { "suketa/nvim-dap-ruby", dependencies = "nvim-dap", config = function() require("dap-ruby").setup() end },
  -- {
  --   "microsoft/vscode-js-debug",
  --   build = "npm install --legacy-peer-deps && npm run compile",
  -- },
  {
    "mxsdev/nvim-dap-vscode-js",
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
  { "sultanahamer/nvim-dap-reactnative", dependencies = "nvim-dap" },
  -- { "microsoft/vscode-react-native", dependencies = "nvim-dap" },
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
  -- {
  --   "chipsenkbeil/distant.nvim",
  --   tag = "v0.2",
  --   build = ":DistantInstall",
  --   config = function()
  --     require("distant").setup({
  --       -- Applies Chip's personal settings to every machine you connect to
  --       --
  --       -- 1. Ensures that distant servers terminate with no connections
  --       -- 2. Provides navigation bindings for remote directories
  --       -- 3. Provides keybinding to jump into a remote file's parent directory
  --       ["*"] = require("distant.settings").chip_default(),
  --     })
  --   end,
  -- },
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cc",
        function() require("neogen").generate({}) end,
        desc = "Neogen Comment",
      },
    },
    config = { snippet_engine = "luasnip" },
  },
  {
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    setup = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  },
  {
    "numToStr/Comment.nvim",
    event = "BufRead",
    config = function()
      require("Comment").setup({

        ignore = "^$", -- ignores empty lines
        --@param ctx CommentCtx
        pre_hook = function(ctx)
          -- Only calculate commentstring for tsx filetypes
          if vim.bo.filetype == "typescriptreact" then
            local U = require("Comment.utils")

            -- Determine whether to use linewise or blockwise commentstring
            local type = ctx.ctype == U.ctype.line and "__default" or "__multiline"

            -- Determine the location where to calculate commentstring from
            local location = nil
            if ctx.ctype == U.ctype.block then
              location = require("ts_context_commentstring.utils").get_cursor_location()
            elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
              location = require("ts_context_commentstring.utils").get_visual_start_location()
            end

            return require("ts_context_commentstring.internal").calculate_commentstring({
              key = type,
              location = location,
            })
          end
        end,
      })
    end,
  },
  {
    "andymass/vim-matchup",
    event = "BufReadPre",
    config = function()
      vim.g.matchup_surround_enabled = true
      vim.g.matchup_matchparen_deferred = true
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
        fullwidth = true,
        highlight = "Normal",
        border = "shadow",
      }
    end,
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  },
  {
    "natecraddock/sessions.nvim",
    config = function()
      require("sessions").setup({
        events = { "VimLeavePre" },
        session_filepath = vim.fn.stdpath("data") .. "/sessions/default",
      })
    end,
  },
  {
    "natecraddock/workspaces.nvim",
    dependencies = "telescope.nvim",
    config = function()
      require("workspaces").setup({
        path = vim.fn.stdpath("data") .. "/workspaces",
        hooks = {
          open_pre = {
            function()
              local open_files = require("mega.utils").get_open_filelist()
              if open_files == nil or #open_files == 0 or (#open_files == 1 and open_files[1] == "") then
                vim.cmd("SessionsStop")
                vim.cmd("silent %bdelete!")
              end
            end,
          },
          open = {
            function()
              local open_files = require("mega.utils").get_open_filelist()
              if open_files == nil or #open_files == 0 or (#open_files == 1 and open_files[1] == "") then
                require("sessions").load(nil, { silent = true })
              end
            end,
          },
        },
      })
      require("telescope").load_extension("workspaces")
    end,
  },
  { "alvan/vim-closetag" },
  {
    "chrisgrieser/nvim-genghis",
    dependencies = { "stevearc/dressing.nvim", { "tpope/vim-eunuch", event = "VeryLazy" } },
    event = "VeryLazy",
    config = function()
      local genghis = require("genghis")
      mega.nnoremap("<localleader>yp", genghis.copyFilepath, { desc = "Copy filepath" })
      mega.nnoremap("<localleader>yn", genghis.copyFilename, { desc = "Copy filename" })
      mega.nnoremap("<localleader>yf", genghis.duplicateFile, { desc = "Duplicate file" })
      mega.nnoremap("<localleader>rf", genghis.renameFile, { desc = "Rename file" })
      mega.nnoremap("<localleader>cx", genghis.chmodx, { desc = "Chmod +x file" })
      mega.nnoremap(
        "<localleader>df",
        function() genghis.trashFile({ trashLocation = "$HOME/.Trash" }) end,
        { desc = "Delete to trash" }
      ) -- default: "$HOME/.Trash".
      -- mega.nmap("<localleader>mf", genghis.moveAndRenameFile)
      -- mega.nmap("<localleader>nf", genghis.createNewFile)
      -- mega.nmap("<localleader>x", genghis.moveSelectionToNewFile)
    end,
  },
  {
    "tpope/vim-abolish",
    config = function()
      mega.nnoremap("<localleader>[", ":S/<C-R><C-W>//<LEFT>", { silent = false })
      mega.nnoremap("<localleader>]", ":%S/<C-r><C-w>//c<left><left>", { silent = false })
      mega.xnoremap("<localleader>[", [["zy:'<'>S/<C-r><C-o>"//c<left><left>]], { silent = false })
    end,
  },
  { "tpope/vim-rhubarb" },
  { "tpope/vim-repeat" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-apathy" },
  { "tpope/vim-scriptease", cmd = { "Messages", "Mess" } },
  { "lambdalisue/suda.vim" },
  { "EinfachToll/DidYouMean" },
  { "wsdjeg/vim-fetch", event = "BufReadPre" }, -- vim path/to/file.ext:12:3
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  -- { "tpope/vim-scriptease" },
  { "axelvc/template-string.nvim" },
  -- @trial: "jghauser/kitty-runner.nvim"

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
            dd("using treesj for %s", langs[vim.bo.filetype])
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
    event = { "VeryLazy" },
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
      -- require("tabout").setup({
      --   ignore_beginning = false,
      --   completion = false,
      --   tabouts = {
      --     { open = "'", close = "'" },
      --     { open = "\"", close = "\"" },
      --     { open = "`", close = "`" },
      --     { open = "(", close = ")" },
      --     { open = "[", close = "]" },
      --     { open = "{", close = "}" },
      --     { open = "<", close = ">" },
      --   },
      -- })
    end,
  },

  -- ( Notes/Docs ) ------------------------------------------------------------
  -- { "ixru/nvim-markdown" },
  { "iamcco/markdown-preview.nvim", ft = "markdown", build = "cd app && yarn install" },
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

  -- {
  --   "epwalsh/obsidian.nvim",
  --   lazy = false,
  --   -- event = "VeryLazy",
  --   config = function()
  --     require("obsidian").setup({
  --       dir = vim.g.obsidian_vault_path,
  --       daily_notes = {
  --         folder = "dailies",
  --       },
  --       notes_subdir = "notes",
  --       highlight = {
  --         enable = true,
  --         additional_vim_regex_highlighting = { "markdown" },
  --       },
  --       completion = {
  --         nvim_cmp = true, -- if using nvim-cmp, otherwise set to false
  --       },
  --       use_advanceduri = true,
  --       note_id_func = function(title)
  --         -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
  --         local suffix = ""
  --         if title ~= nil then
  --           -- If title is given, transform it into valid file name.
  --           suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
  --         else
  --           -- If title is nil, just add 4 random uppercase letters to the suffix.
  --           for _ = 1, 4 do
  --             suffix = suffix .. string.char(math.random(65, 90))
  --           end
  --         end
  --         return tostring(os.time()) .. "-" .. suffix
  --       end,
  --     })
  --     mega.nmap("gf", function()
  --       if require("obsidian").util.cursor_on_markdown_link() then
  --         return "<cmd>ObsidianFollowLink<CR>"
  --       else
  --         return "gf"
  --       end
  --     end, { desc = "obsidian: follow link", expr = true })
  --     mega.vmap("gl", function()
  --       -- if require("obsidian").util.cursor_on_markdown_link() then
  --       --   return "<cmd>ObsidianFollowLink<CR>"
  --       -- else
  --       --   return "gf"
  --       -- end
  --     end, { desc = "obsidian: create link" })
  --
  --     vim.keymap.set("n", "<leader>zo", "<cmd>ObsidianOpen<cr>")
  --     vim.keymap.set("n", "<leader>zn", "<cmd>ObsidianNew<cr>")
  --     vim.keymap.set("n", "<leader>zf", "<cmd>ObsidianSearch<cr>")
  --     -- vim.keymap.set("n", "<leader>zll", "<cmd>ObsidianLink<cr>")
  --     -- vim.keymap.set("n", "<leader>zln", "<cmd>ObsidianLinkNew<cr>")
  --
  --     vim.keymap.set("v", "<leader>zll", ":ObsidianLink<CR>")
  --     vim.keymap.set("v", "<leader>zln", ":ObsidianLinkNew<CR>")
  --     vim.keymap.set("v", "<leader>zb", ":ObsidianBacklinks<CR>")
  --   end,
  -- },
  {
    "lukas-reineke/headlines.nvim",
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
  { "elixir-editors/vim-elixir", lazy = false }, -- nvim exceptions thrown when not installed
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  -- { "tpope/vim-rails" },
  -- { "ngscheurich/edeex.nvim" },
  -- { "antew/vim-elm-analyse" },
  -- { "tjdevries/nlua.nvim" },
  -- { "norcalli/nvim.lua" },
  -- -- { "euclidianace/betterlua.vim" },
  -- -- { "folke/lua-dev.nvim" },
  -- { "milisims/nvim-luaref" },
  -- { "ii14/emmylua-nvim" },
  -- { "MaxMEllon/vim-jsx-pretty" },
  -- { "heavenshell/vim-jsdoc" },
  -- { "jxnblk/vim-mdx-js" },
  -- { "skwp/vim-html-escape" },
  -- { "pedrohdz/vim-yaml-folds" },
  -- { "avakhov/vim-yaml" },
  -- { "chr4/nginx.vim" },
  -- { "nanotee/luv-vimdocs" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
}
