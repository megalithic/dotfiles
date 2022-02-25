local fn = vim.fn
local fmt = string.format

---A thin wrapper around vim.notify to add packer details to the message
---@param msg string
local function packer_notify(msg, level)
  vim.notify(msg, level, { title = "Packer" })
end

---Require a plugin config
---@param name string
---@return any
local function conf(name)
  return require(fmt("mega.plugins.%s", name))
end

---Install an executable, returning the error if any
---@param binary string
---@param installer string
---@param cmd string
---@return string?
local function install(binary, installer, cmd, opts)
  opts = opts or { silent = true }
  cmd = cmd or "install"
  if not mega.executable(binary) and mega.executable(installer) then
    local install_cmd = fmt("%s %s %s", installer, cmd, binary)
    if opts.silent then
      vim.cmd("!" .. install_cmd)
    else
      -- open a small split, make it full width, run the command
      vim.cmd(fmt("25split | wincmd J | terminal %s", install_cmd))
    end
  end
end

local PACKER_COMPILED_PATH = fn.stdpath("cache") .. "/packer/packer_compiled.lua"

-----------------------------------------------------------------------------//
-- Bootstrap Packer {{{3
-----------------------------------------------------------------------------//
local install_path = fmt("%s/site/pack/packer/start/packer.nvim", fn.stdpath("data"))
if fn.empty(fn.glob(install_path)) > 0 then
  packer_notify("Downloading packer.nvim...")
  -- packer_notify(fn.system({
  --   "git",
  --   "clone",
  --   "--depth",
  --   "1",
  --   "https://github.com/wbthomason/packer.nvim",
  --   install_path,
  -- }))
  _G.packer_bootstrap = fn.system({
    "git",
    "clone",
    "--depth",
    "1",
    "https://github.com/wbthomason/packer.nvim",
    install_path,
  })
end

-- vim.cmd([[
--   augroup packer_user_config
--     autocmd!
--     autocmd BufWritePost packer-config.lua source <afile> | PackerCompile
--   augroup end
-- ]])
----------------------------------------------------------------------------- }}}1
-- cfilter plugin allows filter down an existing quickfix list
vim.cmd("packadd! cfilter")

---@see: https://github.com/lewis6991/impatient.nvim/issues/35
-- mega.safe_require("impatient")

