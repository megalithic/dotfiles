return {
  -- ( CORE ) ------------------------------------------------------------------
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "mcchrish/zenbones.nvim",
    lazy = false,
    priority = 999,
    dependencies = "rktjmp/lush.nvim",
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!dirbuf" },
        buftype = { "*", "!prompt", "!nofile", "!dirbuf" },
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
  { "lukas-reineke/virt-column.nvim", config = { char = "│" }, event = "VimEnter" },
  {
    "mbbill/undotree",
    -- enabled = false,
    cmd = "UndotreeToggle",
    keys = { { "<leader>u", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
    config = function()
      vim.g.undotree_TreeNodeShape = "◦" -- Alternative: '◉'
      vim.g.undotree_SetFocusWhenToggle = 1
      vim.g.undotree_DiffCommand = "diff -u"
    end,
  },
  {
    "chrisgrieser/replacer.nvim",
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
          mega.nmap("q", vim.cmd.write, { desc = " Finish replacing", buffer = true, nowait = true })
        end,
      })

      -- { "<leader>R", function() require("replacer").run() end, desc = "qf: replace in qflist" },
      -- { "<C-r>", function() require("replacer").run() end, desc = "qf: replace in qflist" },
    end,
  },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    config = true,
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
      { "<leader><leader>h", function() require("smart-splits").swap_buf_left() end, desc = { "swap left" } },
      { "<leader><leader>j", function() require("smart-splits").swap_buf_down() end, { desc = "swap down" } },
      { "<leader><leader>k", function() require("smart-splits").swap_buf_up() end, { desc = "swap up" } },
      { "<leader><leader>l", function() require("smart-splits").swap_buf_right() end, { desc = "swap right" } },
    },
  },

  -- ( LSP ) -------------------------------------------------------------------
  "onsails/lspkind.nvim",
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "nvim-lua/lsp_extensions.nvim" },
      {
        "jose-elias-alvarez/typescript.nvim",
        ft = { "typescript", "typescriptreact" },
        dependencies = { "jose-elias-alvarez/null-ls.nvim" },
        config = function()
          -- require("typescript").setup({ server = require("mega.servers")("tsserver") })
          require("null-ls").register({
            sources = { require("typescript.extensions.null-ls.code-actions") },
          })
        end,
      },
      { "MunifTanjim/nui.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "b0o/schemastore.nvim" },
      { "mrshmllow/document-color.nvim", event = "BufReadPre" },
      {
        "mhanberg/output-panel.nvim",
        keys = {
          {
            "<localleader>lop",
            ":OutputPanel<CR>",
            desc = "lsp: open output panel",
          },
          {
            "<leader>lip",
            ":OutputPanel<CR>",
            desc = "open output panel",
          },
        },
        cmd = { "OutputPanel" },
        config = function() require("output_panel").setup() end,
      },
      {
        "mhanberg/control-panel.nvim",
        config = function()
          local cp = require("control_panel")
          cp.register({
            id = "output-panel",
            title = "Output Panel",
          })

          local handler = vim.lsp.handlers["window/logMessage"]

          vim.lsp.handlers["window/logMessage"] = function(err, result, context)
            handler(err, result, context)
            if not err then
              local client_id = context.client_id
              local client = vim.lsp.get_client_by_id(client_id)

              if not cp.panel("output-panel"):has_tab(client.name) then
                cp.panel("output-panel")
                  :tab({ name = client.name, key = tostring(#cp.panel("output-panel"):tabs() + 1) })
              end

              cp.panel("output-panel"):append({
                tab = client.name,
                text = "[" .. vim.lsp.protocol.MessageType[result.type] .. "] " .. result.message,
              })
            end
          end
        end,
      },
      {
        "elixir-tools/elixir-tools.nvim",
        ft = { "elixir", "eex", "heex", "surface" },
        config = function()
          local elixir = require("elixir")
          local elixirls = require("elixir.elixirls")

          elixir.setup({
            credo = {},
            elixirls = {
              -- cmd = fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh"),
              settings = elixirls.settings({
                dialyzerEnabled = true,
                dialyzerFormat = "dialyxir_long", -- alts: dialyxir_short
                dialyzerwarnopts = {},
                fetchDeps = false,
                enableTestLenses = false,
                suggestSpecs = true,
              }),
              log_level = vim.lsp.protocol.MessageType.Log,
              message_level = vim.lsp.protocol.MessageType.Log,
              on_attach = function(_client, _bufnr)
                vim.keymap.set(
                  "n",
                  "<localleader>efp",
                  ":ElixirFromPipe<cr>",
                  { buffer = true, noremap = true, desc = "elixir: from pipe" }
                )
                vim.keymap.set(
                  "n",
                  "<localleader>etp",
                  ":ElixirToPipe<cr>",
                  { buffer = true, noremap = true, desc = "elixir: to pipe" }
                )
                vim.keymap.set(
                  "v",
                  "<localleader>eem",
                  ":ElixirExpandMacro<cr>",
                  { buffer = true, noremap = true, desc = "elixir: expand macro" }
                )
              end,
            },
          })
        end,
        dependencies = {
          { "tpope/vim-projectionist", lazy = false },
          "nvim-lua/plenary.nvim",
        },
      },
      {
        "Fildo7525/pretty_hover",
        event = "LspAttach",
        opts = { border = mega.get_border() },
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
              border = require("mega.globals").get_border(),
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
    lazy = false,
    enabled = vim.g.explorer == "oil",
    cond = vim.g.explorer == "oil",
    opts = {
      trash = false,
      -- delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      restore_win_options = false,
      prompt_save_on_select_new_entry = false,
    },
    keys = {
      {
        "<leader>ed",
        function()
          -- vim.cmd([[vertical rightbelow split|vertical resize 60]])
          vim.cmd([[vertical rightbelow split]])
          require("oil").open()
        end,
        desc = "oil: toggle(vsplit)",
      },
      {
        "<leader>ee",
        function() require("oil").open() end,
        desc = "oil: open",
      },
    },
  },
  {
    "megalithic/dirbuf.nvim",
    dev = true,
    enabled = vim.g.explorer == "dirbuf",
    cond = vim.g.explorer == "dirbuf",
    keys = {
      {
        "<leader>ed",
        function()
          local buf = vim.api.nvim_buf_get_name(0)
          -- vim.cmd([[vertical topleft split|vertical resize 60]])
          vim.cmd([[vertical rightbelow split]])
          require("dirbuf").open(buf)
        end,
        desc = "dirbuf: toggle",
      },
      {
        "<leader>ee",
        function()
          local buf = vim.api.nvim_buf_get_name(0)
          -- vim.cmd([[vertical topleft split|vertical resize 60]])
          require("dirbuf").open(buf)
        end,
        desc = "dirbuf: toggle",
      },
    },
    cmd = { "Dirbuf", "DirbufQuit", "DirbufSync" },
    opts = {
      sort_order = "directories_first",
      devicons = true,
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
  -- {
  --   "mg979/vim-visual-multi",
  --   keys = { { "<C-e>", mode = { "n", "x" } }, "\\j", "\\k" },
  --   enabled = false,
  --   event = { "BufReadPost", "BufNewFile" },
  --   init = function()
  --     vim.g.VM_highlight_matches = "underline"
  --     vim.g.VM_theme = "codedark"
  --     vim.g.VM_maps = {
  --       ["Find Word"] = "<C-E>",
  --       ["Find Under"] = "<C-E>",
  --       ["Find Subword Under"] = "<C-E>",
  --       ["Select Cursor Down"] = "\\j",
  --       ["Select Cursor Up"] = "\\k",
  --     }
  --   end,
  -- },
  {
    "mg979/vim-visual-multi",
    lazy = false,
    init = function()
      vim.g.VM_highlight_matches = "underline"
      vim.g.VM_theme = "codedark"
      vim.g.VM_maps = {
        ["Find Word"] = "<M-e>",
        ["Find Under"] = "<M-e>",
        ["Find Subword Under"] = "<M-e>",
        ["Select Cursor Down"] = "\\j",
        ["Select Cursor Up"] = "\\k",
      }
    end,
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
      M.snippet_engine = "luasnip"
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
    event = "BufReadPre",
    config = function()
      vim.g.matchup_surround_enabled = true
      vim.g.matchup_matchparen_deferred = true
      vim.g.matchup_matchparen_nomode = "i"
      vim.g.matchup_matchparen_deferred_show_delay = 400
      vim.g.matchup_matchparen_deferred_hide_delay = 400
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
        -- fullwidth = true,
        highlight = "Normal",
        border = "none",
      }

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
  {
    "linty-org/readline.nvim",
    keys = {
      { "<C-f>", function() require("readline").forward_word() end, mode = "!" },
      { "<C-b>", function() require("readline").backward_word() end, mode = "!" },
      { "<C-a>", function() require("readline").beginning_of_line() end, mode = "!" },
      { "<C-e>", function() require("readline").end_of_line() end, mode = "!" },
      { "<M-d>", function() require("readline").kill_word() end, mode = "!" },
      { "<M-BS>", function() require("readline").backward_kill_word() end, mode = "!" },
      { "<C-w>", function() require("readline").unix_word_rubout() end, mode = "!" },
      { "<C-k>", function() require("readline").kill_line() end, mode = "!" },
      { "<C-u>", function() require("readline").backward_kill_line() end, mode = "!" },
    },
  },
  { "axelvc/template-string.nvim", ft = { "typescript", "javascript", "typescriptreact", "javascriptreact" } },

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
    event = { "InsertEnter" },
    keys = { "<Tab>", "<S-Tab>", "<C-t>", "<C-d>" },
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
  { "iamcco/markdown-preview.nvim", ft = "markdown", build = "cd app && yarn install" },
  {
    "ekickx/clipboard-image.nvim",
    ft = "markdown",
    config = true,
  },
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
  -- {
  --   "gaoDean/autolist.nvim",
  --   ft = { "markdown" },
  --   config = function()
  --     local autolist = require("autolist")
  --     autolist.setup()
  --     autolist.create_mapping_hook("i", "<CR>", autolist.new)
  --     autolist.create_mapping_hook("i", "<Tab>", autolist.indent)
  --     autolist.create_mapping_hook("i", "<S-Tab>", autolist.indent, "<C-D>")
  --     autolist.create_mapping_hook("n", "o", autolist.new)
  --     autolist.create_mapping_hook("n", "O", autolist.new_before)
  --     autolist.create_mapping_hook("n", ">>", autolist.indent)
  --     autolist.create_mapping_hook("n", "<<", autolist.indent)
  --     autolist.create_mapping_hook("n", "<C-r>", autolist.force_recalculate)
  --     autolist.create_mapping_hook("n", "<leader>x", autolist.invert_entry, "")
  --     autolist.create_mapping_hook("n", "<C-c>", autolist.invert_entry, "")
  --     vim.api.nvim_create_autocmd("TextChanged", {
  --       pattern = "*",
  --       callback = function() vim.cmd.normal({ autolist.force_recalculate(nil, nil), bang = false }) end,
  --     })
  --   end,
  -- },
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

  -- ( Syntax/Languages ) ------------------------------------------------------
  { "ii14/emmylua-nvim", ft = "lua" },
  { "elixir-editors/vim-elixir", ft = { "markdown" } }, -- nvim exceptions thrown when not installed
  "kchmck/vim-coffee-script",
  "briancollins/vim-jst",
  { "imsnif/kdl.vim", ft = "kdl" },
  { "chr4/nginx.vim", ft = "nginx" },
  { "fladson/vim-kitty", ft = "kitty" },
  { "SirJson/fzf-gitignore", config = function() vim.g.fzf_gitignore_no_maps = true end },
  { "boltlessengineer/bufterm.nvim", config = true, cmd = { "BufTermEnter", "BufTermNext", "BufTermPrev" } },
  {
    "mrossinek/zen-mode.nvim",
    cmd = { "ZenMode" },
    keys = { { "<localleader>zz", "<cmd>ZenMode<cr>", desc = "Zen Mode" } },
    opts = {
      window = {
        options = {
          foldcolumn = "0",
          number = false,
          relativenumber = false,
          scrolloff = 999,
          signcolumn = "no",
        },
      },
      plugins = {
        tmux = {
          enabled = true,
        },
        wezterm = {
          enabled = true,
          font = "+8",
        },
      },
    },
  },
}
