return {
  -- {
  --   "nicolasgb/jj.nvim",
  --   version = "*", -- Use latest stable release
  --   -- Or from the main branch (uncomment the branch line and comment the version line)
  --   -- branch = "main",
  --   config = function() require("jj").setup({}) end,
  -- },

  {
    "krisajenkins/neojj",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for async operations
    },
    config = function()
      local neojj = require("neojj")
      neojj.setup()

      -- Optional: Add keybindings
      -- vim.keymap.set("n", "<leader>gs", neojj.jj_status, { desc = "JJ Status" })
      vim.keymap.set("n", "<leader>gl", neojj.jj_log, { desc = "JJ Log" })
      -- vim.keymap.set("n", "<leader>gd", neojj.jj_describe, { desc = "JJ Describe" })
      -- vim.keymap.set("n", "<leader>gS", neojj.jj_split, { desc = "JJ Split" })
    end,
  },

  {
    "JulianNymark/neojjit",
    -- opts = {},
    keys = {
      { "<leader>gs", function() require("neojjit").open() end, desc = "Neojjit" },
    },
  },
}
