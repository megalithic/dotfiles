return function()
  -- local ts_ok, _ = mega.require("nvim-treesitter")
  -- if not ts_ok then return end

  vim.opt.indentexpr = "nvim_treesitter#indent()"

  local treesitter_parsers = require("nvim-treesitter.parsers")
  local ft_to_parser = treesitter_parsers.filetype_to_parsername

  ft_to_parser.json = "jsonc"
  ft_to_parser.keymap = "devicetree"
  ft_to_parser.zsh = "bash"
  ft_to_parser.kittybuf = "bash"

  require("nvim-treesitter.configs").setup({
    auto_install = true,
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "comment",
      "devicetree",
      "dockerfile",
      "eex",
      "elixir",
      "elm",
      "erlang",
      "fish",
      "go",
      "graphql",
      "html",
      "heex",
      "help",
      "javascript",
      "markdown",
      "markdown_inline",
      "jsdoc",
      "json",
      "jsonc",
      "json5",
      "lua",
      "make",
      "nix",
      "perl",
      "python",
      "query",
      "regex",
      "ruby",
      "rust",
      "scss",
      "scheme",
      "surface",
      "toml",
      "tsx",
      "typescript",
      "vim",
      "yaml",
    },
    highlight = {
      enable = true,
      use_languagetree = true,
      -- disable = function(lang, bufnr) -- Disable in large files
      --   -- Remove the org part to use TS highlighter for some of the highlights (Experimental)
      --   return lang == "org" or vim.api.nvim_buf_line_count(bufnr) > 5000
      -- end,
      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      -- https://github.com/nvim-treesitter/nvim-treesitter/pull/1042
      -- https://www.reddit.com/r/neovim/comments/ok9frp/v05_treesitter_does_anyone_have_python_indent/h57kxuv/?context=3
      -- Required since TS highlighter doesn't support all syntax features (conceal)
      additional_vim_regex_highlighting = {
        "python",
        "lua",
        "vim",
        "zsh",
      },
    },
    indent = { enable = true },
    autotag = {
      enable = true,
      filetype = {
        "html",
        "xml",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "vue",
        "elixir",
        "eelixir",
        "heex",
      },
    },
    context_commentstring = {
      enable = true,
      enable_autocmd = false,
      config = {
        lua = "-- %s",
        fish = "# %s",
        toml = "# %s",
        yaml = "# %s",
        ["eruby.yaml"] = "# %s",
      },
    },
    matchup = { enable = true },
    rainbow = {
      enable = true,
      disable = { "json", "jsonc", "html" },
      extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
      max_file_lines = 2000, -- Do not enable for files with more than 1000 lines, int
    },
    textobjects = {
      lookahead = true,
      select = {
        enable = true,
        include_surrounding_whitespace = false,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
          ["ac"] = "@class.outer",
          ["ic"] = "@class.inner",
          ["aC"] = "@conditional.outer",
          ["iC"] = "@conditional.inner",
          -- FIXME: this is unusable
          -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/133 is resolved
          -- ['ax'] = '@comment.outer',
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
        -- mappings for incremental selection (visual mappings)
        -- init_selection = "<leader>gv", -- maps in normal mode to init the node/scope selection
        -- node_incremental = "<leader>gv", -- increment to the upper named parent
        -- node_decremental = "<leader>gV", -- decrement to the previous node
        -- scope_incremental = "grc", -- (grc) increment to the upper scope (as defined in locals.scm)
        init_selection = "<CR>", -- maps in normal mode to init the node/scope selection
        node_incremental = "<CR>", -- increment to the upper named parent
        node_decremental = "<BS>", -- decrement to the previous node
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

  -- nvim-treehopper
  require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }

  -- mega.conf("treesitter-context", {
  --   enable = false,
  --   multiline_threshold = 4,
  --   separator = { "▁", "TreesitterContextBorder" }, -- ─▁
  --   mode = "topline",
  -- })
end
