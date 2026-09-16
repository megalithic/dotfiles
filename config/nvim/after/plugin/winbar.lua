if not Plugin_enabled() then return end
-- after/plugin/winbar.lua
-- Winbar with file path and LSP symbol breadcrumbs
-- Reference: https://github.com/nikbrunner/dots/blob/main/common/.config/nvim/plugin/winbar.lua

-- Filetypes to ignore (they have their own winbar or shouldn't have one)
local ignore_filetypes = {
  "minifiles",
  "oil",
  "neo-tree",
  "NvimTree",
  "Trouble",
  "trouble",
  "qf",
  "help",
  "man",
  "toggleterm",
  "terminal",
  "megaterm",
  "lazy",
  "mason",
  "snacks_picker",
  "TelescopePrompt",
  "alpha",
  "dashboard",
  "starter",
  "gitcommit",
  "fugitive",
  "DiffviewFiles",
}

local ignore_buftypes = {
  "terminal",
  "nofile",
  "prompt",
  "quickfix",
}

---Check if position is within range
---@param range {start: {line: integer, character: integer}, ['end']: {line: integer, character: integer}}
---@param line integer
---@param char integer
---@return boolean
local function range_contains_pos(range, line, char)
  local start = range.start
  local stop = range["end"]

  if line < start.line or line > stop.line then return false end
  if line == start.line and char < start.character then return false end
  if line == stop.line and char > stop.character then return false end

  return true
end

---Recursively find symbol path at cursor position
---@param symbol_list table[]|nil
---@param line integer
---@param char integer
---@param path string[]
---@return boolean
local function find_symbol_path(symbol_list, line, char, path)
  if not symbol_list or #symbol_list == 0 then return false end

  for _, symbol in ipairs(symbol_list) do
    if symbol.range and range_contains_pos(symbol.range, line, char) then
      table.insert(path, symbol.name)
      find_symbol_path(symbol.children, line, char, path)
      return true
    end
  end

  return false
end

---Escape string for use in statusline/winbar (% -> %%)
---@param str string
---@return string
local function escape_statusline(str) return str:gsub("%%", "%%%%") end

---Get relative file path with highlights
---@param bufnr integer
---@return string
local function get_relative_path(bufnr)
  local file_path = vim.fn.bufname(bufnr)
  if not file_path or file_path == "" then return "%#WinBarPath#[No Name]%*" end

  -- Get path relative to LSP root or cwd
  local relative_path
  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients > 0 and clients[1].root_dir then
    local root_dir = clients[1].root_dir
    if vim.startswith(vim.fn.fnamemodify(file_path, ":p"), root_dir) then
      relative_path = vim.fn.fnamemodify(file_path, ":p"):sub(#root_dir + 2)
    else
      relative_path = vim.fn.fnamemodify(file_path, ":~:.")
    end
  else
    relative_path = vim.fn.fnamemodify(file_path, ":~:.")
  end

  local parts = vim.split(relative_path, "/", { plain = true })
  local highlighted_parts = {}

  for i, part in ipairs(parts) do
    local escaped = escape_statusline(part)
    if i == #parts then
      -- Filename gets different highlight
      table.insert(highlighted_parts, "%#WinBarFilename#" .. escaped .. "%*")
    else
      -- Directory parts
      table.insert(highlighted_parts, "%#WinBarPath#" .. escaped .. "%*")
    end
  end

  return table.concat(highlighted_parts, "%#WinBarSeparator#/%*")
end

---LSP callback for document symbols
---@param err any
---@param symbols table[]|nil
---@param ctx {bufnr: integer}
local function lsp_callback(err, symbols, ctx)
  -- Check if window still exists
  local winid = vim.fn.bufwinid(ctx.bufnr)
  if winid == -1 then return end

  local path_part = get_relative_path(ctx.bufnr)

  if err or not symbols then
    pcall(vim.api.nvim_set_option_value, "winbar", path_part, { win = winid })
    return
  end

  local pos = vim.api.nvim_win_get_cursor(winid)
  local cursor_line = pos[1] - 1
  local cursor_char = pos[2]

  local symbol_breadcrumbs = {}
  find_symbol_path(symbols, cursor_line, cursor_char, symbol_breadcrumbs)

  local winbar
  if #symbol_breadcrumbs > 0 then
    local symbol_parts = {}
    for _, symbol in ipairs(symbol_breadcrumbs) do
      local escaped = escape_statusline(symbol)
      table.insert(symbol_parts, "%#WinBarSymbol#" .. escaped .. "%*")
    end
    winbar = path_part .. " %#WinBarSeparator#›%* " .. table.concat(symbol_parts, " %#WinBarSeparator#›%* ")
  else
    winbar = path_part
  end

  pcall(vim.api.nvim_set_option_value, "winbar", winbar, { win = winid })
end

---Update winbar for current window
local function update_winbar()
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()

  -- Skip special buffers
  local ft = vim.bo[bufnr].filetype
  local bt = vim.bo[bufnr].buftype

  if vim.list_contains(ignore_filetypes, ft) or vim.list_contains(ignore_buftypes, bt) then
    pcall(vim.api.nvim_set_option_value, "winbar", "", { win = winid })
    return
  end

  -- Skip unnamed buffers
  local file_path = vim.fn.bufname(bufnr)
  if not file_path or file_path == "" then
    pcall(vim.api.nvim_set_option_value, "winbar", "", { win = winid })
    return
  end

  local path_part = get_relative_path(bufnr)

  -- For narrow windows, just show path
  local win_width = vim.api.nvim_win_get_width(winid)
  if win_width < 80 then
    pcall(vim.api.nvim_set_option_value, "winbar", path_part, { win = winid })
    return
  end

  -- Check for LSP document symbol support
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local has_document_symbol = false

  for _, client in ipairs(clients) do
    if client.server_capabilities.documentSymbolProvider then
      has_document_symbol = true
      break
    end
  end

  if not has_document_symbol then
    pcall(vim.api.nvim_set_option_value, "winbar", path_part, { win = winid })
    return
  end

  -- Request document symbols from LSP
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }

  vim.lsp.buf_request(bufnr, "textDocument/documentSymbol", params, lsp_callback)
end

-- Setup highlights
local function setup_highlights()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  local comment = vim.api.nvim_get_hl(0, { name = "Comment" })
  local title = vim.api.nvim_get_hl(0, { name = "Title" })

  vim.api.nvim_set_hl(0, "WinBarPath", { fg = comment.fg, bg = normal.bg })
  vim.api.nvim_set_hl(0, "WinBarFilename", { fg = title.fg, bg = normal.bg, bold = true })
  vim.api.nvim_set_hl(0, "WinBarSeparator", { fg = comment.fg, bg = normal.bg })
  vim.api.nvim_set_hl(0, "WinBarSymbol", { fg = normal.fg, bg = normal.bg })
end

-- Debounce timer for cursor movement (reuse single timer)
local update_timer = vim.uv.new_timer()

local function debounced_update()
  -- Skip during fast scrolling
  if vim.g._fast_scrolling then return end

  update_timer:stop()
  update_timer:start(50, 0, vim.schedule_wrap(update_winbar))
end

-- Autocmds
local augroup = vim.api.nvim_create_augroup("mega.winbar", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = setup_highlights,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "LspAttach" }, {
  group = augroup,
  callback = update_winbar,
})

vim.api.nvim_create_autocmd("CursorMoved", {
  group = augroup,
  callback = debounced_update,
})

-- Clean up timer on exit
vim.api.nvim_create_autocmd("VimLeave", {
  group = augroup,
  callback = function()
    if update_timer then
      update_timer:stop()
      update_timer:close()
      update_timer = nil
    end
  end,
})

-- Initial setup
setup_highlights()
