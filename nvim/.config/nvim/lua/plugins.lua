-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs
-- # local/deve paqs stored here:
--  ~/.local/share/nvim/site/pack/local
return {
	{ "savq/paq-nvim" },
	--
	-- (profiling) --
	"dstein64/vim-startuptime",
	"lewis6991/impatient.nvim",
	--
	-- (appearance/ui) --
	"sainnhe/everforest",
	"rktjmp/lush.nvim",
	-- "goolord/alpha-nvim", -- "folke/persistence.nvim"
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
	"williamboman/nvim-lsp-installer",
	"nvim-lua/plenary.nvim",
	"nvim-lua/popup.nvim",
	"hrsh7th/nvim-cmp",
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-nvim-lua",
	"saadparwaiz1/cmp_luasnip",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-emoji",
	"megalithic/cmp-gitmoji",
	"f3fora/cmp-spell",
	"L3MON4D3/LuaSnip",
	"rafamadriz/friendly-snippets",
	"nvim-lua/lsp-status.nvim",
	"nvim-lua/lsp_extensions.nvim",
	"ray-x/lsp_signature.nvim",
	"jose-elias-alvarez/nvim-lsp-ts-utils",
	"megalithic/null-ls.nvim", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L203-L226
	"folke/trouble.nvim",
	"SmiteshP/nvim-gps",
	-- https://github.com/kosayoda/nvim-lightbulb
	--
	-- (treesitter) --
	{
		"nvim-treesitter/nvim-treesitter",
		run = function()
			vim.cmd("TSUpdate")
		end,
		pin = true,
	},
	"nvim-treesitter/nvim-treesitter-textobjects",
	"nvim-treesitter/playground",
	"RRethy/nvim-treesitter-textsubjects",
	"mfussenegger/nvim-ts-hint-textobject",
	"ikatyang/tree-sitter-markdown",
	"JoosepAlviste/nvim-ts-context-commentstring",
	"windwp/nvim-ts-autotag",
	"p00f/nvim-ts-rainbow",
	-- "lewis6991/spellsitter.nvim", -- https://github.com/ful1e5/dotfiles/blob/main/nvim/.config/nvim/lua/plugins-cfg/spellsitter/init.lua
	--
	-- (file/document navigation) --
	{ "junegunn/fzf", run = "./install --bin" },
	"ibhagwan/fzf-lua",
	"vijaymarupudi/nvim-fzf",
	"ggandor/lightspeed.nvim",
	"voldikss/vim-floaterm",
	--
	-- (text objects) --
	"tpope/vim-rsi",
	"kana/vim-textobj-user",
	"kana/vim-operator-user",
	"mattn/vim-textobj-url", -- au/iu for url
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
	"tpope/vim-fugitive",
	-- {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"},
	"mattn/webapi-vim",
	"rhysd/conflict-marker.vim",
	-- "itchyny/vim-gitbranch",
	"rhysd/git-messenger.vim",
	"sindrets/diffview.nvim",
	-- "dinhhuy258/git.nvim",
	-- "lewis6991/gitsigns.nvim",
	-- "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
	--
	-- (development, et al) --
	"ahmedkhalf/project.nvim",
	"tpope/vim-projectionist",
	"janko/vim-test", -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
	"tpope/vim-ragtag",
	"rizzatti/dash.vim",
	"editorconfig/editorconfig-vim",
	{ "zenbro/mirror.vim", opt = true },
	"vuki656/package-info.nvim",
	--
	-- (the rest...) --
	"nacro90/numb.nvim",
	"ethanholz/nvim-lastplace",
	"andymass/vim-matchup", -- https://github.com/andymass/vim-matchup#tree-sitter-integration
	"windwp/nvim-autopairs",
	"alvan/vim-closetag",
	"terrortylor/nvim-comment",
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
	-- "tmux-plugins/vim-tmux-focus-events",
	"christoomey/vim-tmux-runner",
	"junegunn/vim-slash",
	"junegunn/vim-easy-align",
	-- use_with_config("svermeulen/vim-cutlass", "cutlass") -- separates cut and delete operations
	--     use_with_config("svermeulen/vim-yoink", "yoink") -- improves paste
	--
	-- (langs, syntax, et al) --
	-- # markdown/prose
	"plasticboy/vim-markdown",
	-- "rhysd/vim-gfm-syntax",
	{ "iamcco/markdown-preview.nvim", run = vim.fn["mkdp#util#install"] },
	{ "harshad1/bullets.vim", branch = "performance_improvements" },
	"kristijanhusak/orgmode.nvim",
	"akinsho/org-bullets.nvim",
	"dhruvasagar/vim-table-mode",
	-- https://github.com/jghauser/follow-md-links.nvim
	-- https://github.com/jakewvincent/mkdnflow.nvim
	-- https://github.com/jubnzv/mdeval.nvim
	-- "megalithic/zk.nvim",
	-- "NFrid/due.nvim",
	-- # ruby/rails
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
	"milisims/nvim-luaref",
	-- # JS/TS/JSON
	"MaxMEllon/vim-jsx-pretty",
	"heavenshell/vim-jsdoc",
	"jxnblk/vim-mdx-js",
	"kchmck/vim-coffee-script",
	-- # HTML
	-- "mattn/emmet-vim",
	"skwp/vim-html-escape",
	"pedrohdz/vim-yaml-folds",
	-- # misc
	"avakhov/vim-yaml",
	"chr4/nginx.vim",
	"nanotee/luv-vimdocs",
}
