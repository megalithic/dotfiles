_G.mega = mega or {
  ui = {
    colors = {},
    theme = {},
  },
  lsp = {},
}

-- local ok, err = pcall(require, "core")
-- if not ok then
--   function _G.Plugin_enabled(_plugin) return false end
--   vim.notify("Error loading `core.lua`; loading fallback...\n" .. err)
--   vim.cmd.runtime("minvimrc.vim")
-- end

-- _G.mega = setmetatable(mega or {}, {
--   __index = function(t, k)
--     vim.print(t, k)
--     ---@diagnostic disable-next-line: no-unknown
--     t[k] = require("mega." .. k)
--     return rawget(t, k)
--   end,

--   __newindex = function(t, k, v)
--     vim.print(t, k, v)
--     mega[k] = v
--   end,
-- })

local M = {}

vim.fn = vim.fn or {}
M.L = vim.log.levels
M.I = vim.inspect
M.pack_root = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
-- string.format("%s/site/pack/core", vim.fn.stdpath("data"))
M.should_debug = false

function M.version()
  local v = vim.version()
  if v and v.prerelease then
    vim.notify(
      ("neovim build sha#%s"):format(v.build:match(".*g(.*)$")),
      vim.log.levels.WARN,
      { title = "neovim: running dev build" }
    )
  end

  if v and not v.prerelease then
    vim.notify(
      ("neovim v%d.%d.%d"):format(v.major, v.minor, v.patch),
      vim.log.levels.WARN,
      { title = "neovim: not running dev build" }
    )
  end
end

