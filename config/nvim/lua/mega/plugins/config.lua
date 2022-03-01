local api = vim.api
local vcmd = vim.cmd
local fn = vim.fn

local function conf(plugin)
  if pcall(require, plugin) then
    require("mega.plugins." .. plugin)
  end
end

-- [ EXPLICIT ] ----------------------------------------------------------------

conf("telescope")
conf("cmp")

-- [ MISC ] --------------------------------------------------------------------

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
  require("dressing").setup({
    input = {
      insert_only = false,
      winblend = 2,
    },
    select = {
      winblend = 2,
      telescope = {
        theme = "dropdown",
      },
    },
  })
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
    sources = { -- Sources to configure
      ["elixirls"] = { -- Name of source
        ignore = false, -- Ignore notifications from this source
      },
    },
  })
end

do -- lsp_signature.nvim
  require("lsp_signature").setup({
    bind = true,
    fix_pos = false,
    auto_close_after = 5,
    hint_enable = false,
    handler_opts = { border = "rounded" },
    --   hi_parameter = "QuickFixLine",
    --   handler_opts = {
    --     border = vim.g.floating_window_border,
    --   },
  })
end

do -- gitlinker.nvim
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

do -- indent-blankline
  require("indent_blankline").setup({
    char = "│", -- ┆ ┊ 
    -- char_list = { "│", "|", "¦", "┆", "┊" },
    space_char_blankline = " ",
    show_foldtext = false,
    show_current_context = true,
    show_current_context_start = true,
    show_first_indent_level = true,
    show_end_of_line = true,
    indent_blankline_use_treesitter = true,
    indent_blankline_show_trailing_blankline_indent = false,
    filetype_exclude = {
      "startify",
      "dashboard",
      "bufdir",
      "alpha",
      "log",
      "fugitive",
      "gitcommit",
      "packer",
      "vimwiki",
      "markdown",
      "json",
      "txt",
      "vista",
      "help",
      "NvimTree",
      "git",
      "fzf",
      "TelescopePrompt",
      "undotree",
      "norg",
      "org",
      "orgagenda",
      "", -- for all buffers without a file type
    },
    buftype_exclude = { "terminal", "nofile", "acwrite" },
    context_patterns = {
      "class",
      "function",
      "method",
      "block",
      "list_literal",
      "selector",
      "^if",
      "^table",
      "if_statement",
      "while",
      "for",
      "^object",
      "arguments",
      "else_clause",
      "jsx_element",
      "jsx_self_closing_element",
      "try_statement",
      "catch_clause",
      "import_statement",
      "operation_type",
    },
  })
end

do -- neoscroll
  if true then
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
end

do -- nvim-web-devicons
  require("nvim-web-devicons").setup({ default = true })
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

do -- specs.nvim
  local specs = require("specs")
  specs.setup({
    show_jumps = true,
    min_jump = 30,
    popup = {
      delay_ms = 1, -- delay before popup displays
      inc_ms = 1, -- time increments used for fade/resize effects
      blend = 10, -- starting blend, between 0-100 (fully transparent), see :h winblend
      width = 100,
      winhl = "PMenu",
      fader = specs.linear_fader,
      resizer = specs.slide_resizer,
    },
    ignore_filetypes = { "Telescope", "fzf", "NvimTree", "alpha" },
    ignore_buftypes = {
      nofile = true,
    },
  })
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

do -- conflict-marker.nvim
  -- disable the default highlight group
  vim.g.conflict_marker_highlight_group = "Error"
  -- Include text after begin and end markers
  vim.g.conflict_marker_begin = "^<<<<<<< .*$"
  vim.g.conflict_marker_end = "^>>>>>>> .*$"
end

