local api = vim.api
local fn = vim.fn
local vcmd = vim.cmd
local L = vim.log.levels

_G.I = vim.inspect
_G.fmt = string.format
_G.logger = require("mega.logger")

-- [ global variables ] --------------------------------------------------------

local function get_hostname()
  local hostname = ""
  local handle = io.popen("hostname")

  if handle then
    hostname = handle:read("*l")
    handle:close()
  end

  return hostname
end

vim.g.os = vim.loop.os_uname().sysname
vim.g.is_macos = vim.g.os == "Darwin"
vim.g.is_linux = vim.g.os == "Linux"
vim.g.is_windows = vim.g.os == "Windows"
vim.g.is_work = get_hostname() == "seth-dev"

vim.g.is_remote_dev = vim.trim(vim.fn.system("hostname")) == "seth-dev"
vim.g.is_local_dev = vim.trim(vim.fn.system("hostname")) ~= "seth-dev"

vim.g.open_command = vim.g.is_macos and "open" or "xdg-open"

vim.g.dotfiles = vim.env.DOTS or fn.expand("~/.dotfiles")
vim.g.home = os.getenv("HOME")
vim.g.vim_path = fmt("%s/.config/nvim", vim.g.home)
vim.g.cache_path = fmt("%s/.cache/nvim", vim.g.home)
vim.g.local_state_path = fmt("%s/.local/state/nvim", vim.g.home)
vim.g.local_share_path = fmt("%s/.local/share/nvim", vim.g.home)

mega.dirs.dots = vim.g.dotfiles
mega.dirs.privates = fn.expand("$PRIVATES")
mega.dirs.code = fn.expand("$HOME/code")
mega.dirs.icloud = fn.expand("$ICLOUD_DIR")
mega.dirs.docs = fn.expand("$DOCUMENTS_DIR")
mega.dirs.org = fn.expand(mega.dirs.docs .. "/_org")
mega.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")
mega.dirs.zk = mega.dirs.zettel

-- [ runtimepath (rtp) ] -------------------------------------------------------

vim.opt.runtimepath:remove("~/.cache")
vim.opt.runtimepath:remove("~/.local/share/src")

-- [ utils ] -------------------------------------------------------------------

-- TODO:
-- https://www.reddit.com/r/neovim/comments/xv3v68/tip_nvimnotify_can_be_used_to_display_print/
-- https://github.com/kassio/dotfiles/tree/main/config/xdg/nvim/lua/my/utils

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  if not vim.g.debug_enabled then return end
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  if pcall(require, "plenary") then
    local p_logger = logger.new({ level = "debug" })
    p_logger.info(table.concat(objects, "\n"))
  else
    print(...)
  end

  return ...
end

function _G.PT(tbl, indent)
  if not vim.g.debug_enabled then return end

  if not indent then indent = 2 end
  for k, v in pairs(tbl) do
    local formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      _G.PT(v, indent + 1)
    elseif type(v) == "boolean" then
      print(formatting .. tostring(v))
    else
      print(formatting .. v)
    end
  end
end

function _G.dump(...)
  if not vim.g.debug_enabled then return end

  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end

_G.Path = {
  join = function(...) return table.concat({ ... }, "/") end,
  relative = function(path) return vim.fn.fnamemodify(path, ":~:.") end,
}

_G.Clipboard = {
  copy = function(str) vim.fn.jobstart(string.format("echo -n %q | pbcopy", str), { detach = true }) end,
}

function mega.dump_colors(filter)
  local defs = {}
  for hl_name, hl in pairs(vim.api.nvim__get_hl_defs(0)) do
    if hl_name:find(filter) then
      local def = {}
      if hl.link then def.link = hl.link end
      for key, def_key in pairs({ foreground = "fg", background = "bg", special = "sp" }) do
        if type(hl[key]) == "number" then
          local hex = fmt("#%06x", hl[key])
          def[def_key] = hex
        end
      end
      for _, style in pairs({ "bold", "italic", "underline", "undercurl", "reverse" }) do
        if hl[style] then def.style = (def.style and (def.style .. ",") or "") .. style end
      end
      defs[hl_name] = def
    end
  end
  dump(defs)
end

local installed
---Check if a plugin is on the system; whether or not it is loaded
---@param plugin_name string
---@return boolean
function mega.plugin_installed(plugin_name)
  if not installed then
    local dirs = fn.expand(fn.stdpath("data") .. "/site/pack/paqs/start/*", true, true)
    local opt = fn.expand(fn.stdpath("data") .. "/site/pack/paqs/opt/*", true, true)
    vim.list_extend(dirs, opt)
    installed = vim.tbl_map(function(path) return fn.fnamemodify(path, ":t") end, dirs)
  end
  return vim.tbl_contains(installed, plugin_name)
end

function mega.plugin_loaded(plugin_name)
  local plugins = package.loaded or {}
  return plugins[plugin_name] ~= nil and package.preload[plugin_name] ~= nil
