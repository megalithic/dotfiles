-- lua/lsp/diagnostics.lua
-- Diagnostic configuration and handlers

local M = {}

-- State for undim feature
local undim_au = vim.api.nvim_create_augroup("mega.lsp.undim", { clear = true })

-- Use centralized icons
local ui_icons = require("icons")
local icons = {
  error = ui_icons.lsp.error .. " ",
  warn = ui_icons.lsp.warn .. " ",
  hint = ui_icons.lsp.hint .. " ",
  info = ui_icons.lsp.info .. " ",
}

local severity = vim.diagnostic.severity
local ns = vim.api.nvim_create_namespace("mega.lsp.diagnostics")
local hl_ns = vim.api.nvim_create_namespace("mega.lsp.diagnostic_hl")

--------------------------------------------------------------------------------
-- Config (computed lazily to get correct window dimensions)
--------------------------------------------------------------------------------

function M.get_config()
  return {
    virtual_text = false, -- We use tiny-inline-diagnostic
    virtual_lines = false, -- Disable native virtual lines
    signs = {
      text = {
        [severity.ERROR] = icons.error,
        [severity.WARN] = icons.warn,
        [severity.HINT] = icons.hint,
        [severity.INFO] = icons.info,
      },
      texthl = {
        [severity.ERROR] = "DiagnosticSignError",
        [severity.WARN] = "DiagnosticSignWarn",
        [severity.INFO] = "DiagnosticSignInfo",
        [severity.HINT] = "DiagnosticSignHint",
      },
      numhl = {
        [severity.ERROR] = "DiagnosticSignError",
        [severity.WARN] = "DiagnosticSignWarn",
        [severity.INFO] = "DiagnosticSignInfo",
        [severity.HINT] = "DiagnosticSignHint",
      },
    },
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
      border = "rounded",
      focusable = false,
      severity_sort = true,
      max_width = math.min(math.floor(vim.o.columns * 0.7), 100),
      max_height = math.min(math.floor(vim.o.lines * 0.3), 30),
      header = {},
      close_events = {
        "CursorMoved",
        "BufHidden",
        "InsertCharPre",
        "BufLeave",
        "InsertEnter",
        "FocusLost",
        "BufWritePre",
      },
      suffix = function(d)
        if not (d.source or d.code) then return "", "" end
        local source = (d.source or ""):gsub(" ?%.$", "")
        local code = d.code and (": " .. d.code) or ""
        return (" %s%s"):format(source, code), "Comment"
      end,
      format = function(d)
        local msg = d.message
        if d.source == "typos" then
          msg = msg:gsub("should be", "󰁔"):gsub("`", "")
        elseif d.source == "Lua Diagnostics." then
          msg = msg:gsub("%.$", "")
        end
        return msg
      end,
    },
  }
end

--------------------------------------------------------------------------------
-- Sign handler: show only highest severity per line
--------------------------------------------------------------------------------

local function setup_sign_handler()
  local orig = vim.diagnostic.handlers.signs

  vim.diagnostic.handlers.signs = {
    show = function(_, bufnr, _, opts)
      local diagnostics = vim.diagnostic.get(bufnr)
      local max_per_line = {}

      for _, d in ipairs(diagnostics) do
        local current = max_per_line[d.lnum]
        if not current or d.severity < current.severity then max_per_line[d.lnum] = d end
      end

      orig.show(ns, bufnr, vim.tbl_values(max_per_line), opts)
    end,
    hide = function(_, bufnr) orig.hide(ns, bufnr) end,
  }
end

--------------------------------------------------------------------------------
-- Navigation with highlight flash
--------------------------------------------------------------------------------

local hl_map = {
  [severity.ERROR] = "DiagnosticVirtualTextError",
  [severity.WARN] = "DiagnosticVirtualTextWarn",
  [severity.HINT] = "DiagnosticVirtualTextHint",
  [severity.INFO] = "DiagnosticVirtualTextInfo",
}

-- State for highlight timer
local hl_timer = nil

local function clear_hl()
  if hl_timer then
    hl_timer:stop()
    hl_timer:close()
    hl_timer = nil
  end
  pcall(vim.api.nvim_buf_clear_namespace, 0, hl_ns, 0, -1)
end

function M.goto_next(opts) M.goto_diagnostic("next", opts) end
function M.goto_prev(opts) M.goto_diagnostic("prev", opts) end

