return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    init = function()
      local colorscheme = "megaforest"

      local theme = string.format("config.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end

      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
      P("colorscheme loaded")

      mega.colors = require("config.lush_theme.colors")
      P("colors loaded")
    end,
  },
}
