-- lua/langs/nix.lua
-- Nix language support

return {
  filetypes = { "nix" },

  servers = {
    nil_ls = {
      cmd = { "nil" },
      settings = {
        ["nil"] = {
          formatting = {
            command = { "alejandra" },
          },
          nix = {
            flake = {
              autoArchive = true,
              autoEvalInputs = true,
            },
          },
        },
      },
    },
  },

  formatters = {
    nix = { "alejandra" },
  },
}
