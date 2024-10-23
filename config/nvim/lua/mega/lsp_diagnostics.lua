local SETTINGS = require("mega.settings")
local icons = SETTINGS.icons.lsp
local fmt = string.format

local diagnostic = {}

local max_width = math.min(math.floor(vim.o.columns * 0.7), 60)
local max_height = math.min(math.floor(vim.o.lines * 0.3), 30)

diagnostic.enable = true

diagnostic.config = {
  modes = { "n" },

  width = max_width,
  default_hl = "Comment",
  active_hl = "DiagnosticTitle",

  parts = {
    top = { "╭─ " },
    border = { "│  " },
    item = { "├─ " },
    bottom = { "╰─ " },
  },
  parts_inverse = {
    top = { " ─╮" },
    border = { "  │" },
    item = { " ─┤" },
    bottom = { " ─╯" },
  },

  severity = {
    error = { fmt("%s ", icons.error), "DiagnosticError" },
    warn = { fmt("%s ", icons.warn), "DiagnosticWarn" },
    info = { fmt("%s ", icons.info), "DiagnosticInfo" },
    hint = { fmt("%s ", icons.hint), "DiagnosticHint" },
    -- error = { " ", "DiagnosticError" },
    -- warn = { " ", "DiagnosticWarn" },
    -- info = { " ", "DiagnosticInfo" },
    -- hint = { "󰔨 ", "DiagnosticHint" },
  },
}

diagnostic.win = nil
diagnostic.buffer = vim.api.nvim_create_buf(false, true)
diagnostic.ns = vim.api.nvim_create_namespace("lsp_diagnostics")

diagnostic.get_cursor_pos = function()
  local win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(win)

  return cur[1], vim.fn.virtcol(".") + vim.fn.getwininfo(win)[1].textoff
end

diagnostic.len = function(...)
  local list = { ... }
  local len = 0

  for _, item in ipairs(list) do
    if vim.islist(item) then
      len = len + vim.fn.strchars(item[1])
    elseif type(item) == "string" then
      len = len + vim.fn.strchars(item)
    end
  end

  return len
end

diagnostic.get_icon = function(lvl)
  local severity = vim.diagnostic.severity

  if lvl == severity.WARN then
    return diagnostic.config.severity.warn
  elseif lvl == severity.ERROR then
    return diagnostic.config.severity.error
  elseif lvl == severity.INFO then
    return diagnostic.config.severity.info
  elseif lvl == severity.HINT then
    return diagnostic.config.severity.hint
  end
end

diagnostic.wrap = function(line, max_len)
  local _l = {}
  local tmp = ""

  for part in line:gmatch("%S+") do
    if vim.fn.strchars(part) >= max_len then
      tmp = tmp:gsub("^(%s*)", "")
      -- tmp = tmp:gsub("(%s*)$", "");

      table.insert(_l, tmp)
      table.insert(_l, vim.fn.strcharpart(part, 0, max_len))
      tmp = vim.fn.strcharpart(part, max_len)
    elseif vim.fn.strchars(tmp .. part) + 1 >= max_len then
      tmp = tmp:gsub("^(%s*)", "")
      -- tmp = tmp:gsub("(%s*)$", "");

      table.insert(_l, tmp)
      tmp = part .. " "
    else
      tmp = tmp .. part .. " "
    end
  end

  if tmp ~= "" then table.insert(_l, tmp) end

  return _l
end

