-- lua/langs/init.lua
-- Unified language configuration system
-- All lang-specific settings live in lua/langs/*.lua
-- This module handles loading, merging (with extends), and providing configs
-- to LSP, conform, and ftplugin systems.
--
-- NOTE: Treesitter is NOT managed here - see lua/plugins/treesitter.lua

local M = {}

-- =============================================================================
-- Configuration
-- =============================================================================

-- Valid top-level keys in lang configs (for validation)
local VALID_KEYS = {
  "extends",
  "filetypes",
  "servers",
  "formatters",
  "ftplugin",
  "repl",
  "plugins",
}

-- Valid LSP server config keys (vim.lsp.config fields + our extensions)
local VALID_SERVER_KEYS = {
  -- Native vim.lsp.config fields
  "cmd", "cmd_cwd", "cmd_env", "capabilities", "handlers", "settings",
  "commands", "init_options", "name", "filetypes", "root_dir", "single_file_support",
  "workspace_required", "on_attach", "autostart",
  -- Our extensions
  "keys", "root_markers",  -- root_markers gets converted to root_dir
}

-- Common typos to warn about
local TYPO_WARNINGS = {
  setings = "settings",
  settigns = "settings",
  formaters = "formatters",
  ftplugins = "ftplugin",
  plugin = "plugins",
  server = "servers",
  filetype = "filetypes",
  extend = "extends",
}

-- =============================================================================
-- State
-- =============================================================================

local _cache = {
  loaded = {},           -- Raw loaded configs (before extends resolution)
  resolved = {},         -- Resolved configs (after extends)
  all_resolved = false,  -- Whether all() has been called
  servers = nil,         -- Cached servers result
  server_keys = nil,     -- Cached server_keys result
  ftplugins = nil,       -- Cached ftplugin configs by filetype
  repls = nil,           -- Cached repl configs by filetype
}

-- =============================================================================
-- Utilities
-- =============================================================================

---Notify with consistent prefix
---@param msg string
---@param level? integer
local function notify(msg, level)
  vim.notify("[langs] " .. msg, level or vim.log.levels.INFO)
end

---Convert root_markers to root_dir function
---@param markers string[]
---@return function
local function markers_to_root_dir(markers)
  return function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    if fname == "" then return end
    local match = vim.fs.find(markers, {
      upward = true,
      path = vim.fs.dirname(fname),
    })[1]
    if match then
      on_dir(vim.fs.dirname(match))
    end
  end
end

---Deep merge two tables, with special handling for lang config semantics
---@param parent table
---@param child table
---@return table
local function merge_configs(parent, child)
  local result = vim.deepcopy(parent)

  for key, child_val in pairs(child) do
    if key == "extends" then
      -- Don't copy extends to result
    elseif key == "filetypes" then
      -- Replace: child defines its own filetypes
      result.filetypes = child_val
    elseif key == "servers" then
      -- Deep merge, but false disables
      result.servers = result.servers or {}
      for server, config in pairs(child_val) do
        if config == false then
          result.servers[server] = nil  -- Remove/disable
        elseif result.servers[server] then
          result.servers[server] = vim.tbl_deep_extend("force", result.servers[server], config)
        else
          result.servers[server] = config
        end
      end
    elseif key == "formatters" then
      -- Merge: add new filetypes
      result.formatters = vim.tbl_deep_extend("force", result.formatters or {}, child_val)
    elseif key == "ftplugin" then
      -- Merge: add/override filetypes
      result.ftplugin = result.ftplugin or {}
      for ft, config in pairs(child_val) do
        if result.ftplugin[ft] then
          result.ftplugin[ft] = vim.tbl_deep_extend("force", result.ftplugin[ft], config)
        else
          result.ftplugin[ft] = config
        end
      end
    elseif key == "plugins" then
      -- Extend: concatenate arrays
      result.plugins = result.plugins or {}
      for _, spec in ipairs(child_val) do
        table.insert(result.plugins, spec)
      end
    else
      -- Unknown key: just copy
      result[key] = child_val
    end
  end

  return result
end

---Validate a lang config and warn about issues
---@param name string
---@param config table
local function validate_config(name, config)
  for key, _ in pairs(config) do
    -- Check for typos
    if TYPO_WARNINGS[key] then
      notify(string.format("%s: '%s' looks like a typo for '%s'", name, key, TYPO_WARNINGS[key]), vim.log.levels.WARN)
    -- Check for unknown keys
    elseif not vim.list_contains(VALID_KEYS, key) then
      notify(string.format("%s: unknown key '%s'", name, key), vim.log.levels.WARN)
    end
  end

  -- Validate servers have valid structure
  if config.servers then
    for server, server_config in pairs(config.servers) do
      if type(server_config) == "table" then
        if server_config.setings then
          notify(string.format("%s: server '%s' has 'setings' (typo for 'settings')", name, server), vim.log.levels.WARN)
        end
        -- Validate server config keys
        for key, _ in pairs(server_config) do
          if not vim.list_contains(VALID_SERVER_KEYS, key) then
            notify(string.format("%s: server '%s' has unknown key '%s'", name, server, key), vim.log.levels.WARN)
          end
        end
      end
    end
  end
end

-- =============================================================================
-- Core Loading
-- =============================================================================

---Discover all lang files in lua/langs/ (searches runtimepath)
---Skips init.lua (this file) and files starting with _
---@return string[]
local function discover_langs()
  local langs = {}
  local seen = {}

  -- Search all runtimepath entries for lua/langs/
  for _, rtp in ipairs(vim.api.nvim_list_runtime_paths()) do
    local langs_dir = rtp .. "/lua/langs"
    if vim.fn.isdirectory(langs_dir) == 1 then
      for name, ftype in vim.fs.dir(langs_dir) do
        if ftype == "file" and name:match("%.lua$") then
          local lang_name = name:gsub("%.lua$", "")
          -- Skip init.lua (this file) and files starting with _
          if lang_name ~= "init" and not lang_name:match("^_") and not seen[lang_name] then
            table.insert(langs, lang_name)
            seen[lang_name] = true
          end
        end
      end
    end
  end

  return langs
end

---Load a single lang config file (without resolving extends)
---@param name string
---@return table|nil config, string|nil error
function M.load(name)
  -- Return cached if available
  if _cache.loaded[name] then
    return _cache.loaded[name]
  end

  local ok, config = pcall(require, "langs." .. name)
  if not ok then
    notify(string.format("Failed to load '%s': %s", name, config), vim.log.levels.ERROR)
    return nil, config
  end

  if type(config) ~= "table" then
    local err = string.format("'%s' must return a table, got %s", name, type(config))
    notify(err, vim.log.levels.ERROR)
    return nil, err
  end

  -- Validate
  validate_config(name, config)

  -- Cache and return
  _cache.loaded[name] = config
  return config
end

---Resolve a lang config (following extends chain)
---@param name string
---@param _chain? string[] Internal: tracks extends chain to detect cycles
---@return table|nil
function M.resolve(name, _chain)
  -- Return cached if available
  if _cache.resolved[name] then
    return _cache.resolved[name]
  end

  -- Detect circular extends
  _chain = _chain or {}
  if vim.list_contains(_chain, name) then
    notify(string.format("Circular extends detected: %s -> %s", table.concat(_chain, " -> "), name), vim.log.levels.ERROR)
    return nil
  end
  table.insert(_chain, name)

  -- Load raw config
  local config = M.load(name)
  if not config then
    return nil
  end

  -- If no extends, we're done
  if not config.extends then
    _cache.resolved[name] = config
    return config
  end

  -- Resolve parent first
  local parent = M.resolve(config.extends, _chain)
  if not parent then
    notify(string.format("'%s' extends '%s' which failed to load", name, config.extends), vim.log.levels.ERROR)
    return nil
  end

  -- Merge parent + child
  local resolved = merge_configs(parent, config)
  _cache.resolved[name] = resolved
  return resolved
end

---Load and resolve all lang configs
---@return table<string, table>
function M.all()
  if _cache.all_resolved then
    return _cache.resolved
  end

  local lang_names = discover_langs()
  for _, name in ipairs(lang_names) do
    M.resolve(name)
  end

  _cache.all_resolved = true
  return _cache.resolved
end

-- =============================================================================
-- Aggregated Configs (for consumers)
-- =============================================================================

---Recursively evaluate any function values in a table
---Used for lazy-evaluated settings like schemastore schemas
---@param tbl table
---@return table
local function evaluate_functions(tbl)
  local result = {}
  for k, v in pairs(tbl) do
    if type(v) == "function" then
      local ok, evaluated = pcall(v)
      result[k] = ok and evaluated or nil
    elseif type(v) == "table" then
      result[k] = evaluate_functions(v)
    else
      result[k] = v
    end
  end
  return result
end

---Get all LSP server configs (merged from all langs)
---Extracts 'keys' field for separate handling in LspAttach
---Evaluates any function values in settings (for lazy schemas, etc.)
---Converts root_markers to root_dir functions
---Adds lang's filetypes to each server (required for vim.lsp.enable)
---Results are cached after first call
---@return table<string, table> servers, table<string, table> server_keys
function M.servers()
  -- Return cached if available
  if _cache.servers then
    return _cache.servers, _cache.server_keys
  end

  local all = M.all()
  local servers = {}
  local server_keys = {}

  for _, config in pairs(all) do
    local lang_filetypes = config.filetypes

    for server, server_config in pairs(config.servers or {}) do
      if server_config and server_config ~= false then
        -- Deep copy to avoid mutating cached config
        server_config = vim.deepcopy(server_config)

        -- Add lang's filetypes if server doesn't define its own
        -- This is required for vim.lsp.enable() to know when to attach
        if not server_config.filetypes and lang_filetypes then
          server_config.filetypes = lang_filetypes
        end

        -- Convert root_markers to root_dir function
        if server_config.root_markers then
          server_config.root_dir = markers_to_root_dir(server_config.root_markers)
          server_config.root_markers = nil
        end

        -- Extract keys (our custom field, not LSP config)
        if server_config.keys then
          server_keys[server] = server_config.keys
          server_config.keys = nil
        end

        -- Evaluate any function values in settings
        if server_config.settings then
          server_config.settings = evaluate_functions(server_config.settings)
        end

        -- Merge or set server config
        if servers[server] then
          servers[server] = vim.tbl_deep_extend("force", servers[server], server_config)
        else
          servers[server] = server_config
        end
      end
    end
  end

  -- Cache results
  _cache.servers = servers
  _cache.server_keys = server_keys

  return servers, server_keys
end

---Get all formatter configs (merged from all langs)
---@return table<string, table>
function M.formatters()
  local all = M.all()
  local formatters = {}

  for _, config in pairs(all) do
    for ft, ft_config in pairs(config.formatters or {}) do
      if formatters[ft] then
        formatters[ft] = vim.tbl_deep_extend("force", formatters[ft], ft_config)
      else
        formatters[ft] = ft_config
      end
    end
  end

  return formatters
end

---Get all ftplugin configs (merged from all langs)
---@return table<string, table>
function M.ftplugin_configs()
  if _cache.ftplugins then
    return _cache.ftplugins
  end

  local all = M.all()
  local ftplugins = {}

  for _, config in pairs(all) do
    for ft, ft_config in pairs(config.ftplugin or {}) do
      if ftplugins[ft] then
        ftplugins[ft] = vim.tbl_deep_extend("force", ftplugins[ft], ft_config)
      else
        ftplugins[ft] = ft_config
      end
    end
  end

  _cache.ftplugins = ftplugins
  return ftplugins
end

---Get REPL configs by filetype
---@return table<string, table>
function M.repl_configs()
  if _cache.repls then
    return _cache.repls
  end

  local all = M.all()
  local repls = {}

  for _, config in pairs(all) do
    if config.repl and config.filetypes then
      for _, ft in ipairs(config.filetypes) do
        repls[ft] = config.repl
      end
    end
  end

  _cache.repls = repls
  return repls
end

---Get all plugin specs (collected from all langs)
---@return table[]
function M.lazy_specs()
  local all = M.all()
  local specs = {}

  for _, config in pairs(all) do
    for _, spec in ipairs(config.plugins or {}) do
      table.insert(specs, spec)
    end
  end

  return specs
end

-- =============================================================================
-- ftplugin Application
-- =============================================================================

---Apply ftplugin config to a buffer
---@param bufnr integer
---@param config table
local function apply_ftplugin(bufnr, config)
  -- Buffer options
  if config.opt then
    for key, value in pairs(config.opt) do
      local ok, err = pcall(function()
        local info = vim.api.nvim_get_option_info2(key, {})
        if info.scope == "buf" then
          vim.api.nvim_set_option_value(key, value, { buf = bufnr })
        elseif info.scope == "win" then
          -- Apply to all windows showing this buffer
          for _, winid in ipairs(vim.fn.win_findbuf(bufnr)) do
            vim.api.nvim_set_option_value(key, value, { win = winid })
          end
        else
          -- Global option, set locally
          vim.api.nvim_set_option_value(key, value, { buf = bufnr })
        end
      end)
      if not ok then
        notify(string.format("Failed to set option %s: %s", key, err), vim.log.levels.WARN)
      end
    end
  end

  -- Buffer-local keymaps
  if config.keys then
    for _, keymap in ipairs(config.keys) do
      local mode = keymap[1]
      local lhs = keymap[2]
      local rhs = keymap[3]
      local opts = {
        buffer = bufnr,
        desc = keymap.desc,
        silent = keymap.silent,
        nowait = keymap.nowait,
        remap = keymap.remap,
      }
      vim.keymap.set(mode, lhs, rhs, opts)
    end
  end

  -- Abbreviations (use keymap for proper <ESC> handling)
  if config.abbr then
    for lhs, rhs in pairs(config.abbr) do
      vim.keymap.set("ia", lhs, rhs, { buffer = bufnr })
    end
  end

  -- Buffer variables
  if config.bufvar then
    for key, value in pairs(config.bufvar) do
      vim.b[bufnr][key] = value
    end
  end

  -- Custom callback
  if config.callback then
    local ok, err = pcall(config.callback, bufnr)
    if not ok then
      notify(string.format("ftplugin callback error: %s", err), vim.log.levels.WARN)
    end
  end
end

-- =============================================================================
-- Setup (autocmds)
-- =============================================================================

---Setup autocmds for ftplugin application
---NOTE: LSP keymaps are handled in lua/lsp/init.lua to avoid duplicate M.servers() calls
function M.setup()
  local augroup = vim.api.nvim_create_augroup("mega.langs", { clear = true })

  -- ftplugin: apply on FileType
  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    callback = function(args)
      local ft = args.match
      local bufnr = args.buf
      local ftplugin_configs = M.ftplugin_configs()
      local repl_configs = M.repl_configs()

      -- Handle composite filetypes (e.g., "html.elixir")
      local filetypes = vim.split(ft, ".", { plain = true })
      for _, filetype in ipairs(filetypes) do
        -- Apply ftplugin config
        local config = ftplugin_configs[filetype]
        if config then
          apply_ftplugin(bufnr, config)
        end

        -- Apply REPL keymaps if repl config exists
        local repl = repl_configs[filetype]
        if repl then
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          -- Start REPL
          map("n", "<localleader>rs", function()
            mega.term({ cmd = repl.cmd, position = repl.position or "right" })
          end, "Start REPL")

          -- Send line to REPL
          map("n", "<localleader>rr", function()
            local line = vim.api.nvim_get_current_line()
            mega.term.send(line .. "\n")
          end, "Send line to REPL")

          -- Send selection to REPL
          map("v", "<localleader>rr", function()
            -- Use '< and '> marks (set after exiting visual mode) and visualmode()
            local lines = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = vim.fn.visualmode() })
            mega.term.send(table.concat(lines, "\n") .. "\n")
          end, "Send selection to REPL")

          -- Reload command (if defined)
          if repl.reload_cmd then
            map("n", "<localleader>rc", function()
              mega.term.send(repl.reload_cmd .. "\n")
            end, "Reload in REPL")
          end
        end
      end
    end,
  })
end

-- =============================================================================
-- Debug / Inspection
-- =============================================================================

---Inspect a lang config (resolved)
---@param name? string If nil, shows all
function M.inspect(name)
  if name then
    local config = M.resolve(name)
    if config then
      vim.print(config)
    else
      notify(string.format("Lang '%s' not found", name), vim.log.levels.WARN)
    end
  else
    vim.print(M.all())
  end
end

---List all discovered langs
---@return string[]
function M.list()
  return discover_langs()
end

---Clear cache (for development/reloading)
function M.clear_cache()
  _cache.loaded = {}
  _cache.resolved = {}
  _cache.all_resolved = false
  _cache.servers = nil
  _cache.server_keys = nil
  _cache.ftplugins = nil
  _cache.repls = nil
  -- Also clear from package.loaded
  for key in pairs(package.loaded) do
    if key:match("^langs%.") then
      package.loaded[key] = nil
    end
  end
end

-- =============================================================================
-- Commands
-- =============================================================================

vim.api.nvim_create_user_command("LangInspect", function(opts)
  local name = opts.args ~= "" and opts.args or nil
  M.inspect(name)
end, {
  nargs = "?",
  complete = function()
    return M.list()
  end,
  desc = "Inspect lang config (resolved)",
})

vim.api.nvim_create_user_command("LangList", function()
  local langs = M.list()
  print("Discovered langs: " .. table.concat(langs, ", "))
end, {
  desc = "List all discovered lang configs",
})

vim.api.nvim_create_user_command("LangServers", function()
  local servers, _ = M.servers()
  print("LSP servers: " .. table.concat(vim.tbl_keys(servers), ", "))
end, {
  desc = "List all LSP servers from lang configs",
})

vim.api.nvim_create_user_command("LangReload", function()
  M.clear_cache()
  M.all()
  notify("Lang configs reloaded")
end, {
  desc = "Reload all lang configs (clears cache)",
})

return M
