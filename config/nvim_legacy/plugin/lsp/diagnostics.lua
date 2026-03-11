
return function(_client, _connected_client_bufnr)
local border_style = vim.g.border
local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)
local diagnostic_ns = vim.api.nvim_create_namespace("mega_mvim.lsp_diagnostics")
local diagnostic_group = vim.api.nvim_create_augroup("mega_mvim.lsp_diagnostics", { clear = true })
local has_tiny_diagnostic = pcall(require, "tiny-inline-diagnostic")

  local M = {}
  local diag_sev = vim.diagnostic.severity
  vim.diagnostic.config({
    virtual_text = false,
    signs = {
      text = {
        [diag_sev.ERROR] = Icons.lsp.error,
        [diag_sev.WARN] = Icons.lsp.warn,
        [diag_sev.HINT] = Icons.lsp.hint,
        [diag_sev.INFO] = Icons.lsp.info,
      },
      texthl = {
        [diag_sev.ERROR] = "DiagnosticSignError",
        [diag_sev.WARN] = "DiagnosticSignWarn",
        [diag_sev.INFO] = "DiagnosticSignInfo",
        [diag_sev.HINT] = "DiagnosticSignHint",
      },
      numhl = {
        [diag_sev.ERROR] = "DiagnosticSignError",
        [diag_sev.WARN] = "DiagnosticSignWarn",
        [diag_sev.INFO] = "DiagnosticSignInfo",
        [diag_sev.HINT] = "DiagnosticSignHint",
      },
    },
    update_in_insert = false,
    underline = true,
    severity_sort = true,
    severity = { min = diag_sev.WARN },
    float = {
      source = false,
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
      -- header = { "diagnostics:", "DiagnosticHeader" },
      header = {},
      suffix = function(d)
        if not (d.source or d.code) then
          return "", ""
        end
        local source = (d.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
        local rule = d.code and ": " .. d.code or ""

        return (" %s%s"):format(source, rule), "Comment"
      end,
      -- prefix = function(d, _index, total)
      --   if total == 1 then return "", "" end

      --   local sev = diag_sev[d.severity]
      --   local icon = icons.lsp[sev:lower()]

      --   return icon, "Diagnostic" .. sev:gsub("^%l", string.upper)
      -- end,
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
    jump = {
      on_jump = function(d, b)
        if not d then
          return
        end

        M.show_diagnostics({ buf = b, diagnostic = { d } })
      end,
    },
  })

  local function override_diagnostic_signs(_args)
    local orig_signs_handler = vim.diagnostic.handlers.signs
    vim.diagnostic.handlers.signs = {
      show = function(_, bufnr, _, opts)
        local diagnostics = vim.diagnostic.get(bufnr)
        local max_severity_per_line = {}
        for _, d in pairs(diagnostics) do
          local m = max_severity_per_line[d.lnum]
          if not m or d.severity < m.severity then
            max_severity_per_line[d.lnum] = d
          end
        end
        local filtered_diagnostics = vim.tbl_values(max_severity_per_line)
        orig_signs_handler.show(diagnostic_ns, bufnr, filtered_diagnostics, opts)
      end,
      hide = function(_, bufnr)
        orig_signs_handler.hide(diagnostic_ns, bufnr)
      end,
    }
  end
  override_diagnostic_signs()

  function M.show_diagnostic_popup(opts)
    local bufnr = opts
    if type(opts) == "table" then
      bufnr = opts.buf or 0
    end

    local ok_diags, diags = pcall(vim.diagnostic.open_float, { bufnr = bufnr, scope = "cursor" })
    if not ok_diags and diags then
      local ok_line_diags, _line_diags = pcall(vim.diagnostic.open_float, { bufnr = bufnr })
      if not ok_line_diags then
        vim.diagnostic.open_float()
      end
    end
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
    if not diagnostic then
      return
    end

    if diagnostic_timer then
      diagnostic_timer:close()
      hl_cancel()
    end

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

  function M.show_diagnostics(args)
    if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
      if has_tiny_diagnostic then
        require("tiny-inline-diagnostic").disable()
      end

      vim.schedule(function()
        local cursor = vim.api.nvim_win_get_cursor(0)
        local line = cursor[1] - 1
        local col = cursor[2]

        local valid_diagnostics, _ = pcall(vim.diagnostic.get, args.buf, { lnum = line })
        if not valid_diagnostics then
          return
        end

        local line_diagnostics = args.diagnostic or vim.diagnostic.get(args.buf, { lnum = line })
        local view_diagnostics = vim.tbl_filter(function(item)
          return col >= item.col and col < item.end_col
        end, line_diagnostics)

        if #view_diagnostics == 0 then
          view_diagnostics = line_diagnostics
        end

        if view_diagnostics and #view_diagnostics > 0 and view_diagnostics[1].message ~= nil then
          local diagnostic_num_lines = select(2, view_diagnostics[1].message:gsub("\n", "\n"))
          if diagnostic_num_lines > 1 then
            -- vim.diagnostic.show(diagnostic_ns, args.buf, view_diagnostics, {
            -- virtual_text = {
            --   prefix = function(d)
            --     local icon = icons.lsp[vim.diagnostic.severity[d.severity]:lower()]
            --     return icon or ""
            --   end,
            -- },
            -- })

            M.show_diagnostic_popup(args.buf)
          else
            if has_tiny_diagnostic then
              require("tiny-inline-diagnostic").enable()
            end
          end
        end

        vim.diagnostic.show(nil, args.buf, nil, {
          signs = vim.diagnostic.config().signs,
        })
      end)
    end
  end

  function M.refresh_diagnostics(args)
    if args.buf and vim.api.nvim_buf_is_valid(args.buf) then
      if has_tiny_diagnostic then
        local ns = vim.api.nvim_create_namespace("TinyInlineDiagnostic")
        pcall(vim.api.nvim_buf_clear_namespace, args.buf, ns, 0, -1)
      end

      vim.diagnostic.setloclist({ open = false, namespace = diagnostic_ns })
      M.show_diagnostics(args)
      local loclist = vim.fn.getloclist(0, { items = 0, winid = 0 })
      if vim.tbl_isempty(loclist.items) and loclist.winid > 0 then
        vim.api.nvim_win_close(loclist.winid, true)
        if has_tiny_diagnostic then
          require("tiny-inline-diagnostic").disable()
        end
      end

      if vim.tbl_contains({ "InsertEnter" }, args.event) then
        vim.diagnostic.hide(nil, args.buf)
      end
    end
  end

  Augroup(diagnostic_group, {
    {
      event = { "CursorHold" },
      command = M.show_diagnostics,
    },
    {
      event = { "BufLeave", "WinLeave", "VimResized", "DiagnosticChanged", "InsertLeave", "InsertEnter" },
      command = M.refresh_diagnostics,
    },
  })

  return M
end
