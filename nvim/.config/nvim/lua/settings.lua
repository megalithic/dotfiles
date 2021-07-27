-- [ui/appearance] --------------------------------------------------------- {{{
do
  -- fallback in the event our statusline plugins fail to load
  vim.opt.statusline =
    table.concat(
    {
      "%2{mode()} | ",
      "f", -- relative path
      "m", -- modified flag
      "r",
      "=",
      "{&spelllang}",
      "y", -- filetype
      "8(%l,%c%)", -- line, column
      "8p%% " -- file percentage
    },
    " %"
  )
end
-- }}}

-- [nvim options] ---------------------------------------------------------- {{{
do
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.g.no_man_maps = true
  vim.g.vim_json_syntax_conceal = false
  vim.g.vim_json_conceal = false
  vim.g.floating_window_border = {"╭", "─", "╮", "│", "╯", "─", "╰", "│"}
  vim.g.floating_window_border_dark = {
    {"╭", "FloatBorderDark"},
    {"─", "FloatBorderDark"},
    {"╮", "FloatBorderDark"},
    {"│", "FloatBorderDark"},
    {"╯", "FloatBorderDark"},
    {"─", "FloatBorderDark"},
    {"╰", "FloatBorderDark"},
    {"│", "FloatBorderDark"}
  }
end
-- }}}

-- [tree-sitter] ----------------------------------------------------------- {{{
do
  require("nvim-treesitter.configs").setup {
    ensure_installed = {
      "c",
      "cpp",
      "javascript",
      "elixir",
      "elm",
      "lua",
      "python",
      "rust",
      "html",
      "query",
      "toml",
      "css",
      "nix",
      "tsx",
      "typescript",
      "ruby",
      "jsdoc",
      "erlang"
    },
    highlight = {enable = true},
    indent = {enable = true},
    autotag = {enable = true},
    context_commentstring = {enable = true},
    rainbow = {
      enable = true,
      extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
      max_file_lines = 1000 -- Do not enable for files with more than 1000 lines, int
    },
    textobjects = {
      select = {
        enable = true,
        lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
        keymaps = {
          ["if"] = "@function.inner",
          ["af"] = "@function.outer",
          ["ar"] = "@parameter.outer",
          ["iC"] = "@class.inner",
          ["aC"] = "@class.outer",
          ["ik"] = "@call.inner",
          ["ak"] = "@call.outer",
          ["il"] = "@loop.inner",
          ["al"] = "@loop.outer",
          ["ic"] = "@conditional.outer",
          ["ac"] = "@conditional.inner"
        }
      }
    }
  }

  require("nvim-ts-autotag").setup(
    {
      filetypes = {
        "html",
        "xml",
        "javascript",
        "typescriptreact",
        "javascriptreact",
        "vue",
        "elixir",
        "eelixir"
      }
    }
  )
end
-- }}}

-- [orgmode] --------------------------------------------------------------- {{{
do
  vim.g.indent_blankline_buftype_exclude = {"terminal", "nofile"}
  vim.g.indent_blankline_filetype_exclude = {
    "help",
    "startify",
    "dashboard",
    "packer",
    "neogitstatus",
    "NvimTree",
    "Trouble"
  }
  vim.g.indent_blankline_char = "│"
  vim.g.indent_blankline_use_treesitter = true
  vim.g.indent_blankline_show_trailing_blankline_indent = false
  vim.g.indent_blankline_show_current_context = true
  vim.g.indent_blankline_context_patterns = {
    "class",
    "return",
    "function",
    "method",
    "^if",
    "^while",
    "jsx_element",
    "^for",
    "^object",
    "^table",
    "block",
    "arguments",
    "if_statement",
    "else_clause",
    "jsx_element",
    "jsx_self_closing_element",
    "try_statement",
    "catch_clause",
    "import_statement",
    "operation_type"
  }
end
-- }}}

-- [devicons] -------------------------------------------------------------- {{{
require "nvim-web-devicons".setup({default = true})
-- }}}

-- [orgmode] --------------------------------------------------------------- {{{
do
  require("orgmode").setup(
    {
      org_agenda_files = {"~/Library/Mobile Documents/com~apple~CloudDocs/org/*"},
      org_default_notes_file = "~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org"
    }
  )
end
-- }}}

