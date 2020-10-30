local M = {}

local api = vim.api
local lsp = vim.lsp
local vcmd = vim.cmd
local vfn = vim.fn

function M.show_line_diagnostics()
  local indent = "  "
  local lines = {"Diagnostics:", ""}
  local line_diagnostics = lsp.util.get_line_diagnostics()
  if vim.tbl_isempty(line_diagnostics) then
    return
  end

  for _, diagnostic in pairs(line_diagnostics) do
    local message_lines = vim.split(diagnostic.message, "\n", true)
    table.insert(
      lines,
      string.format("- [%s] %s", diagnostic.source, message_lines[1])
    )
    for j = 2, #message_lines do
      table.insert(lines, indent .. message_lines[j])
    end
  end
  return lsp.util.open_floating_preview(lines, "plaintext")
end

local items_from_diagnostics = function(bufnr, diagnostics)
  local fname = vfn.bufname(bufnr)
  local items = {}
  for _, diagnostic in ipairs(diagnostics) do
    print("item_from_diagnostics -> " .. vim.inspect(diagnostic))

    local pos = diagnostic.range.start
    table.insert(
      items,
      {
        filename = fname,
        lnum = pos.line + 1,
        col = pos.character + 1,
        text = diagnostic.message
      }
    )
  end
  return items
end

local render_diagnostics = function(items)
  lsp.util.set_qflist(items)
  if vim.tbl_isempty(items) then
    vcmd("cclose")
  else
    vcmd("copen")
    vcmd("wincmd p")
    vcmd("cc")
  end
end

function M.list_file_diagnostics()
  local bufnr = api.nvim_get_current_buf()
  local diagnostics = lsp.util.diagnostics_by_buf[bufnr]
  if not diagnostics then
    return
  end

  local items = items_from_diagnostics(bufnr, diagnostics)
  render_diagnostics(items)
end

function M.list_workspace_diagnostics()
  local items_list = {}
  for bufnr, diagnostics in pairs(lsp.util.diagnostics_by_buf) do
    local d_items = items_from_diagnostics(bufnr, diagnostics)
    for _, item in ipairs(d_items) do
      table.insert(items_list, item)
    end
  end
  render_diagnostics(items_list)
end

return M
