local fmt = string.format

return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    init = function()
      local colorscheme = "megaforest"
      -- mega.pcall("lush theme failed to load", function(colorscheme)
      local theme = fmt("mega.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end
      -- NOTE: always make available my lushified-color palette
      -- mega.colors = require("mega.lush_theme.colors")
      -- end, vim.g.colorscheme)

      pcall(vim.cmd.colorscheme, colorscheme)
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
}
