-- lua/langs/bash.lua
-- Bash/shell language support

return {
  filetypes = { "sh", "bash", "zsh" },

  servers = {
    bashls = {
      cmd = { "bash-language-server", "start" },
    },
  },

  formatters = {
    sh = { "shfmt" },
    bash = { "shfmt" },
  },
}
