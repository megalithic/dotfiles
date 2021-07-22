-- [orgmode] -------------------------------------------------------------------
do
  require("orgmode").setup(
    {
      org_agenda_files = {"~/Library/Mobile Documents/com~apple~CloudDocs/org/*"},
      org_default_notes_file = "~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org"
    }
  )
end

-- [zk.nvim] -------------------------------------------------------------------
do
  require("zk").setup({debug = true})
end

-- [trouble] ---------------------------------------------------------------
do
  require("trouble").setup({})
end

-- [bullets.vim] ---------------------------------------------------------------
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

-- [fixcursorhold] -------------------------------------------------------------
do
  vim.g.cursorhold_updatetime = 100
end

-- [lspsaga] -------------------------------------------------------------------
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

-- [beacon] --------------------------------------------------------------------
do
  vim.g.beacon_size = 90
  vim.g.beacon_minimal_jump = 25
  -- vim.g.beacon_shrink = 0
  -- vim.g.beacon_fade = 0
  vim.g.beacon_ignore_filetypes = {"fzf"}
end

-- [surround] ------------------------------------------------------------------
-- vim.g.surround_mappings_style = "surround"
-- require "surround".setup {}

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
do
  -- disable the default highlight group
  vim.g.conflict_marker_highlight_group = ""
  -- Include text after begin and end markers
  vim.g.conflict_marker_begin = "^<<<<<<< .*$"
  vim.g.conflict_marker_end = "^>>>>>>> .*$"
end

-- [nvim-colorizer] ------------------------------------------------------------
-- https://github.com/norcalli/nvim-colorizer.lua/issues/4#issuecomment-543682160
do
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
end

-- [golden_size] ---------------------------------------------------------------
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

-- [nvim-autopairs] ------------------------------------------------------------
do
  require("nvim-autopairs").setup({
    map_cr = true, --  map <CR> on insert mode
    map_complete = false -- it will auto insert `(` after select function or method item
  })
end


-- [vim-polyglot] --------------------------------------------------------------
do
  vim.g.polyglot_disabled = {}
end

-- [quickscope] ----------------------------------------------------------------
do
  vim.g.qs_enable = 1
  vim.g.qs_highlight_on_keys = {"f", "F", "t", "T"}
  vim.g.qs_buftype_blacklist = {"terminal", "nofile"}
  vim.g.qs_lazy_highlight = 1
end

-- [textobj_parameter] ---------------------------------------------------------
do
  vim.g.vim_textobj_parameter_mapping = ","
end

-- [git_messenger] -------------------------------------------------------------
do
  vim.g.git_messenger_no_default_mappings = true
  vim.g.git_messenger_max_popup_width = 100
  vim.g.git_messenger_max_popup_height = 100
end

-- [vim-test] ------------------------------------------------------------------
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

-- [nvim-treesitter] -----------------------------------------------------------
do
  local ts_installed, treesitter = pcall(require, "nvim-treesitter.configs")
  if ts_installed then
    treesitter.setup(
      {
        ensure_installed = "maintained",
        highlight = {
          enable = true,
          use_languagetree = true
        },
        indent = {enable = true},
        autotag = {
          enable = true
        },
        textobjects = {
          select = {
            enable = true,
            keymaps = {
              ["if"] = "@function.inner",
              ["af"] = "@function.outer",
              ["ik"] = "@call.inner",
              ["ak"] = "@call.outer",
              ["il"] = "@loop.inner",
              ["al"] = "@loop.outer",
              ["ic"] = "@conditional.inner",
              ["ac"] = "@conditional.outer"
            }
          }
        }
      }
    )
  end
end

-- [vim-projectionist] ---------------------------------------------------------
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

do
  local telescope = require("telescope")
  local actions = require("telescope.actions")

  telescope.setup({
    defaults =
      {
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
            ["<C-o>"] = actions.select_default,
          },
        }
      } ,
  })
end
