local M = {}

M["textDocument/hover"] = function(_, method, result)
  vim.lsp.util.focusable_float(
    method,
    function()
      if not (result and result.contents) then
        return
      end
      local markdown_lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = vim.lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      local bufnr, winnr = vim.lsp.util.fancy_floating_markdown(markdown_lines, {pad_left = 1, pad_right = 1})
      vim.api.nvim_buf_set_option(bufnr, "readonly", true)
      vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
      vim.api.nvim_win_set_option(winnr, "relativenumber", false)
      vim.lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre"}, winnr)
      return bufnr, winnr
    end
  )
end

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
