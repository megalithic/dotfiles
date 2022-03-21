local api = vim.api
local fn = vim.fn
local vcmd = vim.cmd
local fmt = string.format

_G.mega = {
  functions = {},
  dirs = {},
  mappings = {},
  lsp = {},
  icons = {
    borderchars = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
    lsp = {
      error = "",
      warn = "", -- 喝卑
      info = "",
      hint = "", -- 
      ok = "",
      -- spinner_frames = { "▪", "■", "□", "▫" },
      -- spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      kind = {
        Text = " text", -- Text
        Method = " method", -- Method
        Function = " function", -- Function
        Constructor = " constructor", -- Constructor
        Field = "ﰠ field", -- Field
        Variable = " variable", -- Variable
        Class = " class", -- Class
        Interface = "ﰮ interface", -- Interface
        Module = " module", -- Module
        Property = " property", -- Property
        Unit = " unit", -- Unit
        Value = " value", -- Value
        Enum = "了enum", -- Enum 
        Keyword = " keyword", -- Keyword
        Snippet = " snippet", -- Snippet
        Color = " color", -- Color
        File = " file", -- File
        Reference = " ref", -- Reference
        Folder = " folder", -- Folder
        EnumMember = " enum member", -- EnumMember
        Constant = " const", -- Constant
        Struct = "פּ struct", -- Struct
        Event = "鬒event", -- Event
        Operator = "\u{03a8} operator", -- Operator
        TypeParameter = " type param", -- TypeParameter
      },
    },
    virtual_text = "",
    mode_term = "ﲵ",
    ln_sep = "",
    col_sep = "",
    perc_sep = "",
    modified = "●",
    mode = "",
    vcs = "",
    git = "", -- "" ""
    git_added = "", --  
    git_changed = "",
    git_removed = "", --  
    readonly = "",
    prompt = "",
  },
}
local L = vim.log.levels
local get_log_level = require("vim.lsp.log").get_level

-- [ runtimepath (rtp) ] -------------------------------------------------------
vim.opt.runtimepath:remove("~/.cache")
vim.opt.runtimepath:remove("~/.local/share/src")

-- Global namespace
--- Inspired by @tjdevries' astraunauta.nvim/ @TimUntersberger's config
--- store all callbacks in one global table so they are able to survive re-requiring this file

function mega:load_variables()
  local home = os.getenv("HOME")
  local path_sep = mega.is_windows and "\\" or "/"
  local os_name = vim.loop.os_uname().sysname

  self.is_macos = os_name == "Darwin"
  self.is_linux = os_name == "Linux"
  self.is_windows = os_name == "Windows"
  self.vim_path = home .. path_sep .. ".config" .. path_sep .. "nvim"
  self.cache_dir = home .. path_sep .. ".cache" .. path_sep .. "nvim" .. path_sep
  self.local_share_dir = home .. path_sep .. ".local" .. path_sep .. "share" .. path_sep .. "nvim" .. path_sep
  self.modules_dir = self.vim_path .. path_sep .. "modules"
  self.path_sep = path_sep
  self.home = home

  return self
end
mega:load_variables()

mega.dirs.dots = fn.expand("$DOTS")
mega.dirs.privates = fn.expand("$PRIVATES")
mega.dirs.code = fn.expand("$HOME/code")
mega.dirs.icloud = fn.expand("$ICLOUD_DIR")
mega.dirs.docs = fn.expand("$DOCUMENTS_DIR")
mega.dirs.org = fn.expand(mega.dirs.docs .. "/_org")
mega.dirs.zettel = fn.expand("$ZK_NOTEBOOK_DIR")
mega.dirs.zk = mega.dirs.zettel

--- Check if a directory exists in this path
local function is_dir(path)
  -- check if file exists
  local function file_exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
      if code == 13 then
        -- Permission denied, but it exists
        return true
      end
    end
    return ok, err
  end

  -- "/" works on both Unix and Windows
  return file_exists(path .. "/")
end

