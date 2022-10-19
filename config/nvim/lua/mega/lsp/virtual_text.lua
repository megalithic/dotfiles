-- HT: @williamboman
-- https://github.com/williamboman/nvim-config/blob/main/plugin/diagnostics/virtual_text.lua

-- TODO:
-- 1. pull from vim.diagnostic.config for virtual text settings;
-- 2. disable "native" virtual_text settings after we grab the config;
-- 3. update to his latest code things.

---@class Diagnostic
---@field bufnr integer?
---@field lnum integer
---@field end_lnum integer
---@field col integer
---@field end_col integer
---@field severity integer
---@field message string
---@field source string
---@field code string
---@field user_data any
---@field namespace integer : Not part of core diagnostics API.

---@param base_name string
local function make_highlight_map(base_name)
  local result = {}
  for level, name in ipairs(vim.diagnostic.severity) do
    name = name:sub(1, 1) .. name:sub(2):lower()
    result[level] = "Diagnostic" .. base_name .. name
  end

  return result
end

-- TODO rename?
local virtual_text_highlight_map = make_highlight_map("VirtualText")
local line_highlight_map = make_highlight_map("Line")

---@param diagnostics Diagnostic[]
---@param namespace integer
local function prefix_source(diagnostics, namespace)
  return vim.tbl_map(function(diagnostic)
    diagnostic.namespace = namespace
    if not diagnostic.source then return diagnostic end

    local copy = vim.deepcopy(diagnostic)
    copy.message = string.format("%s: %s", diagnostic.source, diagnostic.message)
    return copy
  end, diagnostics)
end

---@param bufnr integer?
local function get_bufnr(bufnr)
  if not bufnr or bufnr == 0 then return vim.api.nvim_get_current_buf() end
  return bufnr
end

---@param diagnostics Diagnostic[]
local function diagnostic_lines(diagnostics)
  if not diagnostics then return {} end

  local diagnostics_by_line = {}
  for _, diagnostic in ipairs(diagnostics) do
    local line_diagnostics = diagnostics_by_line[diagnostic.lnum]
    if not line_diagnostics then
      line_diagnostics = {}
      diagnostics_by_line[diagnostic.lnum] = line_diagnostics
    end
    table.insert(line_diagnostics, diagnostic)
  end
  return diagnostics_by_line
end

---TODO: this won't play nicely with anticonceal text
---@param bufnr integer
---@param line integer
---@param virt_texts_length integer
local function get_virt_text_pos(bufnr, line, virt_texts_length)
  -- TODO error handling
  local line_contents = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1] or ""
  return ((vim.o.columns - #line_contents) >= virt_texts_length) and "right_align" or "eol"
end

---@type table<integer, table<integer, Diagnostic[]>>
local diagnostics_per_namespace = {}

local namespaces = {}

local function create_namespace()
  local namespace = vim.api.nvim_create_namespace("")
  namespaces[#namespaces + 1] = namespace
  diagnostics_per_namespace[namespace] = {}
  return namespace
end

---@param bufnr integer
---@param trigger_ns integer?
local function redraw_extmarks(bufnr, trigger_ns)
  ---@type Diagnostic[]
  local merged_diagnostics = {}

  for _, ns_diagnostics in pairs(diagnostics_per_namespace) do
    if ns_diagnostics[bufnr] then vim.list_extend(merged_diagnostics, ns_diagnostics[bufnr]) end
  end
  local diagnostic_indicator = "■ "
  local suffix = "    "

  for line, diagnostics in pairs(diagnostic_lines(merged_diagnostics)) do
    ---@type Diagnostic
    local primary_diagnostic
    ---@type table<integer, table[]>
    local virt_texts_by_ns = {}
    local virt_texts_length = 0

    for i = 1, #diagnostics do
      local diagnostic = diagnostics[i]
      if diagnostic.namespace ~= trigger_ns then
        vim.api.nvim_buf_clear_namespace(bufnr, diagnostic.namespace, line, line + 1)
      end

      if not virt_texts_by_ns[diagnostic.namespace] then virt_texts_by_ns[diagnostic.namespace] = {} end
      table.insert(virt_texts_by_ns[diagnostic.namespace], {
        fmt("%s ", mega.icons.lsp[string.lower(vim.diagnostic.severity[diagnostic.severity])]),
        virtual_text_highlight_map[diagnostic.severity],
      })
      virt_texts_length = virt_texts_length + #diagnostic_indicator

      if not primary_diagnostic or primary_diagnostic.severity > diagnostic.severity then
        primary_diagnostic = diagnostic
      end
    end

    if primary_diagnostic.message and primary_diagnostic.severity == vim.diagnostic.severity.ERROR then
      local virt_texts = virt_texts_by_ns[primary_diagnostic.namespace]
      local message = primary_diagnostic.message .. suffix
      table.insert(virt_texts, {
        message,
        virtual_text_highlight_map[primary_diagnostic.severity],
      })
      virt_texts_length = virt_texts_length + #message

      vim.api.nvim_buf_set_extmark(bufnr, primary_diagnostic.namespace, line, 0, {
        hl_mode = "combine",
        priority = 100,
        line_hl_group = line_highlight_map[primary_diagnostic.severity],
        -- cursorline_hl_group = TODO lighter variants?,
        virt_text = virt_texts,
        virt_text_pos = get_virt_text_pos(bufnr, line, virt_texts_length),
      })
      virt_texts_by_ns[primary_diagnostic.namespace] = nil
    end

    for ns, virt_texts in pairs(virt_texts_by_ns) do
      if primary_diagnostic.severity == vim.diagnostic.severity.ERROR then
        vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
          hl_mode = "combine",
          priority = 100,
          line_hl_group = line_highlight_map[primary_diagnostic.severity],
          -- cursorline_hl_group = TODO lighter variants?,
          virt_text = virt_texts,
          virt_text_pos = get_virt_text_pos(bufnr, line, virt_texts_length),
        })
      end
    end
  end
end

---@param namespace integer
---@param bufnr integer?
---@param diagnostics Diagnostic[]
---@param opts table?
local function show(namespace, bufnr, diagnostics, opts)
  bufnr = get_bufnr(bufnr)
  opts = opts or {}

  local ns = vim.diagnostic.get_namespace(namespace)
  if not ns.user_data.right_align_ns then ns.user_data.right_align_ns = create_namespace() end
  diagnostics_per_namespace[ns.user_data.right_align_ns][bufnr] =
    prefix_source(diagnostics, ns.user_data.right_align_ns)
  redraw_extmarks(bufnr, ns.user_data.right_align_ns)
end

---@param namespace integer
---@param bufnr integer?
local function hide(namespace, bufnr)
  bufnr = get_bufnr(bufnr)
  local ns = vim.diagnostic.get_namespace(namespace)
  if ns.user_data.right_align_ns then
    vim.api.nvim_buf_clear_namespace(bufnr, ns.user_data.right_align_ns, 0, -1)
    diagnostics_per_namespace[ns.user_data.right_align_ns][bufnr] = nil
  end
end

mega.augroup("LspVirtualText", {
  {
    event = { "VimResized", "TextChangedI", "WinScrolled" },
    command = function(args) redraw_extmarks(args.buf) end,
  },
})

vim.diagnostic.handlers.right_align = { show = show, hide = hide }
