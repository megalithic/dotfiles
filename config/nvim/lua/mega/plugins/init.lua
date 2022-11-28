local packer = require("mega.plugins.utils")
local packer_notify = packer.notify

local config = {
  -- opt_default = true,
  display = {
    open_cmd = "silent topleft 60vnew",
    non_interactive = false, --(vim.env.PACKER_NON_INTERACTIVE ~= nil and tonumber(vim.env.PACKER_NON_INTERACTIVE) == 1) and true or false,
  },
  disable_commands = true,
  auto_reload_compiled = false,
  compile_path = vim.g.packer_compiled_path,
  ensure_dependencies = true,
  snapshot_path = vim.g.packer_snapshot_path,
  preview_updates = (vim.env.PACKER_NON_INTERACTIVE ~= nil and tonumber(vim.env.PACKER_NON_INTERACTIVE) == 1) and false
    or true,
  git = {
    clone_timeout = 600,
  },
  auto_clean = true,
  compile_on_sync = true,
  max_jobs = 70,
  profile = {
    enable = true,
    threshold = 1,
  },
  -- list of plugins that should be taken from ~/code
  -- this is NOT packer functionality!
  local_plugins = {
    megalithic = true,
    -- ["nvim-lspconfig"] = false,
    -- ["nvim-treesitter"] = true,
  },
}