-- [tabout] ---------------------------------------------------------------- {{{
do
  require("tabout").setup(
    {
      tabkey = "<Tab>", -- key to trigger tabout
      act_as_tab = true, -- shift content if tab out is not possible
      completion = true, -- if the tabkey is used in a completion pum
      tabouts = {
        {open = "'", close = "'"},
        {open = '"', close = '"'},
        {open = "`", close = "`"},
        {open = "(", close = ")"},
        {open = "[", close = "]"},
        {open = "{", close = "}"}
      },
      ignore_beginning = true --[[ if the cursor is at the beginning of a filled element it will rather tab out than shift the content ]],
      exclude = {}
    }
  )
end
-- }}}

-- [zenmode] --------------------------------------------------------------- {{{
do
  --[[ require"zen-mode".setup {
  window = { backdrop = 1, options = { signcolumn = "no" } },
  plugins = { tmux = true },
} ]]
end
-- }}}

-- [zk] -------------------------------------------------------------------- {{{
do
  require("zk").setup({debug = true})
end
-- }}}

-- [trouble] --------------------------------------------------------------- {{{
do
  -- require("trouble").setup({})
end
-- }}}

-- [bullets] --------------------------------------------------------------- {{{
do
  vim.g.bullets_enabled_file_types = {
    "markdown",
    "text",
    "gitcommit",
    "scratch"
  }
  vim.g.bullets_checkbox_markers = " ○◐✗"
  -- vim.g.bullets_set_mappings = 0
end
-- }}}

-- [fixcursorhold] --------------------------------------------------------- {{{
do
  vim.g.cursorhold_updatetime = 100
end
-- }}}

-- [lspsaga] --------------------------------------------------------------- {{{
-- do
--   require("lspsaga").init_lsp_saga {
--     use_saga_diagnostic_sign = false,
--     border_style = 2,
--     finder_action_keys = {
--       open = "<CR>",
--       vsplit = "v",
--       split = "s",
--       quit = {"<ESC>", "q"},
--       scroll_down = "<C-n>",
--       scroll_up = "<C-p>"
--     },
--     code_action_keys = {quit = "<ESC>", exec = "<CR>"},
--     code_action_prompt = {
--       enable = true,
--       sign = false,
--       virtual_text = true
--     },
--     finder_definition_icon = "•d",
--     finder_reference_icon = "•r"
--   }
-- end
-- }}}

-- [beacon] ---------------------------------------------------------------- {{{
do
  vim.g.beacon_size = 90
  vim.g.beacon_minimal_jump = 25
  -- vim.g.beacon_shrink = 0
  -- vim.g.beacon_fade = 0
  vim.g.beacon_ignore_filetypes = {"fzf"}
end
-- }}}

-- [kommentary] ------------------------------------------------------------ {{{
do
  local kommentary_config = require("kommentary.config")
  kommentary_config.configure_language(
    "default",
    {
      single_line_comment_string = "auto",
      prefer_single_line_comments = true,
      multi_line_comment_strings = false
    }
  )
  kommentary_config.configure_language(
    "typescriptreact",
    {
      single_line_comment_string = "auto",
      prefer_single_line_comments = true
    }
  )
  kommentary_config.configure_language(
    "vue",
    {
      single_line_comment_string = "auto",
      prefer_single_line_comments = true
    }
  )
  kommentary_config.configure_language(
    "css",
    {
      single_line_comment_string = "auto",
      prefer_single_line_comments = true
    }
  )
end
-- }}}

-- [conflict-marker] ------------------------------------------------------- {{{
do
  -- disable the default highlight group
  vim.g.conflict_marker_highlight_group = ""
  -- Include text after begin and end markers
  vim.g.conflict_marker_begin = "^<<<<<<< .*$"
  vim.g.conflict_marker_end = "^>>>>>>> .*$"
end
-- }}}

-- [colorizer] ------------------------------------------------------------- {{{
do
  require("colorizer").setup(
    {
      -- '*',
      -- '!vim',
      -- }, {
      css = {rgb_fn = true},
      scss = {rgb_fn = true},
      sass = {rgb_fn = true},
      stylus = {rgb_fn = true},
      vim = {names = false},
      tmux = {names = true},
      "eelixir",
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
      "zsh",
      "sh",
      "conf",
      "lua",
      html = {
        mode = "foreground"
      }
    }
  )
end
-- }}}

