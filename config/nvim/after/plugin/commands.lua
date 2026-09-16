-- after/plugin/commands.lua
-- Custom commands and associated keymaps

if not Plugin_enabled() then return end

--------------------------------------------------------------------------------
-- :Notifications - show snacks notifier history in a scratch split
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("Notifications", function(cmd_opts)
  local ok, Snacks = pcall(require, "snacks")
  if not ok then return vim.notify("snacks.nvim not loaded", vim.log.levels.WARN) end

  local filter = cmd_opts.args ~= "" and cmd_opts.args or nil
  local history = Snacks.notifier.get_history({ reverse = true, filter = filter })

  if #history == 0 then
    vim.notify("No notifications", vim.log.levels.INFO)
    return
  end

  local level_name = {
    [vim.log.levels.ERROR] = "error",
    [vim.log.levels.WARN] = "warn",
    [vim.log.levels.INFO] = "info",
    [vim.log.levels.DEBUG] = "debug",
    [vim.log.levels.TRACE] = "trace",
  }
  local icon_map = {
    error = " ",
    warn = " ",
    info = " ",
    debug = " ",
    trace = " ",
  }
  local hl_map = {
    error = "DiagnosticError",
    warn = "DiagnosticWarn",
    info = "DiagnosticInfo",
    debug = "DiagnosticHint",
    trace = "Comment",
  }

  local lines = {}
  local highlights = {}
  for _, n in ipairs(history) do
    local level = level_name[n.level] or "info"
    local icon = icon_map[level] or "● "
    local time = n.added and os.date("%H:%M:%S", math.floor(n.added)) or ""
    local title = n.title and n.title ~= "" and n.title .. ": " or ""

    for i, line in ipairs(vim.split(n.msg, "\n")) do
      local prefix = i == 1 and string.format("%s %s %s%s", icon, time, title, line)
        or string.format("         %s", line)
      table.insert(lines, prefix)
      table.insert(highlights, { hl = hl_map[level] or "Normal", line = #lines - 1 })
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "notifications"

  local ns = vim.api.nvim_create_namespace("notifications")
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, hl.line, 0, { line_hl_group = hl.hl })
  end

  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.min(#lines, 15))

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end, {
  nargs = "?",
  complete = function() return { "error", "warn", "info", "debug", "trace" } end,
  desc = "Show notification history",
})

-- NOTE: Notification history available via <leader>un (snacks notifier)

--------------------------------------------------------------------------------
-- :Messages - show :messages output in a scratch split
--------------------------------------------------------------------------------

vim.api.nvim_create_user_command("Messages", function()
  local output = vim.api.nvim_exec2("messages", { output = true }).output
  local raw_lines = vim.split(output, "\n", { trimempty = true })

  if #raw_lines == 0 then
    vim.notify("No messages", vim.log.levels.INFO)
    return
  end

  local icon_map = {
    error = " ",
    warn = " ",
    info = " ",
  }
  local hl_map = {
    error = "DiagnosticError",
    warn = "DiagnosticWarn",
    info = "Normal",
  }

  -- Patterns to detect message level
  local function get_level(line)
    if line:match("^E%d+:") or line:match("^Error") or line:match("^Vim:E%d+") then
      return "error"
    elseif line:match("^W%d+:") or line:match("^Warning") then
      return "warn"
    end
    return "info"
  end

  local lines = {}
  local highlights = {}
  for _, line in ipairs(raw_lines) do
    local level = get_level(line)
    local icon = icon_map[level]
    local formatted = string.format("%s %s", icon, line)
    table.insert(lines, formatted)
    table.insert(highlights, { hl = hl_map[level], line = #lines - 1 })
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "messages"

  local ns = vim.api.nvim_create_namespace("messages")
  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_set_extmark(buf, ns, hl.line, 0, { line_hl_group = hl.hl })
  end

  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, math.min(#lines, 15))

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, silent = true })
end, {
  desc = "Show :messages in a scratch split",
})
