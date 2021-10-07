local nls = require("null-ls")

local M = {}

function M.setup()
  nls.config({
    debounce = 150,
    save_after_format = false,
    sources = {
      nls.builtins.formatting.trim_whitespace.with({ filetypes = { "*" } }),
      nls.builtins.formatting.prettierd.with({
        filetypes = {
          -- "javascript",
          -- "javascriptreact",
          -- "typescript",
          -- "typescriptreact",
          "vue",
          "svelte",
          "css",
          "scss",
          "html",
          "json",
          "yaml",
          "markdown",
          "markdown.mdx",
        },
      }),
      nls.builtins.formatting.stylua.with({
        condition = function(util)
          return util.root_has_file("stylua.toml")
        end,
      }),
      nls.builtins.formatting.elm_format,
      nls.builtins.formatting.eslint_d,
      nls.builtins.diagnostics.shellcheck,
      -- nls.builtins.diagnostics.markdownlint,
      -- nls.builtins.diagnostics.selene,
    },
  })
end

function M.has_formatter(ft)
  local config = require("null-ls.config").get()
  local formatters = config._generators["NULL_LS_FORMATTING"]
  for _, f in ipairs(formatters) do
    if vim.tbl_contains(f.filetypes, ft) then
      return true
    end
  end
end

return M
