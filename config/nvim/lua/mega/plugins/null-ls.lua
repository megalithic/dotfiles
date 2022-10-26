return function()
  -- local ok, null = pcall(require, "null-ls")
  -- if not ok then return end
  local null = require("null-ls")

  local format = null.builtins.formatting
  local diag = null.builtins.diagnostics
  -- local actions = nls.builtins.code_actions
  -- local completion = nls.builtins.completion

  null.setup({
    debounce = vim.g.is_local_dev and 200 or 500,
    default_timeout = vim.g.is_local_dev and 500 or 3000,
    root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
    sources = {
      format.trim_whitespace.with({ filetypes = { "*" } }),
      format.prettier.with({
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
        condition = function() return mega.executable("prettier") end,
      }),
      -- format.prettierd.with({
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
      --   condition = function() return mega.executable("prettierd") end,
      -- }),
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
      format.mix.with({
        extra_filetypes = { "eelixir", "heex" },
        args = { "format", "-" },
        extra_args = function(_params)
          local version_output = vim.fn.system("elixir -v")
          local minor_version = vim.fn.matchlist(version_output, "Elixir \\d.\\(\\d\\+\\)")[2]

          local extra_args = {}

          -- tells the formatter the filename for the code passed to it via stdin.
          -- This allows formatting heex files correctly. Only available for
          -- Elixir >= 1.14
          if tonumber(minor_version, 10) >= 14 then extra_args = { "--stdin-filename", "$FILENAME" } end

          return extra_args
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
      diag.credo.with({
        -- run credo in strict mode even if strict mode is not enabled in
        -- .credo.exs
        extra_args = { "--strict" },
        -- only register credo source if it is installed in the current project
        condition = function(_utils)
          local cmd = { "rg", ":credo", "mix.exs" }
          local credo_installed = ("" == vim.fn.system(cmd))
          return not credo_installed
        end,
      }),
    },
  })
end
