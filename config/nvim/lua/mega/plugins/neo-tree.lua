return function()
  vim.g.neo_tree_remove_legacy_commands = 1

  local icons = mega.icons

  mega.nnoremap("<C-t>", "<Cmd>Neotree toggle reveal position=left<CR>")

  require("neo-tree").setup({
    sources = {
      "filesystem",
      "buffers",
      "git_status",
      "diagnostics",
    },
    source_selector = {
      winbar = true,
      -- statusbar = true,
      separator_active = " ",
    },
    close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
    enable_git_status = true,
    git_status_async = true,
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function(args) vim.cmd("highlight! Cursor blend=100") end,
      },
      {
        event = "neo_tree_buffer_leave",
        handler = function(args) vim.cmd("highlight! Cursor blend=0") end,
      },
      {
        event = "neo_tree_window_before_open",
        handler = function(args) end,
      },
      {
        event = "neo_tree_window_after_open",
        handler = function(args)
          vim.cmd("wincmd =")
          vim.api.nvim_win_set_width(0, 50)
        end,
      },
      {
        event = "neo_tree_window_before_close",
        handler = function(args) end,
      },
      {
        event = "neo_tree_window_after_close",
        handler = function(args)
          vim.cmd("wincmd =")
          require("virt-column").refresh()
          mega.resize_windows()
          mega.blink_cursorline()
          vim.cmd("e")
        end,
      },
    },
    filesystem = {
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = true,
      group_empty_dirs = true,
      follow_current_file = true,
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = true,
        never_show = {
          ".DS_Store",
        },
      },
    },
    default_component_configs = {
      icon = {
        folder_empty = "",
      },
      git_status = {
        symbols = {
          added = icons.git.add,
          deleted = icons.git.remove,
          modified = icons.git.mod,
          renamed = icons.git.rename,
          untracked = "",
          ignored = "",
          unstaged = "",
          staged = "",
          conflict = "",
        },
      },
    },
    window = {
      position = "left",
      width = 80,
      mappings = {
        o = "toggle_node",
        ["/"] = "noop",
        ["n"] = "noop",
        ["<c-/>"] = "fuzzy_finder",
        -- ["<c-o>"] = "open",
        -- ["<c-s>"] = "open_split",
        -- ["<CR>"] = "open_vsplit",
        ["<c-o>"] = "open_with_window_picker",
        ["<c-s>"] = "split_with_window_picker",
        ["<CR>"] = "vsplit_with_window_picker",
        ["<esc>"] = "revert_preview",
        ["P"] = { "toggle_preview", config = { use_float = true } },
      },
    },
  })

  mega.conf("window-picker", {
    autoselect_one = true,
    include_current = false,
    filter_rules = {
      bo = {
        filetype = { "neo-tree-popup", "quickfix", "incline" },
        buftype = { "terminal", "quickfix", "nofile" },
      },
    },
    other_win_hl_color = mega.colors.dark_red,
  })
end
