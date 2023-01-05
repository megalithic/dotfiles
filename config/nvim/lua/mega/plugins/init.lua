-- [ COMMANDS ] ----------------------------------------------------------------
-- mega.command("PackerCompiledEdit", function() vim.cmd.vnew(vim.g.packer_compiled_path) end)
-- mega.command("PackerCompiledDelete", function()
--   vim.fn.delete(vim.g.packer_compiled_path)
--   lazy_notify(string.format("deleted %s", vim.g.packer_compiled_path))
-- end)
-- mega.command("PackerUpgrade", function()
--   vim.schedule(function()
--     require("mega.plugins.utils").bootstrap()
--     require("mega.plugins.utils").sync()
--   end)
-- end)
-- mega.command("PackerCompile", function()
--   vim.cmd("packadd! packer.nvim")
--   vim.notify("waiting for compilation..", vim.log.levels.INFO, { title = "packer" })
--   require("packer").compile()
-- end, { nargs = "*" })
-- mega.command("Recompile", function() mega.recompile() end, { nargs = "*" })
-- mega.command("Reload", function() mega.reload() end, { nargs = "*" })
-- mega.command("PR", [[Recompile]], { nargs = "*" })
-- mega.command("PC", [[PackerCompile]], { nargs = "*" })
-- mega.command("PS", [[PackerSync]], { nargs = "*" })
-- mega.command("PU", [[PackerSync]], { nargs = "*" })
-- mega.command("PackerInstall", [[packadd! packer.nvim | lua require('packer').install()]], { nargs = "*" })
-- mega.command("PackerUpdate", [[packadd! packer.nvim | lua require('packer').update()]], { nargs = "*" })
-- mega.command("PackerSync", [[packadd! packer.nvim | lua require('packer').sync()]], { nargs = "*" })
-- mega.command("PackerClean", [[packadd! packer.nvim | lua require('packer').clean()]], { nargs = "*" })
--
-- if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(vim.g.packer_compiled_path) then
--   vim.cmd.source(vim.g.packer_compiled_path)
--   vim.g.packer_compiled_loaded = true
-- end
--
-- mega.nnoremap("<leader>ps", "<Cmd>PackerSync<CR>", "packer: sync")
-- mega.nnoremap("<leader>pc", "<Cmd>PackerCompile<CR>", "packer: compile")
-- mega.nnoremap("<leader>pr", "<Cmd>Reload<CR>", "packer: reload")
-- mega.nnoremap("<leader>px", "<Cmd>PackerClean<CR>", "packer: clean")

