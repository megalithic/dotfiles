-- HT: @williamboman
-- https://github.com/williamboman/nvim-config/blob/main/plugin/diagnostics/virtual_text.lua

-- TODO:
-- 1. pull from vim.diagnostic.config for virtual text settings;
-- 2. disable "native" virtual_text settings after we grab the config;

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
---@param virt_texts table[]
local function get_virt_text_pos(bufnr, line, virt_texts)
  local virt_text_length = 0
  for _, virt_text in ipairs(virt_texts) do
    virt_text_length = virt_text_length + #virt_text[1]
  end
  local line_contents = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, true)[1]
  return ((vim.o.columns - #line_contents) >= virt_text_length) and "right_align" or "eol"
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
---@param trigger_ns integer
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

      if not primary_diagnostic or primary_diagnostic.severity > diagnostic.severity then
        primary_diagnostic = diagnostic
      end
    end

    if primary_diagnostic.message then
      table.insert(virt_texts_by_ns[primary_diagnostic.namespace], {
        primary_diagnostic.message .. suffix,
        virtual_text_highlight_map[primary_diagnostic.severity],
      })
    end

    for ns, virt_texts in pairs(virt_texts_by_ns) do
      if primary_diagnostic.severity == vim.diagnostic.severity.ERROR then
        vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
          hl_mode = "combine",
          priority = 100,
          line_hl_group = line_highlight_map[primary_diagnostic.severity],
          -- cursorline_hl_group = TODO lighter variants?,
          virt_text = virt_texts,
          -- TODO virt text pos calculation only applies to one ns
          virt_text_pos = get_virt_text_pos(bufnr, line, virt_texts),
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

local unused = "here"

local augroup = vim.api.nvim_create_augroup("RightAlign", {})
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = augroup,
  callback = function(args)
    local lineno = vim.fn.line(".") - 1
    for _, ns in ipairs(namespaces) do
      local extmarks = vim.api.nvim_buf_get_extmarks(args.buf, ns, { lineno, 0 }, { lineno, 0 }, { details = true })
      for _, extmark_tuple in ipairs(extmarks) do
        local extmark = extmark_tuple[4]
        vim.api.nvim_buf_set_extmark(
          args.buf,
          ns,
          extmark_tuple[2],
          extmark_tuple[3],
          vim.tbl_extend("force", extmark, {
            id = extmark_tuple[1],
            virt_text_pos = get_virt_text_pos(args.buf, lineno, extmark.virt_text),
          })
        )
      end
    end
  end,
})

vim.diagnostic.handlers.right_align = { show = show, hide = hide }