end

-- TODO: would like to add ability to gather input for continuing; ala `jordwalke/VimAutoMakeDirectory`
function mega.auto_mkdir()
  local dir = fn.expand("%:p:h")

  if fn.isdirectory(dir) == 0 then
    local create_dir = fn.input(fmt("[?] Parent dir [%s] doesn't exist; create it? (y/n) ", dir))
    if create_dir == "y" or create_dir == "yes" then
      fn.mkdir(dir, "p")
      vim.cmd("bufdo e!")
      vim.cmd("e!")
      vim.cmd("redraw!")
    end
  end
end

function mega.get_log_string(label, level)
  local display_level = "[DEBUG]"
  local hl = "Todo"

  if level ~= nil then
    if level == L.ERROR then
      display_level = "[ERROR]"
      hl = "ErrorMsg"
    elseif level == L.WARN then
      display_level = "[WARNING]"
      hl = "WarningMsg"
    end
  end

  local str = fmt("%s %s", display_level, label)

  return str, hl
end

function mega.opt(o, v, scopes)
  scopes = scopes or { vim.o }
  for _, s in ipairs(scopes) do
    s[o] = v
  end
end

---Require a module using `pcall` and report any errors
---@param module string | table
---@param opts table?
---@return boolean, any
function mega.require(module, opts)
  -- local function pc(func, ...)
  --   local args = { ... }
  --   return xpcall(func and function() return func(unpack(args)) end, function(err)
  --     if err:find("DevIcon") or err:find("mason") or err:find("Invalid highlight") then return err end
  --     vim.api.nvim_echo({ { err, "ErrorMsg" }, { debug.traceback("", 3), "Normal" } }, true, {})
  --     return err
  --   end)
  -- end

  opts = opts or { silent = true }
  local ok, result = pcall(require, module)
  if not ok and not opts.silent then
    if opts.message then result = opts.message .. "\n" .. result end
    vim.notify(result, vim.log.levels.ERROR, { title = fmt("Error requiring: %s", module) })
  end
  return ok, result
end

--- Call the given function and use `vim.notify` to notify of any errors
--- this function is a wrapper around `xpcall` which allows having a single
--- error handler for all errors
---@param msg string|nil
---@param func function
---@vararg any
---@return boolean, any
---@overload fun(fun: function, ...): boolean, any
function mega.wrap_err(msg, func, ...)
  local args = { ... }
  if type(msg) == "function" then
    args, func, msg = { func, unpack(args) }, msg, nil
  end
  return xpcall(func, function(err)
    msg = msg and fmt("%s:\n%s", msg, err) or err
    vim.schedule(function() vim.notify(msg, L.ERROR, { title = "ERROR" }) end)
  end, unpack(args))
end

-- ---@alias Plug table<(string | number), string>

--- A convenience wrapper that calls the ftplugin config for a plugin if it exists
--- and warns me if the plugin is not installed
--- TODO: find out if it's possible to annotate the plugin as a module
---@param name string
-- ---@param name string | Plug
---@param callback fun(module: table) | fun()
function mega.ftplugin_conf(name, callback)
  local plugin_name = type(name) == "table" and name.plugin or nil
  if plugin_name and not mega.plugin_loaded(plugin_name) then return end

  local module = type(name) == "table" and name[1] or name
  local info = debug.getinfo(1, "S")
  local ok, plugin = mega.require(module, { message = fmt("In file: %s", info.source) })

  if ok and plugin then
    callback(plugin)
  else
    callback()
  end
end

-- function mega.plugin_setup(plugin_name, setup_tbl)
--   local ok, plugin = mega.require(plugin_name)
--   import(plugin_name, function(module) module.setup(setup_tbl) end)
-- end

--- @class ConfigOpts
--- @field config table|function|string
--- @field enabled? boolean
--- @field silent? boolean
--- @field test? boolean
--- @field event? table

