local fmt = string.format

return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1010,
    init = function()
      local colorscheme = "megaforest"

      local theme = fmt("mega.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end

      -- pcall(vim.cmd.colorscheme, colorscheme)
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  {
    "neanias/everforest-nvim",
    cond = vim.g.colorscheme == "everforest",
    version = false,
    lazy = false,
    priority = 1000, -- make sure to load this before all the other start plugins
    opts = {
      background = "soft",
      transparent_background_level = 2,
    },
    config = function(_, opts)
      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
      require("everforest").setup(opts)
    end,
  },
  {
    "ribru17/bamboo.nvim",
    lazy = false,
    cond = vim.g.colorscheme == "bamboo",
    priority = 1000,
    opts = {
      style = "multiplex", -- Choose between 'vulgaris' (regular), 'multiplex' (greener), and 'light'
      transparent = true,
      toggle_style_key = "<leader><leader>",
      toggle_style_list = { "multiplex", "light", "vulgaris" }, -- List of styles to toggle between
      diagnostics = {
        undercurl = false,
      },
      highlights = {
        ["@comment"] = { fg = "$grey" },
        ["@checked.content"] = { fg = "$grey", fmt = "strikethrough" },
        -- TODO: Put this setting into bamboo.nvim once 0.11 drops
        ["WinBar"] = { fmt = "underline", fg = "$light_grey", sp = "$grey" },
      },
    },
    config = function(_, opts)
      require("bamboo").setup(opts)
      vim.cmd.colorscheme({ args = { vim.g.colorscheme } })
      -- require("bamboo").load()
    end,
  },
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = "rktjmp/lush.nvim",
    cond = vim.g.colorscheme == "forestbones",
    lazy = false,
    priority = 1000,
    opts = {
      solid_line_nr = true,
      darken_comments = 45,
      transparent_background = true,
    },
    config = function(_, opts)
      vim.g.forestbones = opts
      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
    end,
  },
}
