local M = {}
local lsp, api, fn = vim.lsp, vim.api, vim.fn
local fmt = string.format
local C = require("colors")

local severity_map = {
  "DiagnosticError",
  "DiagnosticWarn",
  "DiagnosticInfo",
  "DiagnosticHint",
}

local icon_map = {
  " ✗ ",
  "  ",
  "  ",
  "  ",
}

M.diagnostic_types = {
  { "Error", icon = C.icons.lsp.error },
  { "Warn", icon = C.icons.lsp.warn },
  { "Info", icon = C.icons.lsp.info },
  { "Hint", icon = C.icons.lsp.hint },
}

local function source_string(source)
  return fmt("  [%s]", source)
end

M.wrap_lines = function(input, width)
  local output = {}
  for _, line in ipairs(input) do
    line = line:gsub("\r", "")
    while #line > width + 2 do
      local trimmed_line = string.sub(line, 1, width)
      local index = trimmed_line:reverse():find(" ")
      if index == nil or index > #trimmed_line / 2 then
        break
      end
      table.insert(output, string.sub(line, 1, width - index))
      line = vim.o.showbreak .. string.sub(line, width - index + 2, #line)
    end
    table.insert(output, line)
  end

  return output
end

function M.close_preview_autocmd(events, winnr)
  if #events > 0 then
    api.nvim_command(
      "autocmd "
        .. table.concat(events, ",")
        .. " <buffer> ++once lua pcall(vim.api.nvim_win_close, "
        .. winnr
        .. ", true)"
    )
  end
end

M.line_diagnostics = function()
  local width = 70
  local bufnr, lnum = unpack(fn.getcurpos())
  local diagnostics = lsp.diagnostic.get_line_diagnostics(bufnr, lnum - 1, {})
  if vim.tbl_isempty(diagnostics) then
    return
  end

  local max_severity = vim.diagnostic.severity.HINT
  for _, d in ipairs(diagnostics) do
    -- Equality is "less than" based on how the severities are encoded
    if d.severity < max_severity then
      max_severity = d.severity
    end
  end

  local lines = {}

  for _, diagnostic in ipairs(diagnostics) do
    table.insert(
      lines,
      icon_map[diagnostic.severity] .. " " .. diagnostic.message:gsub("\n", " ") .. source_string(diagnostic.source)
    )
  end

  local floating_bufnr = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, false, lines)
  api.nvim_buf_set_option(floating_bufnr, "filetype", "diagnosticpopup")

  for i, diagnostic in ipairs(diagnostics) do
    local message_length = #lines[i] - #source_string(diagnostic.source)
    api.nvim_buf_add_highlight(floating_bufnr, -1, severity_map[diagnostic.severity], i - 1, 0, message_length)
    api.nvim_buf_add_highlight(floating_bufnr, -1, "DiagnosticSource", i - 1, message_length, -1)
  end

  local border_color = ({
    [vim.diagnostic.severity.HINT] = "DiagnosticHintBorder",
    [vim.diagnostic.severity.INFO] = "DiagnosticInfoBorder",
    [vim.diagnostic.severity.WARN] = "DiagnosticWarnBorder",
    [vim.diagnostic.severity.ERROR] = "DiagnosticErrorBorder",
  })[max_severity]

  local winnr = api.nvim_open_win(floating_bufnr, false, {
    relative = "cursor",
    width = width,
    height = #M.wrap_lines(lines, width - 1),
    row = 1,
    col = 1,
    style = "minimal",
    border = mega.get_border(border_color),
  })

  M.close_preview_autocmd(
    { "CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "WinScrolled", "BufWritePost", "InsertCharPre" },
    winnr
  )
end

---Override diagnostics signs helper to only show the single most relevant sign
---@see: http://reddit.com/r/neovim/comments/mvhfw7/can_built_in_lsp_diagnostics_be_limited_to_show_a
---@param diagnostics table[]
---@param bufnr number
---@return table[]
M.filter_diagnostics = function(diagnostics, bufnr)
  if not diagnostics then
    return {}
  end
  -- Work out max severity diagnostic per line
  local max_severity_per_line = {}
  for _, d in pairs(diagnostics) do
    local lnum = d.lnum
    if max_severity_per_line[lnum] then
      local current_d = max_severity_per_line[lnum]
      if d.severity < current_d.severity then
        max_severity_per_line[lnum] = d
      end
    else
      max_severity_per_line[lnum] = d
    end
  end
  -- map to list
  local filtered_diagnostics = {}
  for _, v in pairs(max_severity_per_line) do
    table.insert(filtered_diagnostics, v)
  end
  return filtered_diagnostics
end

function M.setup()
  fn.sign_define(vim.tbl_map(function(t)
    local hl = "DiagnosticSign" .. t[1]
    return {
      name = hl,
      text = t.icon,
      texthl = hl,
      numhl = hl,
      -- numhl = fmt("%sLine", hl),
      -- linehl = fmt("%sLine", hl),
      linehl = hl,
    }
  end, M.diagnostic_types))

  --- This overwrites the diagnostic show/set_signs function to replace it with a custom function
  --- that restricts nvim's diagnostic signs to only the single most severe one per line
  -- local ns = api.nvim_create_namespace("lsp-diagnostics")
  -- local show = vim.diagnostic.show
  -- local function display_signs(bufnr)
  --   -- Get all diagnostics from the current buffer
  --   local diagnostics = vim.diagnostic.get(bufnr)
  --   local filtered = M.filter_diagnostics(diagnostics, bufnr)
  --   show(ns, bufnr, filtered, {
  --     virtual_text = false,
  --     underline = false,
  --     signs = true,
  --   })
  -- end

  -- -- Monkey-patch vim.diagnostic.show() with our own impl to filter sign severity
  -- function vim.diagnostic.show(namespace, bufnr, ...)
  --   show(namespace, bufnr, ...)
  --   display_signs(bufnr)
  -- end

  -- Monkey-patch vim.diagnostic.open_float() with our own impl..
  -- REF: https://neovim.discourse.group/t/lsp-diagnostics-how-and-where-to-retrieve-severity-level-to-customise-border-color/1679
  vim.diagnostic.open_float = (function(orig)
    return function(bufnr, opts)
      local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
      opts = opts or {}
      -- A more robust solution would check the "scope" value in `opts` to
      -- determine where to get diagnostics from, but if you're only using
      -- this for your own purposes you can make it as simple as you like
      local diagnostics = vim.diagnostic.get(opts.bufnr or 0, { lnum = lnum })
      local max_severity = vim.diagnostic.severity.HINT
      for _, d in ipairs(diagnostics) do
        -- Equality is "less than" based on how the severities are encoded
        if d.severity < max_severity then
          max_severity = d.severity
        end
      end
      local border_color = ({
        [vim.diagnostic.severity.HINT] = "DiagnosticHint",
        [vim.diagnostic.severity.INFO] = "DiagnosticInfo",
        [vim.diagnostic.severity.WARN] = "DiagnosticWarn",
        [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      })[max_severity]
      opts.border = mega.get_border(border_color)
      orig(bufnr, opts)
    end
  end)(vim.diagnostic.open_float)

  vim.diagnostic.config({
    underline = true,
    virtual_text = false,
    signs = true, -- {severity_limit = "Warning"},
    update_in_insert = false,
    severity_sort = true,
    float = {
      show_header = true,
      source = "if_many", -- or "always"
      border = mega.get_border(),
      focusable = false,
      severity_sort = true,
    },
  })
end

return M
