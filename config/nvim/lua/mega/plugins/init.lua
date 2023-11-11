return {
  -- ( CORE ) ------------------------------------------------------------------
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },
  {
    "zeioth/garbage-day.nvim",
    event = "BufEnter",
    config = true,
    cond = false,
  },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "farmergreg/vim-lastplace",
    lazy = false,
    init = function()
      vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
      vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
      vim.g.lastplace_open_folds = true
    end,
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!oil" },
        buftype = { "*", "!prompt", "!nofile", "!oil" },
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
    end,
  },
  { "lukas-reineke/virt-column.nvim", opts = { char = "│" }, event = "VimEnter" },
  -- {
  --   "lukas-reineke/indent-blankline.nvim",
  --   event = "LazyFile",
  --   opts = {
  --     indent = {
  --       char = "│",
  --       tab_char = "│",
  --     },
  --     scope = { enabled = true },
  --     exclude = {
  --       filetypes = {
  --         "help",
  --         "alpha",
  --         "dashboard",
  --         "neo-tree",
  --         "Trouble",
  --         "trouble",
  --         "lazy",
  --         "mason",
  --         "notify",
  --         "toggleterm",
  --         "lazyterm",
  --       },
  --     },
  --   },
  --   main = "ibl",
  -- },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = { { "<leader>U", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
    config = function()
      vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_DiffCommand = "diff -u"
    end,
  },
  -- {
  --   "chrisgrieser/nvim-origami",
  --   event = "BufReadPost",
  --   keys = { { "<BS>", function() require("origami").h() end, desc = "toggle fold" } },
  --   opts = {},
  -- },
  {
    "gabrielpoca/replacer.nvim",
    ft = "qf",
    -- keys = {
    --   { "<leader>R", function() require("replacer").run() end, desc = "qf: replace in qflist" },
    --   { "<C-r>", function() require("replacer").run() end, desc = "qf: replace in qflist" },
    -- },
    init = function()
      -- save & quit via "q"
      mega.augroup("ReplacerFileType", {
        pattern = "replacer",
        callback = function()
          mega.nmap("q", vim.cmd.write, { desc = " done replacing", buffer = true, nowait = true })
        end,
      })
      -- mega.nnoremap(
      --   "<leader>r",
      --   function() require("replacer").run() end,
      --   { desc = "qf: replace in qflist", nowait = true }
      -- )
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = { at_edge = "stop" },
    build = "./kitty/install-kittens.bash",
    keys = {
      { "<A-h>", function() require("smart-splits").resize_left() end },
      { "<A-l>", function() require("smart-splits").resize_right() end },
      -- moving between splits
      { "<C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end },
      -- swapping buffers between windows
      { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = "swap left" },
      { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, desc = "swap down" },
      { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, desc = "swap up" },
      { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, desc = "swap right" },
    },
  },
  {
    "chentoast/marks.nvim",
    cond = false,
    event = "VeryLazy",
    keys = {
      { "<leader>mm", "<Cmd>MarksListBuf<CR>", desc = "marks: list buffer marks" },
      { "<leader>mg", "<Cmd>MarksListBuf<CR>", desc = "marks: list global marks" },
      { "<leader>mb", "<Cmd>MarksListBuf<CR>", desc = "marks: list bookmark marks" },
      { "m/", "<cmd>MarksListAll<CR>", desc = "Marks from all opened buffers" },
      { "<leader>mt", "<cmd>MarksToggleSigns<cr>", desc = "Toggle marks" },
      -- { 'm', '<Plug>(Marks-set)', '<Plug>(Marks-toggle)' },
    },
    opts = {
      sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
      bookmark_1 = { sign = "󰈼" }, -- ⚐ ⚑ 󰈻 󰈼 󰈽 󰈾 󰈿 󰉀
      default_mappings = false, -- whether to map keybinds or not. default true
      builtin_marks = {}, -- which builtin marks to show. default {}
      cyclic = true, -- whether movements cycle back to the beginning/end of buffer. default true
      force_write_shada = false, -- whether the shada file is updated after modifying uppercase marks. default false
      bookmark_0 = { -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own sign/virttext
        sign = "⚑",
        virt_text = "hello world",
      },
      mappings = {
        set_next = "m,",
        next = "m]",
        preview = "m;",
        set_bookmark0 = "m0",
        prev = false, -- pass false to disable only this default mapping
        annotate = "m<Space>",
      },
      excluded_filetypes = {
        "DressingInput",
        "gitcommit",
        "NeogitCommitMessage",
        "NeogitNotification",
        "NeogitStatus",
        "NeogitStatus",
        "NvimTree",
        "Outline",
        "OverseerForm",
        "dropbar_menu",
        "lazy",
        "lspinfo",
        "megaterm",
        "neo-tree",
        "neo-tree-popup",
        "noice",
        "notify",
        "null-ls-info",
        "registers",
        "toggleterm",
        "toggleterm",
      },
    },
  },
  {
    "stevearc/overseer.nvim", -- Task runner and job management
    keys = {
      { "<leader>or", "<cmd>OverseerRun<cr>", desc = "overseer: run task" },
      { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "overseer: toggle tasks" },
    },
    opts = {
      strategy = {
        "terminal",
        use_shell = true,
      },
      form = {
        border = mega.get_border(),
      },
      task_list = { direction = "right" },
      templates = { "builtin", "global" },
      component_aliases = {
        default_neotest = {
          "unique",
          { "on_complete_notify", system = "unfocused", on_change = true },
          "default",
          "on_output_summarize",
          "on_exit_set_status",
          "on_complete_dispose",
        },
      },
    },
  },
  {
    "echasnovski/mini.pick",
    cmd = "Pick",
    opts = {},
  },
  {
    "monaqa/dial.nvim",
    -- stylua: ignore
    keys = {
      { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
          augend.semver.alias.semver,
          augend.constant.new({ elements = { "let", "const" } }),
        },
      })
    end,
  },
  -- {
  --   "3rd/image.nvim",
  --   ft = { "markdown", "norg", "syslang", "vimwiki" },
  --   opts = {
  --     -- backend = "ueberzug",
  --     tmux_show_only_in_active_window = true,
  --   },
  -- },

  -- ( LSP ) -------------------------------------------------------------------
  { "onsails/lspkind.nvim" },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "nvim-lua/lsp_extensions.nvim" },
      -- {
      --   "jose-elias-alvarez/typescript.nvim",
      --   enabled = vim.g.formatter == "null-ls",
      --   ft = { "typescript", "typescriptreact" },
      --   dependencies = { "jose-elias-alvarez/null-ls.nvim" },
      --   config = function()
      --     if vim.g.formatter == "null-ls" then
      --       require("null-ls").register({
      --         sources = { require("typescript.extensions.null-ls.code-actions") },
      --       })
      --     end
      --   end,
      -- },
      { "MunifTanjim/nui.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "b0o/schemastore.nvim" },
      { "ray-x/lsp_signature.nvim" },
      {
        "mhanberg/output-panel.nvim",
        keys = {
          {
            "<leader>lip",
            ":OutputPanel<CR>",
            desc = "lsp: open output panel",
          },
        },
        event = "LspAttach",
        cmd = { "OutputPanel" },
        config = function() require("output_panel").setup() end,
      },
      {
        "Fildo7525/pretty_hover",
        event = "LspAttach",
        opts = { border = _G.mega.get_border() },
      },
      {
        "lewis6991/hover.nvim",
        keys = { "K", "gK" },
        config = function()
          require("hover").setup({
            init = function()
              require("hover.providers.lsp")
              require("hover.providers.gh")
              require("hover.providers.gh_user")
              require("hover.providers.jira")
              require("hover.providers.man")
              require("hover.providers.dictionary")
            end,
            preview_opts = {
              border = _G.mega.get_border(),
            },
            -- Whether the contents of a currently open hover window should be moved
            -- to a :h preview-window when pressing the hover keymap.
            preview_window = true,
            title = false,
          })
        end,
      },
    },
  },
  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    enabled = vim.g.explorer == "oil",
    cond = vim.g.explorer == "oil",
    opts = {
      trash = false,
      skip_confirm_for_simple_edits = true,
      trash_command = "trash-cli",
      prompt_save_on_select_new_entry = false,
      use_default_keymaps = false,
      columns = {
        "icon",
      },
      keymaps = {
        ["gd"] = {
          desc = "Toggle detail view",
          callback = function()
            local oil = require("oil")
            local config = require("oil.config")
            if #config.columns == 1 then
              oil.set_columns({ "icon", "permissions", "size", "mtime" })
            else
              oil.set_columns({ "icon" })
            end
          end,
        },
        ["<CR>"] = "actions.select",
        ["gp"] = function()
          local oil = require("oil")
          local entry = oil.get_cursor_entry()
          if entry["type"] == "file" then
            local dir = oil.get_current_dir()
            local fileName = entry["name"]
            local fullName = dir .. fileName

            require("mega.utils").preview_file(fullName)
          else
            return ""
          end
        end,
      },
    },
    keys = {
      {
        "<leader>ed",
        function()
          -- vim.cmd([[vertical rightbelow split|vertical resize 60]])
          vim.cmd([[vertical rightbelow split]])
          require("oil").open()
        end,
        desc = "oil: open (vsplit)",
      },
      {
        "<leader>ee",
        function() require("oil").open() end,
        desc = "oil: open (edit)",
      },
    },
  },
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
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    config = {
      auto_open = false,
      use_diagnostic_signs = true, -- en
    },
  },

  -- ( Development ) -----------------------------------------------------------
  {
    "kevinhwang91/nvim-hclipboard",
    event = "InsertCharPre",
    config = function() require("hclipboard").start() end,
  },
  {
    "bennypowers/nvim-regexplainer",
    opts = {},
    cmd = { "RegexplainerShowSplit", "RegexplainerShowPopup", "RegexplainerHide", "RegexplainerToggle" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "MunifTanjim/nui.nvim",
    },
  },
  { "tpope/vim-dispatch" },
  {
    "jackMort/ChatGPT.nvim",
    cmd = { "ChatGPT", "ChatGPTActAs", "ChatGPTEditWithInstructions" },
    config = function()
      local border = { style = mega.get_border(), highlight = "PickerBorder" }
      require("chatgpt").setup({
        popup_window = { border = border },
        popup_input = { border = border, submit = "<C-y>" },
        settings_window = { border = border },
        chat = {
          keymaps = {
            close = {
              "<C-c>",
            },
          },
        },
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "tdfacer/explain-it.nvim",
    requires = {
      "rcarriga/nvim-notify",
    },
    config = function()
      require("explain-it").setup({
        -- Prints useful log messages
        debug = true,
        -- Customize notification window width
        max_notification_width = 20,
        -- Retry API calls
        max_retries = 3,
        -- Customize response text file persistence location
        output_directory = "/tmp/chat_output",
        -- Toggle splitting responses in notification window
        split_responses = false,
        -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
        token_limit = 2000,
      })
    end,
  },
  {
    "piersolenski/wtf.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "gw",
        mode = { "n" },
        function() require("wtf").ai() end,
        desc = "Debug diagnostic with AI",
      },
      {
        mode = { "n" },
        "gW",
        function() require("wtf").search() end,
        desc = "Search diagnostic with Google",
      },
    },
  },
  {
    "danymat/neogen",
    cmd = "Neogen",
    keys = {
      {
        "<leader>cc",
        function() require("neogen").generate({}) end,
        desc = "Neogen Comment",
      },
    },
    opts = function()
      local M = {}
      M.snippet_engine = "vsnip"
      M.languages = {}
      M.languages.python = { template = { annotation_convention = "google_docstrings" } }
      M.languages.typescript = { template = { annotation_convention = "tsdoc" } }
      M.languages.typescriptreact = M.languages.typescript
      return M
    end,
  },
  {
    -- TODO: https://github.com/avucic/dotfiles/blob/master/nvim_user/.config/nvim/lua/user/configs/dadbod.lua
    "kristijanhusak/vim-dadbod-ui",
    dependencies = "tpope/vim-dadbod",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection" },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_auto_execute_table_helpers = 1
      -- _G.mega.nnoremap("<leader>db", "<cmd>DBUIToggle<CR>", "dadbod: toggle")
    end,
  },
  { "alvan/vim-closetag", ft = { "elixir", "heex", "html", "liquid", "javascriptreact", "typescriptreact" } },
  {
    "andymass/vim-matchup",
    config = function()
      vim.g.matchup_matchparen_nomode = "i"
      vim.g.matchup_delim_noskips = 1 -- recognize symbols within comments
      vim.g.matchup_matchparen_deferred_show_delay = 400
      vim.g.matchup_matchparen_deferred_hide_delay = 400
      vim.g.matchup_matchparen_offscreen = {}
      -- vim.g.matchup_matchparen_offscreen = {
      --   method = "popup",
      --   -- fullwidth = true,
      --   highlight = "TreesitterContext",
      --   border = "",
      -- }
      vim.g.matchup_matchparen_deferred = 1
      vim.g.matchup_matchparen_timeout = 300
      vim.g.matchup_matchparen_insert_timeout = 60
      vim.g.matchup_surround_enabled = 1 -- defaulted 0
      vim.g.matchup_motion_enabled = 1 -- defaulted 0
      vim.g.matchup_text_obj_enabled = 1

      vim.keymap.set({ "n", "x" }, "[[", "<plug>(matchup-[%)")
      vim.keymap.set({ "n", "x" }, "]]", "<plug>(matchup-]%)")
    end,
  },
  {
    "nacro90/numb.nvim",
    event = "CmdlineEnter",
    config = function() require("numb").setup() end,
  },
  { "tpope/vim-eunuch", cmd = { "Move", "Rename", "Remove", "Delete", "Mkdir", "SudoWrite", "Chmod" } },
  {
    "tpope/vim-abolish",
    event = "CmdlineEnter",
    keys = {
      {
        "<C-s>",
        ":S/<C-R><C-W>//<LEFT>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (line)",
      },
      {
        "<C-s>",
        ":%S/<C-r><C-w>//c<left><left>",
        mode = "n",
        silent = false,
        desc = "abolish: replace word under the cursor (file)",
      },
      {
        "<C-r>",
        [["zy:'<'>S/<C-r><C-o>"//c<left><left>]],
        mode = "x",
        silent = false,
        desc = "abolish: replace word under the cursor (visual)",
      },
    },
  },
  { "tpope/vim-rhubarb", event = { "VeryLazy" } },
  { "tpope/vim-repeat", lazy = false },
  { "tpope/vim-unimpaired", event = { "VeryLazy" } },
  { "tpope/vim-apathy", event = { "VeryLazy" } },
  { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
  { "wsdjeg/vim-fetch", lazy = false }, -- vim path/to/file.ext:12:3
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  { "ryvnf/readline.vim", event = "CmdlineEnter" },

  -- ( Motions/Textobjects ) ---------------------------------------------------
  {
    cond = true,
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      jump = { autojump = false },
      search = { multi_window = false, mode = "exact" },
      modes = {
        search = {
          enabled = false,
        },
        char = {
          keys = { "f", "F", "t", "T", ";" }, -- NOTE: using "," here breaks which-key
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function() require("flash").jump() end,
      },
      {
        "m",
        mode = { "o", "x" },
        function() require("flash").treesitter() end,
      },
      { "r", function() require("flash").remote() end, mode = "o", desc = "Remote Flash" },
      { "<c-s>", function() require("flash").toggle() end, mode = { "c" }, desc = "Toggle Flash Search" },
      {
        "R",
        function() require("flash").treesitter_search() end,
        mode = { "o", "x" },
        desc = "Flash Treesitter Search",
      },
    },
  },
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

  -- ( Notes/Docs ) ------------------------------------------------------------
  {
    cond = false,
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = { "markdown" },
    keys = { { "<localleader>mp", "<cmd>Peek<cr>" } },
    config = function()
      local peek = require("peek")
      peek.setup({})

      _G.mega.command("Peek", function()
        if not peek.is_open() and vim.bo[vim.api.nvim_get_current_buf()].filetype == "markdown" then
          peek.open()
          vim.fn.system([[hs -c 'require("wm.snap").send_window_right(hs.window.find("Peek preview"))']])
          -- vim.fn.system([[hs -c 'require("wm.snap").send_window_left(hs.application.find("kitty"):mainWindow())']])
        else
          peek.close()
        end
      end)
    end,
  },
  {
    "gaoDean/autolist.nvim",
    ft = {
      "org",
      "neorg",
      "plaintext",
      "markdown",
      "gitcommit",
      "NeogitCommitMessage",
      "COMMIT_EDITMSG",
      "NEOGIT_COMMIT_EDITMSG",
    },
    config = function()
      -- local al = require("autolist")
      -- al.setup()
      -- al.create_mapping_hook("i", "<CR>", al.new)
      -- al.create_mapping_hook("i", "<Tab>", al.indent)
      -- al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
      -- al.create_mapping_hook("n", "o", al.new)
      -- al.create_mapping_hook("n", "O", al.new_before)

      require("autolist").setup()

      vim.keymap.set("i", "<tab>", "<cmd>AutolistTab<cr>")
      vim.keymap.set("i", "<s-tab>", "<cmd>AutolistShiftTab<cr>")
      -- vim.keymap.set("i", "<c-t>", "<c-t><cmd>AutolistRecalculate<cr>") -- an example of using <c-t> to indent
      vim.keymap.set("i", "<CR>", "<CR><cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "o", "o<cmd>AutolistNewBullet<cr>")
      vim.keymap.set("n", "O", "O<cmd>AutolistNewBulletBefore<cr>")
      vim.keymap.set("n", "<CR>", "<cmd>AutolistToggleCheckbox<cr><CR>")
      vim.keymap.set("n", "<C-r>", "<cmd>AutolistRecalculate<cr>")

      -- cycle list types with dot-repeat
      vim.keymap.set("n", "<localleader>cn", require("autolist").cycle_next_dr, { expr = true })
      vim.keymap.set("n", "<localleader>cp", require("autolist").cycle_prev_dr, { expr = true })
      -- if you don't want dot-repeat
      -- vim.keymap.set("n", "<leader>cn", "<cmd>AutolistCycleNext<cr>")
      -- vim.keymap.set("n", "<leader>cp", "<cmd>AutolistCycleNext<cr>")

      -- functions to recalculate list on edit
      vim.keymap.set("n", ">>", ">><cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "<<", "<<<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("n", "dd", "dd<cmd>AutolistRecalculate<cr>")
      vim.keymap.set("v", "d", "d<cmd>AutolistRecalculate<cr>")

      mega.iabbrev("-cc", "- [ ]")
      mega.iabbrev("cc", "[ ]")
      mega.iabbrev("cb", "[ ]")
    end,
  },
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
          dash_string = "󰇜",
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

  -- ( Syntax/Languages/langs ) ------------------------------------------------------
  { "ii14/emmylua-nvim", ft = "lua" },
  -- { "elixir-editors/vim-elixir", ft = "elixir" }, -- nvim exceptions thrown when not installed
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
  { "justinsgithub/wezterm-types" },
  {
    "axelvc/template-string.nvim",
    ft = {
      "typescript",
      "typescriptreact",
      "javascript",
      "javascriptreact",
    },
    config = false,
  },
  {
    "pmizio/typescript-tools.nvim",
    event = {
      "BufRead *.js,*.jsx,*.mjs,*.cjs,*ts,*tsx",
      "BufNewFile *.js,*.jsx,*.mjs,*.cjs,*ts,*tsx",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false

        vim.keymap.set(
          "n",
          "gD",
          "<Cmd>TSToolsGoToSourceDefinition<CR>",
          { buffer = bufnr, desc = "lsp (ts/tsx): go to source definition" }
        )

        vim.keymap.set(
          "n",
          "<localleader>li",
          "<Cmd>TSToolsAddMissingImports<CR>",
          { buffer = bufnr, desc = "lsp (ts/tsx): add missing imports" }
        )
        vim.keymap.set(
          "n",
          "<localleader>lo",
          "<Cmd>TSToolsOrganizeImports<CR>",
          { buffer = bufnr, desc = "lsp (ts/tsx): organize imports" }
        )
        vim.keymap.set(
          "n",
          "<localleader>lr",
          "<Cmd>TSToolsRemoveUnused<CR>",
          { buffer = bufnr, desc = "lsp (ts/tsx): remove unused imports" }
        )
        vim.keymap.set(
          "n",
          "<localleader>lf",
          "<Cmd>TSToolsFixAll<CR>",
          { buffer = bufnr, desc = "lsp (ts/tsx): fix all" }
        )
      end,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
      },
    },
  },
}
