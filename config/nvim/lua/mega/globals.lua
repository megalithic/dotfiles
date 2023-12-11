local U = require("mega.utils")

_G.I = vim.inspect
_G.fmt = string.format
_G.L = vim.log.levels
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
vim.g.is_tmux_popup = vim.env.TMUX_POPUP ~= nil

vim.g.is_remote_dev = vim.trim(vim.fn.system("hostname")) == "seth-dev"
vim.g.is_local_dev = vim.trim(vim.fn.system("hostname")) ~= "seth-dev"

vim.g.open_command = vim.g.is_macos and "open" or "xdg-open"

vim.g.dotfiles = vim.env.DOTS or vim.fn.expand("~/.dotfiles")
vim.g.home = os.getenv("HOME")
vim.g.code = fmt("%s/code", vim.g.home)
vim.g.vim_path = fmt("%s/.config/nvim", vim.g.home)
vim.g.nvim_path = fmt("%s/.config/nvim", vim.g.home)
vim.g.cache_path = fmt("%s/.cache/nvim", vim.g.home)
vim.g.local_state_path = fmt("%s/.local/state/nvim", vim.g.home)
vim.g.local_share_path = fmt("%s/.local/share/nvim", vim.g.home)
vim.g.icloud_path = vim.env.ICLOUD_DIR
vim.g.icloud_documents_path = vim.env.ICLOUD_DOCUMENTS_DIR
vim.g.obsidian_vault_path = vim.env.OBSIDIAN_VAULT_DIR
vim.g.notes_path = fmt("%s/_notes", vim.g.icloud_documents_path)
vim.g.neorg_path = fmt("%s/_org", vim.g.icloud_documents_path)
vim.g.hammerspoon_path = fmt("%s/config/hammerspoon", vim.g.dotfiles)
vim.g.hs_emmy_path = fmt("%s/Spoons/EmmyLua.spoon", vim.g.hammerspoon_path)

-- mega.dirs.dots = vim.g.dotfiles
-- mega.dirs.privates = fn.expand("$PRIVATES")
-- mega.dirs.code = fn.expand("$HOME/code")
-- mega.dirs.icloud = vim.g.icloud_path
-- mega.dirs.docs = fn.expand("$DOCUMENTS_DIR")
-- mega.dirs.org = fn.expand(mega.dirs.docs .. "/_org")
-- mega.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")
-- mega.dirs.zk = mega.dirs.zettel

-- [ luarocks ] -----------------------------------------------------------------

package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?/init.lua;", package.path, vim.g.home)
package.path = fmt("%s; %s/.luarocks/share/lua/5.1/?.lua;", package.path, vim.g.home)

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  -- if not vim.g.debug_enabled then return end
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

    -- if not opts.has or client.server_capabilities[opts.has .. "Provider"] then
    if opts.label or opts.desc then
      local ok, wk = pcall(require, "which-key")
      if ok and wk then wk.register({ [lhs] = opts.label or opts.desc }, { mode = mode }) end
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
_G.map = vim.keymap.set
mega.map = vim.keymap.set

---Find an item in a list
---@generic T
---@param matcher fun(arg: T):boolean
---@param haystack T[]
---@return T?
function mega.find(matcher, haystack)
  for _, needle in ipairs(haystack) do
    if matcher(needle) then return needle end
  end
end

function mega.command(name, rhs, opts)
  opts = opts or {}
  vim.api.nvim_create_user_command(name, rhs, opts)
end

---Determine if a value of any type is empty
---@param item any
---@return boolean?
function mega.falsy(item)
  if not item then return true end
  local item_type = type(item)
  if item_type == "boolean" then return not item end
  if item_type == "string" then return item == "" end
  if item_type == "number" then return item <= 0 end
  if item_type == "table" then return vim.tbl_isempty(item) end
  return item ~= nil
end

function mega.get_border(hl)
  hl = hl or "FloatBorder"
  local border = {}
  for _, char in ipairs(mega.icons.border.blank) do
    table.insert(border, { char, hl })
  end

  return border
end

