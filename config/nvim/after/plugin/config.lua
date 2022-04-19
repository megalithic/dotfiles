local api = vim.api
local fn = vim.fn
local fmt = string.format
local conf = mega.conf

conf("nvim-web-devicons", {})

conf("startuptime", function()
  vim.g.startuptime_tries = 10
end)

conf("bullets.vim", function()
  vim.g.bullets_enabled_file_types = {
    "markdown",
    "text",
    "gitcommit",
    "scratch",
  }
  vim.g.bullets_checkbox_markers = " ○◐✗"
  vim.g.bullets_set_mappings = 0
  -- vim.g.bullets_outline_levels = { "num" }

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
end)

conf("dressing", {
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
}, { enabled = false })

-- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/init.lua#L815-L832
conf("gitlinker", {})

conf("vim-gh-line", function()
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
end)

conf("fidget", {
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

conf("lsp_signature", {
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

conf("git-conflict", {
  disable_diagnostics = true,
  highlights = {
    incoming = "DiffText",
    current = "DiffAdd",
  },
})

conf("vim-matchup", function()
  vim.g.matchup_surround_enabled = true
  vim.g.matchup_matchparen_deferred = true
  vim.g.matchup_matchparen_offscreen = {
    method = "popup",
    fullwidth = true,
    highlight = "Normal",
    border = "shadow",
  }
end)

conf("mini.indentscope", {
  symbol = "│",
  delay = "100",
})

conf("hclipboard", function(plug)
  if plug == nil then
    return
  end

  plug.start()
end)

conf("cinnamon", {
  extra_keymaps = true,
})

conf("neoscroll", function(plug)
  if plug == nil then
    return
  end

  local mappings = {}
  plug.setup({
    stop_eof = true,
    hide_cursor = true,
    -- easing_function = "circular",
  })

  mappings["<C-u>"] = { "scroll", { "-vim.wo.scroll", "true", "80" } }
  mappings["<C-d>"] = { "scroll", { "vim.wo.scroll", "true", "80" } }
  mappings["<C-b>"] = { "scroll", { "-vim.api.nvim_win_get_height(0)", "true", "250" } }
  mappings["<C-f>"] = { "scroll", { "vim.api.nvim_win_get_height(0)", "true", "250" } }
  mappings["<C-y>"] = { "scroll", { "-0.10", "false", "80" } }
  mappings["<C-e>"] = { "scroll", { "0.10", "false", "80" } }
  mappings["zt"] = { "zt", { "150" } }
  -- mappings["zz"] = { "zz", { "0" } }
  mappings["zb"] = { "zb", { "150" } }

  require("neoscroll.config").set_mappings(mappings)
end)

conf("trouble", {
  auto_close = true,
})

conf("FixCursorHold", function()
  -- https://github.com/antoinemadec/FixCursorHold.nvim#configuration
  vim.g.cursorhold_updatetime = 100
end)

conf("Comment", {
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

conf("colorizer", { "*" }, {
  mode = "background",
})

conf("virt-column", { char = "│", virtcolumn = tostring(vim.g.default_colorcolumn) })

conf("golden_size", function(plug)
  if plug == nil then
    return
  end

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

  plug.set_ignore_callbacks({
    {
      ignore_by_filetype,
      {
        "help",
        "toggleterm",
        "terminal",
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
    { plug.ignore_float_windows }, -- default one, ignore float windows
    { plug.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
  })
end)

conf("nvim-autopairs", function(plug)
  if plug == nil then
    return
  end

  plug.setup({
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
  plug.add_rules(require("nvim-autopairs.rules.endwise-ruby"))
  local endwise = require("nvim-autopairs.ts-rule").endwise
  plug.add_rules({
    endwise("then$", "end", "lua", nil),
    endwise("do$", "end", "lua", nil),
    endwise("function%(.*%)$", "end", "lua", nil),
    endwise(" do$", "end", "elixir", nil),
  })
  -- REF: neat stuff:
  -- https://github.com/rafamadriz/NeoCode/blob/main/lua/modules/plugins/completion.lua#L130-L192
end)

conf("lightspeed", function(plug)
  if plug == nil then
    return
  end

  vim.cmd("packadd lightspeed.nvim")
  plug.setup({
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
    exit_after_idle_msecs = { unlabeled = 1000, labeled = 1500 },
    --- s/x ---
    jump_to_unique_chars = { safety_timeout = 400 }, -- jump right after the first input, if the target character is unique in the search direction
    match_only_the_start_of_same_char_seqs = true, -- separator line will not snatch up all the available labels for `==` or `--`
    substitute_chars = { ["\r"] = "¬" }, -- highlighted matches by the given characters
    special_keys = { -- switch to the next/previous group of matches, when there are more matches than labels available
      next_match_group = "<space>",
      prev_match_group = "<tab>",
    },
    force_beacons_into_match_width = false,
    --- f/t ---
    limit_ft_matches = 4, -- For 1-character search, the next 'n' matches will be highlighted after [count]
    repeat_ft_with_target_char = false, -- repeat f/t motions by pressing the target character repeatedly
  })
end)

conf("hop", function(plug)
  if plug == nil then
    return
  end

  vim.cmd("packadd hop.nvim")
  plug.setup({
    -- remove h,j,k,l from hops list of keys
    keys = "etovxqpdygfbzcisuran",
    jump_on_sole_occurrence = true,
    uppercase_labels = false,
  })
  nnoremap("s", function()
    plug.hint_char1({ multi_windows = false })
  end)
  -- NOTE: override F/f using hop motions
  vim.keymap.set({ "x", "n" }, "F", function()
    plug.hint_char1({
      direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
      current_line_only = true,
      inclusive_jump = false,
    })
  end)
  vim.keymap.set({ "x", "n" }, "f", function()
    plug.hint_char1({
      direction = require("hop.hint").HintDirection.AFTER_CURSOR,
      current_line_only = true,
      inclusive_jump = false,
    })
  end)
  onoremap("F", function()
    plug.hint_char1({
      direction = require("hop.hint").HintDirection.BEFORE_CURSOR,
      current_line_only = true,
      inclusive_jump = true,
    })
  end)
  onoremap("f", function()
    plug.hint_char1({
      direction = require("hop.hint").HintDirection.AFTER_CURSOR,
      current_line_only = true,
      inclusive_jump = true,
    })
  end)
end, { enabled = false })

conf("git-messenger", function()
  vim.g.git_messenger_floating_win_opts = { border = mega.get_border() }
  vim.g.git_messenger_no_default_mappings = true
  vim.g.git_messenger_max_popup_width = 100
  vim.g.git_messenger_max_popup_height = 100
end)

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

conf("dap", function(plug)
  if plug == nil then
    return
  end

  plug.adapters.mix_task = {
    type = "executable",
    command = fn.stdpath("data") .. "/elixir-ls/debugger.sh",
    args = {},
  }
  plug.configurations.elixir = {
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
end)

conf("vim-test", function()
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
    termsplit = function(cmd)
      vim.cmd(
        fmt("vert new | set filetype=test | call termopen(['zsh', '-ci', 'eval $(desk load); %s'], {'curwin':1})", cmd)
      )
    end,
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
    trial = function(cmd)
      local system = vim.fn.system

      local terminal_notifier_notifier = function(c, exit)
        if exit == 0 then
          print("Success!")
          system(
            string.format([[/usr/local/bin/terminal-notifier -title "Neovim" -subtitle "%s" -message "Success!"]], c)
          )
        else
          print("Failure!")
          system(string.format([[/usr/local/bin/terminal-notifier -title "Neovim" -subtitle "%s" -message "Fail!"]], c))
        end
      end

      local winnr = vim.fn.winnr()
      local nil_buf_id = 999999
      local term_buf_id = nil_buf_id

      local function open(c, w, n)
        -- delete the current buffer if it's still open
        if vim.api.nvim_buf_is_valid(term_buf_id) then
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end

        vim.cmd("botright new | lua vim.api.nvim_win_set_height(0, 15)")
        term_buf_id = vim.api.nvim_get_current_buf()
        vim.opt_local.filetype = "terminal"
        vim.opt_local.number = false
        vim.opt_local.cursorline = false
        nmap("q", function()
          vim.api.nvim_buf_delete(term_buf_id, { force = true })
          term_buf_id = nil_buf_id
        end, { buffer = term_buf_id })

        vim.fn.termopen(c, {
          on_exit = function(_jobid, exit_code, _event)
            if n then
              n(c, exit_code)
            end

            if exit_code == 0 then
              vim.api.nvim_buf_delete(term_buf_id, { force = true })
              term_buf_id = nil_buf_id
            end
          end,
        })

        print(c)

        vim.cmd([[normal! G]])
        vim.cmd(w .. [[wincmd w]])
      end

      open(fmt("eval $(desk load); %s", cmd), winnr, terminal_notifier_notifier)
    end,
  }

  vim.g["test#strategy"] = {
    nearest = "trial",
    file = "toggleterm_f",
    suite = "toggleterm_f",
    last = "toggleterm_f",
  }
end)

conf("numb", {})

conf("bufdel", {
  next = "cycle", -- or 'alternate'
  quit = true,
})

conf("tabout", {
  completion = false,
  ignore_beginning = false,
})

conf("headlines", {
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

conf("dirbuf", {
  hash_padding = 2,
  show_hidden = true,
  sort_order = "directories_first",
})

conf("bqf", {
  auto_enable = true,
  preview = { auto_preview = true },
})

-- FIXME: https://github.com/SmiteshP/nvim-gps/issues/89
conf("nvim-gps", {
  languages = {
    heex = false,
    elixir = false,
    eelixir = false,
  },
}, { enabled = false })

conf("pqf", {})

conf("regexplainer", {})

conf("dd", {
  timeout = 500,
}, { enabled = false })

conf("fzf_gitignore", function()
  vim.g.fzf_gitignore_no_maps = true
end)

conf("notify", function(plug)
  if plug == nil then
    return
  end

  local renderer = require("notify.render")
  plug.setup({
    stages = "fade_in_slide_out",
    timeout = 3000,
    render = function(bufnr, notif, highlights)
      if notif.title[1] == "" then
        return renderer.minimal(bufnr, notif, highlights)
      end
      return renderer.default(bufnr, notif, highlights)
    end,
  })
end)

-- conf("treesitter-context", {})
