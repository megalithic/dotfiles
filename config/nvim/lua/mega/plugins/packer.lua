local fn = vim.fn
local fmt = string.format
local mega = require("mega.globals")
local M = {}

---A thin wrapper around vim.notify to add packer details to the message
---@param msg string
local function packer_notify(msg, level)
  vim.notify(msg, level, { title = "Packer" })
end

local function conf(name)
  require(fmt("mega.plugins.%s", name))
end

local function clone()
  local repo = "https://github.com/wbthomason/packer.nvim"
  local rtp_type = "start" -- "opt" or "start"
  local install_path = fmt("%s/site/pack/packer/%s/packer.nvim", fn.stdpath("data"), rtp_type)

  if fn.empty(fn.glob(install_path)) > 0 then
    packer_notify("Downloading packer.nvim...")
    local packer_clone = fn.system({
      "git",
      "clone",
      "--depth",
      "1",
      repo,
      install_path,
    })
    packer_notify(packer_clone)

    if packer_clone then
      vim.schedule(function()
        packer_notify("Syncing plugins...")
        vim.cmd("packadd! packer.nvim")
        require("packer").sync()
      end)
    end
  else
    -- FIXME: currently development versions of packer do not work
    -- local name = vim.env.DEVELOPING and 'local-packer.nvim' or 'packer.nvim'
    vim.cmd("packadd! packer.nvim")
  end
end

function M.sync_all()
  -- Load packer.nvim
  vim.cmd("packadd! packer.nvim")
  packer_notify("Syncing plugins...")
  require("packer").sync()
end

-- `bin/packer-install` runs this for us in a headless nvim environment
function M.bootstrap(with_sync)
  clone()

  if with_sync then
    M.sync_all()
  end
end

-- HACK: Big Sur and Luarocks support
-- @see https://github.com/wbthomason/packer.nvim/issues/180
fn.setenv("MACOSX_DEPLOYMENT_TARGET", "10.15")

local PACKER_COMPILED_PATH = fn.stdpath("cache") .. "/packer/packer_compiled.lua"

---Some plugins are not safe to be reloaded because their setup functions
---and are not idempotent. This wraps the setup calls of such plugins
---@param func fun()
-- function mega.block_reload(func)
--   if vim.g.packer_compiled_loaded then
--     return
--   end
--   func()
-- end

-- `cfilter` plugin allows filtering down an existing quickfix list
vim.cmd("packadd! cfilter")

M.bootstrap()

