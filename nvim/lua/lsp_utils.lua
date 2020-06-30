M = {}

function M.preview_location(location, context)
  -- location may be LocationLink or Location (more useful for the former)
  context = context or 5
  local uri = location.targetUri or location.uri
  if uri == nil then
    return
  end
  local bufnr = vim.uri_to_bufnr(uri)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end
  local range = location.targetRange or location.range
  local contents =
  vim.api.nvim_buf_get_lines(bufnr, range.start.line - context, range["end"].line + 1 + context, false)
  local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return vim.lsp.util.open_floating_preview(contents, filetype)
end

M.switch_header_source = function()
  vim.lsp.buf_request(
    0,
    "textDocument/switchSourceHeader",
    vim.lsp.util.make_text_document_params(),
    function(err, _, result, _, _)
      if err then
        print(err)
      else
        vim.cmd("e " .. vim.uri_to_fname(result))
      end
    end
    )
end

function M.preview_location_callback(_, method, result, context)
  context = context or 5
  if result == nil or vim.tbl_isempty(result) then
    vim.lsp.log.info(method, "No location found")
    return nil
  end
  if vim.tbl_islist(result) then
    M.preview_location(result[1])
  else
    M.preview_location(result)
  end
end

function M.peek_definition(context)
  context = context or 5
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0, "textDocument/definition", params, M.preview_location_callback, context)
end

return M
