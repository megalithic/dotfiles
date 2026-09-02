-- lua/langs/liquid.lua
-- Shopify Liquid theme support

return {
  filetypes = { "liquid" },

  servers = {
    shopify_theme_ls = {
      cmd = { "shopify", "theme", "language-server" },
      filetypes = { "liquid" },
      root_markers = {
        ".shopifyignore",
        ".theme-check.yml",
        ".theme-check.yaml",
        "shopify.theme.toml",
      },
      settings = {},
    },
  },

  formatters = {
    liquid = { "prettier" },
  },

  ftplugin = {
    liquid = {
      opt = {
        shiftwidth = 2,
        tabstop = 2,
        softtabstop = 2,
        expandtab = true,
      },
    },
  },
}