--- NOTE "use" functions cannot call *upvalues* i.e. the functions
--- passed to setup or config etc. cannot reference aliased functions
--- or local variables
require("packer").startup({
  function(use) -- use, use_rocks
    use("wbthomason/packer.nvim") -- Package manager

    -- use_rocks("penlight")

    ------------------------------------------------------------------------------
    -- (profiling/speed improvements) --
    use({
      "dstein64/vim-startuptime",
      config = function()
        vim.g.startuptime_tries = 10
      end,
    })
    use({ "lewis6991/impatient.nvim" })
    use({ "nathom/filetype.nvim" })
    ------------------------------------------------------------------------------
    -- (appearance/UI/visuals) --
    use({ "rktjmp/lush.nvim" })
    use({ "norcalli/nvim-colorizer.lua" })
    use({ "dm1try/golden_size" })
    use({ "kyazdani42/nvim-web-devicons" })
    use({ "edluffy/specs.nvim" })
    use({ "antoinemadec/FixCursorHold.nvim" }) -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
    use({ "karb94/neoscroll.nvim" })
    use({ "lukas-reineke/indent-blankline.nvim" })
    use({ "MunifTanjim/nui.nvim" })
    use({ "stevearc/dressing.nvim" })
    use({ "folke/which-key.nvim" })
    use({ "ojroques/nvim-bufdel" })
    use({ "rcarriga/nvim-notify" })
    ------------------------------------------------------------------------------
    -- (LSP/completion) --
    use({ "neovim/nvim-lspconfig" })
    -- "williamboman/nvim-lsp-installer" -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L229-L244
    use({ "nvim-lua/plenary.nvim" })
    use({ "nvim-lua/popup.nvim" })
    use({ "hrsh7th/nvim-cmp" })
    use({ "hrsh7th/cmp-nvim-lsp" })
    use({ "hrsh7th/cmp-nvim-lua" })
    use({ "saadparwaiz1/cmp_luasnip" })
    use({ "hrsh7th/cmp-cmdline" })
    use({ "hrsh7th/cmp-buffer" })
    use({ "hrsh7th/cmp-path" })
    use({ "hrsh7th/cmp-emoji" })
    use({ "f3fora/cmp-spell" })
    use({ "hrsh7th/cmp-nvim-lsp-document-symbol" })
    use({ "hrsh7th/cmp-nvim-lsp-signature-help" })
    use({ "L3MON4D3/LuaSnip" })
    use({ "rafamadriz/friendly-snippets" })
    use({ "ray-x/lsp_signature.nvim" })
    use({ "j-hui/fidget.nvim" }) -- replace lsp-status with this
    use({ "nvim-lua/lsp_extensions.nvim" })
    use({ "jose-elias-alvarez/nvim-lsp-ts-utils" })
    use({ "jose-elias-alvarez/null-ls.nvim" })
    use({ "b0o/schemastore.nvim" })
    use({ "folke/trouble.nvim" })
    use({ "abecodes/tabout.nvim" })
    use({ "https://gitlab.com/yorickpeterse/nvim-dd.git" })
    use({ "mhartington/formatter.nvim" })
    ------------------------------------------------------------------------------
    -- (treesitter) --
    use({
      "nvim-treesitter/nvim-treesitter",
      run = function()
        vim.cmd("TSUpdate")
      end,
    })
    use({ "nvim-treesitter/playground" })
    use({ "nvim-treesitter/nvim-treesitter-refactor" })
    use({ "mfussenegger/nvim-treehopper" })
    use({ "JoosepAlviste/nvim-ts-context-commentstring" })
    use({ "windwp/nvim-ts-autotag" })
    use({ "p00f/nvim-ts-rainbow" })
    -- "SmiteshP/nvim-gps"
    use({ "RRethy/nvim-treesitter-textsubjects" })
    use({ "David-Kunz/treesitter-unit" })
    use({ "nvim-treesitter/nvim-tree-docs" })
    -- "primeagen/harpoon"
    -- "romgrk/nvim-treesitter-context"

    ------------------------------------------------------------------------------
    -- (FZF/telescope/file/document navigation) --
    -- "ggandor/lightspeed.nvim"
    use({ "phaazon/hop.nvim" })
    use({ "elihunter173/dirbuf.nvim" })
    -- "kyazdani42/nvim-tree.lua"

    -- use({
    --   "nvim-telescope/telescope.nvim",
    --   cmd = "Telescope",
    --   module_pattern = "telescope.*",
    --   config = conf("telescope"),
    --   requires = {
    --     {
    --       "nvim-telescope/telescope-fzf-native.nvim",
    --       run = "make",
    --       after = "telescope.nvim",
    --       config = function()
    --         require("telescope").load_extension("fzf")
    --       end,
    --     },
    --     {
    --       "nvim-telescope/telescope-frecency.nvim",
    --       after = "telescope.nvim",
    --       requires = "tami5/sqlite.lua",
    --     },
    --     {
    --       "camgraff/telescope-tmux.nvim",
    --       after = "telescope.nvim",
    --       config = function()
    --         require("telescope").load_extension("tmux")
    --       end,
    --     },
    --     {
    --       "nvim-telescope/telescope-smart-history.nvim",
    --       after = "telescope.nvim",
    --       config = function()
    --         require("telescope").load_extension("smart_history")
    --       end,
    --     },
    --     {
    --       "nvim-telescope/telescope-github.nvim",
    --       after = "telescope.nvim",
    --       config = function()
    --         require("telescope").load_extension("gh")
    --       end,
    --     },
    --   },
    -- })

    use({ "tami5/sqlite.lua" })
    use({ "nvim-telescope/telescope.nvim" })
    use({ "nvim-telescope/telescope-frecency.nvim" })
    use({ "nvim-telescope/telescope-fzf-native.nvim", run = "make" })
    use({ "camgraff/telescope-tmux.nvim" })
    use({ "nvim-telescope/telescope-media-files.nvim" })
    use({ "nvim-telescope/telescope-symbols.nvim" })
    use({ "nvim-telescope/telescope-smart-history.nvim" })
    -- -- "nvim-telescope/telescope-file-browser.nvim"

    ------------------------------------------------------------------------------
    -- (text objects) --
    use({ "tpope/vim-rsi" })
    use({ "kana/vim-textobj-user" })
    use({ "kana/vim-operator-user" })
    -- "mattn/vim-textobj-url" -- au/iu for url; FIXME: not working presently
    use({ "jceb/vim-textobj-uri" }) -- au/iu for url
    use({ "whatyouhide/vim-textobj-xmlattr" })
    use({ "amiralies/vim-textobj-elixir" })
    use({ "kana/vim-textobj-entire" }) -- ae/ie for entire buffer
    use({ "Julian/vim-textobj-variable-segment" }) -- av/iv for variable segment
    use({ "beloglazov/vim-textobj-punctuation" }) -- au/iu for punctuation
    use({ "michaeljsmith/vim-indent-object" }) -- ai/ii for indentation area
    -- "chaoren/vim-wordmotion" -- to move across cases and words and such
    use({ "wellle/targets.vim" })
    -- research: windwp/nvim-spectre

    ------------------------------------------------------------------------------
    -- (GIT, vcs, et al) --
    -- {"keith/gist.vim", run = "!chmod -HR 0600 ~/.netrc"} -- TODO: find lua replacement (i don't want python)
    use({ "mattn/webapi-vim" })
    use({ "rhysd/conflict-marker.vim" })
    use({ "itchyny/vim-gitbranch" })
    use({ "rhysd/git-messenger.vim" })
    use({ "sindrets/diffview.nvim" })
    use({ "tpope/vim-fugitive" })
    use({ "lewis6991/gitsigns.nvim" })
    -- "drzel/vim-repo-edit" -- https://github.com/drzel/vim-repo-edit#usage
    -- "gabebw/vim-github-link-opener"
    use({ "ruifm/gitlinker.nvim" })
    use({ "ruanyl/vim-gh-line" })
    use({ "rlch/github-notifications.nvim" })
    ------------------------------------------------------------------------------
    -- (DEV, development, et al) --
    -- "ahmedkhalf/project.nvim"
    use("tpope/vim-projectionist")
    -- "tjdevries/edit_alternate.vim"
    use({ "vim-test/vim-test" }) -- research to supplement vim-test: rcarriga/vim-ultest, for JS testing: David-Kunz/jester
    use({ "mfussenegger/nvim-dap" }) -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
    use({ "tpope/vim-ragtag" })
    -- { "mrjones2014/dash.nvim", run = "make install", opt = true },
    use({ "editorconfig/editorconfig-vim" })
    use({ "zenbro/mirror.vim", opt = true })
    use({ "vuki656/package-info.nvim" })
    -- "jamestthompson3/nvim-remote-containers"
    use({ "tpope/vim-dadbod" })
    use({ "kristijanhusak/vim-dadbod-completion" })
    use({ "kristijanhusak/vim-dadbod-ui" })
    use({
      "glacambre/firenvim",
      run = function()
        vim.fn["firenvim#install"](0)
      end,
    })
    ------------------------------------------------------------------------------
    -- (the rest...) --
    use({ "nacro90/numb.nvim" })
    use({ "ethanholz/nvim-lastplace" })
    use({ "andymass/vim-matchup" }) -- https://github.com/andymass/vim-matchup#tree-sitter-integration
    use({ "windwp/nvim-autopairs" })
    use({ "alvan/vim-closetag" })
    use({ "numToStr/Comment.nvim" })
    use({ "tpope/vim-eunuch" })
    use({ "tpope/vim-abolish" })
    use({ "tpope/vim-rhubarb" })
    use({ "tpope/vim-repeat" })
    use({ "tpope/vim-surround" })
    use({ "tpope/vim-unimpaired" })
    use({ "lambdalisue/suda.vim" })
    use({ "EinfachToll/DidYouMean" })
    use({ "wsdjeg/vim-fetch" }) -- vim path/to/file.ext:12:3
    use({ "ConradIrwin/vim-bracketed-paste" }) -- FIXME: delete?
    -- "kevinhwang91/nvim-hclipboard"
    -- :Messages <- view messages in quickfix list
    -- :Verbose  <- view verbose output in preview window.
    -- :Time     <- measure how long it takes to run some stuff.
    use({ "tpope/vim-scriptease" })
    use({ "sunaku/tmux-navigate" })
    -- "tmux-plugins/vim-tmux-focus-events"
    use({ "junegunn/vim-slash" })
    use({ "junegunn/vim-easy-align" })
    use({ "outstand/logger.nvim" })

    ------------------------------------------------------------------------------
    -- (LANGS, syntax, et al) --
    -- # markdown/prose
    -- "plasticboy/vim-markdown" -- replacing with the below:
    use({ "ixru/nvim-markdown" })
    -- "rhysd/vim-gfm-syntax"
    use({ "iamcco/markdown-preview.nvim", run = "cd app && yarn install" })
    use({ "ellisonleao/glow.nvim" })
    -- { "harshad1/bullets.vim", branch = "performance_improvements" }
    use({ "kristijanhusak/orgmode.nvim" })
    use({ "akinsho/org-bullets.nvim" })
    use({ "dkarter/bullets.vim" })
    -- "dhruvasagar/vim-table-mode"
    use({ "lukas-reineke/headlines.nvim" })
    -- https://github.com/preservim/vim-wordy
    -- https://github.com/jghauser/follow-md-links.nvim
    -- https://github.com/jakewvincent/mkdnflow.nvim
    -- https://github.com/jubnzv/mdeval.nvim
    -- "NFrid/due.nvim"
    use({ "mickael-menu/zk-nvim" })
    -- # ruby/rails
    use({ "tpope/vim-rails" })
    -- # elixir
    -- use({"elixir-editors/vim-elixir"})
    use({ "ngscheurich/edeex.nvim" })
    -- # elm
    use({ "antew/vim-elm-analyse" })
    -- # lua
    use({ "tjdevries/nlua.nvim" })
    use({ "norcalli/nvim.lua" })
    use({ "euclidianace/betterlua.vim" })
    use({ "folke/lua-dev.nvim" })
    use({ "andrejlevkovitch/vim-lua-format" })
    use({ "milisims/nvim-luaref" })
    -- # JS/TS/JSON
    use({ "MaxMEllon/vim-jsx-pretty" })
    use({ "heavenshell/vim-jsdoc" })
    use({ "jxnblk/vim-mdx-js" })
    use({ "kchmck/vim-coffee-script" })
    use({ "briancollins/vim-jst" })
    -- # HTML
    -- "mattn/emmet-vim"
    use({ "skwp/vim-html-escape" })
    use({ "pedrohdz/vim-yaml-folds" })
    -- # misc
    use({ "avakhov/vim-yaml" })
    use({ "chr4/nginx.vim" })
    use({ "nanotee/luv-vimdocs" })
    use({ "fladson/vim-kitty" })
    use({ "SirJson/fzf-gitignore" })

    use({
      "akinsho/toggleterm.nvim",
      config = function()
        require("toggleterm").setup({
          open_mapping = [[<c-\>]],
          shade_filetypes = { "none" },
          direction = "vertical",
          insert_mappings = false,
          start_in_insert = true,
          float_opts = { border = "curved", winblend = 3 },
          size = function(term)
            if term.direction == "horizontal" then
              return 15
            elseif term.direction == "vertical" then
              return math.floor(vim.o.columns * 0.4)
            end
          end,
          --   REF: @ryansch:
          --   size = function(term)
          --     if term.direction == "horizontal" then
          --       return 20
          --     elseif term.direction == "vertical" then
          --       return vim.o.columns * 0.4
          --     end
          --   end,
          persist_size = false,
          on_open = function(term)
            term.opened = term.opened or false

            if not term.opened then
              term:send("eval $(desk load)")
            end

            term.opened = true
          end,
        })

        local float_handler = function(term)
          if vim.fn.mapcheck("jk", "t") ~= "" then
            vim.api.nvim_buf_del_keymap(term.bufnr, "t", "jk")
            vim.api.nvim_buf_del_keymap(term.bufnr, "t", "<esc>")
          end
        end

        local Terminal = require("toggleterm.terminal").Terminal
        local htop = Terminal:new({
          cmd = "htop",
          hidden = "true",
          direction = "float",
          on_open = float_handler,
        })

        mega.command({
          "Htop",
          function()
            htop:toggle()
          end,
        })
      end,
    })

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if _G.packer_bootstrap then
      require("packer").sync()
    end
  end,
  log = { level = "info" },
  config = {
    compile_path = PACKER_COMPILED_PATH,
    display = {
      prompt_border = "rounded",
      open_cmd = "silent topleft 65vnew",
    },
    profile = {
      enable = true,
      threshold = 1,
    },
  },
})

-- mega.command({
--   "PackerCompiledEdit",
--   function()
--     vim.cmd(fmt("edit %s", PACKER_COMPILED_PATH))
--   end,
-- })

-- mega.command({
--   "PackerCompiledDelete",
--   function()
--     vim.fn.delete(PACKER_COMPILED_PATH)
--     packer_notify(fmt("Deleted %s", PACKER_COMPILED_PATH))
--   end,
-- })

-- if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(PACKER_COMPILED_PATH) then
--   mega.source(PACKER_COMPILED_PATH)
--   vim.g.packer_compiled_loaded = true
-- end

mega.augroup("PackerSetupInit", {
  {
    events = { "BufWritePost" },
    targets = { "*/mega/plugins/*.lua" },
    command = function()
      mega.invalidate("mega.plugins", true)
      require("packer").compile()
    end,
  },
})

-- nnoremap("<leader>ps", [[<Cmd>PackerSync<CR>]])
-- nnoremap("<leader>pc", [[<Cmd>PackerClean<CR>]])

-- vim:foldmethod=marker
