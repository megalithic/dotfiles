-- lua/langs/html.lua
-- HTML language support

return {
  filetypes = { "html" },

  servers = {
    html = {
      cmd = { "vscode-html-language-server", "--stdio" },
    },
  },

  formatters = {
    html = { "prettier" },
  },
}
