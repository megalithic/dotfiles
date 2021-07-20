return {
  {"savq/paq-nvim", opt = true},

  --
  -- (appearance/ui) --
  "sainnhe/everforest",
  "norcalli/nvim-colorizer.lua",
  {"dm1try/golden_size", branch = "layout_resizing"},
  "junegunn/rainbow_parentheses.vim",
  {"kyazdani42/nvim-web-devicons", opt = true},
  "hoob3rt/lualine.nvim",
  "danilamihailov/beacon.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "psliwka/vim-smoothie",

  --
  -- (lsp) --
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  "hrsh7th/nvim-compe",
  "onsails/lspkind-nvim",
  "rafamadriz/friendly-snippets",
  "hrsh7th/vim-vsnip",
  "hrsh7th/vim-vsnip-integ",
  "nvim-lua/lsp-status.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "glepnir/lspsaga.nvim",
  "folke/trouble.nvim",
  {"nvim-treesitter/nvim-treesitter", run = "TSUpdate"},
  {"nvim-treesitter/completion-treesitter", run = "TSUpdate"},
  "nvim-treesitter/nvim-treesitter-textobjects",
  "windwp/nvim-ts-autotag",

  --
  -- (file/document navigation) --
  "nvim-telescope/telescope.nvim",
  "unblevable/quick-scope",

  --
  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-operator-user",
  "wellle/targets.vim",

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
  "tpope/vim-ragtag",
  "rizzatti/dash.vim",
  "skywind3000/vim-quickui",
  "sgur/vim-editorconfig",
  {"zenbro/mirror.vim", opt = true},

  --
  -- (markdown/prose/notes) --
  {"folke/zen-mode.nvim", opt = true},
  {"iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"]},
  "dkarter/bullets.vim",
  "kristijanhusak/orgmode.nvim",

  --
  -- (the rest...) --
  "ojroques/vim-oscyank",
  "farmergreg/vim-lastplace",
  "andymass/vim-matchup",
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
  -- "wellle/visual-split.vim",
  "junegunn/vim-slash",
  "junegunn/vim-easy-align",
  -- "gennaro-tedesco/nvim-peekup", -- peek into the vim registers in floating window

  --
  -- (langs, syntax, et al) --
  "tpope/vim-rails",
  "antew/vim-elm-analyse",
  "avdgaag/vim-phoenix",
  "lucidstack/hex.vim",
  "euclidianace/betterlua.vim",
  "andrejlevkovitch/vim-lua-format",
  "darfink/vim-plist",
  "sheerun/vim-polyglot"
}