local function plugins(use)
  use({ "wbthomason/packer.nvim", opt = true })

  -- ( CORE ) ------------------------------------------------------------------
  use({ "lewis6991/impatient.nvim" })
  use({ "nvim-lua/plenary.nvim" })
  use({ "nvim-lua/popup.nvim" })
  use({ "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end })
  use({ "mattn/webapi-vim" })
  use({
    "ethanholz/nvim-lastplace",
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
        lastplace_open_folds = true,
      })
    end,
  })
  -- use({ "miversen33/import.nvim" }) -- A better Lua 'require()'

  -- ( UI ) --------------------------------------------------------------------
  use({ "rktjmp/lush.nvim" })
  use({
    "mcchrish/zenbones.nvim",
    requires = "rktjmp/lush.nvim",
  })
  use({ "neanias/everforest-nvim" })
  use({ "kyazdani42/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end })
  use({
    "NvChad/nvim-colorizer.lua",
    event = { "CursorHold", "CursorMoved", "InsertEnter" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!gitcommit", "!NeogitCommitMessage" },
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
  })
  use({ "lukas-reineke/virt-column.nvim" })
  use({ "MunifTanjim/nui.nvim" })
  use({ "folke/which-key.nvim", ext = "which-key" })
  use({
    "nvim-zh/colorful-winsep.nvim",
    cond = false,
    config = function()
      require("colorful-winsep").setup({
        highlight = {
          guibg = "NONE",
          guifg = mega.colors.grey0.hex,
          -- guifg = "#1F3442",
        },
      })
    end,
  })

  use({ "echasnovski/mini.nvim", ext = "mini", after = "nvim-treesitter" })
  use({ "anuvyklack/hydra.nvim", ext = "hydra" })
  use({
    "rcarriga/nvim-notify",
    ext = "notify",
    module = "notify",
    cond = function() return vim.g.notifier_enabled end,
  })
  use({ "nanozuki/tabby.nvim", ext = "tabby" })
  use({
    "lukas-reineke/indent-blankline.nvim",
    cond = false,
    config = function()
      local ibl = require("indent_blankline")

      -- local refresh = ibl.refresh
      -- ibl.refresh = _G.mega.debounce(100, refresh)

      ibl.setup({
        char = "│", -- alts: ┆ ┊  ▎
        show_foldtext = false,
        context_char = "▎",
        char_priority = 12,
        show_current_context = true,
        show_current_context_start = true,
        show_current_context_start_on_current_line = true,
        show_first_indent_level = true,
        filetype_exclude = {
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
      })
    end,
  })

  -- ( Movements ) -------------------------------------------------------------
  use({ "phaazon/hop.nvim", ext = "hop" })
  -- @trial multi-cursor: https://github.com/brendalf/dotfiles/blob/master/.config/nvim/lua/core/multi-cursor.lua
  use({
    "ggandor/leap.nvim",
    config = function()
      require("leap").setup({
        equivalence_classes = { " \t\r\n", "([{", ")]}", "`\"'" },
      })
    end,
  })
  use({
    "ggandor/flit.nvim",
    wants = { "leap.nvim" },
    after = "leap.nvim",
    config = function()
      require("flit").setup({
        keys = { f = "f", F = "F", t = "t", T = "T" },
        -- A string like "nv", "nvo", "o", etc.
        labeled_modes = "nvo",
        multiline = false,
      })
    end,
  })

  -- ( Telescope ) -------------------------------------------------------------
  use({
    "nvim-telescope/telescope.nvim",
    module_pattern = "telescope.*",
    ext = "telescope",
    event = "CursorHold",
  })
  use({
    "nvim-telescope/telescope-file-browser.nvim",
    after = "telescope.nvim",
    config = function() require("telescope").load_extension("file_browser") end,
  })
  use({
    "natecraddock/telescope-zf-native.nvim",
    after = "telescope.nvim",
    config = function() require("telescope").load_extension("zf-native") end,
  })
  use({
    "benfowler/telescope-luasnip.nvim",
    after = "telescope.nvim",
    config = function() require("telescope").load_extension("luasnip") end,
  })
  use({
    "nvim-telescope/telescope-live-grep-args.nvim",
    cond = vim.g.vscode ~= 1,
    after = "telescope.nvim",
    config = function() require("telescope").load_extension("live_grep_args") end,
  })
  use({
    "nvim-telescope/telescope-media-files.nvim",
    after = "telescope.nvim",
    config = function() require("telescope").load_extension("media_files") end,
  })
  -- use({
  --   "ryansch/habitats.nvim",
  --   after = "telescope-file-browser.nvim",
  --   config = function() require("habitats").setup({}) end,
  -- })

  -- ( FZF ) -------------------------------------------------------------------
  use({ "ibhagwan/fzf-lua", ext = "fzf" })

  -- ( Navigation ) ------------------------------------------------------------
  use({
    "knubie/vim-kitty-navigator",
    -- run = "cp ./*.py ~/.config/kitty/",
    cond = function() return not vim.env.TMUX end,
  })
  -- use({ "elihunter173/dirbuf.nvim", config = function() require("dirbuf").setup({}) end })
  use({
    "nvim-neo-tree/neo-tree.nvim",
    ext = "neo-tree",
    keys = { "<C-t>" },
    cmd = { "NeoTree" },
    requires = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      { "mrbjarksen/neo-tree-diagnostics.nvim", module = "neo-tree.sources.diagnostics" },
      { "s1n7ax/nvim-window-picker" },
    },
  })
  -- use({
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
  -- })
  use({ "kevinhwang91/nvim-bqf", ft = "qf" })
  use({
    "https://gitlab.com/yorickpeterse/nvim-pqf",
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
  })

  -- ( Treesitter ) ------------------------------------------------------------
  use({
    "nvim-treesitter/nvim-treesitter",
    event = "User PackerDeferred",
    run = ":TSUpdate",
    -- run = function() require("nvim-treesitter.install").update({ with_sync = true }) end,
    -- cmd = { "TSUpdate", "TSInstallSync" },
    -- event = { "BufRead", "BufNewFile" },
    ext = "treesitter",
  })
  use({ "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" })
  use({ "RRethy/nvim-treesitter-textsubjects", after = "nvim-treesitter" })
  use({ "nvim-treesitter/nvim-tree-docs", after = "nvim-treesitter" })
  use({ "JoosepAlviste/nvim-ts-context-commentstring", after = "nvim-treesitter" })
  use({ "RRethy/nvim-treesitter-endwise", after = "nvim-treesitter" })
  use({ "jadengis/nvim-ts-autotag", after = "nvim-treesitter" })
  use({ "p00f/nvim-ts-rainbow", after = "nvim-treesitter" })
  use({
    "mfussenegger/nvim-treehopper",
    after = "nvim-treesitter",
    config = function()
      require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }
      _G.mega.augroup("TreehopperMaps", {
        {
          event = { "FileType" },
          command = function(args)
            if vim.tbl_contains(require("nvim-treesitter.parsers").available_parsers(), vim.bo[args.buf].filetype) then
              _G.mega.omap("m", ":<C-U>lua require('tsht').nodes()<CR>", { buffer = args.buf })
              _G.mega.vnoremap("m", ":lua require('tsht').nodes()<CR>", { buffer = args.buf })
            end
          end,
        },
      })
    end,
  })
  use({ "David-Kunz/treesitter-unit", after = "nvim-treesitter" })
  use({
    "nvim-treesitter/nvim-treesitter-context",
    after = "nvim-treesitter",
    config = function()
      require("treesitter-context").setup({
        multiline_threshold = 2,
        -- separator = { "─", "ContextBorder" }, -- alts: ▁ ─ ▄
        separator = { "▁", "TreesitterContextBorder" }, -- alts: ▁ ─ ▄─▁
        mode = "topline",
      })
    end,
  })
  use({
    "nvim-treesitter/playground",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    after = "nvim-treesitter",
  })
  use({
    "folke/paint.nvim",
    config = function()
      require("paint").setup({
        highlights = {
          {
            -- filter can be a table of buffer options that should match,
            -- or a function called with buf as param that should return true.
            -- The example below will paint @something in comments with Constant
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%s*(@%w+)",
            hl = "Todo",
          },
          {
            -- filter can be a table of buffer options that should match,
            -- or a function called with buf as param that should return true.
            -- The example below will paint @something in comments with Constant
            filter = { filetype = "lua" },
            pattern = "%s*%-%-%-%s*(@%w+)",
            hl = "Constant",
          },
        },
      })
    end,
  })

  -- ( LSP ) -------------------------------------------------------------------
  use({
    "williamboman/mason.nvim",
    event = "BufRead",
    requires = {
      "nvim-lspconfig",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- require("mason").setup({
      --   ui = {
      --     border = _G.mega.get_border(),
      --     log_level = vim.log.levels.DEBUG,
      --   },
      -- })

      -- require("mega.lsp.servers")()
      local get_config = require("mega.lsp.servers")
      require("mason").setup({
        ui = {
          border = _G.mega.get_border(),
          log_level = vim.log.levels.DEBUG,
        },
      })
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = {
          "bashls",
          "clangd",
          -- "cmake",
          "cssls",
          "dockerls",
          "elixirls",
          "elmls",
          "ember",
          "emmet_ls",
          -- "erlangls",
          "gopls",
          "html",
          "jsonls",
          -- "marksman",
          "pyright",
          "rust_analyzer",
          "solargraph",
          -- "sqlls",
          "sumneko_lua",
          "tailwindcss",
          "terraformls",
          "tsserver",
          "vimls",
          "yamlls",
          "zk",
          "zls",
        },
      })
      require("mason-lspconfig").setup_handlers({
        function(name)
          local cfg = get_config(name)
          if cfg then
            -- vim.notify(fmt("Found lsp config for %s", name), vim.log.levels.INFO, { title = "mason-lspconfig" })
            require("lspconfig")[name].setup(cfg)
          end
        end,
      })
    end,
  })
  -- use({
  --   "jayp0521/mason-null-ls.nvim",
  --   requires = {
  --     "williamboman/mason.nvim",
  --     "jose-elias-alvarez/null-ls.nvim",
  --   },
  --   after = "mason.nvim",
  --   config = function()
  --     require("mason-null-ls").setup({
  --       automatic_installation = true,
  --       ensure_installed = {
  --         "beautysh",
  --       },
  --     })
  --   end,
  -- })
  use({
    "neovim/nvim-lspconfig",
    module_pattern = "lspconfig.*",
    requires = {
      -- having this one installed just makes neovim api docs available
      -- via LSP, don't need to actually do anything with it
      "folke/neodev.nvim",
    },
    config = function() require("lspconfig.ui.windows").default_options.border = _G.mega.get_border() end,
  })

  use({
    "theHamsta/nvim-semantic-tokens",
    after = "nvim-lspconfig",
    config = function()
      require("nvim-semantic-tokens").setup({
        preset = "default",
        -- highlighters is a list of modules following the interface of nvim-semantic-tokens.table-highlighter or
        -- function with the signature: highlight_token(ctx, token, highlight) where
        --        ctx (as defined in :h lsp-handler)
        --        token  (as defined in :h vim.lsp.semantic_tokens.on_full())
        --        highlight (a helper function that you can call (also multiple times) with the determined highlight group(s) as the only parameter)
        highlighters = { require("nvim-semantic-tokens.table-highlighter") },
      })
    end,
  })

  use({ "jose-elias-alvarez/null-ls.nvim", ext = "null-ls", requires = { "nvim-lua/plenary.nvim" } })
  use({ "SmiteshP/nvim-navic", after = "nvim-lspconfig", requires = "neovim/nvim-lspconfig" })

  -- use({
  --   "issafalcon/lsp-overloads.nvim",
  --   after = "nvim-lspconfig",
  --   config = function()
  --     require("lsp-overloads").setup({
  --       ui = {
  --         -- The border to use for the signature popup window. Accepts same border values as |nvim_open_win()|.
  --         border = mega.get_border(),
  --       },
  --     })
  --   end,
  -- })

  -- use({
  --   "ray-x/lsp_signature.nvim",
  --   after = "nvim-lspconfig",
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
  -- })

  use({ "nvim-lua/lsp_extensions.nvim" })
  use({ "jose-elias-alvarez/nvim-lsp-ts-utils" })
  use({ "b0o/schemastore.nvim" })
  use({ "mrshmllow/document-color.nvim" })
  -- use({ "lewis6991/hover.nvim" })
  -- use({ "folke/lua-dev.nvim", module = "lua-dev" })
  -- use({ "microsoft/python-type-stubs", opt = true })
  -- use({ "lvimuser/lsp-inlayhints.nvim" })

  -- ( Git ) -------------------------------------------------------------------
  use({ "lewis6991/gitsigns.nvim", event = { "BufRead" }, ext = "gitsigns" })
  use({
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
    requires = "plenary.nvim",
  })
  -- use({ "sindrets/diffview.nvim", ext="diffview" })
  use({
    "akinsho/git-conflict.nvim",
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
  })
  -- use({ "itchyny/vim-gitbranch" })
  -- use({ "rhysd/git-messenger.vim" })
  -- use({ "tpope/vim-fugitive" })
  use({
    "ruifm/gitlinker.nvim",
    requires = "plenary.nvim",
    keys = {
      { "n", "<localleader>gu", "gitlinker: copy to clipboard" },
      { "n", "<localleader>go", "gitlinker: open in browser" },
    },
    config = function()
      local linker = require("gitlinker")
      linker.setup({ mappings = "<localleader>gu" })
      mega.nnoremap(
        "<localleader>go",
        function() linker.get_repo_url({ action_callback = require("gitlinker.actions").open_in_browser }) end,
        "gitlinker: open in browser"
      )
    end,
  })
  use({
    "ruanyl/vim-gh-line",
    config = function()
      if vim.fn.exists("g:loaded_gh_line") then
        vim.g["gh_line_map_default"] = 0
        vim.g["gh_line_blame_map_default"] = 0
        vim.g["gh_line_map"] = "<leader>gH"
        vim.g["gh_line_blame_map"] = "<leader>gB"
        vim.g["gh_repo_map"] = "<leader>gO"
        -- Use a custom program to open link:
        -- let g:gh_open_command = 'open '
        -- Copy link to a clipboard instead of opening a browser:
        -- let g:gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '
      end
    end,
  })

  -- ( Completion ) ------------------------------------------------------------
  use({ "rafamadriz/friendly-snippets" })
  use({ "L3MON4D3/LuaSnip", after = "friendly-snippets", module = "luasnip", ext = "luasnip" })
  use({
    "hrsh7th/nvim-cmp",
    ext = "cmp",
    -- after = "LuaSnip",
    module = "cmp",
    requires = {
      { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
      { "hrsh7th/cmp-buffer", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp", module = "cmp_nvim_lsp" },
      { "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
      { "hrsh7th/cmp-path", after = "nvim-cmp" },
      { "hrsh7th/cmp-emoji", after = "nvim-cmp" },
      { "f3fora/cmp-spell", after = "nvim-cmp" },
      { "hrsh7th/cmp-cmdline", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
      -- { "dmitmel/cmp-cmdline-history", after = "nvim-cmp" },
      { "lukas-reineke/cmp-rg", after = "nvim-cmp" },
      -- { "kristijanhusak/vim-dadbod-completion", after = "nvim-cmp" },
    },
  })

  -- ( Testing/Debugging ) -----------------------------------------------------
  use({ "vim-test/vim-test", ext = "vim-test" })
  use({
    "mfussenegger/nvim-dap",
    module = "dap",
    ext = "dap",
  })
  use({
    "theHamsta/nvim-dap-virtual-text",
    after = "nvim-dap",
    config = function()
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })
    end,
  })
  use({ "rcarriga/nvim-dap-ui", ext = "dapui", after = "nvim-dap" })
  use({ "jbyuki/one-small-step-for-vimkind", after = "nvim-dap" })
  use({ "suketa/nvim-dap-ruby", after = "nvim-dap", config = function() require("dap-ruby").setup() end })
  -- use({
  --   "microsoft/vscode-js-debug",
  --   run = "npm install --legacy-peer-deps && npm run compile",
  -- })
  use({
    "mxsdev/nvim-dap-vscode-js",
    after = "nvim-dap",
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
  })
  use({ "sultanahamer/nvim-dap-reactnative", after = "nvim-dap" })
  -- use({ "microsoft/vscode-react-native", after = "nvim-dap" })
  -- use({
  --   "jayp0521/mason-nvim-dap.nvim",
  --   after = "nvim-dap",
  --   config = function()
  --     require("mason-nvim-dap").setup({
  --       ensure_installed = { "python", "node2", "chrome", "firefox" },
  --       automatic_installation = true,
  --     })
  --   end,
  -- })

  -- ( Development ) -----------------------------------------------------------
  use({
    "chipsenkbeil/distant.nvim",
    tag = "v0.2",
    run = ":DistantInstall",
    config = function()
      require("distant").setup({
        -- Applies Chip's personal settings to every machine you connect to
        --
        -- 1. Ensures that distant servers terminate with no connections
        -- 2. Provides navigation bindings for remote directories
        -- 3. Provides keybinding to jump into a remote file's parent directory
        ["*"] = require("distant.settings").chip_default(),
      })
    end,
  })
  use({ "akinsho/toggleterm.nvim", ext = "toggleterm" })
  use({ "danymat/neogen" })
  use({
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    requires = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    setup = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  })
  use({
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
  })
  use({ "tpope/vim-projectionist", ext = "projectionist" })
  use({
    "andymass/vim-matchup",
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
  })
  -- use({
  --   "windwp/nvim-autopairs",
  --   after = "nvim-treesitter",
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
  -- })
  use({
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  })
  use({
    "natecraddock/sessions.nvim",
    config = function()
      require("sessions").setup({
        events = { "VimLeavePre" },
        session_filepath = vim.fn.stdpath("data") .. "/sessions/default",
      })
    end,
  })
  use({
    "natecraddock/workspaces.nvim",
    after = "telescope.nvim",
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
  })
  use({ "editorconfig/editorconfig-vim" })
  use({ "mhartington/formatter.nvim", ext = "formatter" })
  use({ "alvan/vim-closetag" })
  use({ "tpope/vim-eunuch" })
  use({
    "tpope/vim-abolish",
    config = function()
      nnoremap("<localleader>[", ":S/<C-R><C-W>//<LEFT>", { silent = false })
      nnoremap("<localleader>]", ":%S/<C-r><C-w>//c<left><left>", { silent = false })
      xnoremap("<localleader>[", [["zy:'<'>S/<C-r><C-o>"//c<left><left>]], { silent = false })
    end,
  })
  use({ "tpope/vim-rhubarb" })
  use({ "tpope/vim-repeat" })
  use({ "tpope/vim-unimpaired" })
  use({ "tpope/vim-apathy" })
  use({ "tpope/vim-scriptease" })
  use({ "lambdalisue/suda.vim" })
  use({ "EinfachToll/DidYouMean" })
  use({ "wsdjeg/vim-fetch" }) -- vim path/to/file.ext:12:3
  use({ "ConradIrwin/vim-bracketed-paste" }) -- FIXME: delete?
  -- use({ "tpope/vim-scriptease" })
  use({ "axelvc/template-string.nvim" })
  -- @trial: "jghauser/kitty-runner.nvim"

  -- ( Motions/Textobjects ) ---------------------------------------------------
  -- use({
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
  -- })
  use({
    "abecodes/tabout.nvim",
    wants = { "nvim-treesitter" },
    after = { "nvim-cmp" },
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
  })

  -- ( Notes/Docs ) ------------------------------------------------------------
  -- use({ "ixru/nvim-markdown" })
  use({ "iamcco/markdown-preview.nvim", ft = "md", run = "cd app && yarn install" })
  use({
    "toppair/peek.nvim",
    run = "deno task --quiet build:fast",
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
  })
  use({ "mickael-menu/zk-nvim", ext = "zk", after = "telescope.nvim" })
  use({
    "gaoDean/autolist.nvim",
    config = function() require("autolist").setup({ normal_mappings = { invert = { "<c-c>" } } }) end,
  })
  use({ "ellisonleao/glow.nvim" })
  use({
    "lukas-reineke/headlines.nvim",
    after = "nvim-treesitter",
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
  })
  -- @trial phaazon/mind.nvim
  -- @trial "renerocksai/telekasten.nvim"
  -- @trial ekickx/clipboard-image.nvim
  -- @trial preservim/vim-wordy
  -- @trial jghauser/follow-md-links.nvim
  -- @trial jakewvincent/mkdnflow.nvim
  -- @trial jubnzv/mdeval.nvim
  -- "dkarter/bullets.vim"
  -- "dhruvasagar/vim-table-mode"
  -- "rhysd/vim-gfm-syntax"

  -- ( Syntax/Languages ) ------------------------------------------------------
  use({ "ii14/emmylua-nvim" })
  use({ "elixir-editors/vim-elixir" })
  -- use({ "tpope/vim-rails" })
  -- use({ "ngscheurich/edeex.nvim" })
  -- use({ "antew/vim-elm-analyse" })
  -- use({ "tjdevries/nlua.nvim" })
  -- use({ "norcalli/nvim.lua" })
  -- -- use({ "euclidianace/betterlua.vim" })
  -- -- use({ "folke/lua-dev.nvim" })
  -- use({ "milisims/nvim-luaref" })
  -- use({ "ii14/emmylua-nvim" })
  -- use({ "MaxMEllon/vim-jsx-pretty" })
  -- use({ "heavenshell/vim-jsdoc" })
  -- use({ "jxnblk/vim-mdx-js" })
  -- use({ "kchmck/vim-coffee-script" })
  -- use({ "briancollins/vim-jst" })
  -- use({ "skwp/vim-html-escape" })
  -- use({ "pedrohdz/vim-yaml-folds" })
  -- use({ "avakhov/vim-yaml" })
  -- use({ "chr4/nginx.vim" })
  -- use({ "nanotee/luv-vimdocs" })
  use({ "fladson/vim-kitty" })
  use({ "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end })

  use({
    "glacambre/firenvim",
    run = function() vim.fn["firenvim#install"](0) end,
    ext = "firenvim",
  })
end

-- [ COMMANDS ] ----------------------------------------------------------------
mega.command("PackerCompiledEdit", function() vim.cmd.vnew(vim.g.packer_compiled_path) end)
mega.command("PackerCompiledDelete", function()
  vim.fn.delete(vim.g.packer_compiled_path)
  packer_notify(string.format("deleted %s", vim.g.packer_compiled_path))
end)
mega.command("PackerUpgrade", function()
  vim.schedule(function()
    require("mega.plugins.utils").bootstrap()
    require("mega.plugins.utils").sync()
  end)
end)
mega.command("PackerCompile", function()
  vim.cmd("packadd! packer.nvim")
  vim.notify("waiting for compilation..", vim.log.levels.INFO, { title = "packer" })
  require("packer").compile()
end, { nargs = "*" })
mega.command("Recompile", function() mega.recompile() end, { nargs = "*" })
mega.command("Reload", function() mega.reload() end, { nargs = "*" })
mega.command("PR", [[Recompile]], { nargs = "*" })
mega.command("PC", [[PackerCompile]], { nargs = "*" })
mega.command("PS", [[PackerSync]], { nargs = "*" })
mega.command("PU", [[PackerSync]], { nargs = "*" })
mega.command("PackerInstall", [[packadd! packer.nvim | lua require('packer').install()]], { nargs = "*" })
mega.command("PackerUpdate", [[packadd! packer.nvim | lua require('packer').update()]], { nargs = "*" })
mega.command("PackerSync", [[packadd! packer.nvim | lua require('packer').sync()]], { nargs = "*" })
mega.command("PackerClean", [[packadd! packer.nvim | lua require('packer').clean()]], { nargs = "*" })

if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(vim.g.packer_compiled_path) then
  vim.cmd.source(vim.g.packer_compiled_path)
  vim.g.packer_compiled_loaded = true
end

mega.nnoremap("<leader>ps", "<Cmd>PackerSync<CR>", "packer: sync")
mega.nnoremap("<leader>pc", "<Cmd>PackerCompile<CR>", "packer: compile")
mega.nnoremap("<leader>pr", "<Cmd>Reload<CR>", "packer: reload")
mega.nnoremap("<leader>px", "<Cmd>PackerClean<CR>", "packer: clean")

vim.cmd.packadd({ "cfilter", bang = true })
mega.require("impatient")

return packer.setup(config, plugins)
