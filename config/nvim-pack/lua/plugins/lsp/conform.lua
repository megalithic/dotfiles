-- lua/plugins/lsp/conform.lua
-- Formatting with conform.nvim
-- Language-specific formatters come from lua/langs/*.lua via require("langs")

return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = { "ConformInfo" },
  -- NOTE: <leader>lf defined in lua/lsp/keymaps.lua (uses conform with LSP fallback)
  opts = function()
    local langs = require("langs")

    -- Base formatters (can be overridden by lang configs)
    local base_formatters = {
      toml = { "taplo" },
      zsh = { "shfmt" },
    }

    -- Merge lang formatters with base (lang formatters take precedence)
    local formatters_by_ft = vim.tbl_deep_extend("force", base_formatters, langs.formatters())

    return {
      formatters_by_ft = formatters_by_ft,

      -- Format on save
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end

        -- Skip certain paths
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match("/node_modules/") then
          return
        end

        return { timeout_ms = 500, lsp_fallback = true }
      end,

      -- Formatter options
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2", "-ci" },
        },
        prettier = {
          prepend_args = {
            "--single-quote",
            "--trailing-comma", "all",
            "--no-semi",
          },
        },
      },
    }
  end,

  init = function()
    -- Use conform for gq
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    -- Toggle auto-format on save (global or per-buffer)
    vim.api.nvim_create_user_command("ToggleAutoFormat", function(args)
      if args.bang then
        -- Buffer-local toggle
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        vim.notify(
          "Auto-format (buffer): " .. (vim.b.disable_autoformat and "OFF" or "ON"),
          vim.log.levels.INFO
        )
      else
        -- Global toggle
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify(
          "Auto-format (global): " .. (vim.g.disable_autoformat and "OFF" or "ON"),
          vim.log.levels.INFO
        )
      end
    end, {
      bang = true,
      desc = "Toggle auto-format on save (! for buffer-local)",
    })
  end,
}
