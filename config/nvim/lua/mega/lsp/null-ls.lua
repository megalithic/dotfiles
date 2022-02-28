local nls = require("null-ls")
local b = nls.builtins

local M = {}

function M.setup()
  nls.setup({
    debug = false,
    debounce = 150,
    autostart = true,
    save_after_format = false,
    on_attach = mega.lsp.on_attach,
    sources = {
      b.formatting.trim_whitespace.with({ filetypes = { "*" } }),
      b.formatting.prettierd.with({
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "css",
          "scss",
          "html",
          "yaml",
          "markdown",
          "markdown.mdx",
        },
        condition = function()
          return mega.executable("prettierd")
        end,
      }),
      b.formatting.fixjson.with({ filetypes = { "jsonc" } }),
      -- b.formatting.isort,
      b.formatting.stylua.with({ -- sumneko now formats!
        condition = function(util)
          return mega.executable("stylua") and util.root_has_file("stylua.toml")
        end,
      }),
      b.formatting.elm_format,
      -- FIXME: doesn't work on heex for some reason
      -- b.formatting.mix.with({ extra_filetypes = { "heex", "phoenix-html" } }),
      -- b.formatting.surface.with({ filetypes = { "elixir", "eelixir", "heex", "html.heex", "surface" } }),
      -- b.formatting.rustywind.with({
      --   filetypes = {
      --     "javascript",
      --     "javascriptreact",
      --     "typescript",
      --     "typescriptreact",
      --     "html",
      --     "heex",
      --     "elixir",
      --     "eelixir",
      --     "surface",
      --   },
      -- }),
      b.formatting.shfmt.with({
        extra_args = { "-ci", "-s", "-bn", "-i", "2" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "zsh" },
      }),
      b.diagnostics.shellcheck,
      -- b.diagnostics.credo,
      -- b.diagnostics.selene, -- this breaks?
    },
  })
end

return M
