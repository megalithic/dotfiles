return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1010,
    init = function()
      local colorscheme = "megaforest"

      local theme = string.format("mega.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end

      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
}
