local api = vim.api
local fn = vim.fn
local fmt = string.format

local function conf(plugin)
  if pcall(require, plugin) then
    require("mega.plugins." .. plugin)
  end
end

-- NOTE: source order matters! =================================================

-- [ EXPLICIT PLUGIN CONFIGS ] -------------------------------------------------

require("nvim-web-devicons").setup()
conf("telescope")
conf("toggleterm")
conf("cmp")
conf("zk")
conf("projectionist")

-- [ THE REST ] ----------------------------------------------------------------

do -- vim-startuptime
  vim.g.startuptime_tries = 10
end

do -- bullets.vim
  vim.cmd([[
      " Disable default bullets.vim mappings, clashes with other mappings
      let g:bullets_set_mappings = 0
      " let g:bullets_checkbox_markers = '✗○◐●✓'
      let g:bullets_checkbox_markers = ' .oOx'

      " Add custom bullets mappings that don't clash with other mappings
      function! InsertNewBullet()
        InsertNewBullet
        return ''
      endfunction

        " \ inoremap <buffer><expr> <cr> (pumvisible() ? '<C-y>' : '<C-]><C-R>=InsertNewBullet()<cr>')|
      autocmd FileType markdown,text,gitcommit
        \ nnoremap <buffer> o :InsertNewBullet<cr>|
        \ nnoremap cx :ToggleCheckbox<cr>
        \ nmap <C-x> :ToggleCheckbox<cr>
    ]])
end

do
  if false then
    require("dressing").setup({
      input = {
        insert_only = false,
        winblend = 2,
        border = mega.get_border(),
      },
      select = {
        winblend = 2,
        -- FIXME: still complains with deprecation warning; no bueno..
        telescope = require("telescope.themes").get_cursor({
          layout_config = {
            -- NOTE: the limit is half the max lines because this is the cursor theme so
            -- unless the cursor is at the top or bottom it realistically most often will
            -- only have half the screen available
            height = function(self, _, max_lines)
              local results = #self.finder.results
              local PADDING = 4 -- this represents the size of the telescope window
              local LIMIT = math.floor(max_lines / 2)
              return (results <= (LIMIT - PADDING) and results + PADDING or LIMIT)
            end,
          },
        }),
      },
    })
  end
end

do -- vim-gh-line_config
  if fn.exists("g:loaded_gh_line") then
    vim.g["gh_line_map_default"] = 0
    vim.g["gh_line_blame_map_default"] = 0
    vim.g["gh_line_map"] = "<leader>gH"
    vim.g["gh_line_blame_map"] = "<leader>gB"
    vim.g["gh_repo_map"] = "<leader>gO"

    -- Use a custom program to open link:
    -- let g:gh_open_command = 'open '
    -- Copy link to a clipboard instead of opening a browser:
    -- let g:gh_open_command = 'fn() { echo "$@" | pbcopy; }; fn '
  end
end

do -- fidget.nvim
  require("fidget").setup({
    text = {
      spinner = "dots_pulse",
      done = "",
    },
    window = {
      blend = 10,
    },
    sources = { -- Sources to configure
      ["elixirls"] = { -- Name of source
        ignore = false, -- Ignore notifications from this source
      },
    },
  })
end

do -- lsp_signature.nvim
  if false then
    require("lsp_signature").setup({
      bind = true,
      fix_pos = false,
      auto_close_after = 3,
      hint_enable = false,
      handler_opts = { border = mega.get_border() },
      --   hi_parameter = "QuickFixLine",
      --   handler_opts = {
      --     border = vim.g.floating_window_border,
      --   },
    })
  end
end

do -- git-conflict.nvim
  require("git-conflict").setup({
    disable_diagnostics = true,
    highlights = {
      incoming = "DiffText",
      current = "DiffAdd",
    },
  })
end

do -- gitlinker.nvim
  -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L815-L832
  require("gitlinker").setup()
end

