-- Utilities
local lsp_util = require('vim.lsp.util')
local lsp_proto = require('vim.lsp.protocol')

local _config = {}

local function init(_, config)
  _config = config
end

local function extract_symbols(items, _result)
  local result = _result or {}
  if items == nil then return result end
  for _, item in ipairs(items) do
    local kind = lsp_proto.SymbolKind[item.kind] or 'Unknown'
    local sym_range = nil
    if item.location then -- Item is a SymbolInformation
      sym_range = item.location.range
    elseif item.range then -- Item is a DocumentSymbol
      sym_range = item.range
    end

    if sym_range then
      sym_range.start.line = sym_range.start.line + 1
      sym_range['end'].line = sym_range['end'].line + 1
    end

    table.insert(result, {
      filename = item.location and vim.uri_to_fname(item.location.uri) or nil,
      range = sym_range,
      kind = kind,
      text = item.name,
      raw_item = item
    })

    if item.children then
      extract_symbols(item.children, result)
    end
  end

  return result
end

local function in_range(pos, range)
  local line = pos[1]
  local char = pos[2]
  if line < range.start.line or line > range['end'].line then return false end
  if
    line == range.start.line and char < range.start.character or
    line == range['end'].line and char > range['end'].character
  then
    return false
  end

  return true
end

local function filter(list, test)
  local result = {}
  for i, v in ipairs(list) do
    if test(i, v) then
      table.insert(result, v)
    end
  end

  return result
end

-- Find current function context
local function current_function_callback(_, _, result, _, _)
  vim.b.lsp_current_function = ''
  local function_symbols = filter(extract_symbols(result),
    function(_, v)
      return v.kind == 'Class' or v.kind == 'Function' or v.kind == 'Method'
    end)

  if not function_symbols or #function_symbols == 0 then
    vim.api.nvim_command('doautocmd User LspStatusUpdate')
    return
  end

  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  for i = #function_symbols, 1, -1 do
    local sym = function_symbols[i]
    if
      (sym.range and in_range(cursor_pos, sym.range))
      or (_config.select_symbol and _config.select_symbol(cursor_pos, sym.raw_item))
    then
      local fn_name = sym.text
      fn_name = sym.kind .. ': ' .. fn_name
      vim.b.lsp_current_function = fn_name
      vim.api.nvim_command('doautocmd User LspStatusUpdate')
      return
    end
  end
end

local function update_current_function()
  local params = { textDocument = lsp_util.make_text_document_params() }
  vim.lsp.buf_request(0, 'textDocument/documentSymbol', params, current_function_callback)
end

local M = {
  update = update_current_function,
  _init = init
}

M.on_attach = function(client)
  if client.resolved_capabilities.document_symbol then
    vim.api.nvim_command(
      'au CursorHold <buffer> lua require"lsp_status".update()'
    )
    vim.api.nvim_command('augroup END')
  end
end

return M
