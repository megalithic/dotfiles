---@param bufnr integer
---@param ... string
---@return string
local function first(bufnr, ...)
  local conform = require("conform")
  for i = 1, select("#", ...) do
    local formatter = select(i, ...)
    if conform.get_formatter_info(formatter, bufnr).available then
      return formatter
    end
  end
  return select(1, ...)
end

local js_formats = {}
for _, ft in ipairs({
  "javascript",
  "javascript.jsx",
  "javascriptreact",
  "typescript",
  "typescript.tsx",
  "typescriptreact",
}) do
  js_formats[ft] = {
    "deno_fmt",
    "biome",
    "prettier",
    stop_after_first = true,
  }
end

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      log_level = vim.log.levels.DEBUG,
      formatters = {
        injected = {
          options = {
            ignore_errors = true,
          },
        },
        -- Look into dprint as my default formatter instead
        prettier = {
          cwd = function()
            return vim.uv.cwd()
          end,
          prepend_args = function(_, ctx)
            return {
              "--config-precedence",
              "prefer-file",
              "--use-tabs",
              "--single-quote",
              "--no-bracket-spacing",
              "--prose-wrap",
              "always",
              "--arrow-parens",
              "always",
              "--trailing-comma",
              "all",
              "--no-semi",
              "--end-of-line",
              "lf",
              "--print-width",
              vim.bo[ctx.buf].textwidth <= 80 and 80 or vim.bo[ctx.buf].textwidth,
            }
          end,
        },
        statix = {
          command = "statix",
          args = { "fix", "--stdin" },
          stdin = true,
        },
      },
      formatters_by_ft = vim.tbl_extend("force", {
        ["*"] = { "trim_whitespace", "trim_newlines" },
        json = {
          "deno_fmt",
          "biome",
          "prettier",
          "jq",
          stop_after_first = true,
        },
        jsonc = {
          "deno_fmt",
          "biome",
          "prettier",
          stop_after_first = true,
        },
        markdown = function(bufnr)
          return { first(bufnr, "prettier", "deno_fmt"), "injected" }
        end,
        ["markdown.mdx"] = { "prettier", "injected" },
        mdx = { "prettier", "injected" },
        html = { "prettier", "injected" },
        -- yaml = { "prettier", "injected" },
        css = { "biome", "prettier", stop_after_first = true },
        vue = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        graphql = { "prettier" },
        lua = { "stylua" },
        -- Ideally I'd use the LSP for this, but I'd lose organize imports and the autofix
        -- https://github.com/astral-sh/ruff/issues/12778#issuecomment-2279374570
        python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
        go = {
          -- this will run gofmt too
          -- I'm using this instead of LSP format because it cleans up imports too
          "goimports",
        },
        nix = { "alejandra", "statix" },
        -- not 100% supported but does the job as long as I'm writing POSIX and not fancy zsh
        zsh = { "shfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        toml = { "taplo" },
      }, js_formats),
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

        -- Disable autoformat for files in a certain path
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") then
          return
        end

        return { timeout_ms = 500, lsp_format = "fallback" }
      end,
    },
    init = function()
      -- Use conform for gq.
      vim.bo.formatexpr = "v:lua.require'conform'.formatexpr()"

      -- Define a command to run async formatting
      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil

        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end

        require("conform").format({
          async = true,
          lsp_format = "fallback",
          range = range,
        })
      end, { range = true })

      Command("ToggleAutoFormat", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        if vim.g.disable_autoformat then
          vim.notify("Disabled auto-formatting.", L.WARN)
        else
          vim.notify("Enabled auto-formatting.", L.INFO)
        end
      end, {})

      -- vim.api.nvim_create_user_command("ToggleAutoFormat", function(args)
      --   -- FormatToggle! will toggle formatting globally
      --   if args.bang then
      --     if vim.g.disable_autoformat == true then
      --       vim.g.disable_autoformat = nil
      --     else
      --       vim.g.disable_autoformat = true
      --     end
      --
      --     vim.notify(
      --       string.format("%s auto-formatting (global)", vim.g.disable_autoformat and "Disabled" or "Enabled"),
      --       L.WARN
      --     )
      --   else
      --     if vim.b.disable_autoformat == true then
      --       vim.b.disable_autoformat = nil
      --     else
      --       vim.b.disable_autoformat = true
      --     end
      --     vim.notify(
      --       string.format("%s auto-formatting (local)", vim.b.disable_autoformat and "Disabled" or "Enabled"),
      --       L.WARN
      --     )
      --   end
      -- end, {
      --   desc = "Toggle autoformat-on-save",
      --   bang = true,
      -- })
    end,
  },
}
-- -- REF:
-- -- - https://github.com/ahmedelgabri/dotfiles/blob/5ceb4f3220980f95bc674b0785c920fbd9fc45ed/config/nvim/lua/plugins/formatter.lua#L75
-- vim.api.nvim_create_autocmd("BufWritePre", {
--   pattern = "*",
--   callback = function(args)
--     require("conform").format({ bufnr = args.buf })
--   end,
-- })
--
-- Command("ToggleAutoFormat", function()
--   vim.g.disable_autoformat = not vim.g.disable_autoformat
--   if vim.g.disable_autoformat then
--     vim.notify("Disabled auto-formatting.", L.WARN)
--   else
--     vim.notify("Enabled auto-formatting.", L.INFO)
--   end
-- end, {})
--
-- return {
--   "stevearc/conform.nvim",
--   keys = {
--     {
--       "<Leader>F",
--       function()
--         require("conform").format({
--           async = true,
--           lsp_format = "fallback",
--           timeout_ms = 5000,
--         })
--         vim.notify(
--           "Formatted " .. (vim.api.nvim_get_mode().mode == "n" and "buffer" or "selection"),
--           vim.log.levels.INFO,
--           { id = "toggle_conform", title = "Conform" }
--         )
--       end,
--       mode = { "n", "x" },
--       desc = "Format buffer or selection",
--     },
--   },
--   init = function()
--     vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
--   end,
--   config = function()
--     local opts = {
--       formatters = {
--         ["eslint_d"] = {
--           command = "eslint_d",
--           args = { "--fix-to-stdout", "--stdin", "--stdin-filename", "$FILENAME" },
--           cwd = require("conform.util").root_file({ "package.json" }),
--         },
--         prettierd = {
--           require_cwd = true,
--         },
--         ["pg_format"] = {
--           command = "pg_format",
--           -- args = { "--inplace", "--config", ".pg_format.conf" },
--           args = {
--             "--comma-start",
--             "--comma-break",
--             "--spaces",
--             "2",
--             "--keyword-case",
--             "1",
--             "--placeholder",
--             '":: "',
--             "--format-type",
--             "--inplace",
--           },
--           cwd = require("conform.util").root_file({ ".pg_format.conf" }),
--         },
--         stylua = {
--           command = "stylua",
--           args = {
--             "--search-parent-directories",
--             -- "--respect-ignores",
--             "--stdin-filepath",
--             "$FILENAME",
--             "-",
--           },
--         },
--         beautysh = {
--           prepend_args = { "-i", "2" },
--         },
--         dprint = {
--           condition = function(ctx)
--             return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
--           end,
--         },
--         mix = {
--           cwd = function(self, ctx)
--             (require("conform.util").root_file({ "mix.exs" }))(self, ctx)
--           end,
--         },
--         statix = {
--           command = "statix",
--           args = { "fix", "--stdin" },
--           stdin = true,
--         },
--       },
--       formatters_by_ft = {
--         ["*"] = { "trim_whitespace", "trim_newlines" },
--         lua = { "stylua" },
--         luau = { "stylua" },
--         json = { "fixjson", "prettierd", "prettier", "dprint" },
--         jsonc = { "fixjson", "prettierd", "prettier", "dprint" },
--         json5 = { "fixjson", "prettierd", "prettier", "dprint" },
--         javascript = { "prettierd", "prettier", "dprint" },
--         javascriptreact = { "prettierd", "prettier", "dprint" },
--         bash = { "shfmt" }, -- shellharden
--         c = { "clang_format" },
--         cpp = { "clang_format" },
--         css = { "prettierd", "prettier" },
--         go = { "goimports", "gofmt", "gofumpt" },
--         graphql = { "prettierd", "prettier", "dprint" },
--         html = { "prettierd", "prettier", "dprint" },
--         markdown = { "prettierd", "prettier", "dprint" },
--         ["markdown.mdx"] = { "prettierd", "prettier", "dprint" },
--         nix = { "nixpkgs_fmt", "statix" },
--         -- python = { "isort", "black" },
--         python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
--         rust = { "rustfmt" },
--         sass = { "prettierd", "prettier" },
--         scss = { "prettierd", "prettier" },
--         sh = { "shfmt" }, -- shellharden
--         sql = { "pg_format", "sqlfluff" },
--         terraform = { "tofu_fmt" },
--         toml = { "taplo" },
--         typescript = { "prettierd", "prettier", "dprint" },
--         typescriptreact = { "prettierd", "prettier", "dprint" },
--         yaml = { "prettierd", "prettier", "dprint" },
--         zig = { "zigfmt" },
--         zsh = { "shfmt" }, -- shellhardenhfmt,
--         ["_"] = { "trim_whitespace", "trim_newlines", lsp_format = "last" },
--       },
--       default_format_opts = {
--         lsp_format = "fallback",
--       },
--     }
--     if vim.g.started_by_firenvim then
--       opts.format_on_save = false
--       opts.format_after_save = false
--     end
--
--     require("conform.formatters.stylua").env = {
--       XDG_CONFIG_HOME = vim.fn.stdpath("config"),
--     }
--     require("conform.formatters.injected").options.ignore_errors = true
--     local util = require("conform.util")
--     local clang_format = require("conform.formatters.clang_format")
--     local deno_fmt = require("conform.formatters.deno_fmt")
--     local ruff = require("conform.formatters.ruff_format")
--     local shfmt = require("conform.formatters.shfmt")
--     util.add_formatter_args(clang_format, {
--       "--style=file",
--     })
--     util.add_formatter_args(deno_fmt, { "--single-quote", "--prose-wrap", "preserve" }, { append = true })
--     util.add_formatter_args(ruff, { "--config", "format.quote-style = 'single'" }, { append = true })
--     util.add_formatter_args(shfmt, {
--       "--indent",
--       "2",
--       -- Case Indentation
--       "-ci",
--       -- Space after Redirect carets (`foo > bar`)
--       "-sr",
--     })
--
--     require("conform").setup(opts)
--   end,
-- }
