return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
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
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "b0o/schemastore.nvim" },
      { "folke/neodev.nvim" },
      {
        "williamboman/mason.nvim",
        cmd = { "Mason" },
        opts = {
          registries = {
            "lua:mason.registry",
            "github:mason-org/mason-registry",
          },
          ui = {
            border = mega.get_border(),
          },
        },
      },
      -- {
      --   "elixir-tools/elixir-tools.nvim",
      --   event = { "BufReadPre", "BufNewFile" },
      --   config = function()
      --     local elixir = require("elixir")
      --     local elixirls = require("elixir.elixirls")
      --     local arch = {
      --       ["arm64"] = "arm64",
      --       ["aarch64"] = "arm64",
      --       ["amd64"] = "amd64",
      --       ["x86_64"] = "amd64",
      --     }
      --
      --     local os_name = string.lower(vim.uv.os_uname().sysname)
      --     local current_arch = arch[string.lower(vim.uv.os_uname().machine)]
      --     local build_bin = fmt("next_ls_%s_%s", os_name, current_arch)
      --
      --     elixir.setup({
      --       nextls = {
      --         enable = true,
      --         cmd = fmt("%s/lsp/nextls/burrito_out/%s --stdio", vim.env.XDG_DATA_HOME, build_bin),
      --       },
      --       credo = {},
      --       elixirls = {
      --         enable = true,
      --         cmd = fmt("%s/lsp/elixir-ls/%s", vim.env.XDG_DATA_HOME, "language_server.sh"),
      --         settings = elixirls.settings({
      --           dialyzerEnabled = false,
      --           enableTestLenses = false,
      --         }),
      --         on_attach = function(client, bufnr)
      --           vim.keymap.set("n", "<localleader>fp", ":ElixirFromPipe<cr>", { buffer = true, noremap = true })
      --           vim.keymap.set("n", "<localleader>tp", ":ElixirToPipe<cr>", { buffer = true, noremap = true })
      --           vim.keymap.set("v", "<localleader>em", ":ElixirExpandMacro<cr>", { buffer = true, noremap = true })
      --         end,
      --       },
      --     })
      --   end,
      --   dependencies = {
      --     "nvim-lua/plenary.nvim",
      --   },
      -- },
      {
        "williamboman/mason-lspconfig.nvim",
        lazy = true,
      },
    },
    config = function()
      -- require("mason").setup()
      -- require("mason-lspconfig").setup({
      --   ensure_installed = {
      --     "clangd",
      --     "cssls",
      --     "denols",
      --     "emmet_language_server",
      --     "eslint",
      --     "gopls",
      --     "lua_ls",
      --     "marksman",
      --     "pylsp",
      --   },
      -- })
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "sqlls",
          "clangd",
          "cssls",
          "denols",
          "emmet_language_server",
          "eslint",
          "gopls",
          "lua_ls",
          "marksman",
          "pylsp",
        },
      })
      local servers = {
        sqlls = {},
        -- clangd = {},
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
        -- tsserver = {},
        -- html = { filetypes = { 'html', 'twig', 'hbs'} },
        lua_ls = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      }

      -- Setup neovim lua configuration
      require("neodev").setup()

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- Ensure the servers above are installed
      local mason_lspconfig = require("mason-lspconfig")

      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
      })

      local on_attach = function(_, bufnr)
        -- NOTE: Remember that lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself
        -- many times.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local nmap = function(keys, func, desc)
          if desc then desc = "LSP: " .. desc end

          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
        end

        nmap("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
        nmap("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

        nmap("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
        nmap("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
        nmap("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
        nmap("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
        nmap("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
        nmap("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

        -- See `:help K` for why this keymap
        nmap("K", vim.lsp.buf.hover, "Hover Documentation")
        nmap("<C-k>", vim.lsp.buf.signature_help, "Signature Documentation")

        -- Lesser used LSP functionality
        nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
        nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
        nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
        nmap(
          "<leader>wl",
          function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end,
          "[W]orkspace [L]ist Folders"
        )

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(
          bufnr,
          "Format",
          function(_) vim.lsp.buf.format() end,
          { desc = "Format current buffer with LSP" }
        )
      end

      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
          })
        end,
      })
    end,
  },
  {
    -- Autocompletion
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "garymjr/nvim-snippets",
        cond = vim.g.snipper == "snippets",
        opts = {
          friendly_snippets = true,
          search_paths = { vim.fn.stdpath("config") .. "/snippets" },
        },
        dependencies = {
          "rafamadriz/friendly-snippets",
          event = { "InsertEnter" },
          enabled = vim.g.snipper == "snippets",
        },
      },

      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/cmp-nvim-lua" },
      { "hrsh7th/cmp-path" },
      { "FelipeLema/cmp-async-path" },
      { "hrsh7th/cmp-cmdline", event = { "CmdlineEnter" } },
      { "hrsh7th/cmp-nvim-lsp-signature-help" },
      { "hrsh7th/cmp-nvim-lsp-document-symbol" },
    },
    config = function()
      -- [[ Configure nvim-cmp ]]
      -- See `:help cmp`
      local cmp = require("cmp")

      cmp.setup({
        snippet = {
          expand = function(args) vim.snippet.expand(args.body) end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete({}),
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif vim.snippet.jumpable(1) then
              vim.schedule(function() vim.snippet.jump(1) end)
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif vim.snippet.jumpable(-1) then
              vim.schedule(function() vim.snippet.jump(-1) end)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
        },
      })
    end,
  },

  -- Useful plugin to show you pending keybinds.
  { "folke/which-key.nvim", opts = {} },
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map({ "n", "v" }, "]c", function()
          if vim.wo.diff then return "]c" end
          vim.schedule(function() gs.next_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Jump to next hunk" })

        map({ "n", "v" }, "[c", function()
          if vim.wo.diff then return "[c" end
          vim.schedule(function() gs.prev_hunk() end)
          return "<Ignore>"
        end, { expr = true, desc = "Jump to previous hunk" })

        -- Actions
        -- visual mode
        map(
          "v",
          "<leader>hs",
          function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          { desc = "stage git hunk" }
        )
        map(
          "v",
          "<leader>hr",
          function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
          { desc = "reset git hunk" }
        )
        -- normal mode
        map("n", "<leader>hs", gs.stage_hunk, { desc = "git stage hunk" })
        map("n", "<leader>hr", gs.reset_hunk, { desc = "git reset hunk" })
        map("n", "<leader>hS", gs.stage_buffer, { desc = "git Stage buffer" })
        map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "undo stage hunk" })
        map("n", "<leader>hR", gs.reset_buffer, { desc = "git Reset buffer" })
        map("n", "<leader>hp", gs.preview_hunk, { desc = "preview git hunk" })
        map("n", "<leader>hb", function() gs.blame_line({ full = false }) end, { desc = "git blame line" })
        map("n", "<leader>hd", gs.diffthis, { desc = "git diff against index" })
        map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "git diff against last commit" })

        -- Toggles
        map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "toggle git blame line" })
        map("n", "<leader>td", gs.toggle_deleted, { desc = "toggle git show deleted" })

        -- Text object
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "select git hunk" })
      end,
    },
  },
  -- Fuzzy Finder (files, lsp, etc)
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff" },
      { "<leader>fs" },
      { "<leader>fg" },
      { "<leader>fw" },
      { "<leader>fc" },
    },
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 end,
      },
    },
    config = function()
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-u>"] = false,
              ["<C-d>"] = false,
              ["<esc>"] = require("telescope.actions").close,
            },
          },
        },
      })

      -- Enable telescope fzf native, if installed
      pcall(require("telescope").load_extension, "fzf")

      -- Telescope live_grep in git root
      -- Function to find the git root directory based on the current buffer's path
      local function find_git_root()
        -- Use the current buffer's path as the starting point for the git search
        local current_file = vim.api.nvim_buf_get_name(0)
        local current_dir
        local cwd = vim.fn.getcwd()
        -- If the buffer is not associated with a file, return nil
        if current_file == "" then
          current_dir = cwd
        else
          -- Extract the directory from the current file's path
          current_dir = vim.fn.fnamemodify(current_file, ":h")
        end

        -- Find the Git root directory from the current file's path
        local git_root =
          vim.fn.systemlist("git -C " .. vim.fn.escape(current_dir, " ") .. " rev-parse --show-toplevel")[1]
        if vim.v.shell_error ~= 0 then
          print("Not a git repository. Searching on current working directory")
          return cwd
        end
        return git_root
      end

      -- Custom live_grep function to search in git root
      local function live_grep_git_root()
        local git_root = find_git_root()
        if git_root then require("telescope.builtin").live_grep({
          search_dirs = { git_root },
        }) end
      end

      vim.api.nvim_create_user_command("LiveGrepGitRoot", live_grep_git_root, {})

      -- See `:help telescope.builtin`
      vim.keymap.set(
        "n",
        "<leader>?",
        require("telescope.builtin").oldfiles,
        { desc = "[?] Find recently opened files" }
      )
      vim.keymap.set(
        "n",
        "<leader><space>",
        require("telescope.builtin").buffers,
        { desc = "[ ] Find existing buffers" }
      )
      vim.keymap.set("n", "<leader>/", function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
          winblend = 10,
          previewer = false,
        }))
      end, { desc = "[/] Fuzzily search in current buffer" })

      local function telescope_live_grep_open_files()
        require("telescope.builtin").live_grep({
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        })
      end
      vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>s/", telescope_live_grep_open_files, { desc = "[S]earch [/] in Open Files" })
      vim.keymap.set("n", "<leader>ss", require("telescope.builtin").builtin, { desc = "[S]earch [S]elect Telescope" })
      vim.keymap.set("n", "<leader>gf", require("telescope.builtin").git_files, { desc = "Search [G]it [F]iles" })
      vim.keymap.set("n", "<leader>sh", require("telescope.builtin").help_tags, { desc = "[S]earch [H]elp" })
      vim.keymap.set("n", "<leader>sw", require("telescope.builtin").grep_string, { desc = "[S]earch current [W]ord" })
      vim.keymap.set("n", "<leader>sg", require("telescope.builtin").live_grep, { desc = "[S]earch by [G]rep" })
      vim.keymap.set("n", "<leader>sG", ":LiveGrepGitRoot<cr>", { desc = "[S]earch by [G]rep on Git Root" })
      vim.keymap.set("n", "<leader>sd", require("telescope.builtin").diagnostics, { desc = "[S]earch [D]iagnostics" })
      vim.keymap.set("n", "<leader>sr", require("telescope.builtin").resume, { desc = "[S]earch [R]esume" })
    end,
  },
  {
    -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-tree-docs",
      {
        "JoosepAlviste/nvim-ts-context-commentstring",
        config = function()
          require("ts_context_commentstring").setup({})
          -- skip backwards compatibility routines and speed up loading.
          vim.g.skip_ts_context_commentstring_module = true
        end,
      },
      "RRethy/nvim-treesitter-endwise",
      { "megalithic/nvim-ts-autotag" },
      {
        "andymass/vim-matchup",
        lazy = false,
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

          vim.keymap.set({ "n", "x" }, "[[", "<plug>(matchup-[%)", { desc = "goto prev delimiter" })
          vim.keymap.set({ "n", "x" }, "]]", "<plug>(matchup-]%)", { desc = "goto next delimiter" })
        end,
        keys = {
          { "<Tab>", "<plug>(matchup-%)", desc = "goto matching delimiter", mode = { "n", "o", "s", "v", "x" } },
        },
      },
      "David-Kunz/treesitter-unit",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Add languages to be installed here that you want installed for treesitter
        ensure_installed = {
          "bash",
          "c",
          "cpp",
          "css",
          "csv",
          "comment",
          "devicetree",
          "dockerfile",
          "diff",
          "eex", -- doesn't seem to work, using `html_eex` below, too
          "elixir",
          "elm",
          "embedded_template",
          "erlang",
          "fish",
          "git_config",
          "git_rebase",
          "gitattributes",
          "gitcommit",
          "gitignore",
          "go",
          "graphql",
          "heex",
          "html",
          "javascript",
          "jq",
          "jsdoc",
          "json",
          "jsonc",
          "json5",
          "lua",
          "luadoc",
          "luap",
          "make",
          "markdown",
          "markdown_inline",
          "nix",
          -- "norg",
          -- "norg_meta",
          "perl",
          "psv",
          "python",
          "query",
          "regex",
          "ruby",
          "rust",
          "scss",
          "scheme",
          "sql",
          "surface",
          "teal",
          "toml",
          "tsv",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "yaml",
        },

        -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
        auto_install = false,

        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "vv",
            node_incremental = "v",
            -- scope_incremental = "<c-s>",
            node_decremental = "V",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
            keymaps = {
              -- You can use the capture groups defined in textobjects.scm
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["<leader>a"] = "@parameter.inner",
            },
            swap_previous = {
              ["<leader>A"] = "@parameter.inner",
            },
          },
        },
      })
    end,
  },
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    cond = vim.g.notifier_enabled and not vim.g.started_by_firenvim,
    config = function()
      local notify = require("notify")
      local base = require("notify.render.base")
      local U = require("mega.utils")

      -- local stages_util = require("notify.stages.util")
      -- local function initial(direction, opacity)
      --   return function(state)
      --     local next_height = state.message.height + 1 -- + 2
      --     local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
      --     if not next_row then return nil end
      --     return {
      --       relative = "editor",
      --       anchor = "NE",
      --       width = state.message.width,
      --       height = state.message.height,
      --       col = vim.opt.columns:get(),
      --       row = next_row,
      --       border = "none",
      --       style = "minimal",
      --       opacity = opacity,
      --     }
      --   end
      -- end
      -- local function stages(type, direction)
      --   type = type or "static"
      --   direction = stages_util[string.lower(direction)] or stages_util.DIRECTION.BOTTOM_UP
      --   if type == "static" then
      --     return {
      --       initial(direction, 100),
      --       function()
      --         return {
      --           col = { vim.opt.columns:get() },
      --           time = true,
      --         }
      --       end,
      --     }
      --   elseif type == "fade_in_slide_out" then
      --     return {
      --       initial(direction, 0),
      --       function(state, win)
      --         return {
      --           opacity = { 100 },
      --           col = { vim.opt.columns:get() },
      --           row = {
      --             stages_util.slot_after_previous(win, state.open_windows, direction),
      --             frequency = 3,
      --             complete = function() return true end,
      --           },
      --         }
      --       end,
      --       function(state, win)
      --         return {
      --           col = { vim.opt.columns:get() },
      --           time = true,
      --           row = {
      --             stages_util.slot_after_previous(win, state.open_windows, direction),
      --             frequency = 3,
      --             complete = function() return true end,
      --           },
      --         }
      --       end,
      --       function(state, win)
      --         return {
      --           width = {
      --             1,
      --             frequency = 2.5,
      --             damping = 0.9,
      --             complete = function(cur_width) return cur_width < 3 end,
      --           },
      --           opacity = {
      --             0,
      --             frequency = 2,
      --             complete = function(cur_opacity) return cur_opacity <= 4 end,
      --           },
      --           col = { vim.opt.columns:get() },
      --           row = {
      --             stages_util.slot_after_previous(win, state.open_windows, direction),
      --             frequency = 3,
      --             complete = function() return true end,
      --           },
      --         }
      --       end,
      --     }
      --   end
      -- end

      local function stages(type)
        type = type or "static"
        local stages_util = require("notify.stages.util")
        local direction = stages_util.DIRECTION.BOTTOM_UP
        -- local direction = stages_util[string.lower(direction)] or stages_util.DIRECTION.BOTTOM_UP

        if type == "static" then
          local function initial(direction, opacity)
            return function(state)
              local next_height = state.message.height + 1 -- + 2
              local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
              if not next_row then return nil end
              return {
                relative = "editor",
                anchor = "NE",
                width = state.message.width,
                height = state.message.height,
                col = vim.opt.columns:get(),
                row = next_row,
                border = "none",
                style = "minimal",
                opacity = opacity,
              }
            end
          end
          return {
            initial(direction, 100),
            function()
              return {
                col = { vim.opt.columns:get() },
                time = true,
              }
            end,
          }
        end

        return {
          function(state)
            local width = state.message.width or 1
            -- local next_height = state.message.height + 1
            local next_height = #state.open_windows == 0 and state.message.height + 1 or 1
            local next_row = stages_util.available_slot(state.open_windows, next_height, direction)
            if not next_row then return nil end
            return {
              relative = "editor",
              anchor = "NE",
              width = width,
              height = state.message.height,
              col = vim.opt.columns:get(),
              row = next_row,
              border = "none",
              style = "minimal",
              opacity = type == "fade" and 0 or 100,
            }
          end,
          function(state)
            return {
              opacity = type == "fade" and { 100 } or { 100 },
              width = { state.message.width, frequency = 2 },
              col = { vim.opt.columns:get() },
            }
          end,
          function()
            return {
              col = { vim.opt.columns:get() },
              time = true,
            }
          end,
          function()
            return {
              width = {
                1,
                frequency = 2.5,
                damping = 0.9,
                complete = function(cur_width) return cur_width < 2 end,
              },
              opacity = type == "fade" and {
                0,
                frequency = 2,
                complete = function(cur_opacity) return cur_opacity <= 4 end,
              } or { 100 },
              col = { vim.opt.columns:get() },
            }
          end,
        }
      end

      notify.setup({
        timeout = 3000,
        top_down = false,
        background_colour = "NotifyBackground",
        max_width = function() return math.floor(vim.o.columns * 0.8) end,
        max_height = function() return math.floor(vim.o.lines * 0.8) end,
        on_open = function(winnr)
          if vim.api.nvim_win_is_valid(winnr) then
            -- vim.api.nvim_win_set_config(winnr, { border = "", focusable = false })
            local buf = vim.api.nvim_win_get_buf(winnr)
            vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
            -- vim.cmd([[setlocal nospell]])
          end
        end,
        -- stages = "slide", -- alts: "static", "slide"
        stages = stages("slide"), -- alts: "static", "slide", "fade"
        -- render = "compact",
        render = function(bufnr, notif, hls, cfg)
          -- local namespace = base.namespace()
          -- vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, notif.message)
          --
          -- vim.api.nvim_buf_set_extmark(bufnr, namespace, 0, 0, {
          --   hl_group = hls.icon,
          --   end_line = #notif.message - 1,
          --   end_col = #notif.message[#notif.message],
          --   priority = 50,
          -- })

          local ns = base.namespace()
          local icon = notif.icon or "" -- » notif.icon
          local title = notif.title[1]

          local prefix
          if type(title) == "string" and #title > 0 then
            prefix = string.format("%s %s", icon, title)
          else
            prefix = string.format("%s", icon)
          end

          local messages = { notif.message[1] }
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, messages)
          vim.api.nvim_buf_set_extmark(bufnr, ns, 0, 0, {
            virt_text = {
              { " " },
              { prefix, hls.title },
              { " ⋮ " },
              { messages[1], hls.body },
              { " " },
            },
            virt_text_win_col = 0,
            priority = 10,
          })
        end,
      })

      -- HT: https://github.com/davidosomething/dotfiles/blob/dev/nvim/lua/dko/plugins/notify.lua#L32
      local notify_override = function(msg, level, opts)
        if not opts then opts = {} end
        if not opts.title then
          if U.starts_with(msg, "[LSP]") then
            local client, found_client = msg:gsub("^%[LSP%]%[(.-)%] .*", "%1")
            if found_client > 0 then
              opts.title = ("LSP %s %s"):format(mega.icons.misc.caret_right, client)
            else
              opts.title = "LSP"
            end
            msg = msg:gsub("^%[.*%] (.*)", "%1")
          elseif msg == "No code actions available" then
            -- https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/buf.lua#LL629C39-L629C39
            opts.title = "LSP"
          end
          -- opts.render = "wrapped-compact"
        end

        notify(msg, level, opts)
      end

      if not pcall(require, "plenary") then
        vim.notify = notify_override
      else
        local log = require("plenary.log").new({
          plugin = "notify",
          level = "debug",
          use_console = false,
          use_quickfix = false,
          use_file = false,
        })

        vim.notify = function(msg, level, opts)
          log.info(msg, level, opts)

          notify_override(msg, level, opts)
        end
      end
    end,
  },
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
  {
    "echasnovski/mini.comment",
    event = "VeryLazy",
    config = function()
      require("mini.comment").setup({
        ignore_blank_lines = true,
        hooks = {
          pre = function() require("ts_context_commentstring.internal").update_commentstring({}) end,
        },
      })
    end,
  },
}
