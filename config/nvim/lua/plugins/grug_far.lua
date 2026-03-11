return {
  "MagicDuck/grug-far.nvim",
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>fr",
      function() require("grug-far").open({}) end,
      mode = "n",
      desc = "Search and replace",
    },
    {
      "<localleader>fr",
      function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
      desc = "Search and replace in current file",
    },
    {
      "<leader>fr",
      function() require("grug-far").open({ visualSelectionUsage = "operate-within-range" }) end,
      mode = "v",
      desc = "Search and replace visual selection",
    },
  },
}