-- vim.cmd.packadd({ "cfilter", bang = true })
-- mega.require("impatient")

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
    lazy = false,
    priority = 1000,
    config = function()
      require("lush")(require("mega.lush_theme.megaforest"))
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
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
  { "kyazdani42/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
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
  -- {
  --   "folke/styler.nvim",
  --   event = "VeryLazy",
  --   enabled = false,
  --   config = {
  --     themes = {
  --       markdown = { colorscheme = "forestbones" },
  --       help = { colorscheme = "forestbones", background = "dark" },
  --       -- noice = { colorscheme = "gruvbox", background = "dark" },
  --     },
  --   },
  -- },
  -- {
  --   "folke/paint.nvim",
  --   enabled = false,
  --   event = "BufReadPre",
  --   config = function()
  --     require("paint").setup({
  --       highlights = {
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%-%s*(@%w+)",
  --           hl = "Constant",
  --         },
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%[%[(@%w+)",
  --           hl = "Constant",
  --         },
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%-%s*@field%s+(%S+)",
  --           hl = "@field",
  --         },
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%-%s*@class%s+(%S+)",
  --           hl = "@variable.builtin",
  --         },
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%-%s*@alias%s+(%S+)",
  --           hl = "@keyword",
  --         },
  --         {
  --           filter = { filetype = "lua" },
  --           pattern = "%s*%-%-%-%s*@param%s+(%S+)",
  --           hl = "@parameter",
  --         },
  --       },
  --     })
  --   end,
  -- },

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

  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   lazy = false,
  --   config = function()
  --     local ibl = require("indent_blankline")

  --     -- local refresh = ibl.refresh
  --     -- ibl.refresh = _G.mega.debounce(100, refresh)

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
  --  {
  --    "ggandor/flit.nvim",
  --    dependencies = { "leap.nvim",
  --    config = function()
  --      require("leap").setup({
  --        equivalence_classes = { " \t\r\n", "([{", ")]}", "`\"'" },
  --      })
  --    end,
  --  },
  --    config = function()
  --      require("flit").setup({
  --        keys = { f = "f", F = "F", t = "t", T = "T" },
  --        -- A string like "nv", "nvo", "o", etc.
  --        labeled_modes = "nvo",
  --        multiline = false,
  --      })
  --    end,
  --  },

  -- ( FZF ) -------------------------------------------------------------------
  -- { "ibhagwan/fzf-lua", config = lazy.conf("fzf") },

  -- ( Navigation ) ------------------------------------------------------------
  {
    "knubie/vim-kitty-navigator",
    -- build = "cp ./*.py ~/.config/kitty/",
    cond = not vim.env.TMUX,
  },
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
    config = function()
      vim.g.navic_silence = true
      require("nvim-navic").setup({ separator = " ", highlight = true, depth_limit = 5 })
    end,
  },

  {
    "ThePrimeagen/refactoring.nvim",
    keys = {
      {
        "<leader>r",
        function() require("refactoring").select_refactor() end,
        mode = "v",
        noremap = true,
        silent = true,
        expr = false,
      },
    },
    config = {},
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
  -- { "lewis6991/hover.nvim" },
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
  -- { "sindrets/diffview.nvim" },
  {
    "akinsho/git-conflict.nvim",
    event = "VeryLazy",
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
  -- {
  --   "windwp/nvim-autopairs",
  --   dependencies = "nvim-treesitter",
  --   event = "User PackerDeferred",
  --   -- config = function()
  --   --   require("nvim-autopairs").setup({
  --   --     disable_filetype = { "TelescopePrompt" },
  --   --     -- enable_afterquote = true, -- To use bracket pairs inside quotes
  --   --     enable_check_bracket_line = true, -- Check for closing brace so it will not add a close pair
  --   --     disable_in_macro = false,
  --   --     close_triple_quotes = true,
  --   --     check_ts = false,
  --   --     ts_config = {
  --   --       lua = { "string", "source" },
  --   --       javascript = { "string", "template_string" },
  --   --       java = false,
  --   --     },
  --   --     fast_wrap = {
  --   --       map = "<C-,>",
  --   --       chars = { "{", "[", "(", "\"", "'" },
  --   --       pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
  --   --       offset = 0, -- Offset from pattern match
  --   --       end_key = "$",
  --   --       keys = "qwertyuiopzxcvbnmasdfghjkl",
  --   --       check_comma = true,
  --   --       highlight = "PmenuSel",
  --   --       highlight_grey = "LineNr",
  --   --     },
  --   --   })
  --   --   require("nvim-autopairs").add_rules(require("nvim-autopairs.rules.endwise-ruby"))
  --   --   local endwise = require("nvim-autopairs.ts-rule").endwise
  --   --   require("nvim-autopairs").add_rules({
  --   --     endwise("do$", "end", "lua", nil),
  --   --     endwise("then$", "end", "lua", "if_statement"),
  --   --     endwise("function%(.*%)$", "end", "lua", nil),
  --   --     endwise(" do$", "end", "elixir", nil),
  --   --   })
  --   -- end,
  -- }),
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
  { "wsdjeg/vim-fetch" }, -- vim path/to/file.ext:12:3
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  -- { "tpope/vim-scriptease" },
  { "axelvc/template-string.nvim" },
  -- @trial: "jghauser/kitty-runner.nvim"

  -- ( Motions/Textobjects ) ---------------------------------------------------
  -- {
  --   "kylechui/nvim-surround",
  --   config = function()
  --     require("nvim-surround").setup({
  --       move_cursor = true,
  --       keymaps = { visual = "S" },
  --       highlight = { -- Highlight before inserting/changing surrounds
  --         duration = 1,
  --       },
  --     })
  --   end,
  -- },
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter", "AndrewRadev/splitjoin.vim" },
    cmd = { "TSJSplit", "TSJJoin", "TSJToggle", "SplitjoinJoin", "SplitjoinSplit" },
    keys = { "gs", "gj", "gS", "gJ" },
    config = function()
      require("treesj").setup({ use_default_keymaps = false })

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
    event = { "VeryLazy" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/nvim-cmp" },
    config = function()
      require("tabout").setup({
        ignore_beginning = false,
        completion = false,
        tabouts = {
          { open = "'", close = "'" },
          { open = "\"", close = "\"" },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "<", close = ">" },
        },
      })
    end,
  },

  -- ( Notes/Docs ) ------------------------------------------------------------
  -- { "ixru/nvim-markdown" },
  { "iamcco/markdown-preview.nvim", ft = "markdown", build = "cd app && yarn install" },
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
    config = function() require("autolist").setup({ normal_mappings = { invert = { "<c-c>" } } }) end,
  },
  { "ellisonleao/glow.nvim", ft = { "markdown" } },
  { "ekickx/clipboard-image.nvim" },
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
  -- @trial ekickx/clipboard-image.nvim
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
