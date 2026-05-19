return {
  "juniorsundar/refer.nvim",
  lazy = true,
  cmd = "Refer",
  dependencies = {
    "saghen/blink.cmp",
    "nvim-mini/mini.fuzzy",
  },
  config = function() require("refer").setup() end,
}
