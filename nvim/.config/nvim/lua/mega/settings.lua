mega.inspect("activating package settings.lua..")

local cs = require("mega.colors.forest_night")

require("indent_guides").setup(
  {
    even_colors = {fg = "#ffffff", bg = cs.colors.darker_gray},
    odd_colors = {fg = "#ffffff", bg = cs.colors.darkest_gray},
    -- even_colors = {fg = "#ffffff", bg = "#332b36"},
    -- odd_colors = {fg = "#ffffff", bg = "#2a3834"},
    indent_char = "│"
  }
)

-- [prose,wiki,md] -------------------------------------------------------------
vim.g.goyo_width = 120
vim.g.goyo_height = "50%"
vim.g["pencil#conceallevel"] = 0
vim.g["pencil#wrapModeDefault"] = "soft"
-- https://github.com/ishchow/dotfiles/blob/master/.config/nvim/plugin/vim-lexical.vim

vim.g.markdown_enable_conceal = 1

-- ## vimwiki
local journal = {
  path = "~/Documents/zettel",
  syntax = "markdown",
  ext = ".md",
  links_space_char = "_",
  auto_diary_index = 1,
  automatic_nested_syntaxes = 1,
  diary_header = "Daily Notes",
  diary_rel_path = "dailies/",
  diary_index = "index"
}
vim.g.vimwiki_list = {journal}
vim.g.vimwiki_global_ext = 0
vim.g.vimwiki_auto_chdir = 1
-- vim.g.vimwiki_tags_header = "Wiki tags"
vim.g.vimwiki_auto_header = 1
vim.g.vimwiki_hl_headers = 1 --too colourful
vim.g.vimwiki_conceal_pre = 1
vim.g.vimwiki_hl_cb_checked = 1
vim.g.vimwiki_folding = "expr"
vim.g.vimwiki_markdown_link_ext = 1
vim.g.vimwiki_ext2syntax = {
  [".md"] = "markdown",
  [".markdown"] = "markdown",
  [".mdown"] = "markdown"
}
vim.g.vimwiki_key_mappings = {all_maps = 0}

-- ## zettel

-- let g:zettel_format = '%Y%m%d%H%M-%S'
-- let g:zettel_options = [{},{"front_matter" : {"tags" : ""}, "template" :  "~/Templates/zettel.tpl"}]
-- nnoremap <leader>vt :VimwikiSearchTags<space>
-- nnoremap <leader>vs :VimwikiSearch<space>
-- nnoremap <leader>gt :VimwikiRebuildTags!<cr>:ZettelGenerateTags<cr><c-l>
-- nnoremap <leader>zl :ZettelSearch<cr>
-- nnoremap <leader>zn :ZettelNew<cr><cr>:4d<cr>:w<cr>ggA
-- nnoremap <leader>bl :VimwikiBacklinks<cr>

-- vim.g.zettel_format = "%Y%m%d%H%M-%S"
vim.g.zettel_format = "%y%m%d%H%M%S-%title"
-- REF:
-- https://github.com/JamieJQuinn/dotenv/blob/master/.vimrc#L213-L221
-- https://github.com/shaine/dotfiles/blob/master/home/.config/nvim/init.vim#L431-L535
-- https://github.com/WizzardAlex/dotfiles/blob/master/vim/.vimrc#L173-L217
-- https://github.com/svemagie/dotfiles/blob/main/vim/dot.vim/.vimrc#L62-L125
-- https://github.com/cawal/cwl-dotfiles/blob/master/neovim/config/init.vim#L61-L169
-- https://github.com/abers/dotfiles/blob/master/.config/nvim/init.vim#L313-L347
-- https://github.com/phux/.dotfiles/blob/master/roles/neovim/files/lua/plugins/_zettel.lua

vim.g.zettel_options = {
  {},
  {
    front_matter = {tags = ""}
    -- template = "~/Documents/zettel/_templates/zettel.tpl"
  }
}

vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "

