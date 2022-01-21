local nls = require("null-ls")
local b = nls.builtins

local M = {}

function M.setup(on_attach)
  nls.setup({
    debug = false,
    debounce = 150,
    autostart = true,
    save_after_format = false,
    on_attach = on_attach,
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
      b.formatting.stylua.with({
        condition = function(util)
          return mega.executable("stylua") and util.root_has_file("stylua.toml")
        end,
      }),
      b.formatting.elm_format,
      -- b.formatting.mix.with({ filetypes = { "html.heex", "heex" } }),
      -- b.formatting.surface.with({ filetypes = { "elixir", "eelixir", "heex", "html.heex", "surface" } }),
      -- nls.builtins.formatting.rustywind.with({
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
        extra_args = { "-ci", "-s", "-bn" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "zsh" },
      }),
      b.diagnostics.shellcheck,
      b.diagnostics.credo,
      -- b.diagnostics.selene, -- this breaks?
    },
  })
end

function M.has_formatter(ft)
  local sources = require("null-ls.sources")
  local available = sources.get_available(ft, "NULL_LS_FORMATTING")
  return #available > 0
end

return M