local packer = require("packer")
packer.startup({
  log = { level = "info" },
  config = {
    -- https://github.com/wbthomason/packer.nvim/issues/202
    max_jobs = 30,
    -- https://github.com/wbthomason/packer.nvim/issues/201
    -- https://github.com/wbthomason/packer.nvim/issues/274
    -- https://github.com/wbthomason/packer.nvim/issues/554
    compile_path = PACKER_COMPILED_PATH,
    -- package_root = string.format("%s/pack", vim.fn.stdpath("config")),
    git = {
      clone_timeout = 240,
    },
    profile = {
      enable = true,
      threshold = 1,
    },
    display = {
      non_interactive = vim.env.PACKER_NON_INTERACTIVE or false,
      prompt_border = mega.get_border(),
      open_cmd = "silent topleft 65vnew",
      -- open_cmd = function()
      --   return require("packer.util").float({ border = mega.get_border() })
      -- end,
    },
  },
  function(use, use_rocks)
    use_rocks("penlight")

    use({ "wbthomason/packer.nvim" })

    ------------------------------------------------------------------------------
    -- (profiling/speed improvements) --
    use({
      "dstein64/vim-startuptime",
      cmd = "StartupTime",
      config = function()
        vim.g.startuptime_tries = 15
      end,
    })
    -- HACK: redundant once https://github.com/neovim/neovim/pull/15436 is merged
    use({ "lewis6991/impatient.nvim" })

    ------------------------------------------------------------------------------
    -- (core) --
    -- TODO: this fixes a bug in neovim core that prevents "CursorHold" from working
    -- hopefully one day when this issue is fixed this can be removed
    -- @see: https://github.com/neovim/neovim/issues/12587
    use({ "antoinemadec/FixCursorHold.nvim" })
    use({ "nvim-lua/plenary.nvim" })
    use({ "nvim-lua/popup.nvim" })

    ------------------------------------------------------------------------------
    -- (ui/appearance/colors) --
    use({ "rktjmp/lush.nvim" })
    use({ "norcalli/nvim-colorizer.lua" })
    use({ "dm1try/golden_size" })
    use({ "kyazdani42/nvim-web-devicons" })
    use({
      "lukas-reineke/virt-column.nvim",
      config = function()
        -- initial setup of virt-column; required for this plugin
        require("virt-column").setup({ char = "│" })
      end,
    })
    use({ "MunifTanjim/nui.nvim" })
    use({ "folke/which-key.nvim", config = conf("whichkey") })
    use({ "rcarriga/nvim-notify" })
    use({ "echasnovski/mini.nvim" })

    ------------------------------------------------------------------------------
    -- (qf/quickfixlist) --
    use({
      "kevinhwang91/nvim-bqf",
      ft = "qf",
      config = function()
        local fugitive_pv_timer
        local preview_fugitive = function(bufnr, qwinid, bufname)
          local is_loaded = vim.api.nvim_buf_is_loaded(bufnr)
          if fugitive_pv_timer and fugitive_pv_timer:get_due_in() > 0 then
            fugitive_pv_timer:stop()
            fugitive_pv_timer = nil
          end
          fugitive_pv_timer = vim.defer_fn(function()
            if not is_loaded then
              vim.api.nvim_buf_call(bufnr, function()
                vim.cmd(("do fugitive BufReadCmd %s"):format(bufname))
              end)
            end
            require("bqf.preview.handler").open(qwinid, nil, true)
            vim.api.nvim_buf_set_option(require("bqf.preview.session").float_bufnr(), "filetype", "git")
          end, is_loaded and 0 or 60)
          return true
        end

        require("bqf").setup({
          auto_enable = true,
          auto_resize_height = true,
          preview = {
            auto_preview = true,
            win_height = 12,
            win_vheight = 12,
            delay_syntax = 80,
            border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
            ---@diagnostic disable-next-line: unused-local
            should_preview_cb = function(bufnr, qwinid)
              local bufname = vim.api.nvim_buf_get_name(bufnr)
              local fsize = vim.fn.getfsize(bufname)
              if fsize > 100 * 1024 then
                -- skip file size greater than 100k
                return false
              elseif bufname:match("^fugitive://") then
                return preview_fugitive(bufnr, qwinid, bufname)
              end

              return true
            end,
          },
          filter = {
            fzf = {
              extra_opts = { "--bind", "ctrl-o:toggle-all", "--delimiter", "│" },
            },
          },
        })
      end,
    })
    use({
      "https://gitlab.com/yorickpeterse/nvim-pqf",
      event = "BufReadPre",
      config = function()
        require("pqf").setup({})
      end,
    })

    ------------------------------------------------------------------------------
    -- (lsp) --
    use({
      "neovim/nvim-lspconfig",
      requires = {
        {
          "j-hui/fidget.nvim",
          config = function()
            require("fidget").setup({
              text = {
                spinner = "dots_pulse",
                done = "",
              },
              window = {
                blend = 10,
                relative = "editor",
              },
              sources = { -- Sources to configure
                ["elixirls"] = { -- Name of source
                  ignore = false, -- Ignore notifications from this source
                },
              },
            })
          end,
        },
        {
          "ray-x/lsp_signature.nvim",
          config = function()
            require("lsp_signature").setup({
              bind = true,
              fix_pos = false,
              auto_close_after = 3,
              hint_enable = false,
              handler_opts = { border = mega.get_border() },
              zindex = 99, -- Keep signature popup below the completion PUM
            })
          end,
        },
        { "nvim-lua/lsp_extensions.nvim" },
        {
          "jose-elias-alvarez/null-ls.nvim",
          requires = {
            "nvim-lua/plenary.nvim",
          },
        },
        { "b0o/schemastore.nvim" },
        { "mickael-menu/zk-nvim" },
      },
    })

    ------------------------------------------------------------------------------
    -- (completion/snippets) --
    use({
      "hrsh7th/nvim-cmp",
      module = "cmp",
      event = "InsertEnter",
      config = conf("cmp"),
      requires = {
        { "hrsh7th/cmp-nvim-lsp", after = "nvim-lspconfig" },
        { "hrsh7th/cmp-nvim-lua", after = "nvim-cmp" },
        { "andersevenrud/cmp-tmux", after = "nvim-cmp" },
        { "saadparwaiz1/cmp_luasnip", after = "nvim-cmp" },
        { "hrsh7th/cmp-path", after = "nvim-cmp" },
        { "hrsh7th/cmp-buffer", after = "nvim-cmp" },
        { "hrsh7th/cmp-emoji", after = "nvim-cmp" },
        { "f3fora/cmp-spell", after = "nvim-cmp" },
        { "hrsh7th/cmp-cmdline", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-signature-help", after = "nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp-document-symbol", after = "nvim-cmp" },
        { "dmitmel/cmp-cmdline-history", after = "nvim-cmp" },
        { "uga-rosa/cmp-dictionary", after = "nvim-cmp" },
      },
    })
    use({
      "L3MON4D3/LuaSnip",
      requires = {
        { "rafamadriz/friendly-snippets" },
      },
      event = "InsertEnter",
      module = "luasnip",
      config = conf("luasnip"),
    })

    ------------------------------------------------------------------------------
    -- (treesitter) --
    use({
      "nvim-treesitter/nvim-treesitter",
      run = ":TSUpdate",
      config = conf("treesitter"),
      requires = {
        {
          "nvim-treesitter/nvim-treesitter-textobjects",
          after = "nvim-treesitter",
        },
        {
          "nvim-treesitter/playground",
          cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" },
          after = "nvim-treesitter",
          setup = function()
            mega.nnoremap("<leader>E", "<Cmd>TSHighlightCapturesUnderCursor<CR>", "treesitter: highlight cursor group")
          end,
        },
        { "JoosepAlviste/nvim-ts-context-commentstring", after = "nvim-treesitter" },
        { "nvim-treesitter/nvim-tree-docs", after = "nvim-treesitter" },
        {
          "windwp/nvim-ts-autotag",
          config = function()
            require("nvim-ts-autotag").setup({
              filetypes = {
                "html",
                "xml",
                "javascript",
                "typescriptreact",
                "javascriptreact",
                "vue",
                "elixir",
                "heex",
              },
            })
          end,
        },
        { "p00f/nvim-ts-rainbow", after = "nvim-treesitter" },
        {
          "mfussenegger/nvim-treehopper",
          after = "nvim-treesitter",
          config = function()
            require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }
            mega.augroup("TreehopperMaps", {
              {
                event = "FileType",
                command = function(args)
                  -- FIXME: this issue should be handled inside the plugin rather than manually
                  local langs = require("nvim-treesitter.parsers").available_parsers()
                  if vim.tbl_contains(langs, vim.bo[args.buf].filetype) then
                    mega.omap("m", ":<C-U>lua require('tsht').nodes()<CR>", { buffer = args.buf })
                    mega.vnoremap("m", ":lua require('tsht').nodes()<CR>", { buffer = args.buf })
                  end
                end,
              },
            })
          end,
        },
        { "RRethy/nvim-treesitter-textsubjects", after = "nvim-treesitter" },
        { "David-Kunz/treesitter-unit", after = "nvim-treesitter" },
        {
          "nvim-treesitter/nvim-treesitter-context",
          after = "nvim-treesitter",
          config = function()
            require("treesitter-context").setup({
              multiline_threshold = 4,
              separator = { "▁", "TreesitterContextBorder" }, -- ─▁
            })
          end,
        },
        { "SmiteshP/nvim-gps", after = "nvim-treesitter" },
      },
    })
    use({
      "danymat/neogen",
      requires = "nvim-treesitter/nvim-treesitter",
      module = "neogen",
      setup = function()
        mega.nnoremap("<localleader>nc", require("neogen").generate, "comment: generate")
        mega.nnoremap("gdd", require("neogen").generate, "comment: generate")
      end,
      config = function()
        require("neogen").setup({ snippet_engine = "luasnip" })
      end,
    })

    ------------------------------------------------------------------------------
    -- (telescope/file navigation/mru) --
    use({
      "nvim-telescope/telescope.nvim",
      cmd = "Telescope",
      module_pattern = "telescope.*",
      -- setup = conf("telescope").setup,
      -- config = conf("telescope").config,
      config = conf("telescope"),
      requires = {
        {
          "nvim-telescope/telescope-fzf-native.nvim",
          run = "make",
          after = "telescope.nvim",
          config = function()
            require("telescope").load_extension("fzf")
          end,
        },
        {
          "nvim-telescope/telescope-frecency.nvim",
          after = "telescope.nvim",
          requires = "tami5/sqlite.lua",
        },
        {
          "nvim-telescope/telescope-smart-history.nvim",
          after = "telescope.nvim",
          config = function()
            require("telescope").load_extension("smart_history")
          end,
        },
      },
    })

    use({
      "phaazon/hop.nvim",
      cond = false,
      opt = true,
      keys = { { "n", "s" }, "f", "F" },
      config = function()
        local hop = require("hop")
        hop.setup({
          -- remove h,j,k,l from hops list of keys
          keys = "etovxqpdygfbzcisuran",
          jump_on_sole_occurrence = true,
          uppercase_labels = false,
        })

        nnoremap("s", function()
          hop.hint_char1({ multi_windows = false })
        end)
        -- NOTE: override F/f using hop motions
        vim.keymap.set({ "x", "n" }, "F", function()
          hop.hint_char1({
            direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
            current_line_only = true,
            inclusive_jump = false,
          })
        end)
        vim.keymap.set({ "x", "n" }, "f", function()
          hop.hint_char1({
            direction = require("hop.hint").HintDirection.AFTER_CURSOR,
            current_line_only = true,
            inclusive_jump = false,
          })
        end)
        onoremap("F", function()
          hop.hint_char1({
            direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
            current_line_only = true,
            inclusive_jump = true,
          })
        end)
        onoremap("f", function()
          hop.hint_char1({
            direction = require("hop.hint").HintDirection.AFTER_CURSOR,
            current_line_only = true,
            inclusive_jump = true,
          })
        end)
      end,
    })
    use({
      "ggandor/lightspeed.nvim",
      opt = true,
      cond = true,
      config = function()
        require("lightspeed").setup({

          -- jump_to_first_match = true,
          -- jump_on_partial_input_safety_timeout = 400,
          -- This can get _really_ slow if the window has a lot of content,
          -- turn it on only if your machine can always cope with it.
          -- jump_to_unique_chars = true,
          -- jump_to_unique_chars = false,
          -- safe_labels = {},
          -- jump_to_unique_chars = true,
          -- limit_ft_matches = 7,
          -- grey_out_search_area = true,
          -- match_only_the_start_of_same_char_seqs = true,
          -- limit_ft_matches = 5,
          -- full_inclusive_prefix_key = '<c-x>',
          -- By default, the values of these will be decided at runtime,
          -- based on `jump_to_first_match`.
          -- labels = nil,
          -- cycle_group_fwd_key = nil,
          -- cycle_group_bwd_key = nil,
          --
          ignore_case = false,
          exit_after_idle_msecs = { unlabeled = 1000, labeled = 1500 },
          --- s/x ---
          jump_to_unique_chars = { safety_timeout = 400 }, -- jump right after the first input, if the target character is unique in the search direction
          match_only_the_start_of_same_char_seqs = true, -- separator line will not snatch up all the available labels for `==` or `--`
          substitute_chars = { ["\r"] = "¬" }, -- highlighted matches by the given characters
          special_keys = { -- switch to the next/previous group of matches, when there are more matches than labels available
            next_match_group = "<space>",
            prev_match_group = "<tab>",
          },
          force_beacons_into_match_width = false,
          --- f/t ---
          limit_ft_matches = 4, -- For 1-character search, the next 'n' matches will be highlighted after [count]
          repeat_ft_with_target_char = false, -- repeat f/t motions by pressing the target character repeatedly
        })
      end,
    })
    use({ "akinsho/toggleterm.nvim", config = conf("toggleterm") })
    use({
      "elihunter173/dirbuf.nvim",
      config = function()
        require("dirbuf").setup({

          hash_padding = 2,
          show_hidden = true,
          sort_order = "directories_first",
        })
      end,
    })

    ------------------------------------------------------------------------------
    -- (git, gh, vcs, et al) --
    use({ "mattn/webapi-vim" })
    use({ "akinsho/git-conflict.nvim" })
    use({ "itchyny/vim-gitbranch" })
    use({ "rhysd/git-messenger.vim" })
    use({ "tpope/vim-fugitive" })
    use({ "lewis6991/gitsigns.nvim", config = conf("gitsigns") })
    -- @trial "drzel/vim-repo-edit" -- https://github.com/drzel/vim-repo-edit#usage
    -- @trial "gabebw/vim-github-link-opener"
    use({
      "ruifm/gitlinker.nvim",
      requires = "plenary.nvim",
      keys = { "<localleader>gu", "<localleader>go" },
      setup = function()
        require("which-key").register(
          { gu = "gitlinker: get line url", go = "gitlinker: open repo url" },
          { prefix = "<localleader>" }
        )
      end,
      config = function()
        local linker = require("gitlinker")
        linker.setup({ mappings = "<localleader>gu" })
        mega.nnoremap("<localleader>go", function()
          linker.get_repo_url({ action_callback = require("gitlinker.actions").open_in_browser })
        end, "gitlinker: open in browser")
      end,
    })
    use({ "ruanyl/vim-gh-line" })
    -- @trial "ldelossa/gh.nvim"

    ------------------------------------------------------------------------------
    -- (dev, testing, debugging) --
    use({ "rgroli/other.nvim" })
    use({ "tpope/vim-projectionist", config = conf("projectionist") })
    -- @trial "tjdevries/edit_alternate.vim"
    use({ "vim-test/vim-test", config = conf("vim-test") })
    use({
      "rcarriga/neotest",
      config = conf("neotest"),
      requires = {
        "rcarriga/neotest-plenary",
        "rcarriga/neotest-vim-test",
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "antoinemadec/FixCursorHold.nvim",
      },
    })
    use({
      "mfussenegger/nvim-dap",
      module = "dap",
      -- setup = conf("dap").setup,
      -- config = conf("dap").config,
      config = conf("dap"),
      requires = {
        {
          "rcarriga/nvim-dap-ui",
          after = "nvim-dap",
          config = conf("dapui"),
        },
        {
          "theHamsta/nvim-dap-virtual-text",
          after = "nvim-dap",
          config = function()
            require("nvim-dap-virtual-text").setup({ all_frames = true })
          end,
        },
      },
    })
    use({ "jbyuki/one-small-step-for-vimkind", requires = "nvim-dap" })
    use({ "tpope/vim-ragtag" })
    -- @trial { "mrjones2014/dash.nvim" run = "make install", opt = true },
    use({ "editorconfig/editorconfig-vim" })
    use({ "zenbro/mirror.vim", opt = true })

    ------------------------------------------------------------------------------
    -- (the rest...) --
    use({ "nacro90/numb.nvim" })
    use({ "andymass/vim-matchup" })
    use({ "windwp/nvim-autopairs" })
    use({ "alvan/vim-closetag" })
    use({ "numToStr/Comment.nvim" })
    use("wellle/targets.vim")
    use({
      "kana/vim-textobj-user",
      requires = {
        "kana/vim-operator-user",
        {
          "glts/vim-textobj-comment",
          config = function()
            vim.g.textobj_comment_no_default_key_mappings = 1
            mega.xmap("ax", "<Plug>(textobj-comment-a)")
            mega.omap("ax", "<Plug>(textobj-comment-a)")
            mega.xmap("ix", "<Plug>(textobj-comment-i)")
            mega.omap("ix", "<Plug>(textobj-comment-i)")
          end,
        },
      },
    })
    use({
      "johmsalas/text-case.nvim",
      config = function()
        require("textcase").setup()
        mega.nnoremap("<localleader>[", ":Subs/<C-R><C-W>//<LEFT>", { silent = false })
        mega.nnoremap("<localleader>]", ":%Subs/<C-r><C-w>//c<left><left>", { silent = false })
        mega.xnoremap("<localleader>[", [["zy:%Subs/<C-r><C-o>"//c<left><left>]], { silent = false })
      end,
    })
    use({ "tpope/vim-eunuch" })
    use({ "tpope/vim-abolish" })
    use({ "tpope/vim-rhubarb" })
    use({ "tpope/vim-repeat" })
    use({
      "tpope/vim-surround",
      config = function()
        mega.xmap("s", "<Plug>VSurround")
        mega.xmap("s", "<Plug>VSurround")
      end,
    })
    use({ "tpope/vim-unimpaired" })
    use({ "tpope/vim-apathy" })
    use({ "lambdalisue/suda.vim" })
    use({ "EinfachToll/DidYouMean" })
    -- use("wsdjeg/vim-fetch") -- vim path/to/file.ext:12:3
    -- prevent select and visual mode from overwriting the clipboard
    use({
      "kevinhwang91/nvim-hclipboard",
      event = "InsertCharPre",
      config = function()
        require("hclipboard").start()
      end,
    })
    -- :Messages <- view messages in quickfix list
    -- :Verbose  <- view verbose output in preview window.
    -- :Time     <- measure how long it takes to run some stuff.
    use({ "tpope/vim-scriptease" })
    use({
      "aca/wezterm.nvim",
      cond = false,
      -- cond = function()
      --   return not vim.env.TMUX
      -- end,
    })
    use({
      "knubie/vim-kitty-navigator",
      run = "cp ./*.py ~/.config/kitty/",
      cond = function()
        return not vim.env.TMUX
      end,
    })
    use({ "RRethy/nvim-align" })

    ------------------------------------------------------------------------------
    -- (notes, prose, markdown) --
    use({ "ixru/nvim-markdown", ft = "markdown" })
    -- "plasticboy/vim-markdown", -- replacing with the below:
    -- "rhysd/vim-gfm-syntax",
    use({
      "iamcco/markdown-preview.nvim",
      run = function()
        vim.fn["mkdp#util#install"]()
      end,
      ft = { "markdown" },
      config = function()
        vim.g.mkdp_auto_start = 0
        vim.g.mkdp_auto_close = 1
      end,
    })
    use({ "ellisonleao/glow.nvim", ft = "markdown" })
    use({ "dkarter/bullets.vim", ft = "markdown" })
    use({ "lukas-reineke/headlines.nvim", ft = "markdown" })
    use({ "mickael-menu/zk-nvim", config = conf("zk") })

    -- @trial https://github.com/artempyanykh/marksman
    -- @trial  "dhruvasagar/vim-table-mode",
    -- @trial https://github.com/ekickx/clipboard-image.nvim
    -- @trial https://github.com/preservim/vim-wordy
    -- @trial https://github.com/jghauser/follow-md-links.nvim
    -- @trial https://github.com/jakewvincent/mkdnflow.nvim
    -- @trial https://github.com/jubnzv/mdeval.nvim

    ------------------------------------------------------------------------------
    -- (langs, syntax, et al) --
    use({ "tjdevries/nlua.nvim", ft = "lua" })
    use({ "norcalli/nvim.lua", ft = "lua" })
    use({ "euclidianace/betterlua.vim", ft = "lua" })
    use({ "folke/lua-dev.nvim", ft = "lua" })
    use({ "andrejlevkovitch/vim-lua-format", ft = "lua" })
    use({ "milisims/nvim-luaref", ft = "lua" })
    use({ "nanotee/luv-vimdocs" })

    use({ "tpope/vim-rails" })
    use({ "ngscheurich/edeex.nvim" })
    use("antew/vim-elm-analyse")

    use({ "kchmck/vim-coffee-script" })
    use({ "briancollins/vim-jst" })

    use({ "MaxMEllon/vim-jsx-pretty" })
    use({ "heavenshell/vim-jsdoc" })
    use({ "jxnblk/vim-mdx-js" })
    use({ "skwp/vim-html-escape" })
    use({ "pedrohdz/vim-yaml-folds" })
    use({ "avakhov/vim-yaml" })
    use({ "chr4/nginx.vim" })
    use({ "fladson/vim-kitty" })
    use({ "SirJson/fzf-gitignore" })

    ------------------------------------------------------------------------------
    -- (work) --
    use({ "outstand/logger.nvim" })
    -- @trial "outstand/titan.nvim"
    -- @trial "ryansch/habitats.nvim"
  end,
})

mega.command("PackerCompiledEdit", function()
  vim.cmd(fmt("edit %s", PACKER_COMPILED_PATH))
end)

mega.command("PackerCompiledDelete", function()
  vim.fn.delete(PACKER_COMPILED_PATH)
  packer_notify(fmt("Deleted %s", PACKER_COMPILED_PATH))
end)

if not vim.g.packer_compiled_loaded and vim.loop.fs_stat(PACKER_COMPILED_PATH) then
  mega.source(PACKER_COMPILED_PATH)
  vim.g.packer_compiled_loaded = true
end

mega.nnoremap("<leader>ps", "<Cmd>PackerSync<CR>", "packer: sync")

mega.augroup("PackerSetupInit", {
  {
    event = "BufWritePost",
    pattern = { "*/mega/plugins/*.lua" },
    desc = "Packer setup and reload",
    command = function()
      mega.invalidate("mega.plugins", true)
      packer.compile()
    end,
  },
})

return M