---Wraps common plugin `setup` functionality; primarily for use with paq-nvim.
---@param plugin_conf_name string
---@param opts ConfigOpts|function
function mega.conf(plugin_conf_name, opts)
  opts = opts or {}
  local config
  local enabled = false
  local silent = true
  local defer = false
  local fn_at_index = nil

  if type(opts) == "table" then
    -- config props go straight to the plugin setup
    if vim.tbl_isempty(opts) then
      config = {}
    elseif opts.config ~= nil then
      config = opts.config
    else
      config = opts
    end

    for index, value in ipairs(opts) do
      if type(value) == "function" then
        fn_at_index = index

        if not silent then P(fmt("function found at index %d!", index)) end
        config = opts[fn_at_index]
      end
    end

    -- enabled and silent props are taken raw from the opts table and used for plugin setup things
    enabled = (opts.enabled == nil) and true or opts.enabled
    silent = (opts.silent == nil) and true or opts.silent
    defer = (opts.defer == nil) and false or opts.defer

    if not silent then P(fmt("%s (config table): %s", plugin_conf_name, vim.inspect(config))) end
  elseif type(opts) == "function" then
    config = opts
    enabled = true
    silent = true
  elseif fn_at_index ~= nil then
    config = opts[fn_at_index]
    enabled = true
    silent = true
  end

  if not enabled and not silent then P(plugin_conf_name .. " is disabled.") end

  if enabled then
    if type(config) == "table" then
      -- local ok, loader = pcall(require, plugin_conf_name)
      -- if not ok then
      --   -- vim.notify(fmt("Loader %s not found.", plugin_conf_name), "ERROR")
      --   return
      -- end

      local loader = require(plugin_conf_name)

      -- does it have a setup key to execute?
      if vim.tbl_get(loader, "setup") ~= nil then
        if not silent then P(fmt("%s configuring with `setup(config)`", plugin_conf_name)) end

        if defer then
          vim.defer_fn(function() loader.setup(config) end, 0)
        else
          loader.setup(config)
        end
      end
      -- config was passed a function, so we're assuming we want to bypass the plugin auto-invoking, and invoke our own fn
    elseif type(config) == "function" then
      -- passes the loaded plugin back to the caller so they can do more config
      if not silent then P(fmt("%s configuring with `config(loader)`", plugin_conf_name)) end

      if defer then
        vim.defer_fn(function() config() end, 0)
        -- vim.defer_fn(function() mega.ftplugin_conf(plugin_conf_name, config) end, 0)
      else
        config()
        -- mega.ftplugin_conf(plugin_conf_name, config)
      end
    end

    fn_at_index = nil
  end
end

--- @class CommandArgs
--- @field args string
--- @field fargs table
--- @field bang boolean,

---Create an nvim command
---@param name any
---@param rhs string|fun(args: CommandArgs)
---@param opts? table
function mega.command(name, rhs, opts)
  opts = opts or {}
  api.nvim_create_user_command(name, rhs, opts)
end

---check if a mapping already exists
---@param lhs string
---@param mode string
---@return boolean
function mega.has_map(lhs, mode)
  mode = mode or "n"
  return vim.fn.maparg(lhs, mode) ~= ""
end

--[[
╭────────────────────────────────────────────────────────────────────────────╮
│  Str  │  Help page   │  Affected modes                           │  VimL   │
│────────────────────────────────────────────────────────────────────────────│
│  ''   │  mapmode-nvo │  Normal, Visual, Select, Operator-pending │  :map   │
│  'n'  │  mapmode-n   │  Normal                                   │  :nmap  │
│  'v'  │  mapmode-v   │  Visual and Select                        │  :vmap  │
│  's'  │  mapmode-s   │  Select                                   │  :smap  │
│  'x'  │  mapmode-x   │  Visual                                   │  :xmap  │
│  'o'  │  mapmode-o   │  Operator-pending                         │  :omap  │
│  '!'  │  mapmode-ic  │  Insert and Command-line                  │  :map!  │
│  'i'  │  mapmode-i   │  Insert                                   │  :imap  │
│  'l'  │  mapmode-l   │  Insert, Command-line, Lang-Arg           │  :lmap  │
│  'c'  │  mapmode-c   │  Command-line                             │  :cmap  │
│  't'  │  mapmode-t   │  Terminal                                 │  :tmap  │
╰────────────────────────────────────────────────────────────────────────────╯
--]]

---create a mapping function factory
---@param mode string
---@param o table
---@return fun(lhs: string, rhs: string|function, opts: table|nil) 'create a mapping'
local function mapper(mode, o)
  -- copy the opts table as extends will mutate the opts table passed in otherwise
  local parent_opts = vim.deepcopy(o)
  ---Create a mapping
  ---@param lhs string
  ---@param rhs string|function
  ---@param opts table
  return function(lhs, rhs, opts)
    -- If the label is all that was passed in, set the opts automagically
    opts = type(opts) == "string" and { label = opts } or opts and vim.deepcopy(opts) or {}
    if opts.label or opts.desc then
      -- local ok, wk = mega.require("which-key", { silent = true })
      -- if ok then wk.register({ [lhs] = opts.label or opts.desc }, { mode = mode }) end
      if opts.label and not opts.desc then opts.desc = opts.label end
      opts.label = nil
    end

    if rhs == nil then P(mode, lhs, rhs, opts, parent_opts) end

    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("keep", opts, parent_opts))
  end
end

local map_opts = { remap = true, silent = true }
local noremap_opts = { remap = false, silent = true }

-- TODO: https://github.com/b0o/nvim-conf/blob/main/lua/user/mappings.lua#L19-L37

