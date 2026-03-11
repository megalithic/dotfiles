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
    css = { "prettier" },
    scss = { "prettier" },
    less = { "prettier" },
  },
}
