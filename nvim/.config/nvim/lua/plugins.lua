return {
  {"savq/paq-nvim", opt = true},
  "tweekmonster/startuptime.vim",
  --
  -- (appearance/ui) --
  "sainnhe/everforest",
  "norcalli/nvim-colorizer.lua",
  {"dm1try/golden_size", branch = "layout_resizing"},
  "junegunn/rainbow_parentheses.vim",
  "kyazdani42/nvim-web-devicons",
  -- "yamatsum/nvim-nonicons",
  "hoob3rt/lualine.nvim",
  "danilamihailov/beacon.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "psliwka/vim-smoothie",
  "lukas-reineke/indent-blankline.nvim",
  --
  -- (lsp/completion) --
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  "hrsh7th/nvim-compe",
  "hrsh7th/vim-vsnip",
  "hrsh7th/vim-vsnip-integ",
  "rafamadriz/friendly-snippets",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "ray-x/lsp_signature.nvim",
  "jose-elias-alvarez/null-ls.nvim",
  "folke/trouble.nvim",
  --
  -- (treesitter) --
  {"nvim-treesitter/nvim-treesitter", run = "TSUpdate"},
  {"nvim-treesitter/completion-treesitter", run = "TSUpdate"},
  "nvim-treesitter/nvim-treesitter-textobjects",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  --
  -- (file/document navigation) --
  "ibhagwan/fzf-lua",
  "vijaymarupudi/nvim-fzf",
  "nvim-telescope/telescope.nvim",
  {"nvim-telescope/telescope-fzf-native.nvim", run = "make"},
  "unblevable/quick-scope",
  --
  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-operator-user",
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
  -- research: rcarriga/vim-ultest
  "tpope/vim-ragtag",
  "rizzatti/dash.vim",
  "skywind3000/vim-quickui",
  "sgur/vim-editorconfig",
  {"zenbro/mirror.vim", opt = true},
  --
  -- (markdown/prose/notes) --
  {"iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"]},
  "dkarter/bullets.vim",
  "kristijanhusak/orgmode.nvim",
  "megalithic/zk.nvim",
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
  "tpope/vim-rails",
  "antew/vim-elm-analyse",
  "avdgaag/vim-phoenix",
  "lucidstack/hex.vim",
  "euclidianace/betterlua.vim",
  "folke/lua-dev.nvim",
  "andrejlevkovitch/vim-lua-format",
  "darfink/vim-plist",
  "sheerun/vim-polyglot"
}
