return {
  -- ( CORE ) ------------------------------------------------------------------
  { "dstein64/vim-startuptime", cmd = { "StartupTime" }, config = function() vim.g.startuptime_tries = 15 end },

  -- ( UI ) --------------------------------------------------------------------
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    config = function()
      mega.pcall("theme failed to load because", function(colorscheme)
        local theme = fmt("mega.lush_theme.%s", colorscheme)
        local ok, lush_theme = pcall(require, theme)

        if ok then
          vim.g.colors_name = colorscheme
          package.loaded[theme] = nil

          require("lush")(lush_theme)
        else
          pcall(vim.cmd.colorscheme, colorscheme)
        end

        -- NOTE: always make available my lushified-color palette
        -- mega.colors = require("mega.lush_theme.colors")
      end, vim.g.colorscheme)

      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  {
    "mcchrish/zenbones.nvim",
    cond = vim.tbl_contains({ "forestbones", "tokyobones" }, vim.g.colorscheme),
    lazy = false,
    priority = 1001,
  },
  {
    "ribru17/bamboo.nvim",
    cond = vim.g.colorscheme == "bamboo",
    lazy = false,
    priority = 1001,
    config = function()
      require("bamboo").setup({
        style = "multiplex", -- alts: megaforest, multiplex, vulgaris, light
        transparent = true,
        dim_inactive = true,
        highlights = {
          -- make comments blend nicely with background, similar to other color schemes
          -- ["@comment"] = { fg = "$grey" },
          -- ["@keyword"] = { fg = "$green" },
          -- ["@string"] = { fg = "$bright_orange", bg = "#00ff00", fmt = "bold" },
          -- ["@function"] = { fg = "#0000ff", sp = "$cyan", fmt = "underline,italic" },
          -- ["@function.builtin"] = { fg = "#0059ff" },
          --
          CursorLineNr = { fg = "$orange", fmt = "bold,italic" },
          -- TSKeyword = { fg = "$green" },
          -- TSString = { fg = "$bright_orange", bg = "#00ff00", fmt = "bold" },
          -- TSFunction = { fg = "#0000ff", sp = "$cyan", fmt = "underline,italic" },
          -- TSFuncBuiltin = { fg = "#0059ff" },
        },
      })

      require("bamboo").load()
    end,
  },
  {
    "sainnhe/everforest",
    cond = false,
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.everforest_background = "soft"
      vim.g.everforest_better_performance = true
    end,
  },

  {
    "neanias/everforest-nvim",
    lazy = false,
    priority = 1000,
    cond = vim.g.colorscheme == "everforest",
    config = function()
      require("everforest").setup({
        dim_inactive_windows = true,
        transparent_background_level = 2,
        background = "medium",
        italics = true,
        on_highlights = function(hl, p)
          -- hl.NeoTreeStatusLine = { fg = p.none, bg = p.none, sp = p.red }
        end,
      })
    end,
  },
  {
    "farmergreg/vim-lastplace",
    lazy = false,
    init = function()
      vim.g.lastplace_ignore = "gitcommit,gitrebase,svn,hgcommit,oil,megaterm,neogitcommit,gitrebase"
      vim.g.lastplace_ignore_buftype = "quickfix,nofile,help,terminal"
      vim.g.lastplace_open_folds = true
    end,
  },
  { "nvim-tree/nvim-web-devicons", config = function() require("nvim-web-devicons").setup() end },
  {
    "NvChad/nvim-colorizer.lua",
    event = { "BufReadPre" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*", "!lazy", "!gitcommit", "!NeogitCommitMessage", "!oil" },
        buftype = { "*", "!prompt", "!nofile", "!oil" },
        user_default_options = {
          RGB = false, -- #RGB hex codes
          RRGGBB = true, -- #RRGGBB hex codes
          names = false, -- "Name" codes like Blue or blue
          RRGGBBAA = true, -- #RRGGBBAA hex codes
          AARRGGBB = true, -- 0xAARRGGBB hex codes
          rgb_fn = true, -- CSS rgb() and rgba() functions
          hsl_fn = true, -- CSS hsl() and hsla() functions
          -- css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
          css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
          sass = { enable = false, parsers = { "css" } }, -- Enable sass colors
          -- Available modes for `mode`: foreground, background,  virtualtext
          mode = "background", -- Set the display mode.
          virtualtext = "■",
        },
        -- all the sub-options of filetypes apply to buftypes
        buftypes = {},
      })
    end,
  },
}
