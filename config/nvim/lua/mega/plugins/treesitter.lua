-- @REF
-- https://github.com/vsedov/nvim/blob/master/lua/modules/lang/treesitter.lua

return {
  {
    "laytan/tailwind-sorter.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
    },
    build = "cd formatter && npm i && npm run build",
    config = {
      on_save_enabled = true,
      on_save_pattern = { "*.html", "*.heex", "*.ex" },
    },
  },
  {
    enabled = false,
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPre",
    opts = {
      separator = "▁", -- "TreesitterContextBorder" }, -- alts: ▁ ─ ▄─▁
      min_window_height = 5,
      mode = "topline",
      max_lines = 3, -- How many lines the window should span. Values <= 0 mean no limit.
      trim_scope = "outer",
    },
  },
  { "nvim-treesitter/playground", cmd = { "TSPlaygroundToggle", "TSHighlightCapturesUnderCursor" } },
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = "VeryLazy",
    -- cond = #vim.api.nvim_list_uis() > 0,
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "RRethy/nvim-treesitter-textsubjects",
      "nvim-treesitter/nvim-tree-docs",
      "JoosepAlviste/nvim-ts-context-commentstring",
      "RRethy/nvim-treesitter-endwise",
      { "megalithic/nvim-ts-autotag" },
      "David-Kunz/treesitter-unit",
      {
        url = "https://gitlab.com/HiPhish/rainbow-delimiters.nvim",
        event = "VimEnter",
        config = function()
          local rainbow = require("rainbow-delimiters")
          vim.g.rainbow_delimiters = {
            strategy = {
              [""] = rainbow.strategy["global"],
              vim = rainbow.strategy["local"],
            },
            query = {
              [""] = "rainbow-delimiters",
              lua = "rainbow-blocks",
              html = "rainbow-tags",
            },
            highlight = {
              "RainbowDelimiterRed",
              "RainbowDelimiterYellow",
              "RainbowDelimiterBlue",
              "RainbowDelimiterOrange",
              "RainbowDelimiterGreen",
              "RainbowDelimiterViolet",
              "RainbowDelimiterCyan",
            },
            blacklist = { "c", "cpp" },
          }
        end,
      },
    },
    config = function()
      local disable_max_size = 2000000 -- 2MB

      local function should_disable(lang, bufnr)
        local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(bufnr or 0))
        -- size will be -2 if it doesn't fit into a number
        if size > disable_max_size or size == -2 then return true end
        return false
      end
      -- for apple silicon
      require("nvim-treesitter.install").compilers = { "gcc-13" }

      vim.opt.indentexpr = "nvim_treesitter#indent()"

      local ft_to_parser_aliases = {
        dotenv = "bash",
        gitcommit = "NeogitCommitMessage",
        javascriptreact = "jsx",
        json = "jsonc",
        keymap = "devicetree",
        kittybuf = "bash",
        tiltfile = "starlark",
        typescriptreact = "tsx",
        zsh = "bash",
      }

      for ft, parser in pairs(ft_to_parser_aliases) do
        vim.treesitter.language.register(parser, ft)
      end

      -- local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()
      -- parser_configs.norg = {
      --   install_info = {
      --     url = "https://github.com/nvim-neorg/tree-sitter-norg",
      --     files = { "src/parser.c", "src/scanner.cc" },
      --     branch = "main",
      --   },
      -- }
      -- parser_configs.norg_meta = {
      --   install_info = {
      --     url = "https://github.com/nvim-neorg/tree-sitter-norg-meta",
      --     files = { "src/parser.c" },
      --     branch = "main",
      --   },
      -- }

      require("nvim-treesitter.configs").setup({
        auto_install = false,
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
          "norg",
          "norg_meta",
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
        highlight = {
          enable = vim.g.vscode ~= 1,
          -- disable = function(lang, bufnr) return mega.should_disable_ts({ lang = lang, bufnr = bufnr }) end,
          disable = should_disable,

          use_languagetree = true,
          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
          -- Using this option may slow down your editor, and you may see some duplicate highlights.
          -- Instead of true it can also be a list of languages
          -- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
          -- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/h57kxuv/?context=3
          -- Required since TS highlighter doesn't support all syntax features (conceal)
          additional_vim_regex_highlighting = {
            "python",
            -- "lua",
            "vim",
            "zsh",
          },
        },
        indent = {
          enable = true,
          disable = function(lang, bufnr)
            if lang == "lua" then -- or lang == "python" then
              return true
            else
              return should_disable(lang, bufnr)
            end
          end,
        },
        autotag = {
          enable = true,
          filetypes = {
            "html",
            "javascript",
            "typescript",
            "javascriptreact",
            "typescriptreact",
            "tsx",
            "jsx",
            "xml",
            "php",
            "markdown",
            "handlebars",
            "hbs",
            "heex",
            "elixir",
            "eruby",
            "embedded_template",
          },
        },
        endwise = { enable = true },
        context_commentstring = {
          enable = true,
          enable_autocmd = false,
          config = {
            typescript = {
              __default = "// %s",
              jsx_element = "{/* %s */}",
              jsx_fragment = "{/* %s */}",
              jsx_attribute = "// %s",
              comment = "// %s",
              __multiline = "/* %s */",
            },
            javascript = {
              __default = "// %s",
              jsx_element = "{/* %s */}",
              jsx_fragment = "{/* %s */}",
              jsx_attribute = "// %s",
              comment = "// %s",
              __multiline = "/* %s */",
            },
            elixir = {
              __default = "# %s",
              quoted_content = "<%!-- %s --%>",
              component = "<%!-- %s --%>",
            },
            heex = {
              __default = "<%!-- %s --%>",
              component = "<%!-- %s --%>",
              self_closing_component = "<%!-- %s --%>",
              __multiline = "<%!-- %s --%>",
            },
            html = {
              __default = "<!-- %s -->",
              component = "<!-- %s -->",
              self_closing_component = "<!-- %s -->",
              __multiline = "<!-- %s -->",
            },
            lua = "-- %s",
            fish = "# %s",
            toml = "# %s",
            yaml = "# %s",
            ["eruby.yaml"] = "# %s",
          },
        },
        matchup = { enable = false, include_match_words = true, disable = should_disable, disable_virtual_text = true },
        autopairs = { enable = true },
        textobjects = {
          lookahead = true,
          select = {
            enable = true,
            include_surrounding_whitespace = false,
            keymaps = {
              ["ix"] = "@comment.inner",
              ["ax"] = "@comment.outer",
              ["af"] = { query = "@function.outer", desc = "ts: all function" },
              ["if"] = { query = "@function.inner", desc = "ts: inner function" },
              ["ac"] = { query = "@class.outer", desc = "ts: all class" },
              ["ic"] = { query = "@class.inner", desc = "ts: inner class" },
              ["aC"] = { query = "@conditional.outer", desc = "ts: all conditional" },
              ["iC"] = { query = "@conditional.inner", desc = "ts: inner conditional" },
            },
          },
          swap = {
            enable = true,
            swap_next = {
              ["[w"] = "@parameter.inner",
            },
            swap_previous = {
              ["]w"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true, -- whether to set jumps in the jumplist
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
          lsp_interop = {
            enable = true,
            peek_definition_code = {
              ["gD"] = "@function.outer",
            },
          },
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<CR>",
            node_incremental = "v",
            node_decremental = "V",
            scope_incremental = "vv", -- increment to the upper scope (as defined in locals.scm)
          },
        },
        query_linter = {
          enable = true,
          use_virtual_text = true,
          lint_events = { "BufWrite", "CursorHold" },
        },
        playground = {
          enable = true,
          disable = {},
          updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
          persist_queries = true, -- Whether the query persists across vim sessions
          keybindings = {
            toggle_query_editor = "o",
            toggle_hl_groups = "i",
            toggle_injected_languages = "t",
            toggle_anonymous_nodes = "a",
            toggle_language_display = "I",
            focus_language = "f",
            unfocus_language = "F",
            update = "R",
            goto_node = "<cr>",
            show_help = "?",
          },
        },
      })
    end,
  },
}
