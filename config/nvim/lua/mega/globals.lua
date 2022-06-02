local api = vim.api
local fn = vim.fn
local vcmd = vim.cmd
local fmt = string.format
local L = vim.log.levels

_G.mega = {
  functions = {},
  dirs = {},
  mappings = {},
  lsp = {},
  icons = {
    border = {
      rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
      squared = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
      blank = { " ", " ", " ", " ", " ", " ", " ", " " },
    },
    lsp = {
      error = "",
      warn = "", -- 喝卑
      info = "",
      hint = "", -- 
      ok = "",
      -- spinner_frames = { "▪", "■", "□", "▫" },
      -- spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      -- TODO: evaluate
      -- kinds = {
      --   Text = "",
      --   Method = "",
      --   Function = "",
      --   Constructor = "",
      --   Field = "", -- '',
      --   Variable = "", -- '',
      --   Class = "", -- '',
      --   Interface = "",
      --   Module = "",
      --   Property = "ﰠ",
      --   Unit = "塞",
      --   Value = "",
      --   Enum = "",
      --   Keyword = "", -- '',
      --   Snippet = "", -- '', '',
      --   Color = "",
      --   File = "",
      --   Reference = "", -- '',
      --   Folder = "",
      --   EnumMember = "",
      --   Constant = "", -- '',
      --   Struct = "", -- 'פּ',
      --   Event = "",
      --   Operator = "",
      --   TypeParameter = "",
      -- },
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
        Namespace = " namespace",
        Package = " package",
        String = " string",
        Number = " number",
        Boolean = " boolean",
        Array = " array",
        Object = " object",
        Key = " key",
        Null = "ﳠ null",
      },
    },
    kind_highlights = {
      Text = "String",
      Method = "Method",
      Function = "Function",
      Constructor = "TSConstructor",
      Field = "Field",
      Variable = "Variable",
      Class = "Class",
      Interface = "Constant",
      Module = "Include",
      Property = "Property",
      Unit = "Constant",
      Value = "Variable",
      Enum = "Type",
      Keyword = "Keyword",
      File = "Directory",
      Reference = "PreProc",
      Constant = "Constant",
      Struct = "Type",
      Snippet = "Label",
      Event = "Variable",
      Operator = "Operator",
      TypeParameter = "Type",
      Namespace = "Namespace",
      Package = "Package",
      String = "String",
      Number = "Number",
      Boolean = "Boolean",
      Array = "Array",
      Object = "Object",
      Key = "Key",
      Null = "Null",
    },
    codicons = {
      Text = "",
      Method = "",
      Function = "",
      Constructor = "",
      Field = "",
      Variable = "",
      Class = "",
      Interface = "",
      Module = "",
      Property = "",
      Unit = "",
      Value = "",
      Enum = "",
      Keyword = "",
      Snippet = "", --
      Color = "",
      File = "",
      Reference = "",
      Folder = "",
      EnumMember = "",
      Constant = "",
      Struct = "",
      Event = "",
      Operator = "",
      TypeParameter = "",
    },
    git = {
      add = "", -- 
      change = "",
      remove = "", -- 
      ignore = "",
      rename = "",
      diff = "",
      repo = "",
      symbol = "", -- "" ""
    },
    documents = {
      file = "",
      files = "",
      folder = "",
      open_folder = "",
    },
    type = {
      array = "",
      number = "",
      object = "",
      null = "[]",
      float = "",
    },
    misc = {
      ellipsis = "…",
      lblock = "▌",
      rblock = "▐",
      bug = "",
      question = "",
      lock = "",
      circle = "",
      project = "",
      dashboard = "",
      history = "",
      comment = "",
      robot = "ﮧ",
      lightbulb = "",
      search = "",
      code = "",
      telescope = "",
      gear = "",
      package = "",
      list = "",
      sign_in = "",
      check = "",
      fire = "",
      note = "",
      bookmark = "",
      pencil = "",
      chevron_right = "",
      table = "",
      calendar = "",
    },
    virtual_text = "",
    mode_term = "ﲵ",
    ln_sep = "ℓ", -- ℓ 
    col_sep = "",
    perc_sep = "",
    modified = "●",
    mode = "",
    vcs = "",
    readonly = "",
    prompt = "",
  },
}

-- [ global variables ] --------------------------------------------------------

