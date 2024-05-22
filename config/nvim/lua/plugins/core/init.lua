local fmt = string.format

return {
  {
    "rktjmp/lush.nvim",
    lazy = false,
    priority = 1001,
    init = function()
      local colorscheme = "megaforest"

      local theme = fmt("mega.lush_theme.%s", colorscheme)
      local ok, lush_theme = pcall(require, theme)

      if ok then
        vim.g.colors_name = colorscheme
        package.loaded[theme] = nil

        require("lush")(lush_theme)
      end

      pcall(vim.cmd.colorscheme, colorscheme)
      mega.colors = require("mega.lush_theme.colors")
    end,
  },
  {
    "vhyrro/luarocks.nvim",
    priority = 1001, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
    opts = {
      rocks = { "magick" },
      -- rocks = { "fzy", "pathlib.nvim ~> 1.0" }, -- specifies a list of rocks to install
      -- luarocks_build_args = { "--with-lua=/my/path" }, -- extra options to pass to luarocks's configuration script
    },
  },
  {
    "3rd/image.nvim",
    dependencies = { "luarocks.nvim" },
    opts = {
      tmux_show_only_in_active_window = true,
    },
  },
}
