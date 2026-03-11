-- lua/plugins/lsp/init.lua
-- LSP-related lazy.nvim plugin specs only
-- Core LSP setup is in lua/lsp/init.lua

return {
  -- Schemastore for JSON/YAML schemas
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },

  {
    "smjonas/inc-rename.nvim",
    opts = {},
    inti = function()
      vim.keymap.set(
        { "v", "n" },
        "gn",
        function() return ":IncRename " .. vim.fn.expand("<cword>") end,
        { expr = true }
      )
    end,
  },

  -- Inline diagnostics
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      local icons = require("icons")
      require("tiny-inline-diagnostic").setup({
        signs = {
          left = "",
          right = "",
          diag = "", -- No prefix circle - we add icon via format
          arrow = "    ",
          up_arrow = "    ",
          vertical = " │",
          vertical_end = " └",
        },
        hi = {
          error = "DiagnosticError",
          warn = "DiagnosticWarn",
          info = "DiagnosticInfo",
          hint = "DiagnosticHint",
        },
        options = {
          show_source = { enabled = true },
          show_all_diags_on_cursorline = true,
          overflow = { mode = "wrap" }, -- Wrap when going off edge
          format = function(diagnostic)
            local sev_icons = {
              [vim.diagnostic.severity.ERROR] = icons.lsp.error,
              [vim.diagnostic.severity.WARN] = icons.lsp.warn,
              [vim.diagnostic.severity.INFO] = icons.lsp.info,
              [vim.diagnostic.severity.HINT] = icons.lsp.hint,
            }
            local icon = sev_icons[diagnostic.severity] or ""
            return icon .. " " .. diagnostic.message
          end,
        },
      })
    end,
  },

  -- Better code actions
  {
    "rachartier/tiny-code-action.nvim",
    event = "LspAttach",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
