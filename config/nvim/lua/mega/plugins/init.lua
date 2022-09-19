local PACKER_COMPILED_PATH = fmt("%s/packer/packer_compiled.lua", vim.fn.stdpath("cache"))
local PACKER_SNAPSHOTS_PATH = fmt("%s/packer/snapshots/", vim.fn.stdpath("cache"))

local mega = _G.mega or require("mega.globals")

local packer = require("mega.plugins.utils")
local packer_notify = packer.notify

local config = {
  display = {
    -- open_fn = function() return require("packer.util").float({ border = mega.get_border() }) end,
    open_cmd = "silent topleft 65vnew",
  },
  -- opt_default = true,
  auto_reload_compiled = false,
  non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
  compile_path = PACKER_COMPILED_PATH,
  snapshot_path = PACKER_SNAPSHOTS_PATH,
  preview_updates = true,
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
    -- ["null-ls.nvim"] = false,
    -- ["nvim-lspconfig"] = false,
    -- ["nvim-treesitter"] = true,
  },
}

local function plugins(use)
  --print(fmt("use plugin within plugins: %s", I(use)))
  -- packer can manage itself as an optional plugin
  use({ "wbthomason/packer.nvim", opt = true })

  -- ( CORE ) ------------------------------------------------------------------
  use({ "lewis6991/impatient.nvim" })
  use({ "nvim-lua/plenary.nvim" })
  use({ "nvim-lua/popup.nvim" })
  use({ "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end })
  use({ "mattn/webapi-vim" })

  -- ( UI ) --------------------------------------------------------------------
  use({ "rktjmp/lush.nvim" })
  use({ "dm1try/golden_size", ext = "golden_size" })
  use({ "kyazdani42/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end })
  use({
    "NvChad/nvim-colorizer.lua",
    event = "BufRead",
    config = function()
      require("colorizer").setup({
        filetypes = { "*" },
        user_default_options = {
          RGB = true, -- #RGB hex codes
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
    end,
  })
  use({ "lukas-reineke/virt-column.nvim" })
  use({ "MunifTanjim/nui.nvim" })
  use({ "folke/which-key.nvim", ext = "which-key" })
  -- use({ "echasnovski/mini.nvim", ext="mini", after = "nvim-treesitter" })
  use({ "phaazon/hop.nvim", ext = "hop" })
  -- use({ "jghauser/fold-cycle.nvim" })
  use({ "anuvyklack/hydra.nvim", ext = "hydra" })
  use({ "rcarriga/nvim-notify", ext = "notify" })
  use({ "nanozuki/tabby.nvim", ext = "tabby" })
  use({
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require("indent_blankline").setup({
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
  -- use({
  --   "levouh/tint.nvim",
  --   event = "BufRead",
  --   config = function()
  --     require("tint").setup({
  --       tint = -50,
  --       highlight_ignore_patterns = {
  --         "WinSeparator",
  --         "St.*",
  --         "Comment",
  --         "Panel.*",
  --         "Telescope.*",
  --         "Bqf.*",
  --         "Cursor.*",
  --       },
  --       window_ignore_function = function(win_id)
  --         if vim.wo[win_id].diff or vim.fn.win_gettype(win_id) ~= "" then return true end
  --         local buf = vim.api.nvim_win_get_buf(win_id)
  --         local b = vim.bo[buf]
  --         local ignore_bt = { "megaterm", "terminal", "prompt", "nofile" }
  --         local ignore_ft =
  --           { "neo-tree", "packer", "diff", "megaterm", "toggleterm", "Neogit.*", "Telescope.*", "qf" }
  --         return mega.any(b.bt, ignore_bt) or mega.any(b.ft, ignore_ft)
  --       end,
  --     })
  --   end,
  -- })

  -- ( Telescope ) -------------------------------------------------------------
  use({
    "nvim-telescope/telescope.nvim",
    -- module_pattern = "telescope.*",
    ext = "telescope",
    event = "CursorHold",
    requires = {
      {
        "nvim-telescope/telescope-file-browser.nvim",
        after = "telescope.nvim",
        -- config = function() require("telescope").load_extension("file_browser") end,
      },
      {
        "natecraddock/telescope-zf-native.nvim",
        after = "telescope.nvim",
        -- config = function() require("telescope").load_extension("zf-native") end,
      },
      {
        "benfowler/telescope-luasnip.nvim",
        after = "telescope.nvim",
        -- config = function() require("telescope").load_extension("luasnip") end,
      },
    },
  })
  -- use({
  --   "nvim-telescope/telescope-file-browser.nvim",
  --   after = "telescope.nvim",
  --   config = function() require("telescope").load_extension("file_browser") end,
  -- })
  -- use({
  --   "natecraddock/telescope-zf-native.nvim",
  --   after = "telescope.nvim",
  --   config = function() require("telescope").load_extension("zf-native") end,
  -- })
  -- use({
  --   "benfowler/telescope-luasnip.nvim",
  --   after = "telescope.nvim",
  --   config = function() require("telescope").load_extension("luasnip") end,
  -- })

  -- ( Navigation ) ------------------------------------------------------------
  use({
    "knubie/vim-kitty-navigator",
    -- run = "cp ./*.py ~/.config/kitty/",
    cond = function() return not vim.env.TMUX end,
  })
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
    run = ":TSUpdate",
    -- run = function()
    --   if vim.fn.exists(":TSUpdate") == 2 then vim.cmd(":TSUpdate") end
    -- end,
    cmd = { "TSUpdate", "TSInstallSync" },
    event = { "BufRead", "BufNewFile" },
    ext = "treesitter",
  })
  use({ "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" })
  use({ "RRethy/nvim-treesitter-textsubjects", after = "nvim-treesitter" })
  use({ "nvim-treesitter/nvim-tree-docs", after = "nvim-treesitter" })
  use({ "JoosepAlviste/nvim-ts-context-commentstring", after = "nvim-treesitter" })
  use({ "windwp/nvim-ts-autotag", after = "nvim-treesitter" })
  use({ "p00f/nvim-ts-rainbow", after = "nvim-treesitter" })
  use({ "mfussenegger/nvim-treehopper", after = "nvim-treesitter" })
  use({ "David-Kunz/treesitter-unit", after = "nvim-treesitter" })
  use({
    "nvim-treesitter/nvim-treesitter-context",
    after = "nvim-treesitter",
    -- config = function()
    --   require("treesitter-context").setup({
    --     multiline_threshold = 4,
    --     separator = { "─", "ContextBorder" }, -- alts: ▁ ─ ▄
    --     mode = "topline",
    --   })
    -- end,
  })
  use({
    "nvim-treesitter/playground",
    cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
    after = "nvim-treesitter",
  })

  -- ( LSP ) -------------------------------------------------------------------
  use({ "williamboman/mason.nvim", requires = { "nvim-lspconfig", "williamboman/mason-lspconfig.nvim" } })
  use({ "williamboman/mason-lspconfig.nvim" })
  -- TODO: https://github.com/akinsho/dotfiles/commit/6940c6dcf66e08fcaf31da6b4ffba06697ec6f43
  use({
    "neovim/nvim-lspconfig", --[[module_pattern = "lspconfig.*"]]
  })
  use({ "jose-elias-alvarez/null-ls.nvim", ext = "null-ls" })
  use({
    "ray-x/lsp_signature.nvim",
    after = "nvim-lspconfig",
    config = function()
      local border = require("mega.globals").get_border
      require("lsp_signature").setup({
        bind = true,
        fix_pos = false,
        -- auto_close_after = 15, -- close after 15 seconds
        hint_enable = false,
        -- floating_window = true,
        handler_opts = { border = border() },
        -- bind = true,
        -- always_trigger = false,
        -- fix_pos = false,
        -- auto_close_after = 5,
        -- hint_enable = false,
        -- handler_opts = {
        --   anchor = "SW",
        --   relative = "cursor",
        --   row = -1,
        --   focus = false,
        --   border = mega.get_border(),
        -- },
        -- zindex = 99, -- Keep signature popup below the completion PUM
        -- toggle_key = "<C-k>",
      })
    end,
  })
  use({ "nvim-lua/lsp_extensions.nvim" })
  use({ "jose-elias-alvarez/nvim-lsp-ts-utils" })
  use({ "b0o/schemastore.nvim" })
  use({ "mrshmllow/document-color.nvim" })
  -- use({
  --   "j-hui/fidget.nvim",
  --   disable = true,
  --   config = function()
  --     require("fidget").setup({
  --       text = {
  --         spinner = "dots_pulse",
  --         done = "",
  --       },
  --       window = {
  --         blend = 10,
  --         -- relative = "editor",
  --       },
  --       sources = { -- Sources to configure
  --         ["elixirls"] = { -- Name of source
  --           ignore = true, -- Ignore notifications from this source
  --         },
  --         ["markdown"] = { -- Name of source
  --           ignore = true, -- Ignore notifications from this source
  --         },
  --       },
  --       align = {
  --         bottom = false,
  --         right = true,
  --       },
  --       fmt = {
  --         stack_upwards = false,
  --       },
  --     })
  --     require("mega.globals").augroup("CloseFidget", {
  --       {
  --         event = { "VimLeavePre", "LspDetach" },
  --         command = "silent! FidgetClose",
  --       },
  --     })
  --   end,
  -- })
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
  use({ "rafamadriz/friendly-snippets", event = "InsertEnter" })
  use({ "L3MON4D3/LuaSnip", after = "friendly-snippets", module = "luasnip" })
  use({
    "hrsh7th/nvim-cmp",
    ext = "cmp",
    after = "LuaSnip",
    module = "cmp",
    event = "InsertEnter",
    requires = {
      { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
      { "hrsh7th/cmp-buffer", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp", module = "cmp_nvim_lsp" },
      -- { "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
      { "hrsh7th/cmp-path", after = "nvim-cmp" },
      { "hrsh7th/cmp-emoji", after = "nvim-cmp" },
      { "f3fora/cmp-spell", after = "nvim-cmp" },
      { "hrsh7th/cmp-cmdline", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
      { "dmitmel/cmp-cmdline-history", after = "nvim-cmp" },
      { "lukas-reineke/cmp-rg", tag = "*", after = "nvim-cmp" },
    },
  })

  -- ( Testing/Debugging ) -----------------------------------------------------
  use({ "vim-test/vim-test", ext = "vim-test" })
  use({ "mfussenegger/nvim-dap", module = "dap", ext = "dap" })
  use({ "theHamsta/nvim-dap-virtual-text", after = "nvim-dap" })
  use({ "rcarriga/nvim-dap-ui", ext = "dapui", after = "nvim-dap" })
  use({ "jbyuki/one-small-step-for-vimkind", after = "nvim-dap" })
  use({ "suketa/nvim-dap-ruby", after = "nvim-dap" })
  use({ "mxsdev/nvim-dap-vscode-js", after = "nvim-dap" })
  use({ "sultanahamer/nvim-dap-reactnative", after = "nvim-dap" })
  -- use({ "microsoft/vscode-react-native", after = "nvim-dap" })
  use({ "Pocco81/DAPInstall.nvim", after = "nvim-dap" })

  -- ( Development ) -----------------------------------------------------------
  use({ "danymat/neogen" })
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
  use({
    "windwp/nvim-autopairs",
    after = "nvim-cmp",
    requires = "nvim-cmp",
    config = function()
      require("nvim-autopairs").setup({
        disable_filetype = { "TelescopePrompt" },
        -- enable_afterquote = true, -- To use bracket pairs inside quotes
        enable_check_bracket_line = true, -- Check for closing brace so it will not add a close pair
        disable_in_macro = false,
        close_triple_quotes = true,
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          java = false,
        },
      })
      require("nvim-autopairs").add_rules(require("nvim-autopairs.rules.endwise-ruby"))
      local endwise = require("nvim-autopairs.ts-rule").endwise
      require("nvim-autopairs").add_rules({
        endwise("do$", "end", "lua", nil),
        endwise("then$", "end", "lua", "if_statement"),
        endwise("function%(.*%)$", "end", "lua", nil),
        endwise(" do$", "end", "elixir", nil),
      })

      require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
      -- REF: neat stuff:
      -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
    end,
  })
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
    end,
  })
  use({ "ryansch/habitats.nvim", after = "telescope.nvim", config = function() require("habitats").setup({}) end })
  use({ "editorconfig/editorconfig-vim" })
  use({ "mhartington/formatter.nvim", ext = "formatter" })
  use({ "alvan/vim-closetag" })
  use({ "tpope/vim-eunuch" })
  use({ "tpope/vim-abolish" })
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
  use({
    "kylechui/nvim-surround",
    config = function()
      require("nvim-surround").setup({

        highlight = { -- Highlight before inserting/changing surrounds
          duration = 1,
        },
      })
    end,
  })
  use({
    "abecodes/tabout.nvim",
    wants = { "nvim-treesitter" },
    after = { "nvim-cmp" },
    config = function()
      require("tabout").setup({

        ignore_beginning = false,
        completion = false,
      })
    end,
  })

  -- ( Notes/Docs ) ------------------------------------------------------------
  use({ "ixru/nvim-markdown" })
  use({ "iamcco/markdown-preview.nvim", ft = "md", run = "cd app && yarn install" })
  use({ "mickael-menu/zk-nvim", ext = "zk", after = "telescope.nvim" })
  use({ "gaoDean/autolist.nvim" })
  use({ "ellisonleao/glow.nvim" })
  use({
    "lukas-reineke/headlines.nvim",
    config = function()
      require("headlines").setup({
        markdown = {
          source_pattern_start = "^```",
          source_pattern_end = "^```$",
          dash_pattern = "^---+$",
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
  -- use({ "elixir-editors/vim-elixir" })
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
end

mega.command("PackerCompiledEdit", function() vim.cmd.edit(PACKER_COMPILED_PATH) end)

mega.command("PackerCompiledDelete", function()
  vim.fn.delete(PACKER_COMPILED_PATH)
  packer_notify(string.format("Deleted %s", PACKER_COMPILED_PATH))
end)

if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(PACKER_COMPILED_PATH) then
  vim.cmd.source(PACKER_COMPILED_PATH)
  vim.g.packer_compiled_loaded = true
end

mega.nnoremap("<leader>ps", "<Cmd>PackerSync<CR>", "packer: sync")
mega.nnoremap("<leader>pc", "<Cmd>PackerCompile<CR>", "packer: compile")

vim.cmd.packadd({ "cfilter", bang = true })
mega.require("impatient")

return packer.setup(config, plugins)
