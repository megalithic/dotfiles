local U = require("config.utils")
local SETTINGS = require("config.options")
local icons = SETTINGS.icons
local BORDER_STYLE = SETTINGS.border
local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)
local diagnostic_ns = vim.api.nvim_create_namespace("mega.lsp_diagnostics")
local diagnostic_group = vim.api.nvim_create_augroup("mega.lsp_diagnostics", { clear = true })

return function(client, bufnr)
  -- --- @param diagnostic? vim.Diagnostic
  -- --- @param bufnr integer
  -- local function on_jump(diagnostic, bufnr)
  --   if not diagnostic then return end
  --   vim.diagnostic.show(virt_lines_ns, bufnr, { diagnostic }, { virtual_lines = { current_line = true }, virtual_text = false })
  -- end

  local diag_level = vim.diagnostic.severity
  vim.diagnostic.config({
    -- virtual_text = {
    --   severity = { min = diag_level.WARN },
    -- },
    virtual_text = false,
    signs = {
      text = {
        [diag_level.ERROR] = icons.lsp.error,
        [diag_level.WARN] = icons.lsp.warn,
        [diag_level.HINT] = icons.lsp.hint,
        [diag_level.INFO] = icons.lsp.info,
      },
      texthl = {
        [diag_level.ERROR] = "DiagnosticSignError",
        [diag_level.WARN] = "DiagnosticSignWarn",
        [diag_level.INFO] = "DiagnosticSignInfo",
        [diag_level.HINT] = "DiagnosticSignHint",
      },
      numhl = {
        [diag_level.ERROR] = "DiagnosticSignError",
        [diag_level.WARN] = "DiagnosticSignWarn",
        [diag_level.INFO] = "DiagnosticSignInfo",
        [diag_level.HINT] = "DiagnosticSignHint",
      },
    },
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    float = { border = BORDER_STYLE },
  })

  local function override_diagnostic_signs(_args)
    -- Aggregate our signs into one sign, most severe shows first
    local orig_signs_handler = vim.diagnostic.handlers.signs
    vim.diagnostic.handlers.signs = {
      show = function(_, bufnr, _, opts)
        -- Get all diagnostics from the whole buffer rather than just the
        -- diagnostics passed to the handler
        local diagnostics = vim.diagnostic.get(bufnr)
        -- Find the "worst" diagnostic per line
        local max_severity_per_line = {}
        for _, d in pairs(diagnostics) do
          local m = max_severity_per_line[d.lnum]
          if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
        end
        -- Pass the filtered diagnostics (with our custom namespace) to
        -- the original handler
        local filtered_diagnostics = vim.tbl_values(max_severity_per_line)
        orig_signs_handler.show(diagnostic_ns, bufnr, filtered_diagnostics, opts)
      end,
      hide = function(_, bufnr) orig_signs_handler.hide(diagnostic_ns, bufnr) end,
    }
  end
  override_diagnostic_signs()

  local function show_diagnostics(args)
    vim.schedule(function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = cursor[1] - 1
      local col = cursor[2]
      local line_diagnostics = vim.diagnostic.get(args.buf, { lnum = line })
      local view_diagnostics = vim.tbl_filter(function(item) return col >= item.col and col < item.end_col end, line_diagnostics)

      if #view_diagnostics == 0 then view_diagnostics = line_diagnostics end

      vim.diagnostic.show(diagnostic_ns, args.buf, view_diagnostics, {
        virtual_text = {
          prefix = function(diag)
            local icon = icons.lsp[vim.diagnostic.severity[diag.severity]:lower()]
            return icon or ""
          end,
        },
      })
      vim.diagnostic.show(nil, args.buf, nil, {
        signs = vim.diagnostic.config().signs,
      })
    end)
  end

  local function refresh_diagnostics(args)
    vim.diagnostic.setloclist({ open = false, namespace = diagnostic_ns })
    show_diagnostics(args)
    local loclist = vim.fn.getloclist(0, { items = 0, winid = 0 })
    if vim.tbl_isempty(loclist.items) and loclist.winid > 0 then vim.api.nvim_win_close(loclist.winid, true) end
  end

  Augroup(diagnostic_group, {
    {
      event = { "CursorHold" },
      command = show_diagnostics,
    },
    {
      event = { "DiagnosticChanged" },
      command = refresh_diagnostics,
    },
  })
end
