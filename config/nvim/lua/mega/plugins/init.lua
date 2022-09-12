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
  -- (UI/appearance/visuals) --
  "rktjmp/lush.nvim",
  "NvChad/nvim-colorizer.lua",
  "dm1try/golden_size",
  "kyazdani42/nvim-web-devicons",
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  "folke/which-key.nvim",
  -- "echasnovski/mini.nvim",
  "phaazon/hop.nvim",
  -- "ggandor/leap-ast.nvim",
  -- "ggandor/leap.nvim",
  -- "ggandor/flit.nvim",
  "jghauser/fold-cycle.nvim",
  "anuvyklack/hydra.nvim",
  "rcarriga/nvim-notify",
  "nanozuki/tabby.nvim",
  "levouh/tint.nvim",
  "lukas-reineke/indent-blankline.nvim",
  ------------------------------------------------------------------------------
  -- (LSP/completion) --
  "neovim/nvim-lspconfig",
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  { "hrsh7th/nvim-cmp", branch = "main" },
  "hrsh7th/cmp-nvim-lsp",
  "saadparwaiz1/cmp_luasnip",
  "hrsh7th/cmp-cmdline",
  "dmitmel/cmp-cmdline-history",
  "hrsh7th/cmp-buffer",
  "hrsh7th/cmp-path",
  "hrsh7th/cmp-emoji",
  "f3fora/cmp-spell",
  "hrsh7th/cmp-nvim-lsp-document-symbol",
  "hrsh7th/cmp-nvim-lsp-signature-help",
  "rcarriga/cmp-dap",
  "L3MON4D3/LuaSnip",
  "rafamadriz/friendly-snippets",
  "ray-x/lsp_signature.nvim",
  "lewis6991/hover.nvim",
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/nvim-lsp-ts-utils",
  "jose-elias-alvarez/null-ls.nvim",
  "b0o/schemastore.nvim",
  { "kevinhwang91/nvim-bqf" },
  { url = "https://gitlab.com/yorickpeterse/nvim-pqf" },
  "antoinemadec/FixCursorHold.nvim", -- Needed while issue https://github.com/neovim/neovim/issues/12587 is still open
  "ojroques/nvim-bufdel",
  "abecodes/tabout.nvim",
  "mhartington/formatter.nvim",
  "mrshmllow/document-color.nvim",
  ------------------------------------------------------------------------------
  -- (TS/treesitter) --
  {
    "nvim-treesitter/nvim-treesitter",
    run = function() vim.cmd("TSUpdate") end,
  },
  "nvim-treesitter/playground",
  -- "nvim-treesitter/nvim-treesitter-refactor",
  -- "nvim-treesitter/nvim-treesitter-textobjects",
  "JoosepAlviste/nvim-ts-context-commentstring",
  "windwp/nvim-ts-autotag",
  "p00f/nvim-ts-rainbow",
  "mfussenegger/nvim-treehopper",
  "RRethy/nvim-treesitter-textsubjects",
  "David-Kunz/treesitter-unit",
  "nvim-treesitter/nvim-treesitter-context",
  ------------------------------------------------------------------------------
  -- (FZF/telescope/file/document navigation) --
  "nvim-neo-tree/neo-tree.nvim",
  "mrbjarksen/neo-tree-diagnostics.nvim",
  "s1n7ax/nvim-window-picker",
  "nvim-telescope/telescope.nvim",
  "nvim-telescope/telescope-file-browser.nvim",
  "natecraddock/telescope-zf-native.nvim",
  "nvim-telescope/telescope-live-grep-args.nvim",
  "benfowler/telescope-luasnip.nvim",
  -- "windwp/nvim-spectre",
  ------------------------------------------------------------------------------
  -- (GIT) --
  -- {"keith/gist.vim", run = "chmod -HR 0600 ~/.netrc"}, -- TODO: find lua replacement (i don't want python)
  "TimUntersberger/neogit",
  "mattn/webapi-vim",
  "akinsho/git-conflict.nvim",
  "itchyny/vim-gitbranch",
  "tpope/vim-fugitive",
  "lewis6991/gitsigns.nvim",
  "ruifm/gitlinker.nvim",
  "ruanyl/vim-gh-line",
  ------------------------------------------------------------------------------
  -- (DEV, development, et al) --
  -- "rgroli/other.nvim",
  -- "glepnir/template.nvim",
  "tpope/vim-projectionist",
  -- @trial "tjdevries/edit_alternate.vim", -- REF: https://github.com/tjdevries/config_manager/blob/master/xdg_config/nvim/lua/tj/plugins.lua#L467-L480
  "vim-test/vim-test",
  "mfussenegger/nvim-dap", -- REF: https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/lua/dbern/test.lua
  "rcarriga/nvim-dap-ui",
  "theHamsta/nvim-dap-virtual-text",
  "jbyuki/one-small-step-for-vimkind",
  "suketa/nvim-dap-ruby",
  "mxsdev/nvim-dap-vscode-js",
  -- { "microsoft/vscode-js-debug", opt = true, run = "npm install --legacy-peer-deps; npm run-script compile" },
  { "microsoft/vscode-react-native", opt = true },
  -- { "sultanahamer/nvim-dap-reactnative", opt = true },
  "tpope/vim-ragtag",
  -- @trial { "mrjones2014/dash.nvim", run = "make install", opt = true },
  "editorconfig/editorconfig-vim",
  { "zenbro/mirror.vim", opt = true },
  "akinsho/toggleterm.nvim",
  -- "rmagatti/auto-session",
  -- "ahmedkhalf/project.nvim",
  -- "mg979/vim-visual-multi",
  "natecraddock/sessions.nvim",
  "natecraddock/workspaces.nvim",
  "megalithic/habitats.nvim",
  -- "mbbill/undotree",
  -- "danymat/neogen",
  -- "smjonas/live-command.nvim",
  ------------------------------------------------------------------------------
  -- (REST) --
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
  -- "kevinhwang91/nvim-hclipboard", -- FIXME: throwing errors in weird situations
  -- :Messages <- view messages in quickfix list
  -- :Verbose  <- view verbose output in preview window.
  -- :Time     <- measure how long it takes to run some stuff.
  "tpope/vim-scriptease",
  -- "aca/wezterm.nvim",
  { "knubie/vim-kitty-navigator" },
  -- @trial: "jghauser/kitty-runner.nvim",
  "RRethy/nvim-align",
  "junegunn/vim-easy-align",
  ------------------------------------------------------------------------------
  -- (LANGS, syntax, et al) --
  "ixru/nvim-markdown",
  -- "rhysd/vim-gfm-syntax",
  "gaoDean/autolist.nvim",
  { "iamcco/markdown-preview.nvim", run = "cd app && yarn install", opt = true },
  "ellisonleao/glow.nvim",
  -- "dkarter/bullets.vim",
  -- "dhruvasagar/vim-table-mode",
  "lukas-reineke/headlines.nvim",
  -- @trial https://github.com/ekickx/clipboard-image.nvim
  -- @trial https://github.com/preservim/vim-wordy
  -- @trial https://github.com/jghauser/follow-md-links.nvim
  -- @trial https://github.com/jakewvincent/mkdnflow.nvim
  -- @trial https://github.com/jubnzv/mdeval.nvim
  { "mickael-menu/zk-nvim" },
  -- @trial phaazon/mind.nvim
  -- "renerocksai/telekasten.nvim",
  -- "elixir-editors/vim-elixir",
  "tpope/vim-rails",
  "ngscheurich/edeex.nvim",
  "antew/vim-elm-analyse",
  "tjdevries/nlua.nvim",
  "norcalli/nvim.lua",
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
  "axelvc/template-string.nvim",

  -- @trial:
  -- napmn/react-extract.nvim
  -- sultanahamer/nvim-dap-reactnative
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
  if not vim.g.use_packer then
    -- vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/*/start")
    vim.opt.runtimepath:remove("~/.local/share/nvim/site/pack/packer")
  end

  vim.cmd("packadd cfilter")

  conf("golden_size", { config = "golden_size" })
  conf("gitsigns", { config = "gitsigns" })
  conf("telescope", { config = "telescope" })
  conf("toggleterm", { config = "toggleterm" })
  conf("neo-tree", { config = "neo-tree" })
  conf("cmp", { config = "cmp" })
  conf("luasnip", { config = "luasnip" })
  conf("projectionist", { config = "projectionist" })
  conf("vim-test", { config = "vim-test" })
  conf("hop", { config = "hop" })
  -- conf("mini", { config = "mini" })
  conf("zk", { config = "zk" })
  conf("dap", { config = "dap" })
  conf("dapui", { config = "dapui" })
  conf("hydra", { config = "hydra" })
  conf("tabby", { config = "tabby" })

  conf("nvim-web-devicons", {})
  conf("nvim-surround", {
    highlight = { -- Highlight before inserting/changing surrounds
      duration = 1,
    },
  })

  conf("startuptime", function() vim.g.startuptime_tries = 15 end)

  conf("indent_blankline", {
    char = "│", -- ┆ ┊ 
    show_foldtext = false,
    context_char = "▎",
    char_priority = 12,
    show_current_context = true,
    show_current_context_start = true,
    show_current_context_start_on_current_line = false,
    show_first_indent_level = true,
    filetype_exclude = {
      "dbout",
      "neo-tree-popup",
      "dap-repl",
      "startify",
      "dashboard",
      "log",
      "fugitive",
      "gitcommit",
      "packer",
      "vimwiki",
      "markdown",
      "txt",
      "vista",
      "help",
      "NvimTree",
      "git",
      "TelescopePrompt",
      "undotree",
      "flutterToolsOutline",
      "norg",
      "org",
      "orgagenda",
      "", -- for all buffers without a file type
    },
    buftype_exclude = { "terminal", "nofile" },
  })

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
    require("colorizer").setup({
      filetypes = { "*" },
      user_default_options = {
        RGB = true, -- #RGB hex codes
        RRGGBB = true, -- #RRGGBB hex codes
        names = false, -- "Name" codes like Blue or blue
        RRGGBBAA = true, -- #RRGGBBAA hex codes
        AARRGGBB = true, -- 0xAARRGGBB hex codes
        rgb_fn = true, -- CSS rgb() and rgba() functions
        hsl_fn = true, -- CSS hsl() and hsla() functions
        -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
        css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
        -- Available modes for `mode`: foreground, background,  virtualtext
        mode = "background", -- Set the display mode.
        virtualtext = "■",
      },
      -- all the sub-options of filetypes apply to buftypes
      buftypes = {},
    })
  end)

  -- conf("flit", {
  --   multiline = false,
  --   eager_ops = true, -- jump right to the ([count]th) target (no labels)
  --   keymaps = { f = "f", F = "F", t = "t", T = "T" },
  -- })

  -- REF: https://github.com/smjonas/live-command.nvim#gear-usage-and-customization
  -- conf("live_command", {
  --   commands = {
  --     Norm = { cmd = "norm" },
  --   },
  -- })

  -- FIXME: this breaks my cursorline plugin :(
  -- conf("tint", function()
  --   require("tint").setup({
  --     tint = -50,
  --     highlight_ignore_patterns = {
  --       "WinSeparator",
  --       "St.*",
  --       "Comment",
  --       "Panel.*",
  --       "Telescope.*",
  --       'Bqf.*',
  --       "Cursor.*",
  --     },
  --     window_ignore_function = function(win_id)
  --       if vim.wo[win_id].diff or vim.fn.win_gettype(win_id) ~= "" then return true end
  --       local buf = vim.api.nvim_win_get_buf(win_id)
  --       local b = vim.bo[buf]
  --       local ignore_bt = { "megaterm", "terminal", "prompt", "nofile" }
  --       local ignore_ft = { "neo-tree", "packer", "diff", "megaterm", "toggleterm", "Neogit.*", "Telescope.*", "qf" }
  --       return mega.any(b.bt, ignore_bt) or mega.any(b.ft, ignore_ft)
  --     end,
  --   })
  -- end)

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

  conf("template-string", {})

  -- FIXME:
  --Error executing vim.schedule lua callback: /usr/local/share/nvim/runtime/lua/vim/lsp/util.lua:1569: Window was closed immediately
  -- stack traceback:
  --         [C]: in function 'nvim_open_win'
  --         /usr/local/share/nvim/runtime/lua/vim/lsp/util.lua:1569: in function 'open_floating_preview'
  --         ...paqs/start/lsp_signature.nvim/lua/lsp_signature/init.lua:471: in function 'handler'
  --         /usr/local/share/nvim/runtime/lua/vim/lsp.lua:1241: in function ''
  --         vim/_editor.lua: in function <vim/_editor.lua:0>
  conf("lsp_signature", {
    bind = true,
    fix_pos = false,
    auto_close_after = 15, -- close after 15 seconds
    hint_enable = false,
    handler_opts = { border = mega.get_border() },
    -- bind = true,
    -- always_trigger = false,
    -- fix_pos = false,
    -- auto_close_after = 5,
    -- hint_enable = false,
    -- handler_opts = {
    --   anchor = "SW",
    --   relative = "cursor",
    --   row = -1,
    --   focus = false,
    --   border = mega.get_border(),
    -- },
    -- zindex = 99, -- Keep signature popup below the completion PUM
    -- toggle_key = "<C-k>",
  })

  conf("hover", {
    init = function()
      -- Require providers
      require("hover.providers.lsp")
      require("hover.providers.gh")
      require("hover.providers.man")
      require("hover.providers.dictionary")
    end,
    preview_opts = {
      border = mega.get_border(),
    },
    title = true,
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

  conf("pqf", {
    signs = {
      error = mega.icons.lsp.error,
      warning = mega.icons.lsp.warn,
      info = mega.icons.lsp.info,
      hint = mega.icons.lsp.hint,
    },
  })

  -- conf("hclipboard", function() require("hclipboard").start() end)

  conf("numb", {})

  conf("bufdel", {
    next = "cycle", -- alts: 'alternate'
    quit = true,
  })

  conf("fzf_gitignore", function() vim.g.fzf_gitignore_no_maps = true end)
  conf("vim-kitty-navigator", { enabled = not vim.env.TMUX })

  -- conf("neogen", function()
  --   require("neogen").setup({ snippet_engine = "luasnip" })
  --   mega.nnoremap("<localleader>cg", require("neogen").generate, "comment: generate")
  -- end)

  conf("notify", function()
    local notify = require("notify")
    notify.setup({
      timeout = 3000,
      stages = "fade_in_slide_out",
      top_down = false,
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
    vim.notify = notify
  end)

  conf("autolist", {})

  -- conf("vim-visual-multi", function()
  --   vim.g.VM_highlight_matches = "underline"
  --   vim.g.VM_theme = "codedark"
  --   vim.g.VM_maps = {
  --     ["Find Under"] = "<C-e>",
  --     ["Find Subword Under"] = "<C-e>",
  --     ["Select Cursor Down"] = "\\j",
  --     ["Select Cursor Up"] = "\\k",
  --   }
  -- end)

  conf("sessions", {
    events = { "VimLeavePre" },
    session_filepath = vim.fn.stdpath("data") .. "/sessions/default",
  })

  conf("workspaces", {
    path = vim.fn.stdpath("data") .. "/workspaces",
    hooks = {
      open_pre = {
        function()
          local open_files = require("mega.utils").get_open_filelist()
          if open_files == nil or #open_files == 0 or (#open_files == 1 and open_files[1] == "") then
            vim.cmd("SessionsStop")
            vim.cmd("silent %bdelete!")
          end
        end,
      },
      open = {
        function()
          local open_files = require("mega.utils").get_open_filelist()
          if open_files == nil or #open_files == 0 or (#open_files == 1 and open_files[1] == "") then
            require("sessions").load(nil, { silent = true })
          end
        end,
      },
    },
  })

  -- conf("habitats", {})
end

return M
