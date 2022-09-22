-- @HTfunction  tiagovla/.dotfiles for this packer boilerplate

local fn = vim.fn
local fmt = string.format
local M = { local_plugins = {} }
local PACKER_INSTALL_PATH = fmt("%s/site/pack/packer/%s/packer.nvim", fn.stdpath("data"), "opt")

-- ---A thin wrapper around vim.notify to add packer details to the message
-- ---@param msg string
function M.notify(msg, level) vim.notify(msg, level, { title = "Packer" }) end

function M.conf(name)
  -- P(name)
  return require(fmt("mega.plugins.%s", name))
end

local function reload()
  mega.invalidate("mega.plugins", true)
  require("packer").compile()
end

local function setup_autocmds()
  mega.augroup("PackerSetupInit", {
    {
      event = { "BufWritePost" },
      pattern = { "*/mega/plugins/*.lua" },
      desc = "Packer setup and reload",
      command = reload,
    },
    {
      event = { "User" },
      pattern = { "VimrcReloaded" },
      desc = "Packer setup and reload",
      command = reload,
    },
    {
      event = { "User" },
      pattern = { "PackerCompileDone" },
      command = function() M.notify("Compilation finished", "info") end,
    },
  })
end

function M.bootstrap(compile_path)
  if fn.empty(fn.glob(PACKER_INSTALL_PATH)) > 0 then
    M.notify("Downloading packer.nvim...")
    M.notify(
      fn.system({ "git", "clone", "--depth", "1", "https://github.com/wbthomason/packer.nvim", PACKER_INSTALL_PATH })
    )
    vim.fn.delete(compile_path)
    vim.cmd.packadd({ "packer.nvim", bang = true })
    -- require("packer").sync()
    return true
  end

  vim.cmd.packadd({ "packer.nvim", bang = true })
  setup_autocmds()
  return false
end

function M.get_name(pkg)
  local parts = vim.split(pkg, "/")
  return parts[#parts], parts[1]
end

function M.has_local(name) return vim.loop.fs_stat(vim.fn.expand(fmt("%s/%s", vim.env.CODE, name))) ~= nil end

-- This method replaces any plugins with the local clone under vim.env.CODE
function M.process_local_plugins(spec)
  if type(spec) == "string" then
    local name, owner = M.get_name(spec)
    local local_pkg = fmt("%s/%s", vim.env.CODE, name)

    if M.local_plugins[name] or M.local_plugins[owner] or M.local_plugins[owner .. "/" .. name] then
      if M.has_local(name) then
        return local_pkg
      else
        M.notify("Local package " .. name .. " not found", "ERROR")
      end
    end
    return spec
  else
    for i, s in ipairs(spec) do
      spec[i] = M.process_local_plugins(s)
    end
  end
  if spec.requires then spec.requires = M.process_local_plugins(spec.requires) end
  return spec
end

-- processes external config strings
function M.process_ext_configs(spec)
  if spec.ext then spec.config = M.conf(spec.ext) end
  --print(I(spec))

  return spec
end

function M.wrap(use)
  return function(spec)
    spec = M.process_local_plugins(spec)
    spec = M.process_ext_configs(spec)
    use(spec)
  end
end

function M.setup(config, plugins_fn)
  -- HACK: see https://github.com/wbthomason/packer.nvim/issues/180
  vim.fn.setenv("MACOSX_DEPLOYMENT_TARGET", "10.15")

  local bootstrapped = M.bootstrap(config.compile_path)
  local packer = require("packer")
  packer.init(config)
  M.local_plugins = config.local_plugins or {}
  packer.startup({
    function(use)
      use = M.wrap(use)
      plugins_fn(use)
    end,
  })
  if bootstrapped then require("packer").sync() end
end

return M
