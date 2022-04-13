vim.opt.indentexpr = "nvim_treesitter#indent()"

-- custom treesitter parsers and grammars
local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.jsonc.filetype_to_parsername = "json"

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "bash",
    "c",
    "cpp",
    "css",
    "comment",
    "dockerfile",
    "elixir",
    "elm",
    "erlang",
    "fish",
    "go",
    "graphql",
    "html",
    "heex",
    -- "iex",
    "javascript",
    "markdown",
    "jsdoc",
    "json",
    "jsonc",
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
    "surface",
    "toml",
    "tsx",
    "typescript",
    "yaml",
  },
  highlight = {
    enable = true,
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = { "markdown" },
    use_languagetree = true,
  },
  indent = { enable = true },
  autotag = { enable = true },
  tree_docs = {
    enable = false,
    keymaps = {
      doc_node_at_cursor = "gdd",
      doc_all_in_range = "gdd",
      edit_doc_at_cursor = "gde",
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
    max_file_lines = nil, -- Do not enable for files with more than 1000 lines, int
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<cr",
      scope_incremental = "<cr>",
      node_incremental = "<tab>",
      node_decremental = "<s-tab>",
    },
  },
  textsubjects = {
    enable = true,
    keymaps = {
      ["."] = "textsubjects-smart",
      [";"] = "textsubjects-container-outer",
    },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
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
-- require("spellsitter").setup()
require("nvim-ts-autotag").setup({
  filetypes = {
    "html",
    "xml",
    "javascript",
    "typescriptreact",
    "javascriptreact",
    "vue",
    "elixir",
    "heex",
  },
})
-- nvim-treehopper
require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }
