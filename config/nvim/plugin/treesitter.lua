local ts_ok, _ = pcall(require, "nvim-treesitter")
if not ts_ok then return end

vim.opt.indentexpr = "nvim_treesitter#indent()"

local treesitter_parsers = require("nvim-treesitter.parsers")
local ft_to_parser = treesitter_parsers.filetype_to_parsername
ft_to_parser.json = "jsonc"
ft_to_parser.keymap = "devicetree"
ft_to_parser.zsh = "bash"

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
    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = {},
    use_languagetree = true,
  },
  indent = { enable = true },
  autotag = { enable = true, filetype = { "html", "xml", "heex" } },
  tree_docs = {
    enable = true,
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
mega.conf("nvim-ts-autotag", {
  filetypes = {
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
})

-- nvim-treehopper
require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }

mega.conf("treesitter-context", {
  enable = true,
  multiline_threshold = 4,
  separator = { "▁", "TreesitterContextBorder" }, -- ─▁
  mode = "topline",
})