-- [golden-size] ----------------------------------------------------------- {{{
do
  local golden_size_installed, golden_size = pcall(require, "golden_size")
  if golden_size_installed then
    local function ignore_by_buftype(types)
      local buftype = vim.api.nvim_buf_get_option(vim.api.nvim_get_current_buf(), "buftype")
      for _, type in pairs(types) do
        if type == buftype then
          return 1
        end
      end
    end
    golden_size.set_ignore_callbacks(
      {
        {
          ignore_by_buftype,
          {
            "Undotree",
            "quickfix",
            "nerdtree",
            "current",
            "Vista",
            "LuaTree",
            "nofile"
          }
        },
        {golden_size.ignore_float_windows}, -- default one, ignore float windows
        {golden_size.ignore_by_window_flag} -- default one, ignore windows with w:ignore_gold_size=1
      }
    )
  end
end
-- }}}

-- [autopairs] ------------------------------------------------------------- {{{
do
  require("nvim-autopairs").setup(
    {
      map_cr = true, --  map <CR> on insert mode
      map_complete = false -- it will auto insert `(` after select function or method item
    }
  )
end
-- }}}

-- [polyglot] -------------------------------------------------------------- {{{
do
  vim.g.polyglot_disabled = {}
end
-- }}}

-- [quickscope] ------------------------------------------------------------ {{{
do
  vim.g.qs_enable = 1
  vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}
  vim.g.qs_buftype_blacklist = {"terminal", "nofile"}
  vim.g.qs_lazy_highlight = 1
end
-- }}}

-- [diffview] -------------------------------------------------------------- {{{
do
  require "diffview".setup({})
end
-- }}}

-- [git-messenger] --------------------------------------------------------- {{{
do
  vim.g.git_messenger_floating_win_opts = {border = vim.g.floating_window_border_dark}
  vim.g.git_messenger_no_default_mappings = true
  vim.g.git_messenger_max_popup_width = 100
  vim.g.git_messenger_max_popup_height = 100
end
-- }}}

-- [vim-test] -------------------------------------------------------------- {{{
do
  vim.api.nvim_exec(
    [[
    function! TerminalSplit(cmd)
    vert new | set filetype=test | call termopen(['/usr/local/bin/zsh', '-c', a:cmd], {'curwin':1})
    endfunction

    let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
    let g:test#strategy = 'terminal_split'
    let g:test#filename_modifier = ':.'
    let g:test#preserve_screen = 0

    nmap <silent> <leader>tf :TestFile<CR>
    nmap <silent> <leader>tt :TestVisit<CR>
    nmap <silent> <leader>tn :TestNearest<CR>
    nmap <silent> <leader>tl :TestLast<CR>
    nmap <silent> <leader>tv :TestVisit<CR>
    nmap <silent> <leader>ta :TestSuite<CR>
    nmap <silent> <leader>tP :A<CR>
    nmap <silent> <leader>tp :AV<CR>
    nmap <silent> <leader>to :copen<CR>
    ]],
    false
  )
end
-- }}}

-- [projectionist] --------------------------------------------------------- {{{
do
  vim.g.projectionist_heuristics = {
    ["mix.exs"] = {
      ["lib/**/views/*_view.ex"] = {
        ["type"] = "view",
        ["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
          "  use {dirname|camelcase|capitalize}, :view",
          "end"
        }
      },
      ["test/**/views/*_view_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
          "end"
        }
      },
      ["lib/**/live/*_live.ex"] = {
        ["type"] = "liveview",
        ["alternate"] = "test/{dirname}/views/{basename}_live_test.exs",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
          "  use {dirname|camelcase|capitalize}, :live_view",
          "end"
        }
      },
      ["test/**/live/*_live_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
          "end"
        }
      },
      ["lib/*.ex"] = {
        ["type"] = "source",
        ["alternate"] = "test/{}_test.exs",
        ["template"] = {
          "defmodule {camelcase|capitalize|dot} do",
          "",
          "end"
        }
      },
      ["test/*_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{}.ex",
        ["template"] = {
          "defmodule {camelcase|capitalize|dot}Test do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {camelcase|capitalize|dot}",
          "end"
        }
      }
    }
  }
end
-- }}}

-- [telescope] ------------------------------------------------------------- {{{
do
  local telescope = require("telescope")
  local actions = require("telescope.actions")

  telescope.setup(
    {
      defaults = {
        file_ignore_patterns = {".git/*"},
        path_display = {"absolute"},
        winblend = 0,
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
            ["<C-x>"] = false,
            ["<C-u>"] = false,
            ["<C-d>"] = false,
            ["<C-s>"] = actions.select_horizontal,
            ["<CR>"] = actions.select_vertical,
            ["<C-o>"] = actions.select_default
          }
        }
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case" -- or "ignore_case" or "respect_case"
          -- the default case_mode is "smart_case"
        }
      }
    }
  )
  telescope.load_extension("fzf")
end
-- }}}
