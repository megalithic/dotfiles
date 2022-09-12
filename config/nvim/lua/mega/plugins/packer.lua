local fmt = string.format

if vim.g.use_packer then
  -- vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/*/start/*")
  vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/paqs")
end

local _use, use_local, bootstrap_packer, packer_notify, conf = unpack(require("mega.plugins.utils"))
local mega = require("mega.globals")

local PACKER_COMPILED_PATH = fmt("%s/packer/packer_compiled.lua", vim.fn.stdpath("cache"))
local PACKER_SNAPSHOTS_PATH = fmt("%s/packer/snapshots/", vim.fn.stdpath("cache"))

local bootstrapped = bootstrap_packer("start")

vim.cmd.packadd({ "cfilter", bang = true })

require("packer").startup({
  function(use)
    use({ "wbthomason/packer.nvim" })
    use({ "lewis6991/impatient.nvim" })
    use({ "nvim-lua/plenary.nvim" })
    use({ "nvim-lua/popup.nvim" })
    use({ "dstein64/vim-startuptime", cmd = { "StartupTime" } })
    use({ "mattn/webapi-vim" })
    use({ "antoinemadec/FixCursorHold.nvim" }) -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open

    -- ( UI ) ------------------------------------------------------------------
    use({ "rktjmp/lush.nvim" })
    use({ "NvChad/nvim-colorizer.lua", event = "BufRead" })
    use({ "dm1try/golden_size", config = conf("golden_size") })
    use({ "kyazdani42/nvim-web-devicons", after = "lush.nvim" })
    use({ "lukas-reineke/virt-column.nvim" })
    use({ "MunifTanjim/nui.nvim" })
    use({ "folke/which-key.nvim" })
    use({ "echasnovski/mini.nvim", config = conf("mini"), after = "nvim-treesitter" })
    use({ "phaazon/hop.nvim" })
    use({ "jghauser/fold-cycle.nvim" })
    use({ "anuvyklack/hydra.nvim", config = conf("hydra") })
    use({ "rcarriga/nvim-notify", config = conf("notify") })
    use({ "nanozuki/tabby.nvim", config = conf("tabby") })
    -- use({
    --   "levouh/tint.nvim",
    --   event = "BufRead",
    --   config = function()
    --     require("tint").setup({
    --       tint = -50,
    --       highlight_ignore_patterns = {
    --         "WinSeparator",
    --         "St.*",
    --         "Comment",
    --         "Panel.*",
    --         "Telescope.*",
    --         "Bqf.*",
    --         "Cursor.*",
    --       },
    --       window_ignore_function = function(win_id)
    --         if vim.wo[win_id].diff or vim.fn.win_gettype(win_id) ~= "" then return true end
    --         local buf = vim.api.nvim_win_get_buf(win_id)
    --         local b = vim.bo[buf]
    --         local ignore_bt = { "megaterm", "terminal", "prompt", "nofile" }
    --         local ignore_ft =
    --           { "neo-tree", "packer", "diff", "megaterm", "toggleterm", "Neogit.*", "Telescope.*", "qf" }
    --         return mega.any(b.bt, ignore_bt) or mega.any(b.ft, ignore_ft)
    --       end,
    --     })
    --   end,
    -- })

    -- ( Telescope ) -----------------------------------------------------------
    use({
      "nvim-telescope/telescope.nvim",
      module_pattern = "telescope.*",
      config = conf("telescope"),
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

    -- ( Navigation ) ----------------------------------------------------------
    use({
      "knubie/vim-kitty-navigator",
      run = "cp ./*.py ~/.config/kitty/",
      cond = function() return not vim.env.TMUX end,
    })
    use({
      "nvim-neo-tree/neo-tree.nvim",
      config = conf("neo-tree"),
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
    use({ "kevinhwang91/nvim-bqf" })
    use({ "https://gitlab.com/yorickpeterse/nvim-pqf" })

    -- ( Treesitter ) ----------------------------------------------------------
    use({
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      event = { "BufRead", "BufNewFile" },
      requires = {
        { "RRethy/nvim-treesitter-textsubjects", after = "nvim-treesitter" },
        { "nvim-treesitter/nvim-tree-docs", after = "nvim-treesitter" },
        { "JoosepAlviste/nvim-ts-context-commentstring", after = "nvim-treesitter" },
        { "windwp/nvim-ts-autotag", after = "nvim-treesitter" },
        { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
        { "mfussenegger/nvim-treehopper", after = "nvim-treesitter" },
        { "David-Kunz/treesitter-unit", after = "nvim-treesitter" },
        {
          "nvim-treesitter/nvim-treesitter-context",
          after = "nvim-treesitter",
          -- config = function()
          --   require("treesitter-context").setup({
          --     multiline_threshold = 4,
          --     separator = { "─", "ContextBorder" }, -- alternatives: ▁ ─ ▄
          --     mode = "topline",
          --   })
          -- end,
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

    -- ( LSP ) -----------------------------------------------------------------
    use({ "neovim/nvim-lspconfig" })
    use({ "williamboman/mason.nvim" })
    use({ "williamboman/mason-lspconfig.nvim" })
    use({ "jose-elias-alvarez/null-ls.nvim" })
    use({ "ray-x/lsp_signature.nvim", after = "nvim-lspconfig" })
    use({ "lewis6991/hover.nvim" })
    use({ "nvim-lua/lsp_extensions.nvim" })
    use({ "jose-elias-alvarez/nvim-lsp-ts-utils" })
    use({ "b0o/schemastore.nvim" })
    -- use({ "j-hui/fidget.nvim", ext = "fidget" })
    -- use({ "microsoft/python-type-stubs", opt = true })
    -- use({ "lvimuser/lsp-inlayhints.nvim" })

    -- ( Git ) -----------------------------------------------------------------
    use({ "lewis6991/gitsigns.nvim", event = "BufRead", config = conf("gitsigns") })
    use({
      "TimUntersberger/neogit",
      cmd = "Neogit",
      config = function()
        local neogit = require("neogit")
        neogit.setup({
          disable_signs = false,
          disable_hint = true,
          disable_commit_confirmation = true,
          disable_builtin_notifications = true,
          disable_insert_on_commit = false,
          signs = {
            section = { "", "" }, -- "", ""
            item = { "▸", "▾" },
            hunk = { "樂", "" },
          },
          integrations = {
            diffview = true,
          },
        })
        mega.nnoremap("<localleader>gs", function() neogit.open() end)
        mega.nnoremap("<localleader>gc", function() neogit.open({ "commit" }) end)
        mega.nnoremap("<localleader>gl", neogit.popups.pull.create)
        mega.nnoremap("<localleader>gp", neogit.popups.push.create)

        require("which-key").register({
          ["<localleader>g"] = {
            s = "neogit: open status buffer",
            c = "neogit: open commit buffer",
            l = "neogit: open pull popup",
            p = "neogit: open push popup",
          },
        })
      end,
      requires = "plenary.nvim",
    })
    -- use({ "sindrets/diffview.nvim", config = conf("diffview") })
    use({ "akinsho/git-conflict.nvim" })
    use({ "itchyny/vim-gitbranch" })
    use({ "rhysd/git-messenger.vim" })
    use({ "tpope/vim-fugitive" })
    use({ "ruifm/gitlinker.nvim" })
    use({ "ruanyl/vim-gh-line" })

    -- ( Completion ) ----------------------------------------------------------
    use({ "rafamadriz/friendly-snippets", event = "InsertEnter" })
    use({ "L3MON4D3/LuaSnip", after = "friendly-snippets", module = "luasnip" })
    use({
      "hrsh7th/nvim-cmp",
      after = "LuaSnip",
      config = conf("cmp"),
      module = "cmp",
      event = "InsertEnter",
      requires = {
        { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
        { "hrsh7th/cmp-buffer", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp", after = "nvim-cmp" },
        -- { "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
        { "hrsh7th/cmp-path", after = "nvim-cmp" },
        { "hrsh7th/cmp-emoji", after = "nvim-cmp" },
        { "f3fora/cmp-spell", after = "nvim-cmp" },
        { "hrsh7th/cmp-cmdline", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
      },
    })
    -- use_local({ "tiagovla/zotex.nvim", after = "nvim-cmp", ext = "zotex" }) -- experimental

    -- ( Debugging ) -----------------------------------------------------------
    use({ "mfussenegger/nvim-dap", module = "dap", config = conf("dap") })
    use({ "theHamsta/nvim-dap-virtual-text", after = "nvim-dap" })
    use({ "rcarriga/nvim-dap-ui", config = conf("dapui"), after = "nvim-dap" })
    use({ "jbyuki/one-small-step-for-vimkind", after = "nvim-dap" })
    use({ "suketa/nvim-dap-ruby", after = "nvim-dap" })
    use({ "mxsdev/nvim-dap-vscode-js", after = "nvim-dap" })
    use({ "sultanahamer/nvim-dap-reactnative", after = "nvim-dap" })
    -- use({ "microsoft/vscode-react-native", after = "nvim-dap" })
    use({ "Pocco81/DAPInstall.nvim", after = "nvim-dap" })

    -- ( Development ) ---------------------------------------------------------
    use({ "danymat/neogen" })
    use({ "folke/lua-dev.nvim", module = "lua-dev" })
    use({
      "numToStr/Comment.nvim",
      event = "BufRead",
      config = function()
        require("comment").setup({

          ignore = "^$", -- ignores empty lines
          --@param ctx CommentCtx
          pre_hook = function(ctx)
            -- Only calculate commentstring for tsx filetypes
            if vim.bo.filetype == "typescriptreact" then
              local U = require("Comment.utils")

              -- Determine whether to use linewise or blockwise commentstring
              local type = ctx.ctype == U.ctype.line and "__default" or "__multiline"

              -- Determine the location where to calculate commentstring from
              local location = nil
              if ctx.ctype == U.ctype.block then
                location = require("ts_context_commentstring.utils").get_cursor_location()
              elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
                location = require("ts_context_commentstring.utils").get_visual_start_location()
              end

              return require("ts_context_commentstring.internal").calculate_commentstring({
                key = type,
                location = location,
              })
            end
          end,
        })
      end,
    })
    use({ "vim-test/vim-test", config = conf("vim-test") })
    use({ "tpope/vim-projectionist", config = conf("projectionist") })
    use({ "editorconfig/editorconfig-vim" })
    use({ "mhartington/formatter.nvim" })
    use({ "mrshmllow/document-color.nvim" })
    use({ "natecraddock/sessions.nvim" })
    use({ "natecraddock/workspaces.nvim" })
    use({ "megalithic/habitats.nvim" })
    use({ "nacro90/numb.nvim" })
    use({ "andymass/vim-matchup" })
    use({ "windwp/nvim-autopairs" })
    use({ "alvan/vim-closetag" })
    use({ "tpope/vim-eunuch" })
    use({ "tpope/vim-abolish" })
    use({ "tpope/vim-rhubarb" })
    use({ "tpope/vim-repeat" })
    use({ "tpope/vim-unimpaired" })
    use({ "tpope/vim-apathy" })
    use({ "lambdalisue/suda.vim" })
    use({ "EinfachToll/DidYouMean" })
    use({ "wsdjeg/vim-fetch" }) -- vim path/to/file.ext:12:3
    use({ "ConradIrwin/vim-bracketed-paste" }) -- FIXME: delete?
    use({ "tpope/vim-scriptease" })
    -- @trial: "jghauser/kitty-runner.nvim"

    -- ( Motions/Textobjects ) -------------------------------------------------
    use({
      "kylechui/nvim-surround",
      config = function()
        require("nvim-surround").setup({

          highlight = { -- Highlight before inserting/changing surrounds
            duration = 1,
          },
        })
      end,
    })
    use({ "abecodes/tabout.nvim" })

    -- ( Syntax/Languages ) ----------------------------------------------------
    use({ "ixru/nvim-markdown" })
    use({ "iamcco/markdown-preview.nvim", ft = "md", run = "cd app && yarn install" })
    use({ "mickael-menu/zk-nvim" })
    -- @trial phaazon/mind.nvim
    -- "renerocksai/telekasten.nvim"
    -- "rhysd/vim-gfm-syntax"
    use({ "gaoDean/autolist.nvim" })
    use({ "ellisonleao/glow.nvim" })
    -- "dkarter/bullets.vim"
    -- "dhruvasagar/vim-table-mode"
    use({ "lukas-reineke/headlines.nvim" })
    -- @trial ekickx/clipboard-image.nvim
    -- @trial preservim/vim-wordy
    -- @trial jghauser/follow-md-links.nvim
    -- @trial jakewvincent/mkdnflow.nvim
    -- @trial jubnzv/mdeval.nvim
    use({ "elixir-editors/vim-elixir" })
    use({ "tpope/vim-rails" })
    use({ "ngscheurich/edeex.nvim" })
    use({ "antew/vim-elm-analyse" })
    use({ "tjdevries/nlua.nvim" })
    use({ "norcalli/nvim.lua" })
    -- use({ "euclidianace/betterlua.vim" })
    -- use({ "folke/lua-dev.nvim" })
    use({ "milisims/nvim-luaref" })
    use({ "ii14/emmylua-nvim" })
    use({ "MaxMEllon/vim-jsx-pretty" })
    use({ "heavenshell/vim-jsdoc" })
    use({ "jxnblk/vim-mdx-js" })
    use({ "kchmck/vim-coffee-script" })
    use({ "briancollins/vim-jst" })
    use({ "skwp/vim-html-escape" })
    use({ "pedrohdz/vim-yaml-folds" })
    use({ "avakhov/vim-yaml" })
    use({ "chr4/nginx.vim" })
    use({ "nanotee/luv-vimdocs" })
    use({ "fladson/vim-kitty" })
    use({ "SirJson/fzf-gitignore" })
    use({ "axelvc/template-string.nvim" })

    if bootstrapped then require("packer").sync() end
  end,
  --   log = { level = "info" },
  config = {
    display = {
      open_cmd = "silent topleft 65vnew",
      -- open_fn = function() return require("packer.util").float({ border = "single" }) end,
      prompt_border = mega.get_border(),
    },
    non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
    compile_path = PACKER_COMPILED_PATH,
    snapshot_path = PACKER_SNAPSHOTS_PATH,
    preview_updates = true,
    git = {
      clone_timeout = 600,
    },
    auto_clean = true,
    compile_on_sync = true,
    max_jobs = vim.fn.has("win32") == 1 and 5 or nil,
    profile = {
      enable = true,
      threshold = 1,
    },
  },
})

mega.command("PackerCompiledEdit", function() vim.cmd.edit(PACKER_COMPILED_PATH) end)

mega.command("PackerCompiledDelete", function()
  vim.fn.delete(PACKER_COMPILED_PATH)
  packer_notify(string.format("Deleted %s", PACKER_COMPILED_PATH))
end)

if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(PACKER_COMPILED_PATH) then
  vim.cmd.source(PACKER_COMPILED_PATH)
  vim.g.packer_compiled_loaded = true
end

mega.nnoremap("<leader>ps", "<Cmd>PackerSync<CR>", "packer: sync")

local function reload()
  mega.invalidate("mega.plugins", true)
  require("packer").compile()
end

mega.augroup("PackerSetupInit", {
  {
    event = { "BufWritePost" },
    pattern = { "*/mega/plugins/*.lua" },
    desc = "Packer setup and reload",
    command = reload,
  },
  {
    event = { "User" },
    pattern = { "VimrcReloaded" },
    desc = "Packer setup and reload",
    command = reload,
  },
  {
    event = { "User" },
    pattern = { "PackerCompileDone" },
    command = function() packer_notify("Compilation finished", "info") end,
  },
})
