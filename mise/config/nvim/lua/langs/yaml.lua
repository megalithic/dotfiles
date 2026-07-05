-- lua/langs/yaml.lua
-- YAML language support with schemastore

return {
  filetypes = { "yaml", "yml" },

  servers = {
    yamlls = {
      cmd = { "yaml-language-server", "--stdio" },
      settings = {
        yaml = {
          -- Function evaluated at LSP setup time (when schemastore is loaded)
          schemas = function()
            local ok, schemastore = pcall(require, "schemastore")
            return ok and schemastore.yaml.schemas() or {}
          end,
          schemaStore = { enable = false, url = "" },  -- Disable built-in, use schemastore
        },
      },
    },
  },

  formatters = {
    yaml = { "prettier" },
  },
}