do -- vim-matchup
  vim.g.matchup_surround_enabled = true
  vim.g.matchup_matchparen_deferred = true
  vim.g.matchup_matchparen_offscreen = {
    method = "popup",
    fullwidth = true,
    highlight = "Normal",
    border = "shadow",
  }
end

do
  require("mini.indentscope").setup({
    symbol = "│",
    delay = "100",
  })
end

do -- nvim-hclipboard
  require("hclipboard").start()
end

do -- neoscroll
  local mappings = {}
  require("neoscroll").setup({
    -- mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "zt", "zz", "zb" },
    stop_eof = false,
    hide_cursor = false,
    easing_function = "circular",
  })
  mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } }
  mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } }
  mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "250" } }
  mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "250" } }
  mappings["<C-y>"] = { "scroll", { "-0.10", "false", "80" } }
  mappings["<C-e>"] = { "scroll", { "0.10", "false", "80" } }
  mappings["zt"] = { "zt", { "150" } }
  mappings["zz"] = { "zz", { "150" } }
  mappings["zb"] = { "zb", { "150" } }
  require("neoscroll.config").set_mappings(mappings)
end

do -- trouble.nvim
  require("trouble").setup({ auto_close = true })
end

do -- bullets
  vim.g.bullets_enabled_file_types = {
    "markdown",
    "text",
    "gitcommit",
    "scratch",
  }
  vim.g.bullets_checkbox_markers = " ○◐✗"
  vim.g.bullets_set_mappings = 0
  -- vim.g.bullets_outline_levels = { "num" }
end

do -- cursorhold
  -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
  vim.g.cursorhold_updatetime = 100
end

do -- comment.nvim
  require("Comment").setup({
    ignore = "^$",
    pre_hook = function(ctx)
      local U = require("Comment.utils")

      local location = nil
      if ctx.ctype == U.ctype.block then
        location = require("ts_context_commentstring.utils").get_cursor_location()
      elseif ctx.cmotion == U.cmotion.v or ctx.cmotion == U.cmotion.V then
        location = require("ts_context_commentstring.utils").get_visual_start_location()
      end

      return require("ts_context_commentstring.internal").calculate_commentstring({
        key = ctx.ctype == U.ctype.line and "__default" or "__multiline",
        location = location,
      })
    end,
  })
end

do -- colorizer.nvim
  require("colorizer").setup({ "*" }, {
    mode = "background",
  })
end

