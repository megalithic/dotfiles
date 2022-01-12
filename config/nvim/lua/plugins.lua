local api = vim.api
local vcmd = vim.cmd
local fn = vim.fn

-- local C = require("colors")

-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs
-- # local/devel paqs stored here:
--  ~/.local/share/nvim/site/pack/local

local M = {}

M.list = {
  { "savq/paq-nvim" },

  ------------------------------------------------------------------------------
  -- (profiling/speed improvements) --
  "dstein64/vim-startuptime",
  "lewis6991/impatient.nvim",
  "nathom/filetype.nvim",

  ------------------------------------------------------------------------------
  -- (appearance/UI/visuals) --
  "rktjmp/lush.nvim",
  "mhanberg/thicc_forest",
  "norcalli/nvim-colorizer.lua",
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  "edluffy/specs.nvim",
  "antoinemadec/FixCursorHold.nvim", -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
  -- "karb94/neoscroll.nvim",
  "lukas-reineke/indent-blankline.nvim",
  "MunifTanjim/nui.nvim",
  "stevearc/dressing.nvim",
  "goolord/alpha-nvim",
  { "zeertzjq/which-key.nvim", branch = "patch-1" },
  "ojroques/nvim-bufdel",

  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
  -- "williamboman/nvim-lsp-installer", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L229-L244
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-nvim-lua",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-emoji",
  "f3fora/cmp-spell",
  "hrsh7th/cmp-nvim-lsp-document-symbol",

  -- for fuzzy things in nvim-cmp and command:
  "tzachar/fuzzy.nvim",
  "tzachar/cmp-fuzzy-path",
  "tzachar/cmp-fuzzy-buffer",
  --

  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  "folke/trouble.nvim",
  "abecodes/tabout.nvim",
  { url = "https://gitlab.com/yorickpeterse/nvim-dd.git" },

  ------------------------------------------------------------------------------
  -- (treesitter) --
  {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      vim.cmd("TSUpdate")
    end,
  },
  "nvim-treesitter/playground",
  "mfussenegger/nvim-treehopper",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  "SmiteshP/nvim-gps",
  "RRethy/nvim-treesitter-textsubjects",
  "David-Kunz/treesitter-unit",
  -- "primeagen/harpoon",
  -- "romgrk/nvim-treesitter-context",

  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  "ggandor/lightspeed.nvim",
  "voldikss/vim-floaterm",
  "kyazdani42/nvim-tree.lua",

  "tami5/sqlite.lua",
  "nvim-telescope/telescope.nvim",
  "nvim-telescope/telescope-frecency.nvim",
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "camgraff/telescope-tmux.nvim",
  "nvim-telescope/telescope-media-files.nvim",
  "nvim-telescope/telescope-symbols.nvim",
  "nvim-telescope/telescope-smart-history.nvim",
  "nvim-telescope/telescope-file-browser.nvim",

  ------------------------------------------------------------------------------
  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-textobj-user",
  "kana/vim-operator-user",
  -- "mattn/vim-textobj-url", -- au/iu for url; FIXME: not working presently
  "jceb/vim-textobj-uri", -- au/iu for url
  "whatyouhide/vim-textobj-xmlattr",
  "amiralies/vim-textobj-elixir",
  "kana/vim-textobj-entire", -- ae/ie for entire buffer
  "Julian/vim-textobj-variable-segment", -- av/iv for variable segment
  "beloglazov/vim-textobj-punctuation", -- au/iu for punctuation
  "michaeljsmith/vim-indent-object", -- ai/ii for indentation area
  -- "chaoren/vim-wordmotion", -- to move across cases and words and such
  "wellle/targets.vim",
  -- research: windwp/nvim-spectre

  ------------------------------------------------------------------------------
  -- (GIT, vcs, et al) --
  -- {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "mattn/webapi-vim",
  "rhysd/conflict-marker.vim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "sindrets/diffview.nvim",
  "tpope/vim-fugitive",
  -- "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  "pwntester/octo.nvim", -- https://github.com/ryansch/dotfiles/commit/2d0dc63bea2f921de1236c2800605551fb4b3041#diff-45b8a59e398d12063977c5b27e0d065150544908fd4ad8b3e10b2d003c5f4439R119-R246
  -- "gabebw/vim-github-link-opener",
  "ruifm/gitlinker.nvim",
  "rlch/github-notifications.nvim",

  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  -- "ahmedkhalf/project.nvim",
  "tpope/vim-projectionist",
  -- "tjdevries/edit_alternate.vim",
  "janko/vim-test", -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "tpope/vim-ragtag",
  -- { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  "vuki656/package-info.nvim",
  -- "jamestthompson3/nvim-remote-containers",
  "chipsenkbeil/distant.nvim",
  "tpope/vim-dadbod",
  "kristijanhusak/vim-dadbod-completion",
  "kristijanhusak/vim-dadbod-ui",
  {
    "glacambre/firenvim",
    run = function()
      vim.fn["firenvim#install"](0)
    end,
  },

  ------------------------------------------------------------------------------
  -- (the rest...) --
  "nacro90/numb.nvim",
  "ethanholz/nvim-lastplace",
  "andymass/vim-matchup", -- https://github.com/andymass/vim-matchup#tree-sitter-integration
  "windwp/nvim-autopairs",
  "alvan/vim-closetag",
  "numToStr/Comment.nvim",
  "tpope/vim-eunuch",
  "tpope/vim-abolish",
  "tpope/vim-rhubarb",
  "tpope/vim-repeat",
  "tpope/vim-surround",
  "tpope/vim-unimpaired",
  "danro/rename.vim",
  "lambdalisue/suda.vim",
  "EinfachToll/DidYouMean",
  "wsdjeg/vim-fetch", -- vim path/to/file.ext:12:3
  "ConradIrwin/vim-bracketed-paste", -- FIXME: delete?
  -- "kevinhwang91/nvim-hclipboard",
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  "tpope/vim-scriptease",
  "sunaku/tmux-navigate",
  -- "tmux-plugins/vim-tmux-focus-events",
  "junegunn/vim-slash",
  "junegunn/vim-easy-align",
  -- use_with_config("svermeulen/vim-cutlass", "cutlass") -- separates cut and delete operations
  --     use_with_config("svermeulen/vim-yoink", "yoink") -- improves paste

  ------------------------------------------------------------------------------
  -- (LANGS, syntax, et al) --
  -- # markdown/prose
  -- "plasticboy/vim-markdown", -- replacing with the below:
  "ixru/nvim-markdown",
  -- "rhysd/vim-gfm-syntax",
  { "iamcco/markdown-preview.nvim", run = "cd app && yarn install" },
  "ellisonleao/glow.nvim",
  { "harshad1/bullets.vim", branch = "performance_improvements" },
  "kristijanhusak/orgmode.nvim",
  "akinsho/org-bullets.nvim",
  "lervag/vim-rainbow-lists", -- :RBListToggle
  "dhruvasagar/vim-table-mode",
  "lukas-reineke/headlines.nvim",
  -- https://github.com/preservim/vim-wordy
  -- https://github.com/jghauser/follow-md-links.nvim
  -- https://github.com/jakewvincent/mkdnflow.nvim
  -- https://github.com/jubnzv/mdeval.nvim
  -- "NFrid/due.nvim",
  "mickael-menu/zk-nvim",
  "renerocksai/calendar-vim",
  "renerocksai/telekasten.nvim",
  -- # ruby/rails
  "tpope/vim-rails",
  -- # elixir
  "elixir-editors/vim-elixir",
  "ngscheurich/edeex.nvim",
  -- # elm
  "antew/vim-elm-analyse",
  -- # lua
  "tjdevries/nlua.nvim",
  "norcalli/nvim.lua",
  "euclidianace/betterlua.vim",
  "folke/lua-dev.nvim",
  "andrejlevkovitch/vim-lua-format",
  "milisims/nvim-luaref",
  -- # JS/TS/JSON
  "MaxMEllon/vim-jsx-pretty",
  "heavenshell/vim-jsdoc",
  "jxnblk/vim-mdx-js",
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  -- # HTML
  -- "mattn/emmet-vim",
  "skwp/vim-html-escape",
  "pedrohdz/vim-yaml-folds",
  -- # misc
  "avakhov/vim-yaml",
  "chr4/nginx.vim",
  "nanotee/luv-vimdocs",
  "fladson/vim-kitty",
  "SirJson/fzf-gitignore",
}

M.listy = function()
  return M.list
end

M.setup = function()
  do -- vim-startuptime
    vim.g.startuptime_tries = 10
  end

  do
    require("dressing").setup({
      select = {
        telescope = {
          theme = "cursor",
        },
      },
    })
  end

  -- do -- which-key
  --   local wk = require("which-key")
  --   local gl = require("gitlinker")
  --   local gla = require("gitlinker.actions")

  --   -- alt modes
  --   wk.register({
  --     ["<leader>"] = {
  --       g = {
  --         l = {
  --           function()
  --             gl.get_buf_range_url("v", {
  --               action_callback = gla.open_in_browser,
  --             })
  --           end,
  --           "Web Link",
  --           mode = "v",
  --         },
  --       },
  --       c = {
  --         s = { "<cmd>Sort<cr>", "Sort", mode = "v" },
  --       },
  --     },
  --   })

  --   wk.register({
  --     ["<leader>"] = {
  --       [";"] = { [[<cmd>Telescope find_files<cr>]], "Find File" },
  --       ["<space>"] = { [[<cmd>Telescope oldfiles<cr>]], "Find Old File" },
  --       ["<cr>"] = { [[<cmd>bp | sp | bn | bd<cr>]], "Close Buffer" },
  --       [":"] = { [[<cmd>q<cr>]], "Close Window" },
  --       ["-"] = { [[<cmd>only<cr>]], "Close other splits" },
  --       ["'"] = { [[<cmd>vs<cr>]], "Split" },
  --       ["\""] = { [[<cmd>sp<cr>]], "Horizontal Split" },
  --       ["."] = { [[<cmd>Telescope coc definitions<cr>]], "Go to Definition" },
  --       [">"] = { [[<cmd>Telescope coc references_used<cr>]], "Go to other references" },
  --       [","] = { "<cmd>NnnPicker %:p:h<cr>", "File Picker" },
  --       ["|"] = { "<cmd>NnnExplorer %:p:h<cr>", "Explore Files" },
  --       ["/"] = {
  --         function()
  --           print("Current Buffer: " .. vim.api.nvim_buf_get_name(0))
  --         end,
  --         "Current Buffer",
  --       },
  --       f = {
  --         name = "+find",
  --         b = { [[<cmd>Telescope current_buffer_fuzzy_find<cr>]], "Find within buffer" },
  --         k = { [[<cmd>Telescope dap list_breakpoints<cr>]], "Find Breakpoints" },
  --         r = { [[<cmd>Telescope coc references<cr>]], "Find References" },
  --         i = { [[<cmd>Telescope coc implementations<cr>]], "Find Implementations" },
  --         f = { [[<cmd>Telescope live_grep<cr>]], "Live Grep" },
  --         t = { [[<cmd>Telescope coc type_definitions<cr>]], "Type Definitions" },
  --         s = { [[<cmd>Telescope search_history<cr>]], "Previous Searches" },
  --         g = { [[<cmd>Telescope git_files<cr>]], "Git Files" },
  --         m = { [[<cmd>Telescope coc document_symbols<cr>]], "Document Symbols" },
  --         w = { [[<cmd>Telescope coc workspace_symbols<cr>]], "Workspace Symbols" },
  --       },
  --       h = {
  --         name = "+github",
  --         p = {
  --           name = "+pr",
  --           n = { [[<cmd>Octo pr create<cr>]], "Create PR" },
  --           l = { [[<cmd>Octo pr list<cr>]], "List Open PRs" },
  --           o = { [[<cmd>Octo pr checkout<cr>]], "Checkout current PR" },
  --           e = { [[<cmd>Octo pr edit<cr>]], "Edit PR" },
  --           m = { [[<cmd>Octo pr merge<cr>]], "Merge PR" },
  --           c = { [[<cmd>Octo pr commits<cr>]], "PR Commits" },
  --           k = { [[<cmd>Octo pr checks<cr>]], "State of PR Checks" },
  --           d = { [[<cmd>Octo pr diff<cr>]], "PR Diff" },
  --           b = { [[<cmd>Octo pr browser<cr>]], "Open PR in Browser" },
  --           y = { [[<cmd>Octo pr url<cr>]], "Copy PR URL to clipboard" },
  --           r = { [[<cmd>Octo reviewer add<cr>]], "Assign a PR reviewer" },
  --           R = { [[<cmd>Octo pr reload<cr>]], "Reload PR" },
  --         },
  --         c = {
  --           name = "+comment",
  --           a = { [[<cmd>Octo comment add<cr>]], "Add a review comment" },
  --           d = { [[<cmd>Octo comment delete<cr>]], "Delete a review comment" },
  --           r = { [[<cmd>Octo thread resolve<cr>]], "Resolve thread" },
  --           u = { [[<cmd>Octo thread unresolve<cr>]], "Unresolve thread" },
  --         },
  --         l = {
  --           name = "+label",
  --           a = { [[<cmd>Octo label add<cr>]], "Add a label" },
  --           r = { [[<cmd>Octo label remove<cr>]], "Remove a review comment" },
  --           c = { [[<cmd>Octo label create<cr>]], "Create a label" },
  --         },
  --         a = {
  --           name = "+assignees",
  --           a = { [[<cmd>Octo assignees add<cr>]], "Assign a user" },
  --           r = { [[<cmd>Octo assignees remove<cr>]], "Unassign a user" },
  --         },
  --         r = {
  --           name = "+reaction",
  --           e = { [[<cmd>Octo reaction eyes<cr>]], "Add 👀 reaction" },
  --           l = { [[<cmd>Octo reaction laugh<cr>]], "Add 😄 reaction" },
  --           c = { [[<cmd>Octo reaction confused<cr>]], "Add 😕 reaction" },
  --           r = { [[<cmd>Octo reaction rocket<cr>]], "Add 🚀 reaction" },
  --           h = { [[<cmd>Octo reaction heart<cr>]], "Add ❤️ reaction" },
  --           t = { [[<cmd>Octo reaction tada<cr>]], "Add 🎉 reaction" },
  --         },
  --       },
  --       c = {
  --         name = "+code",
  --         e = { "<cmd>NnnExplorer %:p:h<cr>", "Explore" },
  --         E = { "<cmd>NnnExplorer<cr>", "Explore (from root)" },
  --         p = { "<cmd>NnnPicker %:p:h<cr>", "Picker" },
  --         P = { "<cmd>NnnPicker<cr>", "Picker (from root)" },
  --         r = { "<plug>(coc-rename)", "Rename Variable" },
  --         i = { "<cmd>CocActionAsync('doHover')<cr>", "Info (hover)" },
  --         d = { [[<cmd>Telescope coc diagnostics<cr>]], "Document Diagnostics" },
  --         w = { [[<cmd>Telescope coc workspace_diagnostics<cr>]], "Workspace Diagnostics" },
  --         c = { [[<plug>(coc-refactor)]], "Refactor" },
  --         a = { [[<cmd>Telescope coc code_actions]], "Code Actions" },
  --         ["."] = { [[<plug>(coc-fix-current)]], "Do first code action (fix)" },
  --         s = { "<cmd>Sort<cr>", "Sort" },
  --         t = { ":s/\"\\(\\w\\) \\(\\w\\)\"/\\1\", \"\\2/g<cr>", "Split word string" },
  --       },
  --       b = {
  --         name = "+buffers",
  --         b = { [[<cmd>Telescope buffers<cr>]], "Switch Buffer" },
  --         d = { [[<cmd>BufDel<cr>]], "Delete Buffer" },
  --         k = { [[<cmd>BufDel!<cr>]], "Kill Buffer" },
  --       },
  --       e = {
  --         name = "+editor",
  --         m = { [[<cmd>Telescope marks<cr>]], "Marks" },
  --         h = { [[<cmd>Telescope help_tags<cr>]], "Help Tag" },
  --         [";"] = { [[<cmd>Telescope commands<cr>]], "Commands" },
  --         c = { [[<cmd>Telescope command_history<cr>]], "Previous Commands" },
  --         k = { [[<cmd>Telescope keymaps<cr>]], "Keymap" },
  --         q = { [[<cmd>Telescope quickfix<cr>]], "QuickFix" },
  --         o = { [[<cmd>Telescope quickfix<cr>]], "Vim Options" },
  --         v = { "<cmd>VsnipOpenEdit<cr>", "VSnip" },
  --         w = { "<cmd>WinShift<cr>", "Move Window" },
  --         s = {
  --           name = "+sudo",
  --           r = { "<cmd>SudaRead<cr>", "Read file with sudo" },
  --           w = { "<cmd>SudaWrite<cr>", "Write file with sudo" },
  --         },
  --         p = {
  --           name = "+packer",
  --           p = { "<cmd>PackerSync<cr>", "Sync Plugins" },
  --           c = { "<cmd>PackerCompile<cr>", "Compile Plugins" },
  --         },
  --         l = {
  --           name = "+lsp",
  --           f = { [[<cmd>LspInfo<cr>]], "Info" },
  --           i = { [[<cmd>LspInstallInfo<cr>]], "Install" },
  --         },
  --       },
  --       g = {
  --         name = "+git",
  --         c = { [[<cmd>Telescope git_bcommits<cr>]], "Git Commits" },
  --         s = { [[<cmd>Telescope git_status<cr>]], "Git Status" },
  --         t = { [[<cmd>Telescope git_stash<cr>]], "Git Stashes" },
  --         g = { [[<cmd>LazyGit<cr>]], "LazyGit" },
  --         b = { [[<cmd>GitMessenger<cr>]], "Blame" },
  --         l = {
  --           function()
  --             gl.get_buf_range_url("n", {
  --               action_callback = gla.open_in_browser,
  --             })
  --           end,
  --           "Web Link",
  --           silent = true,
  --         },
  --       },
  --       t = {
  --         name = "+test",
  --         t = { "<cmd>TestNearest<cr>", "Test Nearest" },
  --         n = { "<cmd>TestNearest<cr>", "Test Nearest" },
  --         f = { "<cmd>TestFile<cr>", "Test File" },
  --         a = { "<cmd>TestSuite<cr>", "Test Suite" },
  --         [";"] = { "<cmd>TestLast<cr>", "Rerun Last Test" },
  --         ["."] = { "<cmd>TestVisit<cr>", "Visit Test" },
  --       },
  --       x = {
  --         name = "+trouble",
  --         x = { "<cmd>TroubleToggle<cr>", "Toggle Trouble" },
  --         w = { "<cmd>TroubleToggle lsp_workspace_diagnostics<cr>", "Toggle Workspace Diagnostics" },
  --         d = { "<cmd>TroubleToggle lsp_document_diagnostics<cr>", "Toggle Document Diagnostics" },
  --         r = { "<cmd>TroubleToggle lsp_references<cr>", "Toggle References" },
  --         q = { "<cmd>TroubleToggle quickfix<cr>", "Toggle QuickFix" },
  --         l = { "<cmd>TroubleToggle loclist<cr>", "Toggle Location List" },
  --         t = { "<cmd>TodoTrouble<cr>", "Toggle TODOs" },
  --       },
  --       q = {
  --         name = "+quit",
  --         q = { "<cmd>:qa<cr>", "Quit" },
  --         c = { "<cmd>:q!<cr>", "Close" },
  --         k = { "<cmd>:qa!<cr>", "Quit without saving" },
  --         s = { "<cmd>:wa | qa!<cr>", "Quit and save" },
  --       },
  --     },
  --   })
  -- end

  do -- gitlinker.nvim
    require("gitlinker").setup()
  end

  do -- vim-matchup
    vim.g.matchup_surround_enabled = true
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_offscreen = {
      method = "popup",
      fullwidth = true,
      highlight = "Normal",
      border = "shadow",
    }
  end

  do -- treesitter-nvim
    vim.opt.indentexpr = "nvim_treesitter#indent()"

    -- custom treesitter parsers and grammars
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.jsonc.used_by = "json"
    parser_config.org = {
      install_info = {
        url = "https://github.com/milisims/tree-sitter-org",
        revision = "main",
        files = { "src/parser.c", "src/scanner.cc" },
      },
      filetype = "org",
    }
    -- parser_config.embedded_template = {
    --   install_info = {
    --     url = "https://github.com/tree-sitter/tree-sitter-embedded-template",
    --     files = { "src/parser.c" },
    --     requires_generate_from_grammar = true,
    --   },
    --   used_by = { "eex", "leex", "sface", "eelixir", "eruby", "erb" },
    -- }
    -- parser_config.markdown = {
    --   install_info = {
    --     url = "https://github.com/ikatyang/tree-sitter-markdown",
    --     files = { "src/parser.c", "src/scanner.cc", "-DTREE_SITTER_MARKDOWN_AVOID_CRASH=1" },
    --     requires_generate_from_grammar = true,
    --     filetype = "md",
    --   },
    -- }
    require("nvim-treesitter.configs").setup({
      ignore_install = { "elixir" },
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "comment",
        "dockerfile",
        -- "elixir",
        "elm",
        "erlang",
        "fish",
        "go",
        "graphql",
        "html",
        "heex",
        "javascript",
        -- "markdown",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "make",
        "nix",
        "org",
        "perl",
        "python",
        "query",
        "regex",
        "ruby",
        "rust",
        "scss",
        "surface",
        "toml",
        "tsx",
        "typescript",
        "yaml",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      autotag = { enable = true },
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
        config = {
          lua = "-- %s",
          fish = "# %s",
          toml = "# %s",
          yaml = "# %s",
          ["eruby.yaml"] = "# %s",
        },
      },
      matchup = { enable = true },
      rainbow = {
        enable = true,
        disable = { "json", "html" },
        extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
        max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "gnn",
          scope_incremental = "gss",
          node_incremental = ".",
          node_decremental = ";",
        },
      },
      textsubjects = {
        enable = true,
        keymaps = {
          ["."] = "textsubjects-smart",
          [";"] = "textsubjects-container-outer",
        },
      },
      -- REF: https://github.com/stehessel/nix-dotfiles/blob/master/program/editor/neovim/config/lua/plugins/treesitter.lua
      -- textobjects = {
      --   -- lsp_interop = {
      --   --   enable = true,
      --   --   border = "none",
      --   --   peek_definition_code = {
      --   --     ["df"] = "@function.outer",
      --   --     ["dF"] = "@class.outer",
      --   --   },
      --   -- },
      --   select = {
      --     enable = false,
      --     lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      --     keymaps = {
      --       ["if"] = "@function.inner",
      --       ["af"] = "@function.outer",
      --       ["ar"] = "@parameter.outer",
      --       ["iC"] = "@class.inner",
      --       ["aC"] = "@class.outer",
      --       ["ik"] = "@call.inner",
      --       ["ak"] = "@call.outer",
      --       ["il"] = "@loop.inner",
      --       ["al"] = "@loop.outer",
      --       ["ic"] = "@conditional.outer",
      --       ["ac"] = "@conditional.inner",
      --     },
      --   },
      -- },
      query_linter = {
        enable = true,
        use_virtual_text = true,
        lint_events = { "BufWrite", "CursorHold" },
      },
      playground = {
        enable = true,
        disable = {},
        updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
        persist_queries = true, -- Whether the query persists across vim sessions
        keybindings = {
          toggle_query_editor = "o",
          toggle_hl_groups = "i",
          toggle_injected_languages = "t",
          toggle_anonymous_nodes = "a",
          toggle_language_display = "I",
          focus_language = "f",
          unfocus_language = "F",
          update = "R",
          goto_node = "<cr>",
          show_help = "?",
        },
      },
    })
    -- require("spellsitter").setup()
    require("nvim-ts-autotag").setup({
      filetypes = {
        "html",
        "xml",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "vue",
      },
    })
    require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }
  end

  do -- indent-blankline
    require("indent_blankline").setup({
      char = "│", -- ┆ ┊ 
      -- char_list = { "│", "|", "¦", "┆", "┊" },
      space_char_blankline = " ",
      show_foldtext = false,
      show_current_context = true,
      show_current_context_start = true,
      show_first_indent_level = true,
      show_end_of_line = true,
      indent_blankline_use_treesitter = true,
      indent_blankline_show_trailing_blankline_indent = false,
      filetype_exclude = {
        "startify",
        "dashboard",
        "alpha",
        "log",
        "fugitive",
        "gitcommit",
        "packer",
        "vimwiki",
        "markdown",
        "json",
        "txt",
        "vista",
        "help",
        "NvimTree",
        "git",
        "fzf",
        "TelescopePrompt",
        "undotree",
        "norg",
        "org",
        "orgagenda",
        "", -- for all buffers without a file type
      },
      buftype_exclude = { "terminal", "nofile" },
      context_patterns = {
        "class",
        "function",
        "method",
        "block",
        "list_literal",
        "selector",
        "^if",
        "^table",
        "if_statement",
        "while",
        "for",
        "^object",
        "arguments",
        "else_clause",
        "jsx_element",
        "jsx_self_closing_element",
        "try_statement",
        "catch_clause",
        "import_statement",
        "operation_type",
      },
    })
  end

  do -- neoscroll
    if false then
      local mappings = {}
      require("neoscroll").setup({
        -- mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "zt", "zz", "zb" },
        stop_eof = false,
        hide_cursor = false,
        easing_function = "circular",
      })
      mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } }
      mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } }
      mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "250" } }
      mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "250" } }
      mappings["<C-y>"] = { "scroll", { "-0.10", "false", "80" } }
      mappings["<C-e>"] = { "scroll", { "0.10", "false", "80" } }
      mappings["zt"] = { "zt", { "150" } }
      mappings["zz"] = { "zz", { "150" } }
      mappings["zb"] = { "zb", { "150" } }
      require("neoscroll.config").set_mappings(mappings)
    end
  end

  do -- nvim-web-devicons
    require("nvim-web-devicons").setup({ default = true })
  end

  -- do -- project.nvim
  --   require("project_nvim").setup({
  --     manual_mode = true,
  --     patterns = { ".git", ".hg", ".bzr", ".svn", "Makefile", "package.json", "elm.json", "mix.lock" },
  --   }) -- REF: https://github.com/ahmedkhalf/project.nvim#%EF%B8%8F-configuration
  -- end

  do -- orgmode.nvim
    -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/orgmode.lua
    -- CHEAT: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/after/ftplugin/org.lua
    --        https://github.com/huynle/nvim/blob/master/lua/configs/orgmode.lua
    --        https://github.com/tkmpypy/dotfiles/blob/master/.config/nvim/lua/plugins.lua#L358-L470
    --        https://github.com/tricktux/dotfiles/blob/master/defaults/.config/nvim/lua/config/plugins/orgmode.lua
    -- ENABLE TREESITTER: https://github.com/kristijanhusak/orgmode.nvim/tree/tree-sitter#setup
    require("orgmode").setup({
      -- org_agenda_files = {"~/Library/Mobile Documents/com~apple~CloudDocs/org/*"},
      -- org_default_notes_file = "~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org"
      org_agenda_files = { mega.dirs.org .. "/**/*" },
      org_default_notes_file = mega.dirs.org .. "/refile.org",
      org_todo_keywords = { "TODO(t)", "WAITING", "NEXT", "|", "DONE", "CANCELLED", "HACK" },
      org_todo_keyword_faces = {
        NEXT = ":foreground royalblue :weight bold :slant italic",
        CANCELLED = ":foreground darkred",
        HOLD = ":foreground orange :weight bold",
      },
      org_hide_emphasis_markers = true,
      org_hide_leading_stars = true,
      org_agenda_skip_scheduled_if_done = true,
      org_agenda_skip_deadline_if_done = true,
      org_agenda_templates = {
        t = { description = "Task", template = "* TODO %?\n SCHEDULED: %t" },
        l = { description = "Link", template = "* %?\n%a" },
        n = {
          description = "Note",
          template = "* NOTE %?\n  %u",
          target = mega.dirs.org .. "/note.org",
        },
        j = {
          description = "Journal",
          template = "\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?",
          target = mega.dirs.org .. "/journal.org",
        },
        p = {
          description = "Project Todo",
          template = "* TODO %? \nSCHEDULED: %t",
          target = mega.dirs.org .. "/projects.org",
        },
      },
      mappings = {
        org = {
          org_toggle_checkbox = "<leader>x",
        },
      },
      notifications = {
        reminder_time = { 0, 1, 5, 10 },
        repeater_reminder_time = { 0, 1, 5, 10 },
        deadline_warning_reminder_time = { 0 },
        cron_notifier = function(tasks)
          for _, task in ipairs(tasks) do
            local title = string.format("%s (%s)", task.category, task.humanized_duration)
            local subtitle = string.format("%s %s %s", string.rep("*", task.level), task.todo, task.title)
            local date = string.format("%s: %s", task.type, task.time:to_string())

            -- helpful docs for options: https://github.com/julienXX/terminal-notifier#options
            if fn.executable("terminal-notifier") then
              vim.loop.spawn("terminal-notifier", {
                args = {
                  "-title",
                  title,
                  "-subtitle",
                  subtitle,
                  "-message",
                  date,
                  "-appIcon ~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
                  "-ignoreDnD",
                },
              })
            end
            -- if fn.executable("notify-send") then
            -- 	vim.loop.spawn("notify-send", {
            -- 		args = {
            -- 			"--icon=~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
            -- 			string.format("%s\n%s\n%s", title, subtitle, date),
            -- 		},
            -- 	})
            -- end
          end
        end,
      },
    })
    require("org-bullets").setup()
  end

  do -- trouble.nvim
    require("trouble").setup({ auto_close = true })
  end

  do -- bullets
    vim.g.bullets_enabled_file_types = {
      "markdown",
      "text",
      "gitcommit",
      "scratch",
    }
    vim.g.bullets_checkbox_markers = " ○◐✗"
    vim.g.bullets_set_mappings = 0
    -- vim.g.bullets_outline_levels = { "num" }
  end

  do -- cursorhold
    -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
    vim.g.cursorhold_updatetime = 100
  end

  do -- specs.nvim
    local specs = require("specs")
    specs.setup({
      show_jumps = true,
      min_jump = 30,
      popup = {
        delay_ms = 0, -- delay before popup displays
        inc_ms = 1, -- time increments used for fade/resize effects
        blend = 10, -- starting blend, between 0-100 (fully transparent), see :h winblend
        width = 100,
        winhl = "PMenu",
        fader = specs.linear_fader,
        resizer = specs.slide_resizer,
      },
      ignore_filetypes = { "Telescope", "fzf", "NvimTree", "alpha" },
      ignore_buftypes = {
        nofile = true,
      },
    })
  end

  do -- comment.nvim
    require("Comment").setup({
      ignore = "^$",
      pre_hook = function(ctx)
        local U = require("Comment.utils")

        local location = nil
        if ctx.ctype == U.ctype.block then
          location = require("ts_context_commentstring.utils").get_cursor_location()
        elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
          location = require("ts_context_commentstring.utils").get_visual_start_location()
        end

        return require("ts_context_commentstring.internal").calculate_commentstring({
          key = ctx.ctype == U.ctype.line and "__default" or "__multiline",
          location = location,
        })
      end,
    })
  end

  do -- conflict-marker.nvim
    -- disable the default highlight group
    vim.g.conflict_marker_highlight_group = "Error"
    -- Include text after begin and end markers
    vim.g.conflict_marker_begin = "^<<<<<<< .*$"
    vim.g.conflict_marker_end = "^>>>>>>> .*$"
  end

  do -- colorizer.nvim
    require("colorizer").setup({
      -- '*',
      -- '!vim',
      -- }, {
      css = { rgb_fn = true },
      scss = { rgb_fn = true },
      sass = { rgb_fn = true },
      stylus = { rgb_fn = true },
      vim = { names = false },
      tmux = { names = true },
      "toml",
      "eelixir",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "zsh",
      "fish",
      "sh",
      "conf",
      "lua",
      html = {
        mode = "foreground",
      },
    })
  end

  do -- golden_size.nvim
    local golden_size_installed, golden_size = pcall(require, "golden_size")
    if golden_size_installed then
      local function ignore_by_buftype(types)
        local buftype = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
        for _, type in pairs(types) do
          -- mega.log(string.format("type: %s / buftype: %s", type, buftype))

          if type == buftype then
            return 1
          end
        end
      end
      golden_size.set_ignore_callbacks({
        {
          ignore_by_buftype,
          {
            "Undotree",
            "quickfix",
            "nerdtree",
            "current",
            "Vista",
            "LuaTree",
            "NvimTree",
            "nofile",
            "tsplayground",
          },
        },
        { golden_size.ignore_float_windows }, -- default one, ignore float windows
        { golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
      })
    end
  end

  do -- lastplace
    require("nvim-lastplace").setup({
      lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
      lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
      lastplace_open_folds = true,
    })
  end

  do -- nvim-autopairs
    local npairs = require("nvim-autopairs")
    npairs.setup({
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
    npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
    local endwise = require("nvim-autopairs.ts-rule").endwise
    npairs.add_rules({
      endwise("then$", "end", "lua", nil),
      endwise("do$", "end", "lua", nil),
      endwise("function%(.*%)$", "end", "lua", nil),
      endwise(" do$", "end", "elixir", nil),
    })
    -- REF: neat stuff:
    -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
  end

  do -- lightspeed.nvim
    require("lightspeed").setup({
      -- jump_to_first_match = true,
      jump_on_partial_input_safety_timeout = 400,
      -- This can get _really_ slow if the window has a lot of content,
      -- turn it on only if your machine can always cope with it.
      highlight_unique_chars = false,
      grey_out_search_area = true,
      match_only_the_start_of_same_char_seqs = true,
      limit_ft_matches = 5,
      -- full_inclusive_prefix_key = '<c-x>',
      -- By default, the values of these will be decided at runtime,
      -- based on `jump_to_first_match`.
      -- labels = nil,
      -- cycle_group_fwd_key = nil,
      -- cycle_group_bwd_key = nil,
    })
  end

  do -- diffview.nvim
    local cb = require("diffview.config").diffview_callback

    require("diffview").setup({
      diff_binaries = false, -- Show diffs for binaries
      use_icons = true, -- Requires nvim-web-devicons
      file_panel = {
        width = 50,
      },
      enhanced_diff_hl = true,
      key_bindings = {
        disable_defaults = false, -- Disable the default key bindings
        -- The `view` bindings are active in the diff buffers, only when the current
        -- tabpage is a Diffview.
        view = {
          ["<tab>"] = cb("select_next_entry"), -- Open the diff for the next file
          ["<s-tab>"] = cb("select_prev_entry"), -- Open the diff for the previous file
          ["<leader>e"] = cb("focus_files"), -- Bring focus to the files panel
          ["<leader>b"] = cb("toggle_files"), -- Toggle the files panel.
        },
        file_panel = {
          ["j"] = cb("next_entry"), -- Bring the cursor to the next file entry
          ["<down>"] = cb("next_entry"),
          ["k"] = cb("prev_entry"), -- Bring the cursor to the previous file entry.
          ["<up>"] = cb("prev_entry"),
          ["<cr>"] = cb("select_entry"), -- Open the diff for the selected entry.
          ["o"] = cb("select_entry"),
          ["<2-LeftMouse>"] = cb("select_entry"),
          ["-"] = cb("toggle_stage_entry"), -- Stage / unstage the selected entry.
          ["S"] = cb("stage_all"), -- Stage all entries.
          ["U"] = cb("unstage_all"), -- Unstage all entries.
          ["R"] = cb("refresh_files"), -- Update stats and entries in the file list.
          ["<tab>"] = cb("select_next_entry"),
          ["<s-tab>"] = cb("select_prev_entry"),
          ["<leader>e"] = cb("focus_files"),
          ["<leader>b"] = cb("toggle_files"),
        },
      },
    })
  end

  do -- git.nvim
    if false then
      require("git").setup({
        keymaps = {
          -- Open blame window
          blame = "<Leader>gb",
          -- Close blame window
          quit_blame = "q",
          -- Open blame commit
          blame_commit = "<CR>",
          -- Open file/folder in git repository
          browse = "<Leader>gh",
          -- Open pull request of the current branch
          open_pull_request = "<Leader>gp",
          -- Create a pull request with the target branch is set in the `target_branch` option
          create_pull_request = "<Leader>gn",
          -- Opens a new diff that compares against the current index
          diff = "<Leader>gd",
          -- Close git diff
          diff_close = "<Leader>gD",
          -- Revert to the specific commit
          revert = "<Leader>gr",
          -- Revert the current file to the specific commit
          revert_file = "<Leader>gR",
        },
        -- Default target branch when create a pull request
        target_branch = "main",
      })
    end
  end

  do -- git-messenger.nvim
    vim.g.git_messenger_floating_win_opts = { border = mega.get_border() }
    vim.g.git_messenger_no_default_mappings = true
    vim.g.git_messenger_max_popup_width = 100
    vim.g.git_messenger_max_popup_height = 100
  end

  do -- firenvim
    -- REFS:
    -- * https://github.com/cgardner/dotfiles-bare/blob/master/.config/nvim/lua/plugins/firenvim.lua#L3-L9
    vim.g.firenvim_config = {
      globalSettings = {
        alt = "all",
      },
      localSettings = {
        [".*"] = {
          cmdline = "neovim",
          content = "text",
          priority = 0,
          selector = "textarea",
          takeover = "never", -- disable until called with firefox hotkey <C-e>
        },
      },
    }

    if vim.g.started_by_firenvim then
      print("hi from started by firenvim")

      vim.opt.cmdheight = 1
      -- selene: allow(global_usage)
      function _G.set_firenvim_settings()
        local min_lines = 18
        if vim.opt.lines < min_lines then
          vim.opt.lines = min_lines
        end

        vim.opt.guifont = [[Jetbrains Nerd Font:h13]]
        vim.opt.wrap = true
        vim.opt.number = false
        vim.opt.relativenumber = false
        vim.opt.signcolumn = "no"
        vim.opt.list = true
        vim.opt.linebreak = true
        vim.opt.breakindentopt = true
        vim.opt.colorcolumn = 0
        vim.cmd("startinsert")
      end

      vim.cmd([[
        function! OnUIEnter(event) abort
          if 'Firenvim' ==# get(get(nvim_get_chan_info(a:event.chan), 'client', {}), 'name', '')
            echom "hi!"
            lua _G.set_firenvim_settings()
          endif
        endfunction
        autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
        au BufEnter github.com_*.txt,gitlab.com_*.txt,mattermost.*.txt,mail.google.com_*.txt set filetype=markdown
        au BufEnter mail.google.com_*.txt set tw=80
      ]])
    end
  end

  do -- nvim-dap
    local dap = require("dap")
    dap.adapters.mix_task = {
      type = "executable",
      command = fn.stdpath("data") .. "/elixir-ls/debugger.sh",
      args = {},
    }
    dap.configurations.elixir = {
      {
        type = "mix_task",
        name = "mix test",
        task = "test",
        taskArgs = { "--trace" },
        request = "launch",
        startApps = true, -- for Phoenix projects
        projectDir = "${workspaceFolder}",
        requireFiles = {
          "test/**/test_helper.exs",
          "test/**/*_test.exs",
        },
      },
    }
  end

  do -- vim-test
    -- REF:
    -- neat ways to detect jest things
    -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
    -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19
    api.nvim_exec(
      [[
    function! TerminalSplit(cmd)
    vert new | set filetype=test | call termopen(['zsh', '-c', 'eval $(desk load); ' . a:cmd], {'curwin':1})
    endfunction

    let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
    let g:test#strategy = 'terminal_split'
    let g:test#filename_modifier = ':.'
    let g:test#preserve_screen = 0

    " nmap <silent> <leader>tf :TestFile<CR>
    " nmap <silent> <leader>tt :TestVisit<CR>
    " nmap <silent> <leader>tn :TestNearest<CR>
    " nmap <silent> <leader>tl :TestLast<CR>
    " nmap <silent> <leader>tv :TestVisit<CR>
    " nmap <silent> <leader>ta :TestSuite<CR>
    " nmap <silent> <leader>tP :A<CR>
    " nmap <silent> <leader>tp :AV<CR>
    " nmap <silent> <leader>to :copen<CR>
    ]],
      false
    )
    vcmd([[let g:test#javascript#jest#file_pattern = '\v(__tests__/.*|(spec|test))\.(js|jsx|coffee|ts|tsx)$']])
  end

  do -- vim-projectionist
    vim.g.projectionist_heuristics = {
      ["&package.json"] = {
        ["package.json"] = {
          type = "package",
          alternate = { "yarn.lock", "package-lock.json" },
        },
        ["package-lock.json"] = {
          alternate = "package.json",
        },
        ["yarn.lock"] = {
          alternate = "package.json",
        },
      },
      ["package.json"] = {
        -- outstand'ing (ts/tsx)
        ["spec/javascript/*.test.tsx"] = {
          ["alternate"] = "app/webpacker/src/javascript/{}.tsx",
          ["type"] = "test",
        },
        ["app/webpacker/src/javascript/*.tsx"] = {
          ["alternate"] = "spec/javascript/{}.test.tsx",
          ["type"] = "source",
        },
        ["spec/javascript/*.test.ts"] = {
          ["alternate"] = "app/webpacker/src/javascript/{}.ts",
          ["type"] = "test",
        },
        ["app/webpacker/src/javascript/*.ts"] = {
          ["alternate"] = "spec/javascript/{}.test.ts",
          ["type"] = "source",
        },
      },
      -- https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/after/ftplugin/elixir.vim
      ["mix.exs"] = {
        -- "dead" views
        ["lib/**/views/*_view.ex"] = {
          ["type"] = "view",
          ["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
          ["template"] = {
            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
            "  use {dirname|camelcase|capitalize}, :view",
            "end",
          },
        },
        ["test/**/views/*_view_test.exs"] = {
          ["type"] = "test",
          ["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
          ["template"] = {
            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
            "  use ExUnit.Case, async: true",
            "",
            "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
            "end",
          },
        },
        -- "live" views
        ["lib/**/live/*_live.ex"] = {
          ["type"] = "live",
          ["alternate"] = {
            "lib/{dirname}/live/{basename}_live.html.heex",
            "test/{dirname}/live/{basename}_live_test.exs",
          },
          ["template"] = {
            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
            "  use {dirname|camelcase|capitalize}, :live_view",
            "end",
          },
        },
        ["test/**/live/*_live_test.exs"] = {
          ["type"] = "test",
          ["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
          ["template"] = {
            "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
            "  use ExUnit.Case, async: true",
            "",
            "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
            "end",
          },
        },
        ["lib/*.ex"] = {
          ["type"] = "source",
          ["alternate"] = "test/{}_test.exs",
          ["template"] = {
            "defmodule {camelcase|capitalize|dot} do",
            "",
            "end",
          },
        },
        ["test/*_test.exs"] = {
          ["type"] = "test",
          ["alternate"] = "lib/{}.ex",
          ["template"] = {
            "defmodule {camelcase|capitalize|dot}Test do",
            "  use ExUnit.Case, async: true",
            "",
            "  alias {camelcase|capitalize|dot}",
            "end",
          },
        },
      },
    }
  end

  do -- package-info.nvim
    require("package-info").setup({
      colors = {
        --up_to_date = C.cs.bg2, -- Text color for up to date package virtual text
        outdated = "#d19a66", -- Text color for outdated package virtual text
      },
      icons = {
        enable = true, -- Whether to display icons
        style = {
          up_to_date = "|  ", -- Icon for up to date packages
          outdated = "|  ", -- Icon for outdated packages
        },
      },
      autostart = true, -- Whether to autostart when `package.json` is opened
    })
  end

  do -- numb.nvim
    require("numb").setup()
  end

  do -- telescope-nvim
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local themes = require("telescope.themes")

    local function get_border(opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        borderchars = {
          -- { " ", " ", " ", " ", " ", " ", " ", " " },
          { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
          results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
          preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
      })
    end

    ---@param opts table
    ---@return table
    local function dropdown(opts)
      return themes.get_dropdown(get_border(opts))
    end

    telescope.setup({
      defaults = {
        set_env = { ["TERM"] = vim.env.TERM },
        -- borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        prompt_prefix = "  ",
        selection_caret = "» ", -- ❯
        mappings = {
          i = {
            ["<c-w>"] = actions.send_selected_to_qflist,
            ["<c-c>"] = function()
              vim.cmd("stopinsert!")
            end,
            ["<esc>"] = actions.close,
            ["<cr>"] = actions.select_vertical + actions.center,
            ["<c-o>"] = actions.select_default + actions.center,
            ["<c-s>"] = actions.select_horizontal,
            ["<c-b>"] = actions.preview_scrolling_up,
            ["<c-f>"] = actions.preview_scrolling_down,
          },
          n = {
            ["<C-w>"] = actions.send_selected_to_qflist,
          },
        },
        file_ignore_patterns = {
          "%.jpg",
          "%.jpeg",
          "%.png",
          "%.otf",
          "%.ttf",
          "EmmyLua.spoon",
          ".yarn",
          "dotbot/.*",
          "dotbot-plugins/.*",
          ".git/.*",
        },
        -- :help telescope.defaults.path_display
        -- path_display = { "smart", "absolute", "truncate" },
        layout_strategy = "flex",
        layout_config = {
          width = 0.65,
          height = 0.6,
          horizontal = {
            preview_width = 0.45,
          },
          cursor = get_border({
            layout_config = {
              cursor = { width = 0.3 },
            },
          }),
        },
        winblend = 3,
        -- history = {
        --   path = fn.stdpath("data") .. "/telescope_history.sqlite3",
        -- },
        vimgrep_arguments = {
          "rg",
          "--hidden",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        },
      },
      extensions = {
        -- frecency = {
        --   workspaces = {
        --     conf = mega.dirs.dots,
        --     privates = mega.dirs.privates,
        --     project = mega.dirs.code,
        --     notes = mega.dirs.zettel,
        --     icloud = mega.dirs.icloud,
        --     org = mega.dirs.org,
        --     docs = mega.dirs.docs,
        --   },
        -- },
        media_files = {
          find_cmd = "rg",
        },
        fzf = {
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        },
      },
      pickers = {
        buffers = dropdown({
          sort_mru = true,
          sort_lastused = true,
          show_all_buffers = true,
          ignore_current_buffer = true,
          previewer = false,
          theme = "dropdown",
          mappings = {
            i = { ["<c-x>"] = "delete_buffer" },
            n = { ["<c-x>"] = "delete_buffer" },
          },
        }),
        oldfiles = dropdown(),
        live_grep = {
          file_ignore_patterns = { ".git/" },
        },
        current_buffer_fuzzy_find = dropdown({
          previewer = false,
          shorten_path = false,
        }),
        lsp_code_actions = {
          theme = "cursor",
        },
        colorscheme = {
          enable_preview = true,
        },
        find_files = {
          hidden = true,
        },
        git_branches = dropdown(),
        git_bcommits = {
          layout_config = {
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
        git_commits = {
          layout_config = {
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
        reloader = dropdown(),
      },
    })

    --- NOTE: this must be required after setting up telescope
    --- otherwise the result will be cached without the updates
    --- from the setup call
    local builtins = require("telescope.builtin")

    local function project_files(opts)
      if not pcall(builtins.git_files, opts) then
        builtins.find_files(opts)
      end
    end

    local function dotfiles()
      builtins.find_files({
        prompt_title = "~ dotfiles ~",
        cwd = mega.dirs.dots,
      })
    end

    local function privates()
      builtins.find_files({
        prompt_title = "~ privates ~",
        cwd = mega.dirs.privates,
      })
    end

    -- local function frecency()
    --   telescope.extensions.frecency.frecency(dropdown({
    --     -- NOTE: remove default text as it's slow
    --     -- default_text = ':CWD:',
    --     winblend = 10,
    --     border = true,
    --     previewer = false,
    --     shorten_path = false,
    --   }))
    -- end

    local function gh_notifications()
      telescope.extensions.ghn.ghn(dropdown())
    end

    local function installed_plugins()
      require("telescope.builtin").find_files({
        cwd = fn.stdpath("data") .. "/site/pack/paqs",
      })
    end

    local function orgfiles()
      builtins.find_files({
        prompt_title = "Org",
        cwd = mega.dirs.org,
      })
    end

    local function tmux_sessions()
      telescope.extensions.tmux.sessions({})
    end

    local function tmux_windows()
      telescope.extensions.tmux.windows({
        entry_format = "#S: #T",
      })
    end

    require("which-key").register({
      ["<leader>f"] = {
        name = "telescope",
        a = { builtins.builtin, "builtins" },
        b = { builtins.current_buffer_fuzzy_find, "current buffer fuzzy find" },
        d = { dotfiles, "dotfiles" },
        p = { privates, "privates" },
        f = { project_files, "find/git files" },
        g = {
          name = "+git",
          c = { builtins.git_commits, "commits" },
          b = { builtins.git_branches, "branches" },
          n = { gh_notifications, "notifications" },
        },
        M = { builtins.man_pages, "man pages" },
        m = { builtins.oldfiles, "oldfiles (mru)" },
        k = { builtins.keymaps, "keymaps" },
        -- H = { frecency, "history" },
        P = { installed_plugins, "plugins" },
        o = { builtins.buffers, "buffers" },
        O = { orgfiles, "org files" },
        R = { builtins.reloader, "module reloader" },
        r = { builtins.resume, "resume last picker" },
        s = { builtins.live_grep, "grep string" },
        t = {
          name = "+tmux",
          s = { tmux_sessions, "sessions" },
          w = { tmux_windows, "windows" },
        },
        ["?"] = { builtins.help_tags, "help" },
        h = { builtins.help_tags, "help" },
      },
      ["<leader>c"] = {
        d = { builtins.diagnostics, "telescope: diagnostics" },
        s = { builtins.lsp_document_symbols, "telescope: document symbols" },
        w = { builtins.lsp_dynamic_workspace_symbols, "telescope: search workspace symbols" },
      },
      ["<leader>l"] = {
        d = { builtins.lsp_definitions, "telescope: definitions" },
        D = { builtins.lsp_type_definitions, "telescope: type definitions" },
        r = { builtins.lsp_references, "telescope: references" },
        i = { builtins.lsp_implementations, "telescope: implementations" },
      },
    })
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("tmux")
    require("telescope").load_extension("media_files")
    require("telescope").load_extension("file_browser")
    -- require("telescope").load_extension("smart_history")
  end

  do -- nvim-bufdel
    require("bufdel").setup({
      next = "cycle", -- or 'alternate'
      quit = true,
    })
  end

  do -- telekasten.nvim
    require("telekasten").setup({
      home = mega.dirs.zk,
      dailies = mega.dirs.zk .. "/" .. "daily",
      weeklies = mega.dirs.zk .. "/" .. "weekly",
      templates = mega.dirs.zk .. "/" .. "templates",

      -- image subdir for pasting
      -- subdir name
      -- or nil if pasted images shouldn't go into a special subdir
      image_subdir = nil,

      -- markdown file extension
      extension = ".md",

      -- following a link to a non-existing note will create it
      follow_creates_nonexisting = true,
      dailies_create_nonexisting = true,
      weeklies_create_nonexisting = true,

      -- templates for new notes
      template_new_note = mega.dirs.zk .. "/" .. "templates/new_note.md",
      template_new_daily = mega.dirs.zk .. "/" .. "templates/daily_tk.md",
      template_new_weekly = mega.dirs.zk .. "/" .. "templates/weekly_tk.md",

      -- image link style
      -- wiki:     ![[image name]]
      -- markdown: ![](image_subdir/xxxxx.png)
      image_link_style = "markdown",

      -- integrate with calendar-vim
      plug_into_calendar = true,
      calendar_opts = {
        -- calendar week display mode: 1 .. 'WK01', 2 .. 'WK 1', 3 .. 'KW01', 4 .. 'KW 1', 5 .. '1'
        weeknm = 4,
        -- use monday as first day of week: 1 .. true, 0 .. false
        calendar_monday = 1,
        -- calendar mark: where to put mark for marked days: 'left', 'right', 'left-fit'
        calendar_mark = "left-fit",
      },
      debug = false,

      close_after_yanking = false,
      insert_after_inserting = true,

      -- make syntax available to markdown buffers and telescope previewers
      install_syntax = true,

      -- tag notation: '#tag', ':tag:', 'yaml-bare'
      tag_notation = "#tag",

      -- command palette theme: dropdown (window) or ivy (bottom panel)
      command_palette_theme = "ivy",
    })

    -- nnoremap("<leader>zf", "<cmd>lua require('telekasten').find_notes()<cr>", "telekasten: find notes")
    -- nnoremap("<leader>zn", "<cmd>lua require('telekasten').new_note()<cr>", "telekasten: new note")
    -- nnoremap("<leader>zN", "<cmd>lua require('telekasten').new_templated_notes()<cr>", "telekasten: new templated note")
    -- nnoremap("<leader>z", "<cmd>lua require('telekasten').panel()<CR>", "telekasten: show help panel")

    --[[
    autocmd filetype markdown set tw=120
    nnoremap <leader>zf :lua require('telekasten').find_notes()<CR>
    nnoremap <leader>zd :lua require('telekasten').find_daily_notes()<CR>
    nnoremap <leader>zg :lua require('telekasten').search_notes()<CR>
    nnoremap <leader>zz :lua require('telekasten').follow_link()<CR>
    nnoremap <leader>zT :lua require('telekasten').goto_today()<CR>
    nnoremap <leader>zW :lua require('telekasten').goto_thisweek()<CR>
    nnoremap <leader>zw :lua require('telekasten').find_weekly_notes()<CR>
    nnoremap <leader>zn :lua require('telekasten').new_note()<CR>
    nnoremap <leader>zN :lua require('telekasten').new_templated_note()<CR>
    nnoremap <leader>zy :lua require('telekasten').yank_notelink()<CR>
    nnoremap <leader>zc :lua require('telekasten').show_calendar()<CR>
    nnoremap <leader>zC :CalendarT<CR>
    nnoremap <leader>zi :lua require('telekasten').paste_img_and_link()<CR>
    nnoremap <leader>zt :lua require('telekasten').toggle_todo()<CR>
    nnoremap <leader>zr :lua require('plenary.reload').reload_module('telekasten')<CR>
    nnoremap <leader>zb :lua require('telekasten').show_backlinks()<CR>
    nnoremap <leader>zF :lua require('telekasten').find_friends()<CR>
    nnoremap <leader>zI :lua require('telekasten').insert_img_link({i = true})<CR>
    nnoremap <leader>zp :lua require('telekasten').preview_img()<CR>
    nnoremap <leader>zm :lua require('telekasten').browse_media()<CR>
    nnoremap <leader>z :lua require('telekasten').panel()<CR>
    nnoremap <leader>za :lua require('telekasten').show_tags()<CR>

    noremap <leader>P :MarkdownPreviewToggle<CR>

    " autocmd FileType markdown set syntax=telekasten

    hi tklink ctermfg=72 guifg=#689d6a cterm=bold,underline gui=bold,underline
    hi tkBrackets ctermfg=gray guifg=gray

    " real yellow
    hi tkHighlight ctermbg=yellow ctermfg=darkred cterm=bold guibg=yellow guifg=darkred gui=bold
    " gruvbox
    hi tkHighlight ctermbg=214 ctermfg=124 cterm=bold guibg=#fabd2f guifg=#9d0006 gui=bold

    hi link CalNavi CalRuler
    hi tkTagSep ctermfg=gray guifg=gray
    hi tkTag ctermfg=175 guifg=#d3869B

    if has('termguicolors')
      set termguicolors
    endif

    " note: we define [[ in **insert mode** to call insert link
    " note: we don't do this anymore - maybe it makes sense to limit to markdown
    " mode
    inoremap <leader>[ <ESC>:lua require('telekasten').insert_link({i = true})<CR>
    " inoremap [[ <ESC>:lua require('telekasten').insert_link({i = true})<CR>
    inoremap <leader>zt <ESC>:lua require('telekasten').toggle_todo({i = true})<CR>
    inoremap <leader># <cmd>lua require('telekasten').show_tags({i = true})<cr>
    --]]
  end

  do -- zk-nvim
    -- REFS:
    -- https://github.com/mbriggs/nvim/blob/main/lua/mb/zk.lua
    -- https://github.com/pwntester/dotfiles/blob/master/config/nvim/lua/pwntester/zk.lua
    -- https://github.com/kabouzeid/dotfiles/blob/main/config/nvim/lua/lsp-settings.lua#L160-L198
    local zk = require("zk")
    local commands = require("zk.commands")

    zk.setup({
      picker = "telescope",
      create_user_commands = true,
      lsp = {
        cmd = { "zk", "lsp" },
        name = "zk",
        on_attach = function(client, bufnr)
          require("lsp").on_attach(client, bufnr)
        end,
      },
      auto_attach = {
        enabled = true,
        filetypes = { "markdown", "liquid" },
      },
    })

    local function make_edit_fn(defaults, picker_options)
      return function(options)
        options = vim.tbl_extend("force", defaults, options or {})
        zk.edit(options, picker_options)
      end
    end

    commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "Zk Orphans" }))
    commands.add("ZkRecents", make_edit_fn({ createdAfter = "2 weeks ago" }, { title = "Zk Recents" }))

    nnoremap("<Leader>zc", "<cmd>ZkNew<CR>", "zk: new note")
    xnoremap("<Leader>zc", ":'<'>ZkNewFromTitleSelection<CR>", "zk: new note from selection")
    nnoremap("<Leader>zn", "<cmd>ZkNotes<CR>", "zk: find notes")
    nnoremap("<Leader>zb", "<cmd>ZkBacklinks<CR>", "zk: find backlinks")
    nnoremap("<Leader>zl", "<cmd>ZkLinks<CR>", "zk: find links")
    nnoremap("<Leader>zt", "<cmd>ZkTags<CR>", "zk: find tags")
    nnoremap("<Leader>zo", "<cmd>ZkOrphans<CR>", "zk: find orphans")
    nnoremap("<Leader>zr", "<cmd>ZkRecents<CR>", "zk: find recents")
  end

  do -- alpha.nvim
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    math.randomseed(os.time())

    local function button(sc, txt, keybind, keybind_opts)
      local b = dashboard.button(sc, txt, keybind, keybind_opts)
      b.opts.hl = "Function"
      b.opts.hl_shortcut = "Type"
      return b
    end

    local function pick_color()
      local clrs = { "String", "Identifier", "Keyword", "Number" }
      return clrs[math.random(#clrs)]
    end

    local function footer()
      local datetime = os.date("%d-%m-%Y  %H:%M:%S")
      return {
        -- require("colors").icons.git_symbol .. " " .. fn["gitbranch#name"](),
        vim.loop.cwd(),
        datetime,
      }
    end

    -- REF: https://patorjk.com/software/taag/#p=display&f=Elite&t=MEGALITHIC
    dashboard.section.header.val = {
      "• ▌ ▄ ·. ▄▄▄ . ▄▄ •  ▄▄▄· ▄▄▌  ▪  ▄▄▄▄▄ ▄ .▄▪   ▄▄·",
      "·██ ▐███▪▀▄.▀·▐█ ▀ ▪▐█ ▀█ ██•  ██ •██  ██▪▐███ ▐█ ▌▪",
      "▐█ ▌▐▌▐█·▐▀▀▪▄▄█ ▀█▄▄█▀▀█ ██▪  ▐█· ▐█.▪██▀▐█▐█·██ ▄▄",
      "██ ██▌▐█▌▐█▄▄▌▐█▄▪▐█▐█ ▪▐▌▐█▌▐▌▐█▌ ▐█▌·██▌▐▀▐█▌▐███▌",
      "▀▀  █▪▀▀▀ ▀▀▀ ·▀▀▀▀  ▀  ▀ .▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ·▀▀▀·▀▀▀",
    }

    dashboard.section.header.opts.hl = pick_color()
    dashboard.section.buttons.val = {
      button("m", "  Recently opened files", "<cmd>lua require('telescope').oldfiles()<cr>"),
      button("f", "  Find file", "<cmd>lua require('telescope').find_files()<cr>"),
      button("a", "  Find word", "<cmd>lua require('telescope').live_grep()<cr>"),
      button("e", "  New file", "<cmd>ene <BAR> startinsert <CR>"),
      button("p", "  Update plugins", "<cmd>lua mega.sync_plugins()<CR>"),
      button("q", "  Quit", "<cmd>qa<CR>"),
    }

    dashboard.section.footer.val = footer()
    dashboard.section.footer.opts.hl = "Constant"
    dashboard.section.footer.opts.position = "center"

    alpha.setup(dashboard.opts)
  end

  do -- distant.nvim
    local actions = require("distant.nav.actions")

    require("distant").setup({
      ["198.74.55.152"] = { -- 198.74.55.152
        max_timeout = 15000,
        poll_interval = 250,
        timeout_interval = 250,
        ssh = {
          user = "ubuntu",
          identity_file = "~/.ssh/seth-Seths-MBP.lan",
        },
        distant = {
          bin = "/home/ubuntu/.asdf/installs/rust/stable/bin/distant",
          username = "ubuntu",
          args = "\"--log-file ~/tmp/distant-seth_dev-server.log --log-level trace --port 8081:8099 --shutdown-after 60\"",
        },
        file = {},
        dir = {},
        lsp = {
          ["outstand/atlas (elixirls)"] = {
            cmd = { require("utils").lsp.elixirls_cmd({ fallback_dir = "/home/ubuntu/.local/share" }) },
            root_dir = "/home/ubuntu/code/atlas",
            filetypes = { "elixir", "eelixir" },
            on_attach = function(client, bufnr)
              print(vim.inspect(client), bufnr)
            end,
            log_file = "~/tmp/distant-pages-elixirls.log",
            log_level = "trace",
          },
        },
      },
      ["megalithic.io"] = { -- 198.199.91.123
        launch = {
          distant = "/home/replicant/.cargo/bin/distant",
          username = "replicant",
          identity_file = "~/.ssh/seth-Seths-MacBook-Pro.local",
          extra_server_args = "\"--log-file ~/tmp/distant-megalithic_io-server.log --log-level trace --port 8081:8099 --shutdown-after 60\"",
        },
      },

      -- Apply these settings to any remote host
      ["*"] = {
        -- max_timeout = 60000,
        -- timeout_interval = 200,
        client = {
          log_file = "~/tmp/distant-client.log",
          log_level = "trace",
        },
        launch = {
          extra_server_args = "\"--log-file ~/tmp/distant-all-server.log --log-level trace --port 8081:8999 --shutdown-after 60\"",
        },
        file = {
          mappings = {
            ["-"] = actions.up,
          },
        },
        dir = {
          mappings = {
            ["<Return>"] = actions.edit,
            ["-"] = actions.up,
            ["K"] = actions.mkdir,
            ["N"] = actions.newfile,
            ["R"] = actions.rename,
            ["D"] = actions.remove,
          },
        },
      },
    })
  end

  do -- tabout.nvim
    require("tabout").setup({
      completion = false,
      ignore_beginning = false,
    })
  end

  do -- headlines.nvim
    fn.sign_define("Headline1", { linehl = "Headline1" })
    fn.sign_define("Headline2", { linehl = "Headline2" })
    fn.sign_define("Headline3", { linehl = "Headline3" })
    fn.sign_define("Headline4", { linehl = "Headline4" })
    fn.sign_define("Headline5", { linehl = "Headline5" })
    fn.sign_define("Headline6", { linehl = "Headline6" })

    require("headlines").setup({
      markdown = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        headline_pattern = "^#+",
        headline_signs = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
      },
      org = {
        source_pattern_start = "#%+[bB][eE][gG][iI][nN]_[sS][rR][cC]",
        source_pattern_end = "#%+[eE][nN][dD]_[sS][rR][cC]",
        dash_pattern = "^-----+$",
        headline_pattern = "^%*+",
        headline_signs = { "Headline" },
        codeblock_sign = "CodeBlock",
        dash_highlight = "Dash",
      },
    })
  end

  do -- filetype.nvim
    require("filetype").setup({
      overrides = {
        literal = {
          ["kitty.conf"] = "kitty",
          [".gitignore"] = "conf",
          [".env"] = "sh",
        },
      },
    })
  end

  do -- nvim-tree.nvim
    -- local action = require("nvim-tree.config").nvim_tree_callback
    vim.g.nvim_tree_icons = {
      default = "",
      git = {
        unstaged = "",
        staged = "",
        unmerged = "",
        renamed = "",
        untracked = "",
        deleted = "",
      },
    }
    vim.g.nvim_tree_special_files = {}
    vim.g.nvim_tree_indent_markers = 1
    vim.g.nvim_tree_group_empty = 1
    vim.g.nvim_tree_git_hl = 1
    vim.g.nvim_tree_width_allow_resize = 1
    vim.g.nvim_tree_root_folder_modifier = ":t"
    vim.g.nvim_tree_highlight_opened_files = 1

    local tree_cb = require("nvim-tree.config").nvim_tree_callback
    require("nvim-tree").setup({
      view = {
        width = "20%",
        auto_resize = true,
        list = {
          -- { key = "cd", cb = action("cd") },
        },
      },
      nvim_tree_ignore = { ".DS_Store", "fugitive:", ".git" },
      diagnostics = {
        enable = true,
      },
      disable_netrw = false,
      hijack_netrw = true,
      open_on_setup = true,
      hijack_cursor = true,
      update_cwd = true,
      update_focused_file = {
        enable = true,
        update_cwd = true,
      },
      mappings = {
        { key = { "<CR>", "o", "<2-LeftMouse>" }, cb = tree_cb("edit") },
        { key = { "<2-RightMouse>", "<C-]>" }, cb = tree_cb("cd") },
        { key = "<C-v>", cb = tree_cb("vsplit") },
        { key = "<C-x>", cb = tree_cb("split") },
        { key = "<C-t>", cb = tree_cb("tabnew") },
        { key = "<", cb = tree_cb("prev_sibling") },
        { key = ">", cb = tree_cb("next_sibling") },
        { key = "P", cb = tree_cb("parent_node") },
        { key = "<BS>", cb = tree_cb("close_node") },
        { key = "<S-CR>", cb = tree_cb("close_node") },
        { key = "<Tab>", cb = tree_cb("preview") },
        { key = "K", cb = tree_cb("first_sibling") },
        { key = "J", cb = tree_cb("last_sibling") },
        { key = "I", cb = tree_cb("toggle_ignored") },
        { key = "H", cb = tree_cb("toggle_dotfiles") },
        { key = "R", cb = tree_cb("refresh") },
        { key = "a", cb = tree_cb("create") },
        { key = "d", cb = tree_cb("remove") },
        { key = "r", cb = tree_cb("rename") },
        { key = "<C-r>", cb = tree_cb("full_rename") },
        { key = "x", cb = tree_cb("cut") },
        { key = "c", cb = tree_cb("copy") },
        { key = "p", cb = tree_cb("paste") },
        { key = "y", cb = tree_cb("copy_name") },
        { key = "Y", cb = tree_cb("copy_path") },
        { key = "gy", cb = tree_cb("copy_absolute_path") },
        { key = "[c", cb = tree_cb("prev_git_item") },
        { key = "]c", cb = tree_cb("next_git_item") },
        { key = "-", cb = tree_cb("dir_up") },
        { key = "s", cb = tree_cb("system_open") },
        { key = "q", cb = tree_cb("close") },
        { key = "g?", cb = tree_cb("toggle_help") },
      },
    })
  end

  do -- dd.nvim
    require("dd").setup({ timeout = 500 })
  end

  do -- dash.nvim
    -- if fn.getenv("PLATFORM") == "macos" then
    --   vcmd([[packadd dash.nvim]])
    --   require("dash").setup({})
    -- end
  end

  do -- nvim-gps
    require("nvim-gps").setup({
      languages = {
        elixir = false,
        eelixir = false,
      },
    })
  end

  do -- misc
    vim.g.fzf_gitignore_no_maps = true
  end
end

return M
