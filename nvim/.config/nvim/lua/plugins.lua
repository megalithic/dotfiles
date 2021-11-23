-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs
-- # local/devel paqs stored here:
--  ~/.local/share/nvim/site/pack/local

return {
  { "savq/paq-nvim" },

  --
  -- (profiling/speed improvements) --
  "dstein64/vim-startuptime",
  "lewis6991/impatient.nvim",
  "nathom/filetype.nvim",

  --
  -- (appearance/ui/visuals) --
  "rktjmp/lush.nvim",
  "mhanberg/thicc_forest",
  "norcalli/nvim-colorizer.lua",
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  "danilamihailov/beacon.nvim",
  "antoinemadec/FixCursorHold.nvim", -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
  "karb94/neoscroll.nvim",
  "lukas-reineke/indent-blankline.nvim",
  "MunifTanjim/nui.nvim",
  "folke/which-key.nvim",
  "goolord/alpha-nvim",
  -- "megalithic/shade.nvim", -- FIXME: too many broke things for various plugins
  -- "jceb/blinds.nvim",
  -- "akinsho/bufferline.nvim",

  --
  -- (lsp/completion) --
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
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "tzachar/fuzzy.nvim",
  "tzachar/cmp-fuzzy-path",
  "tzachar/cmp-fuzzy-buffer",
  "petertriho/cmp-git",
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  -- "github/copilot.vim",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "ray-x/lsp_signature.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L203-L226
  "b0o/schemastore.nvim",
  "folke/trouble.nvim",
  -- "SmiteshP/nvim-gps", -- this is breaking elixir TS parser/grammar
  "abecodes/tabout.nvim",
  { url = "https://gitlab.com/yorickpeterse/nvim-dd.git" },

  --
  -- (treesitter) --
  {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      vim.cmd("TSUpdate")
    end,
  },
  -- "nvim-treesitter/nvim-treesitter-textobjects",
  "nvim-treesitter/playground",
  -- "RRethy/nvim-treesitter-textsubjects",
  -- "mfussenegger/nvim-ts-hint-textobject",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  -- "lewis6991/spellsitter.nvim", -- https://github.com/ful1e5/dotfiles/blob/main/nvim/.config/nvim/lua/plugins-cfg/spellsitter/init.lua

  --
  -- (file/document navigation) --
  "ibhagwan/fzf-lua",
  "vijaymarupudi/nvim-fzf",
  "ggandor/lightspeed.nvim",
  "voldikss/vim-floaterm",
  "kyazdani42/nvim-tree.lua",
  -- "folke/todo-comments.nvim",

  --
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

  --
  -- (git, vcs, et al) --
  -- {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "mattn/webapi-vim",
  "rhysd/conflict-marker.vim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "sindrets/diffview.nvim",
  -- "lewis6991/gitsigns.nvim",
  "dinhhuy258/git.nvim",
  -- "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  "pwntester/octo.nvim", -- https://github.com/ryansch/dotfiles/commit/2d0dc63bea2f921de1236c2800605551fb4b3041#diff-45b8a59e398d12063977c5b27e0d065150544908fd4ad8b3e10b2d003c5f4439R119-R246
  "ruifm/gitlinker.nvim",

  --
  -- (development, et al) --
  "ahmedkhalf/project.nvim",
  "tpope/vim-projectionist",
  -- "tjdevries/edit_alternate.vim",
  "janko/vim-test", -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
  "tpope/vim-ragtag",
  { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  "vuki656/package-info.nvim",
  -- "jamestthompson3/nvim-remote-containers",
  "chipsenkbeil/distant.nvim",
  "tpope/vim-dadbod",
  "kristijanhusak/vim-dadbod-completion",
  "kristijanhusak/vim-dadbod-ui",
  --
  -- (the rest...) --
  -- "b0o/mapx.nvim",
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
  -- "ConradIrwin/vim-bracketed-paste", -- FIXME: delete?
  -- "sickill/vim-pasta", -- FIXME: delete?
  -- "kevinhwang91/nvim-hclipboard",
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  "tpope/vim-scriptease",
  "sunaku/tmux-navigate",
  -- "aserowy/tmux.nvim",
  -- "christoomey/vim-tmux-navigator",
  -- "tmux-plugins/vim-tmux-focus-events",
  -- "numtostr/Navigator.nvim",
  -- "christoomey/vim-tmux-runner",
  "junegunn/vim-slash",
  "junegunn/vim-easy-align",
  -- use_with_config("svermeulen/vim-cutlass", "cutlass") -- separates cut and delete operations
  --     use_with_config("svermeulen/vim-yoink", "yoink") -- improves paste

  --
  -- (langs, syntax, et al) --
  -- # markdown/prose
  -- "plasticboy/vim-markdown", -- replacing with the below:
  "ixru/nvim-markdown",
  -- "rhysd/vim-gfm-syntax",
  { "iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"] },
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
  -- "megalithic/zk.nvim",
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
