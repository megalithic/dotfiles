local U = require("mega.utils")
local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons
local BORDER_STYLE = SETTINGS.border
local max_width = math.min(math.floor(vim.o.columns * 0.7), 100)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

return function(client, bufnr)
  -- local sev_to_icon = {}
  -- M.signs = { linehl = {}, numhl = {}, text = {} }

  -- local SIGN_TYPES = { "Error", "Warn", "Info", "Hint" }
  -- for _, type in ipairs(SIGN_TYPES) do
  --   local hl = ("DiagnosticSign%s"):format(type)
  --   local icon = icons.lsp[type:lower()]

  --   local key = type:upper()
  --   local code = vim.diagnostic.severity[key]

  --   -- for vim.notify icon
  --   sev_to_icon[code] = icon

  --   -- vim.diagnostic.config signs
  --   local sign = ("%s "):format(icon)
  --   M.signs.text[code] = sign
  --   M.signs.numhl[code] = hl
  --   vim.fn.sign_define(hl, { numhl = hl, text = sign })
  -- end

  ---@param diag vim.Diagnostic
  ---@return string
  local function diag_msg_format(diag)
    local msg = diag.message
    if diag.source == "typos" then
      msg = msg:gsub("should be", "󰁔"):gsub("`", "")
    elseif diag.source == "Lua Diagnostics." then
      msg = msg:gsub("%.$", "")
    end
    return msg
  end

  ---@param diag vim.Diagnostic
  ---@param mode "virtual_text"|"float"
  ---@return string displayedText
  ---@return string highlight
  local function diag_source_as_suffix(diag, mode)
    if not (diag.source or diag.code) then return "", "" end
    local source = (diag.source or ""):gsub(" ?%.$", "") -- trailing dot for lua_ls
    local rule = diag.code and ": " .. diag.code or ""

    if mode == "virtual_text" then
      return (" (%s%s)"):format(source, rule), "Comment"
    elseif mode == "float" then
      return (" %s%s"):format(source, rule), "Comment"
    end

    return "", ""
  end

  --       local function float_format(diagnostic)
  --         --[[ e.g.
  -- {
  --   bufnr = 1,
  --   code = "trailing-space",
  --   col = 4,
  --   end_col = 5,
  --   end_lnum = 44,
  --   lnum = 44,
  --   message = "Line with postspace.",
  --   namespace = 12,
  --   severity = 4,
  --   source = "Lua Diagnostics.",
  --   user_data = {
  --     lsp = {
  --       code = "trailing-space"
  --     }
  --   }
  -- }
  -- ]]

  --         -- diagnostic.message may be pre-parsed in lspconfig's handlers
  --         -- ["textDocument/publishDiagnostics"]
  --         -- e.g. ts_ls in dko/plugins/lsp.lua

  --         local symbol = sev_to_icon[diagnostic.severity] or "-"
  --         local source = diagnostic.source
  --         if source then
  --           if source.sub(source, -1, -1) == "." then
  --             -- strip period at end
  --             source = source:sub(1, -2)
  --           end
  --         else
  --           source = "NIL.SOURCE"
  --           vim.print(diagnostic)
  --         end
  --         local source_tag = U.smallcaps(("%s"):format(source))
  --         local code = diagnostic.code and ("[%s]"):format(diagnostic.code) or ""
  --         return ("%s %s %s\n%s"):format(symbol, source_tag, code, diagnostic.message)
  --       end

  -- Configure diagnostics
  vim.diagnostic.config({
    virtual_text = {
      severity = { min = vim.diagnostic.severity.WARN },
    },
    underline = true,
    float = {
      header = "",
      border = "rounded",
    },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "✗",
        [vim.diagnostic.severity.WARN] = "▲",
        [vim.diagnostic.severity.INFO] = "∙",
        [vim.diagnostic.severity.HINT] = "∴",
      },
      numhl = {
        [vim.diagnostic.severity.ERROR] = "ErrorMsg",
        [vim.diagnostic.severity.WARN] = "WarningMsg",
      },
      severity = { min = vim.diagnostic.severity.INFO },
    },
    jump = {
      float = true,
      wrap = false,
    },
    severity_sort = true,
  })

  local diag_level = vim.diagnostic.severity
  vim.diagnostic.config({
    virtual_lines = false,
    underline = true,
    signs = {
      text = {
        [diag_level.ERROR] = icons.lsp.error, -- alts: ▌
        [diag_level.WARN] = icons.lsp.warn,
        [diag_level.HINT] = icons.lsp.hint,
        [diag_level.INFO] = icons.lsp.info,
      },
      numhl = {
        [diag_level.ERROR] = "DiagnosticError",
        [diag_level.WARN] = "DiagnosticWarn",
        [diag_level.HINT] = "DiagnosticHint",
        [diag_level.INFO] = "DiagnosticInfo",
      },
      texthl = {
        [diag_level.ERROR] = "DiagnosticError",
        [diag_level.WARN] = "DiagnosticWarn",
        [diag_level.HINT] = "DiagnosticHint",
        [diag_level.INFO] = "DiagnosticInfo",
      },
      -- severity = { min = vim_diag.severity.WARN },
    },
    float = {
      show_header = true,
      source = true,
      border = BORDER_STYLE,
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
      -- scope = "cursor",
      header = { " Diagnostics:", "DiagnosticHeader" },
      suffix = function(diag) return diag_source_as_suffix(diag, "float") end,
      prefix = function(_diag, _index, total)
        if total == 1 then return "", "" end
        -- local level = diag.severity[diag.severity]
        -- local prefix = fmt("%s ", SETTINGS.icons.lsp[level:lower()])
        -- return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
        return "• ", "NonText"
      end,
      format = diag_msg_format,
    },
    -- jump = {
    --   -- Do not show floating window
    --   float = false,

    --   -- Wrap around buffer
    --   wrap = true,
    -- },
    severity_sort = true,
    -- virtual_lines = {
    --   current_line = true,
    -- },
    virtual_text = false,
    -- virtual_text = {
    --   spacing = 2,
    --   prefix = "", -- Could be '●', '▎', 'x'
    --   only_current_line = true,
    --   highlight_whole_line = false,
    --   severity = { min = diag_level.ERROR },
    --   suffix = function(diag) return diag_source_as_suffix(diag, "virtual_text") end,
    --   format = function(diag)
    --     local source = diag.source

    --     if source then
    --       local icon = SETTINGS.icons.lsp[vim.diagnostic.severity[diag.severity]:lower()]

    --       return string.format("%s %s %s", icon, source, "[" .. (diag.code ~= nil and diag.code or diag.message) .. "]")
    --     end

    --     return string.format("%s ", diag.message)
    --   end,
    -- },
    update_in_insert = false,
  })

  local signs = { Error = icons.lsp.error, Warn = icons.lsp.warn, Hint = icons.lsp.hint, Info = icons.lsp.info }
  for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  local ns = vim.api.nvim_create_namespace("mega.lsp_max_severity_diagnostics")
  local orig_signs_handler = vim.diagnostic.handlers.signs
  local max_diagnostics = function(_ns, bn, _diagnostics, opts)
    local diagnostics = vim.diagnostic.get(bn)
    local max_severity_per_line = {}
    for _, d in pairs(diagnostics) do
      local m = max_severity_per_line[d.lnum]
      if not m or d.severity < m.severity then max_severity_per_line[d.lnum] = d end
    end
    local filtered_diagnostics = vim.tbl_values(max_severity_per_line)

    -- dbg(filtered_diagnostics)

    if filtered_diagnostics == nil or U.tlen(filtered_diagnostics) == 0 then
      orig_signs_handler.show(ns, bn, diagnostics, opts)
    else
      orig_signs_handler.show(ns, bn, filtered_diagnostics, opts)
    end
  end

  local fname = vim.api.nvim_buf_get_name(bufnr)
  local fext = fname:match("%.[^.]+$")

  if
    SETTINGS.max_diagnostic_exclusions and vim.tbl_contains(SETTINGS.max_diagnostic_exclusions, client.name) or (client.name == "elixirls" and fext ~= ".exs")
  then
    vim.diagnostic.handlers.signs = orig_signs_handler
  else
    vim.diagnostic.handlers.signs = vim.tbl_extend("force", orig_signs_handler, {
      show = max_diagnostics,
      hide = function(_, bn) orig_signs_handler.hide(ns, bn) end,
    })
  end

  -- vim.lsp.handlers["window/showMessage"] = function(_, result)
  --   -- if require("vim.lsp.log").should_log(convert_lsp_log_level_to_neovim_log_level(result.type)) then
  --   vim.print(result.message)
  --   local levels = {
  --     "ERROR",
  --     "WARN",
  --     "INFO",
  --     "DEBUG",
  --     [0] = "TRACE",
  --   }
  --   vim.notify(result.message, vim.log.levels[levels[result.type]])
  --   -- end
  -- end
  --
  --
end
