return {
  "juniorsundar/refer.nvim",
  dependencies = {
    "saghen/blink.cmp",
    "nvim-mini/mini.fuzzy",
  },
  config = function() require("refer").setup() end,
}
