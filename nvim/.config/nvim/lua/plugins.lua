return {
  {"savq/paq-nvim"},
  --
  -- (profiling) --
  "dstein64/vim-startuptime",
  --
  -- (appearance/ui) --
  "sainnhe/everforest",
  "savq/melange",
  "rktjmp/lush.nvim",
  "norcalli/nvim-colorizer.lua",
  "dm1try/golden_size",
  "junegunn/rainbow_parentheses.vim",
  "kyazdani42/nvim-web-devicons",
  "danilamihailov/beacon.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "karb94/neoscroll.nvim",
  "lukas-reineke/indent-blankline.nvim",
  --
  -- (lsp/completion) --
  "neovim/nvim-lspconfig",
  "kabouzeid/nvim-lspinstall",
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  "hrsh7th/nvim-compe",
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "ray-x/lsp_signature.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L203-L226
  "folke/trouble.nvim",
  --
  -- (treesitter) --
  {"nvim-treesitter/nvim-treesitter", vim.fn[":TSUpdate"]},
  "nvim-treesitter/nvim-treesitter-textobjects",
  "RRethy/nvim-treesitter-textsubjects",
  "ikatyang/tree-sitter-markdown",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  -- "lewis6991/spellsitter.nvim", -- https://github.com/ful1e5/dotfiles/blob/main/nvim/.config/nvim/lua/plugins-cfg/spellsitter/init.lua
  --
  -- (file/document navigation) --
  "ibhagwan/fzf-lua",
  "vijaymarupudi/nvim-fzf",
  "archaict/fzf-lua-extensions",
  "ggandor/lightspeed.nvim",
  --
  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-textobj-user",
  "kana/vim-operator-user",
  "mattn/vim-textobj-url",
  "whatyouhide/vim-textobj-xmlattr",
  "amiralies/vim-textobj-elixir",
  "wellle/targets.vim",
  -- research: windwp/nvim-spectre
  --
  -- (git, vcs, et al) --
  "tpope/vim-fugitive",
  -- {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"},
  -- "mattn/webapi-vim",
  "rhysd/conflict-marker.vim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "sindrets/diffview.nvim",
  -- "lewis6991/gitsigns.nvim",
  "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  --
  -- (development, et al) --
  "tpope/vim-projectionist",
  "janko/vim-test",
  -- research to supplement vim-test: rcarriga/vim-ultest
  "tpope/vim-ragtag",
  "rizzatti/dash.vim",
  "skywind3000/vim-quickui",
  "sgur/vim-editorconfig",
  {"zenbro/mirror.vim", opt = true},
  --
  -- (the rest...) --
  "ojroques/vim-oscyank",
  "farmergreg/vim-lastplace",
  "andymass/vim-matchup", -- https://github.com/andymass/vim-matchup#tree-sitter-integration
  "windwp/nvim-autopairs", -- https://github.com/windwp/nvim-autopairs#using-nvim-compe
  "alvan/vim-closetag",
  "b3nj5m1n/kommentary",
  "tpope/vim-eunuch",
  "tpope/vim-abolish",
  "tpope/vim-rhubarb",
  "tpope/vim-repeat",
  "tpope/vim-surround",
  "tpope/vim-unimpaired",
  "EinfachToll/DidYouMean",
  "jordwalke/VimAutoMakeDirectory",
  "wsdjeg/vim-fetch", -- vim path/to/file.ext:12:3
  "ConradIrwin/vim-bracketed-paste",
  "sickill/vim-pasta",
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  "tpope/vim-scriptease",
  "christoomey/vim-tmux-navigator",
  "tmux-plugins/vim-tmux-focus-events",
  "christoomey/vim-tmux-runner",
  "junegunn/vim-slash",
  "junegunn/vim-easy-align",
  --
  -- (langs, syntax, et al) --
  -- # markdown/prose
  "plasticboy/vim-markdown",
  {"iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"]},
  {"harshad1/bullets.vim", branch = "performance_improvements"}, -- "dkarter/bullets.vim"
  "kristijanhusak/orgmode.nvim",
  "akinsho/org-bullets.nvim",
  "megalithic/zk.nvim",
  "dhruvasagar/vim-table-mode",
  -- # ruby/rails
  -- "vim-ruby/vim-ruby",
  "tpope/vim-rails",
  -- # elm
  "antew/vim-elm-analyse",
  -- # elixir/phoenix/erlang
  "elixir-editors/vim-elixir",
  "avdgaag/vim-phoenix",
  "lucidstack/hex.vim",
  -- # lua
  "tjdevries/nlua.nvim",
  "norcalli/nvim.lua",
  "euclidianace/betterlua.vim",
  "folke/lua-dev.nvim",
  "andrejlevkovitch/vim-lua-format",
  -- # rust
  -- "rust-lang/rust.vim",
  "racer-rust/vim-racer",
  -- # JS/TS/JSON
  -- "pangloss/vim-javascript",
  -- "isRuslan/vim-es6",
  -- "othree/yajs.vim",
  "MaxMEllon/vim-jsx-pretty",
  "heavenshell/vim-jsdoc",
  -- "HerringtonDarkholme/yats.vim",
  "jxnblk/vim-mdx-js",
  -- # HTML
  -- "othree/html5.vim",
  -- "mattn/emmet-vim",
  "skwp/vim-html-escape",
  "pedrohdz/vim-yaml-folds",
  -- # CSS
  -- "hail2u/vim-css3-syntax",
  -- # misc
  "avakhov/vim-yaml",
  "chr4/nginx.vim"
}