do -- colorizer.nvim
  require("colorizer").setup({
    -- '*',
    -- '!vim',
    -- }, {
    css = { rgb_fn = true },
    scss = { rgb_fn = true },
    sass = { rgb_fn = true },
    stylus = { rgb_fn = true },
    vim = { names = false },
    tmux = { names = true },
    "toml",
    "eelixir",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "zsh",
    "fish",
    "sh",
    "conf",
    "lua",
    html = {
      mode = "foreground",
    },
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

    golden_size.set_ignore_callbacks({
      {
        ignore_by_buftype,
        {
          "acwrite",
          "Undotree",
          "quickfix",
          "nerdtree",
          "current",
          "Vista",
          "LuaTree",
          "NvimTree",
          "nofile",
          "tsplayground",
        },
      },
      { golden_size.ignore_float_windows }, -- default one, ignore float windows
      { golden_size.ignore_by_window_flag }, -- default one, ignore windows with w:ignore_gold_size=1
    })
  end
end

do -- lastplace
  if true then
    require("nvim-lastplace").setup({
      lastplace_ignore_buftype = { "quickfix", "nofile", "help", ".git/COMMIT_EDITMSG" },
      lastplace_ignore_filetype = { "gitcommit", "gitrebase", "svn", "hgcommit" },
      lastplace_open_folds = true,
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

do -- lightspeed.nvim
  -- require("lightspeed").setup({})
  -- require("lightspeed").setup({
  --   -- jump_to_first_match = true,
  --   -- jump_on_partial_input_safety_timeout = 400,
  --   -- This can get _really_ slow if the window has a lot of content,
  --   -- turn it on only if your machine can always cope with it.
  --   jump_to_unique_chars = true,
  --   -- grey_out_search_area = true,
  --   match_only_the_start_of_same_char_seqs = true,
  --   limit_ft_matches = 5,
  --   -- full_inclusive_prefix_key = '<c-x>',
  --   -- By default, the values of these will be decided at runtime,
  --   -- based on `jump_to_first_match`.
  --   -- labels = nil,
  --   -- cycle_group_fwd_key = nil,
  --   -- cycle_group_bwd_key = nil,
  -- })
end

do
  local hop = require("hop")
  -- remove h,j,k,l from hops list of keys
  hop.setup({ keys = "etovxqpdygfbzcisuran" })
  nnoremap("s", function()
    hop.hint_char1({ multi_windows = true })
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

do -- diffview.nvim
  local cb = require("diffview.config").diffview_callback

  require("diffview").setup({
    diff_binaries = false, -- Show diffs for binaries
    use_icons = true, -- Requires nvim-web-devicons
    file_panel = {
      width = 50,
    },
    enhanced_diff_hl = true,
    key_bindings = {
      disable_defaults = false, -- Disable the default key bindings
      -- The `view` bindings are active in the diff buffers, only when the current
      -- tabpage is a Diffview.
      view = {
        ["<tab>"] = cb("select_next_entry"), -- Open the diff for the next file
        ["<s-tab>"] = cb("select_prev_entry"), -- Open the diff for the previous file
        ["<leader>e"] = cb("focus_files"), -- Bring focus to the files panel
        ["<leader>b"] = cb("toggle_files"), -- Toggle the files panel.
      },
      file_panel = {
        ["j"] = cb("next_entry"), -- Bring the cursor to the next file entry
        ["<down>"] = cb("next_entry"),
        ["k"] = cb("prev_entry"), -- Bring the cursor to the previous file entry.
        ["<up>"] = cb("prev_entry"),
        ["<cr>"] = cb("select_entry"), -- Open the diff for the selected entry.
        ["o"] = cb("select_entry"),
        ["<2-LeftMouse>"] = cb("select_entry"),
        ["-"] = cb("toggle_stage_entry"), -- Stage / unstage the selected entry.
        ["S"] = cb("stage_all"), -- Stage all entries.
        ["U"] = cb("unstage_all"), -- Unstage all entries.
        ["R"] = cb("refresh_files"), -- Update stats and entries in the file list.
        ["<tab>"] = cb("select_next_entry"),
        ["<s-tab>"] = cb("select_prev_entry"),
        ["<leader>e"] = cb("focus_files"),
        ["<leader>b"] = cb("toggle_files"),
      },
    },
  })
end

do -- git.nvim
  if false then
    require("git").setup({
      keymaps = {
        -- Open blame window
        blame = "<Leader>gb",
        -- Close blame window
        quit_blame = "q",
        -- Open blame commit
        blame_commit = "<CR>",
        -- Open file/folder in git repository
        browse = "<Leader>gh",
        -- Open pull request of the current branch
        open_pull_request = "<Leader>gp",
        -- Create a pull request with the target branch is set in the `target_branch` option
        create_pull_request = "<Leader>gn",
        -- Opens a new diff that compares against the current index
        diff = "<Leader>gd",
        -- Close git diff
        diff_close = "<Leader>gD",
        -- Revert to the specific commit
        revert = "<Leader>gr",
        -- Revert the current file to the specific commit
        revert_file = "<Leader>gR",
      },
      -- Default target branch when create a pull request
      target_branch = "main",
    })
  end
end

do -- git-messenger.nvim
  vim.g.git_messenger_floating_win_opts = { border = mega.get_border() }
  vim.g.git_messenger_no_default_mappings = true
  vim.g.git_messenger_max_popup_width = 100
  vim.g.git_messenger_max_popup_height = 100
end

do -- toggleterm.nvim
  local toggleterm = require("toggleterm")
  toggleterm.setup({
    open_mapping = [[<c-\>]],
    shade_filetypes = { "none" },
    direction = "vertical",
    insert_mappings = false,
    start_in_insert = true,
    float_opts = { border = "curved", winblend = 3 },
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return math.floor(vim.o.columns * 0.4)
      end
    end,
    --   REF: @ryansch:
    --   size = function(term)
    --     if term.direction == "horizontal" then
    --       return 20
    --     elseif term.direction == "vertical" then
    --       return vim.o.columns * 0.4
    --     end
    --   end,
    persist_size = false,
    on_open = function(term)
      term.opened = term.opened or false

      if not term.opened then
        term:send("eval $(desk load)")
      end

      term.opened = true
    end,
  })

  local float_handler = function(term)
    if vim.fn.mapcheck("jk", "t") ~= "" then
      vim.api.nvim_buf_del_keymap(term.bufnr, "t", "jk")
      vim.api.nvim_buf_del_keymap(term.bufnr, "t", "<esc>")
    end
  end

  local Terminal = require("toggleterm.terminal").Terminal
  local htop = Terminal:new({
    cmd = "htop",
    hidden = "true",
    direction = "float",
    on_open = float_handler,
  })

  mega.command({
    "Htop",
    function()
      htop:toggle()
    end,
  })
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
  vim.g["test#filename_modifier"] = ":."
  vim.g["test#preserve_screen"] = 0

  if vim.fn.executable("richgo") == 1 then
    vim.g["test#go#runner"] = "richgo"
  end

  -- vcmd([[
  --   function! TerminalSplit(cmd)
  --     vert new | set filetype=test | call termopen(['zsh', '-ci', a:cmd], {'curwin':1})
  --   endfunction

  --   let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
  --   let g:test#strategy = 'terminal_split'
  -- ]])

  vcmd([[
      function! ToggleTermStrategy(cmd) abort
        call luaeval("require('toggleterm').exec(_A[1])", [a:cmd])
      endfunction
      let g:test#custom_strategies = {'toggleterm': function('ToggleTermStrategy')}
    ]])
  vim.g["test#strategy"] = "toggleterm"
end

do -- vim-projectionist
  vim.g.projectionist_heuristics = {
    ["&package.json"] = {
      ["package.json"] = {
        type = "package",
        alternate = { "yarn.lock", "package-lock.json" },
      },
      ["package-lock.json"] = {
        alternate = "package.json",
      },
      ["yarn.lock"] = {
        alternate = "package.json",
      },
    },
    ["package.json"] = {
      -- outstand'ing (ts/tsx)
      ["spec/javascript/*.test.tsx"] = {
        ["alternate"] = "app/webpacker/src/javascript/{}.tsx",
        ["type"] = "test",
      },
      ["app/webpacker/src/javascript/*.tsx"] = {
        ["alternate"] = "spec/javascript/{}.test.tsx",
        ["type"] = "source",
      },
      ["spec/javascript/*.test.ts"] = {
        ["alternate"] = "app/webpacker/src/javascript/{}.ts",
        ["type"] = "test",
      },
      ["app/webpacker/src/javascript/*.ts"] = {
        ["alternate"] = "spec/javascript/{}.test.ts",
        ["type"] = "source",
      },
    },
    -- https://github.com/dbernheisel/dotfiles/blob/master/.config/nvim/after/ftplugin/elixir.vim
    ["mix.exs"] = {
      -- "dead" views
      ["lib/**/views/*_view.ex"] = {
        ["type"] = "view",
        ["alternate"] = "test/{dirname}/views/{basename}_view_test.exs",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View do",
          "  use {dirname|camelcase|capitalize}, :view",
          "end",
        },
      },
      ["test/**/views/*_view_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/views/{basename}_view.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}ViewTest do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}View",
          "end",
        },
      },
      -- "live" views
      ["lib/**/live/*_live.ex"] = {
        ["type"] = "live",
        ["alternate"] = "test/{dirname}/live/{basename}_live_test.exs",
        ["related"] = "lib/{dirname}/live/{basename}_live.html.heex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live do",
          "  use {dirname|camelcase|capitalize}, :live_view",
          "end",
        },
      },
      ["lib/**/live/*_live.heex"] = {
        ["type"] = "heex",
        ["related"] = "lib/{dirname}/live/{basename}_live.html.ex",
      },
      ["test/**/live/*_live_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{dirname}/live/{basename}_live.ex",
        ["template"] = {
          "defmodule {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}LiveTest do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {dirname|camelcase|capitalize}.{basename|camelcase|capitalize}Live",
          "end",
        },
      },
      ["lib/*.ex"] = {
        ["type"] = "source",
        ["alternate"] = "test/{}_test.exs",
        ["template"] = {
          "defmodule {camelcase|capitalize|dot} do",
          "",
          "end",
        },
      },
      ["test/*_test.exs"] = {
        ["type"] = "test",
        ["alternate"] = "lib/{}.ex",
        ["template"] = {
          "defmodule {camelcase|capitalize|dot}Test do",
          "  use ExUnit.Case, async: true",
          "",
          "  alias {camelcase|capitalize|dot}",
          "end",
        },
      },
    },
  }
end

do -- package-info.nvim
  require("package-info").setup({
    colors = {
      --up_to_date = C.cs.bg2, -- Text color for up to date package virtual text
      outdated = "#d19a66", -- Text color for outdated package virtual text
    },
    icons = {
      enable = true, -- Whether to display icons
      style = {
        up_to_date = "|  ", -- Icon for up to date packages
        outdated = "|  ", -- Icon for outdated packages
      },
    },
    autostart = true, -- Whether to autostart when `package.json` is opened
  })
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

do -- zk-nvim
  -- REFS:
  -- https://github.com/mbriggs/nvim/blob/main/lua/mb/zk.lua
  -- https://github.com/pwntester/dotfiles/blob/master/config/nvim/lua/pwntester/zk.lua
  -- https://github.com/kabouzeid/dotfiles/blob/main/config/nvim/lua/lsp-settings.lua#L160-L198
  local zk = require("zk")
  local commands = require("zk.commands")

  zk.setup({
    picker = "telescope",
    create_user_commands = true,
    lsp = {
      cmd = { "zk", "lsp" },
      name = "zk",
      on_attach = function(client, bufnr)
        require("lsp").on_attach(client, bufnr)
      end,
    },
    auto_attach = {
      enabled = true,
      filetypes = { "markdown", "liquid" },
    },
  })

  local function make_edit_fn(defaults, picker_options)
    return function(options)
      options = vim.tbl_extend("force", defaults, options or {})
      zk.edit(options, picker_options)
    end
  end

  commands.add("ZkOrphans", make_edit_fn({ orphan = true }, { title = "Zk Orphans" }))
  commands.add("ZkRecents", make_edit_fn({ createdAfter = "2 weeks ago" }, { title = "Zk Recents" }))

  nnoremap("<Leader>zc", "<cmd>ZkNew<CR>", "zk: new note")
  xnoremap("<Leader>zc", ":'<'>ZkNewFromTitleSelection<CR>", "zk: new note from selection")
  nnoremap("<Leader>zn", "<cmd>ZkNotes<CR>", "zk: find notes")
  nnoremap("<Leader>zb", "<cmd>ZkBacklinks<CR>", "zk: find backlinks")
  nnoremap("<Leader>zl", "<cmd>ZkLinks<CR>", "zk: find links")
  nnoremap("<Leader>zt", "<cmd>ZkTags<CR>", "zk: find tags")
  nnoremap("<Leader>zo", "<cmd>ZkOrphans<CR>", "zk: find orphans")
  nnoremap("<Leader>zr", "<cmd>ZkRecents<CR>", "zk: find recents")
end

do -- tabout.nvim
  require("tabout").setup({
    completion = false,
    ignore_beginning = false,
  })
end

do -- headlines.nvim
  fn.sign_define("Headline1", { linehl = "Headline1" })
  fn.sign_define("Headline2", { linehl = "Headline2" })
  fn.sign_define("Headline3", { linehl = "Headline3" })
  fn.sign_define("Headline4", { linehl = "Headline4" })
  fn.sign_define("Headline5", { linehl = "Headline5" })
  fn.sign_define("Headline6", { linehl = "Headline6" })

  require("headlines").setup({
    markdown = {
      source_pattern_start = "^```",
      source_pattern_end = "^```$",
      dash_pattern = "^---+$",
      headline_pattern = "^#+",
      headline_signs = { "Headline1", "Headline2", "Headline3", "Headline4", "Headline5", "Headline6" },
      codeblock_sign = "CodeBlock",
      dash_highlight = "Dash",
    },
    org = {
      source_pattern_start = "#%+[bB][eE][gG][iI][nN]_[sS][rR][cC]",
      source_pattern_end = "#%+[eE][nN][dD]_[sS][rR][cC]",
      dash_pattern = "^-----+$",
      headline_pattern = "^%*+",
      headline_signs = { "Headline" },
      codeblock_sign = "CodeBlock",
      dash_highlight = "Dash",
    },
  })
end

do -- telescope-nvim
  conf("telescope")
end

do -- dirbuf.nvim
  require("dirbuf").setup({
    hash_padding = 2,
    show_hidden = true,
    sort_order = "directories_first",
    fstate_compare = function(l, r)
      if l.ftype ~= r.ftype then
        return l.ftype < r.ftype
      else
        return l.fname:lower() < r.fname:lower()
      end
    end,
  })
end

do -- dd.nvim
  require("dd").setup({ timeout = 500 })
end

do -- nvim-gps
  if false then
    require("nvim-gps").setup({
      languages = {
        elixir = false,
        eelixir = false,
      },
    })
  end
end

do -- misc
  vim.g.fzf_gitignore_no_maps = true
end

do -- gitsigns.nvim
  local gs = require("gitsigns")
  gs.setup({
    signs = {
      add = { hl = "GitSignsAdd", text = "▎" }, -- ┃, │, ▌, ▎
      change = { hl = "GitSignsChange", text = "▎" },
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
          stdin = false,
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
  local notify = require("notify")
  ---@type table<string, fun(bufnr: number, notif: table, highlights: table)>
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
  -- vim.notify = notify
  -- require("telescope").load_extension("notify")
end