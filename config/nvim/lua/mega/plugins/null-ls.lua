return function()
  -- local ok, null = pcall(require, "null-ls")
  -- if not ok then return end
  local null = require("null-ls")

  local format = null.builtins.formatting
  local diag = null.builtins.diagnostics
  -- local actions = nls.builtins.code_actions
  -- local completion = nls.builtins.completion

  null.setup({
    debounce = 150,
    sources = {
      format.trim_whitespace.with({ filetypes = { "*" } }),
      -- format.prettier.with({
      --   filetypes = {
      --     "javascript",
      --     "javascriptreact",
      --     "typescript",
      --     "typescriptreact",
      --     "css",
      --     "scss",
      --     "eruby",
      --     "html",
      --     "svg",
      --     "json",
      --     "jsonc",
      --     "yaml",
      --     "graphql",
      --     "markdown",
      --   },
      --   condition = function() return mega.executable("prettier") end,
      -- }),
      format.prettierd.with({
        filetypes = {
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "css",
          "scss",
          "eruby",
          "html",
          "svg",
          "json",
          "jsonc",
          "yaml",
          "graphql",
          "markdown",
        },
        condition = function() return mega.executable("prettierd") end,
      }),
      format.fixjson.with({ filetypes = { "jsonc", "json" } }),
      format.cbfmt:with({
        condition = function() return mega.executable("cbfmt") end,
      }),
      format.stylua.with({ -- sumneko now formats!
        condition = function()
          return mega.executable("stylua")
            and not vim.tbl_isempty(vim.fs.find({ ".stylua.toml", "stylua.toml" }, {
              path = vim.fn.expand("%:p"),
              upward = true,
            }))
        end,
      }),
      format.isort,
      format.black.with({
        extra_args = function(_)
          return {
            "--fast",
            "--quiet",
            "--target-version",
            "py310",
            "-l",
            vim.opt_local.colorcolumn:get()[1] or "88",
          }
        end,
      }),
      format.beautysh.with({
        extra_args = { "-i", "2" },
        condition = function() return mega.executable("beautysh") end,
      }),
      format.shellharden,
      format.elm_format,
      format.jq,
      format.markdownlint,
      format.shfmt.with({
        extra_args = { "-i", "2", "-ci" }, -- suggested: { "-i", "2", "-ci" } or { "-ci", "-s", "-bn", "-i", "2" }
        -- extra_args = { "-ci", "-s", "-bn", "-i", "2" }, -- suggested: { "-i", "2", "-ci" }
        filetypes = { "sh", "bash" },
      }),
      diag.flake8.with({
        extra_args = function(_) return { "--max-line-lenth", vim.opt_local.colorcolumn:get()[1] or "88" } end,
      }),
      diag.shellcheck.with({
        filetypes = { "sh", "bash" },
      }),
      diag.zsh.with({
        filetypes = { "zsh" },
      }),
      -- diag.editorconfig_checker.with({ command = "editorconfig-checker" }),
      -- b.diagnostics.credo,
    },
  })
end
