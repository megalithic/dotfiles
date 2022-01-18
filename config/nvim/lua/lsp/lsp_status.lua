-- HT: https://gist.github.com/clason/1fe0f77ed3cc810ff75429edf1c56409

local M = {}
M.clients = {}
M.progress_message = ""

M.init = function()
  M.register_progress()
end

M.update_status = function()
  M.update_progress()
  return M.progress_message
end

M.register_progress = function()
  M.clients = {}

  M.progress_callback = function(_, msg, info)
    local key = msg.token
    if key then
      local client_key = tostring(info.client_id)
      if not M.clients[client_key] then
        M.clients[client_key] = { progress = {}, name = vim.lsp.get_client_by_id(info.client_id).name }
      end
      local progress_collection = M.clients[client_key].progress
      if not progress_collection[key] then
        progress_collection[key] = { title = nil, message = nil, percentage = nil }
      end
      local progress = progress_collection[key]

      local val = msg.value
      if val.kind == "begin" then
        progress.title = val.title
        progress.message = "starting"
      elseif val.kind == "report" then
        progress.percentage = val.percentage
        progress.message = val.message
      elseif val.kind == "end" then
        progress.percentage = "100"
        progress.message = "done"
        vim.defer_fn(function()
          M.clients[client_key] = nil
        end, 1000)
      end
    end
  end
  vim.lsp.handlers["$/progress"] = M.progress_callback
end

M.update_progress = function()
  local result = {}
  for _, client in pairs(M.clients) do
    table.insert(result, client.name .. ": ")
    for _, progress in pairs(client.progress) do
      if progress.title and progress.title ~= "" then
        table.insert(result, progress.title .. " ")
      end
      if progress.percentage and progress.percentage ~= "" then
        table.insert(result, progress.percentage .. "%% ")
      end
      if progress.message and progress.message ~= "" then
        table.insert(result, "(" .. progress.message .. ")")
      end
    end
  end
  M.progress_message = table.concat(result)
end

return M