for _, mode in ipairs({ "n", "x", "i", "v", "o", "t", "s", "c" }) do
  -- {
  -- n = "normal",
  -- v = "visual",
  -- s = "select",
  -- x = "visual & select",
  -- i = "insert",
  -- o = "operator",
  -- t = "terminal",
  -- c = "command",
  -- }

  -- recursive global mappings
  mega[mode .. "map"] = mapper(mode, map_opts)
  _G[mode .. "map"] = mega[mode .. "map"]
  -- non-recursive global mappings
  mega[mode .. "noremap"] = mapper(mode, noremap_opts)
  _G[mode .. "noremap"] = mega[mode .. "noremap"]
end

--- Validate the keys passed to as.augroup are valid
---@param name string
---@param cmd Autocommand
local function validate_autocmd(name, cmd)
  local keys = { "event", "buffer", "pattern", "desc", "command", "group", "once", "nested" }
  local incorrect = mega.fold(function(accum, _, key)
    if not vim.tbl_contains(keys, key) then table.insert(accum, key) end
    return accum
  end, cmd, {})
  if #incorrect == 0 then return end
  vim.schedule(
    function()
      vim.notify("Incorrect keys: " .. table.concat(incorrect, ", "), vim.log.levels.ERROR, {
        title = fmt("Autocmd: %s", name),
      })
    end
  )
end

