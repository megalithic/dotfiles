-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs
-- # local/devel paqs stored here:
--  ~/.local/share/nvim/site/pack/local

-- NOTE: add local module:
-- vim.opt.runtimepath:append '~/path/to/your/plugin'
local PKGS = {
  { "savq/paq-nvim" },
  ------------------------------------------------------------------------------
  -- (profiling/speed improvements) --
  { "dstein64/vim-startuptime" },
  "lewis6991/impatient.nvim",
  -- "nathom/filetype.nvim",

  ------------------------------------------------------------------------------
  -- (appearance/UI/visuals) --
  "rktjmp/lush.nvim",
  "mhanberg/thicc_forest",
  "sainnhe/everforest",
  "mcchrish/zenbones.nvim",
  "savq/melange",
  "rebelot/kanagawa.nvim",
  "norcalli/nvim-colorizer.lua",
  -- { "rrethy/vim-hexokinase", run = "make hexokinase" },
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  "karb94/neoscroll.nvim",
  -- "lukas-reineke/indent-blankline.nvim",
  -- { "lukas-reineke/virt-column.nvim" },
  "MunifTanjim/nui.nvim",
  "stevearc/dressing.nvim",
  "folke/which-key.nvim",
  "rcarriga/nvim-notify",
  "echasnovski/mini.nvim",

  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
  "williamboman/nvim-lsp-installer", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L229-L244
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  -- "lukas-reineke/lsp-format.nvim",
  { "hrsh7th/nvim-cmp" },
  -- { "hrsh7th/nvim-cmp", branch = "dev" },
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-nvim-lua",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-cmdline",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-emoji",
  "f3fora/cmp-spell",
  "hrsh7th/cmp-nvim-lsp-document-symbol",
  "hrsh7th/cmp-nvim-lsp-signature-help",
  "petertriho/cmp-git",

  -- for fuzzy things in nvim-cmp and command:
  -- "tzachar/fuzzy.nvim",
  -- "tzachar/cmp-fuzzy-path",
  -- "tzachar/cmp-fuzzy-buffer",

  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  -- "ray-x/lsp_signature.nvim",
  "j-hui/fidget.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  "folke/trouble.nvim",
  { "kevinhwang91/nvim-bqf" },
  { url = "https://gitlab.com/yorickpeterse/nvim-pqf" },
  "abecodes/tabout.nvim",
  -- { url = "https://gitlab.com/yorickpeterse/nvim-dd.git" },
  "mhartington/formatter.nvim",
  "antoinemadec/FixCursorHold.nvim", -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
  "ojroques/nvim-bufdel",

  ------------------------------------------------------------------------------
  -- (treesitter) --
  {
    "nvim-treesitter/nvim-treesitter",
    run = function()
      vim.cmd("TSUpdate")
    end,
  },
  "nvim-treesitter/playground",
  "nvim-treesitter/nvim-treesitter-refactor",
  "mfussenegger/nvim-treehopper",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  -- "SmiteshP/nvim-gps",
  "RRethy/nvim-treesitter-textsubjects",
  "David-Kunz/treesitter-unit",
  "nvim-treesitter/nvim-tree-docs",
  -- "primeagen/harpoon",
  -- "romgrk/nvim-treesitter-context",

  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  { "ggandor/lightspeed.nvim", opt = true },
  { "phaazon/hop.nvim", opt = true },
  "akinsho/toggleterm.nvim",
  "elihunter173/dirbuf.nvim",
  -- "nvim-neo-tree/neo-tree.nvim",
  -- "kyazdani42/nvim-tree.lua",

  "tami5/sqlite.lua",
  "nvim-telescope/telescope.nvim",
  "nvim-telescope/telescope-frecency.nvim",
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "camgraff/telescope-tmux.nvim",
  "nvim-telescope/telescope-media-files.nvim",
  "nvim-telescope/telescope-symbols.nvim",
  "nvim-telescope/telescope-smart-history.nvim",
  -- "nvim-telescope/telescope-file-browser.nvim",

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
  -- {"keith/gist.vim", run = "chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "mattn/webapi-vim",
  "akinsho/git-conflict.nvim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "tpope/vim-fugitive",
  "lewis6991/gitsigns.nvim",
  -- "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  -- "gabebw/vim-github-link-opener",
  { "ruifm/gitlinker.nvim" },
  { "ruanyl/vim-gh-line" },

  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  -- "ahmedkhalf/project.nvim",
  "bennypowers/nvim-regexplainer",
  "tpope/vim-projectionist",
  -- "tjdevries/edit_alternate.vim",
  "vim-test/vim-test", -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "tpope/vim-ragtag",
  -- { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  -- "tpope/vim-dadbod",
  -- "kristijanhusak/vim-dadbod-completion",
  -- "kristijanhusak/vim-dadbod-ui",
  -- {
  --   "glacambre/firenvim",
  --   run = function()
  --     vim.fn["firenvim#install"](0)
  --   end,
  -- },
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
  "tpope/vim-apathy",
  "lambdalisue/suda.vim",
  "EinfachToll/DidYouMean",
  "wsdjeg/vim-fetch", -- vim path/to/file.ext:12:3
  "ConradIrwin/vim-bracketed-paste", -- FIXME: delete?
  "kevinhwang91/nvim-hclipboard",
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  "tpope/vim-scriptease",
  { "sunaku/tmux-navigate", opt = true },
  { "knubie/vim-kitty-navigator", run = "cp -L ./*.py ~/.dotfiles/config/kitty", opt = true },
  -- "tmux-plugins/vim-tmux-focus-events",
  "junegunn/vim-slash",
  "outstand/logger.nvim",
  "RRethy/nvim-align",

  ------------------------------------------------------------------------------
  -- (LANGS, syntax, et al) --
  -- "plasticboy/vim-markdown", -- replacing with the below:
  "ixru/nvim-markdown",
  -- "rhysd/vim-gfm-syntax",
  { "iamcco/markdown-preview.nvim", run = "cd app && yarn install", opt = true },
  "ellisonleao/glow.nvim",
  "dkarter/bullets.vim",
  -- "dhruvasagar/vim-table-mode",
  "lukas-reineke/headlines.nvim",
  -- https://github.com/preservim/vim-wordy
  -- https://github.com/jghauser/follow-md-links.nvim
  -- https://github.com/jakewvincent/mkdnflow.nvim
  -- https://github.com/jubnzv/mdeval.nvim
  { "mickael-menu/zk-nvim" },
  "tpope/vim-rails",
  "elixir-editors/vim-elixir",
  "ngscheurich/edeex.nvim",
  "antew/vim-elm-analyse",
  "tjdevries/nlua.nvim",
  "norcalli/nvim.lua",
  "euclidianace/betterlua.vim",
  "folke/lua-dev.nvim",
  "andrejlevkovitch/vim-lua-format",
  "milisims/nvim-luaref",
  "MaxMEllon/vim-jsx-pretty",
  "heavenshell/vim-jsdoc",
  "jxnblk/vim-mdx-js",
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  -- "mattn/emmet-vim",
  "skwp/vim-html-escape",
  "pedrohdz/vim-yaml-folds",
  "avakhov/vim-yaml",
  "chr4/nginx.vim",
  "nanotee/luv-vimdocs",
  "fladson/vim-kitty",
  "SirJson/fzf-gitignore",

  -- TODO: work tings; also get packer.nvim going
  -- "outstand/titan.nvim",
  -- "outstand/logger.nvim",
  -- "ryansch/habitats.nvim",
}

local M = {}

M.sync_all = function()
  -- package.loaded.paq = nil
  -- vim.cmd("autocmd User PaqDoneSync quit")
  (require("paq"))(PKGS):sync()
end

local function clone_paq()
  local path = vim.fn.stdpath("data") .. "/site/pack/paqs/start/paq-nvim"
  if vim.fn.empty(vim.fn.glob(path)) > 0 then
    vim.fn.system({
      "git",
      "clone",
      "--depth=1",
      "https://github.com/savq/paq-nvim.git",
      path,
    })
  end
end

-- `bin/paq-install` runs this for us in a headless nvim environment
M.bootstrap = function()
  clone_paq()

  -- Load Paq
  vim.cmd("packadd paq-nvim")
  local paq = require("paq")

  -- Exit nvim after installing plugins
  vim.cmd("autocmd User PaqDoneInstall quit")

  -- Read and install packages
  paq(PKGS):install()
end

return M
