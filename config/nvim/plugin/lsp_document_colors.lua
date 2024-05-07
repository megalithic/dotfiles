-- Credits: contains some code snippets from https://github.com/norcalli/nvim-colorizer.lua
local bit = require("bit")
local U = require("mega.utils")

local M = {}

---@type table<string,true>
M.hl = {}

local function lsp_color_to_hex(color)
  local function to256(c) return math.floor(c * color.alpha * 255) end
  return bit.tohex(bit.bor(bit.lshift(to256(color.red), 16), bit.lshift(to256(color.green), 8), to256(color.blue)), 6)
end

-- Determine whether to use black or white text
-- Ref: https://stackoverflow.com/a/1855903/837964
-- https://stackoverflow.com/questions/596216/formula-to-determine-brightness-of-rgb-color
local function color_is_bright(r, g, b)
  -- Counting the perceptive luminance - human eye favors green color
  local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
  if luminance > 0.5 then
    return true -- Bright colors, black font
  else
    return false -- Dark colors, white font
  end
end

local NAMESPACE = vim.api.nvim_create_namespace("lsp_documentColor")
local HIGHLIGHT_NAME_PREFIX = "lsp_documentColor"
local HIGHLIGHT_MODE_NAMES = { bg = "mb", fg = "mf", extmark = "me" }

local HIGHLIGHT_CACHE = {}

--- Make a deterministic name for a highlight given these attributes
local function make_highlight_name(rgb, mode) return table.concat({ HIGHLIGHT_NAME_PREFIX, HIGHLIGHT_MODE_NAMES[mode], string.gsub(rgb, "#", "") }, "_") end

---@param hex string
---@param mode "fg"|"bg"|"extmark"
---@param default_fg? string
local function set_hl(hex, mode, default_fg)
  local cache_key = table.concat({ HIGHLIGHT_MODE_NAMES[mode], hex }, "_")
  local hl_name = HIGHLIGHT_CACHE[cache_key]
  if hl_name then return hl_name end

  hl_name = make_highlight_name(hex, mode)

  if mode == "fg" then
    vim.api.nvim_set_hl(0, hl_name, { fg = "#" .. hex })
  elseif mode == "bg" then
    vim.api.nvim_set_hl(0, hl_name, { bg = "#" .. hex, fg = default_fg })
  elseif mode == "extmark" then
    vim.api.nvim_set_hl(0, hl_name, { bg = hex })
  end

  HIGHLIGHT_CACHE[cache_key] = hl_name

  return hl_name
end

local function create_highlight(rgb_hex, options)
  local mode = options.mode or "bg"
  local cache_key = table.concat({ HIGHLIGHT_MODE_NAMES[mode], rgb_hex }, "_")
  local hl_name = HIGHLIGHT_CACHE[cache_key]

  -- Existing highlight
  if hl_name then return hl_name end

  -- Create the highlight
  hl_name = make_highlight_name(rgb_hex, mode)
  if mode == "fg" then
    set_hl(rgb_hex, mode)
    -- vim.api.nvim_set_hl(0, highlight_name, { fg = rgb_hex })
  else
    local r, g, b = rgb_hex:sub(1, 2), rgb_hex:sub(3, 4), rgb_hex:sub(5, 6)
    r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
    local fg_color
    if color_is_bright(r, g, b) then
      fg_color = "#000000"
    else
      fg_color = "#ffffff"
    end

    set_hl(rgb_hex, mode, fg_color)
    -- vim.api.nvim_set_hl(0, highlight_name, { fg = fg_color, bg = rgb_hex })
  end

  HIGHLIGHT_CACHE[cache_key] = hl_name

  return hl_name
end

local ATTACHED_BUFFERS = {}

