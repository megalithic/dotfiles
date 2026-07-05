log = {}

---@param payload any
---@return string
local function format_message(payload)
  if type(payload) == "string" then
    return payload
  elseif type(payload) == "number" then
    return tostring(payload)
  else
    return vim.inspect(payload)
  end
end

---@param payload any
---@param opts? table
function log.error(payload, opts)
  vim.notify(format_message(payload), vim.log.levels.ERROR, opts)
end