do -- golden_size.nvim
  local golden_size_installed, golden_size = pcall(require, "golden_size")
  if golden_size_installed then
    local function ignore_by_buftype(types)
      local buftype = api.nvim_buf_get_option(api.nvim_get_current_buf(), "buftype")
      for _, type in pairs(types) do
        -- mega.log(fmt("type: %s / buftype: %s", type, buftype))

        if type == buftype then
          return 1
        end
      end
    end
    local function ignore_by_filetype(types)
      local filetype = api.nvim_buf_get_option(api.nvim_get_current_buf(), "filetype")
      for _, type in pairs(types) do
        -- mega.log(fmt("type: %s / filetype: %s", type, filetype))

        if type == filetype then
          return 1
        end
      end
    end

    golden_size.set_ignore_callbacks({
      {
        ignore_by_filetype,
        {
          "help",
          "toggleterm",
          "dirbuf",
          "Trouble",
          "qf",
        },
        ignore_by_buftype,
        {
          "help",
          "acwrite",
          "Undotree",
          "quickfix",
          "nerdtree",
          "current",
          "Vista",
          "Trouble",
          "LuaTree",
          "NvimTree",
          "terminal",
          "nofile",
          "tsplayground",
        },
      },
      { golden_size.ignore_float_windows }, -- default one, ignore float windows
      { golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
    })
  end
end

do -- nvim-autopairs
  local npairs = require("nvim-autopairs")
  npairs.setup({
    disable_filetype = { "TelescopePrompt" },
    -- enable_afterquote = true, -- To use bracket pairs inside quotes
    enable_check_bracket_line = true, -- Check for closing brace so it will not add a close pair
    disable_in_macro = false,
    close_triple_quotes = true,
    check_ts = true,
    ts_config = {
      lua = { "string", "source" },
      javascript = { "string", "template_string" },
      java = false,
    },
  })
  npairs.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
  local endwise = require("nvim-autopairs.ts-rule").endwise
  npairs.add_rules({
    endwise("then$", "end", "lua", nil),
    endwise("do$", "end", "lua", nil),
    endwise("function%(.*%)$", "end", "lua", nil),
    endwise(" do$", "end", "elixir", nil),
  })
  -- REF: neat stuff:
  -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
end

do -- lightspeed.nvim or hop.nvim; testing them both out
  if true then
    vim.cmd("packadd lightspeed.nvim")
    require("lightspeed").setup({
      -- jump_to_first_match = true,
      -- jump_on_partial_input_safety_timeout = 400,
      -- This can get _really_ slow if the window has a lot of content,
      -- turn it on only if your machine can always cope with it.
      -- jump_to_unique_chars = true,
      -- jump_to_unique_chars = false,
      -- safe_labels = {},
      -- jump_to_unique_chars = true,
      -- limit_ft_matches = 7,
      -- grey_out_search_area = true,
      -- match_only_the_start_of_same_char_seqs = true,
      -- limit_ft_matches = 5,
      -- full_inclusive_prefix_key = '<c-x>',
      -- By default, the values of these will be decided at runtime,
      -- based on `jump_to_first_match`.
      -- labels = nil,
      -- cycle_group_fwd_key = nil,
      -- cycle_group_bwd_key = nil,
      --
      ignore_case = false,
      exit_after_idle_msecs = { unlabeled = 1000, labeled = nil },
      --- s/x ---
      jump_to_unique_chars = { safety_timeout = 400 },
      match_only_the_start_of_same_char_seqs = true,
      force_beacons_into_match_width = false,
      -- Display characters in a custom way in the highlighted matches.
      substitute_chars = { ["\r"] = "¬" },
      -- Leaving the appropriate list empty effectively disables "smart" mode,
      -- and forces auto-jump to be on or off.
      --safe_labels = { . . . },
      --labels = { . . . },
      -- These keys are captured directly by the plugin at runtime.
      special_keys = {
        next_match_group = "<space>",
        prev_match_group = "<tab>",
      },
      --- f/t ---
      limit_ft_matches = 4,
      repeat_ft_with_target_char = false,
    })
    -- autocmd ColorScheme * lua require'lightspeed'.init_highlight(true)
  else
    vim.cmd("packadd hop.nvim")
    local hop = require("hop")
    hop.setup({
      -- remove h,j,k,l from hops list of keys
      keys = "etovxqpdygfbzcisuran",
      jump_on_sole_occurrence = true,
      uppercase_labels = false,
    })
    nnoremap("s", function()
      hop.hint_char1({ multi_windows = false })
    end)
    -- NOTE: override F/f using hop motions
    vim.keymap.set({ "x", "n" }, "F", function()
      hop.hint_char1({
        direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
        current_line_only = true,
        inclusive_jump = false,
      })
    end)
    vim.keymap.set({ "x", "n" }, "f", function()
      hop.hint_char1({
        direction = require("hop.hint").HintDirection.AFTER_CURSOR,
        current_line_only = true,
        inclusive_jump = false,
      })
    end)
    onoremap("F", function()
      hop.hint_char1({
        direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
        current_line_only = true,
        inclusive_jump = true,
      })
    end)
    onoremap("f", function()
      hop.hint_char1({
        direction = require("hop.hint").HintDirection.AFTER_CURSOR,
        current_line_only = true,
        inclusive_jump = true,
      })
    end)
  end
end

do -- git-messenger.nvim
  vim.g.git_messenger_floating_win_opts = { border = mega.get_border() }
  vim.g.git_messenger_no_default_mappings = true
  vim.g.git_messenger_max_popup_width = 100
  vim.g.git_messenger_max_popup_height = 100
end

do -- firenvim
  -- REFS:
  -- * https://github.com/cgardner/dotfiles-bare/blob/master/.config/nvim/lua/plugins/firenvim.lua#L3-L9
  vim.g.firenvim_config = {
    globalSettings = {
      alt = "all",
    },
    localSettings = {
      [".*"] = {
        cmdline = "neovim",
        content = "text",
        priority = 0,
        selector = "textarea",
        takeover = "never", -- disable until called with firefox hotkey <C-e>
      },
    },
  }

  if vim.g.started_by_firenvim then
    print("hi from started by firenvim")

    vim.opt.cmdheight = 1
    -- selene: allow(global_usage)
    function _G.set_firenvim_settings()
      local min_lines = 18
      if vim.opt.lines < min_lines then
        vim.opt.lines = min_lines
      end

      vim.opt.guifont = [[Jetbrains Nerd Font:h13]]
      vim.opt.wrap = true
      vim.opt.number = false
      vim.opt.relativenumber = false
      vim.opt.signcolumn = "no"
      vim.opt.list = true
      vim.opt.linebreak = true
      vim.opt.breakindentopt = true
      vim.opt.colorcolumn = 0
      vim.cmd("startinsert")
    end

    vim.cmd([[
        function! OnUIEnter(event) abort
          if 'Firenvim' ==# get(get(nvim_get_chan_info(a:event.chan), 'client', {}), 'name', '')
            echom "hi!"
            lua _G.set_firenvim_settings()
          endif
        endfunction
        autocmd UIEnter * call OnUIEnter(deepcopy(v:event))
        au BufEnter github.com_*.txt,gitlab.com_*.txt,mattermost.*.txt,mail.google.com_*.txt set filetype=markdown
        au BufEnter mail.google.com_*.txt set tw=80
      ]])
  end
end

do -- nvim-dap
  local dap = require("dap")
  dap.adapters.mix_task = {
    type = "executable",
    command = fn.stdpath("data") .. "/elixir-ls/debugger.sh",
    args = {},
  }
  dap.configurations.elixir = {
    {
      type = "mix_task",
      name = "mix test",
      task = "test",
      taskArgs = { "--trace" },
      request = "launch",
      startApps = true, -- for Phoenix projects
      projectDir = "${workspaceFolder}",
      requireFiles = {
        "test/**/test_helper.exs",
        "test/**/*_test.exs",
      },
    },
  }
end

do -- vim-test
  -- REF:
  -- neat ways to detect jest things
  -- https://github.com/weilbith/vim-blueplanet/blob/master/pack/plugins/start/test_/autoload/test/typescript/jest.vim
  -- https://github.com/roginfarrer/dotfiles/blob/main/nvim/.config/nvim/lua/rf/plugins/vim-test.lua#L19
  vim.g["test#strategy"] = "neovim"
  vim.g["test#javascript#jest#file_pattern"] = "\v(__tests__/.*|(spec|test)).(js|jsx|coffee|ts|tsx)$"
  vim.g["test#ruby#use_binstubs"] = 0
  vim.g["test#ruby#bundle_exec"] = 0
  vim.g["test#filename_modifier"] = ":."
  vim.g["test#preserve_screen"] = 0

  vim.g["test#custom_strategies"] = {
    toggleterm = function(cmd)
      P(fmt("cmd: %s", cmd))
      require("toggleterm").exec(cmd)
    end,
    toggleterm_f = function(cmd)
      P(fmt("f_cmd: %s", cmd))
      require("toggleterm").exec_command(fmt([[cmd="%s" direction=float]], cmd))
    end,
    toggleterm_h = function(cmd)
      P(fmt("h_cmd: %s", cmd))
      require("toggleterm").exec_command(fmt([[cmd="%s" direction=horizontal]], cmd))
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "toggleterm_f",
    file = "toggleterm_f",
    suite = "toggleterm_f",
    last = "toggleterm_f",
  }
end

do -- numb.nvim
  require("numb").setup()
end

do -- nvim-bufdel
  require("bufdel").setup({
    next = "cycle", -- or 'alternate'
    quit = true,
  })
end

do -- tabout.nvim
  require("tabout").setup({
    completion = false,
    ignore_beginning = false,
  })
end

do -- headlines.nvim
  -- fn.sign_define("Headline1", { linehl = "Headline1" })
  -- fn.sign_define("Headline2", { linehl = "Headline2" })
  -- fn.sign_define("Headline3", { linehl = "Headline3" })
  -- fn.sign_define("Headline4", { linehl = "Headline4" })
  -- fn.sign_define("Headline5", { linehl = "Headline5" })
  -- fn.sign_define("Headline6", { linehl = "Headline6" })

  require("headlines").setup({
    markdown = {
      source_pattern_start = "^```",
      source_pattern_end = "^```$",
      dash_pattern = "^---+$",
      dash_highlight = "Dash",
      dash_string = "―",
      headline_pattern = "^#+",
      headline_highlights = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
      codeblock_highlight = "CodeBlock",
    },
    yaml = {
      dash_pattern = "^---+$",
      dash_highlight = "Dash",
    },
  })
end

do -- dirbuf.nvim
  require("dirbuf").setup({
    hash_padding = 2,
    show_hidden = true,
    sort_order = "directories_first",
  })
end

do -- dd.nvim
  -- require("dd").setup({ timeout = 500 })
end

do -- misc
  vim.g.fzf_gitignore_no_maps = true
end

do -- gitsigns.nvim
  local gs = require("gitsigns")
  gs.setup({
    signs = {
      add = { hl = "GitSignsAdd", text = "▎" }, -- ┃, │, ▌, ▎
      change = { hl = "GitSignsChange", text = "▎" }, -- ║▎
      delete = { hl = "GitSignsDelete", text = "▎" },
      topdelete = { hl = "GitSignsDelete", text = "▌" },
      changedelete = { hl = "GitSignsChange", text = "▌" },
    },
    word_diff = false,
    numhl = false,
    current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
      delay = 1000,
      ignore_whitespace = false,
    },
    current_line_blame_formatter_opts = {
      relative_time = false,
    },
    keymaps = {
      -- Default keymap options
      noremap = true,
      buffer = true,
      ["n [h"] = { expr = true, "&diff ? ']h' : '<cmd>lua require\"gitsigns\".next_hunk()<CR>'" },
      ["n ]h"] = { expr = true, "&diff ? '[h' : '<cmd>lua require\"gitsigns\".prev_hunk()<CR>'" },
      ["n <localleader>gw"] = "<cmd>lua require\"gitsigns\".stage_buffer()<CR>",
      ["n <localleader>gre"] = "<cmd>lua require\"gitsigns\".reset_buffer()<CR>",
      ["n <localleader>gbl"] = "<cmd>lua require\"gitsigns\".blame_line()<CR>",
      ["n <localleader>gbd"] = "<cmd>lua require\"gitsigns\".toggle_word_diff()<CR>",
      ["n <leader>lm"] = "<cmd>lua require\"gitsigns\".setqflist(\"all\")<CR>",
      -- Text objects
      ["o ih"] = ":<C-U>lua require\"gitsigns\".select_hunk()<CR>",
      ["x ih"] = ":<C-U>lua require\"gitsigns\".select_hunk()<CR>",
      ["n <leader>hs"] = "<cmd>lua require\"gitsigns\".stage_hunk()<CR>",
      ["v <leader>hs"] = "<cmd>lua require\"gitsigns\".stage_hunk({vim.fn.line(\".\"), vim.fn.line(\"v\")})<CR>",
      ["n <leader>hu"] = "<cmd>lua require\"gitsigns\".undo_stage_hunk()<CR>",
      ["n <leader>hr"] = "<cmd>lua require\"gitsigns\".reset_hunk()<CR>",
      ["v <leader>hr"] = "<cmd>lua require\"gitsigns\".reset_hunk({vim.fn.line(\".\"), vim.fn.line(\"v\")})<CR>",
      ["n <leader>hp"] = "<cmd>lua require\"gitsigns\".preview_hunk()<CR>",
      ["n <leader>hb"] = "<cmd>lua require\"gitsigns\".blame_line()<CR>",
    },
  })
