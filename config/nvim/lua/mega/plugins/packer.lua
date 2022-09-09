-- REF: https://github.com/rstacruz/vimfiles

-- local fn = vim.fn
-- local fmt = string.format
-- local utils = require("mega.plugins.utils")
-- local conf = utils.conf
-- local packer_notify = utils.packer_notify
-- local M = {}

if pcall(require, "packer") then vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/paqs") end

local packer, use, use_local, install_sync = unpack(require("plugins.packer"))

packer.startup({
  function()
    use({ "wbthomason/packer.nvim", opt = true })
    use({ "lewis6991/impatient.nvim" })
    use({ "nvim-lua/plenary.nvim" })
    use({ "dstein64/vim-startuptime" })

    -- UI
    use({ "rktjmp/lush.nvim" })
    use({ "NvChad/nvim-colorizer.lua", event = "BufRead" })
    use({ "dm1try/golden_size" })
    use({ "kyazdani42/nvim-web-devicons", after = "lush.nvim" })
    use({ "lukas-reineke/virt-column.nvim" })
    use({ "MunifTanjim/nui.nvim" })
    use({ "folke/which-key.nvim" })
    use({ "echasnovski/mini.nvim" })
    use({ "phaazon/hop.nvim" })
    use({ "jghauser/fold-cycle.nvim" })
    use({ "anuvyklack/hydra.nvim" })
    use({ "rcarriga/nvim-notify" })
    use({ "nanozuki/tabby.nvim" })
    use({ "levouh/tint.nvim", event = "BufRead" })

    -- use_local({ "tiagovla/tokyodark.nvim", ext = "tokyodark" })
    -- use({ "nvim-lualine/lualine.nvim", after = "nvim-web-devicons", ext = "lualine" })
    -- use({ "kyazdani42/nvim-web-devicons", after = "tokyodark.nvim" })
    -- use({ "akinsho/nvim-bufferline.lua", after = "nvim-web-devicons", ext = "bufferline" })

    -- Telescope
    use({ "nvim-telescope/telescope.nvim", module = "telescope", ext = "telescope" })
    use({ "nvim-telescope/telescope-project.nvim", after = "telescope.nvim", ext = "project" })
    use({ "nvim-telescope/telescope-media-files.nvim", after = "telescope.nvim" })
    use({ "nvim-telescope/telescope-file-browser.nvim", after = "telescope.nvim" })
    -- use({ "jvgrootveld/telescope-zoxide", after = "telescope.nvim", ext = "telescope-zoxide" })

    -- Syntax
    use({ "nvim-treesitter/nvim-treesitter", event = { "BufRead", "BufNewFile" }, ext = "treesitter" })
    use({ "nvim-treesitter/nvim-treesitter-textobjects", after = "nvim-treesitter" })
    use({ "nvim-treesitter/playground", after = "nvim-treesitter" })
    -- use({ "JoseConseco/iswap.nvim", after = "nvim-treesitter", ext = "iswap" })

    -- Lsp
    use({ "neovim/nvim-lspconfig" })
    use({ "williamboman/mason.nvim" })
    use({ "williamboman/mason-lspconfig.nvim" })
    use({ "jose-elias-alvarez/null-ls.nvim" })
    -- use({ "j-hui/fidget.nvim", ext = "fidget" })
    -- use({ "microsoft/python-type-stubs", opt = true })
    -- use({ "lvimuser/lsp-inlayhints.nvim" })

    -- Git
    use({ "lewis6991/gitsigns.nvim", ext = "gitsigns" })
    use({ "TimUntersberger/neogit", cmd = { "Neogit" }, ext = "neogit" })

    -- -- Auto-complete
    use({ "rafamadriz/friendly-snippets", event = "InsertEnter" })
    use({ "L3MON4D3/LuaSnip", after = "friendly-snippets", module = "luasnip", ext = "luasnip" })
    use({ "hrsh7th/nvim-cmp", after = "LuaSnip", ext = "cmp" })
    use({ "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" })
    use({ "hrsh7th/cmp-buffer", after = "nvim-cmp" })
    use({ "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp" })
    use({ "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" })
    use({ "hrsh7th/cmp-path", after = "nvim-cmp" })
    use({ "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" })
    use({ "onsails/lspkind-nvim", after = "nvim-cmp", ext = "lspkind" })
    -- use_local({ "tiagovla/zotex.nvim", after = "nvim-cmp", ext = "zotex" }) -- experimental

    -- UI Helpers
    -- use({ "mbbill/undotree", cmd = "UndotreeToggle" })
    -- use({ "kyazdani42/nvim-tree.lua", ext = "nvim-tree" })
    -- use({ "aserowy/tmux.nvim", ext = "tmux" })

    -- use({ "luukvbaal/stabilize.nvim", event = "BufRead", ext = "stabilize" })
    -- use({ "akinsho/toggleterm.nvim", cmd = "ToggleTerm", ext = "toggleterm" })
    use({ "sindrets/diffview.nvim", ext = "diffview" })
    -- use({ "folke/trouble.nvim", cmd = { "Trouble" }, module = "trouble", ext = "trouble" })
    use({ "rcarriga/nvim-notify", after = "telescope.nvim", ext = "nvim-notify" })
    use({ "folke/which-key.nvim", ext = "whichkey" })
    -- use_local({ "tiagovla/scope.nvim", ext = "scope", event = "BufRead" })
    -- use_local({ "tiagovla/buffercd.nvim", ext = "buffercd", event = "BufRead" })
    -- use({ "simrat39/symbols-outline.nvim", cmd = "SymbolsOutline" })
    -- use({ "famiu/bufdelete.nvim" })

    -- -- Commenter & Colorizer
    use({ "numToStr/Comment.nvim", event = "BufRead", ext = "comment" })

    -- -- Documents
    -- use({ "tiagovla/tex-conceal.vim", ft = "tex" })
    use({ "iamcco/markdown-preview.nvim", ext = "markdownpreview" })
    use({ "danymat/neogen", ext = "neogen" })

    -- -- Debug & Dev
    use({ "mfussenegger/nvim-dap", module = "dap", ext = "dap" })
    use({ "theHamsta/nvim-dap-virtual-text", ext = "nvim-dap-virtual-text" })
    use({ "rcarriga/nvim-dap-ui", ext = "dapui" })
    use({ "Pocco81/DAPInstall.nvim" })
    use({ "folke/lua-dev.nvim", module = "lua-dev" })
    use({ "kylechui/nvim-surround", ext = "nvim-surround" })
    use({ "rcarriga/neotest", ext = "neotest" })

    install_sync()
  end,
  config = {},
})