vim.g.mapleader = "," -- remap leader to `,`
vim.g.maplocalleader = " " -- remap localleader to `<Space>`
vim.g.colorscheme = "megaforest"
vim.g.default_colorcolumn = "81" -- global var, mark column 81

vim.g.os = vim.loop.os_uname().sysname
vim.g.is_macos = vim.g.os == "Darwin"
vim.g.is_linux = vim.g.os == "Linux"
vim.g.is_windows = vim.g.os == "Windows"

vim.g.open_command = vim.g.is_macos and "open" or "xdg-open"

vim.g.dotfiles = vim.env.DOTS or vim.fn.expand("~/.dotfiles")
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
-- # cache_paths
local local_state_paths = {
  fmt("%s/backup", vim.g.local_state_path),
  fmt("%s/session", vim.g.local_state_path),
  fmt("%s/swap", vim.g.local_state_path),
  fmt("%s/shada", vim.g.local_state_path),
  fmt("%s/tags", vim.g.local_state_path),
  fmt("%s/undo", vim.g.local_state_path),
}
if not is_dir(vim.g.local_state_path) then
  os.execute("mkdir -p " .. vim.g.local_state_path)
end
for _, p in pairs(local_state_paths) do
  if not is_dir(p) then
    os.execute("mkdir -p " .. p)
  end
end

-- [ runtimepath (rtp) ] -------------------------------------------------------

vim.opt.runtimepath:remove("~/.cache")
vim.opt.runtimepath:remove("~/.local/share/src")

-- [ utils ] -------------------------------------------------------------------

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

  local has_logger, logger = pcall(require, "logger")
  if has_logger then
    logger = logger.new({ level = "debug" })
    logger.info(table.concat(objects, "\n"))
  else
    print(table.concat(objects, "\n"))
  end
  return ...
end

function _G.dump(...)
  local objects = vim.tbl_map(vim.inspect, { ... })
  print(unpack(objects))
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

function mega.safe_require(module, opts)
  opts = opts or { silent = true }
  local ok, result = pcall(require, module)
  if not ok and not opts.silent then
    vim.notify(result, vim.log.levels.ERROR, { title = fmt("Error requiring: %s", module) })
  end
  return ok, result
end

---Handles retrieval of plugin configuration for given plugin name (used with `mega.conf/3`)
local function build_plugin_config(plugin_conf_name)
  local str_match = function(str, matcher)
    return string.find(str, matcher, 0, true)
  end

  local function parse_name(args)
    if args.as then
      return args.as
    elseif args.url then
      return args.url:gsub("%.git$", ""):match("/([%w-_.]+)$"), args.url
    else
      if type(args) == "table" then
        return args[1]:match("^[%w-]+/([%w-_.]+)$"), args[1]
      elseif type(args) == "string" then
        return args:match("^[%w-]+/([%w-_.]+)$"), args
      end
    end
  end

  local found = nil
  local paqs_path = vim.fn.stdpath("data") .. "/site/pack/paqs/"
  local match = false

  local found_filtered_plugin = vim.tbl_filter(function(pkg)
    local repo = ""
    local opt = false
    local name = parse_name(pkg)
    local dir = ""

    if type(pkg) == "table" then
      if pkg["url"] ~= nil then
        repo = pkg["url"]
      else
        repo = pkg[1]
      end

      if pkg["opt"] ~= nil then
        opt = pkg["opt"]
      end

      match = str_match(repo, plugin_conf_name)

      if match then
        dir = paqs_path .. (opt and "opt/" or "start/") .. name

        found = {
          name = name,
          conf_name = plugin_conf_name,
          spec = pkg,
          repo = repo,
          dir = dir,
          type = "table",
          opt = opt,
        }
      end

      return match
    elseif type(pkg) == "string" then
      repo = pkg
      match = str_match(repo, plugin_conf_name)

      if match then
        dir = paqs_path .. "start/" .. name

        found = {
          name = name,
          conf_name = plugin_conf_name,
          spec = pkg,
          repo = repo,
          dir = dir,
          type = "string",
          opt = opt,
        }
      end

      return match
    end

    return match
  end, require("mega.plugins").packages)

  return found_filtered_plugin and found or nil
end

