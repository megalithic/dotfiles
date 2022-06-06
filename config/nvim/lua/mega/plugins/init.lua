local api = vim.api
local fn = vim.fn
local fmt = string.format
local conf = require("mega.globals").conf

-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs/(opt/start)
-- # local/devel paqs stored here:
--  ~/.local/share/nvim/site/pack/local

-- NOTE: add local module:
-- vim.opt.runtimepath:append '~/path/to/your/plugin'
local PKGS = {
  "savq/paq-nvim",
  ------------------------------------------------------------------------------
  -- (profiling/speed improvements) --
  "dstein64/vim-startuptime",
  "lewis6991/impatient.nvim",

  ------------------------------------------------------------------------------
  -- (appearance/UI/visuals) --
  "rktjmp/lush.nvim",
  "norcalli/nvim-colorizer.lua",
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  -- "karb94/neoscroll.nvim",
  -- "declancm/cinnamon.nvim",
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  "folke/which-key.nvim",
  "rcarriga/nvim-notify",
  "echasnovski/mini.nvim",

  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
  "williamboman/nvim-lsp-installer", -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L229-L244
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  { "hrsh7th/nvim-cmp", branch = "main" },
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
  "ray-x/cmp-treesitter",
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "ray-x/lsp_signature.nvim",
  "j-hui/fidget.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  { "kevinhwang91/nvim-bqf" },
  { url = "https://gitlab.com/yorickpeterse/nvim-pqf" },
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
  { "nvim-treesitter/playground" },
  -- "nvim-treesitter/nvim-treesitter-refactor",
  "nvim-treesitter/nvim-treesitter-textobjects",
  "nvim-treesitter/nvim-tree-docs",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  "mfussenegger/nvim-treehopper",
  "RRethy/nvim-treesitter-textsubjects",
  "David-Kunz/treesitter-unit",
  -- { "lewis6991/nvim-treesitter-context" },
  "SmiteshP/nvim-gps",
  -- @trial ziontee113/syntax-tree-surfer
  -- @trial "primeagen/harpoon",

  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  { "ggandor/lightspeed.nvim", opt = true },
  { "phaazon/hop.nvim", opt = true },
  "akinsho/toggleterm.nvim",
  "elihunter173/dirbuf.nvim",
  -- @trial "nvim-neo-tree/neo-tree.nvim",

  "tami5/sqlite.lua",
  { "nvim-telescope/telescope.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "camgraff/telescope-tmux.nvim",
  "nvim-telescope/telescope-media-files.nvim",
  "nvim-telescope/telescope-symbols.nvim",
  "nvim-telescope/telescope-smart-history.nvim",
  -- @trial "nvim-telescope/telescope-file-browser.nvim",

  ------------------------------------------------------------------------------
  -- (text objects) --
  "tpope/vim-rsi",
  "kana/vim-textobj-user",
  "kana/vim-operator-user",
  -- "mattn/vim-textobj-url", -- au/iu for url; FIXME: not working presently
  -- "jceb/vim-textobj-uri", -- au/iu for url
  -- "whatyouhide/vim-textobj-xmlattr",
  -- "amiralies/vim-textobj-elixir",
  "kana/vim-textobj-entire", -- ae/ie for entire buffer
  "Julian/vim-textobj-variable-segment", -- av/iv for variable segment
  -- "beloglazov/vim-textobj-punctuation", -- au/iu for punctuation
  "michaeljsmith/vim-indent-object", -- ai/ii for indentation area
  -- @trial "chaoren/vim-wordmotion", -- to move across cases and words and such
  "wellle/targets.vim",
  -- @trial: windwp/nvim-spectre

  ------------------------------------------------------------------------------
  -- (GIT, vcs, et al) --
  -- {"keith/gist.vim", run = "chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "mattn/webapi-vim",
  "akinsho/git-conflict.nvim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "tpope/vim-fugitive",
  "lewis6991/gitsigns.nvim",
  -- @trial "drzel/vim-repo-edit", -- https://github.com/drzel/vim-repo-edit#usage
  -- @trial "gabebw/vim-github-link-opener",
  { "ruifm/gitlinker.nvim" },
  { "ruanyl/vim-gh-line" },
  -- @trial "ldelossa/gh.nvim"

  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  "rgroli/other.nvim",
  "tpope/vim-projectionist",
  -- @trial "tjdevries/edit_alternate.vim", -- REF: https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/lua/tj/plugins.lua#L467-L480
  "vim-test/vim-test",
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "tpope/vim-ragtag",
  -- @trial { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  -- @trial "tpope/vim-dadbod",
  -- @trial "kristijanhusak/vim-dadbod-completion",
  -- @trial "kristijanhusak/vim-dadbod-ui",
  -- @trial {
  --   "glacambre/firenvim",
  --   run = function()
  --     vim.fn["firenvim#install"](0)
  --   end,
  -- },
  ------------------------------------------------------------------------------
  -- (the rest...) --
  "nacro90/numb.nvim",
  "andymass/vim-matchup",
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
  -- "aca/wezterm.nvim",
  { "sunaku/tmux-navigate", opt = true },
  { "knubie/vim-kitty-navigator", run = "cp -L ./*.py ~/.config/kitty", opt = true },
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
  -- @trial https://github.com/ekickx/clipboard-image.nvim
  -- @trial https://github.com/preservim/vim-wordy
  -- @trial https://github.com/jghauser/follow-md-links.nvim
  -- @trial https://github.com/jakewvincent/mkdnflow.nvim
  -- @trial https://github.com/jubnzv/mdeval.nvim
  { "mickael-menu/zk-nvim" },
  "tpope/vim-rails",
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
  "skwp/vim-html-escape",
  "pedrohdz/vim-yaml-folds",
  "avakhov/vim-yaml",
  "chr4/nginx.vim",
  "nanotee/luv-vimdocs",
  "fladson/vim-kitty",
  "SirJson/fzf-gitignore",

  -- TODO: work tings;
  "outstand/logger.nvim",
  -- @trial "outstand/titan.nvim",
  -- @trial "ryansch/habitats.nvim",
}

local M = {
  packages = PKGS,
}

M.sync_all = function()
  (require("paq"))(PKGS):sync()
end

M.list = function()
  (require("paq"))(PKGS).list()
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

-- [ plugin config ] -----------------------------------------------------------

M.config = function()
  vim.cmd("packadd cfilter")

  conf("treesitter", { config = "treesitter" })
  conf("telescope", { config = "telescope" })
  conf("cmp", { config = "cmp" })
  conf("luasnip", { config = "luasnip" })
  conf("gitsigns", { config = "gitsigns" })
  conf("projectionist", { config = "projectionist" })
  conf("toggleterm", { config = "toggleterm" })
  conf("vim_test", { config = "vim_test", silent = true })
  conf("zk", { config = "zk" })
  conf("vscode", { config = "vscode" })

  conf("nvim-web-devicons", {})

  conf("startuptime", {
    config = function()
      vim.g.startuptime_tries = 15
    end,
  })

  conf("bullets.vim", {
    config = function()
      vim.g.bullets_enabled_file_types = {
        "markdown",
        "text",
        "gitcommit",
        "scratch",
      }
      vim.g.bullets_checkbox_markers = " ○◐✗"
      vim.g.bullets_set_mappings = 0
      -- vim.g.bullets_outline_levels = { "num" }

      vim.cmd([[
        " Disable default bullets.vim mappings, clashes with other mappings
        let g:bullets_set_mappings = 0
        " let g:bullets_checkbox_markers = '✗○◐●✓'
        let g:bullets_checkbox_markers = ' .oOx'

        " Add custom bullets mappings that don't clash with other mappings
        function! InsertNewBullet()
          InsertNewBullet
          return ''
        endfunction

          " \ inoremap <buffer><expr> <cr> (pumvisible() ? '<C-y>' : '<C-]><C-R>=InsertNewBullet()<cr>')|
        autocmd FileType markdown,text,gitcommit
          \ nnoremap <buffer> o :InsertNewBullet<cr>|
          \ nnoremap cx :ToggleCheckbox<cr>
          \ nmap <C-x> :ToggleCheckbox<cr>
      ]])
    end,
  })

  -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L815-L832
  conf("gitlinker", {})

  conf("vim-gh-line", {
    config = function()
      if fn.exists("g:loaded_gh_line") then
        vim.g["gh_line_map_default"] = 0
        vim.g["gh_line_blame_map_default"] = 0
        vim.g["gh_line_map"] = "<leader>gH"
        vim.g["gh_line_blame_map"] = "<leader>gB"
        vim.g["gh_repo_map"] = "<leader>gO"

        -- Use a custom program to open link:
        -- let g:gh_open_command = 'open '
        -- Copy link to a clipboard instead of opening a browser:
        -- let g:gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '
      end
    end,
  })

  conf("fidget", {
    config = {
      text = {
        spinner = "dots_pulse",
        done = "",
      },
      window = {
        blend = 10,
      },
      sources = { -- Sources to configure
        ["elixirls"] = { -- Name of source
          ignore = false, -- Ignore notifications from this source
        },
      },
    },
  })

  conf("lsp_signature", {
    config = {
      bind = true,
      fix_pos = false,
      auto_close_after = 3,
      hint_enable = false,
      handler_opts = { border = mega.get_border() },
      zindex = 99, -- Keep signature popup below the completion PUM
      --   hi_parameter = "QuickFixLine",
      --   handler_opts = {
      --     border = vim.g.floating_window_border,
      --   },
    },
  })

  conf("git-conflict", {
    config = {
      disable_diagnostics = true,
      highlights = {
        incoming = "DiffText",
        current = "DiffAdd",
      },
    },
  })

  conf("vim-matchup", {
    config = function()
      vim.g.matchup_surround_enabled = true
      vim.g.matchup_matchparen_deferred = true
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
        fullwidth = true,
        highlight = "Normal",
        border = "shadow",
      }
    end,
  })

  conf("mini.indentscope", {
    config = {
      symbol = "▏", -- │ ▏
      draw = {
        delay = 50,
      },

      -- draw = {
      --   delay = 50,
      --   animation = require("mini.indentscope").gen_animation("none"),
      -- },
      -- options = {
      --   indent_at_cursor = false,
      -- },
      -- symbol = "▏",
    },
  })

  conf("hclipboard", {
    config = function(p)
      if p == nil then
        return
      end

      p.start()
    end,
  })

  conf("cinnamon", {
    config = {
      extra_keymaps = true,
    },
  })

  conf("neoscroll", {
    config = function(plug)
      if plug == nil then
        return
      end

      local mappings = {}
      plug.setup({
        stop_eof = true,
        hide_cursor = true,
        easing_function = "circular",
      })

      mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } }
      mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } }
      mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "250" } }
      mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "250" } }
      mappings["<C-y>"] = { "scroll", { "-0.10", "false", "80" } }
      mappings["<C-e>"] = { "scroll", { "0.10", "false", "80" } }
      mappings["zt"] = { "zt", { "150" } }
      -- mappings["zz"] = { "zz", { "0" } }
      mappings["zb"] = { "zb", { "150" } }

      require("neoscroll.config").set_mappings(mappings)
    end,
    enabled = false,
  })

  conf("FixCursorHold", {
    config = function()
      -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
      vim.g.cursorhold_updatetime = 100
    end,
  })

  conf("Comment", {
    config = {
      ignore = "^$",
      pre_hook = function(ctx)
        local U = require("Comment.utils")

        local location = nil
        if ctx.ctype == U.ctype.block then
          location = require("ts_context_commentstring.utils").get_cursor_location()
        elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
          location = require("ts_context_commentstring.utils").get_visual_start_location()
        end

        return require("ts_context_commentstring.internal").calculate_commentstring({
          key = ctx.ctype == U.ctype.line and "__default" or "__multiline",
          location = location,
        })
      end,
    },
  })

  conf("colorizer", { config = { "*" }, {
    mode = "background",
  } })

  conf("virt-column", { config = { char = "│" } })

  conf("golden_size", {
    config = function(plug)
      if plug == nil then
        return
      end

      local function ignore_by_buftype(types)
        local bt = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
        for _, type in pairs(types) do
          if type == bt then
            return 1
          end
        end
      end
      local function ignore_by_filetype(types)
        local ft = api.nvim_buf_get_option(api.nvim_get_current_buf(), "filetype")
        for _, type in pairs(types) do
          if type == ft then
            return 1
          end
        end
      end

      plug.set_ignore_callbacks({
        {
          ignore_by_filetype,
          {
            "help",
            "toggleterm",
            "terminal",
            "megaterm",
            "DirBuf",
            "Trouble",
            "qf",
          },
          ignore_by_buftype,
          {
            "help",
            "acwrite",
            "Undotree",
            "quickfix",
            "nerdtree",
            "current",
            "Vista",
            "Trouble",
            "LuaTree",
            "NvimTree",
            "terminal",
            "DirBuf",
            "tsplayground",
          },
        },
        { plug.ignore_float_windows }, -- default one, ignore float windows
        { plug.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
      })
    end,
  })

  conf("nvim-autopairs", {
    config = function(p)
      if p == nil then
        return
      end

      p.setup({
        disable_filetype = { "TelescopePrompt" },
        -- enable_afterquote = true, -- To use bracket pairs inside quotes
        enable_check_bracket_line = true, -- Check for closing brace so it will not add a close pair
        disable_in_macro = false,
        close_triple_quotes = true,
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          java = false,
        },
      })
      p.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
      local endwise = require("nvim-autopairs.ts-rule").endwise
      p.add_rules({
        endwise("then$", "end", "lua", nil),
        endwise("do$", "end", "lua", nil),
        endwise("function%(.*%)$", "end", "lua", nil),
        endwise(" do$", "end", "elixir", nil),
      })
      -- REF: neat stuff:
      -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
    end,
  })

  conf("lightspeed", {
    enabled = true,
    config = {
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
    },
  })

  conf("hop", {
    enabled = false,
    config = function(p)
      if p == nil then
        return
      end

      p.setup({
        -- remove h,j,k,l from hops list of keys
        keys = "etovxqpdygfbzcisuran",
        jump_on_sole_occurrence = true,
        uppercase_labels = false,
      })

      nnoremap("s", function()
        p.hint_char1({ multi_windows = false })
      end)
      -- NOTE: override F/f using hop motions
      vim.keymap.set({ "x", "n" }, "F", function()
        p.hint_char1({
          direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
          current_line_only = true,
          inclusive_jump = false,
        })
      end)
      vim.keymap.set({ "x", "n" }, "f", function()
        p.hint_char1({
          direction = require("hop.hint").HintDirection.AFTER_CURSOR,
          current_line_only = true,
          inclusive_jump = false,
        })
      end)
      onoremap("F", function()
        p.hint_char1({
          direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
          current_line_only = true,
          inclusive_jump = true,
        })
      end)
      onoremap("f", function()
        p.hint_char1({
          direction = require("hop.hint").HintDirection.AFTER_CURSOR,
          current_line_only = true,
          inclusive_jump = true,
        })
      end)
    end,
  })

  conf("git-messenger", function()
    vim.g.git_messenger_floating_win_opts = { border = mega.get_border() }
    vim.g.git_messenger_no_default_mappings = true
    vim.g.git_messenger_max_popup_width = 100
    vim.g.git_messenger_max_popup_height = 100
  end)

  do -- firenvim
    -- REFS:
    -- * https://github.com/cgardner/dotfiles-bare/blob/master/.config/nvim/lua/plugins/firenvim.lua#L3-L9
    vim.g.firenvim_config = {
      globalSettings = {
        alt = "all",
      },
      localSettings = {
        [".*"] = {
          cmdline = "neovim",
          content = "text",
          priority = 0,
          selector = "textarea",
          takeover = "never", -- disable until called with firefox hotkey <C-e>
        },
      },
    }

    if vim.g.started_by_firenvim then
      print("hi from started by firenvim")

      vim.opt.cmdheight = 1
      -- selene: allow(global_usage)
      function _G.set_firenvim_settings()
        local min_lines = 18
        if vim.opt.lines < min_lines then
          vim.opt.lines = min_lines
        end

        vim.opt.guifont = [[Jetbrains Nerd Font:h13]]
        vim.opt.wrap = true
        vim.opt.number = false
        vim.opt.relativenumber = false
        vim.opt.signcolumn = "no"
        vim.opt.list = true
        vim.opt.linebreak = true
        vim.opt.breakindentopt = true
        vim.opt.colorcolumn = 0
        vim.cmd("startinsert")
      end

      vim.cmd([[
          function! OnUIEnter(event) abort
            if 'Firenvim' ==# get(get(nvim_get_chan_info(a:event.chan), 'client', {}), 'name', '')
              echom "hi!"
              lua _G.set_firenvim_settings()
            endif
          endfunction
          autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
          au BufEnter github.com_*.txt,gitlab.com_*.txt,mattermost.*.txt,mail.google.com_*.txt set filetype=markdown
          au BufEnter mail.google.com_*.txt set tw=80
        ]])
    end
  end

  conf("dap", {
    config = function(p)
      if p == nil then
        return
      end

      p.adapters.mix_task = {
        type = "executable",
        command = fn.stdpath("data") .. "/elixir-ls/debugger.sh",
        args = {},
      }
      p.configurations.elixir = {
        {
          type = "mix_task",
          name = "mix test",
          task = "test",
          taskArgs = { "--trace" },
          request = "launch",
          startApps = true, -- for Phoenix projects
          projectDir = "${workspaceFolder}",
          requireFiles = {
            "test/**/test_helper.exs",
            "test/**/*_test.exs",
          },
        },
      }
    end,
  })

  conf("numb", {})

  conf("bufdel", {
    config = {
      next = "cycle", -- or 'alternate'
      quit = true,
    },
  })

  conf("tabout", { config = {
    completion = false,
    ignore_beginning = false,
    enabled = false,
  } })

  conf("headlines", {
    config = {
      markdown = {
        source_pattern_start = "^```",
        source_pattern_end = "^```$",
        dash_pattern = "^---+$",
        dash_highlight = "Dash",
        dash_string = "―",
        headline_pattern = "^#+",
        headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
        codeblock_highlight = "CodeBlock",
      },
      yaml = {
        dash_pattern = "^---+$",
        dash_highlight = "Dash",
      },
    },
  })

  conf("dirbuf", {
    config = {
      hash_padding = 2,
      show_hidden = true,
      sort_order = "directories_first",
    },
  })

  conf("bqf", {
    config = function(plug)
      if plug == nil then
        return
      end

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

      plug.setup({
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
            local ret = true
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

  -- using this primarily with the winbar
  conf("nvim-gps", {
    config = function(plug)
      if plug == nil then
        return
      end

      local icons = mega.icons.codicons
      local types = mega.icons.type
      plug.setup({
        languages = {
          heex = false,
          elixir = false,
          eelixir = false,
        },
        enabled = true,
        icons = {
          ["class-name"] = icons.Class,
          ["function-name"] = icons.Function,
          ["method-name"] = icons.Method,
          ["container-name"] = icons.Module,
          ["tag-name"] = icons.Field,
          ["array-name"] = icons.Value,
          ["object-name"] = icons.Value,
          ["null-name"] = icons.Null,
          ["boolean-name"] = icons.Keyword,
          ["number-name"] = icons.Value,
          ["string-name"] = icons.Text,
          ["mapping-name"] = types.object,
          ["sequence-name"] = types.array,
          ["integer-name"] = types.number,
          ["float-name"] = types.float,
        },
      })
    end,
  })

  conf("pqf", {})

  conf("regexplainer", {})

  conf("dd", { config = {
    enabled = false,
    timeout = 500,
  } })

  conf("fzf_gitignore", {
    config = function()
      vim.g.fzf_gitignore_no_maps = true
    end,
  })

  conf("treesitter-context", { enabled = false })

  conf("vim-kitty-navigator", { enabled = not vim.env.TMUX })

  conf("other-nvim", {
    enabled = false,
    config = {
      mappings = {
        {
          pattern = "/(.*)/live/*.ex$",
          target = "/%1/live/%2.html.heex",
        },
        {
          pattern = "/(.*)/live/*.html.heex$",
          target = "/%1/live/%2.ex",
        },

        -- {
        --   pattern = "/src/app/(.*)/.*.ts$",
        --   target = "/src/app/%1/%1.component.html",
        -- },
        -- {
        --   pattern = "/src/app/(.*)/.*.html$",
        --   target = "/src/app/%1/%1.component.ts",
        -- },
      },
      -- transformers = {
      --   -- defining a custom transformer
      --   lowercase = function(inputString)
      --     return inputString:lower()
      --   end,
      -- },
    },
  })
end

return M
