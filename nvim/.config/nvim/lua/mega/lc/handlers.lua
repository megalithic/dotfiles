local M = {}

M["textDocument/documentHighlight"] = function(_, _, result, _)
  if not result then
    return
  end
  local bufnr = vim.api.nvim_get_current_buf()
  vim.lsp.util.buf_clear_references(bufnr)
  vim.lsp.util.buf_highlight_references(bufnr, result)
end

-- Handle formatting in a smarter way
-- If the buffer has been edited before formatting has completed, do not try to
-- apply the changes, by Lukas Reineke
M["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end

  -- If the buffer hasn't been modified before the formatting has finished,
  -- update the buffer
  if not vim.api.nvim_buf_get_option(bufnr, "modified") then
    local view = vim.fn.winsaveview()
    vim.lsp.util.apply_text_edits(result, bufnr)
    vim.fn.winrestview(view)
    if bufnr == vim.api.nvim_get_current_buf() then
      vim.api.nvim_command("noautocmd :update")

      -- Trigger post-formatting autocommand which can be used to refresh gitgutter
      vim.api.nvim_command("silent doautocmd <nomodeline> User FormatterPost")
    end
  end
end

local function location_handler(_, method, result)
  if result == nil or vim.tbl_isempty(result) then
    local _ = log.info() and log.info(method, "No location found")
    return nil
  end

  -- textDocument/definition can return Location or Location[]
  -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition

  if vim.tbl_islist(result) then
    vim.lsp.util.jump_to_location(result[1])

    if #result > 1 then
      vim.lsp.util.set_qflist(vim.lsp.util.locations_to_items(result))
      vim.api.nvim_command("copen")
      vim.api.nvim_command("wincmd p")
    end
  else
    vim.lsp.util.jump_to_location(result)
  end
end
M["textDocument/documentLink"] = location_handler

-- M["textDocument/formatting"] = function(err, _, result, _, bufnr)
--   if err ~= nil or result == nil then
--     return
--   end
--   if not vim.api.nvim_buf_get_option(bufnr, "modified") then
--     local view = vim.fn.winsaveview()
--     vim.lsp.util.apply_text_edits(result, bufnr)
--     vim.fn.winrestview(view)
--     if bufnr == vim.api.nvim_get_current_buf() then
--       vim.cmd [[noautocmd :update]]
--     -- vim.cmd [[GitGutter]]
--     end
--   end
-- end

M["textDocument/publishDiagnostics"] = function(...)
  vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
      underline = true,
      virtual_text = false,
      -- virtual_text = {
      --   spacing = 4,
      --   prefix = "●"
      -- },
      signs = true,
      update_in_insert = false,
      severity_sort = true
    }
  )(...)
  pcall(vim.lsp.diagnostic.set_loclist, {open_loclist = false})
end

return M
