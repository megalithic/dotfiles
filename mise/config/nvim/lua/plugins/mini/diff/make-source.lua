-- Shared diff-source factory and reload helper.
-- Extracted from mini/diff.lua so that utils/jj.lua can call reload_all
-- after changing the base rev.
-- Pattern from: https://github.com/madmaxieee/nvim-config/blob/main/lua/plugins/mini-diff/make-source.lua

local M = {}

-- ── Cache ─────────────────────────────────────────────────────────────────

---@alias DiffCacheEntry {fs_event:uv.uv_fs_event_t, timer:uv.uv_timer_t, attached?:string}

---@type table<integer, DiffCacheEntry>
local cache = {}

---@param cache_entry DiffCacheEntry?
local function cleanup(cache_entry)
  if cache_entry == nil then return end
  pcall(vim.uv.fs_event_stop, cache_entry.fs_event)
  pcall(vim.uv.timer_stop, cache_entry.timer)
end

-- ── Helpers ───────────────────────────────────────────────────────────────

---@class WatchPattern
---@field dir string
---@field file string

---@type fun(buf: integer, text: string|string[])
local set_ref_text = vim.schedule_wrap(function(buf, text)
  local ok, err = pcall(require("mini.diff").set_ref_text, buf, text)
  if not ok and err then vim.notify(err) end
end)

---@param buf integer
local function get_buf_realpath(buf) return vim.uv.fs_realpath(vim.api.nvim_buf_get_name(buf)) end

---@param buf integer used as the cache key
---@param watch_pattern WatchPattern
---@param callback fun()
local function start_watching(buf, watch_pattern, callback)
  local buf_fs_event = vim.uv.new_fs_event()
  if not buf_fs_event then
    vim.notify("Could not create new_fs_event")
    return
  end

  local timer = vim.uv.new_timer()
  if not timer then
    vim.notify("Could not create new_timer")
    buf_fs_event:stop()
    return
  end

  local debounced_cb = function(err, filename)
    if err then return end
    if watch_pattern.file and filename ~= watch_pattern.file then return end
    timer:stop()
    timer:start(50, 0, callback)
  end
  timer:start(0, 0, callback)

  buf_fs_event:start(watch_pattern.dir, { recursive = false }, debounced_cb)
  cleanup(cache[buf])
  cache[buf].fs_event = buf_fs_event
  cache[buf].timer = timer
end

-- ── Reload ────────────────────────────────────────────────────────────────

--- Disable then re-enable mini.diff for all buffers attached to the named source.
--- Called by utils/jj.lua after changing base_rev so signs recompute.
---@param name string source name (e.g. "jj")
function M.reload_all(name)
  for buf, entry in pairs(cache) do
    if entry.attached == name then
      vim.schedule(function()
        require("mini.diff").disable(buf)
        require("mini.diff").enable(buf)
      end)
    end
  end
end

-- ── Factory ───────────────────────────────────────────────────────────────

---@class DiffSourceOpts
---@field name                  string
---@field should_enable?        fun(): boolean
---@field setup?                fun()
---@field get_root              fun(path: string): string?
---@field root_to_watch_pattern fun(root: string): WatchPattern
---@field async_get_ref_text    fun(path: string, callback: fun(text: string|string[]))

---@param opts DiffSourceOpts
function M.make_diff_source(opts)
  if not opts.should_enable then opts.should_enable = function() return true end end

  local name = opts.name

  if vim.fn.executable(name) ~= 1 or not opts.should_enable() then
    return {
      name = name,
      attach = function() return false end,
      detach = function(_) end,
    }
  end

  if opts.setup then opts.setup() end

  return {
    name = name,

    ---@param buf integer
    attach = function(buf)
      if cache[buf] ~= nil then return false end

      local path = get_buf_realpath(buf)
      if not path then return false end

      local root = opts.get_root(path)
      if not root then return false end

      cache[buf] = { attached = name }

      local watch_pattern = opts.root_to_watch_pattern(root)
      start_watching(buf, watch_pattern, function()
        opts.async_get_ref_text(path, function(text) set_ref_text(buf, text) end)
      end)
    end,

    ---@param buf integer
    detach = function(buf)
      local entry = cache[buf]
      if entry and entry.attached == name then
        cleanup(entry)
        cache[buf] = nil
      end
    end,
  }
end

return M