local function update_extmark(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local params = { textDocument = vim.lsp.util.make_text_document_params(bufnr) }
  vim.lsp.buf_request(bufnr, "textDocument/documentColor", params, function(err, colors)
    if err then return end
    for _, c in ipairs(colors) do
      local color = c.color
      color.red = math.floor(color.red * 255 + 0.5)
      color.green = math.floor(color.green * 255 + 0.5)
      color.blue = math.floor(color.blue * 255 + 0.5)
      local hex = string.format("#%02x%02x%02x", color.red, color.green, color.blue)

      local offset_encoding = vim.lsp.util._get_offset_encoding(bufnr)
      local start_row = c.range.start.line
      local start_col = vim.lsp.util._get_line_byte_from_position(bufnr, c.range.start, offset_encoding)
      local end_row = c.range["end"].line
      local end_col = vim.lsp.util._get_line_byte_from_position(bufnr, c.range["end"], offset_encoding)

      local hl_group = set_hl(hex, "extmark")
      vim.api.nvim_buf_set_extmark(bufnr, NAMESPACE, start_row, start_col, {
        end_row = end_row,
        end_col = end_col,
        hl_group = hl_group,
        priority = 5000,
        -- conceal = "",
        -- virt_text = { { "  ", hl_group } },
        -- virt_text_win_col = start_col,
        -- right_gravity = true,
        -- virt_text_pos = "virtual_text",
      })
    end
  end)
end

local function buf_set_highlights(bufnr, colors, opts)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)

  for _, color_info in pairs(colors) do
    local rgb_hex = lsp_color_to_hex(color_info.color)
    local highlight_name = create_highlight(rgb_hex, opts)

    local range = color_info.range
    local line = range.start.line
    local start_col = range.start.character
    local end_col = opts.single_column and start_col + opts.col_count or range["end"].character

    vim.api.nvim_buf_add_highlight(bufnr, NAMESPACE, highlight_name, line, start_col, end_col)
    -- update_extmark(bufnr)
  end
end

local function expand_bufnr(bufnr)
  if bufnr == 0 or bufnr == nil then
    return vim.api.nvim_get_current_buf()
  else
    return bufnr
  end
end

--- Can be called to manually update the color highlighting
function M.update_highlight(bufnr, options)
  local params = { textDocument = vim.lsp.util.make_text_document_params() }
  vim.lsp.buf_request(bufnr, "textDocument/documentColor", params, function(err, result, _, _)
    -- update_extmark(bufnr)
    if err == nil and result ~= nil then buf_set_highlights(bufnr, result, options) end
  end)
end

--- Should be called `on_attach` when the LSP client attaches
function M.buf_attach(bufnr, options)
  bufnr = expand_bufnr(bufnr)

  if ATTACHED_BUFFERS[bufnr] then return end
  ATTACHED_BUFFERS[bufnr] = true

  options = options or {}

  -- VSCode extension also does 200ms debouncing
  local trigger_update_highlight, timer = U.debounce_trailing(M.update_highlight, options.debounce or 200, false)

  -- for the first request, the server needs some time before it's ready
  -- sometimes 200ms is not enough for this
  -- TODO: figure out when the first request can be send
  trigger_update_highlight(bufnr, options)

  -- react to changes
  vim.api.nvim_buf_attach(bufnr, false, {
    on_lines = function()
      if not ATTACHED_BUFFERS[bufnr] then return true end
      trigger_update_highlight(bufnr, options)
    end,
    on_detach = function()
      if timer ~= nil then timer:close() end
      ATTACHED_BUFFERS[bufnr] = nil
    end,
  })
end

--- Can be used to detach from the buffer at any time
function M.buf_detach(bufnr)
  bufnr = expand_bufnr(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, NAMESPACE, 0, -1)
  ATTACHED_BUFFERS[bufnr] = nil
end

require("mega.autocmds").augroup("DocumentColors", {
  {
    event = { "BufEnter" },
    desc = "Attach document color LSP functionality to a buffer",
    command = function(evt) M.buf_attach(evt.buf, { single_column = true, col_count = 2, mode = "bg" }) end,
  },
  {
    event = { "BufLeave" },
    desc = "Detach document color LSP functionality from a buffer",
    command = function(evt) M.buf_detach(evt.buf) end,
  },
})

return M