--- Validate the keys passed to mega.augroup are valid
---@param name string
---@param cmd Autocommand
local function validate_autocmd(name, cmd)
  local keys = { "event", "buffer", "pattern", "desc", "command", "group", "once", "nested" }
  local incorrect = U.fold(function(accum, _, key)
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
---@param ... Autocommand A list of autocommands to create (variadic parameter)
---@return number
function mega.augroup(name, commands)
  assert(name ~= "User", "The name of an augroup CANNOT be User")

  local id = vim.api.nvim_create_augroup(name, { clear = true })

  for _, autocmd in ipairs(commands) do
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

  return id
end

--- Call the given function and use `vim.notify` to notify of any errors
--- this function is a wrapper around `xpcall` which allows having a single
--- error handler for all errors
---@param msg string
---@param func function
---@param ... any
---@return boolean, any
---@overload fun(func: function, ...): boolean, any
function mega.pcall(msg, func, ...)
  local args = { ... }
  if type(msg) == "function" then
    local arg = func --[[@as any]]
    args, func, msg = { arg, unpack(args) }, msg, nil
  end
  return xpcall(func, function(err)
    msg = debug.traceback(msg and fmt("%s:\n%s\n%s", msg, vim.inspect(args), err) or err)
    vim.schedule(function() vim.notify(msg, L.ERROR, { title = "ERROR", render = "default" }) end)
  end, unpack(args))
end

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

--- Call the given function and use `vim.notify` to notify of any errors
--- this function is a wrapper around `xpcall` which allows having a single
--- error handler for all errors
---@param msg string
---@param func function
---@vararg any
---@return boolean, any
---@overload fun(fun: function, ...): boolean, any
function mega.wrap_err(msg, func, ...) return mega.pcall(msg, func, ...) end

---Require a module using `pcall` and report any errors
---@param module_name string
---@param opts table?
---@return boolean, any
function mega.require(module_name, opts)
  opts = opts or { silent = true }
  local ok, result = pcall(require, module_name)
  if not ok and not opts.silent then
    if opts.message then result = opts.message .. "\n" .. result end

    -- FIXME: this breaks if silent == true
    -- vim.notify(result, L.ERROR, { title = fmt("Error requiring: %s", module_name), render = "default" })
    vim.notify_once(fmt("Missing module: %s", module_name), L.WARN)
  end
  return ok, result
end

-- function mega.iabbrev(lhs, rhs, opts)
--   opts = opts or {}
--   local ft = opts["ft"] or nil
--   local ext = opts["ext"] or nil
--   if type(opts) == "string" then ft = { opts } end
--   local event = nil
--   local pattern = { "*" }
--   local desc = ""
--   local group = "iabbrevs"
--   if ft ~= nil then
--     group = "iabbrevs_" .. table.concat(ft, "_")
--     event = { "FileType" }
--     pattern = type(ft) == "string" and { ft } or ft
--     desc = "Insert abbreviation for " .. vim.inspect(ft)
--   elseif ext ~= nil then
--     group = "iabbrevs_" .. ext
--     event = {
--       fmt([[BufRead %s]], ext),
--       fmt([[BufNewFile %s]], ext),
--     }
--     pattern = ext
--     desc = "Insert abbreviation for " .. ext
--   end
--
--   if event ~= nil then
--     mega.augroup(group, {
--       {
--         event = event,
--         pattern = pattern,
--         desc = desc,
--         command = function() vim.cmd.iabbrev(fmt([[%s %s]], lhs, rhs)) end,
--       },
--     })
--   else
--     vim.cmd.iabbrev(fmt([[%s %s]], lhs, rhs))
--   end
-- end
function mega.iabbrev(lhs, rhs, ft)
  ft = ft or nil
  if type(ft) == "string" then ft = { ft } end

  if ft ~= nil then
    if vim.tbl_contains(ft, vim.bo.filetype) then vim.cmd.iabbrev(fmt([[%s %s]], lhs, rhs)) end
  else
    vim.cmd.iabbrev(fmt([[%s %s]], lhs, rhs))
  end
end
function mega.cabbrev(lhs, rhs) vim.cmd.cabbrev(fmt([[%s %s]], lhs, rhs)) end
function mega.abbrev(lhs, rhs, ft)
  ft = ft or nil
  if type(ft) == "string" then ft = { ft } end

  if ft ~= nil then
    if vim.tbl_contains(ft, vim.bo.filetype) then vim.cmd.abbrev(fmt([[%s %s]], lhs, rhs)) end
  else
    vim.cmd.abbrev(fmt([[%s %s]], lhs, rhs))
  end
end
function mega.noabbrev(lhs, rhs, ft)
  ft = ft or nil
  if type(ft) == "string" then ft = { ft } end

  if ft ~= nil then
    if vim.tbl_contains(ft, vim.bo.filetype) then vim.cmd.noabbrev(fmt([[%s %s]], lhs, rhs)) end
  else
    vim.cmd.noabbrev(fmt([[%s %s]], lhs, rhs))
  end
end

-- [ commands ] ----------------------------------------------------------------
do
  local command = mega.command
  vim.cmd([[
    command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
  ]])

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
  -- command("Rename", [[RenameFile]])
  -- command("Rename", [[lua require("genghis").renameFile()]])
  -- command("Delete", [[lua require("genghis").trashFile()]])
  command("Flash", function() mega.blink_cursorline() end)
  command("P", function(opts)
    vim.g.debug_enabled = true
    vim.cmd(fmt("lua P(%s)", opts.args))
    vim.g.debug_enabled = false
  end, { nargs = "*" })
  command("D", function(opts)
    vim.g.debug_enabled = true
    vim.cmd(fmt("lua d(%s)", opts.args))
    vim.g.debug_enabled = false
  end, { nargs = "*" })
  -- command("Noti", [[Notifications]])
  command("Noti", [[Messages | Notifications]])

  command("DBUI", function()
    vim.cmd("DotEnv")
    vim.cmd("DBUI")
  end, { nargs = "*" })

  command("CopyBranch", function()
    vim.cmd([[silent !git branch --show-current | tr -d '[:space:]' | (pbcopy || lemonade copy)]])
    vim.notify(fmt("copied to clipboard: %s", vim.fn.getreg("+")))
  end)

  command(
    "TreeInspect",
    function()
      vim.treesitter.inspect_tree({
        command = fmt("botright %dvnew", math.min(math.floor(vim.o.columns * 0.25), 80)),
      })
    end
  )
end
return mega
