local M = {}

function M.map(lhs, rhs, mode, expr) -- wait for lua keymaps: neovim/neovim#13823
  mode = mode or "n"
  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end
  vim.api.nvim_set_keymap(mode, lhs, rhs, {noremap = true, silent = true, expr = expr})
end

function M.bufmap(lhs, rhs, mode, expr)
  mode = mode or "n"
  if mode == "n" then
    rhs = "<cmd>" .. rhs .. "<cr>"
  end
  vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, {noremap = true, silent = true, expr = expr})
end

function M.au(s)
  vim.cmd("au!" .. s)
end

function M.inspect(k, v, l, f)
  local force = f or false
  local should_log = require("vim.lsp.log").should_log(1)
  if not should_log and not force then
    return
  end

  local level = "[DEBUG]"
  if level ~= nil and l == 4 then
    level = "[ERROR]"
  end

  if v then
    print(level .. " " .. k .. " -> " .. vim.inspect(v))
  else
    print(level .. " " .. k .. "..")
  end

  return v
end

-- a safe module loader
function M.load(req, key)
  if key == nil then key = "loader" end

  local loaded, loader = pcall(require, req)

  if loaded then
    return loader
  else
    mega.inspect("loading failed", {key, loader}, 4, true)
  end
end

function M.dump(...)
  print(unpack(vim.tbl_map(inspect, {...})))
end

function M.plugins()
  print("-> syncing plugins..")

  package.loaded["plugins"] = nil
  require("paq"):setup({verbose = false})(require("plugins")):sync()
end

return M