--- @class ConfigOpts
--- @field config table|function
--- @field enabled? boolean
--- @field silent? boolean
--- @field test? boolean
--- @field event? table

---Wraps common plugin `setup` functionality; primarily for use with paq-nvim.
---@param plugin_conf_name string
---@param opts ConfigOpts
function mega.conf(plugin_conf_name, opts)
  opts = opts or {}
  local config
  local enabled
  local silent
  ---@diagnostic disable-next-line: unused-local
  local test
  ---@diagnostic disable-next-line: unused-local
  local event

  if type(opts) == "table" then
    config = (opts.config == nil) and {} or opts.config
    enabled = (opts.enabled == nil) and true or opts.enabled
    silent = (opts.silent == nil) and true or opts.silent
    ---@diagnostic disable-next-line: unused-local
    test = (opts.test == nil) and false or opts.test
    ---@diagnostic disable-next-line: unused-local
    event = (opts.event == nil) and {} or opts.event

    -- handle what to do when opts.config is simply a string "name" to use for loading external config
    if type(opts.config) == "string" then
      local has_external_config, found_external_config = pcall(require, fmt("mega.plugins.%s", plugin_conf_name))
      if has_external_config then
        config = found_external_config
      end
    end
  elseif type(opts) == "function" then
    config = opts
    enabled = true
    silent = true
    ---@diagnostic disable-next-line: unused-local
    test = false
    ---@diagnostic disable-next-line: unused-local
    event = {}
  end

  -- if not enabled then
  --   -- P(plugin_conf_name .. " currently disabled.")
  -- end

  if not enabled and not silent then
    P(plugin_conf_name .. " is disabled.")
  end

  if enabled then
    -- NOTE:
    -- If plugin is `opt` and `enabled`, we'll packadd the plugin (lazyload),
    -- then we'll go forth with setup of plugin or running of optional callback fn.
    -- local plugin_config = build_plugin_config(plugin_conf_name)
    -- if plugin_config then
    --   if plugin_config.opt then
    --     vim.cmd("packadd " .. plugin_config.name)
    --     if not silent then
    --       P(plugin_config.name .. " packadd as opt.")
    --     end

    --     -- For implementing this sort of thing:
    --     -- REF: https://github.com/akinsho/dotfiles/commit/33138f7bc7ad4b836b6c5c0f4ad54ea006f812be#diff-234774bd94026ade0e5765bc362576a2b0e1052dc0ed9bdea777e86a4a66c098R818
    --     -- mega.augroup("PluginConfLoader" .. plugin_conf_name, {
    --     --   {
    --     --     event = { "VimEnter" },
    --     --     once = true,
    --     --     command = function()
    --     --       P("lazy loading " .. plugin_config.name)
    --     --       vim.cmd("packadd " .. plugin_config.name)
    --     --     end,
    --     --   },
    --     -- })
    --   end
    -- end

    local ok, loader = pcall(require, plugin_conf_name, { silent = silent })
    -- plugin is installed, we found it, let's try and execute auto-config things on it, like auto-invoking its `setup` fn
    if ok then
      if type(config) == "table" then
        -- does it have a setup key to execute?
        if vim.fn.has_key(loader, "setup") then
          if not silent then
            P(fmt("%s configuring with `setup(config)`", plugin_conf_name))
          end

          loader.setup(config)
        end
        -- config was passed a function, so we're assuming we want to bypass the plugin auto-invoking, and invoke our own fn
      elseif type(config) == "function" then
        -- passes the loaded plugin back to the caller so they can do more config
        config(loader)
      end
    else
      if type(config) == "function" then
        config()
      else
        -- no-op
      end
    end
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
      local ok, wk = mega.safe_require("which-key", { silent = true })
      if ok then
        wk.register({ [lhs] = opts.label or opts.desc }, { mode = mode })
      end
      if opts.label and not opts.desc then
        opts.desc = opts.label
      end
      opts.label = nil
    end

    if rhs == nil then
      P(mode, lhs, rhs, opts, parent_opts)
    end

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
    if not vim.tbl_contains(keys, key) then
      table.insert(accum, key)
    end
    return accum
  end, cmd, {})
  if #incorrect == 0 then
    return
  end
  vim.schedule(function()
    vim.notify("Incorrect keys: " .. table.concat(incorrect, ", "), "error", {
      title = fmt("Autocmd: %s", name),
    })
  end)
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

