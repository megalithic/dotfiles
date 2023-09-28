local M = {
  "williamboman/mason.nvim",
}

M.tools = {
  "prettierd",
  "prettier",
  "stylua",
  "selene",
  "luacheck",
  -- "fixjson",
  -- "eslint_d",
  "shellcheck",
  -- "deno",
  "shfmt",
  -- "goimports",
  -- "black",
  -- "isort",
  -- "flake8",
  -- "cbfmt",
  -- "buf",
  -- "elm-format",
  "yamlfmt",
}

function M.check()
  local mr = require("mason-registry")
  for _, tool in ipairs(M.tools) do
    local p = mr.get_package(tool)
    if not p:is_installed() then p:install() end
  end
end

function M.config()
  require("mason").setup()
  M.check()
  require("mason-lspconfig").setup({
    automatic_installation = true,
  })

  -- local mason_lspconfig = require("mason-lspconfig")
  --
  -- mason_lspconfig.setup({
  --   ensure_installed = vim.tbl_keys(servers),
  -- })
  --
  -- mason_lspconfig.setup_handlers({
  --   function(server_name)
  --
  --     require("lspconfig")[server_name].setup({
  --       capabilities = capabilities,
  --       on_attach = on_attach,
  --       settings = servers[server_name],
  --       filetypes = (servers[server_name] or {}).filetypes,
  --     })
  --   end,
  -- })
end

return M