---@alias NotifyOpts {lang?:string, title?:string, level?:number, once?:boolean, stacktrace?:boolean, stacklevel?:number}

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

  local formatter = function(msg)
    return string.format("[%s] %s %s:%s -> %s", "DEBUG", os.date("%H:%M:%S"), mod_name, mod_line, msg)
  end
  M.echom(formatter(vim.inspect(#printables > 1 and printables or unpack(printables))), "Question")

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
  -- vim.schedule_wrap(function()
  local formatter = function(msg)
    return string.format("[%s] %s %s:%s -> %s", "INFO", os.date("%H:%M:%S"), mod_name, mod_line, msg)
  end
  M.echom(formatter(vim.inspect(#printables > 1 and printables or unpack(printables))), "Comment")
  -- end)

  return ...
end

M.icons = require("config.icons")

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

-- Printf wrapper
function M.printf(format_str, ...) vim.print(string.format(format_str, ...)) end

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

--- Same as require() but don't abort on error
--- @param mod string
function M.safe_require(mod)
  --- @diagnostic disable-next-line: no-unknown
  local ok, r = xpcall(require, debug.traceback, mod)
  if not ok then vim.schedule(function() error(r) end) end
end

---@generic R
---@param fn fun():R?
---@param opts? string|{msg:string, on_error:fun(msg)}
---@return R
function M.try_fn(fn, opts)
  opts = type(opts) == "string" and { msg = opts } or opts or {}
  local msg = opts.msg
  -- error handler
  local error_handler = function(err)
    msg = (msg and (msg .. "\n\n") or "") .. err .. M.pretty_trace()
    if opts.on_error then
      opts.on_error(msg)
    else
      vim.schedule(function() M.error(msg) end)
    end
    return err
  end

  ---@type boolean, any
  local ok, result = xpcall(fn, error_handler)
  return ok and result or nil
end

---@param opts? {level?: number}
function M.pretty_trace(opts)
  opts = opts or {}
  local trace = {}
  local level = opts.level or 2
  while true do
    local info = debug.getinfo(level, "Sln")
    if not info then break end
    vim.print(info.what, info.source)
    if info.what ~= "C" and (M.should_debug or not info.source:find("mega_mvim")) then
      local source = info.source:sub(2)
      if source:find(M.pack_root, 1, true) == 1 then source = source:sub(#M.pack_root + 1) end
      source = vim.fn.fnamemodify(source, ":p:~:.") --[[@as string]]
      local line = "  - " .. source .. ":" .. info.currentline
      if info.name then line = line .. " _in_ **" .. info.name .. "**" end
      table.insert(trace, line)
    end
    level = level + 1
  end
  return #trace > 0 and ("\n\n# stacktrace:\n" .. table.concat(trace, "\n")) or ""
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.error(msg, opts)
  opts = opts or {}
  opts.level = vim.log.levels.ERROR
  M.notify(msg, opts)
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.info(msg, opts)
  opts = opts or {}
  opts.level = vim.log.levels.INFO
  M.notify(msg, opts)
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.warn(msg, opts)
  opts = opts or {}
  opts.level = vim.log.levels.WARN
  M.notify(msg, opts)
end

---@param msg string|table
---@param opts? NotifyOpts
function M.debug(msg, opts)
  if not M.should_debug then return end
  opts = opts or {}
  if opts.title then opts.title = "mega_mvim: " .. opts.title end
  if type(msg) == "string" then
    M.notify(msg, opts)
  else
    opts.lang = "lua"
    M.notify(vim.inspect(msg), opts)
  end
end

---@param msg string|string[]
---@param opts? NotifyOpts
function M.notify(msg, opts)
  if vim.in_fast_event() then
    return vim.schedule(function() M.notify(msg, opts) end)
  end

  opts = opts or {}
  if type(msg) == "table" then
    msg = table.concat(vim.tbl_filter(function(line) return line or false end, msg), "\n")
  end
  if opts.stacktrace then msg = msg .. M.pretty_trace({ level = opts.stacklevel or 2 }) end
  local lang = opts.lang or "markdown"
  local n = opts.once and vim.notify_once or vim.notify
  n(msg, opts.level or vim.log.levels.INFO, {
    ft = lang,
    on_open = function(win)
      local ok = pcall(function() vim.treesitter.language.add("markdown") end)
      if not ok then pcall(require, "nvim-treesitter") end
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, lang) then
        vim.bo[buf].filetype = lang
        vim.bo[buf].syntax = lang
      end
    end,
    title = opts.title or "mega_mvim",
  })
end

function vim.dbg(msg, level, _opts)
  if pcall(require, "plenary") then
    local log = require("plenary.log").new({
      plugin = "notify",
      level = level or M.L.DEBUG,
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
      level = M.L.DEBUG,
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
    vim.fn.split(
      ":" .. d.short_src .. ":" .. d.currentline .. ":\n" .. vim.inspect(#{ ... } > 1 and { ... } or ...),
      "\n"
    ),
    "/tmp/nlog",
    "a"
  )
end

function vim.wlogclear() vim.fn.writefile({}, "/tmp/nlog") end

-- Takes a table of keys, returns a keymaps lazy config
vim.fn.get_lazy_keys_conf = function(mappings, desc_prefix)
  return vim.tbl_map(function(mapping)
    local lhs = mapping[1]
    local rhs = mapping[2]
    local desc = desc_prefix and desc_prefix .. ": " .. mapping[3] or mapping[3]
    local opts = mapping[4]
    local mode = opts and opts.mode or "n"
    local expr = opts and opts.expr or false
    local remap = opts and opts.remap or false

    local unique = true
    if opts and opts.unique ~= nil then unique = opts.unique end

    return {
      lhs,
      rhs,
      mode = mode,
      noremap = true,
      unique = unique,
      desc = desc,
      expr = expr,
      remap = remap,
    }
  end, mappings)
end

---@param mod table
---@param fn_str string? | string[]?
---@return table?
function _G.Load_macros(mod, fn_str)
  -- bind these functions to our global `mega` table
  -- if _G.mega == nil then
  --   _G.mega = {}
  -- end

  if fn_str ~= nil then
    if type(fn_str) == "string" then
      _G.mega[fn_str] = mod[fn_str]
      _G[fn_str:gsub("^%l", string.upper)] = mod[fn_str]
    elseif type(fn_str) then
      for _, fn in ipairs(fn_str) do
        _G.mega[fn] = mod[fn]
        _G[fn:gsub("^%l", string.upper)] = mod[fn]
      end
    end
  else
    _G.mega = vim.tbl_extend("force", _G.mega or {}, mod)

    -- bind these functions to _the_ global `_G` as a
    -- capitalized function to denote global scope
    vim.iter(mod):each(function(k, v) _G[k:gsub("^%l", string.upper)] = v end)
  end

  -- local d = debug.getinfo(2)
  -- vim.notify(string.format("Loaded macros for %s", d.short_src), L.INFO)

  return mod
end

---Determines if a given plugin is loaded
---@param plugin string
---@return boolean
-- TODO: derive plugin name automatically
function _G.Plugin_enabled(plugin)
  local debug_info = debug.getinfo(2)
  plugin = plugin ~= nil and plugin or vim.fn.fnamemodify(debug_info.short_src, ":t:r")

  return vim.tbl_contains(vim.g.enabled_plugins, plugin)
end

Load_macros(M)

return M
