local api = vim.api
local vcmd = vim.cmd
local fn = vim.fn
local fmt = string.format

-- local C = require("colors")

-- # managed paqs stored here:
--  ~/.local/share/nvim/site/pack/paqs
-- # local/devel paqs stored here:
--  ~/.local/share/nvim/site/pack/local

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

  do -- treesitter-nvim
    vim.opt.indentexpr = "nvim_treesitter#indent()"

    -- custom treesitter parsers and grammars
    local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
    parser_config.jsonc.filetype_to_parsername = "json"
    parser_config.org = {
      install_info = {
        url = "https://github.com/milisims/tree-sitter-org",
        revision = "main",
        files = { "src/parser.c", "src/scanner.cc" },
      },
      filetype = "org",
    }
    -- parser_config.embedded_template = {
    --   install_info = {
    --     url = "https://github.com/tree-sitter/tree-sitter-embedded-template",
    --     files = { "src/parser.c" },
    --     requires_generate_from_grammar = true,
    --   },
    --   used_by = { "eex", "leex", "sface", "eelixir", "eruby", "erb" },
    -- }

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
        "javascript",
        -- "markdown",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "make",
        "nix",
        "org",
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
        disable = { "json", "html" },
        extended_mode = true, -- Highlight also non-parentheses delimiters, boolean or table: lang -> boolean
        max_file_lines = 1000, -- Do not enable for files with more than 1000 lines, int
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
    require("tsht").config.hint_keys = { "h", "j", "f", "d", "n", "v", "s", "l", "a" }
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

  -- do -- project.nvim
  --   require("project_nvim").setup({
  --     manual_mode = true,
  --     patterns = { ".git", ".hg", ".bzr", ".svn", "Makefile", "package.json", "elm.json", "mix.lock" },
  --   }) -- REF: https://github.com/ahmedkhalf/project.nvim#%EF%B8%8F-configuration
  -- end

  do -- orgmode.nvim
    -- REF: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/lua/as/plugins/orgmode.lua
    -- CHEAT: https://github.com/akinsho/dotfiles/blob/main/.config/nvim/after/ftplugin/org.lua
    --        https://github.com/huynle/nvim/blob/master/lua/configs/orgmode.lua
    --        https://github.com/tkmpypy/dotfiles/blob/master/.config/nvim/lua/plugins.lua#L358-L470
    --        https://github.com/tricktux/dotfiles/blob/master/defaults/.config/nvim/lua/config/plugins/orgmode.lua
    -- ENABLE TREESITTER: https://github.com/kristijanhusak/orgmode.nvim/tree/tree-sitter#setup
    require("orgmode").setup({
      -- org_agenda_files = {"~/Library/Mobile Documents/com~apple~CloudDocs/org/*"},
      -- org_default_notes_file = "~/Library/Mobile Documents/com~apple~CloudDocs/org/inbox.org"
      org_agenda_files = { mega.dirs.org .. "/**/*" },
      org_default_notes_file = mega.dirs.org .. "/refile.org",
      org_todo_keywords = { "TODO(t)", "WAITING", "NEXT", "|", "DONE", "CANCELLED", "HACK" },
      org_todo_keyword_faces = {
        NEXT = ":foreground royalblue :weight bold :slant italic",
        CANCELLED = ":foreground darkred",
        HOLD = ":foreground orange :weight bold",
      },
      org_hide_emphasis_markers = true,
      org_hide_leading_stars = true,
      org_agenda_skip_scheduled_if_done = true,
      org_agenda_skip_deadline_if_done = true,
      org_agenda_templates = {
        t = { description = "Task", template = "* TODO %?\n SCHEDULED: %t" },
        l = { description = "Link", template = "* %?\n%a" },
        n = {
          description = "Note",
          template = "* NOTE %?\n  %u",
          target = mega.dirs.org .. "/note.org",
        },
        j = {
          description = "Journal",
          template = "\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?",
          target = mega.dirs.org .. "/journal.org",
        },
        p = {
          description = "Project Todo",
          template = "* TODO %? \nSCHEDULED: %t",
          target = mega.dirs.org .. "/projects.org",
        },
      },
      mappings = {
        org = {
          org_toggle_checkbox = "<leader>x",
        },
      },
      notifications = {
        reminder_time = { 0, 1, 5, 10 },
        repeater_reminder_time = { 0, 1, 5, 10 },
        deadline_warning_reminder_time = { 0 },
        cron_notifier = function(tasks)
          for _, task in ipairs(tasks) do
            local title = fmt("%s (%s)", task.category, task.humanized_duration)
            local subtitle = fmt("%s %s %s", string.rep("*", task.level), task.todo, task.title)
            local date = fmt("%s: %s", task.type, task.time:to_string())

            -- helpful docs for options: https://github.com/julienXX/terminal-notifier#options
            if fn.executable("terminal-notifier") then
              vim.loop.spawn("terminal-notifier", {
                args = {
                  "-title",
                  title,
                  "-subtitle",
                  subtitle,
                  "-message",
                  date,
                  "-appIcon ~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
                  "-ignoreDnD",
                },
              })
            end
            -- if fn.executable("notify-send") then
            -- 	vim.loop.spawn("notify-send", {
            -- 		args = {
            -- 			"--icon=~/.local/share/nvim/site/pack/paqs/start/orgmode.nvim/assets/orgmode_nvim.png",
            -- 			fmt("%s\n%s\n%s", title, subtitle, date),
            -- 		},
            -- 	})
            -- end
          end
        end,
      },
    })
    require("orgmode").setup_ts_grammar()
    require("org-bullets").setup()
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
        delay_ms = 0, -- delay before popup displays
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
    nnoremap("s", hop.hint_char1)
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
      size = function(term)
        if term.direction == "horizontal" then
          return 20
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      persist_size = false,
      on_open = function(term)
        term.opened = term.opened or false

        if not term.opened then
          term:send("eval $(desk load)")
        end

        term.opened = true
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

    vcmd([[
      function! TerminalSplit(cmd)
        vert new | set filetype=test | call termopen(['zsh', '-ci', a:cmd], {'curwin':1})
      endfunction

      let g:test#custom_strategies = {'terminal_split': function('TerminalSplit')}
      let g:test#strategy = 'terminal_split'
    ]])
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

  do -- telescope-nvim
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local themes = require("telescope.themes")
    local layout_actions = require("telescope.actions.layout")

    local function get_border(opts)
      return vim.tbl_deep_extend("force", opts or {}, {
        borderchars = {
          { " ", " ", " ", " ", " ", " ", " ", " " },
          prompt = { " ", " ", " ", " ", " ", " ", " ", " " },
          results = { " ", " ", " ", " ", " ", " ", " ", " " },
          preview = { " ", " ", " ", " ", " ", " ", " ", " " },
          -- { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          -- { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          -- prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
          -- results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
          -- preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
      })
    end

    ---@param opts table
    ---@return table
    local function dropdown(opts)
      return themes.get_dropdown(get_border(opts))
    end

    telescope.setup({
      defaults = {
        set_env = { ["TERM"] = vim.env.TERM, ["COLORTERM"] = "truecolor" },
        border = {},
        borderchars = { " ", " ", " ", " ", " ", " ", " ", " " },
        -- borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        prompt_prefix = "  ",
        selection_caret = "» ", -- ❯
        mappings = {
          i = {
            ["<c-w>"] = actions.send_selected_to_qflist,
            ["<c-c>"] = function()
              vim.cmd("stopinsert!")
            end,
            ["<esc>"] = actions.close,
            ["<cr>"] = actions.select_vertical,
            ["<c-o>"] = actions.select_default,
            ["<c-s>"] = actions.select_horizontal,
            ["<c-b>"] = actions.preview_scrolling_up,
            ["<c-f>"] = actions.preview_scrolling_down,
            ["<c-e>"] = layout_actions.toggle_preview,
            -- ["<c-l>"] = layout_actions.cycle_layout_next,
          },
          n = {
            ["<C-w>"] = actions.send_selected_to_qflist,
          },
        },
        file_ignore_patterns = {
          "%.jpg",
          "%.jpeg",
          "%.png",
          "%.otf",
          "%.ttf",
          "EmmyLua.spoon",
          ".yarn",
          "dotbot/.*",
          ".git/.*",
        },
        -- :help telescope.defaults.path_display
        -- path_display = { "smart", "absolute", "truncate" },
        layout_strategy = "flex",
        layout_config = {
          width = 0.65,
          height = 0.6,
          horizontal = {
            preview_width = 0.45,
          },
          cursor = { -- FIXME: this does not change the size of the cursor layout
            width = 0.4,
            height = 0.5,
          },
        },
        winblend = 3,
        -- history = {
        --   path = fn.stdpath("data") .. "/telescope_history.sqlite3",
        -- },
        dynamic_preview_title = true,
        vimgrep_arguments = {
          "rg",
          "--hidden",
          "--no-heading",
          "--with-filename",
          "--line-number",
          "--column",
          "--smart-case",
        },
      },
      extensions = {
        -- frecency = {
        --   workspaces = {
        --     conf = mega.dirs.dots,
        --     privates = mega.dirs.privates,
        --     project = mega.dirs.code,
        --     notes = mega.dirs.zettel,
        --     icloud = mega.dirs.icloud,
        --     org = mega.dirs.org,
        --     docs = mega.dirs.docs,
        --   },
        -- },
        media_files = {
          find_cmd = "rg",
        },
        fzf = {
          override_generic_sorter = true, -- override the generic sorter
          override_file_sorter = true, -- override the file sorter
          case_mode = "smart_case", -- or "ignore_case" or "respect_case"
        },
      },
      pickers = {
        buffers = dropdown({
          sort_mru = true,
          sort_lastused = true,
          show_all_buffers = true,
          ignore_current_buffer = true,
          previewer = false,
          theme = "dropdown",
          mappings = {
            i = { ["<c-x>"] = "delete_buffer" },
            n = { ["<c-x>"] = "delete_buffer" },
          },
        }),
        oldfiles = dropdown(),
        live_grep = {
          file_ignore_patterns = { ".git/" },
        },
        current_buffer_fuzzy_find = dropdown({
          previewer = false,
          shorten_path = false,
        }),
        lsp_code_actions = {
          theme = "cursor",
        },
        colorscheme = {
          enable_preview = true,
        },
        find_files = {
          hidden = true,
        },
        git_branches = dropdown(),
        git_bcommits = {
          layout_config = {
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
        git_commits = {
          layout_config = {
            horizontal = {
              preview_width = 0.55,
            },
          },
        },
        reloader = dropdown(),
      },
    })

    --- NOTE: this must be required after setting up telescope
    --- otherwise the result will be cached without the updates
    --- from the setup call
    local builtins = require("telescope.builtin")

    local function project_files(opts)
      if not pcall(builtins.git_files, opts) then
        builtins.find_files(opts)
      end
    end

    local function dotfiles()
      builtins.find_files({
        prompt_title = "~ dotfiles ~",
        cwd = mega.dirs.dots,
      })
    end

    local function privates()
      builtins.find_files({
        prompt_title = "~ privates ~",
        cwd = mega.dirs.privates,
      })
    end

    -- local function frecency()
    --   telescope.extensions.frecency.frecency(dropdown({
    --     -- NOTE: remove default text as it's slow
    --     -- default_text = ':CWD:',
    --     winblend = 10,
    --     border = true,
    --     previewer = false,
    --     shorten_path = false,
    --   }))
    -- end

    local function gh_notifications()
      telescope.extensions.ghn.ghn(dropdown())
    end

    local function installed_plugins()
      require("telescope.builtin").find_files({
        cwd = fn.stdpath("data") .. "/site/pack/paqs",
      })
    end

    local function orgfiles()
      builtins.find_files({
        prompt_title = "Org",
        cwd = mega.dirs.org,
      })
    end

    local function tmux_sessions()
      telescope.extensions.tmux.sessions({})
    end

    local function tmux_windows()
      telescope.extensions.tmux.windows({
        entry_format = "#S: #T",
      })
    end

    -- telescope-mappings
    require("which-key").register({
      ["<leader>f"] = {
        name = "telescope",
        a = { builtins.builtin, "builtins" },
        b = { builtins.current_buffer_fuzzy_find, "current buffer fuzzy find" },
        d = { dotfiles, "dotfiles" },
        p = { privates, "privates" },
        f = { builtins.find_files, "find/git files" },
        g = {
          name = "+git",
          c = { builtins.git_commits, "commits" },
          b = { builtins.git_branches, "branches" },
          n = { gh_notifications, "notifications" },
        },
        M = { builtins.man_pages, "man pages" },
        m = { builtins.oldfiles, "oldfiles (mru)" },
        k = { builtins.keymaps, "keymaps" },
        -- H = { frecency, "history" },
        P = { installed_plugins, "plugins" },
        o = { builtins.buffers, "buffers" },
        O = { orgfiles, "org files" },
        R = { builtins.reloader, "module reloader" },
        r = { builtins.resume, "resume last picker" },
        s = { builtins.live_grep, "grep string" },
        t = {
          name = "+tmux",
          s = { tmux_sessions, "sessions" },
          w = { tmux_windows, "windows" },
        },
        ["?"] = { builtins.help_tags, "help" },
        h = { builtins.help_tags, "help" },
      },
      ["<leader>c"] = {
        d = { builtins.diagnostics, "telescope: diagnostics" },
        s = { builtins.lsp_document_symbols, "telescope: document symbols" },
        w = { builtins.lsp_dynamic_workspace_symbols, "telescope: search workspace symbols" },
      },
      ["<leader>l"] = {
        d = { builtins.lsp_definitions, "telescope: definitions" },
        D = { builtins.lsp_type_definitions, "telescope: type definitions" },
        r = { builtins.lsp_references, "telescope: references" },
        i = { builtins.lsp_implementations, "telescope: implementations" },
      },
    })
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("tmux")
    require("telescope").load_extension("media_files")
    -- require("telescope").load_extension("file_browser")
    -- require("telescope").load_extension("smart_history")
  end

  do -- nvim-bufdel
    require("bufdel").setup({
      next = "cycle", -- or 'alternate'
      quit = true,
    })
  end

  do -- telekasten.nvim
    require("telekasten").setup({
      home = mega.dirs.zk,
      dailies = mega.dirs.zk .. "/" .. "daily",
      weeklies = mega.dirs.zk .. "/" .. "weekly",
      templates = mega.dirs.zk .. "/" .. "templates",
      -- image subdir for pasting
      -- subdir name
      -- or nil if pasted images shouldn't go into a special subdir
      image_subdir = nil,
      -- markdown file extension
      extension = ".md",
      -- following a link to a non-existing note will create it
      follow_creates_nonexisting = true,
      dailies_create_nonexisting = true,
      weeklies_create_nonexisting = true,
      -- templates for new notes
      template_new_note = mega.dirs.zk .. "/" .. "templates/new_note.md",
      template_new_daily = mega.dirs.zk .. "/" .. "templates/daily_tk.md",
      template_new_weekly = mega.dirs.zk .. "/" .. "templates/weekly_tk.md",
      -- image link style
      -- wiki:     ![[image name]]
      -- markdown: ![](image_subdir/xxxxx.png)
      image_link_style = "markdown",
      -- integrate with calendar-vim
      plug_into_calendar = true,
      calendar_opts = {
        -- calendar week display mode: 1 .. 'WK01', 2 .. 'WK 1', 3 .. 'KW01', 4 .. 'KW 1', 5 .. '1'
        weeknm = 4,
        -- use monday as first day of week: 1 .. true, 0 .. false
        calendar_monday = 1,
        -- calendar mark: where to put mark for marked days: 'left', 'right', 'left-fit'
        calendar_mark = "left-fit",
      },
      debug = false,
      close_after_yanking = false,
      insert_after_inserting = true,
      -- make syntax available to markdown buffers and telescope previewers
      install_syntax = true,
      -- tag notation: '#tag', ':tag:', 'yaml-bare'
      tag_notation = "#tag",
      -- command palette theme: dropdown (window) or ivy (bottom panel)
      command_palette_theme = "ivy",
    })

    -- nnoremap("<leader>zf", "<cmd>lua require('telekasten').find_notes()<cr>", "telekasten: find notes")
    -- nnoremap("<leader>zn", "<cmd>lua require('telekasten').new_note()<cr>", "telekasten: new note")
    -- nnoremap("<leader>zN", "<cmd>lua require('telekasten').new_templated_notes()<cr>", "telekasten: new templated note")
    -- nnoremap("<leader>z", "<cmd>lua require('telekasten').panel()<CR>", "telekasten: show help panel")

    --[[
    autocmd filetype markdown set tw=120
    nnoremap <leader>zf :lua require('telekasten').find_notes()<CR>
    nnoremap <leader>zd :lua require('telekasten').find_daily_notes()<CR>
    nnoremap <leader>zg :lua require('telekasten').search_notes()<CR>
    nnoremap <leader>zz :lua require('telekasten').follow_link()<CR>
    nnoremap <leader>zT :lua require('telekasten').goto_today()<CR>
    nnoremap <leader>zW :lua require('telekasten').goto_thisweek()<CR>
    nnoremap <leader>zw :lua require('telekasten').find_weekly_notes()<CR>
    nnoremap <leader>zn :lua require('telekasten').new_note()<CR>
    nnoremap <leader>zN :lua require('telekasten').new_templated_note()<CR>
    nnoremap <leader>zy :lua require('telekasten').yank_notelink()<CR>
    nnoremap <leader>zc :lua require('telekasten').show_calendar()<CR>
    nnoremap <leader>zC :CalendarT<CR>
    nnoremap <leader>zi :lua require('telekasten').paste_img_and_link()<CR>
    nnoremap <leader>zt :lua require('telekasten').toggle_todo()<CR>
    nnoremap <leader>zr :lua require('plenary.reload').reload_module('telekasten')<CR>
    nnoremap <leader>zb :lua require('telekasten').show_backlinks()<CR>
    nnoremap <leader>zF :lua require('telekasten').find_friends()<CR>
    nnoremap <leader>zI :lua require('telekasten').insert_img_link({i = true})<CR>
    nnoremap <leader>zp :lua require('telekasten').preview_img()<CR>
    nnoremap <leader>zm :lua require('telekasten').browse_media()<CR>
    nnoremap <leader>z :lua require('telekasten').panel()<CR>
    nnoremap <leader>za :lua require('telekasten').show_tags()<CR>

    noremap <leader>P :MarkdownPreviewToggle<CR>

    " autocmd FileType markdown set syntax=telekasten

    hi tklink ctermfg=72 guifg=#689d6a cterm=bold,underline gui=bold,underline
    hi tkBrackets ctermfg=gray guifg=gray

    " real yellow
    hi tkHighlight ctermbg=yellow ctermfg=darkred cterm=bold guibg=yellow guifg=darkred gui=bold
    " gruvbox
    hi tkHighlight ctermbg=214 ctermfg=124 cterm=bold guibg=#fabd2f guifg=#9d0006 gui=bold

    hi link CalNavi CalRuler
    hi tkTagSep ctermfg=gray guifg=gray
    hi tkTag ctermfg=175 guifg=#d3869B

    if has('termguicolors')
      set termguicolors
    endif

    " note: we define [[ in **insert mode** to call insert link
    " note: we don't do this anymore - maybe it makes sense to limit to markdown
    " mode
    inoremap <leader>[ <ESC>:lua require('telekasten').insert_link({i = true})<CR>
    " inorfalseemap [[ <ESC>:lua require('telekasten').insert_link({i = true})<CR>
    inoremap <leader>zt <ESC>:lua require('telekasten').toggle_todo({i = true})<CR>
    inoremap <leader># <cmd>lua require('telekasten').show_tags({i = true})<cr>
    --]]
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

  do -- alpha.nvim
    if false then
      local alpha = require("alpha")
      local dashboard = require("alpha.themes.dashboard")

      math.randomseed(os.time())

      local function button(sc, txt, keybind, keybind_opts)
        local b = dashboard.button(sc, txt, keybind, keybind_opts)
        b.opts.hl = "Function"
        b.opts.hl_shortcut = "Type"
        return b
      end

      local function pick_color()
        local clrs = { "String", "Identifier", "Keyword", "Number" }
        return clrs[math.random(#clrs)]
      end

      local function footer()
        local datetime = os.date("%d-%m-%Y  %H:%M:%S")
        return {
          -- require("colors").icons.git_symbol .. " " .. fn["gitbranch#name"](),
          vim.loop.cwd(),
          datetime,
        }
      end

      -- REF: https://patorjk.com/software/taag/#p=display&f=Elite&t=MEGALITHIC
      dashboard.section.header.val = {
        "• ▌ ▄ ·. ▄▄▄ . ▄▄ •  ▄▄▄· ▄▄▌  ▪  ▄▄▄▄▄ ▄ .▄▪   ▄▄·",
        "·██ ▐███▪▀▄.▀·▐█ ▀ ▪▐█ ▀█ ██•  ██ •██  ██▪▐███ ▐█ ▌▪",
        "▐█ ▌▐▌▐█·▐▀▀▪▄▄█ ▀█▄▄█▀▀█ ██▪  ▐█· ▐█.▪██▀▐█▐█·██ ▄▄",
        "██ ██▌▐█▌▐█▄▄▌▐█▄▪▐█▐█ ▪▐▌▐█▌▐▌▐█▌ ▐█▌·██▌▐▀▐█▌▐███▌",
        "▀▀  █▪▀▀▀ ▀▀▀ ·▀▀▀▀  ▀  ▀ .▀▀▀ ▀▀▀ ▀▀▀ ▀▀▀ ·▀▀▀·▀▀▀",
      }

      dashboard.section.header.opts.hl = pick_color()
      dashboard.section.buttons.val = {
        button("m", "  Recently opened files", "<cmd>lua require('telescope').oldfiles()<cr>"),
        button("f", "  Find file", "<cmd>lua require('telescope').find_files()<cr>"),
        button("a", "  Find word", "<cmd>lua require('telescope').live_grep()<cr>"),
        button("e", "  New file", "<cmd>ene <BAR> startinsert <CR>"),
        button("p", "  Update plugins", "<cmd>lua mega.sync_plugins()<CR>"),
        button("q", "  Quit", "<cmd>qa<CR>"),
      }

      dashboard.section.footer.val = footer()
      dashboard.section.footer.opts.hl = "Constant"
      dashboard.section.footer.opts.position = "center"

      alpha.setup(dashboard.opts)
    end
  end

  do -- distant.nvim
    local actions = require("distant.nav.actions")

    require("distant").setup({
      ["198.74.55.152"] = {
        -- 198.74.55.152
        max_timeout = 15000,
        poll_interval = 250,
        timeout_interval = 250,
        ssh = {
          user = "ubuntu",
          identity_file = "~/.ssh/seth-Seths-MBP.lan",
        },
        distant = {
          bin = "/home/ubuntu/.asdf/installs/rust/stable/bin/distant",
          username = "ubuntu",
          args = "\"--log-file ~/tmp/distant-seth_dev-server.log --log-level trace --port 8081:8099 --shutdown-after 60\"",
        },
        file = {},
        dir = {},
        lsp = {
          ["outstand/atlas (elixirls)"] = {
            cmd = { require("utils").lsp.elixirls_cmd({ fallback_dir = "/home/ubuntu/.local/share" }) },
            root_dir = "/home/ubuntu/code/atlas",
            filetypes = { "elixir", "eelixir" },
            on_attach = function(client, bufnr)
              print(vim.inspect(client), bufnr)
            end,
            log_file = "~/tmp/distant-pages-elixirls.log",
            log_level = "trace",
          },
        },
      },
      ["megalithic.io"] = {
        -- 198.199.91.123
        launch = {
          distant = "/home/replicant/.cargo/bin/distant",
          username = "replicant",
          identity_file = "~/.ssh/seth-Seths-MacBook-Pro.local",
          extra_server_args = "\"--log-file ~/tmp/distant-megalithic_io-server.log --log-level trace --port 8081:8099 --shutdown-after 60\"",
        },
      },
      -- Apply these settings to any remote host
      ["*"] = {
        -- max_timeout = 60000,
        -- timeout_interval = 200,
        client = {
          log_file = "~/tmp/distant-client.log",
          log_level = "trace",
        },
        launch = {
          extra_server_args = "\"--log-file ~/tmp/distant-all-server.log --log-level trace --port 8081:8999 --shutdown-after 60\"",
        },
        file = {
          mappings = {
            ["-"] = actions.up,
          },
        },
        dir = {
          mappings = {
            ["<Return>"] = actions.edit,
            ["-"] = actions.up,
            ["K"] = actions.mkdir,
            ["N"] = actions.newfile,
            ["R"] = actions.rename,
            ["D"] = actions.remove,
          },
        },
      },
    })
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

  do -- filetype.nvim
    if not vim.filetype then
      require("filetype").setup({
        overrides = {
          literal = {
            ["kitty.conf"] = "kitty",
            [".gitignore"] = "conf",
            [".env"] = "sh",
          },
        },
      })
    end
  end

  do -- dirbuf.nvim
    require("dirbuf").setup({
      hash_padding = 2,
      show_hidden = true,
      fstate_compare = function(l, r)
        if l.ftype ~= r.ftype then
          return l.ftype < r.ftype
        else
          return l.fname:lower() < r.fname:lower()
        end
      end,
    })
  end

  do -- nvim-tree.nvim
    -- local action = require("nvim-tree.config").nvim_tree_callback
    if false then
      vim.g.nvim_tree_icons = {
        default = "",
        git = {
          unstaged = "",
          staged = "",
          unmerged = "",
          renamed = "",
          untracked = "",
          deleted = "",
        },
      }
      vim.g.nvim_tree_special_files = {}
      vim.g.nvim_tree_indent_markers = 1
      vim.g.nvim_tree_group_empty = 1
      vim.g.nvim_tree_git_hl = 1
      vim.g.nvim_tree_width_allow_resize = 1
      vim.g.nvim_tree_root_folder_modifier = ":t"
      vim.g.nvim_tree_highlight_opened_files = 1

      local tree_cb = require("nvim-tree.config").nvim_tree_callback
      require("nvim-tree").setup({
        view = {
          width = "20%",
          auto_resize = true,
          list = {},
        },
        nvim_tree_ignore = { ".DS_Store", "fugitive:", ".git" },
        diagnostics = {
          enable = true,
        },
        disable_netrw = false,
        hijack_netrw = true,
        open_on_setup = true,
        hijack_cursor = true,
        update_cwd = true,
        update_focused_file = {
          enable = true,
          update_cwd = true,
        },
        mappings = {
          { key = { "<CR>", "o", "<2-LeftMouse>" }, cb = tree_cb("edit") },
          { key = { "<2-RightMouse>", "<C-]>" }, cb = tree_cb("cd") },
          { key = "<C-v>", cb = tree_cb("vsplit") },
          { key = "<C-x>", cb = tree_cb("split") },
          { key = "<C-t>", cb = tree_cb("tabnew") },
          { key = "<", cb = tree_cb("prev_sibling") },
          { key = ">", cb = tree_cb("next_sibling") },
          { key = "P", cb = tree_cb("parent_node") },
          { key = "<BS>", cb = tree_cb("close_node") },
          { key = "<S-CR>", cb = tree_cb("close_node") },
          { key = "<Tab>", cb = tree_cb("preview") },
          { key = "K", cb = tree_cb("first_sibling") },
          { key = "J", cb = tree_cb("last_sibling") },
          { key = "I", cb = tree_cb("toggle_ignored") },
          { key = "H", cb = tree_cb("toggle_dotfiles") },
          { key = "R", cb = tree_cb("refresh") },
          { key = "a", cb = tree_cb("create") },
          { key = "d", cb = tree_cb("remove") },
          { key = "r", cb = tree_cb("rename") },
          { key = "<C-r>", cb = tree_cb("full_rename") },
          { key = "x", cb = tree_cb("cut") },
          { key = "c", cb = tree_cb("copy") },
          { key = "p", cb = tree_cb("paste") },
          { key = "y", cb = tree_cb("copy_name") },
          { key = "Y", cb = tree_cb("copy_path") },
          { key = "gy", cb = tree_cb("copy_absolute_path") },
          { key = "[c", cb = tree_cb("prev_git_item") },
          { key = "]c", cb = tree_cb("next_git_item") },
          { key = "-", cb = tree_cb("dir_up") },
          { key = "s", cb = tree_cb("system_open") },
          { sdfasdfkey = "q", cb = tree_cb("close") },
          { key = "g?", cb = tree_cb("toggle_help") },
        },
      })
    end
  end

  do -- dd.nvim
    require("dd").setup({ timeout = 500 })
  end

  do -- dash.nvim
    -- if fn.getenv("PLATFORM") == "macos" then
    --   vcmd([[packadd dash.nvim]])
    --   require("dash").setup({})
    -- end
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

