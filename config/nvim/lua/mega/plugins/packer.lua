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
    use({ "nvim-lua/popup.nvim" })
    use({ "dstein64/vim-startuptime" })

    -- UI
    use({ "rktjmp/lush.nvim" })
    use({ "NvChad/nvim-colorizer.lua", event = "BufRead" })
    use({ "dm1try/golden_size", ext = "golden_size" })
    use({ "kyazdani42/nvim-web-devicons", after = "lush.nvim" })
    use({ "lukas-reineke/virt-column.nvim" })
    use({ "MunifTanjim/nui.nvim" })
    use({ "folke/which-key.nvim" })
    use({ "echasnovski/mini.nvim", ext = "mini", after = "treesitter-nvim" })
    use({ "phaazon/hop.nvim" })
    use({ "jghauser/fold-cycle.nvim" })
    use({ "anuvyklack/hydra.nvim", ext = "hydra" })
    use({ "rcarriga/nvim-notify" })
    use({ "nanozuki/tabby.nvim", ext = "tabby" })
    use({ "levouh/tint.nvim", event = "BufRead" })

    -- use_local({ "tiagovla/tokyodark.nvim", ext = "tokyodark" })
    -- use({ "nvim-lualine/lualine.nvim", after = "nvim-web-devicons", ext = "lualine" })
    -- use({ "kyazdani42/nvim-web-devicons", after = "tokyodark.nvim" })
    -- use({ "akinsho/nvim-bufferline.lua", after = "nvim-web-devicons", ext = "bufferline" })

    -- Telescope
    use({
      "nvim-telescope/telescope.nvim",
      module_pattern = "telescope.*",
      ext = "telescope",
      event = "CursorHold",
      requires = {
        {
          "nvim-telescope/telescope-file-browser.nvim",
          after = "telescope.nvim",
          config = function() require("telescope").load_extension("file_browser") end,
        },
        {
          "natecraddock/telescope-zf-native.nvim",
          after = "telescope.nvim",
          config = function() require("telescope").load_extension("zf-native") end,
        },
        {
          "benfowler/telescope-luasnip.nvim",
          after = "telescope.nvim",
          config = function() require("telescope").load_extension("luasnip") end,
        },
      },
    })

    -- Navigation
    use({
      "knubie/vim-kitty-navigator",
      run = "cp ./*.py ~/.config/kitty/",
      cond = function() return not vim.env.TMUX end,
    })
    use({
      "nvim-neo-tree/neo-tree.nvim",
      ext = "neo-tree",
      keys = { "<C-N>" },
      cmd = { "NeoTree" },
      requires = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "kyazdani42/nvim-web-devicons",
        { "mrbjarksen/neo-tree-diagnostics.nvim", module = "neo-tree.sources.diagnostics" },
        { "s1n7ax/nvim-window-picker" },
      },
    })

    -- Syntax
    use({
      "nvim-treesitter/nvim-treesitter",

      run = ":TSUpdate",
      event = { "BufRead", "BufNewFile" },
      ext = "treesitter",
      requires = {
        { "nvim-treesitter/nvim-treesitter-subjects", after = "nvim-treesitter" },
        { "nvim-treesitter/nvim-tree-docs", after = "nvim-treesitter" },
        { "JoosepAlviste/nvim-ts-context-commentstring", after = "nvim-treesitter" },
        { "windwp/nvim-ts-autotag", after = "nvim-treesitter" },
        { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
        { "mfussenegger/nvim-treehopper", after = "nvim-treesitter" },
        { "David-Kunz/treesitter-unit", after = "nvim-treesitter" },
        {
          "nvim-treesitter/nvim-treesitter-context",
          after = "nvim-treesitter",
          config = function()
            require("treesitter-context").setup({
              multiline_threshold = 4,
              separator = { "─", "ContextBorder" }, -- alternatives: ▁ ─ ▄
              mode = "topline",
            })
          end,
        },
        {
          "nvim-treesitter/playground",
          after = "nvim-treesitter",
          cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
        },
      },
    })

    -- "nvim-treesitter/nvim-tree-docs",
    -- "JoosepAlviste/nvim-ts-context-commentstring",
    -- "windwp/nvim-ts-autotag",
    -- "p00f/nvim-ts-rainbow",
    -- "mfussenegger/nvim-treehopper",
    -- "RRethy/nvim-treesitter-textsubjects",
    -- "David-Kunz/treesitter-unit",
    -- { "nvim-treesitter/nvim-treesitter-context" },

    -- Lsp
    use({ "neovim/nvim-lspconfig" })
    use({ "williamboman/mason.nvim" })
    use({ "williamboman/mason-lspconfig.nvim" })
    use({ "jose-elias-alvarez/null-ls.nvim" })
    use({ "ray-x/lsp_signature.nvim", after = "nvim-lspconfig" })
    -- use({ "j-hui/fidget.nvim", ext = "fidget" })
    -- use({ "microsoft/python-type-stubs", opt = true })
    -- use({ "lvimuser/lsp-inlayhints.nvim" })

    -- Git
    use({ "lewis6991/gitsigns.nvim", ext = "gitsigns" })
    use({ "TimUntersberger/neogit", cmd = { "Neogit" }, ext = "neogit" })

    -- -- Auto-complete
    use({ "rafamadriz/friendly-snippets", event = "InsertEnter" })
    use({ "L3MON4D3/LuaSnip", after = "friendly-snippets", module = "luasnip", ext = "luasnip" })
    use({
      "hrsh7th/nvim-cmp",
      after = "LuaSnip",
      ext = "cmp",
      module = "cmp",
      event = "InsertEnter",
      requires = {
        { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
        { "hrsh7th/cmp-buffer", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
        { "hrsh7th/cmp-path", after = "nvim-cmp" },
        { "hrsh7th/cmp-emoji", after = "nvim-cmp" },
        { "f3fora/cmp-spell", after = "nvim-cmp" },
        { "hrsh7th/cmp-cmdline", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
      },
    })
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
    -- use({ "rcarriga/neotest", ext = "neotest" })

    install_sync()
  end,
  config = {},
})
