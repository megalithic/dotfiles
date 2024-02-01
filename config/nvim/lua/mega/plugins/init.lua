return {
  -- ( CORE ) ------------------------------------------------------------------
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    config = function()
      mega.pcall("theme failed to load because", function(colorscheme)
        local theme = fmt("mega.lush_theme.%s", colorscheme)
        local ok, lush_theme = pcall(require, theme)

        if ok then
          vim.g.colors_name = colorscheme
          package.loaded[theme] = nil

          require("lush")(lush_theme)
        else
          pcall(vim.cmd.colorscheme, colorscheme)
        end

        -- NOTE: always make available my lushified-color palette
        -- mega.colors = require("mega.lush_theme.colors")
      end, vim.g.colorscheme)

      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  {
    "megalithic/bamboo.nvim",
    cond = vim.g.colorscheme == "bamboo",
    lazy = false,
    priority = 1001,
    config = function()
      require("bamboo").setup({
        style = "megaforest", -- alts: megaforest, multiplex, vulgaris, light
        -- transparent = true,
        dim_inactive = true,
        highlights = {
          -- make comments blend nicely with background, similar to other color schemes
          -- ["@comment"] = { fg = "$grey" },
          -- ["@keyword"] = { fg = "$green" },
          -- ["@string"] = { fg = "$bright_orange", bg = "#00ff00", fmt = "bold" },
          -- ["@function"] = { fg = "#0000ff", sp = "$cyan", fmt = "underline,italic" },
          -- ["@function.builtin"] = { fg = "#0059ff" },
          --
          CursorLineNr = { fg = "$orange", fmt = "bold,italic" },
          -- TSKeyword = { fg = "$green" },
          -- TSString = { fg = "$bright_orange", bg = "#00ff00", fmt = "bold" },
          -- TSFunction = { fg = "#0000ff", sp = "$cyan", fmt = "underline,italic" },
          -- TSFuncBuiltin = { fg = "#0059ff" },
        },
      })

      require("bamboo").load()
    end,
  },
  -- {
  --   "ribru17/bamboo.nvim",
  --   lazy = false,
  --   priority = 1001,
  --   opts = {
  --     style = "multiplex", -- alts: multiplex, vulgaris, light
  --     transparent = true,
  --     dim_inactive = true,
  --     -- colors = {
  --     --   multiplex = require("mega.lush_theme.colors"),
  --     -- },
  --   },
  --   -- config = function(opts)
  --   --   require("bamboo").setup(opts)
  --   --   mega.colors = require("mega.lush_theme.colors")
  --   -- end,
  -- },
  {
    "sainnhe/everforest",
    cond = false,
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_background = "soft"
      vim.g.everforest_better_performance = true
    end,
  },

  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("everforest").setup({
        dim_inactive_windows = true,
        transparent_background_level = 2,
        background = "medium",
        italics = true,
      })
    end,
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
  {
    "lukas-reineke/indent-blankline.nvim",
    event = { "VeryLazy" },
    main = "ibl",
    opts = {
      indent = {
        char = "┊",
        smart_indent_cap = true,
      },
      scope = {
        enabled = false,
      },
      exclude = { filetypes = { "markdown" } },
    },
  },
  { "Bekaboo/deadcolumn.nvim" },
  -- {
  --   "luukvbaal/statuscol.nvim",
  --   cond = not vim.g.enabled_plugin["megacolumn"],
  --   event = { "VeryLazy" },
  --   config = function()
  --     local builtin = require("statuscol.builtin")
  --     require("statuscol").setup({
  --       relculright = true,
  --       segments = {
  --         { text = { builtin.foldfunc }, click = "v:lua.ScFa" },
  --         { text = { builtin.lnumfunc }, click = "v:lua.ScLa" },
  --         {
  --           sign = { name = { ".*" }, maxwidth = 2, colwidth = 1 },
  --           click = "v:lua.ScSa",
  --         },
  --       },
  --     })
  --   end,
  -- },

  -- {
  --   "luukvbaal/statuscol.nvim",
  --   cond = not vim.g.enabled_plugin["megacolumn"],
  --   branch = "0.10",
  --   -- event = { "VeryLazy" },
  --   opts = function()
  --     local builtin = require("statuscol.builtin")
  --
  --     return {
  --       bt_ignore = { "nofile", "terminal" },
  --       segments = {
  --         {
  --           sign = {
  --             name = { ".*" },
  --             text = { ".*" },
  --           },
  --           click = "v:lua.ScSa",
  --         },
  --         {
  --           text = { builtin.lnumfunc },
  --           condition = { true, builtin.not_empty },
  --           click = "v:lua.ScLa",
  --         },
  --         {
  --           sign = { namespace = { "gitsigns" }, colwidth = 1, wrap = true },
  --           click = "v:lua.ScSa",
  --         },
  --         {
  --           text = {
  --             function(args)
  --               args.fold.close = ""
  --               args.fold.open = ""
  --               args.fold.sep = " "
  --               return builtin.foldfunc(args)
  --             end,
  --           },
  --           click = "v:lua.ScFa",
  --         },
  --       },
  --     }
  --   end,
  --   -- opts = function()
  --   --   local builtin = require("statuscol.builtin")
  --   --
  --   --   return {
  --   --     -- setopt = true,
  --   --     bt_ignore = { "nofile", "terminal" },
  --   --     relculright = true,
  --   --     segments = {
  --   --       -- {
  --   --       --   text = {
  --   --       --     function(args)
  --   --       --       args.fold.close = ""
  --   --       --       args.fold.open = ""
  --   --       --       args.fold.sep = " "
  --   --       --       return builtin.foldfunc(args)
  --   --       --     end,
  --   --       --   },
  --   --       --   click = "v:lua.ScFa",
  --   --       -- },
  --   --       -- {
  --   --       --   text = { " ", builtin.foldfunc, " " },
  --   --       --   condition = {
  --   --       --     builtin.not_empty,
  --   --       --     true,
  --   --       --     builtin.not_empty,
  --   --       --   },
  --   --       --   click = "v:lua.ScFa",
  --   --       -- },
  --   --       { text = { builtin.foldfunc, " " }, click = "v:lua.ScFa", hl = "Comment" },
  --   --       { sign = { name = { ".*" }, namespace = { "gitsigns" }, colwidth = 1, wrap = true }, click = "v:lua.ScSa" },
  --   --       -- {
  --   --       --   sign = {
  --   --       --     name = { ".*" },
  --   --       --     text = { ".*" },
  --   --       --   },
  --   --       --   click = "v:lua.ScSa",
  --   --       -- },
  --   --       {
  --   --         text = { builtin.lnumfunc, colwidth = 2 },
  --   --         condition = { true, builtin.not_empty },
  --   --         click = "v:lua.ScLa",
  --   --       },
  --   --     },
  --   --   }
  --   -- end,
  -- },
  {
    "echasnovski/mini.indentscope",
    version = "*",
    main = "mini.indentscope",
    event = { "VeryLazy" },
    opts = {
      symbol = "┊", -- alts: ┊│┆ ┊  ▎││ ▏▏
      -- mappings = {
      --   goto_top = "<leader>k",
      --   goto_bottom = "<leader>j",
      -- },
      options = {
        try_as_border = true,
      },
      draw = {
        animation = function() return 0 end,
      },
    },
  },
  {
    "echasnovski/mini.pick",
    cmd = "Pick",
    opts = {},
  },
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    config = function()
      require("mini.comment").setup({
        ignore_blank_lines = true,
        hooks = {
          pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
        },
        mappings = {
          -- Toggle comment (like `gcip` - comment inner paragraph) for both
          -- Normal and Visual modes
          comment = "gc",

          -- Toggle comment on current line
          comment_line = "gcc",

          -- Toggle comment on visual selection
          comment_visual = "gc",

          -- Define 'comment' textobject (like `dgc` - delete whole comment block)
          textobject = "gc",
        },
      })
    end,
  },
  {
    "echasnovski/mini.splitjoin",
    cond = false,
    keys = { "gJ", "gS", "gs", "gj" },
    config = function()
      require("mini.splitjoin").setup({
        mappings = {
          toggle = "gJ",
          split = "gS",
          join = "gJ",
        },
      })
    end,
  },
  {
    -- NOTE: only using for `gct` binding in mappings.lua
    "numToStr/Comment.nvim",
    opts = true,
  },
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    -- keys = { { "<leader>U", "<Cmd>UndotreeToggle<CR>", desc = "undotree: toggle" } },
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
  -- {
  --   "gabrielpoca/replacer.nvim",
  --   ft = { "qf", "quickfix" },
  --   keys = {
  --     -- { "<leader>R", function() require("replacer").run() end, desc = "qf: replace in qflist" },
  --     -- { "<C-r>", function() require("replacer").run() end, desc = "qf: replace in qflist" },
  --   },
  --   init = function()
  --     -- save & quit via "q"
  --     mega.augroup("ReplacerFileType", {
  --       pattern = "replacer",
  --       callback = function()
  --         mega.nmap("q", vim.cmd.write, { desc = " done replacing", buffer = true, nowait = true })
  --       end,
  --     })
  --     -- mega.nnoremap(
  --     --   "<leader>r",
  --     --   function() require("replacer").run() end,
  --     --   { desc = "qf: replace in qflist", nowait = true }
  --     -- )
  --   end,
  -- },
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
  -- {
  --   "chentoast/marks.nvim",
  --   cond = false,
  --   event = "VeryLazy",
  --   keys = {
  --     { "<leader>mm", "<Cmd>MarksListBuf<CR>", desc = "marks: list buffer marks" },
  --     { "<leader>mg", "<Cmd>MarksListBuf<CR>", desc = "marks: list global marks" },
  --     { "<leader>mb", "<Cmd>MarksListBuf<CR>", desc = "marks: list bookmark marks" },
  --     { "m/", "<cmd>MarksListAll<CR>", desc = "Marks from all opened buffers" },
  --     { "<leader>mt", "<cmd>MarksToggleSigns<cr>", desc = "Toggle marks" },
  --     -- { 'm', '<Plug>(Marks-set)', '<Plug>(Marks-toggle)' },
  --   },
  --   opts = {
  --     sign_priority = { lower = 10, upper = 15, builtin = 8, bookmark = 20 },
  --     bookmark_1 = { sign = "󰈼" }, -- ⚐ ⚑ 󰈻 󰈼 󰈽 󰈾 󰈿 󰉀
  --     default_mappings = false, -- whether to map keybinds or not. default true
  --     builtin_marks = {}, -- which builtin marks to show. default {}
  --     cyclic = true, -- whether movements cycle back to the beginning/end of buffer. default true
  --     force_write_shada = false, -- whether the shada file is updated after modifying uppercase marks. default false
  --     -- bookmark_0 = { -- marks.nvim allows you to configure up to 10 bookmark groups, each with its own sign/virttext
  --     --   sign = "⚑",
  --     --   virt_text = "hello world",
  --     -- },
  --     mappings = {
  --       set_next = "m,",
  --       next = "m]",
  --       preview = "m;",
  --       set_bookmark0 = "m0",
  --       prev = false, -- pass false to disable only this default mapping
  --       annotate = "m<Space>",
  --     },
  --     excluded_filetypes = {
  --       "DressingInput",
  --       "gitcommit",
  --       "NeogitCommitMessage",
  --       "NeogitNotification",
  --       "NeogitStatus",
  --       "NeogitStatus",
  --       "NvimTree",
  --       "Outline",
  --       "OverseerForm",
  --       "dropbar_menu",
  --       "lazy",
  --       "lspinfo",
  --       "megaterm",
  --       "neo-tree",
  --       "neo-tree-popup",
  --       "noice",
  --       "notify",
  --       "null-ls-info",
  --       "registers",
  --       "toggleterm",
  --       "toggleterm",
  --     },
  --   },
  -- },

  --   "stevearc/overseer.nvim", -- Task runner and job management
  --   keys = {
  --     { "<leader>or", "<cmd>OverseerRun<cr>", desc = "overseer: run task" },
  --     { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "overseer: toggle tasks" },
  --   },
  --   opts = {
  --     strategy = {
  --       "terminal",
  --       use_shell = true,
  --     },
  --     form = {
  --       border = mega.get_border(),
  --     },
  --     task_list = { direction = "right" },
  --     templates = { "builtin", "global" },
  --     component_aliases = {
  --       default_neotest = {
  --         "unique",
  --         { "on_complete_notify", system = "unfocused", on_change = true },
  --         "default",
  --         "on_output_summarize",
  --         "on_exit_set_status",
  --         "on_complete_dispose",
  --       },
  --     },
  --   },
  -- },

  -- {
  --   "jcdickinson/codeium.nvim",
  --   cond = false,
  --   lazy = true,
  --   event = "VeryLazy",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --   },
  --   opts = true,
  -- },
  -- {
  --   "Exafunction/codeium.nvim",
  --   cmd = { "Codeium" },
  --   lazy = false,
  --   -- event = "VeryLazy",
  --   init = function()
  --     vim.g.codeium_disable_bindings = 1
  --     vim.g.codeium_enabled = true
  --     --   vim.g.codeium_filetypes = {
  --     --     rust = true,
  --     --     go = true,
  --     --     lua = true,
  --     --     markdown = true,
  --     --     norg = true,
  --     --     zsh = true,
  --     --     bash = true,
  --     --     txt = true,
  --     --     js = true,
  --     --     elixir = true,
  --     --     erlang = true,
  --     --   }
  --   end,
  --   build = ":Codeium Auth",
  --   keys = {
  --     { mode = { "n" }, "<leader>Ce", ":Codeium Enable<CR>", { silent = true, desc = "codeium: enable" } },
  --     { mode = { "n" }, "<leader>Cd", ":Codeium Disable<CR>", { silent = true, desc = "codeium: disable" } },
  --   },
  --   config = function()
  --     vim.keymap.set("i", "<C-t>", function() return vim.fn["codeium#Accept"]() end, { expr = true })
  --     -- vim.keymap.set("i", "<M-]>", function() return vim.fn["codeium#CycleCompletions"](1) end, { expr = true })
  --     -- vim.keymap.set("i", "<M-[>", function() return vim.fn["codeium#CycleCompletions"](-1) end, { expr = true })
  --     vim.keymap.set("i", "<C-e>", function() return vim.fn["codeium#Clear"]() end, { expr = true })
  --   end,
  -- },

  -- {
  --   "David-Kunz/gen.nvim",
  --   cmd = { "Gen" },
  --   keys = {
  --     { "<leader>]", ":Gen<CR>", mode = "v" },
  --     { "<leader>]", ":Gen<CR>", mode = "n" },
  --   },
  -- },

  {
    "David-Kunz/gen.nvim",
    cmd = "Gen",
    opts = {
      model = "deepseek-coder",
      display_mode = "split", -- The display mode. Can be "float" or "split".
      show_prompt = true, -- Shows the Prompt submitted to Ollama.
      show_model = true, -- Displays which model you are using at the beginning of your chat session.
      no_auto_close = true, -- Never closes the window automatically.
      init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
      -- Function to initialize Ollama
      command = "curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body",
    },
    config = function(_, opts)
      require("gen").setup(opts)
      require("gen").prompts["Elaborate_Text"] = {
        prompt = "Elaborate the following text:\n$text",
        replace = true,
      }
      require("gen").prompts["Fix_Code"] = {
        prompt = "Fix the following code. Only ouput the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```",
        replace = true,
        extract = "```$filetype\n(.-)```",
      }
      require("gen").prompts["DevOps me!"] = {
        prompt = "You are a senior devops engineer, acting as an assistant. You offer help with cloud technologies like: Terraform, AWS, kubernetes, python. You answer with code examples when possible. $input:\n$text",
        replace = true,
      }

      local icn = {
        Chat = "", --     
        Test = "", --    
        Regex = "", --   
        Comment = "", --  
        Code = "", --   
        Text = "", --   
        Items = "", --    
        Swap = "", -- 
        Keep = "", --  
        into = "", --  
      }

      require("gen").prompts = {
        [icn.Chat .. " Ask about given context " .. icn.Keep] = {
          prompt = "Regarding the following text, $input:\n$text",
          model = "mistral",
        },
        [icn.Chat .. " Chat about anything " .. icn.Keep] = {
          prompt = "$input",
          model = "mistral",
        },
        [icn.Regex .. " Regex create " .. icn.Swap] = {
          prompt = "Create a regular expression for $filetype language that matches the following pattern:\n```$filetype\n$text\n```",
          replace = true,
          no_auto_close = false,
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Regex .. " Regex explain " .. icn.Keep] = {
          prompt = "Explain the following regular expression:\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Comment .. " Code " .. icn.into .. " JSDoc " .. icn.Keep] = {
          prompt = "Write JSDoc comments for the following $filetype code:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Comment .. " JSDoc " .. icn.into .. " Code " .. icn.Keep] = {
          prompt = "Read the following comment and create the $filetype code below it:\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Test .. " Unit Test add missing (React/Jest) " .. icn.Keep] = {
          prompt = "Read the following $filetype code that includes some unit tests inside the 'describe' function. We are using Jest with React testing library, and the main component is reused by the tests via the customRender function. Detect if we have any missing unit tests and create them.\n```$filetype\n$text\n```",
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Code suggestions " .. icn.Keep] = {
          prompt = "Review the following $filetype code and make concise suggestions:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Explain code " .. icn.Keep] = {
          prompt = "Explain the following $filetype code in a very concise way:\n```$filetype\n$text\n```",
          model = "deepseek-coder",
        },
        [icn.Code .. " Fix code " .. icn.Swap] = {
          prompt = "Fix the following $filetype code:\n```$filetype\n$text\n```",
          replace = true,
          no_auto_close = false,
          extract = "```$filetype\n(.-)```",
          model = "deepseek-coder",
        },
        [icn.Items .. " Text " .. icn.into .. " List of items " .. icn.Swap] = {
          prompt = "Convert the following text, except for the code blocks, into a markdown list of items without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Items .. " List of items " .. icn.into .. " Text " .. icn.Swap] = {
          prompt = "Convert the following list of items into a block of text, without additional quotes around it. Modify the resulting text if needed to use better wording.\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Fix Grammar / Syntax in text " .. icn.Swap] = {
          prompt = "Fix the grammar and syntax in the following text, except for the code blocks, and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Reword text " .. icn.Swap] = {
          prompt = "Modify the following text, except for the code blocks, to use better wording, and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Simplify text " .. icn.Swap] = {
          prompt = "Modify the following text, except for the code blocks, to make it as simple and concise as possible and without additional quotes around it:\n$text",
          replace = true,
          no_auto_close = false,
          model = "mistral",
        },
        [icn.Text .. " Summarize text " .. icn.Keep] = {
          prompt = "Summarize the following text, except for the code blocks, without additional quotes around it:\n$text",
          model = "mistral",
        },
      }
    end,
  },

  {
    "monaqa/dial.nvim",
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
          augend.constant.new({ elements = { ":ok", ":error" } }),
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
      {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        opts = {
          ensure_installed = {
            "prettierd",
            "prettier",
            "stylua",
            "eslint_d",
            "isort",
            "black",
            "eslint_d",
            -- "rubocop",
            "ruff",
          },
          automatic_installation = true,
        },
      },
      {
        "williamboman/mason.nvim",
        config = function()
          local tools = {
            "prettierd",
            "prettier",
            "stylua",
            "selene",
            "luacheck",
            -- "fixjson",
            -- "eslint_d",
            "shellcheck",
            -- "deno",
            "shfmt",
            -- "goimports",
            -- "black",
            -- "isort",
            -- "flake8",
            -- "cbfmt",
            -- "buf",
            -- "elm-format",
            "yamlfmt",
          }

          require("mason").setup()
          local mr = require("mason-registry")
          for _, tool in ipairs(tools) do
            local p = mr.get_package(tool)
            if not p:is_installed() then p:install() end
          end

          require("mason-lspconfig").setup({
            automatic_installation = true,
          })
        end,
      },
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
      { "williamboman/mason-lspconfig.nvim" },
      { "b0o/schemastore.nvim" },
      { "ray-x/lsp_signature.nvim" },
      -- {
      --   "j-hui/fidget.nvim",
      --   config = function()
      --     require("fidget").setup({
      --       progress = {
      --         display = {
      --           done_icon = "✓",
      --         },
      --       },
      --       notification = {
      --         view = {
      --           group_separator = "─────", -- digraph `hh`
      --         },
      --         window = {
      --           winblend = 0,
      --         },
      --       },
      --     })
      --   end,
      -- },
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
      {
        "Wansmer/symbol-usage.nvim",
        cond = false,
        event = "LspAttach",
        opts = {
          text_format = function(symbol)
            local res = {}
            local ins = table.insert

            -- local round_start = { "", "SymbolUsageRounding" }
            -- local round_end = { "", "SymbolUsageRounding" }

            if symbol.references then
              local usage = symbol.references <= 1 and "usage" or "usages"
              local num = symbol.references == 0 and "no" or symbol.references
              -- ins(res, round_start)
              ins(res, { "󰌹 ", "SymbolUsageRef" })
              ins(res, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            if symbol.definition then
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_start)
              ins(res, { "󰳽 ", "SymbolUsageDef" })
              ins(res, { symbol.definition .. " defs", "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            if symbol.implementation then
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_start)
              ins(res, { "󰡱 ", "SymbolUsageImpl" })
              ins(res, { symbol.implementation .. " impls", "SymbolUsageContent" })
              if #res > 0 then table.insert(res, { " ", "NonText" }) end
              -- ins(res, round_end)
            end

            return res
          end,
          -- text_format = function(symbol)
          --   local fragments = {}
          --
          --   if symbol.references then
          --     local usage = symbol.references <= 1 and "usage" or "usages"
          --     local num = symbol.references == 0 and "no" or symbol.references
          --     table.insert(fragments, { ("%s %s"):format(num, usage), "SymbolUsageContent" })
          --   end
          --
          --   if symbol.definition then
          --     table.insert(fragments, { symbol.definition .. " defs", "SymbolUsageContent" })
          --   end
          --
          --   if symbol.implementation then
          --     table.insert(fragments, { symbol.implementation .. " impls", "SymbolUsageContent" })
          --   end
          --
          --   -- return table.concat(fragments, ", ")
          --   return fragments
          -- end,
        },
      },
    },
  },
  {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    enabled = vim.g.explorer == "oil",
    cond = vim.g.explorer == "oil",
    config = function()
      local icons = mega.icons
      local icon_file = vim.trim(icons.lsp.kind.File)
      local icon_dir = vim.trim(icons.lsp.kind.Folder)
      local permission_hlgroups = setmetatable({
        ["-"] = "OilPermissionNone",
        ["r"] = "OilPermissionRead",
        ["w"] = "OilPermissionWrite",
        ["x"] = "OilPermissionExecute",
      }, {
        __index = function() return "OilDir" end,
      })

      local type_hlgroups = setmetatable({
        ["-"] = "OilTypeFile",
        ["d"] = "OilTypeDir",
        ["f"] = "OilTypeFifo",
        ["l"] = "OilTypeLink",
        ["s"] = "OilTypeSocket",
      }, {
        __index = function() return "OilTypeFile" end,
      })

      require("oil").setup({
        trash = false,
        skip_confirm_for_simple_edits = true,
        trash_command = "trash-cli",
        prompt_save_on_select_new_entry = false,
        use_default_keymaps = false,
        is_always_hidden = function(name, _bufnr) return name == ".." end,
        -- columns = {
        --   "icon",
        --   -- "permissions",
        --   -- "size",
        --   -- "mtime",
        -- },

        columns = {
          {
            "type",
            icons = {
              directory = "d",
              fifo = "f",
              file = "-",
              link = "l",
              socket = "s",
            },
            highlight = function(type_str) return type_hlgroups[type_str] end,
          },
          {
            "permissions",
            highlight = function(permission_str)
              local hls = {}
              for i = 1, #permission_str do
                local char = permission_str:sub(i, i)
                table.insert(hls, { permission_hlgroups[char], i - 1, i })
              end
              return hls
            end,
          },
          { "size", highlight = "Special" },
          { "mtime", highlight = "Number" },
          {
            "icon",
            default_file = icon_file,
            directory = icon_dir,
            add_padding = false,
          },
        },
        view_options = {
          show_hidden = true,
        },
        keymaps = {
          ["g?"] = "actions.show_help",
          ["gs"] = "actions.change_sort",
          ["gx"] = "actions.open_external",
          ["g."] = "actions.toggle_hidden",
          ["gd"] = {
            desc = "Toggle detail view",
            callback = function()
              local oil = require("oil")
              local config = require("oil.config")
              if #config.columns == 1 then
                oil.set_columns({ "icon", "permissions", "size", "mtime" })
              else
                oil.set_columns({ "type", "icon" })
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
      })
    end,
    keys = {
      {
        "<leader>ev",
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
  { "kevinhwang91/nvim-bqf", ft = "qf", opts = {
    preview = {
      winblend = 0,
    },
  } },
  {
    "yorickpeterse/nvim-pqf",
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
        show_multiple_lines = true,
        max_filename_length = 40,
      })
    end,
  },
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    opts = {
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
    config = true,
    cmd = { "RegexplainerShowSplit", "RegexplainerShowPopup", "RegexplainerHide", "RegexplainerToggle" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "MunifTanjim/nui.nvim",
    },
  },
  {
    "altermo/ultimate-autopair.nvim",
    event = { "VeryLazy" },
    branch = "v0.6", --recomended as each new version will have breaking changes
    opts = {
      cmap = false,
    },
  },
  { "tpope/vim-dispatch" },
  {
    cond = false or not vim.g.started_by_firenvim,
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
      local border = { style = mega.get_border(), highlight = "PickerBorder" }
      require("chatgpt").setup({
        popup_window = { border = border },
        popup_input = { border = border, submit = "<C-y>" },
        settings_window = { border = border },
        -- async_api_key_cmd = "pass show api/openai",
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
      "nvim-telescope/telescope.nvim",
    },
  },
  -- {
  --   "tdfacer/explain-it.nvim",
  --   requires = {
  --     "rcarriga/nvim-notify",
  --   },
  --   config = function()
  --     require("explain-it").setup({
  --       -- Prints useful log messages
  --       debug = true,
  --       -- Customize notification window width
  --       max_notification_width = 20,
  --       -- Retry API calls
  --       max_retries = 3,
  --       -- Customize response text file persistence location
  --       output_directory = "/tmp/chat_output",
  --       -- Toggle splitting responses in notification window
  --       split_responses = false,
  --       -- Set token limit to prioritize keeping costs low, or increasing quality/length of responses
  --       token_limit = 2000,
  --     })
  --   end,
  -- },
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
    dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/vim-vsnip" },
    keys = {
      -- {
      --   "gcd",
      --   function() require("neogen").generate({}) end,
      --   desc = "comment: neogen comment",
      -- },
      {
        "<leader>cc",
        function() require("neogen").generate({}) end,
        desc = "comment: neogen comment",
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
  -- {
  --   "ojroques/nvim-osc52",
  --   -- Only change the clipboard if we're in a SSH session
  --   cond = os.getenv("SSH_CLIENT") ~= nil and (os.getenv("TMUX") ~= nil or vim.fn.has("nvim-0.10") == 0),
  --   config = function()
  --     local osc52 = require("osc52")
  --     local function copy(lines, _) osc52.copy(table.concat(lines, "\n")) end
  --
  --     local function paste() return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") } end
  --
  --     vim.g.clipboard = {
  --       name = "osc52",
  --       copy = { ["+"] = copy, ["*"] = copy },
  --       paste = { ["+"] = paste, ["*"] = paste },
  --     }
  --   end,
  -- },
  { "tpope/vim-rhubarb", event = { "VeryLazy" } },
  { "tpope/vim-repeat", lazy = false },
  { "tpope/vim-unimpaired", event = { "VeryLazy" } },
  { "tpope/vim-apathy", event = { "VeryLazy" } },
  { "tpope/vim-scriptease", event = { "VeryLazy" }, cmd = { "Messages", "Mess", "Noti" } },
  { "lambdalisue/suda.vim", event = { "VeryLazy" } },
  { "EinfachToll/DidYouMean", event = { "BufNewFile" }, init = function() vim.g.dym_use_fzf = true end },
  { "ConradIrwin/vim-bracketed-paste" }, -- FIXME: delete?
  { "ryvnf/readline.vim", event = "CmdlineEnter" },

  -- ( Motions/Textobjects ) ---------------------------------------------------
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      jump = { nohlsearch = true, autojump = false },
      prompt = {
        -- Place the prompt above the statusline.
        win_config = { row = -3 },
      },
      search = {
        multi_window = false,
        mode = "exact",
        exclude = {
          "cmp_menu",
          "flash_prompt",
          "qf",
          function(win)
            -- Floating windows from bqf.
            if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):match("BqfPreview") then return true end

            -- Non-focusable windows.
            return not vim.api.nvim_win_get_config(win).focusable
          end,
        },
      },
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
      {
        "r",
        function() require("flash").remote() end,
        mode = "o",
        desc = "Remote Flash",
      },
      {
        "<c-s>",
        function() require("flash").toggle() end,
        mode = { "c" },
        desc = "Toggle Flash Search",
      },
      {
        "R",
        function() require("flash").treesitter_search() end,
        mode = { "o", "x" },
        desc = "Flash Treesitter Search",
      },
    },
  },
  -- {
  --   "Wansmer/treesj",
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     {
  --       "AndrewRadev/splitjoin.vim",
  --       init = function()
  --         vim.g.splitjoin_split_mapping = ""
  --         vim.g.splitjoin_join_mapping = ""
  --       end,
  --     },
  --   },
  --   cmd = {
  --     "TSJSplit",
  --     "TSJJoin",
  --     "TSJToggle",
  --     "SplitjoinJoin",
  --     "SplitjoinSplit",
  --     "SplitjoinToggle",
  --   },
  --   keys = {
  --     {
  --       "gJ",
  --       function()
  --         if require("treesj.langs")["presets"][vim.bo.filetype] then
  --           vim.cmd("TSJToggle")
  --         else
  --           vim.cmd("SplitjoinToggle")
  --         end
  --       end,
  --       desc = "splitjoin: toggle lines",
  --     },
  --   },
  --   opts = {
  --     use_default_keymaps = false,
  --     max_join_length = tonumber(vim.g.default_colorcolumn),
  --   }, -- config = function()
  --   --   require("treesj").setup({ use_default_keymaps = false, max_join_length = 150 })
  --   --
  --   --   mega.augroup("SplitJoin", {
  --   --     event = { "FileType" },
  --   --     pattern = "*",
  --   --     command = function()
  --   --       if require("treesj.langs")["presets"][vim.bo.filetype] then
  --   --         mega.nnoremap("gJ", ":TSJToggle<cr>", { desc = "splitjoin: toggle lines", buffer = true })
  --   --       else
  --   --         mega.nnoremap("gJ", ":SplitjoinToggle<cr>", { desc = "splitjoin: toggle lines", buffer = true })
  --   --       end
  --   --     end,
  --   --   })
  --   -- end,
  -- },

  -- ( Notes/Docs ) ------------------------------------------------------------
  {
    cond = false,
    "toppair/peek.nvim",
    build = "deno task --quiet build:fast",
    ft = { "markdown" },
    keys = { { "<localleader>mp", "<cmd>Peek<cr>", desc = "markdown: peek preview" } },
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
    event = {
      "BufRead **.md,**.neorg,**.org",
      "BufNewFile **.md,**.neorg,**.org",
    },
    version = "2.3.0",
    config = function()
      local al = require("autolist")
      al.setup()
      al.create_mapping_hook("i", "<CR>", al.new)
      al.create_mapping_hook("i", "<Tab>", al.indent)
      al.create_mapping_hook("i", "<S-Tab>", al.indent, "<C-d>")
      al.create_mapping_hook("n", "o", al.new)
      al.create_mapping_hook("n", "<C-c>", al.invert_entry)
      al.create_mapping_hook("n", "<C-x>", al.invert_entry)
      al.create_mapping_hook("n", "O", al.new_before)
    end,
  },
  {
    "lukas-reineke/headlines.nvim",
    event = {
      "BufRead **.md,**.yaml,**.neorg,**.org",
      "BufNewFile **.md,**.yaml,**.neorg,**.org",
    },
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
  },
  {
    "pmizio/typescript-tools.nvim",
    -- event = {
    --   "BufRead *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
    --   "BufNewFile *.js,*.jsx,*.mjs,*.cjs,*.ts,*.tsx",
    -- },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "neovim/nvim-lspconfig",
    },
    build = "npm i -g @styled/typescript-styled-plugin typescript-styled-plugin",
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

        -- vim.lsp.inlay_hint(bufnr, true)
      end,
      code_lens = "all",
      settings = {
        separate_diagnostic_server = true,
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
          includeCompletionsForModuleExports = true,
          quotePreference = "auto",
        },
        tsserver_plugins = {
          -- for TypeScript v4.9+
          "@styled/typescript-styled-plugin",
          -- or for older TypeScript versions
          -- "typescript-styled-plugin",
        },
      },
    },
  },
}
