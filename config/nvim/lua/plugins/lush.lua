return {
  {
    "rktjmp/lush.nvim",
    branch = "main",
    lazy = false,
    config = function()
      require("themes")
      mega.t[vim.g.theme].apply()
    end,

    -- "rktjmp/lush.nvim",
    -- lazy = false,
    -- priority = 1001,
    -- init = function()
    --   local colorscheme = vim.g.colorscheme or "megaforest"
    --
    --   local config_dir = vim.fn.stdpath("config")
    --   local colorscheme_file = string.format("%s/colors/%s.lua", config_dir, colorscheme)
    --
    --   local ok, lush_theme_obj = pcall(dofile, colorscheme_file)
    --
    --   if ok then
    --     vim.g.colors_name = colorscheme
    --     package.loaded[colorscheme_file] = nil
    --     require("lush")(lush_theme_obj.theme)
    --     _G.mega.ui.colors = lush_theme_obj.colors
    --     _G.mega.ui.theme = lush_theme_obj.theme
    --     pcall(vim.cmd.colorscheme, colorscheme)
    --   end
    -- end,
  },
}
