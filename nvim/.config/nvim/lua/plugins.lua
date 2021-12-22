local api = vim.api
local vcmd = vim.cmd
local fn = vim.fn

local C = require("colors")

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
  "karb94/neoscroll.nvim",
  "lukas-reineke/indent-blankline.nvim",
  "MunifTanjim/nui.nvim",
  -- "folke/which-key.nvim",
  "goolord/alpha-nvim",
  -- "megalithic/shade.nvim", -- FIXME: too many broke things for various plugins
  -- "jceb/blinds.nvim",
  -- "akinsho/bufferline.nvim",

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
  -- "tzachar/fuzzy.nvim",
  -- { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  -- "tzachar/cmp-fuzzy-path",
  -- "tzachar/cmp-fuzzy-buffer",
  --

  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "ray-x/lsp_signature.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  "folke/trouble.nvim",
  "abecodes/tabout.nvim",
  { url = "https://gitlab.com/yorickpeterse/nvim-dd.git" },
  -- "stevearc/dressing.nvim", -- auto UI things for new 0.6 apis

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
  -- "romgrk/nvim-treesitter-context",

  ------------------------------------------------------------------------------
  -- (FZF/file/document navigation) --
  "ibhagwan/fzf-lua",
  "ggandor/lightspeed.nvim",
  "voldikss/vim-floaterm",
  "kyazdani42/nvim-tree.lua",

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
  "dinhhuy258/git.nvim",
  -- "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  "pwntester/octo.nvim", -- https://github.com/ryansch/dotfiles/commit/2d0dc63bea2f921de1236c2800605551fb4b3041#diff-45b8a59e398d12063977c5b27e0d065150544908fd4ad8b3e10b2d003c5f4439R119-R246
  "ruifm/gitlinker.nvim",

  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  "ahmedkhalf/project.nvim",
  "tpope/vim-projectionist",
  -- "tjdevries/edit_alternate.vim",
  "janko/vim-test", -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
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
  "sickill/vim-pasta", -- FIXME: delete?
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
  { "iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"] },
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
  "mickael-menu/zk-nvim",
  -- "NFrid/due.nvim",
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

  do -- treesitter.nvim
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
        "markdown",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
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
          init_selection = "<CR>",
          scope_incremental = "<CR>",
          node_incremental = "<TAB>",
          node_decremental = "<S-TAB>",
        },
      },
      -- textsubjects = {
      --   enable = false,
      --   keymaps = {
      --     ["."] = "textsubjects-smart",
      --     [";"] = "textsubjects-container-outer",
      --     -- [";"] = "textsubjects-big",
      --   },
      -- },
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
        "flutterToolsOutline",
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
            if vim.fn.executable("terminal-notifier") then
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
            -- if vim.fn.executable("notify-send") then
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
      ignore_filetypes = { "fzf", "NvimTree", "alpha" },
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
      check_ts = true,
      close_triple_quotes = true,
      -- FIXME: what is this?
      -- ts_config = {
      -- 	lua = { "string" },
      -- 	-- it will not add pair on that treesitter node
      -- 	javascript = { "template_string" },
      -- 	java = false,
      -- 	-- don't check treesitter on java
      -- },
    })
    npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
    local endwise = require("nvim-autopairs.ts-rule").endwise
    npairs.add_rules({
      endwise("then$", "end", "lua", nil),
      endwise("do$", "end", "lua", nil),
      endwise(" do$", "end", "elixir", nil),
    })
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

  do -- git-messenger.nvim
    vim.g.git_messenger_floating_win_opts = { border = vim.g.floating_window_border_dark }
    vim.g.git_messenger_no_default_mappings = true
    vim.g.git_messenger_max_popup_width = 100
    vim.g.git_messenger_max_popup_height = 100
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
          ["type"] = "spec",
        },
        ["app/webpacker/src/javascript/*.tsx"] = {
          ["alternate"] = "spec/javascript/{}.test.tsx",
          ["type"] = "source",
        },
        ["spec/javascript/*.test.ts"] = {
          ["alternate"] = "app/webpacker/src/javascript/{}.ts",
          ["type"] = "spec",
        },
        ["app/webpacker/src/javascript/*.ts"] = {
          ["alternate"] = "spec/javascript/{}.test.ts",
          ["type"] = "source",
        },
      },
      -- https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/after/ftplugin/elixir.vim
      ["mix.exs"] = {
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
        ["lib/**/live/*_live.ex"] = {
          ["type"] = "liveview",
          ["alternate"] = "test/{dirname}/views/{basename}_live_test.exs",
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
        up_to_date = C.cs.bg2, -- Text color for up to date package virtual text
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

  do -- zk
    local zk = require("zk")
    zk.setup({
      filetypes = { "markdown", "liquid" },
      on_attach = function(client, bufnr)
        local function buf_set_keymap(...)
          vim.api.nvim_buf_set_keymap(bufnr, ...)
        end
        local opts = { noremap = true, silent = true }

        require("lsp").on_attach(client, bufnr)

        buf_set_keymap("n", "<C-t>", [[:Notes<cr>]], opts)
        buf_set_keymap("n", "<leader>zt", [[:Tags<cr>]], opts)
        buf_set_keymap("n", "<leader>zl", [[:Links<cr>]], opts)
        buf_set_keymap("n", "<leader>zb", [[:Backlinks<cr>]], opts)
        buf_set_keymap("n", "<leader>zd", ":ZkDaily<cr>", opts)
        buf_set_keymap("v", "<leader>zn", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)

        -- buf_set_keymap("n", "<A-j>", [[:lua motch.dnd.move_to("previous")<cr>]], opts)
        -- buf_set_keymap("n", "<A-k>", [[:lua motch.dnd.move_to("next")<cr>]], opts)
      end,
    })

    -- vcmd([[command! -nargs=0 ZkIndex :lua require'lspconfig'.zk.index()]])
    -- vcmd([[command! -nargs=? ZkNew :lua require'lspconfig'.zk.new(<args>)]])
    -- vcmd(
    --   [[command! ZkList :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=notes EDITOR=floaterm zk edit -i]]
    -- )
    -- vcmd(
    --   [[command! ZkTags :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=tags zk list -q -f json | jq -r '. | map(.tags) | flatten | unique | join("\n")' | fzf | EDITOR=floaterm xargs -o -t zk edit -i -t]]
    -- )
    -- vcmd(
    --   [[command! ZkBacklinks :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=backlinks EDITOR=floaterm zk edit -i -l %]]
    -- )
    -- vcmd(
    --   [[command! ZkLinks :FloatermNew --autoclose=2 --position=top --opener=edit --width=0.9 --title=links EDITOR=floaterm zk edit -i -L %]]
    -- )

    -- mega.zk_list = function()
    --   vcmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
    --   vcmd([[ZkList]])
    -- end

    -- mega.zk_by_tags = function()
    --   vcmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
    --   vcmd([[ZkTags]])
    -- end

    -- mega.zk_backlinks = function()
    --   vcmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
    --   vcmd([[ZkBacklinks]])
    -- end

    -- mega.zk_links = function()
    --   vcmd([[autocmd User FloatermOpen ++once :tnoremap <buffer> <esc> <C-c>]])
    --   vcmd([[ZkLinks]])
    -- end

    -- local rooter = require("lspconfig").util.root_pattern(".zk")
    -- local rooted = rooter(api.nvim_buf_get_name(0))
    -- local is_zk = fn.empty(rooted)
    -- if is_zk == 0 then
    --   map("n", "<leader>fz", ":lua mega.zk_list()<cr>")
    --   map("n", "<leader>zt", ":lua mega.zk_by_tags()<cr>")
    --   map("n", "<leader>zb", ":lua mega.zk_backlinks()<cr>")
    --   map("n", "<leader>zl", ":lua mega.zk_links()<cr>")
    -- end
  end

  do -- fzf-lua.nvim
    local actions = require("fzf-lua.actions")
    require("fzf-lua").setup({
      -- fzf_args = vim.env.FZF_DEFAULT_OPTS .. " --border rounded",
      fzf_layout = "default",
      winopts = {
        height = 0.6,
        width = 0.65,
        border = false,
        preview = { default = "bat_native", scrollbar = false },
      },
      previewers = {
        bat = {
          cmd = "bat",
          args = "--style=numbers,changes --color always",
          theme = "Forest%20Night%20Italic",
          config = nil,
        },
      },
      oldfiles = {
        actions = {
          ["default"] = actions.file_vsplit,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-o"] = actions.file_edit,
        },
      },
      files = {
        multiprocess = true,
        prompt = string.format("files %s ", C.icons.prompt_symbol),
        fd_opts = [[--type f --follow --hidden --color=always]]
          .. [[ -E '.git' -E 'node_modules' -E '*.png' -E '*.jpg' -E '**/Spoons' -E '.yarn' ]]
          .. [[ --ignore-file '.gitignore']],
        color_icons = true,
        git_icons = false,
        git_diff_cmd = "git diff --name-status --relative HEAD",
        actions = {
          ["default"] = actions.file_vsplit,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-o"] = actions.file_edit,
        },
      },
      grep = {
        multiprocess = true,
        input_prompt = string.format("grep for %s ", C.icons.prompt_symbol),
        prompt = string.format("grep %s ", C.icons.prompt_symbol),
        continue_last_search = false,
        actions = {
          ["default"] = actions.file_vsplit,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-o"] = actions.file_edit,
        },
      },
      lsp = {
        prompt = string.format("%s ", C.icons.prompt_symbol),
        cwd_only = false, -- LSP/diagnostics for cwd only?
        async_or_timeout = false,
        jump_to_single_result = true,
        actions = {
          ["default"] = actions.file_vsplit,
          ["ctrl-t"] = actions.file_tabedit,
          ["ctrl-o"] = actions.file_edit,
        },
      },
      buffers = {
        prompt = string.format("buffers %s ", C.icons.prompt_symbol),
      },
    })
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
        -- require("colors").icons.git_symbol .. " " .. vim.fn["gitbranch#name"](),
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
      button(
        "m",
        "  Recently opened files",
        "<cmd>lua require('fzf-lua').oldfiles({actions = {['default'] = require('fzf-lua.actions').file_edit}})<cr>"
      ),
      button(
        "f",
        "  Find file",
        "<cmd>lua require('fzf-lua').files({actions = {['default'] = require('fzf-lua.actions').file_edit}})<cr>"
      ),
      button(
        "a",
        "  Find word",
        "<cmd>lua require('fzf-lua').live_grep({actions = {['default'] = require('fzf-lua.actions').file_edit}})<cr>"
      ),
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
            cmd = { require("utils").lsp.elixirls_cmd({ fallback_dir = "/home/ubuntu/.config" }) },
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
    -- vim.cmd([[highlight Headline1 guibg=#1e2718]])
    -- vim.cmd([[highlight Headline2 guibg=#21262d]])
    -- vim.cmd([[highlight CodeBlock guibg=#1c1c1c]])

    vim.cmd([[highlight Dash guifg=#D19A66 gui=bold]])
    vim.fn.sign_define("Headline1", { linehl = "Headline1" })
    vim.fn.sign_define("Headline2", { linehl = "Headline2" })
    vim.fn.sign_define("Headline3", { linehl = "Headline3" })

    -- require("headlines").setup {
    --     org = {
    --         headline_signs = { "Headline1", "Headline2" },
    --     },
    -- }
    require("headlines").setup({
      markdown = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        headline_pattern = "^#+",
        headline_signs = { "Headline1", "Headline2", "Headline3" },
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
      disable_netrw = true,
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
