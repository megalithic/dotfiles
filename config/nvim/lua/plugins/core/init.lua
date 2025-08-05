return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    init = function()
      local colorscheme = vim.g.colorscheme or "megaforest"

      local theme = string.format("lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil
        pcall(vim.cmd.colorscheme, colorscheme)

        require("lush")(lush_theme)
      end

      mega.colors = require("lush_theme.colors")
    end,
  },
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

  { "brianhuster/unnest.nvim" },
}
