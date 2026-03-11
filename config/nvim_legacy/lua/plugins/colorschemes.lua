return {

  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    init = function()
      local colorscheme = vim.g.colorscheme or "megaforest"

      local config_dir = vim.fn.stdpath("config")
      local colorscheme_file = string.format("%s/colors/%s.lua", config_dir, colorscheme)

      local ok, lush_theme_obj = pcall(dofile, colorscheme_file)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[colorscheme_file] = nil
        require("lush")(lush_theme_obj.theme)
        _G.mega.ui.colors = lush_theme_obj.colors
        _G.mega.ui.theme = lush_theme_obj.theme
        pcall(vim.cmd.colorscheme, colorscheme)
      end
    end,
  },
  -- {
  --   "rktjmp/lush.nvim",
  --   lazy = false,
  --   priority = 1001,
  --   init = function()
  --     local colorscheme = vim.g.colorscheme or "megaforest"
  --
  --     local config_dir = vim.fn.stdpath("config")
  --     local colorscheme_file = string.format("%s/colors/%s.lua", config_dir, colorscheme)
  --
  --     local ok, lush_theme_obj = pcall(dofile, colorscheme_file)
  --
  --     if ok then
  --       -- vim.g.colors_name = colorscheme
  --       -- package.loaded[colorscheme_file] = nil
  --       require("lush")(lush_theme_obj.theme)
  --       _G.mega.ui.colors = lush_theme_obj.colors
  --     end
  --     -- local colorscheme = vim.g.colorscheme or "megaforest"
  --
  --     -- local theme = string.format("lush_theme.%s", colorscheme)
  --     -- local ok, lush_theme = pcall(require, theme)
  --
  --     -- if ok then
  --     --   vim.g.colors_name = colorscheme
  --     --   package.loaded[theme] = nil
  --     --   pcall(vim.cmd.colorscheme, colorscheme)
  --
  --     --   require("lush")(lush_theme)
  --     -- end
  --
  --     -- mega.ui.colors = require("lush_theme.colors")
  --   end,
  -- },
  -- {
  --   "sainnhe/everforest",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --
  --     -- vim.g.everforest_colors_override = {
  --     --   bg0
  --     -- }
  --
  --     vim.cmd.colorscheme("everforest")
  --   end,
  -- },
  -- {
  --   "zenbones-theme/zenbones.nvim",
  --   dependencies = "rktjmp/lush.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     vim.g.forestbones = { solid_line_nr = true, darken_comments = 45, transparent_background = true }
  --     pcall(vim.cmd.colorscheme, vim.g.colorscheme)
  --   end,
  -- },
}
