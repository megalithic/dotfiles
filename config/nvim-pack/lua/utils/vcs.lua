-- VCS root detection utilities (jj only).
-- Mirrors https://github.com/madmaxieee/nvim-config/blob/main/lua/utils/jj.lua

local M = {}

---@type table<string, boolean>
local jj_root_cache = {}
---@param dir string
---@return boolean
function M.is_jj_root(dir)
  if jj_root_cache[dir] == nil then
    local stat = vim.uv.fs_stat(dir .. "/.jj")
    jj_root_cache[dir] = (stat ~= nil) and (stat.type == "directory")
  end
  return jj_root_cache[dir]
end

--- Gets the vcs root directory for a buffer or path.
--- Defaults to the current buffer.
---@param path? number|string buffer or path
---@param is_root fun(dir: string): boolean
---@return string?
local function get_root(path, is_root)
  path = path or 0
  path = type(path) == "number" and vim.api.nvim_buf_get_name(path) or path --[[@as string]]
  path = path == "" and vim.uv.cwd() or path
  path = vim.fs.normalize(path)

  if is_root(path) then return path end

  for dir in vim.fs.parents(path) do
    if is_root(dir) then return vim.fs.normalize(dir) end
  end

  return nil
end

--- Gets the jj root directory for a buffer or path.
--- Defaults to the current buffer.
---@param path? number|string buffer or path
---@return string?
function M.get_jj_root(path) return get_root(path, M.is_jj_root) end

return M
