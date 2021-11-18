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
          -- "vue",
          -- "svelte",
          "css",
          "scss",
          "html",
          "yaml",
          "markdown",
          "markdown.mdx",
        },
      }),
      nls.builtins.formatting.fixjson.with({ filetypes = { "jsonc" } }),
      nls.builtins.formatting.stylua.with({
        condition = function(util)
          return util.root_has_file("stylua.toml")
        end,
      }),
      nls.builtins.formatting.elm_format,
      -- nls.builtins.formatting.eslint_d,
      nls.builtins.formatting.shfmt.with({
        extra_args = { "-ci", "-s", "-bn" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "zsh" },
      }),
      nls.builtins.diagnostics.shellcheck,
      -- nls.builtins.diagnostics.markdownlint,
      -- nls.builtins.diagnostics.selene,
    },
  })
end

function M.has_formatter(ft)
  local sources = require("null-ls.sources")
  local available = sources.get_available(ft, "NULL_LS_FORMATTING")
  return #available > 0
end

return M
