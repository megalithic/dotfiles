-- REF: https://github.com/rstacruz/vimfiles

local cmd = vim.api.nvim_command
local fn = vim.fn
local fmt = string.format

local M = {}

-- -- Checks if a given package is available
-- function M.has_pkg(name)
--   local path = vim.fn.stdpath("data") .. "/site/pack/packer/start/" .. name
--   return vim.fn.empty(vim.fn.glob(path)) == 0
-- end

-- -- Loads a module using require(), but does nothing if the module is not present
-- -- Used for conditionally configuring a plugin depending on whether it's installed
-- function M.conf(module_name, callback, opts)
--   -- first try to load an external config...
--   if opts == nil then
--     P("no opts")
--     return pcall(require, fmt("mega.plugins.%s", module_name))
--   else
--     -- else, pass in custom function
--     local status, mod = pcall(require, module_name)
--     if status then
--       if opts and opts["defer"] then
--         vim.defer_fn(function() callback(mod) end, 1000)
--       else
--         callback(mod)
--       end
--     end
--   end
-- end

-- function M.which(bin) return vim.fn.executable(bin) == 1 end

-- ---A thin wrapper around vim.notify to add packer details to the message
-- ---@param msg string
local function packer_notify(msg, level) vim.notify(msg, level, { title = "Packer" }) end

-- @HT tiagovla/.dotfiles for this packer boilerplate

local PACKER_INSTALL_PATH = fmt("%s/site/pack/packer/opt/packer.nvim", fn.stdpath("data"))
local PACKER_COMPILED_PATH = fmt("%s/packer/packer_compiled.lua", fn.stdpath("cache"))
local PACKER_SNAPSHOTS_PATH = fmt("%s/packer/snapshots/", fn.stdpath("cache"))

local bootstrap
if fn.empty(fn.glob(PACKER_INSTALL_PATH, nil, nil)) > 0 then
  packer_notify("Installing config...")
  fn.delete(PACKER_COMPILED_PATH)
  bootstrap = fn.system({ "git", "clone", "https://github.com/wbthomason/packer.nvim", PACKER_INSTALL_PATH })
end

cmd([[packadd packer.nvim]])

local ok_packer, packer = pcall(require, "packer")

if not ok_packer then error("Could not install packer") end

local function install_sync()
  if bootstrap then packer.sync() end
end

packer.init({
  display = {
    open_cmd = "silent topleft 65vnew",
    -- open_fn = function() return require("packer.util").float({ border = "single" }) end,
    prompt_border = mega.get_border(),
  },
  compile_path = PACKER_COMPILED_PATH,
  snapshot_path = PACKER_SNAPSHOTS_PATH,
  preview_updates = true,
  git = {
    clone_timeout = 600,
  },
  auto_clean = true,
  compile_on_sync = true,
  profile = {
    enable = true,
    threshold = 1,
  },
  log = { level = "info" },
})

local load = function(path)
  require("mega.plugins." .. path)
  local ok_conf, res = pcall(require, "mega.plugins." .. path)
  if ok_conf then
    return res
  else
    packer_notify(fmt("Could not load %s", path))
    return {}
  end
end

local use = function(config)
  if config.ext then
    local config_ext = load(config.ext)
    config = vim.tbl_deep_extend("force", config, config_ext)
    config.ext = nil
  end
  packer.use(config)
end

-- hard coded local plugins path
local function use_local(config)
  local sp = vim.split(config[1], "/")
  local repo_path = vim.fn.expand("$HOME/code/" .. sp[#sp], nil, nil)
  if vim.fn.isdirectory(repo_path) == 1 then
    config[1] = repo_path
  else
    packer_notify(fmt("Could not load local %s, using online instead.", repo_path))
  end
  use(config)
end

return { packer, use, use_local, install_sync }
