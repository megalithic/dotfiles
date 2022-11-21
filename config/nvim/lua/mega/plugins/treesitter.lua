-- @REF
-- https://github.com/vsedov/nvim/blob/master/lua/modules/lang/treesitter.lua

return function()
  -- local ts_ok, _ = mega.require("nvim-treesitter")
  -- if not ts_ok then return end

  vim.opt.indentexpr = "nvim_treesitter#indent()"

  local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
  parser_config.html_eex = {
    install_info = {
      url = "https://github.com/rockerBOO/tree-sitter-html-eex",
      files = { "src/parser.c", "src/scanner.cc" },
    },
    maintainers = { "@rockerBOO" },
  }
  -- TODO: determine colours and such; presently like what i have over using this.
  -- parser_config.gitcommit = {
  --   install_info = {
  --     url = "https://github.com/gbprod/tree-sitter-gitcommit",
  --     files = { "src/parser.c", "src/scanner.c" },
  --     branch = "main",
  --   },
  --   filetype = "gitcommit",
  --   maintainers = { "@gbprod" },
  -- }

  local treesitter_parsers = require("nvim-treesitter.parsers")
  local ft_to_parser = treesitter_parsers.filetype_to_parsername

  ft_to_parser.json = "jsonc"
  ft_to_parser.keymap = "devicetree"
  ft_to_parser.zsh = "bash"
  ft_to_parser.kittybuf = "bash"
  ft_to_parser.eelixir = "html_eex"

  require("nvim-treesitter.configs").setup({
    auto_install = true,
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "comment", -- see styler.nvim
      "devicetree",
      "dockerfile",
      "diff",
      "eex", -- doesn't seem to work, using `html_eex` below, too
      "elixir",
      "elm",
      "embedded_template",
      "erlang",
      "fish",
      "git_rebase",
      -- "gitcommit",
      "go",
      "graphql",
      "heex",
      "help",
      "html",
      "html_eex",
      "javascript",
      "jsdoc",
      "json",
      "jsonc",
      "json5",
      "lua",
      "make",
      "markdown",
      "markdown_inline",
      "nix",
      "perl",
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
      "tsx",
      "typescript",
      "vim",
      "yaml",
    },
    highlight = {
      enable = vim.g.vscode ~= 1,
      disable = function(lang, bufnr)
        -- local is_ignored_lang = vim.tbl_contains({ "svg", "json", "heex" }, lang)
        return mega.is_chonky(bufnr)
        -- and is_ignored_lang
      end,
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
        "lua",
        "vim",
        "zsh",
      },
    },
    indent = { enable = true },
    autotag = { enable = true },
    endwise = { enable = true },
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
    -- textsubjects = {
    --   enable = true,
    --   prev_selection = ",",
    --   keymaps = {
    --     ["."] = "textsubjects-smart",
    --     -- [";"] = "textsubjects-container-outer",
    --     -- ["i;"] = "textsubjects-container-inner",
    --   },
    -- },
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
      -- keymaps = {
      --   init_selection = "gN", -- maps in normal mode to init the node/scope selection
      --   scope_incremental = "gN", -- increment to the upper scope (as defined in locals.scm)
      --   node_incremental = "gnn", -- increment to the upper named parent
      --   node_decremental = "gnn", -- decrement to the previous node
      -- },
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
end
