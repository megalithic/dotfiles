-- lua/plugins/git.lua
-- Git-related plugins

return {

  -- Gitsigns for git decorations in the sign column
  {
    "lewis6991/gitsigns.nvim",
    event = "LazyFile",
    opts = {
      signs = {
        add = { text = mega.ui.icons.git.add },
        change = { text = mega.ui.icons.git.change },
        delete = { text = mega.ui.icons.git.delete },
        topdelete = { text = mega.ui.icons.git.topdelete },
        changedelete = { text = mega.ui.icons.git.changedelete },
        untracked = { text = mega.ui.icons.git.untracked },
      },
      signs_staged_enable = false,
      signcolumn = false,
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 500,
      },
      -- on_attach = function(bufnr)
      --   -- local gs = package.loaded.gitsigns
      --   -- vim.keymap.set("n", "<localleader>hs", gs.stage_hunk, { desc = "git(hunk): stage hunk", buffer = bufnr })
      --   -- vim.keymap.set(
      --   --   "v",
      --   --   "<localleader>hs",
      --   --   function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end,
      --   --   { desc = "git(hunk): stage hunk", buffer = bufnr }
      --   -- )
      --   -- vim.keymap.set("n", "<localleader>hu", gs.undo_stage_hunk, { desc = "git(hunk): unstage hunk", buffer = bufnr })
      --   -- vim.keymap.set("n", "<localleader>hr", gs.reset_hunk, { desc = "git(hunk): reset hunk", buffer = bufnr })
      --   -- vim.keymap.set("n", "<localleader>hp", gs.preview_hunk, { desc = "git(hunk): preview hunk", buffer = bufnr })
      -- end,
    },
  },

  {
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    keys = {
      -- { "<leader>gyf", "<cmd>GitLink<cr>", mode = { "n", "v" }, desc = "Copy file url" },
      -- { "<leader>gxf", "<cmd>GitLink!", mode = { "n", "v" }, desc = "Open file in browser" },
      --
      -- { "<leader>gxb", "<cmd>GitLink current_branch<cr>", mode = { "n", "v" }, desc = "Open branch in browser" },
      -- { "<leader>gyb", "<cmd>GitLink current_branch<cr>", mode = { "n", "v" }, desc = "Copy branch url" },
      --
      -- { "<leader>gxr", "<cmd>GitLink! default_branch<cr>", mode = { "n", "v" }, desc = "Open repo in browser" },
      -- { "<leader>gyr", "<cmd>GitLink default_branch<cr>", mode = { "n", "v" }, desc = "Copy repo url" },

      { "<localleader>gxb", "<cmd>GitLink! blame<cr>", mode = { "n", "v" }, desc = "Open blame in browser" },
    },
    opts = {},
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      disable_signs = false,
      disable_hint = true,
      disable_commit_confirmation = true,
      disable_builtin_notifications = true,
      disable_insert_on_commit = false,
      fetch_after_checkout = true,
      signs = {
        section = { "", "" },
        item = { "▸", "▾" },
        hunk = { "󰐕", "󰍴" },
      },
      integrations = {
        diffview = true,
        mini_pick = true,
      },
      graph_style = "kitty",
      process_spinner = "true",
    },
    config = function(_, opts) require("neogit").setup(opts) end,
  },

  {
    "madmaxieee/unclash.nvim",
    lazy = false,
    opts = {},
    init = function()
      local unclash = require("unclash")
      local utils = mega.u
      utils.map_repeatable_pair("n", {
        next = {
          "]x",
          function() unclash.next_conflict({ wrap = true }) end,
          { desc = "Go to next conflict" },
        },
        prev = {
          "[x",
          function() unclash.prev_conflict({ wrap = true }) end,
          { desc = "Go to previous conflict" },
        },
      })

      utils.map_repeatable_pair("n", {
        next = {
          "]X",
          function() unclash.next_conflict({ wrap = true, bottom = true }) end,
          { desc = "Go to next conflict (bottom marker)" },
        },
        prev = {
          "[X",
          function() unclash.prev_conflict({ wrap = true, bottom = true }) end,
          { desc = "Go to previous conflict (bottom marker)" },
        },
      })

      vim.keymap.set("n", "<leader>gco", unclash.open_merge_editor, { desc = "Open Merge Editor" })
      --
      -- -- Helper to accept conflicts
      vim.keymap.set("n", "<localleader>cc", unclash.accept_current, { desc = "Accept Current" })
      vim.keymap.set("n", "<localleader>co", unclash.accept_current, { desc = "Accept Current" })
      vim.keymap.set("n", "<localleader>ci", unclash.accept_incoming, { desc = "Accept Incoming" })
      vim.keymap.set("n", "<localleader>ct", unclash.accept_incoming, { desc = "Accept Incoming" })
      vim.keymap.set("n", "<localleader>cb", unclash.accept_both, { desc = "Accept Both" })
    end,
  },
}
