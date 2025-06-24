local SETTINGS = require("config.options")
local icons = SETTINGS.icons
local border_style = SETTINGS.border
local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)
local diagnostic_ns = vim.api.nvim_create_namespace("mega.lsp_diagnostics")
local diagnostic_group = vim.api.nvim_create_augroup("mega.lsp_diagnostics", { clear = true })

return function(_client, _connected_client_bufnr)
  local M = {}
  local diag_level = vim.diagnostic.severity
  vim.diagnostic.config({
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
    severity = { min = diag_level.WARN },
    float = {
      show_header = true,
      source = true,
      border = border_style,
      focusable = false,
      severity_sort = true,
      max_width = max_width,
      max_height = max_height,
      close_events = {
        "CursorMoved",
        "BufHidden",
        "InsertCharPre",
        "BufLeave",
        "InsertEnter",
        "FocusLost",
        "BufWritePre",
        "BufWritePost",
      },
      header = {},
      suffix = function(d)
        if not (d.source or d.code) then return "", "" end
        local source = (d.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
        local rule = d.code and ": " .. d.code or ""

        return (" %s%s"):format(source, rule), "Comment"
      end,
      prefix = function(d, _index, total)
        if total == 1 then return "", "" end
        local level = d.severity[d.severity]
        local prefix = string.format("%s ", SETTINGS.icons.lsp[level:lower()])
        return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
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
    jump = { on_jump = M.on_jump },
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

  function M.show_diagnostics(args)
    vim.schedule(function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local line = cursor[1] - 1
      local col = cursor[2]
      local line_diagnostics = args.diagnostic or vim.diagnostic.get(args.buf, { lnum = line })
      local view_diagnostics = vim.tbl_filter(function(item) return col >= item.col and col < item.end_col end, line_diagnostics)

      if #view_diagnostics == 0 then view_diagnostics = line_diagnostics end

      if view_diagnostics and #view_diagnostics > 0 then
        local count = select(2, view_diagnostics[1].message:gsub("\n", "\n"))
        if count > 1 then
          require("tiny-inline-diagnostic").disable()
          -- vim.diagnostic.show(diagnostic_ns, args.buf, view_diagnostics, {
          -- virtual_text = {
          --   prefix = function(diag)
          --     local icon = icons.lsp[vim.diagnostic.severity[diag.severity]:lower()]
          --     return icon or ""
          --   end,
          -- },
          -- })

          M.show_diagnostic_popup(args.buf)
        else
          require("tiny-inline-diagnostic").enable()
        end
      end

      vim.diagnostic.show(nil, args.buf, nil, {
        signs = vim.diagnostic.config().signs,
      })
    end)
  end

  function M.refresh_diagnostics(args)
    vim.diagnostic.setloclist({ open = false, namespace = diagnostic_ns })
    M.show_diagnostics(args)
    local loclist = vim.fn.getloclist(0, { items = 0, winid = 0 })
    if vim.tbl_isempty(loclist.items) and loclist.winid > 0 then
      vim.api.nvim_win_close(loclist.winid, true)
      require("tiny-inline-diagnostic").disable()
    end
  end

  --- @param diagnostic? vim.Diagnostic
  --- @param buf integer
  function M.on_jump(diagnostic, buf)
    D({ diagnostic, buf })
    if not diagnostic then return end

    M.show_diagnostics({ buf = buf, diagnostic = { diagnostic } })
  end

  function M.show_diagnostic_popup(opts)
    local bufnr = opts
    if type(opts) == "table" then bufnr = opts.buf or 0 end
    -- Try to open diagnostics under the cursor
    local diags = vim.diagnostic.open_float(bufnr, { focus = false, scope = "cursor" })
    -- If there's no diagnostic under the cursor show diagnostics of the entire line
    if not diags then vim.diagnostic.open_float(bufnr, { focus = false, scope = "line" }) end
  end

  function M.goto_diagnostic_hl(dir)
    assert(dir == "prev" or dir == "next")

    local jump_count = dir == "next" and 1 or -1
    local diagnostic_goto_ns = vim.api.nvim_create_namespace("mega.lsp_goto_diagnostic_hl")
    local diagnostic_timer
    local hl_cancel
    local hl_map = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticVirtualTextError",
      [vim.diagnostic.severity.WARN] = "DiagnosticVirtualTextWarn",
      [vim.diagnostic.severity.HINT] = "DiagnosticVirtualTextHint",
      [vim.diagnostic.severity.INFO] = "DiagnosticVirtualTextInfo",
    }

    local diagnostic = vim.diagnostic["get_" .. dir]()
    if not diagnostic then return end

    if diagnostic_timer then
      diagnostic_timer:close()
      hl_cancel()
    end

    -- if end_col is 999, typically we'd get an out of range error from extmarks api
    if diagnostic.end_col ~= 999 then
      vim.api.nvim_buf_set_extmark(0, diagnostic_goto_ns, diagnostic.lnum, diagnostic.col, {
        end_row = diagnostic.end_lnum,
        end_col = diagnostic.end_col,
        hl_group = hl_map[diagnostic.severity],
      })
    end

    hl_cancel = function()
      diagnostic_timer = nil
      hl_cancel = nil
      pcall(vim.api.nvim_buf_clear_namespace, 0, diagnostic_goto_ns, 0, -1)
    end

    diagnostic_timer = vim.defer_fn(hl_cancel, 500)

    vim.diagnostic.jump({
      count = jump_count,
    })
  end

  Augroup(diagnostic_group, {
    {
      event = { "CursorHold" },
      command = M.show_diagnostics,
    },
    {
      event = { "BufLeave", "WinLeave" },
      command = function(args)
        if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
          local ns = vim.api.nvim_create_namespace("TinyInlineDiagnostic")
          pcall(vim.api.nvim_buf_clear_namespace, args.buf, ns, 0, -1)

          M.refresh_diagnostics(args)
        end
      end,
    },
    {
      event = { "DiagnosticChanged" },
      command = M.refresh_diagnostics,
    },
  })

  return M
end
