-- lua/langs/json.lua
-- JSON language support with schemastore

return {
  filetypes = { "json", "jsonc" },

  servers = {
    jsonls = {
      cmd = { "vscode-json-language-server", "--stdio" },
      settings = {
        json = {
          -- Function evaluated at LSP setup time (when schemastore is loaded)
          schemas = function()
            local ok, schemastore = pcall(require, "schemastore")
            return ok and schemastore.json.schemas() or {}
          end,
          validate = { enable = true },
        },
      },
    },
  },

  formatters = {
    json = { "jq" },
    jsonc = { "prettier" },
  },
}