end

do -- formatter.nvim
  local formatter = require("formatter")
  local prettierConfig = function()
    return {
      exe = "prettier",
      args = { "--stdin-filepath", fn.shellescape(api.nvim_buf_get_name(0)), "--single-quote" },
      stdin = true,
    }
  end

  local formatterConfig = {
    lua = {
      function()
        return {
          -- exe = "stylua -s --stdin-filepath ${INPUT} -",
          exe = "stylua",
          args = { "-" },
          stdin = true,
        }
      end,
    },
    vue = {
      function()
        return {
          exe = "prettier",
          args = {
            "--stdin-filepath",
            fn.fnameescape(api.nvim_buf_get_name(0)),
            "--single-quote",
            "--parser",
            "vue",
          },
          stdin = true,
        }
      end,
    },
    rust = {
      -- Rustfmt
      function()
        return {
          exe = "rustfmt",
          args = { "--emit=stdout" },
          stdin = true,
        }
      end,
    },
    swift = {
      -- Swiftlint
      function()
        return {
          exe = "swift-format",
          args = { api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },
    sh = {
      -- Shell Script Formatter
      function()
        return {
          exe = "shfmt",
          args = { "-i", 2 },
          stdin = true,
        }
      end,
    },
    heex = {
      function()
        return {
          exe = "mix",
          args = { "format", api.nvim_buf_get_name(0) },
          stdin = true,
        }
      end,
    },
    elixir = {
      function()
        return {
          exe = "mix",
          args = { "format", "-" },
          stdin = true,
        }
      end,
    },
    ["*"] = {
      function()
        return {
          -- remove trailing whitespace
          exe = "sed",
          args = { "-i", "'s/[ \t]*$//'" },
          stdin = false,
        }
      end,
    },
  }
  local commonFT = {
    "css",
    "scss",
    "html",
    "java",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "markdown",
    "markdown.mdx",
    "json",
    "yaml",
    "xml",
    "svg",
  }
  for _, ft in ipairs(commonFT) do
    formatterConfig[ft] = { prettierConfig }
  end
  -- Setup functions
  formatter.setup({
    logging = true,
    filetype = formatterConfig,
  })
end

do -- vim-notify
  local has_notify, notify = pcall(require, "notify")
  ---@type table<string, fun(bufnr: number, notif: table, highlights: table)>
  if has_notify then
    local renderer = require("notify.render")
    notify.setup({
      stages = "fade_in_slide_out",
      timeout = 3000,
      render = function(bufnr, notif, highlights)
        if notif.title[1] == "" then
          return renderer.minimal(bufnr, notif, highlights)
        end
        return renderer.default(bufnr, notif, highlights)
      end,
    })
  end
  -- vim.notify = notify
  -- require("telescope").load_extension("notify")
end

do -- nvim-regexplainer
  require("regexplainer").setup()
end

do -- quickfix list things
  -- nvim-bqf
  require("bqf").setup({ auto_enable = true, preview = { auto_preview = true } })

  -- nvim-pqf
  require("pqf").setup({})
end

if vim.g.vscode ~= nil then
  conf("vscode")
end
