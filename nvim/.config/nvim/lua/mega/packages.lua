--NOTE: Packages are in the runtimepath, this file is only loaded for updates.
mega.inspect("activating packages.lua..")
return {
  -- vim.cmd([[packadd paq-nvim]])
  -- package.loaded["paq-nvim"] = nil -- Refresh package list

  -- require("paq"):setup({verbose = false}) {
  -- (local/development packages) --
  --    -- located in: ~/.local/share/nvim/site/pack/local
  -- "megalithic/zk.nvim"
  -- "megalithic/lexima.vim"
  -- "megalithic/nvim-fzf-commands"

  -- (paq-nvim) --
  {"savq/paq-nvim", opt = true},
  -- "tweekmonster/startuptime.vim",
  -- :StartupTime 100 -- -u ~/foo.vim -i NONE -- ~/foo.vim

  -- (ui, interface) --
  "sainnhe/everforest",
  "folke/tokyonight.nvim",
  "savq/melange",
  -- {"cocopon/inspecthi.vim", opt=true}
  "norcalli/nvim-colorizer.lua",
  {"dm1try/golden_size", branch = "layout_resizing"},
  "junegunn/rainbow_parentheses.vim",
  -- "ryanoasis/vim-devicons",
  {"kyazdani42/nvim-web-devicons", opt = true},
  "hoob3rt/lualine.nvim",
  "danilamihailov/beacon.nvim",
  -- "edluffy/specs.nvim",
  "antoinemadec/FixCursorHold.nvim",
  "psliwka/vim-smoothie",
  -- {"lukas-reineke/indent-blankline.nvim", branch = "lua"},

  -- (lsp, completion, diagnostics, snippets, treesitter) --
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
  -- {"nvim-treesitter/nvim-treesitter-refactor"},

  -- (file navigation) --
  -- {"junegunn/fzf", run = "./install --all"},
  -- "junegunn/fzf.vim",
  -- "vijaymarupudi/nvim-fzf",
  -- "ibhagwan/fzf-lua",
  "nvim-telescope/telescope.nvim",
  -- "nvim-telescope/telescope-z.nvim",
  -- "nvim-telescope/telescope-project.nvim",
  -- "nvim-telescope/telescope-symbols.nvim",
  -- {"nvim-telescope/telescope-fzy-native.nvim", run = "git submodule update --init --recursive"},
  "unblevable/quick-scope",
  -- "kevinhwang91/nvim-bqf",
  -- "windwp/nvim-spectre",
  -- https://github.com/elianiva/dotfiles/blob/master/nvim/.config/nvim/lua/modules/_mappings.lua
  -- "tjdevries/astronauta.nvim",

  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-operator-user",
  -- -- provide ai and ii for indent blocks
  -- -- provide al and il for current line
  -- -- provide a_ and i_ for underscores
  -- -- provide a- and i-
  -- "kana/vim-textobj-user", -- https://github.com/kana/vim-textobj-user/wiki
  -- "kana/vim-textobj-function", -- function text object (af/if)
  -- "kana/vim-textobj-indent", -- for indent level (ai/ii)
  -- "kana/vim-textobj-line", -- for current line (al/il)
  -- "andyl/vim-textobj-elixir", -- elixir block text object (ae/ie)
  -- "glts/vim-textobj-comment", -- comment text object (ac/ic)
  -- "michaeljsmith/vim-indent-object",
  -- "machakann/vim-textobj-delimited", -- - d/D   for underscore section (e.g. `did` on foo_b|ar_baz -> foo__baz)
  -- "gilligan/textobj-lastpaste", -- - P     for last paste
  -- "mattn/vim-textobj-url", -- - u     for url
  -- "rhysd/vim-textobj-anyblock", -- - '', \"\", (), {}, [], <>
  -- "arthurxavierx/vim-caser", -- https://github.com/arthurxavierx/vim-caser#usage
  -- "Julian/vim-textobj-variable-segment", -- variable parts (av/iv)
  -- "sgur/vim-textobj-parameter", -- function parameters (a,/i,)
  "wellle/targets.vim", -- improved targets line cin) next parens) https://github.com/wellle/targets.vim/blob/master/cheatsheet.md
  -- https://github.com/AckslD/nvim-revJ.lua

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

  -- (development, et al) --
  "tpope/vim-projectionist",
  "janko/vim-test",
  "tpope/vim-ragtag",
  "rizzatti/dash.vim",
  "skywind3000/vim-quickui",
  "sgur/vim-editorconfig",
  {"zenbro/mirror.vim", opt = true},

  -- (markdown/prose/notes) --
  -- "KosukeMizuno/vim-markdown",
  {"folke/zen-mode.nvim", opt = true},
  -- {"junegunn/goyo.vim", opt = true},
  -- {"junegunn/limelight.vim", opt = true},
  -- {"reedes/vim-pencil", opt = true},
  {"iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"]},
  "dkarter/bullets.vim",
  "kristijanhusak/orgmode.nvim",
  -- "SidOfc/mkdx",
  -- {"reedes/vim-wordy", opt = true},
  -- {"reedes/vim-lexical", opt = true},
  -- "sedm0784/vim-you-autocorrect",
  -- {
  --   "npxbr/glow.nvim",
  --   run = function()
  --     vim.api.nvim_command("GlowInstall")
  --   end
  -- },

  -- (the rest...) --
  "ojroques/vim-oscyank",
  "farmergreg/vim-lastplace",
  -- "blackCauldron7/surround.nvim",
  "andymass/vim-matchup",
  -- "windwp/nvim-autopairs", -- https://github.com/windwp/nvim-autopairs#using-nvim-compe
  "alvan/vim-closetag",
  -- "Raimondi/delimitMate",
  -- "tpope/vim-endwise",
  -- "rstacruz/vim-closer", -- broke: has conflicting tags `closer`
  "b3nj5m1n/kommentary", -- broke: issues with multiline in lua
  -- "trevordmiller/nova-vim",
  -- "terrortylor/nvim-comment"
  -- "tpope/vim-commentary"
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
  "christoomey/vim-tmux-navigator", -- https://github.com/knubie/vim-kitty-navigator analog
  -- "tmux-plugins/vim-tmux-focus-events",
  -- "trevordmiller/nova-vim",
  "christoomey/vim-tmux-runner",
  -- "wellle/visual-split.vim",
  "junegunn/vim-slash",
  "junegunn/vim-easy-align",
  -- "junegunn/vim-peekaboo",
  -- "gennaro-tedesco/nvim-peekup", -- peek into the vim registers in floating window
  -- https://github.com/awesome-streamers/awesome-streamerrc/blob/master/ThePrimeagen/plugin/firenvim.vim
  -- {
  --   "glacambre/firenvim",
  --   run = function()
  --     vim.fn["firenvim#install"](777)
  --   end
  -- },

  -- (langs, syntax, et al) --
  "tpope/vim-rails",
  "antew/vim-elm-analyse",
  "avdgaag/vim-phoenix",
  "lucidstack/hex.vim",
  "euclidianace/betterlua.vim",
  "andrejlevkovitch/vim-lua-format",
  -- "yyq123/vim-syntax-logfile",
  "darfink/vim-plist",
  "sheerun/vim-polyglot"
}
