return function(plug)
  local telescope = plug
  if plug == nil then
    return
  end

  local fn = vim.fn
  local actions = require("telescope.actions")
  local themes = require("telescope.themes")
  local layout_actions = require("telescope.actions.layout")

  mega.augroup("TelescopePreviews", {
    {
      event = "User",
      pattern = "TelescopePreviewerLoaded",
      -- FIXME: https://github.com/nvim-telescope/telescope.nvim/issues/1661
      command = "setlocal number wrap",
    },
  })

  local function get_border(opts)
    return vim.tbl_deep_extend("force", opts or {}, {
      borderchars = {
        { " ", " ", " ", " ", " ", " ", " ", " " },
        prompt = { " ", " ", " ", " ", " ", " ", " ", " " },
        results = { " ", " ", " ", " ", " ", " ", " ", " " },
        preview = { " ", " ", " ", " ", " ", " ", " ", " " },
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
      -- borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
      prompt_prefix = "  ",
      selection_caret = "» ", -- ❯
      cycle_layout_list = { "flex", "horizontal", "vertical", "bottom_pane", "center" },
      mappings = {
        i = {
          ["<c-q>"] = actions.send_selected_to_qflist,
          ["<c-l>"] = actions.send_to_qflist,
          ["<c-c>"] = function()
            vim.cmd("stopinsert!")
          end,
          ["<esc>"] = actions.close,
          ["<cr>"] = actions.select_vertical,
          ["<c-o>"] = actions.select_default,
          ["<c-s>"] = actions.select_horizontal,
          ["<c-b>"] = actions.preview_scrolling_up,
          ["<c-f>"] = actions.preview_scrolling_down,
          ["<c-u>"] = actions.preview_scrolling_up,
          ["<c-d>"] = actions.preview_scrolling_down,
          ["<c-e>"] = layout_actions.toggle_preview,
          ["<c-/>"] = actions.which_key,
          ["<Tab>"] = actions.toggle_selection,
        },
        n = {
          ["<c-q>"] = actions.send_selected_to_qflist,
          ["<c-l>"] = actions.send_to_qflist,
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
        "config/zsh/plugins/.*",
        "^.git/.*",
        "%.DS_Store",
        "%yarn.lock",
        "%package-lock.json",
        "^node_modules/.*",
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
          height = function(self, _, max_lines) -- was 0.5
            local results = #self.finder.results
            return (results <= max_lines and results or max_lines - 10) + 4
          end,
        },
      },
      winblend = 0,
      -- history = {
      --   path = fn.stdpath("data") .. "/telescope_history.sqlite3",
      -- },
      dynamic_preview_title = true,
      color_devicons = true,
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
      --     docs = mega.dirs.docs,
      --   },
      -- },
      media_files = {
        find_cmd = "rg",
      },
      fzf = {
        fuzzy = true, -- false will only do exact matching
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
        max_results = 500,
        file_ignore_patterns = { ".git/", "%.lock" },
        on_input_filter_cb = function(prompt)
          -- AND operator for live_grep like how fzf handles spaces with wildcards in rg
          return { prompt = prompt:gsub("%s", ".*") }
        end,
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
      keymaps = dropdown({
        layout_config = {
          height = 18,
          width = 0.5,
        },
      }),
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
  local builtin = require("telescope.builtin")

  local function builtins()
    builtin.builtin({ include_extensions = true })
  end

  local function delta_opts(opts, is_buf)
    local previewers = require("telescope.previewers")
    local delta = previewers.new_termopen_previewer({
      get_command = function(entry)
        local args = {
          "git",
          "-c",
          "core.pager=delta",
          "-c",
          "delta.side-by-side=false",
          "diff",
          entry.value .. "^!",
        }
        if is_buf then
          vim.list_extend(args, { "--", entry.current_file })
        end
        return args
      end,
    })
    opts = opts or {}
    opts.previewer = {
      delta,
      previewers.git_commit_message.new(opts),
    }
    return opts
  end

  local function delta_git_commits(opts)
    builtin.git_commits(delta_opts(opts))
  end

  local function delta_git_bcommits(opts)
    builtin.git_bcommits(delta_opts(opts, true))
  end

  local function project_files(opts)
    if not pcall(builtin.git_files, opts) then
      builtin.find_files(opts)
    end
  end

  local function dotfiles()
    builtin.find_files({
      prompt_title = "~ dotfiles ~",
      cwd = mega.dirs.dots,
      file_ignore_patterns = {
        ".git/.*",
        "dotbot/.*",
        "config/zsh/plugins/.*",
      },
    })
  end

  local function privates()
    builtin.find_files({
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

  local function installed_plugins()
    builtin.find_files({
      prompt_title = "~ installed plugins ~",
      cwd = fn.stdpath("data") .. "/site/pack/paqs",
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
  nmap("<leader>fB", builtins, "builtins")
  nmap("<leader>fb", builtin.current_buffer_fuzzy_find, "fuzzy find current buffer")
  nmap("<leader>fd", dotfiles, "dotfiles")
  nmap("<leader>fp", privates, "privates")
  nmap("<leader>ff", project_files, "find/git files")

  nmap("<leader>fgc", delta_git_commits, "commits")
  nmap("<leader>fgb", delta_git_bcommits, "buffer commits")
  nmap("<leader>fgB", builtin.git_branches, "branches")

  nmap("<leader>fM", builtin.man_pages, "man pages")
  nmap("<leader>fm", builtin.man_pages, "oldfiles (mru)")
  nmap("<leader>fk", builtin.keymaps, "keymaps")
  nmap("<leader>fP", installed_plugins, "installed plugins")
  nmap("<leader>fo", builtin.buffers, "opened buffers")
  nmap("<leader>fr", builtin.resume, "resume last picker")
  nmap("<leader>fa", builtin.live_grep, "live grep string")
  nmap("<leader>fs", builtin.live_grep, "live grep string")

  nmap("<leader>fts", tmux_sessions, "sessions")
  nmap("<leader>ftw", tmux_windows, "windows")

  nmap("<leader>f?", builtin.help_tags, "help")
  nmap("<leader>fh", builtin.help_tags, "help")

  nmap("<leader>ld", builtin.lsp_definitions, "telescope: definitions")
  nmap("<leader>lD", builtin.lsp_type_definitions, "telescope: type definitions")
  nmap("<leader>lt", builtin.diagnostics, "telescope: diagnostics")
  nmap("<leader>lr", builtin.lsp_references, "telescope: references")
  nmap("<leader>li", builtin.lsp_implementations, "telescope: implementations")
  nmap("<leader>ls", builtin.lsp_document_symbols, "telescope: document symbols")
  nmap("<leader>lS", builtin.lsp_workspace_symbols, "telescope: workspace symbols")
  nmap("<leader>lw", builtin.lsp_dynamic_workspace_symbols, "telescope: dynamic workspace symbols")

  require("telescope").load_extension("fzf")
  require("telescope").load_extension("tmux")
  require("telescope").load_extension("media_files")
  -- require("telescope").load_extension("file_browser")
  -- require("telescope").load_extension("smart_history")
end
