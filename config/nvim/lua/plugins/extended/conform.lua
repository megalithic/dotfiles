-- REF:
-- - https://github.com/ahmedelgabri/dotfiles/blob/5ceb4f3220980f95bc674b0785c920fbd9fc45ed/config/nvim/lua/plugins/formatter.lua#L75
local SETTINGS = require("config.options")

local prettier = { "prettierd", "prettier", "dprint" }
local shfmt = { "shfmt" } -- shellharden
local timeout_ms = 1500
local lsp_fallback = "always"
local keys = {}

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args) require("conform").format({ bufnr = args.buf }) end,
})

Command("ToggleAutoFormat", function()
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

return {
  "stevearc/conform.nvim",
  version = "*",

  init = function() vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" end,
  config = function(_, opts)
    if vim.g.started_by_firenvim then
      opts.format_on_save = false
      opts.format_after_save = false
    end

    require("conform").setup({
      formatters = {
        injected = { options = { ignore_errors = true } },
        ["eslint_d"] = {
          command = "eslint_d",
          args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
          cwd = require("conform.util").root_file({ "package.json" }),
        },
        prettierd = {
          require_cwd = true,
        },
        ["pg_format"] = {
          command = "pg_format",
          -- args = { "--inplace", "--config", ".pg_format.conf" },
          args = {
            "--comma-start",
            "--comma-break",
            "--spaces",
            "2",
            "--keyword-case",
            "1",
            "--placeholder",
            "\":: \"",
            "--format-type",
            "--inplace",
          },
          cwd = require("conform.util").root_file({ ".pg_format.conf" }),
        },
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        stylua = {
          command = "stylua",
          args = {
            "--search-parent-directories",
            -- "--respect-ignores",
            "--stdin-filepath",
            "$FILENAME",
            "-",
          },
        },
        beautysh = {
          prepend_args = { "-i", "2" },
        },
        deno_fmt = {
          prepend_args = { "--prose-wrap", "preserve" },
        },
        dprint = {
          condition = function(ctx) return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1] end,
        },
        mix = {
          cwd = function(self, ctx) (require("conform.util").root_file({ "mix.exs" }))(self, ctx) end,
        },
        statix = {
          command = "statix",
          args = { "fix", "--stdin" },
          stdin = true,
        },
      },
      formatters_by_ft = {
        ["*"] = { "injected" },
        -- ["*"] = { "trim_whitespace", "trim_newlines" },
        lua = { "stylua" },
        -- elixir = { "mix", timeout_ms = 1000 },
        -- eelixir = { "mix" },
        -- heex = { "mix" },
        json = { "fixjson", "prettierd", "prettier", "dprint" },
        jsonc = { "fixjson", "prettierd", "prettier", "dprint" },
        json5 = { "fixjson", "prettierd", "prettier", "dprint" },
        javascript = { "prettierd", "prettier", "dprint" },
        javascriptreact = { "prettierd", "prettier", "dprint" },
        bash = { "shfmt" }, -- shellharden
        c = { "clang_format" },
        cpp = { "clang_format" },
        -- css = { "prettierd" },
        go = { "goimports", "gofmt", "gofumpt" },
        graphql = { "prettierd", "prettier", "dprint" },
        html = { "prettierd", "prettier", "dprint" },
        markdown = { "prettierd", "prettier", "dprint" },
        ["markdown.mdx"] = { "prettierd", "prettier", "dprint" },
        nix = { "nixpkgs_fmt", "statix" },
        python = { "isort", "black" },
        rust = { "rustfmt" },
        -- sass = { "prettierd" },
        -- scss = { "prettierd" },
        sh = { "shfmt" }, -- shellharden
        sql = { "pg_format", "sqlfluff" },
        terraform = { "tofu_fmt" },
        toml = { "taplo" },
        typescript = { "prettierd", "prettier", "dprint" },
        typescriptreact = { "prettierd", "prettier", "dprint" },
        yaml = { "prettierd", "prettier", "dprint" },
        zig = { "zigfmt" },
        zsh = { "shfmt" }, -- shellhardenhfmt,
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end

        return {
          timeout_ms = timeout_ms,
          lsp_fallback = lsp_fallback,
          filter = function(client, exclusions)
            local client_name = type(client) == "table" and client.name or client
            exclusions = exclusions or SETTINGS.formatter_exclusions
            if not exclusions then return false end

            return not vim.tbl_contains(exclusions, client_name)
          end,
        }
      end,
    })
  end,
}

-- if vim.g.formatter == "conform" then
--   keys = {
--     {
--       "=",
--       function()
--         vim.notify("formatting with conform")
--         require("conform").format({ async = true, lsp_fallback = true })
--       end,
--       mode = "",
--       desc = "Format buffer (async)",
--     },
--     {
--       "<leader>F",
--       function()
--         vim.notify("formatting with conform")
--         require("conform").format({ async = false, lsp_fallback = true })
--       end,
--       desc = "Format buffer (sync)",
--     },
--   }
-- end

-- ---@param bufnr integer
-- ---@param ... string
-- ---@return string
-- local function first(bufnr, ...)
--   local conform = require("conform")
--   for i = 1, select("#", ...) do
--     local formatter = select(i, ...)
--     if conform.get_formatter_info(formatter, bufnr).available then
--       return formatter
--     end
--   end
--   return select(1, ...)
-- end

-- require("conform").setup({
--   formatters_by_ft = {
--     markdown = function(bufnr)
--       return { first(bufnr, "prettierd", "prettier"), "injected" }
--     end,
--   },
-- })

-- return {
--   "stevearc/conform.nvim",
--   cond = vim.g.formatter == "conform",
--   event = { "BufReadPre", "BufNewFile", "BufWritePre", "BufWritePost", "LspAttach" },
--   cmd = "ConformInfo",
--   keys = keys,
--   opts = {
--     -- stop_after_first = true,
--     formatters_by_ft = {
--       -- ["*"] = { "trim_whitespace", "trim_newlines" },
--       bash = shfmt,
--       c = { "clang_format" },
--       cpp = { "clang_format" },
--       -- css = { "prettierd" },
--       -- elixir = { "mix", timeout_ms = 2000 },
--       go = { "goimports", "gofmt", "gofumpt" },
--       graphql = prettier,
--       html = prettier,
--       javascript = prettier,
--       javascriptreact = prettier,
--       json = { "fixjson", "prettierd", "prettier", "dprint" },
--       jsonc = { "fixjson", "prettierd", "prettier", "dprint" },
--       lua = { "stylua" },
--       markdown = prettier,
--       ["markdown.mdx"] = prettier,
--       nix = { "nixpkgs_fmt", "statix" },
--       python = { "isort", "black" },
--       rust = { "rustfmt" },
--       -- sass = { "prettierd" },
--       -- scss = { "prettierd" },
--       sh = shfmt,
--       sql = { "pg_format", "sqlfluff" },
--       terraform = { "tofu_fmt" },
--       toml = { "taplo" },
--       typescript = prettier,
--       typescriptreact = prettier,
--       yaml = prettier,
--       zig = { "zigfmt" },
--       zsh = shfmt,
--     },
--       statix = {
--         command = "statix",
--         args = { "fix", "--stdin" },
--         stdin = true,
--       },
--     },
--     log_level = vim.log.levels.DEBUG,
--     format_on_save = function(bufnr)
--       -- local async_format = vim.g.async_format_filetypes[vim.bo[bufnr].filetype]
--       -- if async_format or vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
--       if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
--       -- dd("format on save")
--       return {
--         timeout_ms = timeout_ms,
--         lsp_fallback = lsp_fallback,
--         filter = function(client, exclusions)
--           local client_name = type(client) == "table" and client.name or client
--           exclusions = exclusions or SETTINGS.formatter_exclusions
--           if not exclusions then return false end

--           return not vim.tbl_contains(exclusions, client_name)
--         end,
--       }
--     end,
--     user_async_format_filetypes = {
--       python = true,
--     },
--   },
--   init = function() vim.o.formatexpr = "v:lua.require'conform'.formatexpr()" end,
--   config = function(_, opts)
--     if vim.g.started_by_firenvim then
--       opts.format_on_save = false
--       opts.format_after_save = false
--     end
--     vim.g.async_format_filetypes = opts.user_async_format_filetypes

--     require("conform").setup(opts)
--   end,
-- }