-- setup vim's various config directories
-- # cache_dirs
local data_dir = {
  mega.cache_dir .. "backup",
  mega.cache_dir .. "session",
  mega.cache_dir .. "swap",
  mega.cache_dir .. "tags",
  mega.cache_dir .. "undo",
}
if not is_dir(mega.cache_dir) then
  os.execute("mkdir -p " .. mega.cache_dir)
end
for _, v in pairs(data_dir) do
  if not is_dir(v) then
    os.execute("mkdir -p " .. v)
  end
end
-- # local_share_dirs
local local_share_dir = {
  mega.local_share_dir .. "shada",
}
if not is_dir(mega.local_share_dir) then
  os.execute("mkdir -p " .. mega.local_share_dir)
end
for _, v in pairs(local_share_dir) do
  if not is_dir(v) then
    os.execute("mkdir -p " .. v)
  end
end

-- _G.logger = require("logger").new({
--   level = "trace",
-- })

-- function _G.put(...)
--   return logger.debug(...)
-- end

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function _G.P(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

function _G.dump_text(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

function mega.dump_colors(filter)
  local defs = {}
  for hl_name, hl in pairs(vim.api.nvim__get_hl_defs(0)) do
    if hl_name:find(filter) then
      local def = {}
      if hl.link then
        def.link = hl.link
      end
      for key, def_key in pairs({ foreground = "fg", background = "bg", special = "sp" }) do
        if type(hl[key]) == "number" then
          local hex = fmt("#%06x", hl[key])
          def[def_key] = hex
        end
      end
      for _, style in pairs({ "bold", "italic", "underline", "undercurl", "reverse" }) do
        if hl[style] then
          def.style = (def.style and (def.style .. ",") or "") .. style
        end
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
    installed = vim.tbl_map(function(path)
      return fn.fnamemodify(path, ":t")
    end, dirs)
  end
  return vim.tbl_contains(installed, plugin_name)
end

function mega.plugin_loaded(plugin_name)
  local plugins = package.loaded or {}
  return plugins[plugin_name] ~= nil -- and plugins[plugin_name].loaded
end

-- TODO: would like to add ability to gather input for continuing; ala `jordwalke/VimAutoMakeDirectory`
function mega.auto_mkdir()
  local dir = fn.expand("%:p:h")

  if fn.isdirectory(dir) == 0 then
    local create_dir = fn.input(fmt("[?] Parent dir [%s] doesn't exist; create it? (y/n) ", dir))
    if create_dir == "y" or create_dir == "yes" then
      fn.mkdir(dir, "p")
      vcmd("bufdo e")
      -- vcmd("redraw!")
    end
  end
end

-- inspect the contents of an object very quickly
-- in your code or from the command-line:
-- @see: https://www.reddit.com/r/neovim/comments/p84iu2/useful_functions_to_explore_lua_objects/
-- USAGE:
-- in lua: P({1, 2, 3})
-- in commandline: :lua P(vim.loop)
---@vararg any
function mega.P(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  print(table.concat(objects, "\n"))
  return ...
end

function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
end
mega.dump = dump

function mega.dump_text(...)
  local objects, v = {}, nil
  for i = 1, select("#", ...) do
    v = select(i, ...)
    table.insert(objects, vim.inspect(v))
  end

  local lines = vim.split(table.concat(objects, "\n"), "\n")
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  vim.fn.append(lnum, lines)
  return ...
end

function mega.log(msg, hl, reason)
  if hl == nil and reason == nil then
    api.nvim_echo({ { msg } }, true, {})
  else
    local name = "megavim"
    local prefix = name .. " -> "
    if reason ~= nil then
      prefix = name .. " -> " .. reason .. "\n"
    end
    hl = hl or "DiagnosticDefaultInformation"
    api.nvim_echo({ { prefix, hl }, { msg } }, true, {})
  end
end

function mega.warn(msg, reason)
  mega.log(msg, "DiagnosticDefaultWarning", reason)
end

function mega.error(msg, reason)
  mega.log(msg, "DiagnosticDefaultError", reason)
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

function mega.inspect(label, v, opts)
  opts = opts or {}
  opts = vim.tbl_deep_extend("keep", opts, { data_before = true, level = L.INFO })

  local log_str, hl = mega.get_log_string(label, opts.level)

  -- presently no better API to get the current lsp log level
  -- L.DEBUG == 3
  if opts.level == L.DEBUG and (get_log_level() == L.DEBUG or get_log_level() == 3) then
    if opts.data_before then
      mega.P(v)
      mega.log(log_str, hl)
    else
      mega.log(log_str, hl)
      mega.P(v)
    end
  end

  return v
end

function mega.opt(o, v, scopes)
  scopes = scopes or { vim.o }
  for _, s in ipairs(scopes) do
    s[o] = v
  end
end

-- a safe module loader
function mega.load(module, opts)
  opts = opts or { silent = false, safe = false }

  if opts.key == nil then
    opts.key = "loader"
  end

  local ok, result = pcall(require, module)

  if not ok and (opts.silent ~= nil and not opts.silent) then
    -- REF: https://github.com/neovim/neovim/blob/master/src/nvim/lua/vim.lua#L421
    local level = L.ERROR
    local reason = mega.get_log_string("loading failed", level)

    mega.error(result, reason)
  end

  if opts.safe ~= nil and opts.safe == true then
    return ok, result
  else
    return result
  end
end

function mega.safe_require(module, opts)
  opts = vim.tbl_extend("keep", { safe = true }, opts or {})
  return mega.load(module, opts)
end

---Create an nvim command
---@param name any
---@param rhs string|fun(args: string, fargs: table, bang: boolean)
---@param opts table
function mega.command(name, rhs, opts)
  opts = opts or {}
  api.nvim_add_user_command(name, rhs, opts)
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
    if opts.label then
      local ok, wk = mega.safe_require("which-key", { silent = true })
      if ok then
        wk.register({ [lhs] = opts.label }, { mode = mode })
      end
      opts.label = nil
    end
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("keep", opts, parent_opts))
  end
end

local map_opts = { remap = true, silent = true }
local noremap_opts = { remap = false, silent = true }

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

-- FIXME: this needs to be better; using new autocmd api
function mega.au(s, override)
  override = override or false
  if override then
    vcmd("au! " .. s)
  else
    vcmd("au " .. s)
  end
end

-- REF: https://github.com/neovim/neovim/blob/master/runtime/doc/api.txt#L3112
function mega.augroup(name, commands)
  local id = vim.api.nvim_create_augroup(name, { clear = true })

  for _, autocmd in ipairs(commands) do
    local is_callback = type(autocmd.command) == "function"
    api.nvim_create_autocmd(autocmd.events, {
      group = id,
      pattern = autocmd.targets,
      desc = autocmd.description,
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
      if opts.guifg and opts.guifg ~= "" then
        table.insert(hi_opt, "guifg=" .. opts.guifg)
      end
      if opts.guibg and opts.guibg ~= "" then
        table.insert(hi_opt, "guibg=" .. opts.guibg)
      end
      if opts.gui and opts.gui ~= "" then
        table.insert(hi_opt, "gui=" .. opts.gui)
      end
      if opts.guisp and opts.guisp ~= "" then
        table.insert(hi_opt, "guisp=" .. opts.guisp)
      end
      if opts.cterm and opts.cterm ~= "" then
        table.insert(hi_opt, "cterm=" .. opts.cterm)
      end
      vcmd(table.concat(hi_opt, " "))
    end
  end
end
mega.hi = mega.highlight

function mega.hi_link(src, dest)
  vcmd("hi! link " .. src .. " " .. dest)
end

function mega.exec(c, bool)
  bool = bool or true
  api.nvim_exec(c, bool)
end

function mega.noop() end

---A terser proxy for `nvim_replace_termcodes`
---@param str string
---@return any
function mega.replace_termcodes(str)
  return api.nvim_replace_termcodes(str, true, true, true)
end

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

mega.deep_merge = function(...)
  mega.table_merge(..., { strategy = "deep" })
end

mega.shallow_merge = function(...)
  mega.table_merge(..., { strategy = "shallow" })
end

function mega.iter(list_or_iter)
  if type(list_or_iter) == "function" then
    return list_or_iter
  end

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
  if decimal < 128 then
    return string.char(decimal)
  end
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

function mega.has(feature)
  return fn.has(feature) > 0
end

function mega.executable(e)
  return fn.executable(e) > 0
end

-- open URI under cursor
function mega.open_uri()
  local Job = require("plenary.job")
  local uri = vim.fn.expand("<cWORD>")
  Job
    :new({
      "open",
      uri,
    })
    :sync()
end

function mega.save_and_exec()
  if vim.bo.filetype == "vim" then
    vcmd("silent! write")
    vcmd("source %")
  elseif vim.bo.filetype == "lua" then
    vcmd("silent! write")
    vcmd("luafile %")
  end
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

---Determine if a value of any type is empty
---@param item any
---@return boolean
function mega.empty(item)
  if not item then
    return true
  end
  local item_type = type(item)
  if item_type == "string" then
    return item == ""
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

  if opts.attendees ~= nil and opts.attendees ~= "" then
    content = fmt("Attendees:\n%s\n\n---\n", opts.attendees)
  end

  local changed_title = fn.input(fmt("[?] Change title from [%s] to: ", title))
  if changed_title ~= "" then
    title = changed_title
  end

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
  for _, char in ipairs(mega.icons.borderchars) do
    table.insert(border, { char, hl or "FloatBorder" })
  end
  return border
end

function mega.sync_plugins()
  mega.log("paq-nvim: syncing plugins..")
  package.loaded["mega.plugins"] = nil
  require("mega.plugins").sync_all()
end

--- Usage:
--- 1. Call `local stop = utils.profile('my-log')` at the top of the file
--- 2. At the bottom of the file call `stop()`
--- 3. Restart neovim, the newly created log file should open
function mega.profile(filename)
  local base = "/tmp/config/profile/"
  fn.mkdir(base, "p")
  local success, profile = pcall(require, "plenary.profile.lua_profiler")
  if not success then
    vim.api.nvim_echo({ "Plenary is not installed.", "Title" }, true, {})
  end
  profile.start()
  return function()
    profile.stop()
    local logfile = base .. filename .. ".log"
    profile.report(logfile)
    vim.defer_fn(function()
      vcmd("tabedit " .. logfile)
    end, 1000)
  end
end

function mega.showCursorHighlights()
  local ft = vim.bo.filetype
  local is_ts_enabled = require("nvim-treesitter.configs").is_enabled("highlight", ft)
    and require("nvim-treesitter.configs").is_enabled("playground", ft)
  if is_ts_enabled then
    require("nvim-treesitter-playground.hl-info").show_hl_captures()
  else
    local synstack = vim.fn.synstack(vim.fn.line("."), vim.fn.col("."))
    local lmap = vim.fn.map(synstack, "synIDattr(v:val, \"name\")")
    vim.notify(vim.fn.join(vim.fn.reverse(lmap), " "))
  end
end

mega.nightly = mega.has("nvim-0.7")

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

      timer:start(ms, 0, function()
        pcall(vim.schedule_wrap(func), unpack(argv, 1, argc))
      end)
    end
  else
    local argv, argc
    function wrapped_fn(...)
      argv = argv or { ... }
      argc = argc or select("#", ...)

      timer:start(ms, 0, function()
        pcall(vim.schedule_wrap(func), unpack(argv, 1, argc))
      end)
    end
  end
  return wrapped_fn, timer
end

function mega.colors()
  local lush = require("lush")
  local spec = require("mega.lush_theme.megaforest")
  return lush(spec)
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

-- [ commands ] ----------------------------------------------------------------
do
  local command = mega.command
  vcmd([[
    command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
  ]])

  command("AutoResize", mega.auto_resize(), { nargs = "?" })
  command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]])
  command(
    "Duplicate",
    [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]]
  )
  command("Copy", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]])
  command("Flash", function() mega.flash_cursorline() end)
end

return mega
