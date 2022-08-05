return function(on_attach)
  local nls = require("null-ls")
  local b = nls.builtins

  nls.setup({
    debug = false,
    on_attach = on_attach,
    debounce = 150,
    autostart = true,
    save_after_format = false,
    sources = {
      b.formatting.trim_whitespace.with({ filetypes = { "*" } }),
      b.formatting.prettierd.with({
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "css",
          "scss",
          "html",
          "json",
          "jsonc",
          "yaml",
          "graphql",
          "markdown",
        },
        condition = function() return mega.executable("prettierd") end,
      }),
      b.formatting.fixjson.with({ filetypes = { "jsonc", "json" } }),
      -- b.formatting.isort,
      b.formatting.cbfmt:with({
        condition = function() return mega.executable("cbfmt") end,
      }),
      b.formatting.stylua.with({ -- sumneko now formats!
        condition = function()
          return mega.executable("stylua")
            and not vim.tbl_isempty(vim.fs.find({ ".stylua.toml", "stylua.toml" }, {
              path = vim.fn.expand("%:p"),
              upward = true,
            }))
        end,
      }),
      b.formatting.isort,
      b.formatting.black,
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
        extra_args = { "-i", "2", "-ci" }, -- suggested: { "-i", "2", "-ci" } or { "-ci", "-s", "-bn", "-i", "2" }
        -- extra_args = { "-ci", "-s", "-bn", "-i", "2" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "bash" },
      }),
      b.diagnostics.shellcheck.with({
        filetypes = { "sh", "bash" },
      }),
      b.diagnostics.zsh.with({
        filetypes = { "zsh" },
      }),
      -- b.diagnostics.credo,
    },
  })
end
