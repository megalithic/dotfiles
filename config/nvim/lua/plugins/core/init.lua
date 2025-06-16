return {
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.forestbones = { solid_line_nr = true, darken_comments = 45, transparent_background = true }
      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
    end,
  },
}