---Navigate to next/prev diagnostic with highlight flash
---@param dir "next"|"prev"
---@param opts? {severity?: vim.diagnostic.Severity}
function M.goto_diagnostic(dir, opts)
  opts = opts or {}
  local count = dir == "next" and 1 or -1

  -- Clear any existing highlight
  clear_hl()

  -- Get the diagnostic BEFORE jumping (so we can highlight it)
  local get_fn = dir == "next" and vim.diagnostic.get_next or vim.diagnostic.get_prev
  local diag = get_fn({ severity = opts.severity })

  if not diag then
    vim.notify("No more diagnostics", vim.log.levels.INFO)
    return
  end

  -- Highlight the diagnostic range
  if diag.end_col and diag.end_col ~= 999 then
    pcall(vim.api.nvim_buf_set_extmark, 0, hl_ns, diag.lnum, diag.col, {
      end_row = diag.end_lnum or diag.lnum,
      end_col = diag.end_col,
      hl_group = hl_map[diag.severity] or "Visual",
    })
  end

  -- Jump to the diagnostic
  vim.diagnostic.jump({ count = count, severity = opts.severity })

  -- Blink cursorline for extra visibility
  if mega and mega.ui and mega.ui.blink_cursorline then mega.ui.blink_cursorline(150) end

  -- Clear highlight after delay
  hl_timer = vim.uv.new_timer()
  hl_timer:start(500, 0, vim.schedule_wrap(clear_hl))
end

--------------------------------------------------------------------------------
-- Show diagnostics popup
--------------------------------------------------------------------------------

function M.show_popup(bufnr)
  bufnr = bufnr or 0
  local ok = pcall(vim.diagnostic.open_float, { bufnr = bufnr, scope = "cursor" })
  if not ok then pcall(vim.diagnostic.open_float, { bufnr = bufnr, scope = "line" }) end
end

--------------------------------------------------------------------------------
-- Intelligent diagnostic display (multi-line vs inline)
--------------------------------------------------------------------------------

-- Check if tiny-inline-diagnostic is available
local tiny_inline = nil
local function get_tiny_inline()
  if tiny_inline == nil then
    local ok, mod = pcall(require, "tiny-inline-diagnostic")
    tiny_inline = ok and mod or false
  end
  return tiny_inline
end

--- Show diagnostics intelligently:
--- - Multi-line diagnostics → floating popup
--- - Single-line diagnostics → tiny-inline-diagnostic (if available)
---@param args {buf: number, diagnostic?: vim.Diagnostic[]}
function M.show_diagnostics(args)
  local bufnr = args.buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  local tiny = get_tiny_inline()

  vim.schedule(function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = cursor[1] - 1
    local col = cursor[2]

    -- Get diagnostics for current line
    local ok, line_diags = pcall(vim.diagnostic.get, bufnr, { lnum = line })
    if not ok or not line_diags then return end

    -- Use provided diagnostics or filter to cursor position
    local diags = args.diagnostic or line_diags

    -- Filter to diagnostics under cursor (if any)
    local cursor_diags = vim.tbl_filter(function(d)
      return col >= d.col and col < (d.end_col or d.col + 1)
    end, diags)

    -- Fall back to line diagnostics if none under cursor
    if #cursor_diags == 0 then cursor_diags = diags end

    if #cursor_diags == 0 then
      -- No diagnostics - ensure tiny-inline is enabled for future
      if tiny then tiny.enable() end
      return
    end

    -- Check if any diagnostic is multi-line
    local has_multiline = false
    for _, d in ipairs(cursor_diags) do
      local newline_count = select(2, d.message:gsub("\n", "\n"))
      if newline_count > 0 then
        has_multiline = true
        break
      end
    end

    if has_multiline then
      -- Multi-line: use floating popup, disable inline
      if tiny then tiny.disable() end
      M.show_popup(bufnr)
    else
      -- Single-line: use tiny-inline-diagnostic
      if tiny then tiny.enable() end
    end
  end)
end

--- Refresh diagnostics display (called on various events)
---@param args {buf: number, event?: string}
function M.refresh_diagnostics(args)
  local bufnr = args.buf
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return end

  local tiny = get_tiny_inline()

  -- Clear tiny-inline namespace to refresh
  if tiny then
    local tiny_ns = vim.api.nvim_create_namespace("TinyInlineDiagnostic")
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, tiny_ns, 0, -1)
  end

  -- Hide diagnostics on InsertEnter
  if args.event == "InsertEnter" then
    vim.diagnostic.hide(nil, bufnr)
    if tiny then tiny.disable() end
    return
  end

  -- Show diagnostics and refresh display
  M.show_diagnostics(args)
end

--------------------------------------------------------------------------------
-- Autocommands
--------------------------------------------------------------------------------