---@class Autocommand
---@field desc string
---@field event  string[] list of autocommand events
---@field pattern string[] list of autocommand patterns
---@field command string | function
---@field nested  boolean
---@field once    boolean
---@field buffer  number
---Create an autocommand
---returns the group ID so that it can be cleared or manipulated.
---@param name string
---@param commands Autocommand[]
---@return number
function mega.augroup(name, commands)
  assert(name ~= "User", "The name of an augroup CANNOT be User")

  local id = vim.api.nvim_create_augroup(name, { clear = true })

  for _, autocmd in ipairs(commands) do
    validate_autocmd(name, autocmd)
    local is_callback = type(autocmd.command) == "function"
    api.nvim_create_autocmd(autocmd.event, {
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

  return id
end

--- TODO eventually move to using `nvim_set_hl`
--- however for the time being that expects colors
--- to be specified as rgb not hex
---@param name string
---@param opts table
function mega.highlight(name, opts)
  local force = opts.force or true
  if name and vim.tbl_count(opts) > 0 then
    if opts.link and opts.link ~= "" then
      vcmd("highlight" .. (force and "!" or "") .. " link " .. name .. " " .. opts.link)
    else
      local hi_opt = { "highlight", name }
      if opts.guifg and opts.guifg ~= "" then table.insert(hi_opt, "guifg=" .. opts.guifg) end
      if opts.guibg and opts.guibg ~= "" then table.insert(hi_opt, "guibg=" .. opts.guibg) end
      if opts.gui and opts.gui ~= "" then table.insert(hi_opt, "gui=" .. opts.gui) end
      if opts.guisp and opts.guisp ~= "" then table.insert(hi_opt, "guisp=" .. opts.guisp) end
      if opts.cterm and opts.cterm ~= "" then table.insert(hi_opt, "cterm=" .. opts.cterm) end
      vcmd(table.concat(hi_opt, " "))
    end
  end
end
mega.hi = mega.highlight

function mega.hi_link(src, dest) vcmd("hi! link " .. src .. " " .. dest) end

function mega.exec(c, bool)
  bool = bool or true
  api.nvim_exec(c, bool)
end

function mega.noop() end

---A terser proxy for `nvim_replace_termcodes`
---@param str string
---@return any
function mega.replace_termcodes(str) return api.nvim_replace_termcodes(str, true, true, true) end

-- essentially allows for a ternary operator of sorts
function mega._if(bool, a, b)
  if bool then
    return a
  else
    return b
  end
end

function mega.table_merge(t1, t2, opts)
  opts = opts or { strategy = "deep" }

  if opts.strategy == "deep" then
    -- # deep_merge:
    for k, v in pairs(t2) do
      if (type(v) == "table") and (type(t1[k] or false) == "table") then
        mega.table_merge(t1[k], t2[k])
      else
        t1[k] = v
      end
    end
  else
    -- # shallow_merge:
    for k, v in pairs(t2) do
      t1[k] = v
    end
  end

  return t1
end

function mega.deep_merge(t1, t2) mega.table_merge(t1, t2, { strategy = "deep" }) end

function mega.shallow_merge(t1, t2) mega.table_merge(t1, t2, { strategy = "shallow" }) end

function mega.iter(list_or_iter)
  if type(list_or_iter) == "function" then return list_or_iter end

  return coroutine.wrap(function()
    for i = 1, #list_or_iter do
      coroutine.yield(list_or_iter[i])
    end
  end)
end

function mega.reduce(list, memo, func)
  for i in mega.iter(list) do
    memo = func(memo, i)
  end
  return memo
end

-- helps with nerdfonts usages
local bytemarkers = { { 0x7FF, 192 }, { 0xFFFF, 224 }, { 0x1FFFFF, 240 } }
function mega.utf8(decimal)
  if decimal < 128 then return string.char(decimal) end
  local charbytes = {}
  for bytes, vals in ipairs(bytemarkers) do
    if decimal <= vals[1] then
      for b = bytes + 1, 2, -1 do
        local mod = decimal % 64
        decimal = (decimal - mod) / 64
        charbytes[b] = string.char(128 + mod)
      end
      charbytes[1] = string.char(vals[2] + decimal)
      break
    end
  end
  return table.concat(charbytes)
end

function mega.has(feature) return fn.has(feature) > 0 end

function mega.executable(e) return fn.executable(e) > 0 end

local function open(path)
  fn.jobstart({ vim.g.open_command, path }, { detach = true })
  vim.notify(fmt("Opening %s", path))
end

-- open URI under cursor
function mega.open_uri()
  local file = fn.expand("<cfile>")
  if fn.isdirectory(file) > 0 then return vim.cmd("edit " .. file) end
  if file:match("http[s]?://") then return open(file) end
  -- Any URI with a protocol segment
  local protocol_uri_regex = "%a*:%/%/[%a%d%#%[%]%-%%+:;!$@/?&=_.,~*()]*"
  if file:match(protocol_uri_regex) then return vim.cmd("norm! gf") end

  -- consider anything that looks like string/string a github link
  local plugin_url_regex = "[%a%d%-%.%_]*%/[%a%d%-%.%_]*"
  local link = string.match(file, plugin_url_regex)
  if link then return open(fmt("https://www.github.com/%s", link)) end
  -- local Job = require("plenary.job")
  -- local uri = vim.fn.expand("<cWORD>")
  -- Job
  --   :new({
  --     "open",
  --     uri,
  --   })
  --   :sync()
end

function mega.open_plugin_url()
  mega.nnoremap("gf", function()
    local repo = fn.expand("<cfile>")
    if repo:match("https://") then return vim.cmd("norm gx") end
    if not repo or #vim.split(repo, "/") ~= 2 then return vim.cmd("norm! gf") end
    local url = fmt("https://www.github.com/%s", repo)
    fn.jobstart(fmt("%s %s", vim.g.open_command, url))
    vim.notify(fmt("Opening %s at %s", repo, url))
  end)
end

-- Open one or more man pages
-- Accepts a string representing how to open the man pages, one of:
--   - ''        - current window
--   - 'split'   - new horizontal split
--   - 'vsplit'  - new vertical split
--   - 'tab'     - new tab
-- Varargs should be strings of the format
--   <manpage>
-- or
--   <section> <manpage>
function mega.man(dest, ...)
  if dest == "tab" then dest = "tabnew" end
  if dest ~= "" then dest = dest .. " | " end
  for _, page in ipairs({ ... }) do
    if vim.regex("^\\d\\+p\\? \\w\\+$"):match_str(page) ~= nil then
      local s = vim.split(page, " ")
      page = ("%s(%s)"):format(s[2], s[1])
    end
    local prefix = dest
    if vim.fn.bufname(0) == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then prefix = "" end
    vim.cmd(prefix .. "file " .. page .. " | call man#read_page(\"" .. page .. "\")")
  end
end

-- https://www.reddit.com/r/neovim/comments/nrz9hp/can_i_close_all_floating_windows_without_closing/h0lg5m1/
function mega.close_float_wins()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then vim.api.nvim_win_close(win, false) end
  end
end

-- Open a Help topic
--  - If a blank buffer is focused, open it there
--  - Otherwise, open in a new tab
function mega.help(...)
  for _, topic in ipairs({ ... }) do
    if vim.fn.bufname() == "" and vim.api.nvim_buf_line_count(0) == 1 and vim.fn.getline(1) == "" then
      local win = vim.api.nvim_get_current_win()
      vim.cmd("help")
      vim.api.nvim_win_close(win, false)
    else
      vim.cmd("tab help " .. topic)
    end
  end
end

---Source a lua or vimscript file
---@param path string path relative to the nvim directory
---@param prefix boolean?
function mega.source(path, prefix)
  if not prefix then
    vim.cmd(fmt("source %s", path))
  else
    vim.cmd(fmt("source %s/%s", vim.g.vim_dir, path))
  end
end

---Reload lua modules
---@param path string
---@param recursive boolean
function mega.invalidate(path, recursive)
  if recursive then
    for key, value in pairs(package.loaded) do
      if key ~= "_G" and value and fn.match(key, path) ~= -1 then
        package.loaded[key] = nil
        require(key)
      end
    end
  else
    package.loaded[path] = nil
    require(path)
  end
end

function mega.save_and_exec()
  if vim.bo.filetype == "vim" then
    vcmd("silent! write")
    vcmd("source %")
    vim.notify("wrote and sourced vim file..", vim.log.levels.INFO, { title = "nvim" })
  elseif vim.bo.filetype == "lua" then
    vcmd("silent! write")
    vcmd("luafile %")
    vim.notify("wrote and sourced lua file..", vim.log.levels.INFO, { title = "nvim" })
  end
end

---Find an item in a list
---@generic T
---@param matcher fun(arg: T):boolean
---@param haystack T[]
---@return T
function mega.find(matcher, haystack)
  local found
  for _, needle in ipairs(haystack) do
    if matcher(needle) then
      found = needle
      break
    end
  end
  return found
end

---Check whether or not the location or quickfix list is open
---@return boolean
function mega.is_vim_list_open()
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    local location_list = fn.getloclist(0, { filewinid = 0 })
    local is_loc_list = location_list.filewinid > 0
    if vim.bo[buf].filetype == "qf" or is_loc_list then return true end
  end
  return false
end

---Determine if a value of any type is empty
---@param item any
---@return boolean
function mega.empty(item)
  if not item then return true end
  local item_type = type(item)
  if item_type == "string" then
    return item == ""
  elseif item_type == "number" then
    return item <= 0
  elseif item_type == "table" then
    return vim.tbl_isempty(item)
  end
end

function mega.zetty(args)
  local default_opts = {
    cmd = "meeting",
    action = "edit",
    title = "",
    notebook = "",
    tags = "",
    attendees = "",
  }

  local opts = vim.tbl_extend("force", default_opts, args or {})

  local title = fmt([[%s]], string.gsub(opts.title, "|", "&"))

  local content = ""

  if opts.attendees ~= nil and opts.attendees ~= "" then content = fmt("Attendees:\n%s\n\n---\n", opts.attendees) end

  local changed_title = fn.input(fmt("[?] Change title from [%s] to: ", title))
  if changed_title ~= "" then title = changed_title end

  if opts.cmd == "meeting" then
    require("zk.command").new({ title = title, action = "edit", notebook = "meetings", content = content })
  elseif opts.cmd == "new" then
    require("zk.command").new({ title = title, action = "edit" })
  end
end

function mega.get_num_entries(iter)
  local i = 0
  for _ in iter do
    i = i + 1
  end
  return i
end

function mega.get_border(hl)
  local border = {}
  for _, char in ipairs(mega.icons.border.squared) do
    table.insert(border, { char, hl or "FloatBorder" })
  end

  return border
end

function mega.sync_plugins()
  require("mega.plugins.utils").notify("syncing plugins..")
  package.loaded["mega.plugins"] = nil
  vim.cmd("PackerSync")
end

function mega.list_plugins()
  package.loaded["mega.plugins"] = nil
  require("mega.plugins").list()
end

--- Usage:
--- 1. Call `local stop = utils.profile('my-log')` at the top of the file
--- 2. At the bottom of the file call `stop()`
--- 3. Restart neovim, the newly created log file should open
function mega.profile(filename)
  local base = "/tmp/config/profile/"
  fn.mkdir(base, "p")
  local success, profile = pcall(require, "plenary.profile.lua_profiler")
  if not success then vim.api.nvim_echo({ "Plenary is not installed.", "Title" }, true, {}) end
  profile.start()
  return function()
    profile.stop()
    local logfile = base .. filename .. ".log"
    profile.report(logfile)
    vim.defer_fn(function() vcmd("tabedit " .. logfile) end, 1000)
  end
end

function mega.showCursorHighlights()
  vim.cmd("TSHighlightCapturesUnderCursor")
  -- local ft = vim.bo.filetype
  -- local is_ts_enabled = require("nvim-treesitter.configs").is_enabled("highlight", ft)
  --   and require("nvim-treesitter.configs").is_enabled("playground", ft)
  -- if is_ts_enabled then
  --   -- require("nvim-treesitter-playground.hl-info").show_hl_captures()
  --   vim.cmd("TSHighlightCapturesUnderCursor")
  -- else
  --   local synstack = vim.fn.synstack(vim.fn.line("."), vim.fn.col("."))
  --   local lmap = vim.fn.map(synstack, "synIDattr(v:val, \"name\")")
  --   vim.notify(vim.fn.join(vim.fn.reverse(lmap), " "))
  -- end
end

mega.nightly = mega.has("nvim-0.7")

function mega.debounce(ms, fn)
  local timer = vim.loop.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

function mega.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  return function(...)
    if not running then
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function()
        running = false
        pcall(vim.schedule_wrap(fn), unpack(argv, 1, argc))
      end)
      running = true
    end
  end
end

--- Debounces a function on the trailing edge. Automatically
--- `schedule_wrap()`s.
---
-- @param fn (function) Function to debounce
-- @param timeout (number) Timeout in ms
-- @param first (boolean, optional) Whether to use the arguments of the first
---call to `fn` within the timeframe. Default: Use arguments of the last call.
-- @returns (function, timer) Debounced function and timer. Remember to call
---`timer:close()` at the end or you will leak memory!
function mega.debounce_trailing(func, ms, first)
  local timer = vim.loop.new_timer()
  local wrapped_fn

  if not first then
    function wrapped_fn(...)
      local argv = { ... }
      local argc = select("#", ...)

      timer:start(ms, 0, function() pcall(vim.schedule_wrap(func), unpack(argv, 1, argc)) end)
    end
  else
    local argv, argc
    function wrapped_fn(...)
      argv = argv or { ... }
      argc = argc or select("#", ...)

      timer:start(ms, 0, function() pcall(vim.schedule_wrap(func), unpack(argv, 1, argc)) end)
    end
  end
  return wrapped_fn, timer
end

-----------------------------------------------------------------------------//
-- Autoresize
-----------------------------------------------------------------------------//
-- Auto resize Vim splits to active split to 70% -
-- https://stackoverflow.com/questions/11634804/vim-auto-resize-focused-window
function mega.auto_resize()
  local auto_resize_on = false
  return function(args)
    if not auto_resize_on then
      local factor = args and tonumber(args) or 70
      local fraction = factor / 10
      -- NOTE: mutating &winheight/&winwidth are key to how
      -- this functionality works, the API fn equivalents do
      -- not work the same way
      vim.cmd(fmt("let &winheight=&lines * %d / 10 ", fraction))
      vim.cmd(fmt("let &winwidth=&columns * %d / 10 ", fraction))
      auto_resize_on = true
      vim.notify("Auto resize ON")
    else
      vim.cmd("let &winheight=30")
      vim.cmd("let &winwidth=30")
      vim.cmd("wincmd =")
      auto_resize_on = false
      vim.notify("Auto resize OFF")
    end
  end
end

function mega.flash_cursorline()
  -- local cursorline_state = vim.opt.cursorline:get()
  vim.opt.cursorline = true
  vim.cmd([[hi CursorLine guifg=#FFFFFF guibg=#FF9509]])
  vim.fn.timer_start(200, function()
    vim.cmd([[hi CursorLine guifg=NONE guibg=NONE]])
    vim.opt.cursorline = false
  end)
end

function mega.truncate(str, width, at_tail)
  local ellipsis = "…"
  local n_ellipsis = #ellipsis

  -- HT: https://github.com/lunarmodules/Penlight/blob/master/lua/pl/stringx.lua#L771-L796
  --- Return a shortened version of a string.
  -- Fits string within w characters. Removed characters are marked with ellipsis.
  -- @string s the string
  -- @int w the maxinum size allowed
  -- @bool tail true if we want to show the end of the string (head otherwise)
  -- @usage ('1234567890'):shorten(8) == '12345...'
  -- @usage ('1234567890'):shorten(8, true) == '...67890'
  -- @usage ('1234567890'):shorten(20) == '1234567890'
  local function shorten(s, w, tail)
    if #s > w then
      if w < n_ellipsis then return ellipsis:sub(1, w) end
      if tail then
        local i = #s - w + 1 + n_ellipsis
        return ellipsis .. s:sub(i)
      else
        return s:sub(1, w - n_ellipsis) .. ellipsis
      end
    end
    return s
  end

  return shorten(str, width, at_tail)
end

--- Convert a list or map of items into a value by iterating all it's fields and transforming
--- them with a callback
---@generic T : table
---@param callback fun(T, T, key: string | number): T
---@param list T[]
---@param accum T
---@return T
function mega.fold(callback, list, accum)
  for k, v in pairs(list) do
    accum = callback(accum, v, k)
    assert(accum ~= nil, "The accumulator must be returned on each iteration")
  end
  return accum
end

---@generic T : table
---@param callback fun(item: T, key: string | number, list: T[]): T
---@param list T[]
---@return T[]
function mega.map(callback, list)
  return mega.fold(function(accum, v, k)
    accum[#accum + 1] = callback(v, k, accum)
    return accum
  end, list, {})
end

---@generic T : table
---@param callback fun(T, key: string | number): T
---@param list T[]
function mega.foreach(callback, list)
  for k, v in pairs(list) do
    callback(v, k)
  end
end

--- Check if the target matches  any item in the list.
---@param target string
---@param list string[]
---@return boolean | string
function mega.any(target, list)
  return mega.fold(function(accum, item)
    if accum then return accum end
    if target:match(item) then return true end
    return accum
  end, list, false)
end

---Find an item in a list
---@generic T
---@param haystack T[]
---@param matcher fun(arg: T):boolean
---@return T
function mega.find(haystack, matcher)
  local found
  for _, needle in ipairs(haystack) do
    if matcher(needle) then
      found = needle
      break
    end
  end
  return found
end

function mega.tlen(t)
  local len = 0
  for _ in pairs(t) do
    len = len + 1
  end
  return len
end

--- automatically clear commandline messages after a few seconds delay
--- source: http://unix.stackexchange.com/a/613645
---@return function
function mega.clear_commandline()
  --- Track the timer object and stop any previous timers before setting
  --- a new one so that each change waits for 10secs and that 10secs is
  --- deferred each time
  local timer
  return function()
    if timer then timer:stop() end
    timer = vim.defer_fn(function()
      if fn.mode() == "n" then vim.cmd([[echon '']]) end
    end, 2500)
  end
end

function mega.is_chonky(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local is_too_long = vim.api.nvim_buf_line_count(bufnr) >= 5000
  local is_too_large = false

  local max_filesize = 50 * 1024 -- 50 KB
  local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  if ok and stats and stats.size > max_filesize then is_too_large = true end

  return (is_too_long or is_too_large)
end

function mega.hl_search_blink(delay)
  mega.blink_cursorline(delay * 1000)
  -- local ns = vim.api.nvim_create_namespace("HLSearch")
  -- vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  -- local search_pat = "\\c\\%#" .. vim.fn.getreg("/")
  -- local m = vim.fn.matchadd("IncSearch", search_pat)
  -- vim.cmd("redraw")
  -- vim.cmd("sleep " .. delay * 1000 .. "m")

  -- local sc = vim.fn.searchcount()
  -- vim.api.nvim_buf_set_extmark(0, ns, vim.api.nvim_win_get_cursor(0)[1] - 1, 0, {
  --   virt_text = { { "[" .. sc.current .. "/" .. sc.total .. "]", "LspCodeLens" } },
  --   virt_text_pos = "eol",
  -- })

  -- vim.fn.matchdelete(m)
  -- vim.cmd("redraw")
end

-- NOTE: This fn defers sourcing of most time consuming commands (mostly plugins). This is done by using `vim.schedule(f)` which defers execution of `f` until Vim is loaded. This doesn't affect general usability; it decreases time before showing fully functional start screen (or asked file).
function mega.packer_deferred() vim.cmd([[do User PackerDeferred]]) end

function mega.get_cursor_position()
  local rowcol = vim.api.nvim_win_get_cursor(0)
  local row = rowcol[1] - 1
  local col = rowcol[2]

  return row, col
end

function mega.clear_ui()
  -- vcmd([[nnoremap <silent><ESC> :syntax sync fromstart<CR>:nohlsearch<CR>:redrawstatus!<CR><ESC> ]])
  vim.cmd("nohlsearch")
  vim.cmd("diffupdate")
  vim.cmd("syntax sync fromstart")
  mega.close_float_wins()
  vim.cmd("echo ''")
  if vim.g.enabled_plugin["cursorline"] then mega.blink_cursorline() end

  -- do
  --   local ok, mj = pcall(require, "mini.jump")
  --   if ok then mj.stop_jumping() end
  -- end

  local ok, n = mega.require("notify")
  if ok then n.dismiss() end
end

-- [ commands ] ----------------------------------------------------------------
do
  local command = mega.command
  vcmd([[
    command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
  ]])

  command("AutoResize", mega.auto_resize(), { nargs = "?" })
  command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]])
  command("ReloadModule", function(tbl) require("plenary.reload").reload_module(tbl.args) end, {
    nargs = 1,
  })
  command(
    "DuplicateFile",
    [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]]
  )
  command("SaveAsFile", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]])
  command("RenameFile", [[noautocmd clear | :execute "Rename " .input('rename to -> ') | :e ]])
  command("Flash", function() mega.blink_cursorline() end)
  command("P", function(opts)
    vim.g.debug_enabled = true
    vim.cmd(fmt("lua P(%s)", opts.args))
    vim.g.debug_enabled = false
  end, { nargs = "*" })
  -- command("P", "<cmd>lua P(<args>)", { nargs = "?" })
  -- command("P", function(opts)
  --   local opts = opts.args or "¯\\_(ツ)_/¯"
  --   _G.P(opts)
  -- end, { nargs = "?" })

  mega.command("PackerUpgrade", function()
    vim.schedule(function()
      -- vim.g.PACKER_NON_INTERACTIVE = true
      require("mega.plugins.utils").bootstrap()
      require("mega.plugins.utils").sync()
    end)
  end)

  vim.cmd([[command! PackerInstall packadd packer.nvim | lua require('packer').install()]])
  vim.cmd([[command! PackerUpdate packadd packer.nvim | lua require('packer').update()]])
  vim.cmd([[command! PackerSync packadd packer.nvim | lua require('packer').sync()]])
  vim.cmd([[command! PackerClean packadd packer.nvim | lua require('packer').clean()]])
  vim.cmd([[command! PackerCompile packadd packer.nvim | lua require('packer').compile()]])
  vim.cmd([[command! PC PackerCompile]])
  vim.cmd([[command! PS PackerStatus]])
  vim.cmd([[command! PU PackerSync]])
  vim.cmd([[command! Noti Mess | Notifications]])
  -- vim.cmd([[command! Noti Mess | NotifierReplay!]])
end

return mega
