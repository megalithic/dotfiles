local M = {}

local api = vim.api
local lsp = vim.lsp
local fn = vim.fn

local function fzf_symbol_handler(_, _, result, _, bufnr)
  if not result or vim.tbl_isempty(result) then
    return
  end

  local items = lsp.util.symbols_to_items(result, bufnr)
  require("mega.lc.fzf").send(items, "Symbols")
end

M["textDocument/documentSymbol"] = fzf_symbol_handler

M["workspace/symbol"] = fzf_symbol_handler

local function fzf_location_handler(_, _, result)
  if result == nil or vim.tbl_isempty(result) then
    return nil
  end

  if vim.tbl_islist(result) then
    lsp.util.jump_to_location(result[1])

    if #result > 1 then
      local items = lsp.util.locations_to_items(result)
      require("mega.lc.fzf").send(items, "Locations")
    end
  else
    lsp.util.jump_to_location(result)
  end
end

M["textDocument/declaration"] = fzf_location_handler
M["textDocument/definition"] = fzf_location_handler
M["textDocument/typeDefinition"] = fzf_location_handler
M["textDocument/implementation"] = fzf_location_handler

M["textDocument/references"] = function(_, _, result)
  if not result then
    return
  end

  local items = lsp.util.locations_to_items(result)
  require("mega.lc.fzf").send(items, "References")
end

M["textDocument/hover"] = function(_, method, result)
  lsp.util.focusable_float(
    method,
    function()
      if not (result and result.contents) then
        return
      end
      local markdown_lines = lsp.util.convert_input_to_markdown_lines(result.contents)
      markdown_lines = lsp.util.trim_empty_lines(markdown_lines)
      if vim.tbl_isempty(markdown_lines) then
        return
      end
      local bufnr, winnr = lsp.util.fancy_floating_markdown(markdown_lines, {pad_left = 1, pad_right = 1})
      api.nvim_buf_set_option(bufnr, "readonly", true)
      api.nvim_buf_set_option(bufnr, "modifiable", false)
      api.nvim_win_set_option(winnr, "relativenumber", false)
      lsp.util.close_preview_autocmd({"CursorMoved", "BufHidden", "InsertCharPre"}, winnr)
      return bufnr, winnr
    end
  )
end

M["textDocument/documentHighlight"] = function(_, _, result, _)
  if not result then
    return
  end
  local bufnr = api.nvim_get_current_buf()
  lsp.util.buf_clear_references(bufnr)
  lsp.util.buf_highlight_references(bufnr, result)
end

M["textDocument/formatting"] = function(err, _, result, _, bufnr)
  if err ~= nil or result == nil then
    return
  end
  if not api.nvim_buf_get_option(bufnr, "modified") then
    local view = fn.winsaveview()
    lsp.util.apply_text_edits(result, bufnr)
    fn.winrestview(view)
    api.nvim_command("noautocmd :update")
  -- api.nvim_command("GitGutter")
  end
end

M["textDocument/publishDiagnostics"] = function(...)
  lsp.with(
    lsp.diagnostic.on_publish_diagnostics,
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
