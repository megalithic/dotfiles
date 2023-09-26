local M = {
  -- {
  "jose-elias-alvarez/null-ls.nvim",
  -- cond = vim.g.formatter == "null-ls",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    if vim.g.formatter ~= "null-ls" then return end
    local nls = require("null-ls")

    local format = nls.builtins.formatting
    local diag = nls.builtins.diagnostics

    -- local custom_ca = require("user.lsp.code_actions")
    -- REF: https://github.com/scottming/nvim/blob/master/lua/user/lsp/code_actions.lua
    -- local elixir_dbg = {
    --   method = nls.methods.CODE_ACTION,
    --   filetypes = { "elixir" },
    --   generator = { fn = custom_ca.add_or_remove_dbg },
    -- }

    local erb_format = {
      method = nls.methods.FORMATTING,
      filetypes = { "eruby" },
      generator = nls.formatter({
        command = "erb-format",
        args = { "--stdin-filename", "$FILENAME" },
        to_stdin = true,
      }),
    }
    nls.register(erb_format)

    nls.setup({
      debounce = 150,
      root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", ".git"),
      sources = {
        format.trim_whitespace.with({ filetypes = { "*" } }),
        format.prettierd.with({
          filetypes = {
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "css",
            "scss",
            "sass",
            "html",
            "svg",
            "json",
            "jsonc",
            "graphql",
            "markdown",
          },
          condition = function() return mega.executable("prettierd") end,
        }),
        format.fixjson.with({ filetypes = { "jsonc", "json" } }),
        -- format.cbfmt:with({
        --   condition = function() return mega.executable("cbfmt") end,
        -- }),
        format.stylua.with({
          condition = function()
            return mega.executable("stylua")
            -- and not vim.tbl_isempty(vim.fs.find({ ".stylua.toml", "stylua.toml" }, {
            --   path = vim.fn.expand("%:p"),
            --   upward = true,
            -- }))
          end,
        }),
        -- format.mix.with({
        --   extra_filetypes = { "elixir", "eelixir", "heex", "surface" },
        --   args = { "format", "-" },
        --   extra_args = function(_params)
        --     -- local version_output = vim.fn.system("elixir -v")
        --     -- local minor_version = vim.fn.matchlist(version_output, "Elixir \\d.\\(\\d\\+\\)")[2]
        --
        --     local extra_args = { "--stdin-filename", "$FILENAME" }
        --
        --     -- tells the formatter the filename for the code passed to it via stdin.
        --     -- This allows formatting heex files correctly. Only available for
        --     -- Elixir >= 1.14
        --     -- if tonumber(minor_version, 10) >= 14 then extra_args = { "--stdin-filename", "$FILENAME" } end
        --
        --     return extra_args
        --   end,
        -- }),
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
        -- format.beautysh.with({
        --   extra_args = { "-i", "2" },
        --   condition = function() return mega.executable("beautysh") end,
        -- }),
        -- format.shellharden,
        format.elm_format,
        format.jq,
        -- format.markdownlint,
        format.shfmt.with({
          extra_args = { "-i", "2", "-ci" }, -- suggested: { "-i", "2", "-ci" } or { "-ci", "-s", "-bn", "-i", "2" }
          filetypes = { "sh", "bash", "zsh" },
        }),
        diag.flake8.with({
          extra_args = function(_) return { "--max-line-lenth", vim.opt_local.colorcolumn:get()[1] or "88" } end,
        }),
        diag.shellcheck.with({
          filetypes = { "sh", "bash" },
        }),
        -- elixir_dbg,
        diag.zsh.with({
          filetypes = { "zsh" },
        }),
        -- diag.editorconfig_checker.with({ command = "editorconfig-checker" }),
        -- diag.credo.with({
        --   -- run credo in strict mode even if strict mode is not enabled in
        --   -- .credo.exs
        --   extra_args = { "--strict" },
        --   -- only register credo source if it is installed in the current project
        --   condition = function(_utils)
        --     local cmd = { "/usr/local/bin/rg", ":credo", "mix.exs" }
        --     local credo_installed = ("" == vim.fn.system(cmd))
        --     return not credo_installed
        --   end,
        -- }),
      },
    })

    nls.enabled = true
    local toggle_null_formatters = function()
      nls.enabled = not nls.enabled
      mega.lsp.null_formatters_enabled = not nls.enabled
      nls.toggle({ methods = nls.methods.FORMATTING })
    end

    mega.command("ToggleAutoFormat", toggle_null_formatters)
  end,
  -- },
  -- {
  --   "jay-babu/mason-null-ls.nvim",
  --   event = { "BufReadPre", "BufNewFile" },
  --   dependencies = { "mason.nvim", "null-ls.nvim" },
  --   config = function()
  --     require("mason-null-ls").setup({
  --       automatic_setup = true,
  --       automatic_installation = {},
  --       ensure_installed = { "buf", "goimports", "golangci_lint", "stylua", "prettier" },
  --     })
  --     require("null-ls").setup()
  --     require("mason-null-ls").setup_handlers()
  --   end,
  -- },
}

function M.has_formatter(ft)
  local sources = require("null-ls.sources")
  local available = sources.get_available(ft, "NULL_LS_FORMATTING")
  return #available > 0
end

return M