-- vim.g.zettel_format = "%Y%m%d%H%M"
-- vim.g.vimwiki_list = [{'path': '~/path/to/zettelkasten/', 'syntax': 'markdown', 'ext': '.md'}]
-- vim.g.vimwiki_markdown_link_ext = 1
-- vim.g.vimwiki_ext2syntax = {'.md': 'markdown', '.markdown': 'markdown', '.mdown': 'markdown'}
-- vim.g.nv_search_paths = ['~/path/to/Zettelkasten']
-- vim.g.zettel_options = [{"front_matter" : [["tags", ""], ["citation", ""]]}]
-- vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "
-- nnoremap <leader>nz :ZettelNew<space>

-- do
--   -- vim.g.wiki_root = "~/Documents/_wiki"
--   -- vim.g.wiki_filetypes = {"md"}
--   -- vim.g.wiki_link_target_type = "md"
--   -- vim.g.wiki_map_link_create = "CreateLinks" -- cannot use anonymous functions
--   -- vim.cmd [[
--   --   function! CreateLinks(text) abort
--   --     return substitute(tolower(a:text), '\s\+', '-', 'g')
--   --   endfunction
--   -- ]]

--   -- vimwiki REFS:
--   -- https://github.com/peterhajas/dotfiles/blob/master/vim/.vimrc#L392-L441
--   -- https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/vimwiki.lua

--   vim.g.vimwiki_list = {
--     {
--       path = vim.fn.expand("$HOME/Documents/_wiki"),
--       syntax = "markdown",
--       ext = ".md",
--       auto_diary_index = 1,
--       auto_toc = 1,
--       auto_generate_links = 1,
--       auto_tags = 1
--       -- auto_tags = true,
--       -- auto_toc = true,
--       -- auto_generate_links = true,
--       -- auto_generate_tags = true,
--       -- auto_diary_index = true
--     }
--   }
--   vim.g.vimwiki_global_ext = 0
--   vim.g.vimwiki_auto_chdir = 1
--   vim.g.vimwiki_tags_header = "Wiki tags"
--   vim.g.vimwiki_auto_header = 1
--   vim.g.vimwiki_hl_headers = 1 --too colourful
--   vim.g.vimwiki_conceal_pre = 1
--   vim.g.vimwiki_hl_cb_checked = 1
--   -- vim.g.vimwiki_list = {vim.g.wiki, vim.g.learnings_wiki, vim.g.system_wiki}
--   vim.g.vimwiki_folding = "expr"
--   vim.g.vimwiki_markdown_link_ext = 1
--   vim.g.vimwiki_ext2syntax = {
--     [".md"] = "markdown",
--     [".markdown"] = "markdown",
--     [".mdown"] = "markdown"
--   }
--   -- vim.g.vimwiki_key_mappings = {all_maps = 0}

--   -- vim.g.vimwiki_global_ext = 0
--   -- vim.g.vimwiki_list = {
--   --     path = "~/src/github.com/evantravers/undo-zk/wiki/",
--   --     syntax = "markdown",
--   --     ext = ".md",
--   --     diary_rel_path = "journal"
--   --   }
--   -- }

