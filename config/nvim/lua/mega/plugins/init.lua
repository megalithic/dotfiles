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
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  "folke/which-key.nvim",
  "rcarriga/nvim-notify",
  "echasnovski/mini.nvim",
  "kevinhwang91/promise-async",
  "kevinhwang91/nvim-ufo",

  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
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
  { "nvim-treesitter/nvim-treesitter-context" },
  "SmiteshP/nvim-gps",
  -- @trial "m-demare/hlargs.nvim"
  -- @trial "ziontee113/syntax-tree-surfer"

  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  { "ggandor/lightspeed.nvim", opt = true },
  { "phaazon/hop.nvim", opt = true },
  "akinsho/toggleterm.nvim",
  -- "elihunter173/dirbuf.nvim",
  "nvim-neo-tree/neo-tree.nvim",

  { "nvim-telescope/telescope.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "camgraff/telescope-tmux.nvim",
  "nvim-telescope/telescope-media-files.nvim",
  "nvim-telescope/telescope-symbols.nvim",
  "nvim-telescope/telescope-smart-history.nvim",
  -- @trial "AckslD/nvim-neoclip.lua", -- https://github.com/akinsho/dotfiles/blob/nightly/.config/nvim/lua/as/plugins/init.lua#L351-L367
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
  "rcarriga/neotest",
  "rcarriga/neotest-plenary",
  "rcarriga/neotest-vim-test",
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "rcarriga/nvim-dap-ui",
  "theHamsta/nvim-dap-virtual-text",
  "jbyuki/one-small-step-for-vimkind",
  "tpope/vim-ragtag",
  -- @trial { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  "mbbill/undotree",
  "danymat/neogen",

  ------------------------------------------------------------------------------
  -- (the rest...) --
  "nacro90/numb.nvim",
  "andymass/vim-matchup",
  "windwp/nvim-autopairs",
  "alvan/vim-closetag",
  "numToStr/Comment.nvim",
  -- "tpope/vim-abolish",
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
  { "knubie/vim-kitty-navigator", run = "cp -L ./*.py ~/.config/kitty", opt = true },
  "RRethy/nvim-align",

  ------------------------------------------------------------------------------
  -- (LANGS, syntax, et al) --
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
  -- "renerocksai/telekasten.nvim",
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

function M.sync_all()
  (require("paq"))(PKGS):sync()
end

function M.list()
  (require("paq"))(PKGS).list()
end

-- `bin/paq-install` runs this for us in a headless nvim environment
function M.bootstrap()
  clone_paq()

  -- Load Paq
  vim.cmd("packadd paq-nvim")
  local paq = require("paq")

  -- Exit nvim after installing plugins
  vim.cmd("autocmd User PaqDoneInstall quit")

  -- Read and install packages
  paq(PKGS):install()

  --- Check if a directory exists in this path
  local function is_dir(path)
    -- check if file exists
    local function file_exists(file)
      local ok, err, code = os.rename(file, file)
      if not ok then
        if code == 13 then
          -- Permission denied, but it exists
          return true
        end
      end
      return ok, err
    end

    -- "/" works on both Unix and Windows
    return file_exists(path .. "/")
  end

  -- setup vim's various config directories
  -- # cache_paths
  if vim.g.local_state_path ~= nil then
    local local_state_paths = {
      fmt("%s/backup", vim.g.local_state_path),
      fmt("%s/session", vim.g.local_state_path),
      fmt("%s/swap", vim.g.local_state_path),
      fmt("%s/shada", vim.g.local_state_path),
      fmt("%s/tags", vim.g.local_state_path),
      fmt("%s/undo", vim.g.local_state_path),
    }
    if not is_dir(vim.g.local_state_path) then
      os.execute("mkdir -p " .. vim.g.local_state_path)
    end
    for _, p in pairs(local_state_paths) do
      if not is_dir(p) then
        os.execute("mkdir -p " .. p)
      end
    end
  end
end

-- [ plugin config ] -----------------------------------------------------------

function M.config()
  if pcall(require, "paq") then
    vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/packer")
  end

  vim.cmd("packadd cfilter")

  -- conf("whichkey", { config = "whichkey" })
  -- conf("hydra", { config = "hydra" })
  conf("gitsigns", { config = "gitsigns" })
  conf("telescope", { config = "telescope" })
  conf("neo-tree", { config = "neo-tree" })
  conf("cmp", { config = "cmp" })
  conf("luasnip", { config = "luasnip" })
  conf("projectionist", { config = "projectionist" })
  conf("toggleterm", { config = "toggleterm" })
  conf("vim-test", { config = "vim-test" })
  conf("neotest", { config = "neotest" })
  conf("mini", { config = "mini" })
  conf("zk", { config = "zk" })
  -- conf("telekasten", { config = "telekasten" })
  conf("vscode", { config = "vscode" })
  conf("nvim-web-devicons", {})

  conf("startuptime", {
    function()
      vim.g.startuptime_tries = 15
    end,
  })

  conf("bullets.vim", function()
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
          \ nnoremap <silent><buffer> o :InsertNewBullet<cr>|
          \ nnoremap cx :ToggleCheckbox<cr>
          \ nmap <C-x> :ToggleCheckbox<cr>
      ]])
  end)

  conf("ufo", function()
    local handler = function(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local suffix = (" %s  %d "):format(mega.icons.misc.ellipsis, endLnum - lnum)
      local sufWidth = vim.fn.strdisplaywidth(suffix)
      local targetWidth = width - sufWidth
      local curWidth = 0
      for _, chunk in ipairs(virtText) do
        local chunkText = chunk[1]
        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
        if targetWidth > curWidth + chunkWidth then
          table.insert(newVirtText, chunk)
        else
          chunkText = truncate(chunkText, targetWidth - curWidth)
          local hlGroup = chunk[2]
          table.insert(newVirtText, { chunkText, hlGroup })
          chunkWidth = vim.fn.strdisplaywidth(chunkText)
          -- str width returned from truncate() may less than 2rd argument, need padding
          if curWidth + chunkWidth < targetWidth then
            suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
          end
          break
        end
        curWidth = curWidth + chunkWidth
      end
      table.insert(newVirtText, { suffix, "FoldMoreMsg" })
      return newVirtText
    end

    require("ufo").setup({
      fold_virt_text_handler = handler,
    })

    -- map("n", "[z", require("ufo.action").goPreviousClosedFold)
    -- map("n", "]z", require("ufo.action").goNextClosedFold)
  end)

  -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L815-L832
  conf("gitlinker", {})

  conf("vim-gh-line", function()
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
  end)

  conf("fidget", {
    text = {
      spinner = "dots_pulse",
      done = "",
    },
    window = {
      blend = 10,
      -- relative = "editor",
    },
    sources = { -- Sources to configure
      ["elixirls"] = { -- Name of source
        ignore = true, -- Ignore notifications from this source
      },
      ["markdown"] = { -- Name of source
        ignore = true, -- Ignore notifications from this source
      },
    },
  })

  conf("lsp_signature", {
    bind = true,
    fix_pos = false,
    auto_close_after = 5,
    hint_enable = false,
    handler_opts = {
      anchor = "SW",
      relative = "cursor",
      row = -1,
      focus = false,
      border = mega.get_border(),
    },
    zindex = 99, -- Keep signature popup below the completion PUM
    toggle_key = "<C-k>",
    --   hi_parameter = "QuickFixLine",
  })

  conf("git-conflict", {
    disable_diagnostics = true,
    highlights = {
      incoming = "DiffText",
      current = "DiffAdd",
      ancestor = "DiffBase",
    },
  })

  conf("vim-matchup", function()
    vim.g.matchup_surround_enabled = true
    vim.g.matchup_matchparen_deferred = true
    vim.g.matchup_matchparen_offscreen = {
      method = "popup",
      fullwidth = true,
      highlight = "Normal",
      border = "shadow",
    }
  end)

  conf("hclipboard", function()
    require("hclipboard").start()
  end)

  conf("FixCursorHold", function()
    -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
    vim.g.cursorhold_updatetime = 100
  end)

  conf("Comment", {
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
  })

  conf("colorizer", function()
    require("colorizer").setup({ "*" }, {
      RGB = true, -- #RGB hex codes
      RRGGBB = true, -- #RRGGBB hex codes
      names = true, -- "Name" codes like Blue
      RRGGBBAA = true, -- #RRGGBBAA hex codes
      rgb_fn = true, -- CSS rgb() and rgba() functions
      hsl_fn = true, -- CSS hsl() and hsla() functions
      css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
      mode = "background",
    })
  end)

  conf("golden_size", function()
    local gs = require("golden_size")

    -- local function ignore_by(type, types)
    --   local t = api.nvim_buf_get_option(api.nvim_get_current_buf(), type)
    --   for _, type in pairs(types) do
    --     if type == t then
    --       return 1
    --     end
    --   end
    -- end

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

    gs.set_ignore_callbacks({
      -- {
      --   ignore_by,
      --   "filetype",
      --   {
      --     "help",
      --     "toggleterm",
      --     "terminal",
      --     "megaterm",
      --     "dirbuf",
      --     "Trouble",
      --     "qf",
      --     "neo-tree",
      --   },
      -- },
      {
        ignore_by_filetype,
        {
          "help",
          "toggleterm",
          "terminal",
          "megaterm",
          "dirbuf",
          "Trouble",
          "qf",
          "neo-tree",
        },
      },
      {
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
          "dirbuf",
          "tsplayground",
          "neo-tree",
        },
      },
      { gs.ignore_float_windows }, -- default one, ignore float windows
      { gs.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
    })
  end)

  conf("nvim-autopairs", function()
    require("nvim-autopairs").setup({
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
    require("nvim-autopairs").add_rules(require("nvim-autopairs.rules.endwise-ruby"))
    local endwise = require("nvim-autopairs.ts-rule").endwise
    require("nvim-autopairs").add_rules({
      endwise("then$", "end", "lua", nil),
      endwise("do$", "end", "lua", nil),
      endwise("function%(.*%)$", "end", "lua", nil),
      endwise(" do$", "end", "elixir", nil),
    })

    require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
    -- REF: neat stuff:
    -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
  end)

  conf("lightspeed", {
    enabled = false,
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

  conf("hop", {
    enabled = false,
    config = function()
      local p = require("hop")

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

  conf("numb", {})

  conf("bufdel", {
    next = "cycle", -- alts: 'alternate'
    quit = true,
  })

  conf("headlines", {
    markdown = {
      source_pattern_start = "^```",
      source_pattern_end = "^```$",
      dash_pattern = "^---+$",
      dash_highlight = "Dash",
      dash_string = "", -- alts:  靖並   ﮆ 
      headline_pattern = "^#+",
      headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
      codeblock_highlight = "CodeBlock",
    },
    yaml = {
      dash_pattern = "^---+$",
      dash_highlight = "Dash",
    },
  })

  conf("dirbuf", {
    hash_padding = 2,
    show_hidden = true,
    sort_order = "directories_first",
  })

  conf("bqf", function()
    local bqf = require("bqf")

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

    bqf.setup({
      auto_enable = true,
      auto_resize_height = true,
      preview = {
        auto_preview = true,
        win_height = 15,
        win_vheight = 15,
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
  end)

  -- using this primarily with the winbar
  conf("nvim-gps", function()
    local plug = require("nvim-gps")

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
  end)

  conf("pqf", {})

  conf("dd", {
    enabled = false,
    timeout = 500,
  })

  conf("fzf_gitignore", function()
    vim.g.fzf_gitignore_no_maps = true
  end)

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

  conf("neogen", function()
    require("neogen").setup({ snippet_engine = "luasnip" })
    mega.nnoremap("<localleader>cg", require("neogen").generate, "comment: generate")
  end)

  conf("undotree", function()
    mega.nnoremap("<leader>u", "<cmd>UndotreeToggle<CR>", "undotree: toggle")
    vim.g.undotree_TreeNodeShape = "◦" -- alts: '◉'
    vim.g.undotree_SetFocusWhenToggle = 1
  end)
end

return M
