local fmt = string.format
local U = require("config.utils")

vim.noti = vim.notify

_G.mega = {
  colors = {},
  enabled_plugins = {
    "abbreviations",
    "megaline",
    "megacolumn",
    -- "megatab",
    "term",
    "lsp",
    "repls",
    "cursorline",
    "colorcolumn",
    "windows",
    "numbers",
    "clipboard",
    "folds",
    "env",
    "notes",
    "filetypes",
  },
  ui = { statusline = {}, statuscolumn = {}, tabline = {} },
  term = nil,
  notify = vim.noti,
}

---@param mod table
---@return table?
function _G.Load_macros(mod)
  -- bind these functions to our global `mega` table
  _G.mega = vim.tbl_extend("force", mega, mod)

  -- bind these functions to _the_ global `_G` as a
  -- capitalized function to denote global scope
  vim.iter(mod):each(function(k, v) _G[k:gsub("^%l", string.upper)] = v end)

  return mod
end

---Determines if a given plugin is loaded
---@param plugin string
---@return boolean
-- TODO: derive plugin name automatically
function _G.Plugin_enabled(plugin)
  local debug_info = debug.getinfo(2)
  plugin = plugin ~= nil and plugin or vim.fn.fnamemodify(debug_info.short_src, ":t:r")

  return vim.tbl_contains(mega.enabled_plugins, plugin)
end

function vim.dbg(msg, level, _opts)
  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = level or "DEBUG",
      use_console = true,
      use_quickfix = false,
      use_file = false,
    })
    vim.schedule_wrap(log.info)(msg)
  else
    vim.schedule_wrap(P)(msg)
  end
end

