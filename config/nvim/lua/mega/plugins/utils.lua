-- REF: https://github.com/rstacruz/vimfiles

local fmt = string.format
local M = {}

-- Checks if a given package is available
function M.has_pkg(name)
  local path = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. name
  return vim.fn.empty(vim.fn.glob(path)) == 0
end

-- Loads a module using require(), but does nothing if the module is not present
-- Used for conditionally configuring a plugin depending on whether it's installed
function M.conf(module_name, callback, opts)
  -- first try to load an external config...
  if opts == nil then
    return pcall(require, fmt("mega.plugins.%s", module_name))
  else
    -- else, pass in custom function
    local status, mod = pcall(require, module_name)
    if status then
      if opts and opts["defer"] then
        vim.defer_fn(function()
          callback(mod)
        end, 1000)
      else
        callback(mod)
      end
    end
  end
end

function M.which(bin)
  return vim.fn.executable(bin) == 1
end

---A thin wrapper around vim.notify to add packer details to the message
---@param msg string
local function packer_notify(msg, level)
  vim.notify(msg, level, { title = "Packer" })
end

return M
