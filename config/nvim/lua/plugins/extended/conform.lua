local SETTINGS = require("mega.settings")
local U = require("mega.utils")

local prettier = { "dprint", "prettierd", "prettier" }
local shfmt = { "shfmt" } -- shellharden
local timeout_ms = 1500
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
  cond = vim.g.formatter == "conform",
  event = { "BufReadPre", "BufNewFile", "BufWritePre", "BufWritePost" },
  cmd = "ConformInfo",
  keys = keys,
  opts = {
    formatters_by_ft = {
      ["*"] = { "trim_whitespace", "trim_newlines" },
      bash = { shfmt },
      c = { "clang_format" },
      cpp = { "clang_format" },
      -- css = { "prettierd" },
      go = { "goimports", "gofmt", "gofumpt" },
      graphql = { prettier },
      html = { prettier },
      javascript = { prettier },
      javascriptreact = { prettier },
      json = { prettier, "fixjson" },
      jsonc = { prettier, "fixjson" },
      lua = { "stylua" },
      ["markdown"] = { prettier },
      ["markdown.mdx"] = { prettier },
      python = { "isort", "black" },
      rust = { "rustfmt" },
      -- sass = { "prettierd" },
      -- scss = { "prettierd" },
      sh = { shfmt },
      toml = { "taplo" },
      typescript = { prettier },
      typescriptreact = { prettier },
      yaml = { prettier },
      zig = { "zigfmt" },
      zsh = { shfmt },
    },
    formatters = {
      shfmt = {
        prepend_args = { "-i", "2", "-ci" },
      },
      beautysh = {
        prepend_args = { "-i", "2" },
      },
      dprint = {
        condition = function(ctx) return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1] end,
      },
    },
    log_level = vim.log.levels.DEBUG,
    format_on_save = function(bufnr)
      -- local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
      -- if async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      -- dd("format on save")
      return { timeout_ms = timeout_ms, lsp_fallback = lsp_fallback, filter = U.lsp.formatting_filter }
    end,
    -- format_after_save = function(bufnr)
    --   -- local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
    --   -- if not async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
    --   if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
    --   -- dd("format after save")
    --   return { timeout_ms = timeout_ms, lsp_fallback = lsp_fallback, filter = U.lsp.formatting_filter }
    -- end,
    user_async_format_filetypes = {
      python = true,
    },
  },
  init = function() vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" end,
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
      opts.format_after_save = false
    end
    vim.g.async_format_filetypes = opts.user_async_format_filetypes
    require("conform").setup(opts)

    vim.api.nvim_create_user_command("ToggleAutoFormat", function()
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      if vim.g.disable_autoformat then
        vim.notify("Disabled auto-formatting.", L.WARN)
      else
        vim.notify("Enabled auto-formatting.", L.INFO)
        -- NOTE: probably better to NOT run formatter (elixir related formatting is wonky)
        -- require("conform").format({
        --   timeout_ms = timeout_ms,
        --   lsp_fallback = lsp_fallback,
        --   filter = U.lsp.formatting_filter,
        --   bufnr = 0,
        -- })
      end
    end, {})
  end,
}
