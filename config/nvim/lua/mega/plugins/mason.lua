local M = {
  "williamboman/mason.nvim",
}

M.tools = {
  "prettierd",
  "prettier",
  "stylua",
  "selene",
  "luacheck",
  "fixjson",
  "eslint_d",
  "shellcheck",
  "deno",
  "shfmt",
  "buf",
  "goimports",
  -- "black",
  -- "isort",
  -- "flake8",
  "cbfmt",
  "elm-format",
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
end

return M
