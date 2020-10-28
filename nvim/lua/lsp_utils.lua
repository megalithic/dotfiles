-- [ utils & helpers ] ---------------------------------------------------------

local M = {}

function M.bmap(mode, key, result, opts)
  local map_opts = opts

  if opts == nil then
    map_opts = { noremap=true, silent=true }
  end

  vim.api.nvim_buf_set_keymap(0, mode, key, result, map_opts)
end

function M.gmap(mode, key, result, opts)
  vim.api.nvim_set_keymap(mode, key, result, opts)
end

function M.augroup(group, fn)
  vim.api.nvim_command("augroup "..group)
  vim.api.nvim_command("autocmd!")
  fn()
  vim.api.nvim_command("augroup END")
end

function M.get_color(synID, what, mode)
  return vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID(synID)), what, mode)
end

function M.inspect(k, v, l)
  local should_log = require("vim.lsp.log").should_log(1)
  if not should_log then return end

  local level = "[DEBUG]"
  if level ~= nil and l == 4 then
    level = "[ERROR]"
  end

  if v then
    print(level .. " " .. k .. " -> " .. vim.inspect(v))
  else
    print(level .. " " .. k .. "..")
  end
end

function M.pclients()
  M.inspect("active_clients", vim.inspect(vim.lsp.get_active_clients()))
end

function M.pbclients()
  M.inspect("buf_clients", vim.inspect(vim.lsp.buf_get_clients()))
end

function M.pcallbacks()
  M.inspect("callbacks", vim.inspect(vim.lsp.callbacks))
end

function M.plogpath()
  M.inspect("log_path", vim.inspect(vim.lsp.get_log_path()))
end


-- [ globals ] -----------------------------------------------------------------

P = function(v)
  print(vim.inspect(v))
  return v
end

return M
