return {
  -- ( CORE ) ------------------------------------------------------------------
  "nvim-lua/plenary.nvim",
  "nvim-lua/popup.nvim",
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },
  "mattn/webapi-vim",
  {
    "ethanholz/nvim-lastplace",
    lazy = false,
    config = function()
      require("nvim-lastplace").setup({
        lastplace_ignore_buftype = { "quickfix", "nofile", "help" },
        lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit", "terminal", "megaterm" },
        lastplace_open_folds = true,
      })
    end,
  },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = true,
    priority = 1000,
    config = function()
      require("lush")(require("mega.lush_theme.megaforest"))
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  -- {
  --   "JoosepAlviste/palenightfall.nvim",
  --   lazy = false,
  --   config = vim.g.colorscheme == "palenightfall",
  -- },
  {
    "mcchrish/zenbones.nvim",
    lazy = false,
    dependencies = "rktjmp/lush.nvim",
  },
  {
    "neanias/everforest-nvim",
    lazy = false,
    config = function()
      require("everforest").setup({
        -- Controls the "hardness" of the background. Options are "soft", "medium" or "hard".
        -- Default is "medium".
        background = "soft",
        -- How much of the background should be transparent. Options are 0, 1 or 2.
        -- Default is 0.
        --
        -- 2 will have more UI components be transparent (e.g. status line
        -- background).
        transparent_background_level = 0,
      })
    end,
  },
  {
    "luukvbaal/statuscol.nvim",
    event = "BufReadPost",
    enabled = false,
    config = function()
      require("statuscol").setup({
        setopt = true,
        order = "FSNs",
        relculright = true,
        foldfunc = "builtin",
      })
    end,
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    -- event = { "CursorHold", "CursorMoved", "InsertEnter" },
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage" },
        buftype = { "*", "!prompt", "!nofile" },
        user_default_options = {
          RGB = false, -- #RGB hex codes
          RRGGBB = true, -- #RRGGBB hex codes
          names = false, -- "Name" codes like Blue or blue
          RRGGBBAA = true, -- #RRGGBBAA hex codes
          AARRGGBB = true, -- 0xAARRGGBB hex codes
          rgb_fn = true, -- CSS rgb() and rgba() functions
          hsl_fn = true, -- CSS hsl() and hsla() functions
          -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
          css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
          sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
          -- Available modes for `mode`: foreground, background,  virtualtext
          mode = "background", -- Set the display mode.
          virtualtext = "■",
        },
        -- all the sub-options of filetypes apply to buftypes
        buftypes = {},
      })

      _G.mega.augroup("Colorizer", {
        {
          event = { "BufReadPost" },
          command = function()
            if _G.mega.is_chonky(vim.api.nvim_get_current_buf()) then vim.cmd("ColorizerDetachFromBuffer") end
          end,
        },
      })
    end,
  },
  "lukas-reineke/virt-column.nvim",
  "MunifTanjim/nui.nvim",
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("todo-comments").setup()
      -- mega.command("TodoDots", ("TodoQuickFix cwd=%s keywords=TODO,FIXME"):format(vim.g.vim_dir))
    end,
  },
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    opts = {
      plugins = {
        gitsigns = true,
        tmux = true,
        kitty = { enabled = false, font = "+2" },
      },
    },
    keys = { { "<localleader>zz", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
  },
  {
    "stevearc/dressing.nvim",
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
  },

  -- indent guides for Neovim
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    enabled = true,
    opts = {
      char = "│", -- alts: ┆ ┊  ▎
      --       show_foldtext = false,
      --       context_char = "▎",
      --       char_priority = 12,
      show_current_context = true,
      show_current_context_start = true,
      show_current_context_start_on_current_line = true,
      show_trailing_blankline_indent = false,
      show_first_indent_level = true,
      filetype_exclude = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "lazy",
        "fzf",
        "fzf-lua",
        "fzflua",
        "megaterm",
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
    },
  },

  -- ( Movements ) -------------------------------------------------------------
  -- @trial multi-cursor: https://github.com/brendalf/dotfiles/blob/master/.config/nvim/lua/core/multi-cursor.lua

  -- ( Navigation ) ------------------------------------------------------------
  {
    "knubie/vim-kitty-navigator",
    -- build = "cp ./*.py ~/.config/kitty/",
    cond = not vim.env.TMUX and not vim.env.ZELLIJ,
  },
  {
    "Lilja/zellij.nvim",
    cond = vim.env.ZELLIJ,
    config = function()
      require("zellij").setup({})
      local function edgeDetect(direction)
        local currWin = vim.api.nvim_get_current_win()
        vim.api.nvim_command("wincmd " .. direction)
        local newWin = vim.api.nvim_get_current_win()

        -- You're at the edge when you just moved direction and the window number is the same
        print("ol winN ")
        print(currWin)
        print(" new ")
        print(newWin)
        print(" same? ")
        print(currWin == newWin)
        return currWin == newWin
      end

      local function zjCall(direction)
        local directionTranslation = {
          h = "left",
          j = "down",
          k = "up",
          l = "right",
        }
        -- local cmd  = "zellij action move-focus-or-tab " .. directionTranslation[direction]
        local cmd = "zellij action move-focus-or-tab " .. directionTranslation[direction]
        local cmd2 = "zellij --help"
        print("cmd")
        print(cmd)
        local c = vim.fn.system(cmd)
        print(c)
        local c2 = vim.fn.system("ls -l")
        print(c2)
      end

      local function zjNavigate(direction)
        if edgeDetect(direction) then zjCall(direction) end
      end

      vim.keymap.set("n", "<C-h>", function() zjNavigate("h") end)
      vim.keymap.set("n", "<C-j", function() zjNavigate("j") end)
      vim.keymap.set("n", "<C-k", function() zjNavigate("k") end)
      vim.keymap.set("n", "<C-l", function() zjNavigate("l") end)
    end,
  },
  -- { "sunaku/tmux-navigate", cond = vim.env.TMUX },
  -- { "elihunter173/dirbuf.nvim", config = function() require("dirbuf").setup({}) end },
  { "kevinhwang91/nvim-bqf", ft = "qf" },
  {
    url = "https://gitlab.com/yorickpeterse/nvim-pqf",
    event = "BufReadPre",
    config = function()
      local icons = require("mega.icons")
      require("pqf").setup({
        signs = {
          error = icons.lsp.error,
          warning = icons.lsp.warn,
          info = icons.lsp.info,
          hint = icons.lsp.hint,
        },
      })
    end,
  },

  -- ( LSP ) -------------------------------------------------------------------
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    dependencies = "nvim-lspconfig",
    config = function()
      require("lsp_signature").setup({
        bind = true,
        fix_pos = true,
        auto_close_after = 10, -- close after 15 seconds
        hint_enable = false,
        floating_window_above_cur_line = true,
        doc_lines = 0,
        handler_opts = {
          anchor = "SW",
          relative = "cursor",
          row = -1,
          focus = false,
          border = _G.mega.get_border(),
        },
        zindex = 99, -- Keep signature popup below the completion PUM
        toggle_key = "<C-K>",
        select_signature_key = "<M-N>",
      })
    end,
  },
  "nvim-lua/lsp_extensions.nvim",
  "jose-elias-alvarez/typescript.nvim",
  "MunifTanjim/nui.nvim",
  "williamboman/mason-lspconfig.nvim",
  "b0o/schemastore.nvim",
  "mrshmllow/document-color.nvim",
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    config = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },
  {
    "lewis6991/hover.nvim",
    keys = { "K", "gK" },
    config = function()
      require("hover").setup({
        init = function()
          -- Require providers
          require("hover.providers.lsp")
          -- require('hover.providers.gh')
          -- require('hover.providers.gh_user')
          -- require('hover.providers.jira')
          -- require('hover.providers.man')
          -- require('hover.providers.dictionary')
        end,
        preview_opts = {
          border = require("mega.globals").get_border(),
        },
        -- Whether the contents of a currently open hover window should be moved
        -- to a :h preview-window when pressing the hover keymap.
        preview_window = false,
        title = true,
      })
    end,
  },
  -- { "folke/lua-dev.nvim", module = "lua-dev" },
  -- { "microsoft/python-type-stubs", lazy = true },
  -- { "lvimuser/lsp-inlayhints.nvim" },

  -- ( Git ) -------------------------------------------------------------------
  {
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
    end,
    dependencies = "nvim-lua/plenary.nvim",
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    config = true,
    keys = { { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
  },
  {
    "akinsho/git-conflict.nvim",
    lazy = false,
    dependencies = "rktjmp/lush.nvim",
    config = function()
      require("git-conflict").setup({
        disable_diagnostics = true,
        highlights = {
          incoming = "DiffText",
          current = "DiffAdd",
          ancestor = "DiffBase",
        },
      })
    end,
  },
  {
    "ruifm/gitlinker.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    keys = {
      { "<localleader>gu", mode = "n" },
      { "<localleader>gu", mode = "v" },
      "<localleader>go",
      "<leader>gH",
      { "<localleader>go", mode = "n" },
      { "<localleader>go", mode = "v" },
    },
    config = function()
      require("gitlinker").setup({ mappings = nil })

      local function linker() return require("gitlinker") end
      local function browser_open() return { action_callback = require("gitlinker.actions").open_in_browser } end
      mega.nnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("n") end,
        "gitlinker: copy line to clipboard"
      )
      mega.vnoremap(
        "<localleader>gu",
        function() linker().get_buf_range_url("v") end,
        "gitlinker: copy range to clipboard"
      )
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_repo_url(browser_open()) end,
        "gitlinker: open in browser"
      )
      mega.nnoremap("<leader>gH", function() linker().get_repo_url(browser_open()) end, "gitlinker: open in browser")
      mega.nnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("n", browser_open()) end,
        "gitlinker: open current line in browser"
      )
      mega.vnoremap(
        "<localleader>go",
        function() linker().get_buf_range_url("v", browser_open()) end,
        "gitlinker: open current selection in browser"
      )
    end,
  },

  -- ( Testing/Debugging ) -----------------------------------------------------
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = "nvim-dap",
    config = function()
      require("nvim-dap-virtual-text").setup({
        commented = true,
      })
    end,
  },
  { "jbyuki/one-small-step-for-vimkind", dependencies = "nvim-dap" },
  { "suketa/nvim-dap-ruby", dependencies = "nvim-dap", config = function() require("dap-ruby").setup() end },
  -- {
  --   "microsoft/vscode-js-debug",
  --   build = "npm install --legacy-peer-deps && npm run compile",
  -- },
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = "nvim-dap",
    config = function()
      require("dap-vscode-js").setup({
        log_file_level = vim.log.levels.TRACE,
        adapters = {
          "pwa-node",
          "pwa-chrome",
          "pwa-msedge",
          "node-terminal",
          "pwa-extensionHost",
        },
      })
    end,
  },
  { "sultanahamer/nvim-dap-reactnative", dependencies = "nvim-dap" },
  -- {
  --   "jayp0521/mason-nvim-dap.nvim",
  --   dependencies = "nvim-dap",
  --   config = function()
  --     require("mason-nvim-dap").setup({
  --       ensure_installed = { "python", "node2", "chrome", "firefox" },
  --       automatic_installation = true,
  --     })
  --   end,
  -- },

  -- ( Development ) -----------------------------------------------------------
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cc",
        function() require("neogen").generate({}) end,
        desc = "Neogen Comment",
      },
    },
    config = { snippet_engine = "luasnip" },
  },
  {
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    setup = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  },
  {
    "andymass/vim-matchup",
    event = "BufReadPre",
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
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  },
  { "alvan/vim-closetag" },
  { "tpope/vim-eunuch", event = "VeryLazy" },
  {
    "chrisgrieser/nvim-genghis",
    dependencies = { "stevearc/dressing.nvim", { "tpope/vim-eunuch", event = "VeryLazy" } },
    event = "VeryLazy",
    config = function()
      local genghis = require("genghis")
      mega.nnoremap("<localleader>yp", genghis.copyFilepath, { desc = "Copy filepath" })
      mega.nnoremap("<localleader>yn", genghis.copyFilename, { desc = "Copy filename" })
      mega.nnoremap("<localleader>yf", genghis.duplicateFile, { desc = "Duplicate file" })
      mega.nnoremap("<localleader>rf", genghis.renameFile, { desc = "Rename file" })
      mega.nnoremap("<localleader>cx", genghis.chmodx, { desc = "Chmod +x file" })
      mega.nnoremap(
        "<localleader>df",
        function() genghis.trashFile({ trashLocation = "$HOME/.Trash" }) end,
        { desc = "Delete to trash" }
      ) -- default: "$HOME/.Trash".
      -- mega.nmap("<localleader>mf", genghis.moveAndRenameFile)
      -- mega.nmap("<localleader>nf", genghis.createNewFile)
      -- mega.nmap("<localleader>x", genghis.moveSelectionToNewFile)
    end,
  },
  {
    "tpope/vim-abolish",
    config = function()
      mega.nnoremap("<localleader>[", ":S/<C-R><C-W>//<LEFT>", { silent = false })
      mega.nnoremap("<localleader>]", ":%S/<C-r><C-w>//c<left><left>", { silent = false })
      mega.xnoremap("<localleader>[", [["zy:'<'>S/<C-r><C-o>"//c<left><left>]], { silent = false })
    end,
  },
  { "tpope/vim-rhubarb" },
  { "tpope/vim-repeat" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-apathy" },
  { "tpope/vim-scriptease", cmd = { "Messages", "Mess" } },
  { "lambdalisue/suda.vim" },
  { "EinfachToll/DidYouMean" },
  { "wsdjeg/vim-fetch", lazy = false }, -- vim path/to/file.ext:12:3
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  -- { "tpope/vim-scriptease" },
  { "axelvc/template-string.nvim" },
  -- @trial: "jghauser/kitty-runner.nvim"

  -- ( Motions/Textobjects ) ---------------------------------------------------
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter", "AndrewRadev/splitjoin.vim" },
    cmd = { "TSJSplit", "TSJJoin", "TSJToggle", "SplitjoinJoin", "SplitjoinSplit" },
    keys = { "gs", "gj", "gS", "gJ" },
    config = function()
      require("treesj").setup({ use_default_keymaps = false, max_join_length = 150 })

      local langs = require("treesj.langs")["presets"]

      vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = "*",
        callback = function()
          if langs[vim.bo.filetype] then
            mega.nnoremap("gS", ":TSJSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gJ", ":TSJJoin<cr>", { desc = "Join lines", buffer = true })
            mega.nnoremap("gs", ":TSJSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gj", ":TSJJoin<cr>", { desc = "Join lines", buffer = true })
          else
            mega.nnoremap("gS", ":SplitjoinSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gJ", ":SplitjoinJoin<cr>", { desc = "Join lines", buffer = true })
            mega.nnoremap("gs", ":SplitjoinSplit<cr>", { desc = "Split lines", buffer = true })
            mega.nnoremap("gj", ":SplitjoinJoin<cr>", { desc = "Join lines", buffer = true })
          end
        end,
      })
    end,
  },
  {
    "abecodes/tabout.nvim",
    event = { "VeryLazy" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/nvim-cmp" },
    config = function()
      require("tabout").setup({
        tabkey = "<Tab>", -- key to trigger tabout, set to an empty string to disable
        backwards_tabkey = "<S-Tab>", -- key to trigger backwards tabout, set to an empty string to disable
        act_as_tab = true, -- shift content if tab out is not possible
        act_as_shift_tab = false, -- reverse shift content if tab out is not possible (if your keyboard/terminal supports <S-Tab>)
        default_tab = "<C-t>", -- shift default action (only at the beginning of a line, otherwise <TAB> is used)
        default_shift_tab = "<C-d>", -- reverse shift default action,
        enable_backwards = true, -- well ...
        completion = true, -- if the tabkey is used in a completion pum
        tabouts = {
          { open = "'", close = "'" },
          { open = "\"", close = "\"" },
          { open = "`", close = "`" },
          { open = "(", close = ")" },
          { open = "[", close = "]" },
          { open = "{", close = "}" },
          { open = "<", close = ">" },
        },
        ignore_beginning = true, --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]]
        exclude = {}, -- tabout will ignore these filetypes
      })
    end,
  },

  -- ( Notes/Docs ) ------------------------------------------------------------
  -- { "ixru/nvim-markdown" },
  { "iamcco/markdown-preview.nvim", ft = "markdown", build = "cd app && yarn install" },
  {
    "evanpurkhiser/image-paste.nvim",
    ft = "markdown",
    keys = {
      { "<C-v>", function() require("image-paste").paste_image() end, mode = "i" },
    },
    config = {
      imgur_client_id = "2974b259fd073e2",
    },
  },
  {
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = { "markdown" },
    config = function()
      local peek = require("peek")
      peek.setup({})

      _G.mega.command("Peek", function()
        if not peek.is_open() and vim.bo[vim.api.nvim_get_current_buf()].filetype == "markdown" then
          peek.open()
          -- vim.fn.system([[hs -c 'require("wm.snap").send_window_right(hs.window.find("Peek preview"))']])
          -- vim.fn.system([[hs -c 'require("wm.snap").send_window_left(hs.application.find("kitty"):mainWindow())']])
        else
          peek.close()
        end
      end)
    end,
  },
  {
    "gaoDean/autolist.nvim",
    ft = { "markdown" },
    config = function()
      local autolist = require("autolist")
      autolist.setup()
      autolist.create_mapping_hook("i", "<CR>", autolist.new)
      autolist.create_mapping_hook("i", "<Tab>", autolist.indent)
      autolist.create_mapping_hook("i", "<S-Tab>", autolist.indent, "<C-D>")
      autolist.create_mapping_hook("n", "o", autolist.new)
      autolist.create_mapping_hook("n", "O", autolist.new_before)
      autolist.create_mapping_hook("n", ">>", autolist.indent)
      autolist.create_mapping_hook("n", "<<", autolist.indent)
      autolist.create_mapping_hook("n", "<C-r>", autolist.force_recalculate)
      autolist.create_mapping_hook("n", "<leader>x", autolist.invert_entry, "")
      autolist.create_mapping_hook("n", "<C-c>", autolist.invert_entry, "")
      vim.api.nvim_create_autocmd("TextChanged", {
        pattern = "*",
        callback = function() vim.cmd.normal({ autolist.force_recalculate(nil, nil), bang = false }) end,
      })
      -- require("autolist").setup({ normal_mappings = { invert = { "<c-c>" } } })
    end,
  },
  { "ellisonleao/glow.nvim", ft = { "markdown" } },
  {
    "lukas-reineke/headlines.nvim",
    ft = { "markdown" },
    dependencies = "nvim-treesitter",
    config = function()
      require("headlines").setup({
        markdown = {
          source_pattern_start = "^```",
          source_pattern_end = "^```$",
          dash_pattern = "-",
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
    end,
  },
  -- @trial phaazon/mind.nvim
  -- @trial "renerocksai/telekasten.nvim"
  -- @trial preservim/vim-wordy
  -- @trial jghauser/follow-md-links.nvim
  -- @trial jakewvincent/mkdnflow.nvim
  -- @trial jubnzv/mdeval.nvim
  -- "dkarter/bullets.vim".
  -- "dhruvasagar/vim-table-mode".
  -- "rhysd/vim-gfm-syntax".

  -- ( Syntax/Languages ) ------------------------------------------------------
  { "ii14/emmylua-nvim", ft = "lua" },
  -- { "elixir-editors/vim-elixir", ft = { "markdown" } }, -- nvim exceptions thrown when not installed
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
}