local function open(path)
  fn.jobstart({ vim.g.open_command, path }, { detach = true })
  vim.notify(fmt("Opening %s", path))
end

-- open URI under cursor
function mega.open_uri()
  local file = fn.expand("<cfile>")
  if fn.isdirectory(file) > 0 then
    return vim.cmd("edit " .. file)
  end
  if file:match("https://") then
    return open(file)
  end
  -- Any URI with a protocol segment
  local protocol_uri_regex = "%a*:%/%/[%a%d%#%[%]%-%%+:;!$@/?&=_.,~*()]*"
  if file:match(protocol_uri_regex) then
    return vim.cmd("norm! gf")
  end

  -- consider anything that looks like string/string a github link
  local plugin_url_regex = "[%a%d%-%.%_]*%/[%a%d%-%.%_]*"
  local link = string.match(file, plugin_url_regex)
  if link then
    return open(fmt("https://www.github.com/%s", link))
  end
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
    if repo:match("https://") then
      return vim.cmd("norm gx")
    end
    if not repo or #vim.split(repo, "/") ~= 2 then
      return vim.cmd("norm! gf")
    end
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
mega.man = function(dest, ...)
  if dest == "tab" then
    dest = "tabnew"
  end
  if dest ~= "" then
    dest = dest .. " | "
  end
  for _, page in ipairs({ ... }) do
    if vim.regex("^\\d\\+p\\? \\w\\+$"):match_str(page) ~= nil then
      local s = vim.split(page, " ")
      page = ("%s(%s)"):format(s[2], s[1])
    end
    local prefix = dest
    if vim.fn.bufname(0) == "" and vim.fn.line("$") == 1 and vim.fn.getline(1) == "" then
      prefix = ""
    end
    vim.cmd(prefix .. "file " .. page .. " | call man#read_page(\"" .. page .. "\")")
  end
end

-- https://www.reddit.com/r/neovim/comments/nrz9hp/can_i_close_all_floating_windows_without_closing/h0lg5m1/
mega.close_float_wins = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" then
      vim.api.nvim_win_close(win, false)
    end
  end
end

-- Open a Help topic
--  - If a blank buffer is focused, open it there
--  - Otherwise, open in a new tab
mega.help = function(...)
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

---Check whether or not the location or quickfix list is open
---@return boolean
function mega.is_vim_list_open()
  for _, win in ipairs(api.nvim_list_wins()) do
    local buf = api.nvim_win_get_buf(win)
    local location_list = fn.getloclist(0, { filewinid = 0 })
    local is_loc_list = location_list.filewinid > 0
    if vim.bo[buf].filetype == "qf" or is_loc_list then
      return true
    end
  end
  return false
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
  for _, char in ipairs(mega.icons.border.squared) do
    table.insert(border, { char, hl or "FloatBorder" })
  end

  return border
end

function mega.sync_plugins()
  P("paq-nvim: syncing plugins..")
  package.loaded["mega.plugins"] = nil
  require("mega.plugins").sync_all()
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
      if w < n_ellipsis then
        return ellipsis:sub(1, w)
      end
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
    assert(accum, "The accumulator must be return on each iteration")
  end
  return accum
end

-- [ commands ] ----------------------------------------------------------------
do
  local command = mega.command
  vcmd([[
    command! -nargs=1 Rg lua require("telescope.builtin").grep_string({ search = vim.api.nvim_eval('"<args>"') })
  ]])

  command("AutoResize", mega.auto_resize(), { nargs = "?" })
  command("Todo", [[noautocmd silent! grep! 'TODO\|FIXME\|BUG\|HACK' | copen]])
  command("ReloadModule", function(tbl)
    require("plenary.reload").reload_module(tbl.args)
  end, {
    nargs = 1,
  })
  command(
    "Duplicate",
    [[noautocmd clear | silent! execute "!cp '%:p' '%:p:h/%:t:r-copy.%:e'"<bar>redraw<bar>echo "Copied " . expand('%:t') . ' to ' . expand('%:t:r') . '-copy.' . expand('%:e')]]
  )
  command("Copy", [[noautocmd clear | :execute "saveas %:p:h/" .input('save as -> ') | :e ]])
  command("Flash", function()
    mega.flash_cursorline()
  end)
end

return mega
