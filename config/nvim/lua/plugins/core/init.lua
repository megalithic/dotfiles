return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
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
  {
    "comfysage/evergarden",
    priority = 1000,
    opts = {
      transparent_background = true,
      variant = "soft", -- 'hard'|'medium'|'soft'
      override_terminal = true,
      style = {
        tabline = { "reverse" },
        search = { "italic" },
        incsearch = { "reverse" },
        types = { "italic" },
        keyword = { "italic" },
        comment = { "italic" },
        sign = { highlight = false },
      },
      integrations = {
        blink_cmp = true,
        cmp = true,
        gitsigns = true,
        indent_blankline = { enable = true, scope_color = "green" },
        nvimtree = true,
        rainbow_delimiters = true,
        symbols_outline = true,
        telescope = true,
        which_key = true,
      },
      overrides = {}, -- add custom overrides
    },
    config = function(_, opts)
      require("evergarden").setup(opts)
      pcall(vim.cmd.colorscheme, vim.g.colorscheme)
    end,
  },
  {
    "rachartier/tiny-glimmer.nvim",
    cond = false,
    event = "VeryLazy",
    opts = {
      -- your configuration
    },
  },
}
