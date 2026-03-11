return {
  -- {
  --   "NicolasGB/jj.nvim",
  --   version = "*", -- Use latest stable release
  --   -- Or from the main branch (uncomment the branch line and comment the version line)
  --   -- branch = "main",
  --   opts = {
  --     diff = { backend = "codediff" }, -- native|codediff|diffview
  --   },
  --   config = function(_, opts) require("jj").setup(opts) end,
  -- },
  {
    "yannvanhalewyn/jujutsu.nvim",
    opts = {
      diff_preset = "diffview",
    },
    config = function(_, opts) require("jujutsu-nvim").setup(opts) end,
  },
  -- {
  --   -- https://github.com/jceb/jiejie.nvim.git
  --   "jceb/jiejie.nvim",
  --   opts = {},
  -- },
}
