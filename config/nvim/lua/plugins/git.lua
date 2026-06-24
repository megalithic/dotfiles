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
    "barrettruth/diffs.nvim",
    init = function()
      vim.g.diffs = {
        integrations = {
          fugitive = true,
          neogit = true,
          neojj = false,
          gitsigns = true,
          committia = false,
          telescope = false,
        },
      }
    end,
  },

  {
    "linrongbin16/gitlinker.nvim",
    cmd = "GitLink",
    keys = {
      { "<localleader>gof", "<cmd>GitLink!<cr>", mode = { "n", "x" }, desc = "copy file url" },
      { "<localleader>gyf", "<cmd>GitLink<cr>", mode = { "n", "x" }, desc = "open file url" },
      { "<localleader>goc", "<cmd>GitLink! current_branch<cr>", mode = { "n", "x" }, desc = "open current branch url" },
      { "<localleader>gyc", "<cmd>GitLink current_branch<cr>", mode = { "n", "x" }, desc = "copy current branch url" },
      { "<localleader>gob", "<cmd>GitLink! blame<cr>", mode = { "n", "x" }, desc = "open blame url" },
      { "<localleader>gyb", "<cmd>GitLink blame<cr>", mode = { "n", "x" }, desc = "copy blame url" },
    },
    opts = {},
  },

  {
    "NeogitOrg/neogit",
    cmd = "Neogit",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>gg", function() require("neogit").open() end, desc = "neogit: open status" },
      { "<leader>gS", function() require("neogit").open() end, desc = "neogit: open status" },
      { "<localleader>gc", function() require("neogit").open({ "commit", "-v" }) end, desc = "neogit: commit" },
    },
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
        snacks = true,
      },
      graph_style = "kitty",
      process_spinner = "true",
    },
    config = function(_, opts) require("neogit").setup(opts) end,
  },

  {
    "madmaxieee/unclash.nvim",
    lazy = true,
    cmd = {
      "UnclashAcceptCurrent",
      "UnclashAcceptIncoming",
      "UnclashAcceptBoth",
      "UnclashScan",
      "UnclashQf",
      "UnclashTrouble",
      "UnclashOpenMergeEditor",
      "UnclashPick",
    },
    opts = {},
    keys = {
      { "<leader>fx", function() require("unclash.snacks").pick() end, desc = "Pick conflicts" },
      { "<leader>gco", function() require("unclash").open_merge_editor() end, desc = "Open Merge Editor" },
      { "<localleader>cc", function() require("unclash").accept_current() end, desc = "Accept Current" },
      { "<localleader>co", function() require("unclash").accept_current() end, desc = "Accept Current" },
      { "<localleader>ci", function() require("unclash").accept_incoming() end, desc = "Accept Incoming" },
      { "<localleader>ct", function() require("unclash").accept_incoming() end, desc = "Accept Incoming" },
      { "<localleader>cb", function() require("unclash").accept_both() end, desc = "Accept Both" },
    },
    init = function()
      local utils = mega.u
      utils.map_repeatable_pair("n", {
        next = {
          "]x",
          function() require("unclash").next_conflict({ wrap = true }) end,
          { desc = "Go to next conflict" },
        },
        prev = {
          "[x",
          function() require("unclash").prev_conflict({ wrap = true }) end,
          { desc = "Go to previous conflict" },
        },
      })

      utils.map_repeatable_pair("n", {
        next = {
          "]X",
          function() require("unclash").next_conflict({ wrap = true, bottom = true }) end,
          { desc = "Go to next conflict (bottom marker)" },
        },
        prev = {
          "[X",
          function() require("unclash").prev_conflict({ wrap = true, bottom = true }) end,
          { desc = "Go to previous conflict (bottom marker)" },
        },
      })
    end,
  },
}