function vim.pprint(...)
  local s, args = pcall(vim.deepcopy, { ... })
  if not s then args = { ... } end
  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = "debug",
      use_console = true,
      use_quickfix = false,
      use_file = false,
    })
    vim.schedule_wrap(log.info)(vim.inspect(#args > 1 and args or unpack(args)))
  else
    vim.schedule_wrap(vim.notify)(vim.inspect(#args > 1 and args or unpack(args)))
  end
end

function vim.wlog(...)
  if vim.in_fast_event() then return vim.schedule_wrap(vim.wlog)(...) end
  local d = debug.getinfo(2)
  return vim.fn.writefile(
    vim.fn.split(":" .. d.short_src .. ":" .. d.currentline .. ":\n" .. vim.inspect(#{ ... } > 1 and { ... } or ...), "\n"),
    "/tmp/nlog",
    "a"
  )
end

function vim.wlogclear() vim.fn.writefile({}, "/tmp/nlog") end

local M = {}

M.L = vim.log.levels
M.I = vim.inspect

-- Echo a message with optional highlighting and history
function M.echo(msg, hl, history)
  history = history or false
  return vim.api.nvim_echo({ { msg, hl } }, history, {})
end

-- Echo a message with history enabled
function M.echom(msg, hl) return M.echo(msg, hl, true) end

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :P vim.loop
---@vararg any
function M.D(...)
  local debug_info = debug.getinfo(2)
  local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t")
  local mod_line = debug_info.currentline

  local printables = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(printables, vim.inspect(v))
  end

  -- if pcall(require, "plenary") then
  --   local log = require("plenary.log").new({
  --     plugin = "notify",
  --     level = "debug",
  --     use_console = true,
  --     use_quickfix = false,
  --     use_file = false,
  --   })

  --   -- vim.schedule_wrap(log.info)(table.concat(printables, "\n"))
  --   vim.schedule_wrap(log.info)(vim.inspect(#printables > 1 and printables or unpack(printables)))
  -- else
  -- vim.schedule_wrap(print)(table.concat(printables, "\n"))
  -- vim.schedule_wrap(function() print(vim.inspect(#printables > 1 and printables or unpack(printables))) end)
  -- end

  vim.schedule_wrap(function()
    local formatter = function(msg) return string.format("[%s] %s %s:%s -> %s", "DEBUG", os.date("%H:%M:%S"), mod_name, mod_line, msg) end
    M.echom(formatter(vim.inspect(#printables > 1 and printables or unpack(printables))), "Question")
  end)

  return ...
end

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :P vim.loop
---@vararg any
function M.P(...)
  local debug_info = debug.getinfo(2)
  local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t")
  local mod_line = debug_info.currentline

  local printables = {}
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    table.insert(printables, vim.inspect(v))
  end

  -- local formatter = function(msg) return string.format("[%s] %s -> %s", "INFO", os.date("%H:%M:%S"), msg) end
  vim.schedule_wrap(function()
    local formatter = function(msg) return string.format("[%s] %s %s:%s -> %s", "INFO", os.date("%H:%M:%S"), mod_name, mod_line, msg) end
    M.echom(formatter(vim.inspect(#printables > 1 and printables or unpack(printables))), "Comment")
  end)

  return ...
end

-- Map a key in the given mode. Defaults to non-recursive and silent.
function M.keymap(modes, from, to, opts)
  opts = opts or {}

  -- Ensure modes is a table
  if type(modes) == "string" then modes = { modes } end

  -- Handle function callbacks
  local callback = nil
  local cmd = to
  if type(to) == "function" then
    callback = to
    cmd = ""
    -- Set description if not provided
    if not opts.desc then opts.desc = "Custom function" end
  elseif type(to) ~= "string" then
    callback = to
    cmd = ""
    if not opts.desc then opts.desc = tostring(to) end
  end

  -- Set default options
  if opts.noremap == nil then opts.noremap = true end
  if opts.expr and opts.replace_keycodes == nil then opts.replace_keycodes = true end
  if opts.silent == nil then opts.silent = true end

  -- Handle buffer-specific mappings
  local buf = nil
  if opts.buffer == true then
    buf = 0
  elseif type(opts.buffer) == "number" then
    buf = opts.buffer
  end
  opts.buffer = nil

  -- Create mappings for each mode
  for _, mode in ipairs(modes) do
    if callback then
      opts.callback = callback
      vim.keymap.set(mode, from, callback, opts)
    else
      if buf then
        vim.api.nvim_buf_set_keymap(buf, mode, from, cmd, opts)
      else
        vim.api.nvim_set_keymap(mode, from, cmd, opts)
      end
    end
  end
end

-- Create autocmd with optional clearing
local function autocmd_impl(clear, ...)
  local args = { ... }
  local group = nil
  local event, pattern, opts, desc, callback

  -- Parse group if first arg is a string/symbol
  if type(args[1]) == "string" then group = table.remove(args, 1) end

  event = table.remove(args, 1)

  -- Parse pattern if next arg is string or table
  if type(args[1]) == "string" or type(args[1]) == "table" then pattern = table.remove(args, 1) end

  -- Parse options if next arg is table
  opts = {}
  if type(args[1]) == "table" then opts = table.remove(args, 1) end
  opts.group = opts.group or group

  -- Parse description if next arg is string and more args follow
  if type(args[1]) == "string" and #args > 1 then desc = table.remove(args, 1) end

  callback = args[1]

  -- Clear autocmds if requested
  if clear then
    if event == "*" then
      local autocmds = vim.api.nvim_get_autocmds({
        group = opts.group,
        pattern = pattern,
        buffer = opts.buffer,
      })
      for _, autocmd in ipairs(autocmds) do
        vim.api.nvim_del_autocmd(autocmd.id)
      end
    else
      vim.api.nvim_clear_autocmds({
        event = event,
        group = opts.group,
        pattern = pattern,
        buffer = opts.buffer,
      })
    end
  end

  -- Create autocmd if callback provided
  if callback then
    if opts.group and not clear then vim.api.nvim_create_augroup(opts.group, { clear = false }) end

    vim.api.nvim_create_autocmd(event, {
      group = opts.group,
      pattern = pattern,
      desc = desc or (type(callback) == "function" and "Custom function" or nil),
      command = type(callback) == "string" and callback or nil,
      callback = type(callback) ~= "string" and callback or nil,
      buffer = opts.buffer,
      once = opts.once,
      nested = opts.nested,
    })
  end
end

-- Create autocmd without clearing
function M.autocmd(...) return autocmd_impl(false, ...) end

-- Create autocmd with clearing
function M.autocmd_clear(...) return autocmd_impl(true, ...) end

-- Create augroup with optional clearing
local function augroup_impl(clear, group, ...)
  local args = { ... }

  if clear and #args == 0 then
    vim.api.nvim_del_augroup_by_name(tostring(group))
  else
    vim.api.nvim_create_augroup(tostring(group), { clear = clear })
    -- Execute any additional forms
    for _, form in ipairs(args) do
      if type(form) == "function" then form() end
    end
  end
end

-- -- Create augroup without clearing
-- function M.augroup(group, ...)
--   return augroup_impl(false, group, ...)
-- end

-- -- Create augroup with clearing
-- function M.augroup_clear(group, ...)
--   return augroup_impl(true, group, ...)
-- end

---@class Autocommand
---@field desc string
---@field event  string[] list of autocommand events
---@field pattern string[] list of autocommand patterns
---@field command string | function
---@field nested  boolean
---@field once    boolean
---@field buffer  number
---@field enabled boolean

---Create an autocommand
---returns the group ID so that it can be cleared or manipulated.
---@param name string
---@param ... Autocommand A list of autocommands to create (variadic parameter)
---@return number
function M.augroup(name, commands)
  --- Validate the keys passed to mega.augroup are valid
  ---@param name string
  ---@param cmd Autocommand
  local function validate_autocmd(name, cmd)
    local keys = { "event", "buffer", "pattern", "desc", "callback", "command", "group", "once", "nested", "enabled" }
    local incorrect = U.fold(function(accum, _, key)
      if not vim.tbl_contains(keys, key) then table.insert(accum, key) end
      return accum
    end, cmd, {})
    if #incorrect == 0 then return end
    local debug_info = debug.getinfo(2)
    local mod_name = vim.fn.fnamemodify(debug_info.short_src, ":t:r")
    local mod_line = debug_info.currentline

    vim.schedule(
      function()
        vim.notify("Incorrect keys: " .. table.concat(incorrect, ", "), vim.log.levels.ERROR, {
          title = fmt("Autocmd: %s", name),
        })
      end
    )
  end

  assert(name ~= "User", "The name of an augroup CANNOT be User")

  local auname = fmt("mega-%s", name)
  local id = vim.api.nvim_create_augroup(auname, { clear = true })

  for _, autocmd in ipairs(commands) do
    if autocmd.enabled == nil or autocmd.enabled == true then
      validate_autocmd(name, autocmd)
      local is_callback = type(autocmd.command) == "function"
      vim.api.nvim_create_autocmd(autocmd.event, {
        group = id,
        pattern = autocmd.pattern,
        desc = autocmd.desc,
        callback = is_callback and autocmd.command or nil,
        command = not is_callback and autocmd.command or nil,
        once = autocmd.once,
        nested = autocmd.nested,
        buffer = autocmd.buffer,
      })
    end
  end

  return id
end

-- Create user command
function M.command(cmd, func, opts)
  opts = opts or {}

  local bufnr = nil
  if opts.buffer == true then
    bufnr = 0
  elseif type(opts.buffer) == "number" then
    bufnr = opts.buffer
  end
  opts.buffer = nil

  if bufnr then
    vim.api.nvim_buf_create_user_command(bufnr, cmd, func, opts)
  else
    vim.api.nvim_create_user_command(cmd, func, opts)
  end
end

function M.with_module(module_name, func)
  local ok, module = pcall(require, module_name)
  if ok then return func(module) end
end

-- Safely execute code with a module binding
function M.prequire(mod_name, ...)
  local ok, mod = pcall(require, mod_name, ...)
  if ok then
    -- if fn ~= nil then
    --   return fn(mod)
    -- else
    return mod
    -- end
  else
    vim.notify_once(string.format("Missing module: %s", mod), vim.log.levels.WARN)

    return nil
  end
end

-- --- Call the given function and use `vim.notify` to notify of any errors
-- --- this function is a wrapper around `xpcall` which allows having a single
-- --- error handler for all errors
-- ---@param msg string
-- ---@param func function
-- ---@param ... any
-- ---@return boolean, any
-- ---@overload fun(func: function, ...): boolean, any
-- function M.pcall(msg, func, ...)
--   local args = { ... }

--   if type(msg) == "function" then
--     local arg = func --[[@as any]]
--     args, func, msg = { arg, unpack(args) }, msg, nil
--   end

--   return xpcall(func, function(err)
--     msg = debug.traceback(msg and fmt("%s:\n%s\n%s", msg, vim.inspect(args), err) or err)
--     vim.schedule(function() vim.notify_once(msg, L.ERROR, { title = "ERROR", render = "default" }) end)
--   end, unpack(args))
-- end

-- XPCALL example:
-- function _M.load_module_if_exists(module_name)
--   local status, res = xpcall(function()
--     return require(module_name)
--   end, debug.traceback)
--   if status then
--     return true, res
--   -- Here we match any character because if a module has a dash '-' in its name, we would need to escape it.
--   elseif type(res) == "string" and find(res, "module '" .. module_name .. "' not found", nil, true) then
--     return false, res
--   else
--     error("error loading module '" .. module_name .. "':\n" .. res)
--   end
-- end
--

-- --- Call the given function and use `vim.notify` to notify of any errors
-- --- this function is a wrapper around `xpcall` which allows having a single
-- --- error handler for all errors
-- ---@param msg string
-- ---@param func function
-- ---@vararg any
-- ---@return boolean, any
-- ---@overload fun(fun: function, ...): boolean, any
-- function M.wrap_err(msg, func, ...) return M.pcall(msg, func, ...) end

-- Printf wrapper
function M.printf(format_str, ...) print(string.format(format_str, ...)) end

-- Execute code silently (suppress print output)
function M.silent(func)
  local old_print = _G.print
  _G.print = function() end
  local result = func()
  _G.print = old_print
  return result
end

-- Execute vim command
function M.exec(cmd) vim.api.nvim_exec2(cmd, {}) end

Load_macros(M)

return M