--   vim.g.nv_search_paths = {"~/Documents/_wiki/"}
--   vim.g.zettel_format = "%Y%m%d-%H%M%S"
--   -- vim.g.zettel_format = "%Y%m%d%H%M-%S"
--   -- vim.g.zettel_options = [{},{"front_matter" : {"tags" : ""}, "template" :  "~/Templates/zettel.tpl"}]
--   vim.g.zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "
--   --
--   -- nnoremap <leader>vt :VimwikiSearchTags<space>
--   -- nnoremap <leader>vs :VimwikiSearch<space>
--   -- nnoremap <leader>gt :VimwikiRebuildTags!<cr>:ZettelGenerateTags<cr><c-l>
--   -- nnoremap <leader>zl :ZettelSearch<cr>
--   -- nnoremap <leader>zn :ZettelNew<cr><cr>:4d<cr>:w<cr>ggA
--   -- nnoremap <leader>bl :VimwikiBacklinks<cr>
--   -- let g:vimwiki_list = [{'path': '~/Documents/notes/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1, 'auto_diary_index': 1},
--   --                      \{'path': '~/Documents/wiki/', 'syntax': 'markdown', 'ext': '.md', 'auto_tags': 1}]

--   -- let g:nv_search_paths = ['~/Documents/notes/']

--   -- " Filename format. The filename is created using strftime() function
--   -- let g:zettel_format = "%y%m%d-%H%M"

--   -- let g:zettel_fzf_command = "rg --column --line-number --ignore-case --no-heading --color=always "

--   -- " Set template and custom header variable for the second Wiki
--   -- " let g:zettel_options = [{"front_matter" : {"tags" : ""}, "template" :  "./vimztl.tpl"},{}]

--   -- nnoremap <leader>sn/ :NV<CR>

--   -- nnoremap <leader>zn :ZettelNew<space>
--   -- nnoremap <leader>z<leader>i :ZettelGenerateLinks<CR>
--   -- nnoremap <leader>z<leader>t :ZettelGenerateTags<CR>
--   vim.cmd "packadd vimwiki"
-- end

-- [lexima] ------------------------------------------------------------------
-- vim.g.lexima_enable_basic_rules = 0
-- vim.g.lexima_enable_newline_rules = 0
-- vim.g.lexima_enable_endwise_rules = 1

-- [fixcursorhold] -------------------------------------------------------------
vim.g.cursorhold_updatetime = 100

-- [lspfuzzy] --------------------------------------------------------------------
require("lspfuzzy").setup(
  {
    methods = "all" -- either 'all' or a list of LSP methods (see below)
  }
)

-- [lspsaga] -------------------------------------------------------------------
require("lspsaga").init_lsp_saga {
  use_saga_diagnostic_sign = false,
  border_style = 2,
  finder_action_keys = {
    open = "<CR>",
    vsplit = "v",
    split = "s",
    -- quit = {"q", [[\<ESC>]]}
    quit = {"<ESC>", "q"}
  }
}

-- [beacon] --------------------------------------------------------------------
vim.g.beacon_size = 90
vim.g.beacon_minimal_jump = 25
vim.g.beacon_shrink = 0
vim.g.beacon_ignore_filetypes = {"fzf"}

-- [surround] ------------------------------------------------------------------
-- vim.g.surround_mappings_style = "surround"
-- require "surround".setup {}

-- [nvim_comment] --------------------------------------------------------------
-- require("nvim_comment").setup()

-- [kommentary] ----------------------------------------------------------------
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

-- [conflict-marker] -----------------------------------------------------------
-- disable the default highlight group
vim.g.conflict_marker_highlight_group = ""
-- Include text after begin and end markers
vim.g.conflict_marker_begin = "^<<<<<<< .*$"
vim.g.conflict_marker_end = "^>>>>>>> .*$"

-- [nvim-colorizer] ------------------------------------------------------------
-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
local colorizer_installed, colorizer = pcall(require, "colorizer")
if colorizer_installed then
  colorizer.setup(
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

-- [focus] ---------------------------------------------------------------------
-- do
--   local focus = require("focus")
--   focus.enable = true
--   focus.width = 120
--   focus.height = 40
--   focus.cursorline = true
--   focus.signcolumn = true
--   focus.winhighlight = false
-- end

-- [golden_size] ---------------------------------------------------------------
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

-- [nvim-autopairs] ------------------------------------------------------------
require("nvim-autopairs").setup()
-- require('nvim-autopairs').setup({
--   pairs_map = {
--     ["'"] = "'",
--     ['"'] = '"',
--     ['('] = ')',
--     ['['] = ']',
--     ['{'] = '}',
--     ['`'] = '`',
--     ['$'] = '$'
--   }
-- })

-- [fzf] -----------------------------------------------------------------------
vim.g.fzf_command_prefix = "Fzf"
vim.g.fzf_layout = {window = {width = 0.5, height = 0.5}}
vim.g.fzf_action = {enter = "vsplit"}
vim.g.fzf_preview_window = {"right:40%", "alt-p"}
vim.env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude '.git' --exclude 'node_modules'"
vim.api.nvim_exec(
  [[
  function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
  endfunction
  ]],
  false
)
vim.cmd([[command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)]])
vim.g.fzf_colors = {
  fg = {"fg", "Normal"},
  bg = {"bg", "Normal"},
  hl = {"fg", "IncSearch"},
  ["fg+"] = {"fg", "CursorLine", "CursorColumn", "Normal"},
  ["bg+"] = {"bg", "CursorLine", "CursorColumn"},
  ["hl+"] = {"fg", "IncSearch"},
  info = {"fg", "IncSearch"},
  border = {"fg", "Ignore"},
  prompt = {"fg", "Comment"},
  pointer = {"fg", "IncSearch"},
  marker = {"fg", "IncSearch"},
  spinner = {"fg", "IncSearch"},
  header = {"fg", "WildMenu"}
}
-- @evantravers:
-- vim.g.fzf_colors = {
--   fg = {"fg", "Normal"},
--   bg = {"bg", "Normal"},
--   hl = {"fg", "Comment"},
--   ["fg+"] = {"fg", "CursorLine", "CursorColumn", "Normal"},
--   ["bg+"] = {"bg", "CursorLine", "CursorColumn"},
--   ["hl+"] = {"fg", "Statement"},
--   info = {"fg", "PreProc"},
--   border = {"fg", "Ignore"},
--   prompt = {"fg", "Conditional"},
--   pointer = {"fg", "Exception"},
--   marker = {"fg", "Keyword"},
--   spinner = {"fg", "Label"},
--   header = {"fg", "Comment"}
-- }

-- [vim-polyglot] --------------------------------------------------------------
vim.g.polyglot_disabled = {
  "typescript",
  "typescriptreact",
  "typescript.tsx",
  "javascriptreact",
  "markdown",
  "md",
  "graphql",
  "lua",
  "tsx",
  "jsx",
  "sass",
  "scss",
  "css",
  "elm",
  "elixir",
  "eelixir",
  "ex",
  "exs",
  "zsh",
  "sh"
}

-- [quickscope] ----------------------------------------------------------------
vim.g.qs_enable = 1
vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}
vim.g.qs_buftype_blacklist = {"terminal", "nofile"}
vim.g.qs_lazy_highlight = 1