diagnostic.print = function(messages)
  if not diagnostic.buffer or not vim.api.nvim_buf_is_valid(diagnostic.buffer) then diagnostic.buffer = vim.api.nvim_create_buf(false, true) end

  vim.api.nvim_buf_set_lines(diagnostic.buffer, 0, -1, false, {})
  vim.api.nvim_buf_clear_namespace(diagnostic.buffer, diagnostic.ns, 0, -1)

  local row, col = diagnostic.get_cursor_pos()

  local _l = 0
  local used_col = 0

  local _o = {}
  local total = 0

  for _, message in ipairs(messages) do
    local icon = diagnostic.get_icon(message.severity)
    local wrapped = diagnostic.wrap(message.message, diagnostic.config.width - diagnostic.len(icon, diagnostic.config.parts.item))

    local maxlen = 0

    for _, ln in ipairs(wrapped) do
      if vim.fn.strchars(ln) > maxlen then maxlen = vim.fn.strchars(ln) end
    end

    if maxlen > used_col then used_col = maxlen end

    total = total + #wrapped
    local curr_col = vim.api.nvim_win_get_cursor(0)[2]

    table.insert(_o, {
      icon = icon,
      max_len = maxlen,
      text = wrapped,
      in_range = curr_col >= message.col and curr_col <= message.end_col,
    })
  end

  local onBottom = row + total <= vim.api.nvim_win_get_height(0)
  local onRight = col + diagnostic.config.width > vim.api.nvim_win_get_width(0) and true or false

  for i, item in ipairs(_o) do
    for l, line in ipairs(item.text) do
      local stack, pos = {}, "inline"

      if onBottom == true and i == #_o then
        if l == 1 and onRight == true then
          -- pos = "right_align";

          table.insert(stack, { string.rep(" ", diagnostic.config.width - used_col - (diagnostic.len(item.icon, diagnostic.config.parts_inverse.bottom))) })
          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, item.icon)
          table.insert(stack, diagnostic.config.parts_inverse.bottom)
        elseif l == 1 and onRight == false then
          pos = "inline"

          table.insert(stack, diagnostic.config.parts.bottom)
          table.insert(stack, item.icon)
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        elseif onRight == true then
          pos = "right_align"

          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, { string.rep(" ", diagnostic.len(diagnostic.config.parts_inverse.bottom)) })
        elseif onRight == false then
          pos = "inline"

          table.insert(stack, { string.rep(" ", diagnostic.len(diagnostic.config.parts_inverse.bottom)) })
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        end
      elseif onBottom == false and i == 1 then
        if l == 1 and onRight == true then
          -- pos = "right_align";

          table.insert(stack, { string.rep(" ", diagnostic.config.width - used_col - (diagnostic.len(item.icon, diagnostic.config.parts_inverse.top))) })
          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, item.icon)
          table.insert(stack, diagnostic.config.parts_inverse.top)
        elseif l == 1 and onRight == false then
          pos = "inline"

          table.insert(stack, diagnostic.config.parts.top)
          table.insert(stack, item.icon)
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        elseif onRight == true then
          pos = "right_align"

          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, diagnostic.config.parts_inverse.border)
        elseif onRight == false then
          pos = "inline"

          table.insert(stack, diagnostic.config.parts.border)
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        end
      else
        if l == 1 and onRight == true then
          pos = "right_align"

          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, item.icon)
          table.insert(stack, diagnostic.config.parts_inverse.item)
        elseif l == 1 and onRight == false then
          pos = "inline"

          table.insert(stack, diagnostic.config.parts.item)
          table.insert(stack, item.icon)
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        elseif onRight == true then
          pos = "right_align"

          table.insert(
            stack,
            { string.format("%+" .. used_col .. "s", line), item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl }
          )
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, diagnostic.config.parts_inverse.border)
        else
          pos = "inline"

          table.insert(stack, diagnostic.config.parts.border)
          table.insert(stack, { string.rep(" ", diagnostic.len(item.icon)) })
          table.insert(stack, { line, item.in_range == true and diagnostic.config.active_hl or diagnostic.config.default_hl })
        end
      end

      vim.fn.setbufline(diagnostic.buffer, _l + 1, "")
      vim.api.nvim_buf_set_extmark(diagnostic.buffer, diagnostic.ns, _l, 0, {
        virt_text_pos = pos,
        virt_text = stack,
      })

      _l = _l + 1
    end
  end

  return _l, used_col + diagnostic.len(diagnostic.config.parts.item, diagnostic.config.severity.warn)
end

