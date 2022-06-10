return function()
  -- only needed if you want to use the commands with "_with_window_picker" suffix
  -- 's1n7ax/nvim-window-picker',
  -- tag = "1.*",
  -- config = function()
  --   require'window-picker'.setup({
  --     autoselect_one = true,
  --     include_current = false,
  --     filter_rules = {
  --       -- filter using buffer options
  --       bo = {
  --         -- if the file type is one of following, the window will be ignored
  --         filetype = { 'neo-tree', "neo-tree-popup", "notify", "quickfix" },

  --         -- if the buffer type is one of following, the window will be ignored
  --         buftype = { 'terminal' },
  --       },
  --     },
  --     other_win_hl_color = '#e35e4f',
  --   })
  -- end,
  vim.g.neo_tree_remove_legacy_commands = 1
  local icons = mega.icons
  mega.nnoremap("<c-n>", "<Cmd>Neotree toggle reveal<CR>")
  mega.nnoremap("<c-t>", "<Cmd>Neotree toggle reveal<CR>")
  require("neo-tree").setup({
    enable_git_status = true,
    git_status_async = true,
    event_handlers = {
      {
        event = "neo_tree_buffer_enter",
        handler = function()
          vim.cmd("setlocal signcolumn=no")
          vim.cmd("highlight! Cursor blend=100")
        end,
      },
      {
        event = "neo_tree_buffer_leave",
        handler = function()
          vim.cmd("highlight! Cursor blend=0")
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
      mappings = {
        o = "toggle_node",
        -- ["<CR>"] = "open_with_window_picker",
        -- ["<c-s>"] = "split_with_window_picker",
        -- ["<c-v>"] = "vsplit_with_window_picker",
        ["<c-o>"] = "open",
        ["<c-s>"] = "open_split",
        ["<CR>"] = "open_vsplit",
      },
    },
  })
end
