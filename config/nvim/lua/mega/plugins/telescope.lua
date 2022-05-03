return function(plug)
  local telescope = plug
  if plug == nil then
    telescope = require("telescope")
  end

  local fn = vim.fn
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
          ["<c-e>"] = layout_actions.toggle_preview,
          -- ["<c-l>"] = layout_actions.cycle_layout_next,
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
        ".git/.*",
        "%.DS_Store",
        "%yarn.lock",
        "%package-lock.json",
        "node_modules/.*",
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
  nmap("<leader>fa", builtins.builtin, "builtins")
  nmap("<leader>fb", builtins.current_buffer_fuzzy_find, "fuzzy find current buffer")
  nmap("<leader>fd", dotfiles, "dotfiles")
  nmap("<leader>fp", privates, "privates")
  nmap("<leader>ff", builtins.find_files, "find/git files")

  nmap("<leader>fgc", builtins.git_commits, "commits")
  nmap("<leader>fgb", builtins.git_branches, "branches")

  nmap("<leader>fM", builtins.man_pages, "man pages")
  nmap("<leader>fm", builtins.man_pages, "oldfiles (mru)")
  nmap("<leader>fk", builtins.keymaps, "keymaps")
  nmap("<leader>fP", installed_plugins, "installed plugins")
  nmap("<leader>fo", builtins.buffers, "opened buffers")
  nmap("<leader>fr", builtins.resume, "resume last picker")
  nmap("<leader>fa", builtins.live_grep, "live grep string")
  nmap("<leader>fs", builtins.live_grep, "live grep string")

  nmap("<leader>fts", tmux_sessions, "sessions")
  nmap("<leader>ftw", tmux_windows, "windows")

  nmap("<leader>f?", builtins.help_tags, "help")
  nmap("<leader>fh", builtins.help_tags, "help")

  nmap("<leader>ld", builtins.lsp_definitions, "telescope: definitions")
  nmap("<leader>lD", builtins.lsp_type_definitions, "telescope: type definitions")
  nmap("<leader>lt", builtins.diagnostics, "telescope: diagnostics")
  nmap("<leader>lr", builtins.lsp_references, "telescope: references")
  nmap("<leader>li", builtins.lsp_implementations, "telescope: implementations")
  nmap("<leader>ls", builtins.lsp_document_symbols, "telescope: document symbols")
  nmap("<leader>lS", builtins.lsp_workspace_symbols, "telescope: workspace symbols")
  nmap("<leader>lw", builtins.lsp_dynamic_workspace_symbols, "telescope: dynamic workspace symbols")

  require("telescope").load_extension("fzf")
  require("telescope").load_extension("tmux")
  require("telescope").load_extension("media_files")
  -- require("telescope").load_extension("file_browser")
  -- require("telescope").load_extension("smart_history")
end
