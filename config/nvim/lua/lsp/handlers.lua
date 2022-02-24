local M = {}
local lsp = vim.lsp

function M.setup()
  -- hover
  -- NOTE: the hover handler returns the bufnr,winnr so can be used for mappings
  local opts = {
    border = mega.get_border(),
    max_width = math.max(math.floor(vim.o.columns * 0.7), 100),
    max_height = math.max(math.floor(vim.o.lines * 0.3), 30),
    focusable = false,
    silent = true,
    severity_sort = true,
    close_events = {
      "CursorMoved",
      "BufHidden",
      "InsertCharPre",
      "BufLeave",
      "InsertEnter",
      "FocusLost",
    },
  }
  -- lsp.handlers["$/progress"] = require("lsp.progress").lsp_progress_notification
  lsp.handlers["textDocument/hover"] = lsp.with(vim.lsp.handlers.hover, opts)
  lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, opts)
  lsp.handlers["textDocument/publishDiagnostics"] = lsp.with(lsp.diagnostic.on_publish_diagnostics, opts)
  lsp.handlers["window/showMessage"] = function(_, result, ctx)
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    local lvl = ({ "ERROR", "WARN", "INFO", "DEBUG" })[result.type]
    vim.notify(result.message, lvl, {
      title = "LSP | " .. client.name,
      timeout = 10000,
      keep = function()
        return lvl == "ERROR" or lvl == "WARN"
      end,
    })
  end
  -- REF: https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/lsp/handlers.lua#L1-L17
  -- lsp.handlers["textDocument/formatting"] = function(err, result, ctx)
  --   if err ~= nil or result == nil then
  --     return
  --   end
  --   if api.nvim_buf_get_var(ctx.bufnr, "init_changedtick") == api.nvim_buf_get_var(ctx.bufnr, "changedtick") then
  --     local view = fn.winsaveview()
  --     lsp.util.apply_text_edits(result, ctx.bufnr)
  --     fn.winrestview(view)
  --     if ctx.bufnr == api.nvim_get_current_buf() then
  --       vim.b.saving_format = true
  --       vcmd([[update]])
  --       vim.b.saving_format = false
  --     end
  --   end
  -- end
end

return M