-- [textobj_parameter] ---------------------------------------------------------
vim.g.vim_textobj_parameter_mapping = ","

-- [git_messenger] -------------------------------------------------------------
vim.g.git_messenger_no_default_mappings = true
vim.g.git_messenger_max_popup_width = 100
vim.g.git_messenger_max_popup_height = 100
mega.map("n", "<Leader>gb", "<cmd>GitMessenger<CR>")

-- [indentLine/indent_blankline] -----------------------------------------------
-- set concealcursor=n
-- vim.g.indentLine_char = "│"
-- vim.g.indentLine_first_char = vim.g.indentLine_char
-- vim.g.indentLine_showFirstIndentLevel = 1
-- -- " vim.g.indentLine_color_gui = onedark#GetColors().cursor_grey.gui
-- vim.g.indentLine_bgcolor_gui = "NONE"
-- vim.g.indentLine_setConceal = 0
-- vim.g.indentLine_fileTypeExclude = {"help", "defx", "vimwiki", "prcomment"}
-- vim.g.indentLine_autoResetWidth = 0
-- vim.g.indent_blankline_space_char = " "
-- vim.g.indent_blankline_debug = true

-- [gitsigns] ------------------------------------------------------------------
local gitsigns_installed, gitsigns = pcall(require, "gitsigns")
if gitsigns_installed then
  -- https://github.com/JoosepAlviste/dotfiles/blob/master/config/nvim/lua/j/gitsigns.lua
  gitsigns.setup(
    {
      signs = {
        add = {hl = "DiffAdd", text = "│"},
        change = {hl = "DiffChange", text = "│"},
        delete = {hl = "DiffDelete", text = "_"},
        topdelete = {hl = "DiffDelete", text = "‾"},
        changedelete = {hl = "DiffChange", text = "~"}
      },
      keymaps = {
        -- Default keymap options
        noremap = true,
        buffer = true,
        ["n ]g"] = {expr = true, '&diff ? \']g\' : \'<cmd>lua require"gitsigns".next_hunk()<CR>\''},
        ["n [g"] = {expr = true, '&diff ? \'[g\' : \'<cmd>lua require"gitsigns".prev_hunk()<CR>\''},
        ["n <leader>hs"] = '<cmd>lua require"gitsigns".stage_hunk()<CR>',
        ["n <leader>hu"] = '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>',
        ["n <leader>hr"] = '<cmd>lua require"gitsigns".reset_hunk()<CR>',
        ["n <leader>hp"] = '<cmd>lua require"gitsigns".preview_hunk()<CR>',
        ["n <leader>hb"] = '<cmd>lua require"gitsigns".blame_line()<CR>'
      },
      watch_index = {
        interval = 1000
      },
      sign_priority = 6,
      status_formatter = nil -- Use default
    }
  )
