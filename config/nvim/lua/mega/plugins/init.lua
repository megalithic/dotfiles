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
  "NvChad/nvim-colorizer.lua",
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  "folke/which-key.nvim",
  { "echasnovski/mini.nvim" },
  "jghauser/fold-cycle.nvim",
  "anuvyklack/hydra.nvim",
  "rcarriga/nvim-notify",

  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  { "hrsh7th/nvim-cmp", branch = "main" },
  "hrsh7th/cmp-nvim-lsp",
  -- "hrsh7th/cmp-nvim-lua",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-cmdline",
  "dmitmel/cmp-cmdline-history",
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
  -- "j-hui/fidget.nvim",
  "ZenLian/fidget.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  { "kevinhwang91/nvim-bqf" },
  { url = "https://gitlab.com/yorickpeterse/nvim-pqf" },
  "mhartington/formatter.nvim",
  "antoinemadec/FixCursorHold.nvim", -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
  "ojroques/nvim-bufdel",
  "abecodes/tabout.nvim",

  ------------------------------------------------------------------------------
  -- (treesitter) --
  {
    "nvim-treesitter/nvim-treesitter",
    run = function() vim.cmd("TSUpdate") end,
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
  "lewis6991/spellsitter.nvim",

  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  "nvim-neo-tree/neo-tree.nvim",
  { "nvim-telescope/telescope.nvim" },
  { "nvim-telescope/telescope-fzf-native.nvim", run = "make" },
  "natecraddock/telescope-zf-native.nvim",
  "camgraff/telescope-tmux.nvim",
  "nvim-telescope/telescope-live-grep-args.nvim",

  ------------------------------------------------------------------------------
  -- (text objects) --

  -- "tpope/vim-rsi",
  -- "kana/vim-textobj-user",
  -- "kana/vim-operator-user",
  -- "kana/vim-textobj-entire", -- ae/ie for entire buffer
  -- "michaeljsmith/vim-indent-object", -- ai/ii for indentation area
  -- "wellle/targets.vim",

  ------------------------------------------------------------------------------
  -- (GIT, vcs, et al) --
  -- {"keith/gist.vim", run = "chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "TimUntersberger/neogit",
  "mattn/webapi-vim",
  "akinsho/git-conflict.nvim",
  "itchyny/vim-gitbranch",
  "rhysd/git-messenger.vim",
  "tpope/vim-fugitive",
  "lewis6991/gitsigns.nvim",
  { "ruifm/gitlinker.nvim" },
  { "ruanyl/vim-gh-line" },

  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  -- "rgroli/other.nvim",
  -- "glepnir/template.nvim",
  "tpope/vim-projectionist",
  -- @trial "tjdevries/edit_alternate.vim", -- REF: https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/lua/tj/plugins.lua#L467-L480
  "vim-test/vim-test",
  -- "rcarriga/neotest",
  -- "rcarriga/neotest-plenary",
  -- "rcarriga/neotest-vim-test",
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "rcarriga/nvim-dap-ui",
  "theHamsta/nvim-dap-virtual-text",
  "jbyuki/one-small-step-for-vimkind",
  "tpope/vim-ragtag",
  -- @trial { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  -- "mbbill/undotree",
  "danymat/neogen",

  ------------------------------------------------------------------------------
  -- (the rest...) --
  "nacro90/numb.nvim",
  "andymass/vim-matchup",
  "windwp/nvim-autopairs",
  "alvan/vim-closetag",
  { "numToStr/Comment.nvim" },
  -- "tpope/vim-abolish",
  "tpope/vim-eunuch",
  "tpope/vim-abolish",
  "tpope/vim-rhubarb",
  "tpope/vim-repeat",
  -- "tpope/vim-surround",
  "tpope/vim-unimpaired",
  "tpope/vim-apathy",
  "kylechui/nvim-surround",
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
  "junegunn/vim-easy-align",

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
  "elixir-editors/vim-elixir",
  "tpope/vim-rails",
  "ngscheurich/edeex.nvim",
  "antew/vim-elm-analyse",
  "tjdevries/nlua.nvim",
  "norcalli/nvim.lua",
  "euclidianace/betterlua.vim",
  "folke/lua-dev.nvim",
  "andrejlevkovitch/vim-lua-format",
  "milisims/nvim-luaref",
  "ii14/emmylua-nvim",
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

function M.sync_all() (require("paq"))(PKGS):sync() end

function M.list() (require("paq"))(PKGS).list() end

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
    if not is_dir(vim.g.local_state_path) then os.execute("mkdir -p " .. vim.g.local_state_path) end
    for _, p in pairs(local_state_paths) do
      if not is_dir(p) then os.execute("mkdir -p " .. p) end
    end
  end
end

-- [ plugin configs ] -----------------------------------------------------------

function M.config()
  if pcall(require, "paq") then vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/packer") end

  vim.cmd("packadd cfilter")

  conf("gitsigns", { config = "gitsigns" })
  conf("telescope", { config = "telescope" })
  conf("neo-tree", { config = "neo-tree" })
  conf("cmp", { config = "cmp" })
  conf("luasnip", { config = "luasnip" })
  conf("projectionist", { config = "projectionist" })
  conf("vim-test", { config = "vim-test" })
  conf("mini", { config = "mini" })
  conf("zk", { config = "zk" })
  conf("dap", { config = "dap" })
  conf("dapui", { config = "dapui" })
  conf("hydra", { config = "hydra" })

  conf("nvim-web-devicons", {})
  conf("nvim-surround", {
    highlight = { -- Highlight before inserting/changing surrounds
      duration = 1,
    },
  })

  conf("startuptime", function() vim.g.startuptime_tries = 15 end)

  conf("Comment", {
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

  conf("colorizer", function()
    require("colorizer").setup({ "*" }, {
      RGB = true, -- #RGB hex codes
      RRGGBB = true, -- #RRGGBB hex codes
      names = false, -- "Name" codes like Blue
      RRGGBBAA = true, -- #RRGGBBAA hex codes
      rgb_fn = true, -- CSS rgb() and rgba() functions
      hsl_fn = true, -- CSS hsl() and hsla() functions
      css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
      css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
      mode = "virtualtext",
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
        if type == bt then return 1 end
      end
    end

    local function ignore_by_filetype(types)
      local ft = api.nvim_buf_get_option(api.nvim_get_current_buf(), "filetype")
      for _, type in pairs(types) do
        if type == ft then return 1 end
      end
    end

    gs.set_ignore_callbacks({
      {
        ignore_by_filetype,
        {
          "help",
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
      endwise("do$", "end", "lua", nil),
      endwise("then$", "end", "lua", "if_statement"),
      endwise("function%(.*%)$", "end", "lua", nil),
      endwise(" do$", "end", "elixir", nil),
    })

    require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
    -- REF: neat stuff:
    -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
  end)

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

  -- FIXME: breaks mini.nvim#jump
  -- conf("fidget", {
  --   text = {
  --     spinner = "dots_pulse",
  --     done = "",
  --   },
  --   window = {
  --     blend = 10,
  --     -- relative = "editor",
  --   },
  --   sources = { -- Sources to configure
  --     ["elixirls"] = { -- Name of source
  --       ignore = true, -- Ignore notifications from this source
  --     },
  --     ["markdown"] = { -- Name of source
  --       ignore = true, -- Ignore notifications from this source
  --     },
  --   },
  -- })

  -- FIXME:
  --Error executing vim.schedule lua callback: /usr/local/share/nvim/runtime/lua/vim/lsp/util.lua:1569: Window was closed immediately
  -- stack traceback:
  --         [C]: in function 'nvim_open_win'
  --         /usr/local/share/nvim/runtime/lua/vim/lsp/util.lua:1569: in function 'open_floating_preview'
  --         ...paqs/start/lsp_signature.nvim/lua/lsp_signature/init.lua:471: in function 'handler'
  --         /usr/local/share/nvim/runtime/lua/vim/lsp.lua:1241: in function ''
  --         vim/_editor.lua: in function <vim/_editor.lua:0>
  conf("lsp_signature", {
    enable = false,
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

  conf("git-conflict", {
    disable_diagnostics = true,
    highlights = {
      incoming = "DiffText",
      current = "DiffAdd",
      ancestor = "DiffBase",
    },
  })

  conf("FixCursorHold", function()
    -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
    vim.g.cursorhold_updatetime = 100
  end)

  -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L815-L832
  conf("gitlinker", {})

  conf("vim-easy-align", function()
    -- n : interactive EasyAlign for a motion/text object (e.g. gaip)
    -- x : interactive EasyAlign in visual mode (e.g. vipga)
    nmap("<leader>ga", "<Plug>(EasyAlign)", "align things")
    xmap("<leader>ga", "<Plug>(EasyAlign)", "align things")
  end)

  conf("tabout", {
    ignore_beginning = false,
    completion = false,
  })

  conf("neogit", function()
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
  end)

  conf("fold-cycle", {})

  conf("pqf", {})

  conf("hclipboard", function() require("hclipboard").start() end)

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

  conf("fzf_gitignore", function() vim.g.fzf_gitignore_no_maps = true end)
  conf("vim-kitty-navigator", { enabled = not vim.env.TMUX })

  conf("neogen", function()
    require("neogen").setup({ snippet_engine = "luasnip" })
    mega.nnoremap("<localleader>cg", require("neogen").generate, "comment: generate")
  end)

  conf("notify", {
    timeout = 3000,
    stages = "slide",
    background_colour = "NotifyFloat",
    max_width = function() return math.floor(vim.o.columns * 0.8) end,
    max_height = function() return math.floor(vim.o.lines * 0.8) end,
    on_open = function(win)
      if api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_config(win, { border = mega.get_border("NotifyFloat") })
      end
    end,
    render = function(...)
      local notif = select(2, ...)
      local style = notif.title[1] == "" and "minimal" or "default"
      require("notify.render")[style](...)
    end,
  })
end

return M
