local nls = require("null-ls")
local b = nls.builtins

local M = {}

function M.setup()
  nls.config({
    debounce = 150,
    save_after_format = false,
    sources = {
      b.formatting.trim_whitespace.with({ filetypes = { "*" } }),
      b.formatting.prettierd.with({
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
      b.formatting.fixjson.with({ filetypes = { "jsonc" } }),
      b.formatting.stylua.with({
        condition = function(util)
          print("has stylua.toml root file?", util.root_has_file("stylua.toml"))
          return util.root_has_file("stylua.toml")
        end,
      }),
      b.formatting.elm_format,
      -- nls.builtins.formatting.eslint_d,
      b.formatting.shfmt.with({
        extra_args = { "-ci", "-s", "-bn" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "zsh" },
      }),
      b.diagnostics.shellcheck,
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