end

-- [vim-test] ------------------------------------------------------------------
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

-- [nvim-treesitter] -----------------------------------------------------------
local ts_installed, treesitter = pcall(require, "nvim-treesitter.configs")
if ts_installed then
-- local parser_configs = require "nvim-treesitter.parsers".get_parser_configs()
-- parser_configs.elixir = {
--   install_info = {
--     url = "~/.config/treesitter/tree-sitter-elixir",
--     files = {"src/parser.c"}
--   },
--   filetype = "elixir",
--   used_by = {"eelixir"}
-- }
-- treesitter.setup(
--   {
--     -- ensure_installed = "maintained",
--     ensure_installed = {
--       "bash",
--       "c",
--       "cpp",
--       "css",
--       "elm",
--       "erlang",
--       -- "elixir",
--       -- "fennel",
--       "html",
--       "jsdoc",
--       "javascript",
--       "json",
--       "lua",
--       -- "nix",
--       "python",
--       "regex",
--       "ruby",
--       -- "rust",
--       -- "toml",
--       "tsx",
--       "typescript",
--       "yaml"
--     },
--     -- ensure_installed = {
--     --   "bash",
--     --   "c",
--     --   "cpp",
--     --   "css",
--     --   "elm",
--     --   "erlang",
--     --   "elixir",
--     --   "fennel",
--     --   "html",
--     --   "jsdoc",
--     --   "javascript",
--     --   "json",
--     --   "lua",
--     --   "nix",
--     --   "python",
--     --   "regex",
--     --   "ruby",
--     --   "rust",
--     --   "toml",
--     --   "tsx",
--     --   "typescript",
--     --   "yaml"
--     -- },
--     highlight = {enable = false, use_languagetree = true},
--     indent = {enable = true},
--     incremental_selection = {
--       enable = false,
--       keymaps = {
--         init_selection = "gnn",
--         node_incremental = "grn",
--         scope_incremental = "grc",
--         node_decremental = "grm"
--       }
--     },
--     textobjects = {
--       select = {
--         enable = true,
--         keymaps = {
--           ["af"] = "@function.outer",
--           ["if"] = "@function.inner",
--           ["as"] = "@class.outer",
--           ["is"] = "@class.inner",
--           ["ac"] = "@conditional.outer",
--           ["ic"] = "@conditional.inner",
--           ["al"] = "@loop.outer",
--           ["il"] = "@loop.inner",
--           ["ab"] = "@block.outer",
--           ["ib"] = "@block.inner",
--           ["cm"] = "@comment.outer"
--           -- ["ss"] = "@statement.outer",
--         }
--       },
--       move = {
--         enable = true,
--         goto_next_start = {
--           ["nf"] = "@function.outer",
--           ["ns"] = "@class.outer",
--           ["nc"] = "@conditional.outer",
--           ["nl"] = "@loop.outer",
--           ["nb"] = "@block.outer"
--         },
--         goto_previous_start = {
--           ["Nf"] = "@function.outer",
--           ["Ns"] = "@class.outer",
--           ["Nc"] = "@conditional.outer",
--           ["Nl"] = "@loop.outer",
--           ["Nb"] = "@block.outer"
--         }
--       }
--     }
--   }
-- )
end

