local M = {}

M["textDocument/documentHighlight"] = function(_, _, result, _)
  if not result then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.util.buf_clear_references(bufnr)
  vim.lsp.util.buf_highlight_references(bufnr, result)
end

M["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end
  if not vim.api.nvim_buf_get_option(bufnr, "modified") then
    local view = vim.fn.winsaveview()
    vim.lsp.util.apply_text_edits(result, bufnr)
    vim.fn.winrestview(view)
    if bufnr == vim.api.nvim_get_current_buf() then
      vim.cmd [[noautocmd :update]]
    -- vim.cmd [[GitGutter]]
    end
  end
end

M["textDocument/publishDiagnostics"] = function(...)
  vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
      underline = true,
      virtual_text = false,
      -- virtual_text = {
      --   spacing = 4,
      --   prefix = vim.api.nvim_get_var("virtual_text_symbol"),
      -- },
      signs = true,
      update_in_insert = false
    }
  )(...)
  pcall(vim.lsp.diagnostic.set_loclist, {open_loclist = false})
end

return M
