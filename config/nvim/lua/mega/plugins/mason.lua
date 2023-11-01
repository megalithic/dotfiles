local M = {
  "williamboman/mason.nvim",
  config = function()
    local tools = {
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

    require("mason").setup()
    local mr = require("mason-registry")
    for _, tool in ipairs(tools) do
      local p = mr.get_package(tool)
      if not p:is_installed() then p:install() end
    end
    require("mason-lspconfig").setup({
      automatic_installation = true,
    })
  end,
}

return M
