local prettier = { "prettierd", "prettier" }
local timeout_ms = 2000
local lsp_fallback = "always"
local keys = {}

if vim.g.formatter == "conform" then
  keys = {
    {
      "=",
      function()
        vim.notify("formatting with conform")
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "Format buffer (async)",
    },
    {
      "<leader>F",
      function()
        vim.notify("formatting with conform")
        require("conform").format({ async = false, lsp_fallback = true })
      end,
      desc = "Format buffer (sync)",
    },
  }
end

return {
  "stevearc/conform.nvim",
  -- cond = vim.g.formatter == "conform",
  event = { "BufReadPre", "BufNewFile", "BufWritePre" },
  cmd = "ConformInfo",
  keys = keys,
  opts = {
    formatters_by_ft = {
      ["*"] = { "trim_whitespace", "trim_newlines" },
      bash = { "shfmt", "beautysh", "shellharden" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      css = { prettier },
      go = { "goimports", "gofmt", "gofumpt" },
      graphql = { prettier },
      html = { prettier },
      javascript = { prettier },
      javascriptreact = { prettier },
      json = { prettier, "fixjson" },
      jsonc = { prettier, "fixjson" },
      lua = { "stylua" },
      markdown = { prettier },
      python = {
        formatters = { "isort", "black" },
        -- Run formatters one after another instead of stopping at the first success
        run_all_formatters = true,
      },
      rust = { "rustfmt" },
      sh = { "shfmt", "beautysh", "shellharden" },
      toml = { "taplo" },
      typescript = { prettier },
      typescriptreact = { prettier },
      yaml = { prettier },
      zig = { "zigfmt" },
      zsh = { "shfmt" },
    },
    log_level = vim.log.levels.DEBUG,
    format_on_save = function(bufnr)
      -- local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
      -- if async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      -- dd("format on save")
      return { timeout_ms = timeout_ms, lsp_fallback = lsp_fallback, filter = mega.lsp.formatting_filter }
    end,
    format_after_save = function(bufnr)
      -- local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
      -- if not async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      -- dd("format after save")
      return { timeout_ms = timeout_ms, lsp_fallback = lsp_fallback, filter = mega.lsp.formatting_filter }
    end,
    user_async_format_filetypes = {
      python = true,
    },
  },
  config = function(_, opts)
    if vim.g.formatter ~= "conform" then return end

    if vim.g.started_by_firenvim then
      opts.format_on_save = false
      opts.format_after_save = false
    end
    vim.g.async_format_filetypes = opts.user_async_format_filetypes
    require("conform").setup(opts)

    mega.command("ToggleAutoFormat", function()
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      if vim.g.disable_autoformat then
        vim.notify("Disabled auto-formatting.", L.WARN)
      else
        vim.notify("Enabled auto-formatting.", L.INFO)
        require("conform").format({
          timeout_ms = timeout_ms,
          lsp_fallback = lsp_fallback,
          filter = mega.lsp.formatting_filter,
          bufnr = 0,
        })
      end
    end)
  end,
}