---+ ${func}
diagnostic.open_win = function(line_count, max_column)
  if line_count == 0 then return end

  if not diagnostic.win or not vim.api.nvim_win_is_valid(diagnostic.win) then
    diagnostic.win = vim.api.nvim_open_win(diagnostic.buffer, false, {
      relative = "cursor",
      row = 1,
      col = 0,

      focusable = false,
      width = diagnostic.config.width,
      height = line_count,
    })
  else
    vim.api.nvim_win_set_config(diagnostic.win, {
      width = diagnostic.config.width,
      height = line_count,
    })
  end

  vim.api.nvim_win_set_cursor(diagnostic.win, { 1, 0 })

  vim.wo[diagnostic.win].number = false
  vim.wo[diagnostic.win].relativenumber = false
  vim.wo[diagnostic.win].cursorline = false

  vim.wo[diagnostic.win].winhighlight = diagnostic.config.winhl
    or table.concat({
      "Normal:NormalFloat",
      "FloatBorder:FloatBorder",
      "CursorLine:Visual",
      "Search:None",
    }, ",")

  local scr_row, scr_col = diagnostic.get_cursor_pos()
  local w, h = vim.api.nvim_win_get_width(0), vim.api.nvim_win_get_height(0)

  if line_count + scr_row > h then
    if scr_col + diagnostic.config.width > w then
      vim.api.nvim_win_set_config(diagnostic.win, {
        relative = "cursor",
        row = 0,
        col = 1,

        anchor = "SE",
      })
    else
      vim.api.nvim_win_set_config(diagnostic.win, {
        relative = "cursor",
        row = 0,
        col = 0,

        anchor = "SW",
      })
    end
  else
    if scr_col + diagnostic.config.width > w then
      vim.api.nvim_win_set_config(diagnostic.win, {
        relative = "cursor",
        row = 1,
        col = 1,

        anchor = "NE",
      })
    else
      vim.api.nvim_win_set_config(diagnostic.win, {
        relative = "cursor",
        row = 1,
        col = 0,

        anchor = "NW",
      })
    end
  end
end
--_

diagnostic.show = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local buffer = vim.api.nvim_get_current_buf()

  local diag_data = vim.diagnostic.get(buffer, { lnum = cursor[1] - 1 })
  diagnostic.open_win(diagnostic.print(diag_data))
end

diagnostic.close = function()
  pcall(vim.api.nvim_win_close, diagnostic.win, true)
  diagnostic.win = nil
end

diagnostic.autocmd = nil
diagnostic.timer = vim.uv.new_timer()

diagnostic.init = function(config)
  if config and type(config) == "table" then diagnostic.config = vim.tbl_deep_extend("force", diagnostic.config, config) end

  pcall(vim.api.nvim_del_autocmd, diagnostic.autocmd)

  local events = { "ModeChanged", "LspNotify" }
  local debounce = 50

  if vim.list_contains(diagnostic.config.modes, "n") then
    table.insert(events, "CursorMoved")
    table.insert(events, "CursorHold")
    table.insert(events, "TextChanged")
  end

  diagnostic.autocmd = vim.api.nvim_create_autocmd(events, {
    callback = function()
      diagnostic.timer:stop()
      diagnostic.timer:start(
        debounce,
        0,
        vim.schedule_wrap(function()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local buffer = vim.api.nvim_get_current_buf()

          local mode = vim.api.nvim_get_mode().mode

          if diagnostic.enable ~= true then
            pcall(vim.api.nvim_win_close, diagnostic.win, true)
            diagnostic.win = nil
            return
          end

          if not vim.list_contains(diagnostic.config.modes, mode) then
            pcall(vim.api.nvim_win_close, diagnostic.win, true)
            diagnostic.win = nil
            return
          end

          local diag_data = vim.diagnostic.get(buffer, { lnum = cursor[1] - 1 })

          if #diag_data == 0 then
            pcall(vim.api.nvim_win_close, diagnostic.win, true)
            diagnostic.win = nil
            return
          end

          diagnostic.open_win(diagnostic.print(diag_data))
          vim.cmd("redraw")
        end)
      )
    end,
  })
end

diagnostic.init()

-- vim.diagnostic.config({
--   virtual_text = false,
--   signs = {
--     text = {
--       [vim.diagnostic.severity.ERROR] = " ",
--       [vim.diagnostic.severity.WARN] = " ",
--       [vim.diagnostic.severity.HINT] = " ",
--       [vim.diagnostic.severity.INFO] = "󰔨 ",
--     },
--   },
-- })

return diagnostic
