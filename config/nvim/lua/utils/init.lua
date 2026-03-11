mega.u = {}
mega.ui = mega.ui or {}

-- Core utilities used by after/plugin/ files

---Check if a value is falsy (nil, false, empty string, empty table)
---@param val any
---@return boolean
function mega.u.falsy(val)
  if val == nil or val == false then return true end
  if type(val) == "string" and val == "" then return true end
  if type(val) == "table" and vim.tbl_isempty(val) then return true end
  return false
end

---Check if a value is empty (nil or empty string)
---@param val any
---@return boolean
function mega.u.empty(val) return val == nil or val == "" end

---Fold/reduce over a table
---@generic T, U
---@param fn fun(acc: U, item: T, index: number): U
---@param tbl T[]
---@param init? U
---@return U
function mega.u.fold(fn, tbl, init)
  local acc = init or {}
  for i, v in ipairs(tbl) do
    acc = fn(acc, v, i)
  end
  return acc
end

---Iterate over a table with a function
---@generic T
---@param fn fun(item: T, index: number)
---@param tbl T[]
function mega.u.foreach(fn, tbl)
  for i, v in ipairs(tbl) do
    fn(v, i)
  end
end

---Protected call with error notification
---@param msg string Error message prefix
---@param fn function Function to call
---@param ... any Arguments
---@return boolean, any
function mega.u.pcall(msg, fn, ...)
  local ok, result = pcall(fn, ...)
  if not ok then vim.schedule(function() vim.notify(msg .. ": " .. tostring(result), vim.log.levels.ERROR) end) end
  return ok, result
end

---Get count of listed buffers
---@return number
function mega.u.get_bufnrs()
  local count = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then count = count + 1 end
  end
  return count
end
---Wrapper around vim.keymap.set that will
---not create a keymap if a lazy key handler exists.
---It will also set `silent` to true by default.
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts vim.keymap.set.Opts?
function mega.u.safe_keymap_set(mode, lhs, rhs, opts)
  if not pcall(require, "lazy.core.handler") then
    vim.keymap.set(mode, lhs, rhs, opts)
    return
  end

  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler

  local modes = type(mode) == "string" and { mode } or mode
  ---@cast modes string[]

  ---@param m string
  modes = vim.tbl_filter(function(m) return not (keys.have and keys:have(lhs, m)) end, modes)

  -- do not create the keymap if a lazy keys handler exists
  if #modes > 0 then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(modes, lhs, rhs, opts)
  end
end

---@param name string
---@param fn fun(name:string)
function mega.u.on_load(name, fn)
  local Config = require("lazy.core.config")
  if Config.plugins[name] and Config.plugins[name]._.loaded then
    fn(name)
  else
    local group_id = vim.api.nvim_create_augroup(("LazyLoad:%s"):format(name), {})
    vim.api.nvim_create_autocmd("User", {
      group = group_id,
      pattern = "LazyLoad",
      callback = function(event)
        if event.data == name then
          vim.api.nvim_del_augroup_by_id(group_id)
          fn(name)
          return true
        end
      end,
    })
  end
end

---@param height_ratio number (0.0 - 1.0)
---@param width_ratio number (0.0 - 1.0)
---@param opts table
function mega.u.float_window_config(height_ratio, width_ratio, opts)
  local screen_w = vim.opt.columns:get()
  local screen_h = vim.opt.lines:get()
  local window_w = screen_w * width_ratio
  local window_h = screen_h * height_ratio
  local window_w_int = math.ceil(window_w)
  local window_h_int = math.ceil(window_h)
  local center_x = (screen_w - window_w) / 2
  local center_y = (vim.opt.lines:get() - window_h) / 2
  return {
    border = opts.border or "rounded",
    relative = opts.relative or "editor",
    winblend = opts.winblend or 0,
    row = center_y,
    col = center_x,
    width = window_w_int,
    height = window_h_int,
  }
end

---remove an item from a list by value
---@param list any[]
---@param value_to_remove any
function mega.u.remove_by_value(list, value_to_remove)
  for i = #list, 1, -1 do -- Iterate backwards!
    if list[i] == value_to_remove then table.remove(list, i) end
  end
end

function mega.u.flatten(tbl) return vim.iter(tbl):flatten():totable() end

function mega.u.set_jumplist_wrap(fn)
  return function(...)
    vim.cmd("normal! m'")
    return fn(...)
  end
end

function mega.u.set_jumplist() vim.cmd("normal! m'") end

---@alias KeymapSpec [string,function,vim.keymap.set.Opts?]
---@class RepeatablePairSpec
---@field next KeymapSpec
---@field prev KeymapSpec

---@param modes string|string[]
---@param specs RepeatablePairSpec
---@param opts? {set_jumplist:boolean?}
function mega.u.map_repeatable_pair(modes, specs, opts)
  opts = opts or {}
  if opts.set_jumplist == nil then opts.set_jumplist = true end
  local repeatable = require("utils.repeatable")
  local next_repeat, prev_repeat = repeatable.make_repeatable_move_pair(specs.next[2], specs.prev[2])
  if opts.set_jumplist then
    next_repeat = mega.u.set_jumplist_wrap(next_repeat)
    prev_repeat = mega.u.set_jumplist_wrap(prev_repeat)
  end
  mega.u.safe_keymap_set(modes, specs.next[1], next_repeat, specs.next[3])
  mega.u.safe_keymap_set(modes, specs.prev[1], prev_repeat, specs.prev[3])
end

mega.u.modes = {
  VisualEnter = "ModeChanged *:[vV\x16]*",
  visual_enter_pattern = "*:[vV\x16]*",
  VisualLeave = "ModeChanged [vV\x16]*:*",
  visual_leave_pattern = "[vV\x16]*:*",
}

require("utils.log")
require("utils.fs")
require("utils.clipboard")
require("utils.repeatable")
require("utils.colors")

return mega.u