-- Hide diagnostics in insert mode (less visual noise while typing)
local function on_insert_enter(args)
  if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
    vim.diagnostic.hide(nil, args.buf)
    local tiny = get_tiny_inline()
    if tiny then tiny.disable() end
  end
end

local function on_insert_leave(args)
  if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
    vim.diagnostic.show(nil, args.buf)
    M.show_diagnostics(args)
  end
end

--------------------------------------------------------------------------------
-- Undim diagnostics: show "unnecessary" code clearly when cursor is on it
--------------------------------------------------------------------------------

-- Toggle undim for a specific buffer/client
function M.toggle_undim(buf, client_id)
  buf = buf or 0
  local client = vim.lsp.get_client_by_id(client_id)
  if not client then return false end

  -- Check if client supports unnecessary tag
  local caps = client.capabilities
  local tag_support = caps
    and caps.textDocument
    and caps.textDocument.diagnostic
    and caps.textDocument.diagnostic.tagSupport
    and caps.textDocument.diagnostic.tagSupport.valueSet
  if not tag_support or not vim.list_contains(tag_support, 1) then return false end

  -- Create per-client namespace for extmarks
  local name = string.format("mega.lsp.%s.%d.undim", client.name, client.id)
  local undim_ns = vim.api.nvim_create_namespace(name)

  -- Iterator for unnecessary diagnostics
  local function iter_unnecessary()
    local diagnostics = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.HINT })
    return vim.iter(diagnostics):filter(function(d) return d._tags and d._tags.unnecessary end)
  end

  -- Set DiagnosticUnnecessary highlight via extmark
  local function set_dim(d)
    vim.api.nvim_buf_set_extmark(buf, undim_ns, d.lnum, d.col, {
      hl_group = "DiagnosticUnnecessary",
      end_row = d.end_lnum,
      end_col = d.end_col,
      strict = false,
    })
  end

  -- Toggle state
  local state = vim.b[buf].undim_diagnostics or {}
  state[client.id] = not state[client.id]
  vim.b[buf].undim_diagnostics = state

  if not state[client.id] then
    -- Disabled: clear autocmds and restore normal dim behavior
    vim.api.nvim_clear_autocmds({ buffer = buf, group = undim_au })
    vim.api.nvim_buf_clear_namespace(buf, undim_ns, 0, -1)
    for d in iter_unnecessary() do
      set_dim(d)
    end
  else
    -- Enabled: undim on cursor line
    local function update()
      vim.api.nvim_buf_clear_namespace(buf, undim_ns, 0, -1)
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lnum = cursor[1] - 1

      local function in_range(d) return lnum >= d.lnum and lnum <= d.end_lnum end

      for d in iter_unnecessary() do
        if not in_range(d) then set_dim(d) end
        -- On cursor line: don't set extmark, so it shows undimmed
      end
    end

    vim.api.nvim_create_autocmd("ModeChanged", {
      buffer = buf,
      group = undim_au,
      callback = function()
        local mode = vim.fn.mode()
        if mode == "n" then
          update()
        elseif mode ~= "c" then
          -- In insert/visual: clear all undim extmarks
          vim.api.nvim_buf_clear_namespace(buf, undim_ns, 0, -1)
        end
      end,
    })

    vim.api.nvim_create_autocmd({ "CursorHold", "DiagnosticChanged" }, {
      buffer = buf,
      group = undim_au,
      callback = function()
        if vim.fn.mode() == "n" then update() end
      end,
    })

    -- Initial update
    update()
  end

  return true
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------

function M.setup()
  vim.diagnostic.config(M.get_config())
  setup_sign_handler()

  local group = vim.api.nvim_create_augroup("mega.lsp.diagnostics", { clear = true })

  -- CursorHold: intelligently show diagnostics (popup vs inline)
  vim.api.nvim_create_autocmd("CursorHold", {
    group = group,
    callback = M.show_diagnostics,
  })

  -- Refresh diagnostics on various events
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "DiagnosticChanged" }, {
    group = group,
    callback = M.refresh_diagnostics,
  })

  -- Hide diagnostics while typing, show on leave
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = on_insert_enter,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = on_insert_leave,
  })

  -- Auto-enable undim on LspAttach
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Enable undim for unnecessary diagnostics",
    callback = function(e)
      local buf, client_id = e.buf, e.data.client_id
      local state = vim.b[buf].undim_diagnostics or {}
      -- Only enable if not already set for this client
      if state[client_id] == nil then M.toggle_undim(buf, client_id) end
    end,
  })
end

return M
