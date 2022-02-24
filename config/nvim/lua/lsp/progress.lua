local M = {}
local lsp = vim.lsp

-----------------------------------------------------------------------------//
-- LSP Progress notification
-----------------------------------------------------------------------------//
local client_notifs = {}

local spinner_frames = { "⣾", "⣽", "⣻", "⢿", "⡿", "⣟", "⣯", "⣷" }

local function update_spinner(client_id, token)
  local notif_data = client_notifs[client_id][token]
  if notif_data and notif_data.spinner then
    local new_spinner = (notif_data.spinner + 1) % #spinner_frames
    local new_notif = vim.notify(nil, nil, {
      hide_from_history = true,
      icon = spinner_frames[new_spinner],
      replace = notif_data.notification,
    })
    client_notifs[client_id][token] = {
      notification = new_notif,
      spinner = new_spinner,
    }
    vim.defer_fn(function()
      update_spinner(client_id, token)
    end, 100)
  end
end

local function format_title(title, client)
  return client.name .. (#title > 0 and ": " .. title or "")
end

local function format_message(message, percentage)
  return (percentage and percentage .. "%\t" or "") .. (message or "")
end

M.lsp_progress_notification = function(_, result, ctx)
  local client_id = ctx.client_id
  local val = result.value
  if val.kind then
    if not client_notifs[client_id] then
      client_notifs[client_id] = {}
    end
    local notif_data = client_notifs[client_id][result.token]
    if val.kind == "begin" then
      -- local message = format_message(val.message, val.percentage)
      local message = format_message(val.message or "Loading...", val.percentage)
      local notification = vim.notify(message, "info", {
        title = format_title(val.title, vim.lsp.get_client_by_id(client_id)),
        icon = spinner_frames[1],
        timeout = false,
        hide_from_history = true,
      })
      client_notifs[client_id][result.token] = {
        notification = notification,
        spinner = 1,
      }
      update_spinner(client_id, result.token)
    elseif val.kind == "report" and notif_data then
      local new_notif = vim.notify(
        format_message(val.message, val.percentage),
        "info",
        { replace = notif_data.notification, hide_from_history = false }
      )
      client_notifs[client_id][result.token] = {
        notification = new_notif,
        spinner = notif_data.spinner,
      }
    elseif val.kind == "end" and notif_data then
      local new_notif = vim.notify(
        val.message and format_message(val.message) or "Complete",
        "info",
        { icon = "", replace = notif_data.notification, timeout = 3000 }
      )
      client_notifs[client_id][result.token] = {
        notification = new_notif,
      }
    end
  end
end

return M
