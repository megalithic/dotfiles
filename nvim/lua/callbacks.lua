local M = {}

local api = vim.api
local lsp = vim.lsp

local function fzf_symbol_callback(_, _, result, _, bufnr)
  if not result or vim.tbl_isempty(result) then
    return
  end

  local items = lsp.util.symbols_to_items(result, bufnr)
  require('fzf').send(items, 'Symbols')
end

M['textDocument/documentSymbol'] = fzf_symbol_callback

M['workspace/symbol'] = fzf_symbol_callback

local function fzf_location_callback(_, _, result)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end

  if vim.tbl_islist(result) then
    lsp.util.jump_to_location(result[1])

    if #result > 1 then
      local items = lsp.util.locations_to_items(result)
      require('fzf').send(items, 'Locations')
    end
  else
    lsp.util.jump_to_location(result)
  end
end

M['textDocument/declaration'] = fzf_location_callback
M['textDocument/definition'] = fzf_location_callback
M['textDocument/typeDefinition'] = fzf_location_callback
M['textDocument/implementation'] = fzf_location_callback

M['textDocument/references'] = function(_, _, result)
  if not result then
    return
  end
  local items = lsp.util.locations_to_items(result)
  require('fzf').send(items, 'References')
end

M['textDocument/hover'] = function(_, method, result)
  lsp.util.focusable_float(method, function()
    if not (result and result.contents) then
      return
    end
    local markdown_lines = lsp.util.convert_input_to_markdown_lines(result.contents)
    markdown_lines = lsp.util.trim_empty_lines(markdown_lines)
    if vim.tbl_isempty(markdown_lines) then
      return
    end
    local bufnr, winnr = lsp.util.fancy_floating_markdown(markdown_lines,
                                                          {pad_left = 1; pad_right = 1})
    api.nvim_buf_set_option(bufnr, 'readonly', true)
    api.nvim_buf_set_option(bufnr, 'modifiable', false)
    api.nvim_win_set_option(winnr, 'relativenumber', false)
    lsp.util.close_preview_autocmd({'CursorMoved'; 'BufHidden'; 'InsertCharPre'}, winnr)
    return bufnr, winnr
  end)
end

M['textDocument/documentHighlight'] = function(_, _, result, _)
  if not result then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  lsp.util.buf_clear_references(bufnr)
  lsp.util.buf_highlight_references(bufnr, result)
end

-- M['textDocument/publishDiagnostics'] = function(err, method, result, client_id)
--   require('buf_diagnostic').publishDiagnostics(err, method, result, client_id)
-- end

return M