-- [vim-projectionist] ---------------------------------------------------------
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

-- [telescope] ---------------------------------------------------------
-- REFS:
-- https://github.com/delafthi/dotfiles/blob/master/nvim/.config/nvim/lua/config/telescope.lua
-- https://github.com/CalinLeafshade/dots/blob/master/nvim/.config/nvim/lua/leafshade/telescope/init.lua
--https://github.com/SubeetKD/.dotfiles/blob/main/.config/nvim/lua/subeet/telescope/fun.lua
--https://github.com/Liberatys/configs/blob/main/nvim/lua/init_telescope.lua
do
  local themes = require "telescope.themes"
  local actions = require "telescope.actions"
  local sorters = require "telescope.sorters"
  local previewers = require("telescope.previewers")

  local telescope_config = {
    prompt_prefix = " > ",
    hidden = true,
    winblend = 0,
    width = 0.45,
    -- preview_cutoff = 120,
    -- results_height = 1,
    -- results_width = 0.8,
    -- scroll_strategy = "cycle",
    -- layout_strategy = "horizontal",
    file_previewer = previewers.vim_buffer_cat.new,
    grep_previewer = previewers.vim_buffer_vimgrep.new,
    qflist_previewer = previewers.vim_buffer_qflist.new,
    scroll_strategy = "cycle",
    selection_strategy = "reset",
    layout_strategy = "horizontal",
    layout_defaults = {
      horizontal = {
        preview_width = 0.55
      }
    },
    -- layout_defaults = {
    --   horizontal = {
    --     width_padding = 0.1,
    --     height_padding = 0.1,
    --     preview_width = 0.6
    --   },
    --   vertical = {
    --     width_padding = 0.05,
    --     height_padding = 1,
    --     preview_height = 0.5
    --   }
    -- },
    -- layout_defaults = {
    --   horizontal = {
    --     width_padding = 0.05,
    --     height_padding = 0.1,
    --     preview_width = 0.3
    --   },
    --   vertical = {
    --     width_padding = 0.05,
    --     height_padding = 1,
    --     preview_height = 0.5
    --   }
    -- },
    sorting_strategy = "descending",
    prompt_position = "bottom",
    color_devicons = true,
    use_less = true,
    set_env = {
      ["BAT_THEME"] = "gruvbox",
      ["COLORTERM"] = "truecolor"
    }, -- default = nil,
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<C-c>"] = actions.close,
        ["<c-x>"] = false,
        -- ["<CR>"] = actions.select_default,
        ["<CR>"] = actions.select_vertical,
        -- ["<c-s>"] = actions.goto_file_selection_split
        ["<C-q>"] = actions.send_to_qflist
      }
    },
    borderchars = {
      {"─", "│", "─", "│", "╭", "╮", "╯", "╰"},
      preview = {"─", "│", "─", "│", "╭", "╮", "╯", "╰"}
    }
    -- file_sorter = sorters.get_fzy_sorter
  }

  require("telescope").setup({defaults = telescope_config})
end

-- _G.no_preview = function()
--   return require("telescope.themes").get_dropdown(
--     {
--       borderchars = {
--         {"─", "│", "─", "│", "┌", "┐", "┘", "└"},
--         prompt = {"─", "│", " ", "│", "┌", "┐", "│", "│"},
--         results = {"─", "│", "─", "│", "├", "┤", "┘", "└"},
--         preview = {"─", "│", "─", "│", "┌", "┐", "┘", "└"}
--       },
--       width = 0.8,
--       previewer = false,
--       prompt_title = false
--     }
--   )
-- end

-- then use it on whatever picker you want
-- ex:
--
-- mega.map("n", "<leader>ff", ":lua require('telescope.builtin').current_buffer_fuzzy_find(v:lua.no_preview())<cr>")
