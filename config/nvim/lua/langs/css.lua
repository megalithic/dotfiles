-- lua/langs/css.lua
-- CSS/SCSS/LESS language support

return {
  filetypes = { "css", "scss", "less" },

  servers = {
    cssls = {
      cmd = { "vscode-css-language-server", "--stdio" },
    },
  },

  formatters = {
    css = { "biome", "prettier", stop_after_first = true },
    scss = { "biome", "prettier", stop_after_first = true },
    less = { "biome", "prettier", stop_after_first = true },
  },
}
